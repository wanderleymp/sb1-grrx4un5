/*
  # Correção do tenant de demonstração

  1. Alterações
    - Verifica existência do tenant antes de inserir
    - Atualiza configurações apenas se necessário
    - Adiciona licença de exemplo se não existir

  2. Dados
    - ID fixo para o tenant demo
    - Configurações completas
    - Licença inicial para demonstração
*/

DO $$
DECLARE
  v_tenant_exists boolean;
BEGIN
  -- Verifica se o tenant já existe
  SELECT EXISTS (
    SELECT 1 FROM tenants 
    WHERE id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
  ) INTO v_tenant_exists;

  -- Se não existe, insere o novo tenant
  IF NOT v_tenant_exists THEN
    INSERT INTO tenants (id, name, slug, settings, status)
    VALUES (
      'e97f27c9-8d4e-4e8c-a172-7846995c38b2',
      'Empresa Demonstração',
      'demo-' || substr(md5(random()::text), 1, 8),
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
    );
  END IF;

  -- Adiciona licença de exemplo apenas se não existir nenhuma para este tenant
  IF NOT EXISTS (
    SELECT 1 FROM licenses 
    WHERE tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
  ) THEN
    INSERT INTO licenses (
      name,
      domain,
      company_name,
      modules,
      primary_color,
      status,
      tenant_id
    )
    VALUES (
      'Licença Demonstração',
      'demo-' || substr(md5(random()::text), 1, 8) || '.empresa.com.br',
      'Empresa Demonstração LTDA',
      ARRAY['saas', 'crm', 'chat', 'financeiro'],
      '#2563eb',
      'active',
      'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
    );
  END IF;
END $$;