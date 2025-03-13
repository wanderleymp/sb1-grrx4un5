/*
  # Adicionar notificações de demonstração
  
  1. Inserções
    - Adiciona notificações de exemplo para o usuário demo
    - Diferentes tipos de notificações (info, warning, error, success)
    - Algumas lidas e outras não lidas
    
  2. Dados
    - Notificações relacionadas a funcionalidades do sistema
    - Timestamps variados para simular histórico
*/

-- Inserir notificações de demonstração
INSERT INTO notifications (
  user_id,
  title,
  message,
  type,
  read,
  created_at
) VALUES 
(
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'Bem-vindo ao Finance AI',
  'Explore todas as funcionalidades disponíveis no seu painel.',
  'info',
  true,
  now() - interval '2 days'
),
(
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'Nova licença criada',
  'A licença "Finance AI Master" foi criada com sucesso.',
  'success',
  false,
  now() - interval '1 day'
),
(
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'Atualização do sistema',
  'Uma nova atualização estará disponível em breve. Fique atento!',
  'warning',
  false,
  now() - interval '12 hours'
),
(
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'Backup automático realizado',
  'O backup diário foi concluído com sucesso.',
  'success',
  true,
  now() - interval '6 hours'
),
(
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'Tentativa de acesso detectada',
  'Uma tentativa de acesso incomum foi detectada. Verifique suas configurações de segurança.',
  'error',
  false,
  now() - interval '1 hour'
);