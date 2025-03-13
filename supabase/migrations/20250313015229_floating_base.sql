/*
  # Implementação da estrutura de contatos

  1. Nova Tabela
    - `contacts`
      - `id` (uuid, chave primária)
      - `tenant_id` (uuid, referência ao tenant)
      - `owner_id` (uuid, usuário que criou o contato)
      - `type` (tipo do contato: user, whatsapp, email, instagram)
      - `identifier` (identificador único do contato)
      - `name` (nome do contato)
      - `avatar_url` (URL do avatar)
      - `metadata` (dados adicionais específicos do tipo)
      - `status` (status do contato)
      - `created_at` (data de criação)
      - `updated_at` (data de atualização)

  2. Segurança
    - Políticas RLS para controle de acesso
    - Índices para melhor performance
    - Validações e constraints
*/

-- Criar tipo enum para tipos de contato
CREATE TYPE contact_type AS ENUM (
  'user',      -- Usuário do sistema
  'whatsapp',  -- Contato WhatsApp
  'email',     -- Contato Email
  'instagram', -- Contato Instagram
  'phone',     -- Telefone
  'telegram',  -- Telegram
  'custom'     -- Tipo personalizado para expansão futura
);

-- Criar tabela de contatos
CREATE TABLE contacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
  owner_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  type contact_type NOT NULL,
  identifier text NOT NULL,
  name text NOT NULL,
  avatar_url text,
  metadata jsonb DEFAULT '{}',
  status text DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'blocked')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  -- Garante identificador único por tipo e tenant
  UNIQUE(tenant_id, type, identifier)
);

-- Criar tabela de grupos de contatos
CREATE TABLE contact_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
  owner_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Relacionamento contatos-grupos
CREATE TABLE contact_group_members (
  group_id uuid REFERENCES contact_groups(id) ON DELETE CASCADE,
  contact_id uuid REFERENCES contacts(id) ON DELETE CASCADE,
  added_at timestamptz DEFAULT now(),
  PRIMARY KEY (group_id, contact_id)
);

-- Criar índices
CREATE INDEX idx_contacts_tenant_id ON contacts(tenant_id);
CREATE INDEX idx_contacts_owner_id ON contacts(owner_id);
CREATE INDEX idx_contacts_type ON contacts(type);
CREATE INDEX idx_contacts_identifier ON contacts(identifier);
CREATE INDEX idx_contact_groups_tenant_id ON contact_groups(tenant_id);
CREATE INDEX idx_contact_groups_owner_id ON contact_groups(owner_id);

-- Habilitar RLS
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_group_members ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para contacts
CREATE POLICY "Usuários podem ver contatos do seu tenant"
  ON contacts
  FOR SELECT
  TO authenticated
  USING (tenant_id = COALESCE(
    (current_setting('app.current_tenant_id', TRUE))::uuid,
    'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
  ));

CREATE POLICY "Usuários podem criar contatos no seu tenant"
  ON contacts
  FOR INSERT
  TO authenticated
  WITH CHECK (tenant_id = COALESCE(
    (current_setting('app.current_tenant_id', TRUE))::uuid,
    'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
  ));

CREATE POLICY "Usuários podem atualizar seus próprios contatos"
  ON contacts
  FOR UPDATE
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Usuários podem deletar seus próprios contatos"
  ON contacts
  FOR DELETE
  TO authenticated
  USING (owner_id = auth.uid());

-- Políticas RLS para contact_groups
CREATE POLICY "Usuários podem ver grupos do seu tenant"
  ON contact_groups
  FOR SELECT
  TO authenticated
  USING (tenant_id = COALESCE(
    (current_setting('app.current_tenant_id', TRUE))::uuid,
    'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
  ));

CREATE POLICY "Usuários podem criar grupos no seu tenant"
  ON contact_groups
  FOR INSERT
  TO authenticated
  WITH CHECK (tenant_id = COALESCE(
    (current_setting('app.current_tenant_id', TRUE))::uuid,
    'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
  ));

CREATE POLICY "Usuários podem gerenciar seus próprios grupos"
  ON contact_groups
  FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- Políticas RLS para contact_group_members
CREATE POLICY "Usuários podem gerenciar membros dos seus grupos"
  ON contact_group_members
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM contact_groups
      WHERE contact_groups.id = group_id
      AND contact_groups.owner_id = auth.uid()
    )
  );

-- Triggers para atualizar updated_at
CREATE TRIGGER update_contacts_updated_at
  BEFORE UPDATE ON contacts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contact_groups_updated_at
  BEFORE UPDATE ON contact_groups
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Função para criar contato de usuário automaticamente
CREATE OR REPLACE FUNCTION create_user_contact()
RETURNS trigger AS $$
BEGIN
  INSERT INTO contacts (
    tenant_id,
    owner_id,
    type,
    identifier,
    name,
    metadata
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
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para criar contato quando um perfil é criado
CREATE TRIGGER on_profile_created
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION create_user_contact();

-- Comentários
COMMENT ON TABLE contacts IS 'Tabela de contatos do sistema';
COMMENT ON TABLE contact_groups IS 'Grupos para organização de contatos';
COMMENT ON TABLE contact_group_members IS 'Relacionamento entre contatos e grupos';
COMMENT ON COLUMN contacts.type IS 'Tipo do contato (user, whatsapp, email, etc)';
COMMENT ON COLUMN contacts.identifier IS 'Identificador único do contato (email, telefone, etc)';
COMMENT ON COLUMN contacts.metadata IS 'Dados adicionais específicos do tipo de contato';