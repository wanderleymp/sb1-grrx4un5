/*
  # Criação da tabela de licenças

  1. Nova Tabela
    - `licenses`
      - `id` (uuid, chave primária)
      - `name` (texto, nome da licença)
      - `domain` (texto, domínio único)
      - `company_name` (texto, nome da empresa)
      - `document` (texto, opcional, CPF/CNPJ)
      - `document_type` (texto, opcional, tipo do documento)
      - `modules` (array de texto, módulos ativos)
      - `expires_at` (timestamp com timezone, opcional)
      - `primary_color` (texto, cor primária)
      - `status` (texto, status da licença)
      - `created_at` (timestamp com timezone, data de criação)
      - `updated_at` (timestamp com timezone, data de atualização)

  2. Segurança
    - Habilitado RLS
    - Políticas para usuários autenticados
*/

CREATE TABLE licenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  domain text NOT NULL UNIQUE,
  company_name text NOT NULL,
  document text,
  document_type text CHECK (document_type IN ('cpf', 'cnpj')),
  modules text[] NOT NULL DEFAULT '{}',
  expires_at timestamptz,
  primary_color text NOT NULL,
  status text NOT NULL CHECK (status IN ('active', 'inactive', 'suspended')) DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE licenses ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Usuários autenticados podem visualizar licenças"
  ON licenses
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem criar licenças"
  ON licenses
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_licenses_updated_at
  BEFORE UPDATE ON licenses
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();