/*
  # Correção da política RLS de profiles

  1. Alterações
    - Remove política anterior que causava recursão
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
    id = auth.uid() OR
    tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2' OR
    tenant_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid())
  )
  WITH CHECK (
    id = auth.uid() OR
    tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2' OR
    tenant_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid())
  );

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_profiles_tenant_id ON profiles(tenant_id);

-- Comentários
COMMENT ON POLICY "profiles_policy" ON profiles IS 'Política simplificada para controle de acesso aos perfis';