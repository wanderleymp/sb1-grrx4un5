/*
  # Criar usuário de demonstração

  1. Alterações
    - Insere um usuário de demonstração na tabela auth.users
    - Cria o perfil associado na tabela profiles
    - Define as credenciais iniciais:
      - Email: admin@demo.com
      - Senha: demo123
*/

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
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3', -- ID fixo para facilitar referência
  '00000000-0000-0000-0000-000000000000',
  'admin@demo.com',
  crypt('demo123', gen_salt('bf')), -- Senha: demo123
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"name": "Admin Demo"}',
  now(),
  now(),
  'authenticated',
  '',
  '',
  '',
  ''
) ON CONFLICT (id) DO NOTHING;

-- Inserir perfil do usuário
INSERT INTO profiles (
  id,
  email,
  name,
  role,
  tenant_id
) VALUES (
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3', -- Mesmo ID do usuário
  'admin@demo.com',
  'Admin Demo',
  'admin',
  'e97f27c9-8d4e-4e8c-a172-7846995c38b2' -- ID do tenant de demonstração
) ON CONFLICT (id) DO NOTHING;