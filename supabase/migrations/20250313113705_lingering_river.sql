/*
  # Reset e Inicialização do Banco de Dados

  1. Limpeza
    - Remove todos os dados existentes
    - Mantém estrutura das tabelas
    
  2. Dados Iniciais
    - Tenant principal (root)
    - Licença master com todos os módulos
    - Usuário super admin
    - Permissões iniciais
*/

-- Limpar dados existentes
TRUNCATE TABLE 
  notifications,
  chat_messages,
  chat_participants,
  chat_rooms,
  user_permissions,
  role_permissions,
  permissions,
  resources,
  contact_group_members,
  contact_groups,
  contacts,
  licenses,
  profiles,
  tenants
CASCADE;

-- Criar tenant principal
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
      'mode', 'light'
    ),
    'features', jsonb_build_object(
      'chat', true,
      'crm', true,
      'financeiro', true,
      'tickets', true,
      'saas', true
    )
  ),
  'active'
);

-- Criar super admin
INSERT INTO profiles (
  id,
  email,
  name,
  role,
  tenant_id
) VALUES (
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'admin@financeai.com',
  'Super Admin',
  'admin',
  'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
);

-- Criar licença master
INSERT INTO licenses (
  id,
  name,
  domain,
  company_name,
  modules,
  primary_color,
  status,
  tenant_id,
  owner_id
) VALUES (
  'e97f27c9-8d4e-4e8c-a172-7846995c38b4',
  'Finance AI Master',
  'app.financeai.com',
  'Finance AI Technologies',
  ARRAY[
    'saas',
    'crm',
    'chat',
    'tickets',
    'financeiro',
    'documentos',
    'recursos_humanos',
    'marketing',
    'vendas',
    'compras',
    'estoque',
    'projetos'
  ],
  '#3B82F6',
  'active',
  'e97f27c9-8d4e-4e8c-a172-7846995c38b2',
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3'
);

-- Criar recursos principais
INSERT INTO resources (code, name, type, description) VALUES
('financial', 'Financeiro', 'module', 'Módulo de gestão financeira'),
('crm', 'CRM', 'module', 'Módulo de gestão de relacionamento com clientes'),
('saas', 'SaaS', 'module', 'Módulo de gestão de licenças e tenants'),
('chat', 'Chat', 'module', 'Módulo de comunicação'),
('tickets', 'Tickets', 'module', 'Módulo de suporte'),
('documents', 'Documentos', 'module', 'Módulo de gestão de documentos'),
('hr', 'Recursos Humanos', 'module', 'Módulo de RH'),
('marketing', 'Marketing', 'module', 'Módulo de marketing'),
('sales', 'Vendas', 'module', 'Módulo de vendas'),
('purchases', 'Compras', 'module', 'Módulo de compras'),
('inventory', 'Estoque', 'module', 'Módulo de estoque'),
('projects', 'Projetos', 'module', 'Módulo de projetos');

-- Criar permissões para cada módulo
INSERT INTO permissions (resource_id, action, name, description)
SELECT 
  r.id,
  a.action,
  r.name || ' - ' || 
  CASE 
    WHEN a.action = 'view' THEN 'Visualizar'
    WHEN a.action = 'create' THEN 'Criar'
    WHEN a.action = 'edit' THEN 'Editar'
    WHEN a.action = 'delete' THEN 'Excluir'
  END,
  'Permissão para ' || 
  CASE 
    WHEN a.action = 'view' THEN 'visualizar'
    WHEN a.action = 'create' THEN 'criar'
    WHEN a.action = 'edit' THEN 'editar'
    WHEN a.action = 'delete' THEN 'excluir'
  END || ' ' || LOWER(r.name)
FROM resources r
CROSS JOIN (
  VALUES 
    ('view'),
    ('create'),
    ('edit'),
    ('delete')
) AS a(action);

-- Atribuir todas as permissões ao super admin
INSERT INTO role_permissions (role_id, permission_id, tenant_id, granted_by)
SELECT 
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  p.id,
  'e97f27c9-8d4e-4e8c-a172-7846995c38b2',
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3'
FROM permissions p;