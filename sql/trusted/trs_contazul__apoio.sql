-- trs_contazul__apoio
-- Trusted / Conta Azul. Grao: um cadastro de apoio do razao, identificado por (origem, id_apoio). Reune as dimensoes pequenas:
-- CENTRO_CUSTO (115), VENDEDOR (41), CATEGORIA_DRE (26), SERVICO (29), CONTA_FINANCEIRA (64), CATEGORIA (631) =
-- 906 linhas, 906 chaves (2026-10-18). Origem: vanguardamartech_raw.supabase_conta_azul_ca_dim_* (fonte supabase-x0tz).
-- Nivel: L3 CONFIDENTIAL (saldo por conta bancaria; nome de vendedor). O esquema e comum por convencao:
--   codigo = entrada_dre (CATEGORIA) | codigo (CATEGORIA_DRE) | sku (SERVICO); ordem = versao (CATEGORIA) | ordem (CATEGORIA_DRE);
--   flag = considera_custo_dre (CATEGORIA) | indica_totalizador (CATEGORIA_DRE); valor_num = saldo_atual (CONTA_FINANCEIRA)
--   | valor_venda (SERVICO); data_ref = saldo_atualizado_em (CONTA_FINANCEIRA).
-- id_centro_custo resolve 2.841 de 2.841 parcelas vigentes de trs_contazul__movimento; id_categoria resolve 5.503 de 5.504.
-- Categoria vem de duas operacoes (BRM e VD): 631 categorias, o mesmo nome pode aparecer em operacoes diferentes.
SELECT
  a.*,
  'L3_CONFIDENTIAL'                  AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(a)))     AS _payload_hash
FROM (
  SELECT 'CENTRO_CUSTO' AS origem, id_centro_custo AS id_apoio, operacao, NULLIF(TRIM(nome), '') AS nome,
         CAST(NULL AS STRING) AS tipo, CAST(NULL AS STRING) AS status, CAST(NULL AS STRING) AS id_pai,
         CAST(NULL AS STRING) AS codigo, CAST(NULL AS INT64) AS ordem, CAST(NULL AS BOOL) AS flag,
         CAST(NULL AS FLOAT64) AS valor_num, CAST(NULL AS TIMESTAMP) AS data_ref, processed_at
  FROM vanguardamartech_raw.supabase_conta_azul_ca_dim_centro_custo
  UNION ALL
  SELECT 'VENDEDOR', id_vendedor, operacao, NULLIF(TRIM(nome), ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, processed_at
  FROM vanguardamartech_raw.supabase_conta_azul_ca_dim_vendedor
  UNION ALL
  SELECT 'CATEGORIA_DRE', id_categoria_dre, CAST(NULL AS STRING), NULLIF(TRIM(nome), ''), NULL, NULL, id_categoria, codigo, ordem, indica_totalizador, NULL, NULL, processed_at
  FROM vanguardamartech_raw.supabase_conta_azul_ca_dim_categoria_dre
  UNION ALL
  SELECT 'SERVICO', id_produto, operacao, NULLIF(TRIM(nome), ''), tipo, status, NULL, NULLIF(TRIM(sku), ''), NULL, NULL, valor_venda, NULL, processed_at
  FROM vanguardamartech_raw.supabase_conta_azul_ca_dim_servico
  UNION ALL
  SELECT 'CONTA_FINANCEIRA', id_conta_financeira, operacao, NULLIF(TRIM(nome), ''), tipo, NULL, NULL, NULL, NULL, NULL, saldo_atual, saldo_atualizado_em, processed_at
  FROM vanguardamartech_raw.supabase_conta_azul_ca_dim_conta_financeira
  UNION ALL
  SELECT 'CATEGORIA', id_categoria, operacao, NULLIF(TRIM(nome), ''), tipo, NULL, id_categoria_pai, NULLIF(TRIM(entrada_dre), ''), versao, considera_custo_dre, NULL, NULL, processed_at
  FROM vanguardamartech_raw.supabase_conta_azul_ca_dim_categoria
) a
