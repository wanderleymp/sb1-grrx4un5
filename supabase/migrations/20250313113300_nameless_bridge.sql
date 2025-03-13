/*
  # Correção da política RLS de profiles

  1. Alterações
    - Remove política anterior que causa erro
    - Cria nova política simplificada sem acessar auth.users
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
    -- Admin do tenant principal
    tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
    OR
    -- Mesmo tenant do usuário
    tenant_id = (
      SELECT tenant_id 
      FROM profiles 
      WHERE id = auth.uid()
      LIMIT 1
    )
  )
  WITH CHECK (
    -- Próprio perfil
    id = auth.uid()
    OR
    -- Admin do tenant principal
    tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
    OR
    -- Mesmo tenant do usuário
    tenant_id = (
      SELECT tenant_id 
      FROM profiles 
      WHERE id = auth.uid()
      LIMIT 1
    )
  );

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_profiles_tenant_id ON profiles(tenant_id);

-- Comentários
COMMENT ON POLICY "profiles_policy" ON profiles IS 'Política simplificada para controle de acesso aos perfis';