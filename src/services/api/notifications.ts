import { supabase } from '../supabase';
import { RealtimeChannel } from '@supabase/supabase-js';

export interface Notification {
  id: string;
  user_id: string;
  title: string;
  message: string;
  type: 'info' | 'warning' | 'error' | 'success';
  read: boolean;
  created_at: string;
}

interface CreateNotificationDTO {
  title: string;
  message: string;
  type: 'info' | 'warning' | 'error' | 'success';
  user_id: string;
}

class NotificationAPI {
  private realtimeChannel: RealtimeChannel | null = null;

  subscribeToNotifications(userId: string, onNewNotification: (notification: Notification) => void) {
    if (this.realtimeChannel) {
      this.realtimeChannel.unsubscribe();
    }

    this.realtimeChannel = supabase
      .channel('notifications')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'notifications',
          filter: `user_id=eq.${userId}`
        },
        (payload) => {
          onNewNotification(payload.new as Notification);
        }
      )
      .subscribe();

    return () => {
      if (this.realtimeChannel) {
        this.realtimeChannel.unsubscribe();
        this.realtimeChannel = null;
      }
    };
  }

  async create(data: CreateNotificationDTO): Promise<Notification> {
    const { data: notification, error } = await supabase
      .from('notifications')
      .insert({
        title: data.title,
        message: data.message,
        type: data.type,
        user_id: data.user_id,
        read: false
      })
      .select()
      .single();

    if (error) {
      console.error('Erro ao criar notificação:', error);
      throw new Error('Não foi possível criar a notificação');
    }

    return notification;
  }

  async findAll(): Promise<Notification[]> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
    
      if (!user) {
        console.warn('Usuário não autenticado');
        return [];
      }
    
      const { data: notifications, error } = await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Erro ao buscar notificações:', error);
        throw new Error('Não foi possível buscar as notificações');
      }

      return notifications || [];
    } catch (error) {
      console.error('Erro ao buscar notificações:', error);
      return [];
    }
  }

  async markAsRead(id: string): Promise<void> {
    const { error } = await supabase
      .from('notifications')
      .update({ read: true })
      .eq('id', id);

    if (error) {
      console.error('Erro ao marcar notificação como lida:', error);
      throw new Error('Não foi possível atualizar a notificação');
    }
  }

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('notifications')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('Erro ao deletar notificação:', error);
      throw new Error('Não foi possível deletar a notificação');
    }
  }
}

export const notificationAPI = new NotificationAPI();