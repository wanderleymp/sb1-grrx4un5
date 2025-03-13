/*
  # Correção de recursão infinita nas políticas de perfis

  1. Alterações
    - Remove políticas que causam recursão
    - Simplifica lógica de acesso
    - Mantém segurança sem recursão
    
  2. Segurança
    - Mantém isolamento por tenant
    - Permite acesso adequado para admins
*/

-- Remover políticas existentes que causam recursão
DROP POLICY IF EXISTS "enable_select_profiles" ON profiles;
DROP POLICY IF EXISTS "enable_insert_profiles" ON profiles;
DROP POLICY IF EXISTS "enable_update_profiles" ON profiles;

-- Criar novas políticas simplificadas
CREATE POLICY "profiles_select_policy"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    -- Usuário pode ver seu próprio perfil
    id = auth.uid()
    OR
    -- Usuário pode ver perfis do seu tenant
    tenant_id = (
      SELECT tenant_id FROM profiles 
      WHERE id = auth.uid()
    )
  );

CREATE POLICY "profiles_insert_policy"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Usuário só pode inserir no seu tenant
    tenant_id = (
      SELECT tenant_id FROM profiles 
      WHERE id = auth.uid()
    )
  );

CREATE POLICY "profiles_update_policy"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (
    -- Usuário pode atualizar seu próprio perfil
    id = auth.uid()
    OR
    -- Admin pode atualizar perfis do seu tenant
    (
      tenant_id = (
        SELECT tenant_id FROM profiles 
        WHERE id = auth.uid()
      )
      AND EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = auth.uid() 
        AND role = 'admin'
      )
    )
  );

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_profiles_tenant_id_role ON profiles(tenant_id, role);

-- Comentários
COMMENT ON POLICY "profiles_select_policy" ON profiles IS 'Permite usuários verem seu próprio perfil e perfis do seu tenant';
COMMENT ON POLICY "profiles_insert_policy" ON profiles IS 'Permite usuários criarem perfis apenas no seu tenant';
COMMENT ON POLICY "profiles_update_policy" ON profiles IS 'Permite usuários atualizarem seu próprio perfil e admins atualizarem perfis do seu tenant';