import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Brain, Menu, X, Search, ChevronDown, Settings, LogOut, User } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { NotificationCenter } from '../notifications/NotificationCenter';

export function Header() {
  const { user, signOut } = useAuth();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false);
  const navigate = useNavigate();

  const handleSignOut = async () => {
    try {
      await signOut();
      navigate('/login');
    } catch (error) {
      console.error('Erro ao fazer logout:', error);
    }
  };

  return (
    <header className="border-b bg-white sticky top-0 z-50">
      <div className="flex h-16 items-center px-4 container mx-auto">
        {/* Logo */}
        <Link to="/" className="flex items-center space-x-3">
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-lg blur opacity-75"></div>
            <div className="relative bg-gradient-to-r from-blue-600 to-indigo-600 p-2 rounded-lg">
              <Brain className="h-6 w-6 text-white" />
            </div>
          </div>
          <div className="flex flex-col">
            <span className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 text-transparent bg-clip-text">
              Finance AI
            </span>
            <span className="text-xs text-gray-500 -mt-1">Intelligent Solutions</span>
          </div>
        </Link>
        
        {/* Barra de Pesquisa */}
        <div className="hidden md:flex items-center space-x-4 ml-8 flex-1">
          <div className="relative max-w-md w-full">
            <Search className="h-5 w-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Buscar..."
              className="pl-10 pr-4 py-2 w-full rounded-lg border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-gray-50"
            />
          </div>
        </div>

        <nav className="ml-auto flex items-center space-x-4">
          <button className="lg:hidden" onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}>
            {isMobileMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
          </button>
          
          {/* Menu Desktop */}
          <div className="hidden lg:flex items-center space-x-6">
            <Link to="/dashboard" className="text-gray-600 hover:text-gray-900 font-medium">Dashboard</Link>
            <Link to="/saas" className="text-gray-600 hover:text-gray-900 font-medium">Gerenciamento SaaS</Link>
            <Link to="/permissions" className="text-gray-600 hover:text-gray-900 font-medium">Permissões</Link>
            <Link to="/users" className="text-gray-600 hover:text-gray-900 font-medium">Usuários</Link>
            <Link to="/chat" className="text-gray-600 hover:text-gray-900 font-medium">Chat</Link>
            <Link to="/crm" className="text-gray-600 hover:text-gray-900 font-medium">CRM</Link>
            <Link to="/tickets" className="text-gray-600 hover:text-gray-900 font-medium">Tickets</Link>
            <Link to="/financeiro" className="text-gray-600 hover:text-gray-900 font-medium">Financeiro</Link>
          </div>

          {/* Notificações */}
          <NotificationCenter />

          {/* Menu do Usuário */}
          <div className="relative">
            <button
              onClick={() => setIsUserMenuOpen(!isUserMenuOpen)}
              className="flex items-center space-x-3 p-2 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <div className="w-8 h-8 rounded-full bg-gradient-to-r from-blue-600 to-indigo-600 flex items-center justify-center">
                <span className="text-sm font-medium text-white">
                  {user?.name?.[0]?.toUpperCase() || 'U'}
                </span>
              </div>
              <div className="hidden md:block text-left">
                <p className="text-sm font-medium text-gray-700">{user?.name || 'Usuário'}</p>
                <p className="text-xs text-gray-500">{user?.role === 'admin' ? 'Administrador' : 'Usuário'}</p>
              </div>
              <ChevronDown className="h-4 w-4 text-gray-500" />
            </button>

            {/* Dropdown do Usuário */}
            {isUserMenuOpen && (
              <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-gray-100 py-1">
                <div className="px-4 py-2 border-b border-gray-100">
                  <p className="text-sm font-medium text-gray-900">{user?.name}</p>
                  <p className="text-xs text-gray-500">{user?.email}</p>
                </div>
                <button
                  onClick={() => navigate('/profile')}
                  className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                >
                  <User className="h-4 w-4 mr-3" />
                  Meu Perfil
                </button>
                <button
                  onClick={() => navigate('/settings')}
                  className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                >
                  <Settings className="h-4 w-4 mr-3" />
                  Configurações
                </button>
                <button
                  onClick={handleSignOut}
                  className="flex items-center w-full px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                >
                  <LogOut className="h-4 w-4 mr-3" />
                  Sair
                </button>
              </div>
            )}
          </div>
        </nav>
      </div>

      {/* Menu Mobile */}
      {isMobileMenuOpen && (
        <div className="lg:hidden border-t border-gray-200">
          <div className="py-2 px-4 space-y-1">
            <Link to="/dashboard" className="block py-2 px-4 text-gray-600 hover:bg-gray-50 rounded-lg">Dashboard</Link>
            <Link to="/saas" className="block py-2 px-4 text-gray-600 hover:bg-gray-50 rounded-lg">Gerenciamento SaaS</Link>
            <Link to="/permissions" className="block py-2 px-4 text-gray-600 hover:bg-gray-50 rounded-lg">Permissões</Link>
            <Link to="/users" className="block py-2 px-4 text-gray-600 hover:bg-gray-50 rounded-lg">Usuários</Link>
            <Link to="/chat" className="block py-2 px-4 text-gray-600 hover:bg-gray-50 rounded-lg">Chat</Link>
            <Link to="/crm" className="block py-2 px-4 text-gray-600 hover:bg-gray-50 rounded-lg">CRM</Link>
            <Link to="/tickets" className="block py-2 px-4 text-gray-600 hover:bg-gray-50 rounded-lg">Tickets</Link>
            <Link to="/financeiro" className="block py-2 px-4 text-gray-600 hover:bg-gray-50 rounded-lg">Financeiro</Link>
          </div>
        </div>
      )}
    </header>
  );
}