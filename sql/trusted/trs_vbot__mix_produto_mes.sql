-- trs_vbot__mix_produto_mes
-- Trusted / VBOT. Grao: um cliente x produto em um fechamento mensal do mix de produtos (assinatura e servicos) da VBOT.
-- Chave (periodo, customer_id, produto_id, tipo): 1.475 distintos em 1.475 linhas, 4 fechamentos (2026-07 a 2026-10), 121 clientes, 7 familias (medido em 2026-10-18).
-- Origem: vanguardamartech_raw.supabase_gold_fato_mix_vbot_mes (fonte supabase-x0tz). Nivel: L3 CONFIDENTIAL (receita por cliente e produto).
-- `tipo` = plano (assinatura-base) ou servico (complementar e pontual): produto_id vem de tabelas diferentes conforme o tipo, por isso tipo entra na chave.
-- E FOTOGRAFIA de fim de mes (captured_at): cada periodo e um retrato e a soma de mrr entre periodos conta o mesmo cliente varias vezes (R$ 725.972,79 somados nos 4).
-- assina_hoje descreve o estado na data da captura, nao no periodo. customer_id e o id do cliente no Conexa (liga a trs_conexa__cliente).
SELECT
  CONCAT(periodo, '|', CAST(customer_id AS STRING), '|', CAST(produto_id AS STRING), '|', tipo)   AS id_linha,
  periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(periodo, '-01'))   AS mes_referencia,
  CAST(customer_id AS STRING)                           AS id_cliente_conexa,
  CAST(produto_id AS STRING)                            AS id_produto,
  NULLIF(TRIM(cliente), '')                             AS cliente,
  NULLIF(TRIM(produto), '')                             AS produto,
  NULLIF(TRIM(familia), '')                             AS familia,
  NULLIF(TRIM(tipo), '')                                AS tipo,
  assina_hoje                                           AS is_assina_hoje,
  mrr,
  n_assinaturas                                         AS qtd_assinaturas,
  receita_pontual,
  n_compras                                             AS qtd_compras,
  captured_at,
  'L3_CONFIDENTIAL'                                     AS classificacao_dado,
  CURRENT_TIMESTAMP()                                   AS _extraido_at,
  'supabase-x0tz'                                       AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(x)))                        AS _payload_hash
FROM vanguardamartech_raw.supabase_gold_fato_mix_vbot_mes x
