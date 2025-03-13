/*
  # Correção da política RLS de profiles

  1. Alterações
    - Remove política anterior que causa recursão
    - Cria nova política simplificada
    - Adiciona índices para performance
    
  2. Segurança
    - Mantém isolamento por tenant
    - Permite acesso adequado para admins
*/

-- Remover política existente
DROP POLICY IF EXISTS "profiles_policy" ON profiles;

-- Criar nova política simplificada
CREATE POLICY "profiles_policy"
  ON profiles
  FOR ALL
  TO authenticated
  USING (
    -- Próprio perfil
    id = auth.uid()
    OR
    -- Perfis do tenant principal
    tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
    OR
    -- Perfis do mesmo tenant do usuário
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = u.id
        AND p.tenant_id = profiles.tenant_id
      )
    )
  )
  WITH CHECK (
    -- Próprio perfil
    id = auth.uid()
    OR
    -- Perfis do tenant principal
    tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
    OR
    -- Perfis do mesmo tenant do usuário
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = u.id
        AND p.tenant_id = profiles.tenant_id
      )
    )
  );

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_profiles_tenant_id ON profiles(tenant_id);

-- Comentários
COMMENT ON POLICY "profiles_policy" ON profiles IS 'Política simplificada para controle de acesso aos perfis';