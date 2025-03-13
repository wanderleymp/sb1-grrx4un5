/*
  # Implementação de validação de contatos

  1. Nova Função
    - `validate_contact`: Valida o formato de um contato baseado no seu tipo
    - Parâmetros:
      - p_type: Tipo do contato (email, whatsapp, etc)
      - p_identifier: Identificador do contato

  2. Validações
    - Tipo de contato válido
    - Formato do identificador por tipo
    - Tratamento de erros detalhado

  3. Atualização
    - Função update_user_contacts atualizada para usar validação
    - Retorno detalhado com status de sucesso/erro
*/

-- Função para validar formato de contato
CREATE OR REPLACE FUNCTION validate_contact(
  p_type text,
  p_identifier text
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
  -- Validar tipo de contato
  IF p_type NOT IN ('email', 'whatsapp', 'phone', 'instagram', 'telegram', 'custom') THEN
    RAISE EXCEPTION 'Tipo de contato inválido: %', p_type;
  END IF;

  -- Validar identificador
  IF p_identifier IS NULL OR length(trim(p_identifier)) < 3 THEN
    RAISE EXCEPTION 'Identificador inválido para contato do tipo %', p_type;
  END IF;

  -- Validações específicas por tipo
  CASE p_type
    WHEN 'email' THEN
      IF NOT p_identifier ~ '^[^@]+@[^@]+\.[^@]+$' THEN
        RAISE EXCEPTION 'Formato de email inválido';
      END IF;
    WHEN 'phone' THEN
      IF NOT p_identifier ~ '^\+?[0-9]{10,}$' THEN
        RAISE EXCEPTION 'Formato de telefone inválido';
      END IF;
    WHEN 'whatsapp' THEN
      IF NOT p_identifier ~ '^\+?[0-9]{10,}$' THEN
        RAISE EXCEPTION 'Formato de WhatsApp inválido';
      END IF;
    WHEN 'instagram' THEN
      IF NOT p_identifier ~ '^@?[a-zA-Z0-9_.]{1,30}$' THEN
        RAISE EXCEPTION 'Formato de Instagram inválido';
      END IF;
  END CASE;

  RETURN true;
END;
$$;

-- Função principal para atualizar contatos
CREATE OR REPLACE FUNCTION update_user_contacts(
  p_user_id uuid,
  p_contacts jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tenant_id uuid;
  v_user_email text;
  v_contact jsonb;
  v_order int;
  v_result jsonb;
  v_errors jsonb := '[]'::jsonb;
  v_success_count int := 0;
  v_error_count int := 0;
BEGIN
  -- Obter tenant_id e email do usuário
  SELECT tenant_id, email INTO v_tenant_id, v_user_email
  FROM profiles
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Usuário não encontrado';
  END IF;

  -- Validar array de contatos
  IF NOT jsonb_typeof(p_contacts) = 'array' THEN
    RAISE EXCEPTION 'Formato inválido: esperado array de contatos';
  END IF;

  -- Remover contatos não-sistema existentes
  DELETE FROM contacts
  WHERE owner_id = p_user_id
  AND is_system = false;

  -- Iniciar ordem após contatos do sistema
  v_order := 10;

  -- Processar cada contato
  FOR v_contact IN SELECT * FROM jsonb_array_elements(p_contacts)
  LOOP
    -- Pular contatos do sistema
    CONTINUE WHEN (
      v_contact->>'type' = 'user'
      OR (
        v_contact->>'type' = 'email' 
        AND v_contact->>'identifier' = v_user_email
      )
    );

    BEGIN
      -- Validar contato
      PERFORM validate_contact(
        v_contact->>'type',
        v_contact->>'identifier'
      );

      -- Inserir contato
      INSERT INTO contacts (
        tenant_id,
        owner_id,
        type,
        identifier,
        name,
        metadata,
        status,
        is_system,
        display_order
      )
      VALUES (
        v_tenant_id,
        p_user_id,
        v_contact->>'type',
        v_contact->>'identifier',
        (SELECT name FROM profiles WHERE id = p_user_id),
        jsonb_build_object(
          'source', 'manual',
          'description', CASE 
            WHEN v_contact->>'type' = 'email' THEN 'Email adicional'
            WHEN v_contact->>'type' = 'whatsapp' THEN 'Contato WhatsApp'
            WHEN v_contact->>'type' = 'phone' THEN 'Telefone'
            WHEN v_contact->>'type' = 'instagram' THEN 'Instagram'
            WHEN v_contact->>'type' = 'telegram' THEN 'Telegram'
            ELSE 'Contato adicional'
          END,
          'verified', false,
          'is_primary', false,
          'hidden', false
        ),
        'active',
        false,
        v_order
      )
      ON CONFLICT (tenant_id, type, identifier) 
      DO UPDATE SET
        owner_id = p_user_id,
        name = EXCLUDED.name,
        metadata = EXCLUDED.metadata,
        display_order = EXCLUDED.display_order,
        updated_at = now();

      v_order := v_order + 1;
      v_success_count := v_success_count + 1;

    EXCEPTION WHEN OTHERS THEN
      v_error_count := v_error_count + 1;
      v_errors := v_errors || jsonb_build_object(
        'type', v_contact->>'type',
        'identifier', v_contact->>'identifier',
        'error', SQLERRM
      );
      CONTINUE;
    END;
  END LOOP;

  -- Construir resultado
  v_result := jsonb_build_object(
    'success', v_success_count > 0,
    'message', format(
      'Processados %s contatos: %s sucesso, %s erro(s)',
      v_success_count + v_error_count,
      v_success_count,
      v_error_count
    ),
    'data', jsonb_build_object(
      'success_count', v_success_count,
      'error_count', v_error_count,
      'errors', v_errors
    )
  );

  RETURN v_result;
END;
$$;

-- Comentários
COMMENT ON FUNCTION validate_contact IS 'Valida o formato de um contato baseado no seu tipo';
COMMENT ON FUNCTION update_user_contacts IS 'Atualiza os contatos de um usuário com validação e tratamento de erros';