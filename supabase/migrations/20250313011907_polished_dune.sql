/*
  # Adicionar mais notificações de demonstração
  
  1. Inserções
    - Adiciona várias notificações de teste
    - Usa diferentes tipos e estados
    - Distribui as datas ao longo do dia
    
  2. Dados
    - Notificações com diferentes status (lida/não lida)
    - Diferentes tipos (info, warning, error, success)
    - Mensagens relevantes para o contexto do sistema
*/

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
  'Nova funcionalidade disponível',
  'O módulo de análise preditiva foi ativado em sua conta.',
  'info',
  false,
  now() - interval '30 minutes'
),
(
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'Relatório mensal gerado',
  'O relatório de desempenho de março está disponível para download.',
  'success',
  false,
  now() - interval '45 minutes'
),
(
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'Limite de uso próximo',
  'Você atingiu 80% do limite de armazenamento. Considere fazer uma limpeza.',
  'warning',
  false,
  now() - interval '1 hour'
),
(
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'Integração concluída',
  'A integração com o sistema de pagamentos foi finalizada com sucesso.',
  'success',
  false,
  now() - interval '2 hours'
),
(
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'Manutenção programada',
  'Haverá uma manutenção programada no próximo domingo, das 02h às 04h.',
  'info',
  false,
  now() - interval '3 hours'
),
(
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'Erro na sincronização',
  'Ocorreu um erro durante a sincronização dos dados. Tente novamente.',
  'error',
  false,
  now() - interval '4 hours'
),
(
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'Novo cliente registrado',
  'Um novo cliente foi registrado através do portal de vendas.',
  'success',
  false,
  now() - interval '5 hours'
),
(
  'e97f27c9-8d4e-4e8c-a172-7846995c38b3',
  'Atualização de segurança',
  'Uma nova atualização de segurança está disponível. Recomendamos a instalação.',
  'warning',
  false,
  now() - interval '6 hours'
);