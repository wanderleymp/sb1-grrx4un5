/*
  # Melhoria na visualização de contatos

  1. Alterações
    - Adiciona campo display_order para ordenar contatos
    - Atualiza funções para melhor organização visual
    - Melhora metadados dos contatos
    
  2. Dados
    - Organiza ordem de exibição dos contatos
    - Atualiza descrições para melhor clareza
*/

-- Adicionar campo para ordem de exibição
ALTER TABLE contacts ADD COLUMN IF NOT EXISTS display_order int DEFAULT 0;

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
      is_system,
      display_order
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
        'description', 'Usuário do sistema',
        'hidden', true
      ),
      'active',
      true,
      0
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
      is_system,
      display_order
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
        'description', 'Email principal',
        'hidden', false
      ),
      'active',
      true,
      1
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
  v_order int;
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

  -- Iniciar ordem após contatos do sistema
  v_order := 10;

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
        is_system,
        display_order
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
              'description', 'Email adicional',
              'hidden', false
            )
          WHEN v_contact->>'type' = 'whatsapp' THEN
            jsonb_build_object(
              'source', 'manual',
              'description', 'Contato WhatsApp',
              'hidden', false
            )
          WHEN v_contact->>'type' = 'phone' THEN
            jsonb_build_object(
              'source', 'manual',
              'description', 'Telefone',
              'hidden', false
            )
          ELSE
            jsonb_build_object(
              'source', 'manual',
              'description', 'Contato adicional',
              'hidden', false
            )
        END,
        'active',
        false,
        v_order
      )
      ON CONFLICT (tenant_id, type, identifier) 
      DO UPDATE SET
        owner_id = EXCLUDED.owner_id,
        name = EXCLUDED.name,
        metadata = EXCLUDED.metadata,
        display_order = EXCLUDED.display_order;

      v_order := v_order + 1;
    EXCEPTION 
      WHEN OTHERS THEN
        RAISE WARNING 'Erro ao inserir contato %: %', v_contact->>'identifier', SQLERRM;
        CONTINUE;
    END;
  END LOOP;
END;
$$;

-- Atualizar contatos existentes
UPDATE contacts
SET 
  display_order = CASE
    WHEN type = 'user' THEN 0
    WHEN type = 'email' AND (metadata->>'is_primary')::boolean = true THEN 1
    ELSE 10 + id::varchar::int % 90  -- Distribuir outros contatos entre 10-99
  END,
  metadata = jsonb_set(
    metadata,
    '{hidden}',
    CASE 
      WHEN type = 'user' THEN 'true'
      ELSE 'false'
    END::jsonb
  );

-- Criar índice para ordenação
CREATE INDEX IF NOT EXISTS idx_contacts_display_order ON contacts(display_order);

-- Comentários
COMMENT ON COLUMN contacts.display_order IS 'Ordem de exibição do contato na interface';
COMMENT ON FUNCTION create_user_contact IS 'Função para criar contatos principais do usuário com ordem de exibição';
COMMENT ON FUNCTION update_user_contacts IS 'Função para atualizar contatos adicionais com ordem personalizada';