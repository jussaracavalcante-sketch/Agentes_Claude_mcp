-- trs_financeiro__dre_cliente
-- Trusted / Financeiro. Grao: um cliente (ou grupo) em um mes sob UM de quatro METODOS de DRE por cliente calculados no Supabase:
--   SERVICO_PECAS (4.583), SERVICO_TEMPO (4.583), PI (3.763) e DIRETO (789) = 13.718 linhas, 13.718 chaves (medido em 2026-10-18).
-- Origem: mvw_dre_cliente_servico, mvw_dre_cliente_servico_tempo, mvw_dre_cliente_pi, mvw_dre_cliente_direto (fonte supabase-x0tz).
-- Nivel: L3 CONFIDENTIAL (receita, custo e margem por cliente).
-- OS QUATRO METODOS NAO SAO VERSOES UM DO OUTRO: SERVICO_PECAS e SERVICO_TEMPO somam exatamente o mesmo total (receita R$ 49.636.903,76;
--   custo direto R$ 1.685.320,80; custo de servico R$ 3.866.478,55; overhead R$ 23.684.564,24; resultado R$ 17.427.086,45) e diferem so em COMO o overhead
--   e rateado entre clientes (por pecas ou por tempo). PI cobre menos receita (R$ 41.247.879,89; resultado R$ 9.970.473,06; deducao SIMULADA).
--   DIRETO e a margem sem rateio de overhead, por cliente e por escopo de housing. Somar metodos duplica o resultado: sempre filtrar por metodo.
-- grupo_key e o agrupamento do SUPABASE (raiz de CNPJ de 8 digitos, 'G:' grupo, 'N:' por nome, '(...)' placeholder). NAO e decisao desta casa e NAO
--   vale como chave de conta (R-003): contas de mesmo prefixo nao se fundem aqui.
-- deducao_tipo: RATEADA (SERVICO_*, DIRETO) ou SIMULADA (PI, com aliquota_pct e aliquota_fonte). Colunas que o metodo nao tem saem NULL, nunca zero.
SELECT
  CONCAT(metodo, '|', CAST(ano AS STRING), '|', CAST(mes AS STRING), '|', IFNULL(grupo_key, IFNULL(grupo_nome, '-')), '|', IFNULL(escopo, '-'), '|', IFNULL(CAST(setor_id AS STRING), '-')) AS id_linha,
  a.*,
  DATE(ano, mes, 1)                                  AS mes_referencia,
  'L3_CONFIDENTIAL'                                  AS classificacao_dado,
  CURRENT_TIMESTAMP()                                AS _extraido_at,
  'supabase-x0tz'                                    AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(a)))                     AS _payload_hash
FROM (
  SELECT 'SERVICO_PECAS' AS metodo, ano, mes, grupo_key, grupo_nome, eh_nao_atribuido, CAST(NULL AS STRING) AS escopo, CAST(NULL AS INT64) AS setor_id, CAST(NULL AS STRING) AS rotulo,
         receita_cliente, receita_bv, receita_total, deducao_rateada AS deducao, 'RATEADA' AS deducao_tipo, CAST(NULL AS FLOAT64) AS aliquota_pct, CAST(NULL AS STRING) AS aliquota_fonte,
         custo_direto, custo_servico, overhead, margem_servico, CAST(NULL AS FLOAT64) AS margem_direta, resultado
  FROM vanguardamartech_raw.supabase_gold_mvw_dre_cliente_servico
  UNION ALL
  SELECT 'SERVICO_TEMPO', ano, mes, grupo_key, grupo_nome, eh_nao_atribuido, NULL, NULL, NULL,
         receita_cliente, receita_bv, receita_total, deducao_rateada, 'RATEADA', NULL, NULL,
         custo_direto, custo_servico, overhead, margem_servico, NULL, resultado
  FROM vanguardamartech_raw.supabase_gold_mvw_dre_cliente_servico_tempo
  UNION ALL
  SELECT 'PI', ano, mes, grupo_key, grupo_nome, eh_nao_atribuido, NULL, NULL, NULL,
         receita_cliente, receita_bv_pi, receita_total, deducao_simulada, 'SIMULADA', aliquota_pct, aliquota_fonte,
         custo_direto, custo_servico, overhead, margem_servico, NULL, resultado
  FROM vanguardamartech_raw.supabase_gold_mvw_dre_cliente_pi
  UNION ALL
  SELECT 'DIRETO', ano, mes, CAST(NULL AS STRING), cliente_nome, CAST(NULL AS BOOL), escopo, CAST(setor_id AS INT64), rotulo,
         receita_cliente, receita_bv, receita_total, deducao_rateada, 'RATEADA', NULL, NULL,
         custo_direto, NULL, NULL, NULL, margem_direta, NULL
  FROM vanguardamartech_raw.supabase_gold_mvw_dre_cliente_direto
) a
