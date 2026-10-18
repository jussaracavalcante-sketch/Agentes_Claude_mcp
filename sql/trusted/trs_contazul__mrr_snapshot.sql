-- trs_contazul__mrr_snapshot
-- Trusted / Conta Azul. Grao: um contrato (cliente) em um snapshot mensal de MRR. Chave composta id_snapshot =
-- ref_mes|operacao|id_pessoa (446 distintos em 446, 2026-10-18; 5 meses de referencia).
-- Origem: vanguardamartech_raw.supabase_conta_azul_ca_snapshot_contrato (fonte supabase-x0tz). Nivel: L3 CONFIDENTIAL.
-- E SNAPSHOT: o mes ja tirado nao se recalcula a partir do razao. vw_mrr_mensal/vw_churn_mensal sao derivadas de contratos vivos.
SELECT
  CONCAT(CAST(ref_mes AS STRING), '|', operacao, '|', IFNULL(id_pessoa, ''))  AS id_snapshot,
  ref_mes,
  data_snapshot,
  operacao,
  NULLIF(REGEXP_REPLACE(IFNULL(cnpj, ''), r'[^0-9]', ''), '')                AS cnpj_operacao,
  id_pessoa,
  NULLIF(TRIM(cliente), '')                                                  AS cliente,
  mrr,
  ativo                                                                      AS is_ativo,
  'L3_CONFIDENTIAL'                                                          AS classificacao_dado,
  CURRENT_TIMESTAMP()                                                        AS _extraido_at,
  'supabase-x0tz'                                                            AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(s)))                                             AS _payload_hash
FROM vanguardamartech_raw.supabase_conta_azul_ca_snapshot_contrato s
