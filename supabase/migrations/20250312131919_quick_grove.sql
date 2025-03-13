/*
  # Configuração do Tenant Principal e Licença

  1. Estrutura
    - Cria o tenant principal (root) da plataforma
    - Cria uma licença master com todos os módulos habilitados
    - Configura as permissões especiais para o tenant principal

  2. Dados Iniciais
    - Tenant principal com status ativo
    - Licença master com acesso total
    - Configurações especiais para gerenciamento global

  3. Segurança
    - Mantém as políticas RLS existentes
    - Adiciona verificações especiais para o tenant principal
*/

-- Inserir o tenant principal
INSERT INTO tenants (
  id,
  name,
  slug,
  settings,
  status
) VALUES (
  'e97f27c9-8d4e-4e8c-a172-7846995c38b2',
  'Finance AI Platform',
  'finance-ai',
  jsonb_build_object(
    'is_root', true,
    'can_manage_tenants', true,
    'theme', jsonb_build_object(
      'primary_color', '#3B82F6',
      'logo_url', 'https://example.com/logo.png'
    )
  ),
  'active'
) ON CONFLICT (id) DO UPDATE SET
  settings = EXCLUDED.settings,
  status = EXCLUDED.status;

-- Criar a licença master para o tenant principal
INSERT INTO licenses (
  id,
  name,
  domain,
  company_name,
  modules,
  primary_color,
  status,
  tenant_id
) VALUES (
  'e97f27c9-8d4e-4e8c-a172-7846995c38b4',
  'Finance AI Master',
  'app.financeai.com',
  'Finance AI Technologies',
  ARRAY['saas', 'crm', 'chat', 'tickets', 'financeiro', 'documentos'],
  '#3B82F6',
  'active',
  'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
) ON CONFLICT (domain) DO UPDATE SET
  modules = EXCLUDED.modules,
  status = EXCLUDED.status;

-- Adicionar política especial para o tenant principal
CREATE POLICY "Tenant principal pode ver todos os tenants"
  ON tenants
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND profiles.role = 'admin'
    )
  );

-- Adicionar política especial para licenças do tenant principal
CREATE POLICY "Tenant principal pode gerenciar todas as licenças"
  ON licenses
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND profiles.role = 'admin'
    )
  );