import { SupabaseAuthProvider } from './supabase-auth';
import { AuthProvider } from './types';

export * from './types';

// Aqui podemos facilmente trocar o provider de autenticação
export const authProvider: AuthProvider = new SupabaseAuthProvider();