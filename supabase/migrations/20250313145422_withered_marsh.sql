/*
  # Correção de validações para registros duplicados

  1. Alterações
    - Adiciona validações específicas para cada tipo de registro
    - Melhora mensagens de erro
    - Adiciona verificação de slug único
    
  2. Segurança
    - Mantém transação para consistência
    - Melhora tratamento de erros
*/

-- Remover função existente
DROP FUNCTION IF EXISTS create_full_tenant;

-- Criar nova função com validações melhoradas
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
  v_domain text;
BEGIN
  -- Iniciar transação
  BEGIN
    -- Validar email
    IF EXISTS (
      SELECT 1 FROM auth.users WHERE email = p_admin_email
    ) THEN
      RAISE EXCEPTION 'Email % já está em uso', p_admin_email;
    END IF;

    -- Validar slug
    IF EXISTS (
      SELECT 1 FROM tenants WHERE slug = p_tenant_slug
    ) THEN
      RAISE EXCEPTION 'Identificador % já está em uso', p_tenant_slug;
    END IF;

    -- Validar documento se fornecido
    IF p_company_document IS NOT NULL AND length(p_company_document) > 0 THEN
      IF EXISTS (
        SELECT 1 FROM tenants 
        WHERE company_document = p_company_document 
        AND company_document_type = p_company_document_type
      ) THEN
        RAISE EXCEPTION 'Documento % já está cadastrado', p_company_document;
      END IF;
    END IF;

    -- Gerar domínio
    v_domain := p_tenant_slug || '.financeai.com';

    -- Validar domínio
    IF EXISTS (
      SELECT 1 FROM licenses WHERE domain = v_domain
    ) THEN
      RAISE EXCEPTION 'Domínio % já está em uso', v_domain;
    END IF;

    -- Criar tenant
    INSERT INTO tenants (
      name,
      slug,
      company_name,
      company_document,
      company_document_type,
      status,
      created_at,
      updated_at
    )
    VALUES (
      p_tenant_name,
      p_tenant_slug,
      p_company_name,
      p_company_document,
      p_company_document_type,
      'active',
      now(),
      now()
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
      limits,
      created_at,
      updated_at
    )
    VALUES (
      p_tenant_name || ' - Licença Principal',
      v_domain,
      p_company_name,
      p_company_document,
      p_company_document_type,
      p_license_modules,
      '#3B82F6',
      'active',
      v_tenant_id,
      v_admin_id,
      p_license_features,
      p_license_limits,
      now(),
      now()
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
      -- Tentar identificar qual constraint foi violada
      CASE 
        WHEN SQLERRM LIKE '%auth.users_email_key%' THEN
          RAISE EXCEPTION 'Email % já está em uso', p_admin_email;
        WHEN SQLERRM LIKE '%tenants_slug_key%' THEN
          RAISE EXCEPTION 'Identificador % já está em uso', p_tenant_slug;
        WHEN SQLERRM LIKE '%licenses_domain_key%' THEN
          RAISE EXCEPTION 'Domínio % já está em uso', v_domain;
        ELSE
          RAISE EXCEPTION 'Já existe um registro com os mesmos dados';
      END CASE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Erro ao criar tenant: %', SQLERRM;
  END;
END;
$$;