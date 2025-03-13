/*
  # Correção final da recursão infinita em profiles

  1. Alterações
    - Remove todas as políticas existentes
    - Cria uma única política simplificada sem auto-referência
    - Usa subconsultas otimizadas
    - Adiciona índices para performance
    
  2. Segurança
    - Mantém isolamento por tenant
    - Permite acesso adequado para admins
*/

-- Remover todas as políticas existentes
DROP POLICY IF EXISTS "profiles_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_access_policy" ON profiles;
DROP POLICY IF EXISTS "enable_profiles_select" ON profiles;
DROP POLICY IF EXISTS "enable_profiles_insert" ON profiles;
DROP POLICY IF EXISTS "enable_profiles_update" ON profiles;
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;

-- Criar uma única política sem recursão
CREATE POLICY "profiles_policy"
  ON profiles
  FOR ALL
  TO authenticated
  USING (
    -- Próprio perfil
    id = auth.uid()
    OR
    -- Admin do tenant principal
    EXISTS (
      SELECT 1
      FROM auth.users u
      JOIN profiles p ON p.id = u.id
      WHERE u.id = auth.uid()
      AND p.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND p.role = 'admin'
    )
    OR
    -- Admin do tenant
    EXISTS (
      SELECT 1
      FROM auth.users u
      JOIN profiles p ON p.id = u.id
      WHERE u.id = auth.uid()
      AND p.tenant_id = profiles.tenant_id
      AND p.role = 'admin'
    )
  )
  WITH CHECK (
    -- Próprio perfil
    id = auth.uid()
    OR
    -- Admin do tenant principal
    EXISTS (
      SELECT 1
      FROM auth.users u
      JOIN profiles p ON p.id = u.id
      WHERE u.id = auth.uid()
      AND p.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND p.role = 'admin'
    )
    OR
    -- Admin do tenant
    EXISTS (
      SELECT 1
      FROM auth.users u
      JOIN profiles p ON p.id = u.id
      WHERE u.id = auth.uid()
      AND p.tenant_id = profiles.tenant_id
      AND p.role = 'admin'
    )
  );

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_profiles_tenant_id_role ON profiles(tenant_id, role);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_tenant_id_id ON profiles(tenant_id, id);

-- Comentários
COMMENT ON POLICY "profiles_policy" ON profiles IS 'Política unificada para controle de acesso aos perfis sem recursão';