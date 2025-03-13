/*
  # Sistema de Chat (Correção)

  1. Nova Tabela
    - `chat_rooms`: Salas de chat
      - `id` (uuid, chave primária)
      - `name` (texto, nome da sala)
      - `type` (texto, tipo da sala: direct, group)
      - `tenant_id` (uuid, referência a tenants)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

    - `chat_participants`: Participantes das salas
      - `room_id` (uuid, referência a chat_rooms)
      - `user_id` (uuid, referência a profiles)
      - `joined_at` (timestamp)

    - `chat_messages`: Mensagens
      - `id` (uuid, chave primária)
      - `room_id` (uuid, referência a chat_rooms)
      - `user_id` (uuid, referência a profiles)
      - `content` (texto, conteúdo da mensagem)
      - `type` (texto, tipo da mensagem: text, image, file)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Segurança
    - RLS habilitado em todas as tabelas
    - Políticas baseadas em tenant_id
*/

-- Criar tabela de salas de chat
CREATE TABLE chat_rooms (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    type text NOT NULL CHECK (type IN ('direct', 'group')),
    tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Criar tabela de participantes
CREATE TABLE chat_participants (
    room_id uuid REFERENCES chat_rooms(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (room_id, user_id)
);

-- Criar tabela de mensagens
CREATE TABLE chat_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id uuid REFERENCES chat_rooms(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    content text NOT NULL,
    type text NOT NULL CHECK (type IN ('text', 'image', 'file')) DEFAULT 'text',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Criar índices para melhor performance
CREATE INDEX idx_chat_rooms_tenant_id ON chat_rooms(tenant_id);
CREATE INDEX idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at DESC);
CREATE INDEX idx_chat_participants_user_id ON chat_participants(user_id);

-- Habilitar RLS
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Políticas para chat_rooms
CREATE POLICY "enable_tenant_access_chat_rooms"
    ON chat_rooms
    FOR ALL
    TO authenticated
    USING (
        tenant_id = COALESCE(
            (current_setting('app.current_tenant_id', TRUE))::uuid,
            'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
        )
    )
    WITH CHECK (
        tenant_id = COALESCE(
            (current_setting('app.current_tenant_id', TRUE))::uuid,
            'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
        )
    );

-- Políticas para chat_participants
CREATE POLICY "enable_tenant_access_chat_participants"
    ON chat_participants
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM chat_rooms
            WHERE chat_rooms.id = room_id
            AND chat_rooms.tenant_id = COALESCE(
                (current_setting('app.current_tenant_id', TRUE))::uuid,
                'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
            )
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM chat_rooms
            WHERE chat_rooms.id = room_id
            AND chat_rooms.tenant_id = COALESCE(
                (current_setting('app.current_tenant_id', TRUE))::uuid,
                'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
            )
        )
    );

-- Políticas para chat_messages
CREATE POLICY "enable_tenant_access_chat_messages"
    ON chat_messages
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM chat_rooms
            WHERE chat_rooms.id = room_id
            AND chat_rooms.tenant_id = COALESCE(
                (current_setting('app.current_tenant_id', TRUE))::uuid,
                'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
            )
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM chat_rooms
            WHERE chat_rooms.id = room_id
            AND chat_rooms.tenant_id = COALESCE(
                (current_setting('app.current_tenant_id', TRUE))::uuid,
                'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
            )
        )
    );

-- Triggers para atualizar updated_at
CREATE TRIGGER update_chat_rooms_updated_at
    BEFORE UPDATE ON chat_rooms
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_messages_updated_at
    BEFORE UPDATE ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentários
COMMENT ON TABLE chat_rooms IS 'Salas de chat do sistema';
COMMENT ON TABLE chat_participants IS 'Participantes das salas de chat';
COMMENT ON TABLE chat_messages IS 'Mensagens enviadas nas salas de chat';