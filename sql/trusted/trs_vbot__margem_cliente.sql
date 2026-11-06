-- trs_vbot__margem_cliente
-- Trusted / VBOT. Grao: um cliente (cliente_key) em um periodo (mes), com a receita do Conexa e o custo da plataforma white-label (Helena) ligados por NOME.
-- Chave (periodo, cliente_key, operacao): 765 distintos em 765 linhas, 12 periodos (2025-12 a 2026-11), medido em 2026-10-18.
-- Origem: vanguardamartech_raw.supabase_gold_vw_margem_vbot_cliente (fonte supabase-x0tz). Nivel: L3 CONFIDENTIAL (receita, custo e margem por cliente).
-- LIGACAO POR NOME, NAO POR DOCUMENTO: `origem_match` diz como a conta do white-label foi ligada ao cliente do Conexa — RAZAO (333 linhas), CURADORIA (76, ligacao manual),
--   FANTASIA (66, nome fantasia), INTERNA (47, conta da casa, sem receita), SEM MATCH (28, custo sem cliente) e SO RECEITA (215, receita sem conta de custo). Nenhum
--   casamento e por CNPJ: e hipotese declarada, nao prova (R-003/R-004). `sem_cliente` = custo que nao achou cliente (47 linhas: INTERNA + SEM MATCH).
-- O CUSTO SO EXISTE ATE 2026-08: nos periodos 2026-09 em diante custo_helena e ZERO na origem porque a fatura do white-label ainda nao foi apurada, nao porque custou zero.
--   Aqui o zero sai como veio; a Refined e quem separa. margem_pct NULL em 147 linhas (sem receita). margem = receita_conexa - custo_helena; margem_liquida desconta o
--   desconto e o dominio rateados. Percentuais vem da origem e nao se recalculam aqui (nao se mexe em metrica derivada na Trusted).
SELECT
  CONCAT(periodo, '|', cliente_key, '|', operacao)  AS id_linha,
  periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(periodo, '-01')) AS mes_referencia,
  cliente_key,
  NULLIF(TRIM(cliente), '')                         AS cliente,
  operacao,
  NULLIF(TRIM(origem_match), '')                    AS origem_match,
  sem_cliente                                       AS is_sem_cliente,
  n_contas                                          AS qtd_contas,
  NULLIF(TRIM(contas), '')                          AS contas,
  receita_conexa,
  custo_helena,
  margem,
  margem_pct,
  desconto_rateado,
  dominio_rateado,
  custo_liquido,
  margem_liquida,
  margem_liquida_pct,
  custo_contas,
  custo_infra,
  custo_instancias,
  atendimentos                                      AS qtd_atendimentos,
  mau                                               AS qtd_mau,
  n_instancias                                      AS qtd_instancias,
  n_ociosas                                         AS qtd_instancias_ociosas,
  'L3_CONFIDENTIAL'                                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                               AS _extraido_at,
  'supabase-x0tz'                                   AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(m)))                    AS _payload_hash
FROM vanguardamartech_raw.supabase_gold_vw_margem_vbot_cliente m
