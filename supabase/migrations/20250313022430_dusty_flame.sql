/*
  # Ajuste na criação automática de contatos de usuário

  1. Alterações
    - Atualiza função create_user_contact para criar ambos os contatos
    - Adiciona verificações de existência
    - Melhora tratamento de erros
    
  2. Segurança
    - Mantém políticas RLS existentes
    - Preserva integridade dos dados
*/

-- Atualizar função de criação de contato de usuário
CREATE OR REPLACE FUNCTION create_user_contact()
RETURNS trigger
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Criar contato principal (user)
  INSERT INTO contacts (
    tenant_id,
    owner_id,
    type,
    identifier,
    name,
    metadata,
    status
  )
  VALUES (
    NEW.tenant_id,
    NEW.id,
    'user',
    NEW.email,
    NEW.name,
    jsonb_build_object(
      'email', NEW.email,
      'role', NEW.role,
      'is_primary', true
    ),
    'active'
  )
  ON CONFLICT (tenant_id, type, identifier)
  DO UPDATE SET
    name = EXCLUDED.name,
    metadata = EXCLUDED.metadata;

  -- Criar contato de email
  INSERT INTO contacts (
    tenant_id,
    owner_id,
    type,
    identifier,
    name,
    metadata,
    status
  )
  VALUES (
    NEW.tenant_id,
    NEW.id,
    'email',
    NEW.email,
    NEW.name,
    jsonb_build_object(
      'is_primary', true,
      'verified', true,
      'source', 'registration'
    ),
    'active'
  )
  ON CONFLICT (tenant_id, type, identifier)
  DO UPDATE SET
    name = EXCLUDED.name,
    metadata = EXCLUDED.metadata;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log do erro (pode ser expandido conforme necessidade)
    RAISE NOTICE 'Erro ao criar contatos do usuário: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Atualizar função de atualização de contatos
CREATE OR REPLACE FUNCTION update_user_contacts(
  p_user_id uuid,
  p_contacts jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tenant_id uuid;
  v_user_email text;
  v_contact jsonb;
BEGIN
  -- Obter tenant_id e email do usuário
  SELECT tenant_id, email INTO v_tenant_id, v_user_email
  FROM profiles
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Usuário não encontrado';
  END IF;

  -- Remover apenas contatos adicionais (preservar user e email principal)
  DELETE FROM contacts
  WHERE owner_id = p_user_id
  AND type NOT IN ('user')
  AND NOT (
    type = 'email' 
    AND identifier = v_user_email 
    AND (metadata->>'is_primary')::boolean = true
  );

  -- Inserir novos contatos
  FOR v_contact IN SELECT * FROM jsonb_array_elements(p_contacts)
  LOOP
    -- Pular contatos principais
    CONTINUE WHEN (
      v_contact->>'type' = 'user'
      OR (
        v_contact->>'type' = 'email' 
        AND v_contact->>'identifier' = v_user_email
      )
    );

    -- Inserir novo contato
    INSERT INTO contacts (
      tenant_id,
      owner_id,
      type,
      identifier,
      name,
      metadata,
      status
    )
    VALUES (
      v_tenant_id,
      p_user_id,
      v_contact->>'type',
      v_contact->>'identifier',
      (SELECT name FROM profiles WHERE id = p_user_id),
      CASE 
        WHEN v_contact->>'type' = 'email' THEN 
          jsonb_build_object(
            'is_primary', false,
            'verified', false,
            'source', 'manual'
          )
        ELSE
          jsonb_build_object(
            'source', 'manual'
          )
      END,
      'active'
    );
  END LOOP;
END;
$$;

-- Criar contatos para usuários existentes que não os têm
DO $$
DECLARE
  v_profile RECORD;
BEGIN
  FOR v_profile IN SELECT * FROM profiles
  LOOP
    -- Verificar se já tem contato do tipo 'user'
    IF NOT EXISTS (
      SELECT 1 FROM contacts 
      WHERE owner_id = v_profile.id 
      AND type = 'user'
    ) THEN
      -- Criar contato user
      INSERT INTO contacts (
        tenant_id,
        owner_id,
        type,
        identifier,
        name,
        metadata,
        status
      )
      VALUES (
        v_profile.tenant_id,
        v_profile.id,
        'user',
        v_profile.email,
        v_profile.name,
        jsonb_build_object(
          'email', v_profile.email,
          'role', v_profile.role,
          'is_primary', true
        ),
        'active'
      )
      ON CONFLICT (tenant_id, type, identifier) DO NOTHING;
    END IF;

    -- Verificar se já tem contato do tipo 'email'
    IF NOT EXISTS (
      SELECT 1 FROM contacts 
      WHERE owner_id = v_profile.id 
      AND type = 'email'
      AND identifier = v_profile.email
    ) THEN
      -- Criar contato email
      INSERT INTO contacts (
        tenant_id,
        owner_id,
        type,
        identifier,
        name,
        metadata,
        status
      )
      VALUES (
        v_profile.tenant_id,
        v_profile.id,
        'email',
        v_profile.email,
        v_profile.name,
        jsonb_build_object(
          'is_primary', true,
          'verified', true,
          'source', 'migration'
        ),
        'active'
      )
      ON CONFLICT (tenant_id, type, identifier) DO NOTHING;
    END IF;
  END LOOP;
END;
$$;

-- Comentários
COMMENT ON FUNCTION create_user_contact IS 'Função para criar contatos principais do usuário (user e email)';
COMMENT ON FUNCTION update_user_contacts IS 'Função para atualizar contatos adicionais preservando os principais';