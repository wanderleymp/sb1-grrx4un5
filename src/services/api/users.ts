import { supabase } from '../supabase';
import { getTenantId } from '../tenant';
import { notificationAPI } from './notifications';

export interface User {
  id: string;
  email: string;
  name: string;
  avatar_url?: string;
  role: 'admin' | 'user';
  tenant_id: string;
  created_at: string;
  contacts: {
    type: string;
    identifier: string;
    metadata: any;
  }[];
}

export interface CreateUserDTO {
  email: string;
  name: string;
  role: 'admin' | 'user';
  password: string;
  contacts?: {
    type: string;
    identifier: string;
  }[];
}

export interface UpdateUserDTO {
  name?: string;
  role?: 'admin' | 'user';
  contacts?: {
    type: string;
    identifier: string;
  }[];
}

class UserAPI {
  async findAll(): Promise<User[]> {
    const tenantId = await getTenantId();
    
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select(`
        *,
        contacts(
          type,
          identifier,
          metadata,
          display_order
        )
      `)
      .eq('tenant_id', tenantId)
      .order('created_at', { ascending: false });

    if (profilesError) {
      console.error('Erro ao buscar usuários:', profilesError);
      throw new Error('Não foi possível buscar os usuários');
    }

    // Filtrar e ordenar contatos após buscar os perfis
    const usersWithFilteredContacts = profiles?.map(profile => ({
      ...profile,
      contacts: profile.contacts
        ?.filter(contact => !(contact.metadata?.hidden))
        ?.sort((a, b) => (a.display_order || 0) - (b.display_order || 0)) || []
    })) || [];

    return usersWithFilteredContacts;
  }

  async create(data: CreateUserDTO): Promise<User> {
    const tenantId = await getTenantId();

    // Criar usuário no Auth
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: data.email,
      password: data.password,
      options: {
        data: {
          name: data.name,
          role: data.role
        }
      }
    });

    if (authError) {
      console.error('Erro ao criar usuário:', authError);
      throw new Error('Não foi possível criar o usuário');
    }

    if (!authData.user) {
      throw new Error('Erro ao criar usuário');
    }

    // Aguardar trigger criar o perfil
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Buscar o perfil criado
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', authData.user.id)
      .single();

    if (profileError) {
      console.error('Erro ao buscar perfil:', profileError);
      throw new Error('Erro ao criar usuário');
    }

    // Criar contatos adicionais
    if (data.contacts?.length) {
      const { error: contactsError } = await supabase
        .from('contacts')
        .insert(
          data.contacts.map(contact => ({
            tenant_id: tenantId,
            owner_id: authData.user?.id,
            type: contact.type,
            identifier: contact.identifier,
            name: data.name
          }))
        );

      if (contactsError) {
        console.error('Erro ao criar contatos:', contactsError);
      }
    }

    // Notificar usuário
    try {
      await notificationAPI.create({
        user_id: authData.user.id,
        title: 'Bem-vindo ao Finance AI',
        message: 'Sua conta foi criada com sucesso. Explore todas as funcionalidades disponíveis.',
        type: 'success'
      });
    } catch (error) {
      console.error('Erro ao criar notificação:', error);
    }

    return profile;
  }

  async update(id: string, data: UpdateUserDTO): Promise<User> {
    try {
      // Primeiro verifica se o perfil existe no tenant atual
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', id)
        .maybeSingle();

      if (profileError || !profile) {
        throw new Error('Perfil não encontrado');
      }

      // Atualiza o perfil usando a função RPC
      const { data: updatedProfile, error: updateError } = await supabase
        .rpc('update_profile', {
          p_id: id,
          p_name: data.name,
          p_role: data.role
        });

      if (updateError) throw updateError;

      // Atualiza os contatos
      if (data.contacts?.length) {
        await supabase.rpc('update_user_contacts', {
          p_user_id: id,
          p_contacts: JSON.stringify(data.contacts)
        });
      }

      // Busca o perfil atualizado com os contatos
      const { data: finalProfile, error: finalError } = await supabase
        .from('profiles')
        .select(`
          *,
          contacts(*)
        `)
        .eq('id', id)
        .single();

      if (finalError) throw finalError;
      return finalProfile;
    } catch (error) {
      console.error('Erro ao atualizar usuário:', error);
      throw new Error('Não foi possível atualizar o usuário');
    }
  }
}

export const userAPI = new UserAPI();