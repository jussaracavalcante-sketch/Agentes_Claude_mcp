-- trs_contazul__funil_faturamento
-- Trusted / Conta Azul. Grao: uma parcela a receber no funil de faturamento. Chave: id_parcela
-- (2.087 distintos em 2.087 linhas, medido em 2026-10-18).
-- Origem: vanguardamartech_raw.supabase_conta_azul_vw_funil_faturamento (fonte supabase-x0tz).
-- Nivel: L3 CONFIDENTIAL (valor por cliente). Nao emite e-mail, telefone nem a URL da cobranca.
--
-- E o unico lugar onde existe o estagio da parcela (faturada, enviada, nf_emitida, paga): a pergunta
-- "o que esta por faturar" dos setores Financeiro e Account. NAO e derivado do razao: tem 2.087 linhas
-- contra 2.522 parcelas a receber vigentes em trs_contazul__movimento.
SELECT
  id_parcela,
  operacao,
  REGEXP_REPLACE(IFNULL(cnpj, ''), r'[^0-9]', '')           AS cnpj_operacao,
  id_pessoa,
  NULLIF(TRIM(cliente), '')                                 AS cliente,
  NULLIF(TRIM(descricao), '')                               AS descricao,
  data_competencia,
  DATE_TRUNC(data_competencia, MONTH)                       AS mes_competencia,
  data_vencimento,
  valor,
  valor_nao_pago,
  NULLIF(TRIM(cobranca_status_entrega), '')                 AS cobranca_status_entrega,
  (cobranca_url IS NOT NULL AND TRIM(cobranca_url) <> '')   AS tem_cobranca_url,
  NULLIF(TRIM(metodo_pagamento), '')                        AS metodo_pagamento,
  NULLIF(TRIM(status), '')                                  AS status_origem,
  faturado                                                  AS is_faturado,
  enviada                                                   AS is_enviada,
  nf_emitida                                                AS is_nf_emitida,
  pago                                                      AS is_pago,
  NULLIF(TRIM(estagio), '')                                 AS estagio,
  flag_migrado                                              AS is_migrado,
  recorrente                                                AS is_recorrente,
  NULLIF(TRIM(categoria), '')                               AS categoria,
  NULLIF(TRIM(tipo_venda), '')                              AS tipo_venda,
  NULLIF(TRIM(vendedor), '')                                AS vendedor,
  (id_pessoa IS NULL)                                       AS flag_sem_pessoa,
  'L3_CONFIDENTIAL'                                         AS classificacao_dado,
  CURRENT_TIMESTAMP()                                       AS _extraido_at,
  'supabase-x0tz'                                           AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(f)))                            AS _payload_hash
FROM vanguardamartech_raw.supabase_conta_azul_vw_funil_faturamento f
