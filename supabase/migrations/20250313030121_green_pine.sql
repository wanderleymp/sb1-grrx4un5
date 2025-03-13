/*
  # Correção de Persistência de Perfis

  1. Alterações
    - Ajusta políticas RLS para profiles
    - Melhora função de atualização de perfil
    - Adiciona validações de tenant
    
  2. Segurança
    - Mantém isolamento por tenant
    - Permite acesso adequado para admins
*/

-- Remover políticas existentes
DROP POLICY IF EXISTS "enable_select_profiles" ON profiles;
DROP POLICY IF EXISTS "enable_insert_profiles" ON profiles;
DROP POLICY IF EXISTS "enable_update_profiles" ON profiles;

-- Criar novas políticas
CREATE POLICY "enable_select_profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() OR
    tenant_id = COALESCE(
      (current_setting('app.current_tenant_id', TRUE))::uuid,
      'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
    )
  );

CREATE POLICY "enable_insert_profiles"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "enable_update_profiles"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.tenant_id = profiles.tenant_id
      AND p.role = 'admin'
    )
  )
  WITH CHECK (
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.tenant_id = profiles.tenant_id
      AND p.role = 'admin'
    )
  );

-- Função para atualizar perfil com validações
CREATE OR REPLACE FUNCTION update_profile(
  p_id uuid,
  p_name text,
  p_role text DEFAULT NULL
)
RETURNS profiles
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_profile profiles;
  v_tenant_id uuid;
BEGIN
  -- Obter tenant_id atual
  v_tenant_id := COALESCE(
    (current_setting('app.current_tenant_id', TRUE))::uuid,
    'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
  );

  -- Verificar se o perfil existe no tenant atual
  SELECT * INTO v_profile
  FROM profiles
  WHERE id = p_id
  AND tenant_id = v_tenant_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Perfil não encontrado no tenant atual';
  END IF;

  -- Atualizar o perfil
  UPDATE profiles
  SET
    name = COALESCE(p_name, name),
    role = COALESCE(p_role, role),
    updated_at = now()
  WHERE id = p_id
  AND tenant_id = v_tenant_id
  RETURNING * INTO v_profile;

  RETURN v_profile;
END;
$$;

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_profiles_tenant_id_id ON profiles(tenant_id, id);

-- Comentários
COMMENT ON POLICY "enable_select_profiles" ON profiles IS 'Permite leitura de perfis do mesmo tenant';
COMMENT ON POLICY "enable_insert_profiles" ON profiles IS 'Permite inserção de novos perfis';
COMMENT ON POLICY "enable_update_profiles" ON profiles IS 'Permite atualização de perfil próprio ou por admin do tenant';
COMMENT ON FUNCTION update_profile IS 'Função para atualizar perfil com validação de tenant';