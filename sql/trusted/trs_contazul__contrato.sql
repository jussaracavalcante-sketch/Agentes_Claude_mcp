-- trs_contazul__contrato
-- Trusted / Conta Azul. Grao: um contrato recorrente nativo do Conta Azul. Chave: id_contrato (390 distintos em 390, 2026-10-18).
-- Origem: vanguardamartech_raw.supabase_conta_azul_ca_contrato (fonte supabase-x0tz): o contrato chega como JSON em `payload`
-- e e desaninhado aqui (id, numero, status, total, termos, cliente, conta financeira). Nivel: L3 CONFIDENTIAL.
-- `valor_total` do payload e STRING e vira FLOAT64 por SAFE_CAST. vw_contrato_nativo (390 linhas) e a mesma tabela desaninhada.
SELECT
  id                                                          AS id_contrato,
  operacao,
  id_vendedor,
  SAFE_CAST(JSON_VALUE(payload, '$.numero') AS INT64)         AS numero,
  NULLIF(JSON_VALUE(payload, '$.status'), '')                 AS status_origem,
  SAFE_CAST(JSON_VALUE(payload, '$.total') AS FLOAT64)        AS valor_total,
  SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(payload, '$.data_inicio'))     AS data_inicio,
  SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(payload, '$.termos.data_fim')) AS data_fim,
  NULLIF(JSON_VALUE(payload, '$.termos.tipo_expiracao'), '')  AS tipo_expiracao,
  SAFE_CAST(JSON_VALUE(payload, '$.termos.vigencia_atual') AS INT64) AS vigencia_atual,
  SAFE_CAST(JSON_VALUE(payload, '$.termos.vigencia_total') AS INT64) AS vigencia_total,
  NULLIF(JSON_VALUE(payload, '$.cliente.id'), '')             AS id_pessoa,
  NULLIF(TRIM(JSON_VALUE(payload, '$.cliente.nome')), '')     AS cliente_nome,
  NULLIF(JSON_VALUE(payload, '$.tipo_pagamento'), '')         AS tipo_pagamento,
  NULLIF(JSON_VALUE(payload, '$.conta_financeira.id'), '')    AS id_conta_financeira,
  SAFE.PARSE_DATE('%Y-%m-%d', NULLIF(JSON_VALUE(payload, '$.proximo_vencimento'), '')) AS proximo_vencimento,
  SAFE_CAST(JSON_VALUE(payload, '$.total_proximo_vencimento') AS FLOAT64) AS valor_proximo_vencimento,
  (JSON_VALUE(payload, '$.status') = 'ATIVO')                 AS is_ativo,
  fetched_at,
  'L3_CONFIDENTIAL'                                           AS classificacao_dado,
  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  'supabase-x0tz'                                             AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(c)))                              AS _payload_hash
FROM vanguardamartech_raw.supabase_conta_azul_ca_contrato c
