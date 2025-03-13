/*
  # Corrigir políticas de perfil

  1. Alterações
    - Remover políticas recursivas
    - Simplificar lógica de acesso
    - Garantir acesso básico para autenticação

  2. Segurança
    - Manter RLS ativo
    - Permitir acesso básico para autenticação
    - Evitar recursão nas políticas
*/

-- Remover políticas existentes para evitar conflitos
DROP POLICY IF EXISTS "Permitir inserção de perfis via trigger" ON profiles;
DROP POLICY IF EXISTS "Permitir leitura de perfis" ON profiles;
DROP POLICY IF EXISTS "Permitir atualização do próprio perfil" ON profiles;

-- Política básica para leitura
CREATE POLICY "enable_read_access_profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (true);

-- Política para inserção via trigger
CREATE POLICY "enable_insert_profiles"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Política para atualização do próprio perfil
CREATE POLICY "enable_update_own_profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());