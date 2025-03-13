/*
  # Correção de Políticas e Funções para Perfis e Contatos

  1. Alterações
    - Ajusta políticas RLS para perfis
    - Corrige função de criação de contato de usuário
    - Adiciona função para atualizar contatos
    - Atualiza políticas de contatos

  2. Segurança
    - Mantém RLS ativo
    - Ajusta políticas para permitir operações necessárias
*/

-- Remover políticas existentes de profiles
DROP POLICY IF EXISTS "enable_read_profiles" ON profiles;
DROP POLICY IF EXISTS "enable_insert_profiles" ON profiles;
DROP POLICY IF EXISTS "enable_update_profiles" ON profiles;

-- Criar novas políticas para profiles
CREATE POLICY "enable_read_profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING ((
    id = auth.uid() OR
    tenant_id = COALESCE(
      (current_setting('app.current_tenant_id', TRUE))::uuid,
      'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
    )
  ));

CREATE POLICY "enable_insert_profiles"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "enable_update_profiles"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role = 'admin'
      AND p.tenant_id = profiles.tenant_id
    )
  );

-- Atualizar função de criação de contato de usuário
CREATE OR REPLACE FUNCTION create_user_contact()
RETURNS trigger
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
  v_contact_exists boolean;
BEGIN
  -- Verificar se o contato já existe
  SELECT EXISTS (
    SELECT 1 FROM contacts
    WHERE tenant_id = NEW.tenant_id
    AND type = 'user'
    AND identifier = NEW.email
  ) INTO v_contact_exists;

  IF v_contact_exists THEN
    -- Atualizar contato existente
    UPDATE contacts
    SET
      owner_id = NEW.id,
      name = NEW.name,
      metadata = jsonb_build_object(
        'email', NEW.email,
        'role', NEW.role
      )
    WHERE
      tenant_id = NEW.tenant_id
      AND type = 'user'
      AND identifier = NEW.email;
  ELSE
    -- Criar novo contato
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
    );
  END IF;

  RETURN NEW;
END;
$$;

-- Função para atualizar contatos de um usuário
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
  v_contact jsonb;
BEGIN
  -- Obter tenant_id do usuário
  SELECT tenant_id INTO v_tenant_id
  FROM profiles
  WHERE id = p_user_id;

  -- Remover contatos existentes (exceto o contato de usuário)
  DELETE FROM contacts
  WHERE owner_id = p_user_id
  AND type != 'user';

  -- Inserir novos contatos
  FOR v_contact IN SELECT * FROM jsonb_array_elements(p_contacts)
  LOOP
    INSERT INTO contacts (
      tenant_id,
      owner_id,
      type,
      identifier,
      name,
      status
    )
    SELECT
      v_tenant_id,
      p_user_id,
      v_contact->>'type',
      v_contact->>'identifier',
      (SELECT name FROM profiles WHERE id = p_user_id),
      'active';
  END LOOP;
END;
$$;

-- Comentários
COMMENT ON FUNCTION update_user_contacts IS 'Função para atualizar os contatos de um usuário';
COMMENT ON FUNCTION create_user_contact IS 'Função para criar ou atualizar o contato principal do usuário';