import { supabase } from '../supabase';
import { useAuth } from '../../contexts/AuthContext';

export interface Tenant {
  id: string;
  name: string;
  slug: string;
  owner_id: string;
  settings: Record<string, any>;
  status: 'active' | 'inactive' | 'suspended';
  created_at: string;
  updated_at: string;
}

interface CreateTenantDTO {
  name: string;
  slug: string;
  settings?: Record<string, any>;
  company_name?: string;
  company_document?: string;
  company_document_type?: 'cpf' | 'cnpj';
  company_email?: string;
  company_phone?: string;
  company_address?: {
    street: string;
    number: string;
    complement?: string;
    neighborhood: string;
    city: string;
    state: string;
    zipCode: string;
  };
}

interface CreateFullTenantDTO {
  tenant: CreateTenantDTO;
  license: {
    modules: string[];
    expires_at?: string;
    features: Record<string, boolean>;
    limits: Record<string, number>;
  };
  admin: {
    name: string;
    email: string;
    password: string;
  };
}

class TenantAPI {
  async create(data: CreateTenantDTO): Promise<Tenant> {
    const { user } = useAuth();
    if (!user) throw new Error('Usuário não autenticado');

    const { data: tenant, error } = await supabase
      .from('tenants')
      .insert({
        name: data.name,
        slug: data.slug,
        owner_id: user.id,
        settings: data.settings || {},
        status: 'active'
      })
      .select()
      .single();

    if (error) {
      console.error('Erro ao criar tenant:', error);
      throw new Error('Não foi possível criar o tenant');
    }

    return tenant;
  }

  async createFull(data: CreateFullTenantDTO): Promise<{
    tenant: Tenant;
    license: License;
    admin: { id: string; email: string };
  }> {
    const { data: result, error } = await supabase
      .rpc('create_full_tenant', {
        p_tenant_name: data.tenant.name,
        p_tenant_slug: data.tenant.slug,
        p_company_name: data.tenant.company_name,
        p_company_document: data.tenant.company_document,
        p_company_document_type: data.tenant.company_document_type,
        p_company_email: data.tenant.company_email,
        p_company_phone: data.tenant.company_phone,
        p_company_address: data.tenant.company_address,
        p_admin_name: data.admin.name,
        p_admin_email: data.admin.email,
        p_admin_password: data.admin.password,
        p_license_modules: data.license.modules,
        p_license_expires_at: data.license.expires_at,
        p_license_features: data.license.features,
        p_license_limits: data.license.limits
      });

    if (error) {
      console.error('Erro ao criar tenant completo:', error);
      throw new Error('Não foi possível criar o tenant');
    }

    return result;
  }

  async findAll(): Promise<Tenant[]> {
    const { data, error } = await supabase
      .from('tenants')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Erro ao buscar tenants:', error);
      throw new Error('Não foi possível buscar os tenants');
    }

    return data || [];
  }

  async update(id: string, data: Partial<CreateTenantDTO>): Promise<Tenant> {
    const { data: tenant, error } = await supabase
      .from('tenants')
      .update({
        name: data.name,
        slug: data.slug,
        settings: data.settings
      })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Erro ao atualizar tenant:', error);
      throw new Error('Não foi possível atualizar o tenant');
    }

    return tenant;
  }

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('tenants')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('Erro ao deletar tenant:', error);
      throw new Error('Não foi possível deletar o tenant');
    }
  }
}

export const tenantAPI = new TenantAPI();