/*
  # Criar perfil padrão para usuário autenticado

  1. Alterações
    - Adiciona trigger para criar perfil automaticamente quando um novo usuário é criado
    - Adiciona função para criar perfil padrão
    - Garante que todo usuário terá um perfil básico

  2. Segurança
    - Mantém as políticas de acesso existentes
    - Garante que o perfil seja criado com o tenant padrão
*/

-- Função para criar perfil automaticamente
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, role, tenant_id)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'name', 'Usuário'),
    'user',
    'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para criar perfil quando um novo usuário é criado
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Criar perfis para usuários existentes que não têm perfil
INSERT INTO public.profiles (id, email, name, role, tenant_id)
SELECT 
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'name', 'Usuário'),
  'user',
  'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE p.id IS NULL;