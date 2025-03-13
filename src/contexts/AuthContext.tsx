import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, authProvider } from '../services/auth';
import { useNavigate } from 'react-router-dom';

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, data?: Record<string, any>) => Promise<void>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    checkUser();
  }, []);

  async function checkUser() {
    try {
      const user = await authProvider.getUser();
      setUser(user);
    } catch (error) {
      console.error('Erro ao verificar usuário:', error);
    } finally {
      setIsLoading(false);
    }
  }

  async function signIn(email: string, password: string) {
    const { user, error } = await authProvider.signIn(email, password);
    
    if (error) throw error;
    if (user) {
      setUser(user);
      navigate('/dashboard');
    }
  }

  async function signUp(email: string, password: string, data?: Record<string, any>) {
    const { user, error } = await authProvider.signUp(email, password, data);
    
    if (error) throw error;
    if (user) {
      setUser(user);
      navigate('/dashboard');
    }
  }

  async function signOut() {
    await authProvider.signOut();
    setUser(null);
    navigate('/login');
  }

  async function resetPassword(email: string) {
    await authProvider.resetPassword(email);
  }

  const value = {
    user,
    isLoading,
    signIn,
    signUp,
    signOut,
    resetPassword
  };

  return (
    <AuthContext.Provider value={value}>
      {!isLoading && children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}