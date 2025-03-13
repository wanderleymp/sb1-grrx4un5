/*
  # Ajuste de permissões para admin global

  1. Alterações
    - Adiciona políticas especiais para admin do tenant principal
    - Garante acesso total a todas as licenças e usuários
    - Mantém isolamento para outros usuários
    
  2. Segurança
    - Apenas admins do tenant principal têm acesso global
    - Mantém políticas existentes para outros usuários
*/

-- Atualizar política de licenças para permitir acesso global ao admin
DROP POLICY IF EXISTS "enable_license_access" ON licenses;

CREATE POLICY "enable_license_access"
  ON licenses
  FOR ALL
  TO authenticated
  USING (
    -- Admin do tenant principal vê tudo
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND profiles.role = 'admin'
    )
    OR
    -- Outros usuários veem apenas suas licenças ou do seu tenant
    (
      tenant_id = COALESCE(
        (current_setting('app.current_tenant_id', TRUE))::uuid,
        'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
      ) AND (
        owner_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM profiles
          WHERE profiles.id = auth.uid()
          AND profiles.tenant_id = licenses.tenant_id
          AND profiles.role = 'admin'
        )
      )
    )
  )
  WITH CHECK (
    -- Admin do tenant principal pode criar/editar em qualquer tenant
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND profiles.role = 'admin'
    )
    OR
    -- Outros usuários só no próprio tenant
    (
      tenant_id = COALESCE(
        (current_setting('app.current_tenant_id', TRUE))::uuid,
        'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
      ) AND (
        owner_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM profiles
          WHERE profiles.id = auth.uid()
          AND profiles.tenant_id = licenses.tenant_id
          AND profiles.role = 'admin'
        )
      )
    )
  );

-- Atualizar política de perfis para permitir acesso global ao admin
DROP POLICY IF EXISTS "enable_select_profiles" ON profiles;
DROP POLICY IF EXISTS "enable_insert_profiles" ON profiles;
DROP POLICY IF EXISTS "enable_update_profiles" ON profiles;

-- Política para leitura de perfis
CREATE POLICY "enable_select_profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    -- Admin do tenant principal vê todos os perfis
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND p.role = 'admin'
    )
    OR
    -- Outros usuários veem apenas perfis do seu tenant
    id = auth.uid() OR
    tenant_id = COALESCE(
      (current_setting('app.current_tenant_id', TRUE))::uuid,
      'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
    )
  );

-- Política para inserção de perfis
CREATE POLICY "enable_insert_profiles"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Admin do tenant principal pode criar em qualquer tenant
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND p.role = 'admin'
    )
    OR
    -- Outros usuários só no próprio tenant
    tenant_id = COALESCE(
      (current_setting('app.current_tenant_id', TRUE))::uuid,
      'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
    )
  );

-- Política para atualização de perfis
CREATE POLICY "enable_update_profiles"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (
    -- Admin do tenant principal pode atualizar qualquer perfil
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND p.role = 'admin'
    )
    OR
    -- Outros usuários só podem atualizar próprio perfil ou do seu tenant (se for admin)
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.tenant_id = profiles.tenant_id
      AND p.role = 'admin'
    )
  )
  WITH CHECK (
    -- Mesmas regras do USING
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND p.role = 'admin'
    )
    OR
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.tenant_id = profiles.tenant_id
      AND p.role = 'admin'
    )
  );

-- Comentários
COMMENT ON POLICY "enable_license_access" ON licenses IS 'Controla acesso às licenças com permissão especial para admin global';
COMMENT ON POLICY "enable_select_profiles" ON profiles IS 'Controla visualização de perfis com acesso global para admin principal';
COMMENT ON POLICY "enable_insert_profiles" ON profiles IS 'Controla criação de perfis com permissão especial para admin global';
COMMENT ON POLICY "enable_update_profiles" ON profiles IS 'Controla atualização de perfis com permissão especial para admin global';