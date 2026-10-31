-- rfn_financeiro__contazul_mrr_mensal
-- Refined / financeiro. Grao: um snapshot mensal de MRR por operacao. Le trs_contazul__mrr_snapshot (so contratos ativos).
-- Nivel: L3 CONFIDENTIAL (agregado por operacao; nenhum cliente atravessa).
-- REGRA 1: MRR do mes = soma de `mrr` das linhas do snapshot daquele ref_mes (nao soma entre meses).
-- REGRA 2: novos = contratos (id_pessoa) presentes no snapshot e ausentes do snapshot ANTERIOR da mesma operacao; saidas =
--   presentes no anterior e ausentes neste. O snapshot anterior e o ultimo existente, nao necessariamente o mes de calendario anterior.
-- REGRA 3: primeiro snapshot de cada operacao NAO tem anterior: novos e saidas saem NULL, nunca zero.
-- LIMITACOES - NAO CONTORNE: e identidade por id_pessoa, nao por contrato (um cliente com dois contratos conta uma vez em novos/saidas
--   mas soma os dois no MRR); churn aqui nao e o churn_mensal da origem (derivado dos contratos vivos); poucos meses de historico.
WITH s AS (
  SELECT ref_mes, operacao, id_pessoa, mrr FROM vanguardamartech_trusted.trs_contazul__mrr_snapshot WHERE is_ativo
),
meses AS (
  SELECT DISTINCT ref_mes, operacao FROM s
),
pares AS (
  SELECT ref_mes, operacao, LAG(ref_mes) OVER (PARTITION BY operacao ORDER BY ref_mes) AS ref_mes_anterior FROM meses
),
novos AS (
  SELECT p.ref_mes, p.operacao, COUNT(DISTINCT c.id_pessoa) AS qtd_novos, SUM(c.mrr) AS mrr_novos
  FROM pares p
  JOIN s c ON c.ref_mes = p.ref_mes AND c.operacao = p.operacao
  LEFT JOIN s a ON a.ref_mes = p.ref_mes_anterior AND a.operacao = p.operacao AND a.id_pessoa = c.id_pessoa
  WHERE p.ref_mes_anterior IS NOT NULL AND a.id_pessoa IS NULL
  GROUP BY 1, 2
),
saidas AS (
  SELECT p.ref_mes, p.operacao, COUNT(DISTINCT a.id_pessoa) AS qtd_saidas, SUM(a.mrr) AS mrr_saidas
  FROM pares p
  JOIN s a ON a.ref_mes = p.ref_mes_anterior AND a.operacao = p.operacao
  LEFT JOIN s c ON c.ref_mes = p.ref_mes AND c.operacao = p.operacao AND c.id_pessoa = a.id_pessoa
  WHERE p.ref_mes_anterior IS NOT NULL AND c.id_pessoa IS NULL
  GROUP BY 1, 2
),
base AS (
  SELECT ref_mes, operacao, COUNT(*) AS qtd_contratos, COUNT(DISTINCT id_pessoa) AS qtd_clientes, SUM(mrr) AS mrr
  FROM s GROUP BY 1, 2
)
SELECT
  CONCAT(CAST(b.ref_mes AS STRING), '|', b.operacao)      AS id_mrr_mensal,
  b.ref_mes,
  b.operacao,
  p.ref_mes_anterior,
  b.qtd_contratos,
  b.qtd_clientes,
  b.mrr,
  SAFE_DIVIDE(b.mrr, b.qtd_contratos)                     AS mrr_medio_por_contrato,
  IF(p.ref_mes_anterior IS NULL, NULL, IFNULL(n.qtd_novos, 0))   AS qtd_novos,
  IF(p.ref_mes_anterior IS NULL, NULL, IFNULL(n.mrr_novos, 0))   AS mrr_novos,
  IF(p.ref_mes_anterior IS NULL, NULL, IFNULL(sd.qtd_saidas, 0)) AS qtd_saidas,
  IF(p.ref_mes_anterior IS NULL, NULL, IFNULL(sd.mrr_saidas, 0)) AS mrr_saidas,
  'L3_CONFIDENTIAL'                                       AS classificacao_dado,
  CURRENT_TIMESTAMP()                                     AS _extraido_at,
  'supabase-x0tz'                                         AS _fonte
FROM base b
JOIN pares p ON p.ref_mes = b.ref_mes AND p.operacao = b.operacao
LEFT JOIN novos n ON n.ref_mes = b.ref_mes AND n.operacao = b.operacao
LEFT JOIN saidas sd ON sd.ref_mes = b.ref_mes AND sd.operacao = b.operacao
