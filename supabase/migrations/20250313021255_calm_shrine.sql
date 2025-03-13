/*
  # Correção de Perfis e Contatos

  1. Alterações
    - Ajusta as políticas RLS para perfis
    - Adiciona índices para melhorar performance
    - Corrige trigger de criação de contato de usuário
    - Atualiza políticas de contatos

  2. Segurança
    - Mantém RLS ativo
    - Ajusta políticas para permitir operações necessárias
*/

-- Remover políticas existentes de profiles
DROP POLICY IF EXISTS "Política de leitura de perfis" ON profiles;
DROP POLICY IF EXISTS "Política de inserção de perfis" ON profiles;
DROP POLICY IF EXISTS "Política de atualização de perfis" ON profiles;
DROP POLICY IF EXISTS "enable_read_access_profiles" ON profiles;
DROP POLICY IF EXISTS "enable_insert_profiles" ON profiles;
DROP POLICY IF EXISTS "enable_update_own_profile" ON profiles;

-- Criar novas políticas para profiles
CREATE POLICY "enable_read_profiles"
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
      AND p.role = 'admin'
      AND p.tenant_id = profiles.tenant_id
    )
  )
  WITH CHECK (
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role = 'admin'
      AND p.tenant_id = profiles.tenant_id
    )
  );

-- Atualizar função de criação de contato de usuário
CREATE OR REPLACE FUNCTION create_user_contact()
RETURNS trigger
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO contacts (
    tenant_id,
    owner_id,
    type,
    identifier,
    name,
    metadata,
    status
  )
  VALUES (
    NEW.tenant_id,
    NEW.id,
    'user',
    NEW.email,
    NEW.name,
    jsonb_build_object(
      'email', NEW.email,
      'role', NEW.role
    ),
    'active'
  )
  ON CONFLICT (tenant_id, type, identifier)
  DO UPDATE SET
    name = EXCLUDED.name,
    metadata = EXCLUDED.metadata;
    
  RETURN NEW;
END;
$$;

-- Adicionar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_profiles_tenant_id ON profiles(tenant_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Comentários
COMMENT ON POLICY "enable_read_profiles" ON profiles IS 'Permite leitura de perfis do mesmo tenant';
COMMENT ON POLICY "enable_insert_profiles" ON profiles IS 'Permite inserção de novos perfis';
COMMENT ON POLICY "enable_update_profiles" ON profiles IS 'Permite atualização de perfil próprio ou por admin do tenant';