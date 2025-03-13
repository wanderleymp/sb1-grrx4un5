/*
  # Correção da estrutura de contatos de usuário

  1. Alterações
    - Ajusta políticas RLS para contatos
    - Adiciona índices para melhor performance
    - Corrige função de atualização de contatos
    - Garante unicidade correta dos contatos

  2. Segurança
    - Políticas RLS baseadas no tenant_id e owner_id
    - Proteção contra duplicatas
*/

-- Remover políticas existentes de contatos
DROP POLICY IF EXISTS "Usuários podem ver contatos do seu tenant" ON contacts;
DROP POLICY IF EXISTS "Usuários podem criar contatos no seu tenant" ON contacts;
DROP POLICY IF EXISTS "Usuários podem atualizar seus próprios contatos" ON contacts;
DROP POLICY IF EXISTS "Usuários podem deletar seus próprios contatos" ON contacts;

-- Criar novas políticas para contatos
CREATE POLICY "enable_select_contacts"
  ON contacts
  FOR SELECT
  TO authenticated
  USING (
    tenant_id = COALESCE(
      (current_setting('app.current_tenant_id', TRUE))::uuid,
      'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
    )
  );

CREATE POLICY "enable_insert_contacts"
  ON contacts
  FOR INSERT
  TO authenticated
  WITH CHECK (
    tenant_id = COALESCE(
      (current_setting('app.current_tenant_id', TRUE))::uuid,
      'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
    )
  );

CREATE POLICY "enable_update_contacts"
  ON contacts
  FOR UPDATE
  TO authenticated
  USING (
    owner_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tenant_id = contacts.tenant_id
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "enable_delete_contacts"
  ON contacts
  FOR DELETE
  TO authenticated
  USING (
    owner_id = auth.uid() AND
    NOT is_system
  );

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
        owner_id = p_user_id,
        name = EXCLUDED.name,
        metadata = EXCLUDED.metadata,
        display_order = EXCLUDED.display_order,
        updated_at = now();

      v_order := v_order + 1;
    EXCEPTION 
      WHEN OTHERS THEN
        RAISE WARNING 'Erro ao inserir contato %: %', v_contact->>'identifier', SQLERRM;
        CONTINUE;
    END;
  END LOOP;
END;
$$;

-- Criar índices adicionais
CREATE INDEX IF NOT EXISTS idx_contacts_owner_id_type ON contacts(owner_id, type);
CREATE INDEX IF NOT EXISTS idx_contacts_tenant_id_owner_id ON contacts(tenant_id, owner_id);

-- Comentários
COMMENT ON FUNCTION update_user_contacts IS 'Função para atualizar contatos com tratamento de duplicatas e ordem';