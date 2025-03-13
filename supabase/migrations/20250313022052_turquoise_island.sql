/*
  # Ajuste na criação e atualização de contatos de usuário

  1. Alterações
    - Atualiza função create_user_contact para criar contato de email
    - Melhora função update_user_contacts para preservar contatos principais
    - Adiciona validações e tratamento de erros

  2. Segurança
    - Mantém políticas RLS existentes
    - Garante integridade dos dados
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
      'role', NEW.role
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
      'primary', true,
      'verified', true
    ),
    'active'
  )
  ON CONFLICT (tenant_id, type, identifier)
  DO UPDATE SET
    name = EXCLUDED.name,
    metadata = EXCLUDED.metadata;

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
  AND NOT (type = 'email' AND identifier = v_user_email);

  -- Inserir novos contatos
  FOR v_contact IN SELECT * FROM jsonb_array_elements(p_contacts)
  LOOP
    -- Pular se for contato do tipo user
    CONTINUE WHEN (v_contact->>'type' = 'user');
    
    -- Pular se for o email principal
    CONTINUE WHEN (v_contact->>'type' = 'email' AND v_contact->>'identifier' = v_user_email);

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
          jsonb_build_object('verified', false)
        ELSE
          '{}'::jsonb
      END,
      'active'
    );
  END LOOP;
END;
$$;

-- Comentários
COMMENT ON FUNCTION create_user_contact IS 'Função para criar contato principal do usuário e seu email';
COMMENT ON FUNCTION update_user_contacts IS 'Função para atualizar contatos adicionais do usuário';