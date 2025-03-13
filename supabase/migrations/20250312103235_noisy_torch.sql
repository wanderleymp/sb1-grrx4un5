/*
  # Criar tenant padrão

  1. Inserções
    - Adiciona um tenant padrão para desenvolvimento
    
  2. Dados
    - Nome: "Empresa Padrão"
    - Slug: "empresa-padrao"
    - Status: active
*/

INSERT INTO tenants (name, slug, settings, status)
VALUES (
  'Empresa Padrão',
  'empresa-padrao',
  '{"theme": "light"}',
  'active'
) ON CONFLICT (slug) DO NOTHING;