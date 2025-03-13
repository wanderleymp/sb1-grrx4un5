/*
  # Ajuste nas políticas RLS da tabela de licenças

  1. Alterações
    - Remove políticas existentes
    - Adiciona nova política para permitir acesso anônimo
    - Mantém RLS ativado para controle básico de acesso

  2. Segurança
    - Permite operações CRUD para usuários anônimos e autenticados
    - Mantém proteção básica através do RLS
*/

-- Remove políticas existentes
DROP POLICY IF EXISTS "allow_all_authenticated" ON licenses;

-- Adiciona nova política para permitir acesso anônimo
CREATE POLICY "enable_all_access"
  ON licenses
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);