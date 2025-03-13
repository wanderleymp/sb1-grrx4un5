import React from 'react';
import { Bell, X, Check, Info, AlertTriangle, AlertCircle, CheckCircle2 } from 'lucide-react';
import { useNotificationStore } from '../../store/notifications';
import { useAuth } from '../../contexts/AuthContext';
import * as DropdownMenu from '@radix-ui/react-dropdown-menu';

export function NotificationCenter() {
  const { user } = useAuth();
  const {
    notifications,
    unreadCount,
    isLoading,
    fetchNotifications,
    markAsRead,
    deleteNotification,
    subscribeToRealtime,
    unsubscribeFromRealtime
  } = useNotificationStore();

  React.useEffect(() => {
    fetchNotifications();
    
    if (user?.id) {
      subscribeToRealtime(user.id);
      return () => unsubscribeFromRealtime();
    }
  }, [fetchNotifications, user?.id, subscribeToRealtime, unsubscribeFromRealtime]);

  const getIcon = (type: string) => {
    switch (type) {
      case 'info':
        return <Info className="h-5 w-5 text-blue-500" />;
      case 'warning':
        return <AlertTriangle className="h-5 w-5 text-yellow-500" />;
      case 'error':
        return <AlertCircle className="h-5 w-5 text-red-500" />;
      case 'success':
        return <CheckCircle2 className="h-5 w-5 text-green-500" />;
      default:
        return <Info className="h-5 w-5 text-gray-500" />;
    }
  };

  return (
    <DropdownMenu.Root>
      <DropdownMenu.Trigger asChild>
        <button className="relative p-2 hover:bg-gray-100 rounded-full">
          <Bell className="h-5 w-5 text-gray-600" />
          {unreadCount > 0 && (
            <span className="absolute top-0 right-0 h-4 w-4 bg-red-500 rounded-full flex items-center justify-center">
              <span className="text-xs text-white font-medium">
                {unreadCount > 9 ? '9+' : unreadCount}
              </span>
            </span>
          )}
        </button>
      </DropdownMenu.Trigger>

      <DropdownMenu.Portal>
        <DropdownMenu.Content
          className="w-80 bg-white rounded-lg shadow-lg border border-gray-200 py-2 mt-2"
          sideOffset={5}
          align="end"
        >
          <div className="px-4 py-2 border-b border-gray-100">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-semibold text-gray-900">Notificações</h3>
              {unreadCount > 0 && (
                <span className="text-xs text-gray-500">
                  {unreadCount} não {unreadCount === 1 ? 'lida' : 'lidas'}
                </span>
              )}
            </div>
          </div>

          <div className="max-h-96 overflow-y-auto">
            {isLoading ? (
              <div className="flex items-center justify-center py-8">
                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
              </div>
            ) : notifications.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                <Bell className="h-8 w-8 mx-auto mb-2 text-gray-400" />
                <p>Nenhuma notificação</p>
              </div>
            ) : (
              notifications.map((notification) => (
                <div
                  key={notification.id}
                  className={`px-4 py-3 hover:bg-gray-50 ${
                    !notification.read ? 'bg-blue-50' : ''
                  }`}
                >
                  <div className="flex items-start space-x-3">
                    {getIcon(notification.type)}
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-900">
                        {notification.title}
                      </p>
                      <p className="text-sm text-gray-500">{notification.message}</p>
                      <div className="mt-1 flex items-center space-x-2">
                        <span className="text-xs text-gray-400">
                          {new Date(notification.created_at).toLocaleDateString('pt-BR', {
                            hour: '2-digit',
                            minute: '2-digit'
                          })}
                        </span>
                        {!notification.read && (
                          <button
                            onClick={() => markAsRead(notification.id)}
                            className="text-xs text-blue-600 hover:text-blue-700 font-medium flex items-center"
                          >
                            <Check className="h-3 w-3 mr-1" />
                            Marcar como lida
                          </button>
                        )}
                      </div>
                    </div>
                    <button
                      onClick={() => deleteNotification(notification.id)}
                      className="text-gray-400 hover:text-gray-500"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
        </DropdownMenu.Content>
      </DropdownMenu.Portal>
    </DropdownMenu.Root>
  );
}