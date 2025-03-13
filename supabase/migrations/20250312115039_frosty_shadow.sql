/*
  # Adiciona função RPC para definir tenant atual

  1. Nova Função
    - `set_current_tenant`: Define o tenant atual no contexto da sessão
    - Parâmetros:
      - tenant_id: UUID do tenant

  2. Segurança
    - Função acessível para usuários anônimos e autenticados
    - Validação do tenant_id
*/

-- Função para definir o tenant atual
CREATE OR REPLACE FUNCTION set_current_tenant(tenant_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Valida se o tenant existe
  IF NOT EXISTS (SELECT 1 FROM tenants WHERE id = tenant_id) THEN
    RAISE EXCEPTION 'Tenant não encontrado';
  END IF;

  -- Define o tenant_id no contexto da sessão
  PERFORM set_config('app.current_tenant_id', tenant_id::text, false);
END;
$$;