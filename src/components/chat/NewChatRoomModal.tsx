import React from 'react';
import { Users, User } from 'lucide-react';
import { Modal } from '../ui/Modal';
import { useAuth } from '../../contexts/AuthContext';
import { chatAPI } from '../../services/api/chat';

interface NewChatRoomModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function NewChatRoomModal({ isOpen, onClose, onSuccess }: NewChatRoomModalProps) {
  const { user } = useAuth();
  const [isLoading, setIsLoading] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [formData, setFormData] = React.useState({
    name: '',
    type: 'direct' as 'direct' | 'group'
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name.trim()) return;

    setIsLoading(true);
    setError(null);

    try {
      // Criar sala com o usuário atual como participante
      await chatAPI.createRoom(
        formData.name,
        formData.type,
        [user?.id || '']
      );
      
      onSuccess();
      onClose();
    } catch (error) {
      console.error('Erro ao criar sala:', error);
      setError('Não foi possível criar a sala. Tente novamente.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose}>
      <div className="p-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-6">Nova Conversa</h2>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Tipo de Conversa
            </label>
            <div className="grid grid-cols-2 gap-4">
              <label className={`
                flex items-center p-4 rounded-lg border cursor-pointer transition-colors
                ${formData.type === 'direct' ? 'bg-blue-50 border-blue-500' : 'border-gray-200 hover:border-blue-200'}
              `}>
                <input
                  type="radio"
                  name="type"
                  value="direct"
                  checked={formData.type === 'direct'}
                  onChange={(e) => setFormData(prev => ({ ...prev, type: e.target.value as 'direct' | 'group' }))}
                  className="sr-only"
                />
                <User className={`h-5 w-5 mr-3 ${formData.type === 'direct' ? 'text-blue-500' : 'text-gray-400'}`} />
                <div>
                  <span className="text-sm font-medium block">Chat Direto</span>
                  <span className="text-xs text-gray-500">Conversa individual</span>
                </div>
              </label>

              <label className={`
                flex items-center p-4 rounded-lg border cursor-pointer transition-colors
                ${formData.type === 'group' ? 'bg-blue-50 border-blue-500' : 'border-gray-200 hover:border-blue-200'}
              `}>
                <input
                  type="radio"
                  name="type"
                  value="group"
                  checked={formData.type === 'group'}
                  onChange={(e) => setFormData(prev => ({ ...prev, type: e.target.value as 'direct' | 'group' }))}
                  className="sr-only"
                />
                <Users className={`h-5 w-5 mr-3 ${formData.type === 'group' ? 'text-blue-500' : 'text-gray-400'}`} />
                <div>
                  <span className="text-sm font-medium block">Grupo</span>
                  <span className="text-xs text-gray-500">Conversa em grupo</span>
                </div>
              </label>
            </div>
          </div>

          <div>
            <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-1">
              Nome {formData.type === 'group' ? 'do Grupo' : 'do Chat'}
            </label>
            <input
              type="text"
              id="name"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder={formData.type === 'group' ? 'Ex: Equipe de Vendas' : 'Ex: João Silva'}
            />
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-600 text-sm">
              {error}
            </div>
          )}

          <div className="flex justify-end space-x-3 pt-6 border-t">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-800 transition-colors"
              disabled={isLoading}
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={isLoading || !formData.name.trim()}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed inline-flex items-center"
            >
              {isLoading ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                  Criando...
                </>
              ) : (
                'Criar Conversa'
              )}
            </button>
          </div>
        </form>
      </div>
    </Modal>
  );
}