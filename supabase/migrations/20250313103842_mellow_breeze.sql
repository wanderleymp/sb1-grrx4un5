/*
  # Adicionar relacionamento de proprietário

  1. Alterações
    - Adiciona coluna owner_id nas tabelas licenses e tenants
    - Atualiza políticas RLS para considerar proprietário
    - Adiciona índices para melhor performance
    
  2. Segurança
    - Mantém isolamento por tenant
    - Permite que proprietários gerenciem seus recursos
*/

-- Adicionar coluna owner_id
ALTER TABLE licenses ADD COLUMN owner_id uuid REFERENCES profiles(id);
ALTER TABLE tenants ADD COLUMN owner_id uuid REFERENCES profiles(id);

-- Criar índices
CREATE INDEX idx_licenses_owner_id ON licenses(owner_id);
CREATE INDEX idx_tenants_owner_id ON tenants(owner_id);

-- Atualizar políticas RLS para licenses
DROP POLICY IF EXISTS "enable_tenant_access" ON licenses;
DROP POLICY IF EXISTS "Tenant principal pode gerenciar todas as licenças" ON licenses;

CREATE POLICY "enable_license_access"
  ON licenses
  FOR ALL
  TO authenticated
  USING (
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
  WITH CHECK (
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
  );

-- Atualizar políticas RLS para tenants
DROP POLICY IF EXISTS "Tenant principal pode ver todos os tenants" ON tenants;
DROP POLICY IF EXISTS "Tenants são visíveis para todos os usuários autenticados" ON tenants;

CREATE POLICY "enable_tenant_management"
  ON tenants
  FOR ALL
  TO authenticated
  USING (
    owner_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    owner_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND profiles.role = 'admin'
    )
  );

-- Atualizar registros existentes
UPDATE licenses 
SET owner_id = (
  SELECT id FROM profiles 
  WHERE tenant_id = licenses.tenant_id 
  AND role = 'admin' 
  LIMIT 1
)
WHERE owner_id IS NULL;

UPDATE tenants
SET owner_id = (
  SELECT id FROM profiles 
  WHERE tenant_id = tenants.id 
  AND role = 'admin' 
  LIMIT 1
)
WHERE owner_id IS NULL;

-- Comentários
COMMENT ON COLUMN licenses.owner_id IS 'Usuário proprietário da licença';
COMMENT ON COLUMN tenants.owner_id IS 'Usuário proprietário do tenant';