import { create } from 'zustand';
import { ChatRoom, ChatMessage, chatAPI } from '../services/api/chat';

interface ChatState {
  rooms: ChatRoom[];
  activeRoom: ChatRoom | null;
  messages: Record<string, ChatMessage[]>;
  isLoading: boolean;
  error: string | null;
  unsubscribeFunction: (() => void) | null;
  
  // Ações
  fetchRooms: () => Promise<void>;
  setActiveRoom: (room: ChatRoom | null) => void;
  fetchMessages: (roomId: string) => Promise<void>;
  sendMessage: (content: string, type?: 'text' | 'image' | 'file') => Promise<void>;
  subscribeToMessages: (roomId: string) => void;
  unsubscribeFromMessages: () => void;
}

export const useChatStore = create<ChatState>((set, get) => ({
  rooms: [],
  activeRoom: null,
  messages: {},
  isLoading: false,
  error: null,
  unsubscribeFunction: null,

  fetchRooms: async () => {
    set({ isLoading: true, error: null });
    try {
      const rooms = await chatAPI.getRooms();
      set({ rooms });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Erro ao carregar salas';
      set({ error: message });
    } finally {
      set({ isLoading: false });
    }
  },

  setActiveRoom: (room) => {
    set({ activeRoom: room });
    if (room) {
      get().fetchMessages(room.id);
      get().subscribeToMessages(room.id);
    } else {
      get().unsubscribeFromMessages();
    }
  },

  fetchMessages: async (roomId) => {
    set({ isLoading: true, error: null });
    try {
      const messages = await chatAPI.getMessages(roomId);
      set(state => ({
        messages: {
          ...state.messages,
          [roomId]: messages
        }
      }));
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Erro ao carregar mensagens';
      set({ error: message });
    } finally {
      set({ isLoading: false });
    }
  },

  sendMessage: async (content, type = 'text') => {
    const { activeRoom } = get();
    if (!activeRoom) return;

    try {
      const message = await chatAPI.sendMessage(activeRoom.id, content, type);
      set(state => ({
        messages: {
          ...state.messages,
          [activeRoom.id]: [message, ...(state.messages[activeRoom.id] || [])]
        }
      }));
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Erro ao enviar mensagem';
      set({ error: message });
    }
  },

  subscribeToMessages: (roomId) => {
    get().unsubscribeFromMessages();

    const unsubscribe = chatAPI.subscribeToMessages(roomId, (message) => {
      set(state => ({
        messages: {
          ...state.messages,
          [roomId]: [message, ...(state.messages[roomId] || [])]
        }
      }));
    });

    set({ unsubscribeFunction: unsubscribe });
  },

  unsubscribeFromMessages: () => {
    const { unsubscribeFunction } = get();
    if (unsubscribeFunction) {
      unsubscribeFunction();
      set({ unsubscribeFunction: null });
    }
  }
}));