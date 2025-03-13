/*
  # Configuração de Autenticação e Perfis

  1. Nova Tabela
    - `profiles`
      - `id` (uuid, chave primária, referencia auth.users)
      - `email` (texto, email do usuário)
      - `name` (texto, nome do usuário)
      - `avatar_url` (texto, URL do avatar)
      - `role` (texto, papel do usuário)
      - `tenant_id` (uuid, referência ao tenant)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Segurança
    - Políticas RLS para controle de acesso
    - Trigger para atualização automática
*/

-- Criar tabela de perfis
CREATE TABLE profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email text NOT NULL,
    name text,
    avatar_url text,
    role text NOT NULL CHECK (role IN ('admin', 'user')),
    tenant_id uuid REFERENCES tenants(id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Usuários podem ver seus próprios perfis"
    ON profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Usuários podem atualizar seus próprios perfis"
    ON profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Trigger para atualização automática
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();