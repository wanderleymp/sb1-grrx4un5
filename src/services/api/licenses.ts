import { supabase } from '../supabase';
import { getTenantId } from '../../services/tenant';
import api from '../api';
import { useAuth } from '../../contexts/AuthContext';

export interface License {
  id: string;
  name: string;
  domain: string;
  company_name: string;
  tenant_id: string;
  owner_id: string;
  document?: string;
  document_type?: 'cpf' | 'cnpj';
  modules: string[];
  expires_at?: string;
  primary_color: string;
  status: 'active' | 'inactive' | 'suspended';
  created_at: string;
  updated_at: string;
}

interface CreateLicenseDTO {
  name: string;
  domain: string;
  companyName: string;
  document?: string;
  documentType?: 'cpf' | 'cnpj';
  modules: string[];
  expiresAt?: string;
  primaryColor: string;
}

class LicenseAPI {
  async create(data: CreateLicenseDTO): Promise<License> {
    const tenantId = await getTenantId();
    const { user } = useAuth();
    if (!user) throw new Error('Usuário não autenticado');
    
    // Define o tenant_id como header personalizado
    supabase.headers = {
      ...supabase.headers,
      'x-tenant-id': tenantId
    };
    
    const { data: license, error } = await supabase
      .from('licenses')
      .insert({
        tenant_id: tenantId,
        owner_id: user.id,
        name: data.name,
        domain: data.domain,
        company_name: data.companyName,
        document: data.document,
        document_type: data.documentType,
        modules: data.modules,
        expires_at: data.expiresAt,
        primary_color: data.primaryColor,
        status: 'active'
      })
      .select()
      .single();

    if (error) {
      console.error('Erro Supabase:', error);
      throw new Error('Não foi possível criar a licença');
    }

    return license;
  }

  async findAll(): Promise<License[]> {
    const tenantId = await getTenantId();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      throw new Error('Usuário não autenticado');
    }
    
    // Define o tenant_id como header personalizado
    supabase.headers = {
      ...supabase.headers,
      'x-tenant-id': tenantId
    };
    
    if (!tenantId) {
      return [];
    }
    
    const { data, error } = await supabase
      .from('licenses')
      .select('*')
      .eq('owner_id', user.id)
      .eq('tenant_id', tenantId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Erro ao buscar licenças:', error);
      return [];
    }

    return data || [];
  }

  async findOne(id: string): Promise<License> {
    const { data, error } = await supabase
      .from('licenses')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      console.error('Erro ao buscar licença:', error);
      throw new Error('Não foi possível buscar a licença');
    }

    return data;
  }

  async update(id: string, data: Partial<CreateLicenseDTO>): Promise<License> {
    const { data: license, error } = await supabase
      .from('licenses')
      .update({
        name: data.name,
        domain: data.domain,
        company_name: data.companyName,
        document: data.document,
        document_type: data.documentType,
        modules: data.modules,
        expires_at: data.expiresAt,
        primary_color: data.primaryColor
      })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Erro ao atualizar licença:', error);
      throw new Error('Não foi possível atualizar a licença');
    }

    return license;
  }

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('licenses')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('Erro ao deletar licença:', error);
      throw new Error('Não foi possível deletar a licença');
    }
  }

  async consultarCNPJ(cnpj: string) {
    const response = await api.get(`/person/cnpj/${cnpj}`);
    return response.data;
  }
}

export const licenseAPI = new LicenseAPI();