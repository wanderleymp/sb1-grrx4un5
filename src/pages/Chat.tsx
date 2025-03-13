import React from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useChatStore } from '../store/chat';
import { NewChatRoomModal } from '../components/chat/NewChatRoomModal';
import { Send, Plus, Users, Search, Image, Paperclip, Smile, MoreVertical } from 'lucide-react';

export function Chat() {
  const { user } = useAuth();
  const [isNewRoomModalOpen, setIsNewRoomModalOpen] = React.useState(false);
  const {
    rooms,
    activeRoom,
    messages,
    isLoading,
    fetchRooms,
    setActiveRoom,
    sendMessage
  } = useChatStore();

  const [messageInput, setMessageInput] = React.useState('');
  const [searchQuery, setSearchQuery] = React.useState('');
  const messagesEndRef = React.useRef<HTMLDivElement>(null);
  const fileInputRef = React.useRef<HTMLInputElement>(null);

  React.useEffect(() => {
    fetchRooms();
  }, [fetchRooms]);

  React.useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [messages, activeRoom]);

  const filteredRooms = React.useMemo(() => {
    if (!searchQuery) return rooms;
    return rooms.filter(room =>
      room.name.toLowerCase().includes(searchQuery.toLowerCase())
    );
  }, [rooms, searchQuery]);

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!messageInput.trim()) return;

    try {
      await sendMessage(messageInput);
      setMessageInput('');
    } catch (error) {
      console.error('Erro ao enviar mensagem:', error);
    }
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // TODO: Implementar upload de arquivos
    console.log('Upload de arquivo:', file);
  };

  const activeRoomMessages = activeRoom ? messages[activeRoom.id] || [] : [];

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-[calc(100vh-4rem)]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="flex h-[calc(100vh-4rem)]">
      {/* Lista de Salas */}
      <div className="w-80 bg-white border-r border-gray-200 flex flex-col">
        <div className="p-4 border-b border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Chat</h2>
            <button 
              onClick={() => setIsNewRoomModalOpen(true)}
              className="p-2 hover:bg-gray-100 rounded-lg"
            >
              <Plus className="h-5 w-5 text-gray-600" />
            </button>
          </div>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Buscar conversas..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
        </div>

        <div className="flex-1 overflow-y-auto">
          {filteredRooms.map((room) => (
            <button
              key={room.id}
              onClick={() => setActiveRoom(room)}
              className={`w-full p-4 flex items-center space-x-3 hover:bg-gray-50 ${
                activeRoom?.id === room.id ? 'bg-blue-50' : ''
              }`}
            >
              <div className="flex-shrink-0">
                {room.type === 'group' ? (
                  <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                    <Users className="h-6 w-6 text-blue-600" />
                  </div>
                ) : (
                  <div className="w-12 h-12 bg-gradient-to-br from-purple-500 to-indigo-500 rounded-lg flex items-center justify-center">
                    <span className="text-lg font-medium text-white">
                      {room.name[0].toUpperCase()}
                    </span>
                  </div>
                )}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between">
                  <p className="text-sm font-medium text-gray-900 truncate">
                    {room.name}
                  </p>
                  <span className="text-xs text-gray-500">
                    {new Date(room.updated_at).toLocaleTimeString('pt-BR', {
                      hour: '2-digit',
                      minute: '2-digit'
                    })}
                  </span>
                </div>
                <p className="text-sm text-gray-500 truncate">
                  {room.type === 'group' ? '👥 Grupo' : '👤 Chat direto'}
                </p>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Área de Chat */}
      {activeRoom ? (
        <div className="flex-1 flex flex-col bg-gray-50">
          {/* Cabeçalho */}
          <div className="p-4 bg-white border-b border-gray-200 flex items-center justify-between">
            <div className="flex items-center space-x-3">
              {activeRoom.type === 'group' ? (
                <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                  <Users className="h-5 w-5 text-blue-600" />
                </div>
              ) : (
                <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-indigo-500 rounded-lg flex items-center justify-center">
                  <span className="text-lg font-medium text-white">
                    {activeRoom.name[0].toUpperCase()}
                  </span>
                </div>
              )}
              <div>
                <h3 className="text-lg font-semibold text-gray-900">
                  {activeRoom.name}
                </h3>
                <p className="text-sm text-gray-500">
                  {activeRoom.type === 'group' ? 'Grupo' : 'Chat direto'}
                </p>
              </div>
            </div>
            <button className="p-2 hover:bg-gray-100 rounded-lg">
              <MoreVertical className="h-5 w-5 text-gray-600" />
            </button>
          </div>

          {/* Mensagens */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {activeRoomMessages.map((message) => (
              <div
                key={message.id}
                className={`flex ${
                  message.user_id === user?.id ? 'justify-end' : 'justify-start'
                }`}
              >
                <div
                  className={`max-w-[70%] rounded-lg p-3 ${
                    message.user_id === user?.id
                      ? 'bg-blue-600 text-white'
                      : 'bg-white border border-gray-200'
                  }`}
                >
                  <p className={message.user_id === user?.id ? 'text-white' : 'text-gray-900'}>
                    {message.content}
                  </p>
                  <p
                    className={`text-xs mt-1 ${
                      message.user_id === user?.id ? 'text-blue-100' : 'text-gray-500'
                    }`}
                  >
                    {new Date(message.created_at).toLocaleTimeString('pt-BR', {
                      hour: '2-digit',
                      minute: '2-digit'
                    })}
                  </p>
                </div>
              </div>
            ))}
            <div ref={messagesEndRef} />
          </div>

          {/* Input de Mensagem */}
          <div className="p-4 bg-white border-t border-gray-200">
            <form onSubmit={handleSendMessage} className="flex items-center space-x-2">
              <button
                type="button"
                className="p-2 text-gray-500 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
                onClick={() => fileInputRef.current?.click()}
              >
                <Paperclip className="h-5 w-5" />
              </button>
              <input
                ref={fileInputRef}
                type="file"
                className="hidden"
                onChange={handleFileUpload}
                accept="image/*,.pdf,.doc,.docx"
              />
              <button
                type="button"
                className="p-2 text-gray-500 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
              >
                <Image className="h-5 w-5" />
              </button>
              <button
                type="button"
                className="p-2 text-gray-500 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
              >
                <Smile className="h-5 w-5" />
              </button>
              <input
                type="text"
                value={messageInput}
                onChange={(e) => setMessageInput(e.target.value)}
                placeholder="Digite sua mensagem..."
                className="flex-1 px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <button
                type="submit"
                disabled={!messageInput.trim()}
                className="p-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Send className="h-5 w-5" />
              </button>
            </form>
          </div>
        </div>
      ) : (
        <div className="flex-1 flex items-center justify-center bg-gray-50">
          <div className="text-center">
            <Users className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              Nenhuma conversa selecionada
            </h3>
            <p className="text-gray-500">
              Selecione uma conversa para começar a chatear
            </p>
          </div>
        </div>
      )}
      
      <NewChatRoomModal
        isOpen={isNewRoomModalOpen}
        onClose={() => setIsNewRoomModalOpen(false)}
        onSuccess={fetchRooms}
      />
    </div>
  );
}