/*
  # Criar usuário super admin

  1. Inserções
    - Cria usuário na tabela auth.users
    - Senha: admin123 (criptografada)
    - Email: admin@financeai.com
    
  2. Dados
    - Usuário com acesso total ao sistema
    - Vinculado ao tenant principal
    - Todas as permissões habilitadas
*/

-- Inserir super admin na tabela auth.users
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  role,
  aud,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3', -- ID fixo para facilitar referência
  '00000000-0000-0000-0000-000000000000',
  'admin@financeai.com',
  crypt('admin123', gen_salt('bf')), -- Senha: admin123
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"name":"Super Admin"}',
  now(),
  now(),
  'authenticated',
  'authenticated',
  '',
  '',
  '',
  ''
) ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  encrypted_password = EXCLUDED.encrypted_password,
  raw_user_meta_data = EXCLUDED.raw_user_meta_data;

-- Atualizar perfil existente
UPDATE profiles
SET 
  email = 'admin@financeai.com',
  name = 'Super Admin',
  role = 'admin',
  tenant_id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b2',
  updated_at = now()
WHERE id = 'e97f27c9-8d4e-4e8c-a172-7846995c38b3';