-- trs_contazul__venda
-- Trusted / Conta Azul. Grao: uma venda (ou contrato agendado) do razao Conta Azul. Chave: id_venda
-- (3.070 distintos em 3.070 linhas, medido em 2026-10-18).
-- Origem: vanguardamartech_raw.supabase_conta_azul_ca_fato_venda (fonte supabase-x0tz). Nivel: L3 CONFIDENTIAL.
-- REGRA 1: removido_em preenchido = removida na origem; a linha fica com is_removido/is_vigente (marcar, nunca apagar).
-- REGRA 2: data_venda vai ate o futuro (vendas agendadas, tipo SCHEDULED_SALE): is_agendada separa.
-- id_legado '0' e sentinela (ponte para o historico de vendas do iClips) e sai NULL.
SELECT
  id_venda,
  operacao,
  NULLIF(TRIM(numero), '')                      AS numero,
  id_pessoa,
  id_vendedor,
  data_venda,
  DATE_TRUNC(data_venda, MONTH)                 AS mes_venda,
  data_alteracao,
  NULLIF(TRIM(situacao), '')                    AS situacao,
  NULLIF(TRIM(tipo), '')                        AS tipo,
  (tipo = 'SCHEDULED_SALE')                     AS is_agendada,
  valor_total,
  flag_projecao                                 AS is_projecao,
  ano_referencia,
  NULLIF(NULLIF(TRIM(id_legado), '0'), '')      AS id_legado_iclips,
  criado_em,
  removido_em,
  (removido_em IS NOT NULL)                     AS is_removido,
  (removido_em IS NULL)                         AS is_vigente,
  visto_em,
  criado_em_dw,
  ca_updated_at,
  processed_at,
  'L3_CONFIDENTIAL'                             AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz'                               AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(v)))                AS _payload_hash
FROM vanguardamartech_raw.supabase_conta_azul_ca_fato_venda v
