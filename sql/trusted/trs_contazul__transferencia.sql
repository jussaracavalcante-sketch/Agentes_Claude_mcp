-- trs_contazul__transferencia
-- Trusted / Conta Azul. Grao: uma transferencia entre contas financeiras proprias. Chave: id_transferencia (286 em 286, 2026-10-18).
-- Origem: vanguardamartech_raw.supabase_conta_azul_ca_fato_transferencia (fonte supabase-x0tz). Nivel: L3 CONFIDENTIAL.
-- Transferencia entre contas proprias NAO e receita nem custo: nao entra em resultado. Aqui e o fato unico (um lado so);
-- o par pagar/receber no razao e separado em trs_contazul__movimento.classe_financeira = TRANSFERENCIA.
SELECT
  id_transferencia,
  operacao,
  data                                          AS data_transferencia,
  valor,
  id_conta_origem,
  id_conta_destino,
  NULLIF(TRIM(descricao), '')                   AS descricao,
  ano_referencia,
  ca_updated_at,
  processed_at,
  'L3_CONFIDENTIAL'                             AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz'                               AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(t)))                AS _payload_hash
FROM vanguardamartech_raw.supabase_conta_azul_ca_fato_transferencia t
