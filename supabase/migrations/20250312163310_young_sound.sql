/*
  # Ajustar políticas de perfil e função de criação de usuário

  1. Alterações
    - Simplificar políticas de RLS para profiles
    - Atualizar função handle_new_user para garantir criação correta do perfil
    - Remover políticas conflitantes

  2. Segurança
    - Manter RLS ativo
    - Garantir que usuários só possam acessar seus próprios dados
    - Permitir que admins do tenant principal vejam todos os perfis
*/

-- Remover políticas existentes para evitar conflitos
DROP POLICY IF EXISTS "Política de leitura de perfis" ON profiles;
DROP POLICY IF EXISTS "Política de inserção de perfis" ON profiles;
DROP POLICY IF EXISTS "Política de atualização de perfis" ON profiles;

-- Atualizar a função de criação de perfil
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
SECURITY DEFINER SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    email,
    name,
    role,
    tenant_id,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'Usuário'),
    'user',
    'e97f27c9-8d4e-4e8c-a172-7846995c38b2',
    NOW(),
    NOW()
  );
  
  RETURN NEW;
END;
$$;

-- Recriar políticas simplificadas
CREATE POLICY "Permitir inserção de perfis via trigger"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Permitir leitura de perfis"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Permitir atualização do próprio perfil"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Garantir que o trigger está ativo
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();