/*
  # Criar tenant de demonstração

  1. Inserções
    - Adiciona um tenant de demonstração
    - Garante que o tenant esteja ativo
    - Configura permissões adequadas
    
  2. Dados
    - Nome: "Empresa Demonstração"
    - Slug: "demo"
    - Status: active
    - Configurações completas
*/

-- Inserir tenant de demonstração com configurações completas
INSERT INTO tenants (id, name, slug, settings, status)
VALUES (
  'e97f27c9-8d4e-4e8c-a172-7846995c38b2',
  'Empresa Demonstração',
  'demo',
  jsonb_build_object(
    'theme', jsonb_build_object(
      'primary_color', '#2563eb',
      'mode', 'light'
    ),
    'features', jsonb_build_object(
      'chat', true,
      'crm', true,
      'financeiro', true,
      'tickets', true,
      'saas', true
    ),
    'modules', jsonb_build_array('chat', 'crm', 'financeiro', 'tickets', 'saas')
  ),
  'active'
) ON CONFLICT (slug) DO UPDATE
SET 
  name = EXCLUDED.name,
  settings = EXCLUDED.settings,
  status = EXCLUDED.status;