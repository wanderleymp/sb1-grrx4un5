import { supabase } from '../supabase';
import { AuthProvider, AuthResponse, User } from './types';
import { setCurrentTenant } from '../tenant';

export class SupabaseAuthProvider implements AuthProvider {
  async signIn(email: string, password: string): Promise<AuthResponse> {
    try {
      const { data: { user, session }, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) throw error;

      if (user) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

        if (profile?.tenant_id) {
          await setCurrentTenant(profile.tenant_id);
        }

        return {
          user: this.mapUser(user, profile),
          session
        };
      }

      return { user: null, session: null };
    } catch (error) {
      console.error('Erro ao fazer login:', error);
      return {
        user: null,
        session: null,
        error: error instanceof Error ? error : new Error('Erro ao fazer login')
      };
    }
  }

  async signUp(email: string, password: string, data?: Record<string, any>): Promise<AuthResponse> {
    try {
      const { data: { user, session }, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            name: data?.name,
            role: 'user',
          }
        }
      });

      if (error) throw error;

      if (user) {
        // Aguardar um momento para o trigger criar o perfil
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Tentar buscar o perfil recém-criado
        try {
          const { data: profile } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .single();
            
          return {
            user: this.mapUser(user, profile),
            session
          };
        } catch (profileError) {
          // Se não conseguir buscar o perfil, retorna usuário com valores padrão
          return {
            user: {
              id: user.id,
              email: user.email!,
              name: data?.name || 'Usuário',
              role: 'user',
              tenant_id: 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
            },
            session
          };
        }
      }

      return { user: null, session: null };
    } catch (error) {
      console.error('Erro ao criar conta:', error);
      
      if (error instanceof Error) {
        return {
          user: null,
          session: null,
          error
        };
      }
      
      return {
        user: null,
        session: null,
        error: new Error('Erro ao criar conta')
      };
    }
  }

  async signOut(): Promise<void> {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
  }

  async resetPassword(email: string): Promise<void> {
    const { error } = await supabase.auth.resetPasswordForEmail(email);
    if (error) throw error;
  }

  async updatePassword(password: string): Promise<void> {
    const { error } = await supabase.auth.updateUser({ password });
    if (error) throw error;
  }

  async getUser(): Promise<User | null> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) return null;

      try {
        const { data: profile } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

        return this.mapUser(user, profile);
      } catch (error) {
        console.error('Erro ao buscar perfil:', error);
        // Retorna usuário com valores padrão se não encontrar o perfil
        return {
          id: user.id,
          email: user.email!,
          name: user.user_metadata?.name || 'Usuário',
          role: 'user',
          tenant_id: 'e97f27c9-8d4e-4e8c-a172-7846995c38b2' // Tenant padrão
        };
      }
    } catch (error) {
      console.error('Erro ao buscar usuário:', error);
      return null;
    }
  }

  private mapUser(supabaseUser: any, profile?: any): User {
    return {
      id: supabaseUser.id,
      email: supabaseUser.email || '',
      name: profile?.name || supabaseUser.user_metadata?.name || 'Usuário',
      avatar_url: profile?.avatar_url,
      role: profile?.role || 'user',
      tenant_id: profile?.tenant_id || 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
    };
  }
}