import { create } from 'zustand';
import { Notification, notificationAPI } from '../services/api/notifications';
import { supabase } from '../services/supabase';

interface NotificationState {
  notifications: Notification[];
  unreadCount: number;
  isLoading: boolean;
  error: string | null;
  subscribeToRealtime: (userId: string) => void;
  unsubscribeFromRealtime: () => void;
  fetchNotifications: () => Promise<void>;
  markAsRead: (id: string) => Promise<void>;
  deleteNotification: (id: string) => Promise<void>;
  addNotification: (notification: Notification) => void;
}

export const useNotificationStore = create<NotificationState>((set, get) => ({
  notifications: [],
  unreadCount: 0,
  isLoading: false,
  error: null,
  unsubscribeFunction: null as (() => void) | null,

  subscribeToRealtime: (userId: string) => {
    const unsubscribe = notificationAPI.subscribeToNotifications(userId, (notification) => {
      get().addNotification(notification);
    });
    set({ unsubscribeFunction: unsubscribe });
  },

  unsubscribeFromRealtime: () => {
    const { unsubscribeFunction } = get() as any;
    if (unsubscribeFunction) {
      unsubscribeFunction();
      set({ unsubscribeFunction: null });
    }
  },

  addNotification: (notification: Notification) => {
    set(state => ({
      notifications: [notification, ...state.notifications],
      unreadCount: state.unreadCount + 1
    }));
  },

  fetchNotifications: async () => {
    set({ isLoading: true, error: null });
    try {
      const data = await notificationAPI.findAll();
      set({
        notifications: data,
        unreadCount: data.filter(n => !n.read).length,
        error: null
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Erro ao carregar notificações';
      console.error('Erro ao carregar notificações:', error);
      set({ error: message, notifications: [], unreadCount: 0 });
    } finally {
      set({ isLoading: false });
    }
  },

  markAsRead: async (id: string) => {
    try {
      await notificationAPI.markAsRead(id);
      const notifications = get().notifications.map(n =>
        n.id === id ? { ...n, read: true } : n
      );
      const unreadCount = notifications.filter(n => !n.read).length;
      set({ notifications, unreadCount });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Erro ao atualizar notificação';
      set({ error: message });
    }
  },

  deleteNotification: async (id: string) => {
    try {
      await notificationAPI.delete(id);
      const notifications = get().notifications.filter(n => n.id !== id);
      const unreadCount = notifications.filter(n => !n.read).length;
      set({ notifications, unreadCount });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Erro ao deletar notificação';
      set({ error: message });
    }
  },
}));