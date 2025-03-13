/*
  # Correção da função create_full_tenant

  1. Alterações
    - Remove função existente
    - Recria com parâmetros corretos
    - Simplifica estrutura
    
  2. Segurança
    - Mantém validações
    - Preserva integridade dos dados
*/

-- Remover função existente
DROP FUNCTION IF EXISTS create_full_tenant;

-- Criar nova função com parâmetros corretos
CREATE OR REPLACE FUNCTION create_full_tenant(
  p_tenant_name text,
  p_tenant_slug text,
  p_company_name text,
  p_company_document text,
  p_company_document_type text,
  p_admin_name text,
  p_admin_email text,
  p_admin_password text,
  p_license_modules text[],
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
    status
  )
  VALUES (
    p_tenant_name,
    p_tenant_slug,
    p_company_name,
    p_company_document,
    p_company_document_type,
    'active'
  )
  RETURNING id INTO v_tenant_id;

  -- Criar usuário admin
  v_admin_id := gen_random_uuid();
  
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    role,
    aud
  )
  VALUES (
    v_admin_id,
    p_admin_email,
    crypt(p_admin_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('name', p_admin_name),
    'authenticated',
    'authenticated'
  );

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