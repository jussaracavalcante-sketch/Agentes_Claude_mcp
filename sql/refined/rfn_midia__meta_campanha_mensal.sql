-- rfn_midia__meta_campanha_mensal
-- Refined / dominio Midia. Grao: uma linha por (id_conta, id_campanha, mes_referencia). Chave id_meta_campanha_mensal.
-- Le trs_facebook_ads__insight_diario (grao anuncio-dia) + __campanha + __conta, na camada Trusted Facebook Ads.
-- Gatilho: evento nas duas Trusted de origem que disparam por cron terca 13:35 (query-QXqC e query-7aLj), regra all.
-- A dimensao de conta (query-HCcd, cron diario 03:00) NAO entra no gatilho: com regra all misturaria cadencias.
-- Derivados (CTR, CPC, CPM, CPA, ROAS) RECALCULADOS DOS TOTAIS, nunca herdados linha a linha nem com AVG.
-- ALCANCE E FREQUENCIA NAO SAO EMITIDOS DE PROPOSITO: alcance e de pessoas distintas e nao e aditivo
-- (somar anuncios e dias conta a mesma pessoa varias vezes). O desempenho de alcance por campanha-mes exigiria
-- uma consulta propria ao Meta no nivel campanha, que esta extracao nao faz.
WITH fato AS (
  SELECT
    i.id_conta,
    i.id_campanha,
    i.mes_referencia,
    MAX(i.campanha)                                                       AS campanha_no_insight,
    COUNT(DISTINCT i.id_anuncio)                                          AS qtd_anuncios,
    COUNT(DISTINCT i.data)                                                AS qtd_dias_com_linha,
    COUNT(DISTINCT IF(i.investimento > 0 OR i.impressoes > 0, i.data, NULL)) AS qtd_dias_com_entrega,
    MIN(i.data)                                                           AS primeira_data,
    MAX(i.data)                                                           AS ultima_data,
    -- spend em unidade de moeda com 2 decimais; micros (INT64) so para somar sem deriva de FLOAT64
    CAST(ROUND(SUM(i.investimento) * 1000000) AS INT64)                   AS investimento_micros,
    SUM(i.impressoes)                                                     AS impressoes,
    SUM(i.cliques)                                                        AS cliques,
    SUM(i.cliques_no_link)                                                AS cliques_no_link,
    SUM(i.engajamento_post)                                               AS engajamento_post,
    SUM(COALESCE(i.leads, 0))                                             AS conversoes_leads,
    SUM(COALESCE(i.compras, 0))                                           AS conversoes_compras,
    SUM(COALESCE(i.conversas_iniciadas_7d, 0))                            AS conversoes_conversas,
    -- NULL quando NENHUMA linha tem receita de compra (conta que nao e e-commerce): ausencia, nao zero
    SUM(i.receita_compras)                                                AS valor_compras,
    SUM(COALESCE(i.visualizacoes_video, 0))                               AS visualizacoes_video,
    LOGICAL_OR(i.conta_defasada)                                          AS conta_defasada,
    MAX(i._extraido_at)                                                   AS _extraido_at
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario` i
  GROUP BY i.id_conta, i.id_campanha, i.mes_referencia
),

calc AS (
  SELECT
    f.*,
    f.investimento_micros / 1000000                                       AS inv,
    f.conversoes_leads + f.conversoes_compras + f.conversoes_conversas    AS conversoes
  FROM fato f
)

SELECT
  CONCAT(f.id_conta, '|', f.id_campanha, '|', FORMAT_DATE('%Y%m', f.mes_referencia)) AS id_meta_campanha_mensal,
  'FACEBOOK_ADS'                                                          AS plataforma,
  f.id_conta,
  a.conta                                                                 AS conta_na_plataforma,
  -- R-003: cliente = nome da conta, nunca o do grupo
  a.cliente,
  a.moeda,
  a.fuso_conta,
  a.status_conta                                                          AS status_conta_atual,

  f.mes_referencia,

  f.id_campanha,
  COALESCE(c.campanha, f.campanha_no_insight)                             AS campanha,
  c.objetivo,
  c.objetivo_canonico,
  c.geracao_objetivo,
  c.status_efetivo                                                        AS status_campanha_atual,
  c.ativa                                                                 AS campanha_ativa,

  f.qtd_anuncios,
  f.qtd_dias_com_linha,
  f.qtd_dias_com_entrega,
  f.primeira_data,
  f.ultima_data,

  f.investimento_micros,
  ROUND(f.inv, 2)                                                         AS investimento,
  f.impressoes,
  f.cliques,
  f.cliques_no_link,
  f.engajamento_post,
  f.visualizacoes_video,
  f.conversoes_leads,
  f.conversoes_compras,
  f.conversoes_conversas,
  f.conversoes,
  f.valor_compras,

  ROUND(SAFE_DIVIDE(f.cliques, f.impressoes) * 100, 2)                    AS ctr_pct,
  ROUND(SAFE_DIVIDE(f.inv, f.cliques), 2)                                 AS cpc,
  ROUND(SAFE_DIVIDE(f.inv, f.impressoes) * 1000, 2)                       AS cpm,
  ROUND(SAFE_DIVIDE(f.inv, f.conversoes), 2)                              AS cpa,
  ROUND(SAFE_DIVIDE(f.inv, f.conversoes_leads), 2)                        AS custo_por_lead,
  ROUND(SAFE_DIVIDE(f.inv, f.conversoes_conversas), 2)                    AS custo_por_conversa,
  ROUND(SAFE_DIVIDE(f.valor_compras, f.inv), 2)                           AS roas,

  f.mes_referencia = DATE_TRUNC(DATE(f._extraido_at, 'America/Sao_Paulo'), MONTH) AS flag_mes_parcial_na_carga,
  f.conta_defasada,
  c.id_campanha IS NULL                                                   AS flag_campanha_nao_catalogada,
  a.id_conta    IS NULL                                                   AS flag_conta_nao_catalogada,
  NOT (c.id_campanha IS NULL OR a.id_conta IS NULL)                       AS registro_confiavel,
  a.dimensao_congelada                                                    AS dimensao_conta_congelada,

  f._extraido_at
FROM calc f
LEFT JOIN `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__campanha` c
  ON c.id_campanha = f.id_campanha
LEFT JOIN `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conta` a
  ON a.id_conta = f.id_conta
