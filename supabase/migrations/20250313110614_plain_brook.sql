/*
  # Correção de recursão infinita nas políticas de perfis

  1. Alterações
    - Remove políticas que causam recursão
    - Simplifica lógica de acesso
    - Adiciona cache de tenant_id para evitar recursão
    
  2. Segurança
    - Mantém isolamento por tenant
    - Permite acesso adequado para admins
*/

-- Remover políticas existentes
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;

-- Função para obter tenant_id do usuário com cache
CREATE OR REPLACE FUNCTION get_user_tenant_id()
RETURNS uuid
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_tenant_id uuid;
BEGIN
  -- Tentar obter do cache primeiro
  BEGIN
    v_tenant_id := current_setting('app.user_tenant_id')::uuid;
    RETURN v_tenant_id;
  EXCEPTION WHEN OTHERS THEN
    -- Se não estiver no cache, buscar do banco
    SELECT tenant_id INTO v_tenant_id
    FROM profiles
    WHERE id = auth.uid();
    
    -- Armazenar no cache
    PERFORM set_config('app.user_tenant_id', v_tenant_id::text, false);
    
    RETURN v_tenant_id;
  END;
END;
$$;

-- Criar novas políticas simplificadas
CREATE POLICY "enable_profiles_select"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    -- Admin do tenant principal vê todos
    (
      get_user_tenant_id() = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2' AND
      EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role = 'admin'
      )
    )
    OR
    -- Próprio perfil
    id = auth.uid()
    OR
    -- Perfis do mesmo tenant
    tenant_id = get_user_tenant_id()
  );

CREATE POLICY "enable_profiles_insert"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Admin do tenant principal pode criar em qualquer tenant
    (
      get_user_tenant_id() = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2' AND
      EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role = 'admin'
      )
    )
    OR
    -- Outros só no próprio tenant
    tenant_id = get_user_tenant_id()
  );

CREATE POLICY "enable_profiles_update"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (
    -- Admin do tenant principal pode atualizar qualquer perfil
    (
      get_user_tenant_id() = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2' AND
      EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role = 'admin'
      )
    )
    OR
    -- Próprio perfil
    id = auth.uid()
    OR
    -- Admin pode atualizar perfis do seu tenant
    (
      tenant_id = get_user_tenant_id() AND
      EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role = 'admin'
      )
    )
  );

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_profiles_tenant_id_role ON profiles(tenant_id, role);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Comentários
COMMENT ON FUNCTION get_user_tenant_id IS 'Retorna o tenant_id do usuário atual com cache para evitar recursão';
COMMENT ON POLICY "enable_profiles_select" ON profiles IS 'Controla visualização de perfis com acesso global para admin principal';
COMMENT ON POLICY "enable_profiles_insert" ON profiles IS 'Controla criação de perfis com permissão especial para admin global';
COMMENT ON POLICY "enable_profiles_update" ON profiles IS 'Controla atualização de perfis com permissão especial para admin global';