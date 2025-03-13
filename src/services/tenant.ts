import { supabase } from './supabase';

let currentTenantId: string | null = null;
let isInitializing = false;
const DEMO_TENANT_ID = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2';

interface Tenant {
  id: string;
  name: string;
  slug: string;
  settings: Record<string, any>;
  status: 'active' | 'inactive' | 'suspended';
  created_at: string;
  updated_at: string;
}

export async function getTenantId(): Promise<string> {
  // Evita múltiplas inicializações simultâneas
  if (isInitializing) {
    await new Promise(resolve => setTimeout(resolve, 100));
    return getTenantId();
  }

  if (currentTenantId) {
    return currentTenantId;
  }

  isInitializing = true;

  const storedTenantId = localStorage.getItem('tenant_id');
  if (storedTenantId) {
    currentTenantId = storedTenantId;
    isInitializing = false;
    return storedTenantId;
  }

  try {
    const { data: tenant, error } = await supabase
      .from('tenants')
      .select()
      .eq('id', DEMO_TENANT_ID)
      .single();

    if (error) {
      console.error('Erro Supabase:', {
        message: error.message,
        details: error.details,
        hint: error.hint
      });
      return handleNoTenant();
    }

    if (!tenant) {
      console.error('Nenhum tenant encontrado');
      return handleNoTenant();
    }

    currentTenantId = tenant.id;
    localStorage.setItem('tenant_id', tenant.id);
    return tenant.id;
  } catch (error) {
    if (error instanceof Error) {
      return handleNoTenant();
    }
    return handleNoTenant();
  } finally {
    isInitializing = false;
  }
}

function handleNoTenant(): string {
  currentTenantId = DEMO_TENANT_ID;
  localStorage.setItem('tenant_id', DEMO_TENANT_ID);
  return DEMO_TENANT_ID;
}

export async function setCurrentTenant(tenantId: string): Promise<void> {
  currentTenantId = tenantId;
  localStorage.setItem('tenant_id', tenantId);
  
  // Define o tenant_id como header personalizado
  supabase.headers = {
    ...supabase.headers,
    'x-tenant-id': tenantId
  };
}