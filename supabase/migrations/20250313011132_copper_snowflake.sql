/*
  # Criar sistema de notificações

  1. Nova Tabela
    - `notifications`
      - `id` (uuid, chave primária)
      - `user_id` (uuid, referência ao usuário)
      - `title` (texto, título da notificação)
      - `message` (texto, mensagem da notificação)
      - `type` (texto, tipo da notificação)
      - `read` (booleano, status de leitura)
      - `created_at` (timestamp com timezone)

  2. Segurança
    - Habilitar RLS
    - Políticas para usuários autenticados
    - Garantir que usuários só vejam suas próprias notificações
*/

-- Criar tabela de notificações
CREATE TABLE notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    title text NOT NULL,
    message text NOT NULL,
    type text NOT NULL CHECK (type IN ('info', 'warning', 'error', 'success')),
    read boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Criar índice para melhorar performance de queries
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- Habilitar RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Usuários podem ver suas próprias notificações"
    ON notifications
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem criar notificações"
    ON notifications
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar suas próprias notificações"
    ON notifications
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem deletar suas próprias notificações"
    ON notifications
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- Comentários para documentação
COMMENT ON TABLE notifications IS 'Tabela para armazenar notificações dos usuários';
COMMENT ON COLUMN notifications.type IS 'Tipo da notificação: info, warning, error, success';
COMMENT ON COLUMN notifications.read IS 'Indica se a notificação foi lida pelo usuário';