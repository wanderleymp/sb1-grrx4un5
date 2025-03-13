/*
  # Melhoria na visualização de contatos

  1. Alterações
    - Adiciona campo is_system para identificar contatos do sistema
    - Atualiza funções para marcar contatos principais
    - Melhora metadados dos contatos
    
  2. Dados
    - Marca contatos existentes apropriadamente
    - Atualiza metadados para melhor organização
*/

-- Adicionar campo is_system para identificar contatos do sistema
ALTER TABLE contacts ADD COLUMN IF NOT EXISTS is_system boolean DEFAULT false;

-- Atualizar função de criação de contato de usuário
CREATE OR REPLACE FUNCTION create_user_contact()
RETURNS trigger
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Criar contato principal (user)
  BEGIN
    INSERT INTO contacts (
      tenant_id,
      owner_id,
      type,
      identifier,
      name,
      metadata,
      status,
      is_system
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
        'is_primary', true,
        'description', 'Usuário do sistema'
      ),
      'active',
      true
    )
    ON CONFLICT (tenant_id, type, identifier) 
    DO UPDATE SET
      owner_id = EXCLUDED.owner_id,
      name = EXCLUDED.name,
      metadata = EXCLUDED.metadata,
      is_system = true;
  EXCEPTION 
    WHEN OTHERS THEN
      RAISE WARNING 'Erro ao criar contato user: %', SQLERRM;
  END;

  -- Criar contato de email principal
  BEGIN
    INSERT INTO contacts (
      tenant_id,
      owner_id,
      type,
      identifier,
      name,
      metadata,
      status,
      is_system
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
        'source', 'registration',
        'description', 'Email principal'
      ),
      'active',
      true
    )
    ON CONFLICT (tenant_id, type, identifier) 
    DO UPDATE SET
      owner_id = EXCLUDED.owner_id,
      name = EXCLUDED.name,
      metadata = EXCLUDED.metadata,
      is_system = true;
  EXCEPTION 
    WHEN OTHERS THEN
      RAISE WARNING 'Erro ao criar contato email: %', SQLERRM;
  END;

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

  -- Remover apenas contatos não-sistema
  DELETE FROM contacts
  WHERE owner_id = p_user_id
  AND is_system = false;

  -- Inserir novos contatos
  FOR v_contact IN SELECT * FROM jsonb_array_elements(p_contacts)
  LOOP
    -- Pular contatos do sistema
    CONTINUE WHEN (
      v_contact->>'type' = 'user'
      OR (
        v_contact->>'type' = 'email' 
        AND v_contact->>'identifier' = v_user_email
      )
    );

    -- Inserir ou atualizar contato
    BEGIN
      INSERT INTO contacts (
        tenant_id,
        owner_id,
        type,
        identifier,
        name,
        metadata,
        status,
        is_system
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
              'source', 'manual',
              'description', 'Email adicional'
            )
          WHEN v_contact->>'type' = 'whatsapp' THEN
            jsonb_build_object(
              'source', 'manual',
              'description', 'Contato WhatsApp'
            )
          WHEN v_contact->>'type' = 'phone' THEN
            jsonb_build_object(
              'source', 'manual',
              'description', 'Telefone'
            )
          ELSE
            jsonb_build_object(
              'source', 'manual',
              'description', 'Contato adicional'
            )
        END,
        'active',
        false
      )
      ON CONFLICT (tenant_id, type, identifier) 
      DO UPDATE SET
        owner_id = EXCLUDED.owner_id,
        name = EXCLUDED.name,
        metadata = EXCLUDED.metadata;
    EXCEPTION 
      WHEN OTHERS THEN
        RAISE WARNING 'Erro ao inserir contato %: %', v_contact->>'identifier', SQLERRM;
        CONTINUE;
    END;
  END LOOP;
END;
$$;

-- Marcar contatos existentes do sistema
UPDATE contacts
SET is_system = true
WHERE type = 'user'
OR (type = 'email' AND (metadata->>'is_primary')::boolean = true);

-- Atualizar metadados dos contatos existentes
UPDATE contacts
SET metadata = jsonb_set(
  metadata,
  '{description}',
  CASE 
    WHEN type = 'user' THEN '"Usuário do sistema"'
    WHEN type = 'email' AND (metadata->>'is_primary')::boolean = true THEN '"Email principal"'
    WHEN type = 'email' THEN '"Email adicional"'
    WHEN type = 'whatsapp' THEN '"Contato WhatsApp"'
    WHEN type = 'phone' THEN '"Telefone"'
    ELSE '"Contato adicional"'
  END::jsonb
)
WHERE metadata->>'description' IS NULL;

-- Comentários
COMMENT ON COLUMN contacts.is_system IS 'Indica se é um contato do sistema (não pode ser removido)';
COMMENT ON FUNCTION create_user_contact IS 'Função para criar contatos principais do usuário com melhor organização';
COMMENT ON FUNCTION update_user_contacts IS 'Função para atualizar contatos adicionais preservando contatos do sistema';