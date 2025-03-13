/*
  # Melhorar validação de tenant

  1. Alterações
    - Adiciona índices únicos compostos
    - Melhora validações na função create_full_tenant
    - Adiciona verificações prévias
    
  2. Segurança
    - Garante unicidade de dados importantes
    - Previne duplicatas
*/

-- Remover função existente
DROP FUNCTION IF EXISTS create_full_tenant;

-- Adicionar índices únicos compostos
CREATE UNIQUE INDEX IF NOT EXISTS idx_tenants_document_type 
ON tenants (company_document, company_document_type) 
WHERE company_document IS NOT NULL AND company_document_type IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_tenant_email 
ON profiles (tenant_id, email);

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
  v_clean_document text;
BEGIN
  -- Validações iniciais
  IF p_tenant_name IS NULL OR length(trim(p_tenant_name)) < 3 THEN
    RAISE EXCEPTION 'Nome do tenant inválido';
  END IF;

  IF p_tenant_slug IS NULL OR length(trim(p_tenant_slug)) < 3 THEN
    RAISE EXCEPTION 'Identificador do tenant inválido';
  END IF;

  IF p_admin_email IS NULL OR length(trim(p_admin_email)) < 5 THEN
    RAISE EXCEPTION 'Email do administrador inválido';
  END IF;

  -- Limpar documento
  IF p_company_document IS NOT NULL THEN
    v_clean_document := regexp_replace(p_company_document, '\D', '', 'g');
    
    -- Validar formato do documento
    IF p_company_document_type = 'cpf' AND length(v_clean_document) != 11 THEN
      RAISE EXCEPTION 'CPF inválido';
    END IF;
    
    IF p_company_document_type = 'cnpj' AND length(v_clean_document) != 14 THEN
      RAISE EXCEPTION 'CNPJ inválido';
    END IF;
  END IF;

  -- Iniciar transação
  BEGIN
    -- Verificar duplicatas
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_admin_email) THEN
      RAISE EXCEPTION 'Email % já está em uso', p_admin_email;
    END IF;

    IF EXISTS (SELECT 1 FROM tenants WHERE slug = p_tenant_slug) THEN
      RAISE EXCEPTION 'Identificador % já está em uso', p_tenant_slug;
    END IF;

    IF v_clean_document IS NOT NULL AND EXISTS (
      SELECT 1 FROM tenants 
      WHERE company_document = v_clean_document 
      AND company_document_type = p_company_document_type
    ) THEN
      RAISE EXCEPTION 'Documento % já está cadastrado', 
        CASE p_company_document_type 
          WHEN 'cpf' THEN 'CPF'
          WHEN 'cnpj' THEN 'CNPJ'
        END;
    END IF;

    -- Gerar domínio
    v_domain := p_tenant_slug || '.financeai.com';
    
    IF EXISTS (SELECT 1 FROM licenses WHERE domain = v_domain) THEN
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
      trim(p_tenant_name),
      trim(p_tenant_slug),
      trim(p_company_name),
      v_clean_document,
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
      lower(trim(p_admin_email)), -- Normalizar email
      crypt(p_admin_password, gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      jsonb_build_object('name', trim(p_admin_name)),
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
      lower(trim(p_admin_email)), -- Normalizar email
      trim(p_admin_name),
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
      trim(p_tenant_name) || ' - Licença Principal',
      v_domain,
      trim(p_company_name),
      v_clean_document,
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

  EXCEPTION
    WHEN unique_violation THEN
      -- Identificar qual constraint foi violada
      CASE 
        WHEN SQLERRM LIKE '%auth.users_email_key%' THEN
          RAISE EXCEPTION 'Email % já está em uso', p_admin_email;
        WHEN SQLERRM LIKE '%tenants_slug_key%' THEN
          RAISE EXCEPTION 'Identificador % já está em uso', p_tenant_slug;
        WHEN SQLERRM LIKE '%licenses_domain_key%' THEN
          RAISE EXCEPTION 'Domínio % já está em uso', v_domain;
        WHEN SQLERRM LIKE '%idx_tenants_document_type%' THEN
          RAISE EXCEPTION 'Documento % já está cadastrado',
            CASE p_company_document_type 
              WHEN 'cpf' THEN 'CPF'
              WHEN 'cnpj' THEN 'CNPJ'
            END;
        ELSE
          RAISE EXCEPTION 'Já existe um registro com os mesmos dados';
      END CASE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Erro ao criar tenant: %', SQLERRM;
  END;
END;
$$;