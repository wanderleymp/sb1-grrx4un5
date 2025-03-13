/*
  # Reset do Estado Inicial da Aplicação
  
  1. Limpeza
    - Remove todos os dados existentes mantendo a estrutura
    - Preserva políticas e configurações de segurança
    
  2. Dados Iniciais
    - Tenant principal (root)
    - Licença master
    - Configurações padrão
*/

-- Limpar todos os dados existentes
DELETE FROM licenses;
DELETE FROM profiles;
DELETE FROM tenants;

-- Inserir tenant principal
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
);

-- Inserir licença master
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
);