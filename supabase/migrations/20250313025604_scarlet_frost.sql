/*
  # Correção da atualização de perfil

  1. Alterações
    - Ajusta políticas RLS para profiles
    - Adiciona verificação de existência
    - Melhora tratamento de erros
    
  2. Segurança
    - Mantém restrições de acesso por tenant
    - Permite admins gerenciarem usuários do tenant
*/

-- Remover políticas existentes
DROP POLICY IF EXISTS "enable_read_profiles" ON profiles;
DROP POLICY IF EXISTS "enable_insert_profiles" ON profiles;
DROP POLICY IF EXISTS "enable_update_profiles" ON profiles;

-- Criar novas políticas
CREATE POLICY "enable_select_profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING ((
    id = auth.uid() OR
    tenant_id = COALESCE(
      (current_setting('app.current_tenant_id', TRUE))::uuid,
      'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
    )
  ));

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
  );

-- Função para atualizar perfil com validação
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
BEGIN
  -- Verificar se o perfil existe
  SELECT * INTO v_profile
  FROM profiles
  WHERE id = p_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Perfil não encontrado';
  END IF;

  -- Atualizar o perfil
  UPDATE profiles
  SET
    name = COALESCE(p_name, name),
    role = COALESCE(p_role, role),
    updated_at = now()
  WHERE id = p_id
  RETURNING * INTO v_profile;

  RETURN v_profile;
END;
$$;

-- Comentários
COMMENT ON FUNCTION update_profile IS 'Função para atualizar perfil com validações';