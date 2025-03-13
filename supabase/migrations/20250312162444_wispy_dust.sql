/*
  # Correção da criação de perfis duplicados

  1. Alterações
    - Atualiza a função handle_new_user para evitar duplicatas
    - Adiciona verificação de existência antes da inserção
    - Mantém dados existentes em caso de conflito
  
  2. Segurança
    - Mantém as políticas RLS existentes
    - Preserva os dados dos perfis existentes
*/

-- Atualizar a função para lidar com perfis existentes
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    email,
    name,
    role,
    tenant_id
  )
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'name', 'Usuário'),
    'user',
    'e97f27c9-8d4e-4e8c-a172-7846995c38b2'
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recriar o trigger com a nova função
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();