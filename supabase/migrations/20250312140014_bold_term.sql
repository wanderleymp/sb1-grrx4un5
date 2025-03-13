/*
  # Reset Seguro do Banco de Dados
  
  1. Limpeza
    - Remove dados existentes mantendo a estrutura
    - Preserva políticas e configurações de segurança
    
  2. Dados Iniciais
    - Tenant principal (root)
    - Licença master
*/

-- Limpar dados existentes com segurança
DELETE FROM licenses WHERE tenant_id != 'e97f27c9-8d4e-4e8c-a172-7846995c38b2';
DELETE FROM profiles WHERE tenant_id != 'e97f27c9-8d4e-4e8c-a172-7846995c38b2';
DELETE FROM tenants WHERE id != 'e97f27c9-8d4e-4e8c-a172-7846995c38b2';

-- Inserir ou atualizar tenant principal
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
  name = EXCLUDED.name,
  settings = EXCLUDED.settings,
  status = EXCLUDED.status;

-- Inserir ou atualizar licença master
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
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  domain = EXCLUDED.domain,
  company_name = EXCLUDED.company_name,
  modules = EXCLUDED.modules,
  primary_color = EXCLUDED.primary_color,
  status = EXCLUDED.status;