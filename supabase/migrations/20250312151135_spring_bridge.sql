/*
  # Ajuste de políticas RLS para profiles

  1. Alterações
    - Adiciona política para permitir inserção de novos perfis
    - Mantém política existente para leitura e atualização
  
  2. Segurança
    - Permite que novos usuários criem seus perfis
    - Mantém restrições de acesso para leitura/atualização
*/

-- Remover políticas existentes
DROP POLICY IF EXISTS "Usuários podem ver seus próprios perfis" ON profiles;
DROP POLICY IF EXISTS "Usuários podem atualizar seus próprios perfis" ON profiles;

-- Política para inserção de novos perfis
CREATE POLICY "Permitir criação de perfis"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Política para leitura de perfis
CREATE POLICY "Usuários podem ver seus próprios perfis"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = id OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND profiles.role = 'admin'
    )
  );

-- Política para atualização de perfis
CREATE POLICY "Usuários podem atualizar seus próprios perfis"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);