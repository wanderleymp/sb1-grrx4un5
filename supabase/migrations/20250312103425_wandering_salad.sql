/*
  # Criar tenant inicial

  1. Inserções
    - Adiciona um tenant inicial para desenvolvimento
    - Garante que pelo menos um tenant esteja disponível
    
  2. Dados
    - Nome: "Empresa Demonstração"
    - Slug: "demo"
    - Status: active
    - Configurações básicas de tema
*/

-- Inserir tenant inicial
INSERT INTO tenants (name, slug, settings, status)
VALUES (
  'Empresa Demonstração',
  'demo',
  jsonb_build_object(
    'theme', 'light',
    'features', jsonb_build_object(
      'chat', true,
      'crm', true,
      'financeiro', true
    )
  ),
  'active'
) ON CONFLICT (slug) DO UPDATE
SET 
  name = EXCLUDED.name,
  settings = EXCLUDED.settings,
  status = EXCLUDED.status;