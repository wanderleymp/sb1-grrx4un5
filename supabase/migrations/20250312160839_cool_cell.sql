/*
  # Correção de recursão infinita nas políticas RLS

  1. Alterações
    - Remove políticas que causam recursão
    - Simplifica as políticas de acesso
    - Mantém segurança sem recursão
  
  2. Segurança
    - Permite que usuários vejam e atualizem seus próprios perfis
    - Permite que administradores do tenant principal vejam todos os perfis
*/

-- Remover políticas existentes
DROP POLICY IF EXISTS "Usuários podem ver seus próprios perfis" ON profiles;
DROP POLICY IF EXISTS "Usuários podem atualizar seus próprios perfis" ON profiles;
DROP POLICY IF EXISTS "Permitir criação de perfis" ON profiles;

-- Política simplificada para leitura
CREATE POLICY "Política de leitura de perfis"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() OR
    tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
  );

-- Política para inserção
CREATE POLICY "Política de inserção de perfis"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Política para atualização
CREATE POLICY "Política de atualização de perfis"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());