/*
  # Correção da criação de perfil no create_full_tenant

  1. Alterações
    - Adiciona verificação de existência do perfil
    - Melhora tratamento de erros
    - Adiciona transação para garantir consistência
    
  2. Segurança
    - Mantém validações
    - Garante integridade dos dados
*/

-- Remover função existente
DROP FUNCTION IF EXISTS create_full_tenant;

-- Criar nova função com tratamento de erros
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
  -- Iniciar transação
  BEGIN
    -- Verificar se já existe usuário com este email
    IF EXISTS (
      SELECT 1 FROM auth.users WHERE email = p_admin_email
    ) THEN
      RAISE EXCEPTION 'Já existe um usuário com este email';
    END IF;

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

    -- Gerar ID do admin
    v_admin_id := gen_random_uuid();
    
    -- Criar usuário admin
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      role,
      aud,
      created_at,
      updated_at
    )
    VALUES (
      v_admin_id,
      '00000000-0000-0000-0000-000000000000',
      p_admin_email,
      crypt(p_admin_password, gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      jsonb_build_object('name', p_admin_name),
      'authenticated',
      'authenticated',
      now(),
      now()
    );

    -- Criar perfil do admin
    INSERT INTO profiles (
      id,
      email,
      name,
      role,
      tenant_id,
      created_at,
      updated_at
    )
    VALUES (
      v_admin_id,
      p_admin_email,
      p_admin_name,
      'admin',
      v_tenant_id,
      now(),
      now()
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

  -- Tratar erros específicos
  EXCEPTION
    WHEN unique_violation THEN
      RAISE EXCEPTION 'Já existe um registro com os mesmos dados';
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Erro ao criar tenant: %', SQLERRM;
  END;
END;
$$;