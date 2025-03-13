/*
  # Correção das notificações

  1. Alterações
    - Ajusta políticas RLS para notificações
    - Adiciona índices para melhor performance
    - Garante que usuários só vejam suas próprias notificações
    
  2. Segurança
    - Políticas RLS baseadas no user_id
    - Proteção contra acesso não autorizado
*/

-- Remover políticas existentes
DROP POLICY IF EXISTS "Usuários podem ver suas próprias notificações" ON notifications;
DROP POLICY IF EXISTS "Usuários podem criar notificações" ON notifications;
DROP POLICY IF EXISTS "Usuários podem atualizar suas próprias notificações" ON notifications;
DROP POLICY IF EXISTS "Usuários podem deletar suas próprias notificações" ON notifications;

-- Criar novas políticas
CREATE POLICY "enable_select_notifications"
  ON notifications
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "enable_insert_notifications"
  ON notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "enable_update_notifications"
  ON notifications
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "enable_delete_notifications"
  ON notifications
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_read ON notifications(user_id, read);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_type ON notifications(user_id, type);

-- Comentários
COMMENT ON TABLE notifications IS 'Tabela para armazenar notificações dos usuários';
COMMENT ON COLUMN notifications.type IS 'Tipo da notificação: info, warning, error, success';
COMMENT ON COLUMN notifications.read IS 'Indica se a notificação foi lida pelo usuário';