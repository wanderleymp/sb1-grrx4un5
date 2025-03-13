import React from 'react';
import { User, Mail, Lock, Phone, Instagram, MessageSquare, AlertCircle } from 'lucide-react';
import { useUserStore } from '../../store/users';
import type { User as UserType } from '../../services/api/users';

interface UserFormProps {
  user?: UserType;
  onClose: () => void;
}

export function UserForm({ user, onClose }: UserFormProps) {
  const { createUser, updateUser } = useUserStore();
  const [isSubmitting, setIsSubmitting] = React.useState(false);
  const [errors, setErrors] = React.useState<Record<string, string>>({});

  const [formData, setFormData] = React.useState({
    name: user?.name || '',
    email: user?.email || '',
    password: '',
    role: user?.role || 'user',
    contacts: user?.contacts || [],
    addEmailAsContact: true
  });

  const [newContact, setNewContact] = React.useState({
    type: 'whatsapp',
    identifier: ''
  });

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.name.trim()) {
      newErrors.name = 'Nome é obrigatório';
    }

    if (!user && !formData.email.trim()) {
      newErrors.email = 'Email é obrigatório';
    } else if (!user && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Email inválido';
    }

    if (!user && !formData.password) {
      newErrors.password = 'Senha é obrigatória';
    } else if (!user && formData.password.length < 6) {
      newErrors.password = 'A senha deve ter pelo menos 6 caracteres';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) return;

    setIsSubmitting(true);
    try {
      if (user) {
        // Preparar contatos para atualização
        const updatedContacts = formData.contacts
          .filter(c => c.type !== 'user')
          .map(c => ({
            type: c.type,
            identifier: c.identifier
          }));

        // Adicionar email como contato se marcado
        if (formData.addEmailAsContact) {
          updatedContacts.push({
            type: 'email',
            identifier: user.email
          });
        }

        await updateUser(user.id, {
          name: formData.name,
          role: formData.role as 'admin' | 'user',
          contacts: updatedContacts
        });
      } else {
        // Preparar contatos para criação
        const initialContacts = formData.addEmailAsContact ? [
          {
            type: 'email',
            identifier: formData.email
          }
        ] : [];

        await createUser({
          name: formData.name,
          email: formData.email,
          password: formData.password,
          role: formData.role as 'admin' | 'user',
          contacts: initialContacts
        });
      }
      onClose();
    } catch (error) {
      console.error('Erro ao salvar usuário:', error);
      setErrors(prev => ({
        ...prev,
        submit: 'Erro ao salvar usuário. Tente novamente.'
      }));
    } finally {
      setIsSubmitting(false);
    }
  };

  const addContact = () => {
    if (!newContact.identifier.trim()) return;

    setFormData(prev => ({
      ...prev,
      contacts: [...prev.contacts, newContact]
    }));

    setNewContact({
      type: 'whatsapp',
      identifier: ''
    });
  };

  const removeContact = (index: number) => {
    setFormData(prev => ({
      ...prev,
      contacts: prev.contacts.filter((_, i) => i !== index)
    }));
  };

  const getContactIcon = (type: string) => {
    switch (type) {
      case 'whatsapp':
        return <MessageSquare className="h-5 w-5 text-green-500" />;
      case 'email':
        return <Mail className="h-5 w-5 text-blue-500" />;
      case 'instagram':
        return <Instagram className="h-5 w-5 text-purple-500" />;
      case 'phone':
        return <Phone className="h-5 w-5 text-gray-500" />;
      default:
        return <User className="h-5 w-5 text-gray-500" />;
    }
  };

  return (
    <div className="p-6 max-w-2xl mx-auto">
      <h2 className="text-2xl font-bold text-gray-900 mb-6">
        {user ? 'Editar Usuário' : 'Novo Usuário'}
      </h2>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Nome
          </label>
          <div className="relative">
            <User className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              className={`pl-10 w-full rounded-lg border ${
                errors.name ? 'border-red-300' : 'border-gray-300'
              } focus:ring-2 focus:ring-blue-500 focus:border-transparent py-2`}
              placeholder="Nome completo"
            />
            {errors.name && (
              <div className="mt-1 text-sm text-red-600 flex items-center">
                <AlertCircle className="h-4 w-4 mr-1" />
                {errors.name}
              </div>
            )}
          </div>
          <div className="mt-2">
            <label className="flex items-center space-x-2">
              <input
                type="checkbox"
                checked={formData.addEmailAsContact}
                onChange={(e) => setFormData(prev => ({ ...prev, addEmailAsContact: e.target.checked }))}
                className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <span className="text-sm text-gray-600">
                Adicionar este email como contato
              </span>
            </label>
          </div>
        </div>

        {!user && (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email
              </label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
                  className={`pl-10 w-full rounded-lg border ${
                    errors.email ? 'border-red-300' : 'border-gray-300'
                  } focus:ring-2 focus:ring-blue-500 focus:border-transparent py-2`}
                  placeholder="email@exemplo.com"
                />
                {errors.email && (
                  <div className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertCircle className="h-4 w-4 mr-1" />
                    {errors.email}
                  </div>
                )}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Senha
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                <input
                  type="password"
                  value={formData.password}
                  onChange={(e) => setFormData(prev => ({ ...prev, password: e.target.value }))}
                  className={`pl-10 w-full rounded-lg border ${
                    errors.password ? 'border-red-300' : 'border-gray-300'
                  } focus:ring-2 focus:ring-blue-500 focus:border-transparent py-2`}
                  placeholder="••••••"
                />
                {errors.password && (
                  <div className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertCircle className="h-4 w-4 mr-1" />
                    {errors.password}
                  </div>
                )}
              </div>
            </div>
          </>
        )}

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Função
          </label>
          <select
            value={formData.role}
            onChange={(e) => setFormData(prev => ({ ...prev, role: e.target.value }))}
            className="w-full rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent py-2 px-3"
          >
            <option value="user">Usuário</option>
            <option value="admin">Administrador</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            Contatos
          </label>

          <div className="space-y-3">
            {formData.contacts.map((contact, index) => (
              <div
                key={index}
                className="flex items-center space-x-2 bg-gray-50 p-2 rounded-lg"
              >
                {getContactIcon(contact.type)}
                <span className="flex-1 text-sm">{contact.identifier}</span>
                {contact.type !== 'user' && (
                  <button
                    type="button"
                    onClick={() => removeContact(index)}
                    className="text-red-500 hover:text-red-600"
                  >
                    Remover
                  </button>
                )}
              </div>
            ))}
          </div>

          <div className="mt-3 flex space-x-2">
            <select
              value={newContact.type}
              onChange={(e) => setNewContact(prev => ({ ...prev, type: e.target.value }))}
              className="rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent py-2 px-3"
            >
              <option value="whatsapp">WhatsApp</option>
              <option value="email">Email</option>
              <option value="instagram">Instagram</option>
              <option value="phone">Telefone</option>
            </select>
            <input
              type="text"
              value={newContact.identifier}
              onChange={(e) => setNewContact(prev => ({ ...prev, identifier: e.target.value }))}
              placeholder={
                newContact.type === 'whatsapp' ? '+55 11 99999-9999' :
                newContact.type === 'email' ? 'email@exemplo.com' :
                newContact.type === 'instagram' ? '@usuario' : '(11) 99999-9999'
              }
              className="flex-1 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent py-2 px-3"
            />
            <button
              type="button"
              onClick={addContact}
              className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200"
            >
              Adicionar
            </button>
          </div>
        </div>

        {errors.submit && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-600">
            {errors.submit}
          </div>
        )}

        <div className="flex justify-end space-x-3 pt-6 border-t">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-800"
            disabled={isSubmitting}
          >
            Cancelar
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed inline-flex items-center"
          >
            {isSubmitting ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                Salvando...
              </>
            ) : (
              'Salvar'
            )}
          </button>
        </div>
      </form>
    </div>
  );
}