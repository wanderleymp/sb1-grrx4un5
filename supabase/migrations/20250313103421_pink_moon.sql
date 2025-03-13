/*
  # Dados iniciais do sistema de permissões

  1. Inserções
    - Recursos do sistema (módulos e funcionalidades)
    - Permissões básicas
    - Permissões para papel de admin
*/

-- Inserir recursos principais (módulos)
INSERT INTO resources (code, name, type, description) VALUES
('financial', 'Financeiro', 'module', 'Módulo de gestão financeira'),
('crm', 'CRM', 'module', 'Módulo de gestão de relacionamento com clientes'),
('saas', 'SaaS', 'module', 'Módulo de gestão de licenças e tenants');

-- Inserir recursos do módulo financeiro
WITH financial_id AS (
    SELECT id FROM resources WHERE code = 'financial'
)
INSERT INTO resources (code, name, type, parent_id, description) VALUES
('financial.accounts.payable', 'Contas a Pagar', 'feature', (SELECT id FROM financial_id), 'Gestão de contas a pagar'),
('financial.accounts.receivable', 'Contas a Receber', 'feature', (SELECT id FROM financial_id), 'Gestão de contas a receber'),
('financial.reports', 'Relatórios Financeiros', 'feature', (SELECT id FROM financial_id), 'Relatórios e análises financeiras');

-- Inserir recursos do módulo CRM
WITH crm_id AS (
    SELECT id FROM resources WHERE code = 'crm'
)
INSERT INTO resources (code, name, type, parent_id, description) VALUES
('crm.contacts', 'Contatos', 'feature', (SELECT id FROM crm_id), 'Gestão de contatos'),
('crm.leads', 'Leads', 'feature', (SELECT id FROM crm_id), 'Gestão de leads'),
('crm.opportunities', 'Oportunidades', 'feature', (SELECT id FROM crm_id), 'Gestão de oportunidades');

-- Inserir recursos do módulo SaaS
WITH saas_id AS (
    SELECT id FROM resources WHERE code = 'saas'
)
INSERT INTO resources (code, name, type, parent_id, description) VALUES
('saas.licenses', 'Licenças', 'feature', (SELECT id FROM saas_id), 'Gestão de licenças'),
('saas.tenants', 'Tenants', 'feature', (SELECT id FROM saas_id), 'Gestão de tenants'),
('saas.users', 'Usuários', 'feature', (SELECT id FROM saas_id), 'Gestão de usuários');

-- Criar permissões para cada recurso
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
) AS a(action)
WHERE r.type = 'feature';

-- Atribuir todas as permissões ao papel de admin do tenant principal
WITH admin_profile AS (
    SELECT id, role
    FROM profiles
    WHERE email = 'admin@demo.com'
    LIMIT 1
)
INSERT INTO role_permissions (role_id, permission_id, tenant_id, granted_by)
SELECT 
    gen_random_uuid(), -- Gera um UUID único para cada role_id
    p.id,
    'e97f27c9-8d4e-4e8c-a172-7846995c38b2',
    (SELECT id FROM admin_profile)
FROM permissions p
WHERE EXISTS (SELECT 1 FROM admin_profile);