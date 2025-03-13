/*
  # Implementação do Sistema de Permissões

  1. Novas Tabelas
    - `resources`: Recursos do sistema (módulos, funcionalidades, ações)
    - `permissions`: Permissões disponíveis
    - `role_permissions`: Permissões por papel
    - `user_permissions`: Permissões específicas por usuário

  2. Segurança
    - Políticas RLS para controle de acesso
    - Funções para verificação de permissões
    - Auditoria de alterações
*/

-- Criar enum para tipos de recursos
CREATE TYPE resource_type AS ENUM ('module', 'feature', 'action');

-- Criar enum para tipos de permissão
CREATE TYPE permission_override AS ENUM ('allow', 'deny');

-- Tabela de recursos
CREATE TABLE resources (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code text NOT NULL UNIQUE,
    name text NOT NULL,
    description text,
    type resource_type NOT NULL,
    parent_id uuid REFERENCES resources(id),
    metadata jsonb DEFAULT '{}',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Tabela de permissões
CREATE TABLE permissions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id uuid NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    action text NOT NULL CHECK (action IN ('view', 'create', 'edit', 'delete')),
    name text NOT NULL,
    description text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(resource_id, action)
);

-- Tabela de permissões por papel
CREATE TABLE role_permissions (
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    granted_by uuid NOT NULL REFERENCES profiles(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (role_id, permission_id, tenant_id)
);

-- Tabela de permissões por usuário
CREATE TABLE user_permissions (
    user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    permission_id uuid NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    override_type permission_override NOT NULL,
    granted_by uuid NOT NULL REFERENCES profiles(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, permission_id, tenant_id)
);

-- Habilitar RLS
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Recursos visíveis para todos os usuários autenticados"
    ON resources
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Permissões visíveis para todos os usuários autenticados"
    ON permissions
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Permissões de papel visíveis no tenant"
    ON role_permissions
    FOR SELECT
    TO authenticated
    USING (
        tenant_id = COALESCE(
            (current_setting('app.current_tenant_id', TRUE))::uuid,
            'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
        )
    );

CREATE POLICY "Permissões de usuário visíveis no tenant"
    ON user_permissions
    FOR SELECT
    TO authenticated
    USING (
        tenant_id = COALESCE(
            (current_setting('app.current_tenant_id', TRUE))::uuid,
            'e97f27c9-8d4e-4e8c-a172-7846995c38b2'::uuid
        )
    );

-- Função para verificar permissão
CREATE OR REPLACE FUNCTION check_permission(
    p_user_id uuid,
    p_resource_code text,
    p_action text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_tenant_id uuid;
    v_resource_id uuid;
    v_permission_id uuid;
    v_user_override permission_override;
    v_has_role_permission boolean;
BEGIN
    -- Obter tenant_id do usuário
    SELECT tenant_id INTO v_tenant_id
    FROM profiles
    WHERE id = p_user_id;

    -- Obter resource_id
    SELECT id INTO v_resource_id
    FROM resources
    WHERE code = p_resource_code;

    IF NOT FOUND THEN
        RETURN false;
    END IF;

    -- Obter permission_id
    SELECT id INTO v_permission_id
    FROM permissions
    WHERE resource_id = v_resource_id
    AND action = p_action;

    IF NOT FOUND THEN
        RETURN false;
    END IF;

    -- Verificar override específico do usuário
    SELECT override_type INTO v_user_override
    FROM user_permissions
    WHERE user_id = p_user_id
    AND permission_id = v_permission_id
    AND tenant_id = v_tenant_id;

    -- Se existe override, retorna com base no tipo
    IF FOUND THEN
        RETURN v_user_override = 'allow';
    END IF;

    -- Verificar permissão do papel
    SELECT EXISTS (
        SELECT 1
        FROM profiles p
        JOIN role_permissions rp ON rp.role_id = p.role::uuid
        WHERE p.id = p_user_id
        AND rp.permission_id = v_permission_id
        AND rp.tenant_id = v_tenant_id
    ) INTO v_has_role_permission;

    RETURN v_has_role_permission;
END;
$$;

-- Índices
CREATE INDEX idx_resources_parent_id ON resources(parent_id);
CREATE INDEX idx_resources_code ON resources(code);
CREATE INDEX idx_permissions_resource_id ON permissions(resource_id);
CREATE INDEX idx_role_permissions_tenant_id ON role_permissions(tenant_id);
CREATE INDEX idx_user_permissions_tenant_id ON user_permissions(tenant_id);

-- Triggers
CREATE TRIGGER update_resources_updated_at
    BEFORE UPDATE ON resources
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_permissions_updated_at
    BEFORE UPDATE ON permissions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentários
COMMENT ON TABLE resources IS 'Recursos do sistema (módulos, funcionalidades, ações)';
COMMENT ON TABLE permissions IS 'Permissões disponíveis para cada recurso';
COMMENT ON TABLE role_permissions IS 'Permissões atribuídas a papéis por tenant';
COMMENT ON TABLE user_permissions IS 'Permissões específicas por usuário';
COMMENT ON FUNCTION check_permission IS 'Verifica se um usuário tem determinada permissão';