-- trs_contazul__nota_fiscal
-- Trusted / Conta Azul. Grao: uma nota fiscal emitida (NFSE ou outra). Chave: id_nota (1.289 distintos em 1.289, medido em 2026-10-18).
-- Origem: vanguardamartech_raw.supabase_conta_azul_ca_fato_nota_fiscal (fonte supabase-x0tz). Nivel: L4 PERSONAL_DATA
-- (nome e documento do cliente; ha CPF). Documento: so e documento o que tem 14 ou 11 digitos; o cru fica em documento_origem.
-- status da origem preservado (CANCELAMENTO_MANUAL e afins): nota cancelada continua na tabela, com is_cancelada.
SELECT
  id_nota,
  operacao,
  NULLIF(TRIM(tipo), '')                        AS tipo,
  NULLIF(TRIM(numero_nf), '')                   AS numero_nf,
  NULLIF(TRIM(numero_nfse), '')                 AS numero_nfse,
  NULLIF(TRIM(numero_rps), '')                  AS numero_rps,
  NULLIF(TRIM(numero_venda), '')                AS numero_venda,
  chave_acesso,
  id_venda,
  id_pessoa,
  NULLIF(TRIM(status), '')                      AS status_origem,
  REGEXP_CONTAINS(IFNULL(status, ''), r'CANCEL') AS is_cancelada,
  data_emissao,
  data_competencia,
  DATE_TRUNC(data_competencia, MONTH)           AS mes_competencia,
  valor,
  flag_projecao                                 AS is_projecao,
  ano_referencia,
  NULLIF(TRIM(nome_cliente), '')                AS nome_cliente,
  NULLIF(REGEXP_REPLACE(IFNULL(documento_cliente, ''), r'[^0-9]', ''), '') AS documento_origem,
  IF(LENGTH(REGEXP_REPLACE(IFNULL(documento_cliente, ''), r'[^0-9]', '')) IN (11, 14),
     REGEXP_REPLACE(documento_cliente, r'[^0-9]', ''), NULL)               AS documento_cliente,
  NULLIF(TRIM(codigo_cnae), '')                 AS codigo_cnae,
  NULLIF(TRIM(cidade_emissao), '')              AS cidade_emissao,
  NULLIF(TRIM(estado_emissao), '')              AS estado_emissao,
  escriturado_manualmente                       AS is_escriturado_manualmente,
  ca_updated_at,
  processed_at,
  'L4_PERSONAL_DATA'                            AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz'                               AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(n)))                AS _payload_hash
FROM vanguardamartech_raw.supabase_conta_azul_ca_fato_nota_fiscal n
