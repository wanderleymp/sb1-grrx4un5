import { supabase } from '../supabase';
import { RealtimeChannel } from '@supabase/supabase-js';
import { getTenantId } from '../tenant';

export interface ChatRoom {
  id: string;
  name: string;
  type: 'direct' | 'group';
  created_at: string;
  updated_at: string;
}

export interface ChatMessage {
  id: string;
  room_id: string;
  user_id: string;
  content: string;
  type: 'text' | 'image' | 'file';
  created_at: string;
  updated_at: string;
}

interface ChatParticipant {
  room_id: string;
  user_id: string;
  joined_at: string;
}

class ChatAPI {
  private messageChannel: RealtimeChannel | null = null;

  // Gerenciamento de Salas
  async createRoom(name: string, type: 'direct' | 'group', participants: string[]): Promise<ChatRoom> {
    const tenantId = await getTenantId();
    
    const { data: room, error: roomError } = await supabase
      .from('chat_rooms')
      .insert({ 
        name, 
        type,
        tenant_id: tenantId
      })
      .select()
      .single();

    if (roomError) throw roomError;

    // Adicionar participantes
    const participantsData = participants.map(userId => ({
      room_id: room.id,
      user_id: userId
    }));

    const { error: participantsError } = await supabase
      .from('chat_participants')
      .insert(participantsData);

    if (participantsError) throw participantsError;

    return room;
  }

  async getRooms(): Promise<ChatRoom[]> {
    const { data, error } = await supabase
      .from('chat_rooms')
      .select('*')
      .order('updated_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  // Mensagens
  async getMessages(roomId: string, limit = 50): Promise<ChatMessage[]> {
    const { data, error } = await supabase
      .from('chat_messages')
      .select('*')
      .eq('room_id', roomId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  }

  async sendMessage(roomId: string, content: string, type: 'text' | 'image' | 'file' = 'text'): Promise<ChatMessage> {
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) throw new Error('Usuário não autenticado');

    const { data, error } = await supabase
      .from('chat_messages')
      .insert({
        room_id: roomId,
        user_id: user.id,
        content,
        type
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  // Realtime
  subscribeToMessages(roomId: string, onNewMessage: (message: ChatMessage) => void): () => void {
    if (this.messageChannel) {
      this.messageChannel.unsubscribe();
    }

    this.messageChannel = supabase
      .channel(`room:${roomId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'chat_messages',
          filter: `room_id=eq.${roomId}`
        },
        (payload) => {
          onNewMessage(payload.new as ChatMessage);
        }
      )
      .subscribe();

    return () => {
      if (this.messageChannel) {
        this.messageChannel.unsubscribe();
        this.messageChannel = null;
      }
    };
  }

  // Participantes
  async getParticipants(roomId: string): Promise<ChatParticipant[]> {
    const { data, error } = await supabase
      .from('chat_participants')
      .select('*, profiles(*)')
      .eq('room_id', roomId);

    if (error) throw error;
    return data || [];
  }

  async addParticipant(roomId: string, userId: string): Promise<void> {
    const { error } = await supabase
      .from('chat_participants')
      .insert({ room_id: roomId, user_id: userId });

    if (error) throw error;
  }

  async removeParticipant(roomId: string, userId: string): Promise<void> {
    const { error } = await supabase
      .from('chat_participants')
      .delete()
      .eq('room_id', roomId)
      .eq('user_id', userId);

    if (error) throw error;
  }
}

export const chatAPI = new ChatAPI();