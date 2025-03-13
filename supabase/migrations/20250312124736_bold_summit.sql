/*
  # Correção do usuário de demonstração

  1. Alterações
    - Remove e recria o usuário de demonstração com configurações corretas
    - Garante que o perfil está corretamente associado
    - Define as credenciais:
      - Email: admin@demo.com
      - Senha: demo123

  2. Segurança
    - Usuário vinculado ao tenant de demonstração
    - Perfil com role de admin
*/

-- Remover registros existentes para garantir uma criação limpa
DELETE FROM auth.users WHERE email = 'admin@demo.com';
DELETE FROM profiles WHERE email = 'admin@demo.com';

-- Inserir usuário de demonstração
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
  recovery_token,
  is_super_admin
) VALUES (
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  '00000000-0000-0000-0000-000000000000',
  'admin@demo.com',
  crypt('demo123', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"name":"Admin Demo"}',
  now(),
  now(),
  'authenticated',
  'authenticated',
  '',
  '',
  '',
  '',
  false
);

-- Inserir perfil do usuário
INSERT INTO profiles (
  id,
  email,
  name,
  role,
  tenant_id,
  created_at,
  updated_at
) VALUES (
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'admin@demo.com',
  'Admin Demo',
  'admin',
  'e97f27c9-8d4e-4e8c-a172-7846995c38b2',
  now(),
  now()
);