/*
  # Implementação de Multi-tenancy (Correção)

  1. Nova Tabela
    - `tenants`
      - `id` (uuid, chave primária)
      - `name` (texto, nome do tenant)
      - `slug` (texto, identificador único)
      - `settings` (jsonb, configurações do tenant)
      - `status` (texto, status do tenant)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Alterações
    - Adiciona coluna tenant_id na tabela licenses
    - Adiciona foreign key para garantir integridade referencial
    - Atualiza políticas RLS para isolamento por tenant

  3. Segurança
    - Políticas RLS baseadas em tenant_id
    - Função helper para obter tenant atual
*/

-- Criar enum para status do tenant
CREATE TYPE tenant_status AS ENUM ('active', 'inactive', 'suspended');

-- Criar tabela de tenants
CREATE TABLE tenants (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    slug text NOT NULL UNIQUE,
    settings jsonb DEFAULT '{}'::jsonb,
    status tenant_status NOT NULL DEFAULT 'active',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Adicionar coluna tenant_id na tabela licenses
ALTER TABLE licenses 
ADD COLUMN tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE;

-- Criar índice para melhorar performance de queries por tenant
CREATE INDEX idx_licenses_tenant_id ON licenses(tenant_id);

-- Função para obter o tenant atual do cabeçalho de tenant
CREATE OR REPLACE FUNCTION get_current_tenant_id()
RETURNS uuid
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    header_tenant_id uuid;
BEGIN
    -- Tenta obter o tenant_id do cabeçalho personalizado
    header_tenant_id := current_setting('request.headers', true)::jsonb->>'x-tenant-id';
    
    IF header_tenant_id IS NOT NULL THEN
        RETURN header_tenant_id;
    END IF;
    
    -- Fallback para o primeiro tenant (apenas para desenvolvimento)
    RETURN (SELECT id FROM tenants LIMIT 1);
END;
$$;

-- Habilitar RLS para tenants
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para tenants
CREATE POLICY "Tenants são visíveis para todos os usuários autenticados"
  ON tenants
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Atualizar políticas RLS para licenses
DROP POLICY IF EXISTS "enable_all_access" ON licenses;

CREATE POLICY "Licenses são visíveis apenas dentro do seu tenant"
  ON licenses
  FOR ALL
  TO authenticated
  USING (tenant_id = get_current_tenant_id())
  WITH CHECK (tenant_id = get_current_tenant_id());

-- Trigger para atualizar updated_at
CREATE TRIGGER update_tenants_updated_at
  BEFORE UPDATE ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comentários para documentação
COMMENT ON TABLE tenants IS 'Tabela para armazenar informações dos tenants (empresas)';
COMMENT ON COLUMN tenants.slug IS 'Identificador único usado para URLs e referências';
COMMENT ON COLUMN tenants.settings IS 'Configurações específicas do tenant em formato JSON';
COMMENT ON FUNCTION get_current_tenant_id() IS 'Retorna o ID do tenant atual baseado no cabeçalho x-tenant-id';