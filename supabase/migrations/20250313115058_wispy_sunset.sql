/*
  # Ajustes para criação de tenant com licença e usuário

  1. Alterações
    - Adiciona campos para configuração inicial do tenant
    - Melhora campos de licença
    - Adiciona campos para usuário admin
    
  2. Segurança
    - Mantém políticas existentes
    - Adiciona validações
*/

-- Adicionar campos para configuração inicial do tenant
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS company_name text,
ADD COLUMN IF NOT EXISTS company_document text,
ADD COLUMN IF NOT EXISTS company_document_type text CHECK (company_document_type IN ('cpf', 'cnpj')),
ADD COLUMN IF NOT EXISTS company_email text,
ADD COLUMN IF NOT EXISTS company_phone text,
ADD COLUMN IF NOT EXISTS company_address jsonb DEFAULT '{}'::jsonb;

-- Adicionar campos para configuração da licença
ALTER TABLE licenses
ADD COLUMN IF NOT EXISTS features jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS limits jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS custom_settings jsonb DEFAULT '{}'::jsonb;

-- Criar função para criar tenant completo
CREATE OR REPLACE FUNCTION create_full_tenant(
  p_tenant_name text,
  p_tenant_slug text,
  p_company_name text,
  p_company_document text,
  p_company_document_type text,
  p_company_email text,
  p_company_phone text,
  p_company_address jsonb,
  p_admin_name text,
  p_admin_email text,
  p_admin_password text,
  p_license_modules text[],
  p_license_expires_at timestamptz DEFAULT NULL,
  p_license_features jsonb DEFAULT '{}'::jsonb,
  p_license_limits jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tenant_id uuid;
  v_admin_id uuid;
  v_license_id uuid;
BEGIN
  -- Criar tenant
  INSERT INTO tenants (
    name,
    slug,
    company_name,
    company_document,
    company_document_type,
    company_email,
    company_phone,
    company_address,
    status
  )
  VALUES (
    p_tenant_name,
    p_tenant_slug,
    p_company_name,
    p_company_document,
    p_company_document_type,
    p_company_email,
    p_company_phone,
    p_company_address,
    'active'
  )
  RETURNING id INTO v_tenant_id;

  -- Criar usuário admin
  INSERT INTO auth.users (
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    role,
    aud
  )
  VALUES (
    p_admin_email,
    crypt(p_admin_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('name', p_admin_name),
    'authenticated',
    'authenticated'
  )
  RETURNING id INTO v_admin_id;

  -- Criar perfil do admin
  INSERT INTO profiles (
    id,
    email,
    name,
    role,
    tenant_id
  )
  VALUES (
    v_admin_id,
    p_admin_email,
    p_admin_name,
    'admin',
    v_tenant_id
  );

  -- Criar licença
  INSERT INTO licenses (
    name,
    domain,
    company_name,
    document,
    document_type,
    modules,
    expires_at,
    primary_color,
    status,
    tenant_id,
    owner_id,
    features,
    limits
  )
  VALUES (
    p_tenant_name || ' - Licença Principal',
    p_tenant_slug || '.financeai.com',
    p_company_name,
    p_company_document,
    p_company_document_type,
    p_license_modules,
    p_license_expires_at,
    '#3B82F6',
    'active',
    v_tenant_id,
    v_admin_id,
    p_license_features,
    p_license_limits
  )
  RETURNING id INTO v_license_id;

  -- Retornar IDs criados
  RETURN jsonb_build_object(
    'tenant_id', v_tenant_id,
    'admin_id', v_admin_id,
    'license_id', v_license_id
  );
END;
$$;