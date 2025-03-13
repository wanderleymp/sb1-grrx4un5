/*
  # Ajuste nas políticas RLS da tabela de licenças

  1. Alterações
    - Remove políticas existentes
    - Adiciona nova política para permitir todas as operações
    - Mantém RLS ativado para segurança

  2. Segurança
    - Permite operações CRUD para usuários autenticados
    - Mantém proteção contra acesso não autenticado
*/

-- Remove políticas existentes
DROP POLICY IF EXISTS "Usuários autenticados podem visualizar licenças" ON licenses;
DROP POLICY IF EXISTS "Usuários autenticados podem criar licenças" ON licenses;

-- Adiciona nova política mais permissiva
CREATE POLICY "allow_all_authenticated"
  ON licenses
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);