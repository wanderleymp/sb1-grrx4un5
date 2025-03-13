/*
  # Correção de recursão infinita nas políticas de perfis

  1. Alterações
    - Remove políticas que causam recursão
    - Simplifica lógica de acesso
    - Usa subqueries otimizadas
    
  2. Segurança
    - Mantém isolamento por tenant
    - Permite acesso adequado para admins
*/

-- Remover políticas existentes
DROP POLICY IF EXISTS "enable_profiles_select" ON profiles;
DROP POLICY IF EXISTS "enable_profiles_insert" ON profiles;
DROP POLICY IF EXISTS "enable_profiles_update" ON profiles;
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;

-- Remover função que causa recursão
DROP FUNCTION IF EXISTS get_user_tenant_id();

-- Criar novas políticas simplificadas
CREATE POLICY "profiles_access_policy"
  ON profiles
  FOR ALL
  TO authenticated
  USING (
    -- Próprio perfil
    id = auth.uid()
    OR
    -- Admin do tenant principal vê e gerencia todos
    EXISTS (
      SELECT 1 
      FROM profiles p 
      WHERE p.id = auth.uid() 
      AND p.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND p.role = 'admin'
    )
    OR
    -- Admin do tenant vê e gerencia usuários do seu tenant
    EXISTS (
      SELECT 1 
      FROM profiles p 
      WHERE p.id = auth.uid() 
      AND p.tenant_id = profiles.tenant_id
      AND p.role = 'admin'
    )
  )
  WITH CHECK (
    -- Próprio perfil
    id = auth.uid()
    OR
    -- Admin do tenant principal pode criar/editar em qualquer tenant
    EXISTS (
      SELECT 1 
      FROM profiles p 
      WHERE p.id = auth.uid() 
      AND p.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND p.role = 'admin'
    )
    OR
    -- Admin do tenant pode criar/editar no seu tenant
    EXISTS (
      SELECT 1 
      FROM profiles p 
      WHERE p.id = auth.uid() 
      AND p.tenant_id = profiles.tenant_id
      AND p.role = 'admin'
    )
  );

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_profiles_tenant_id_role ON profiles(tenant_id, role);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Comentários
COMMENT ON POLICY "profiles_access_policy" ON profiles IS 'Controla acesso aos perfis com permissões especiais para admins';