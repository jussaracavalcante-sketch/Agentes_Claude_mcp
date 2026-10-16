-- Trusted / Google Ads - trs_google_ads__insight_semanal
-- Grao: uma linha por (grao, id_origem). grao = ANUNCIO (semana x anuncio) ou
-- CAMPANHA (semana x campanha, so nos pares que o Google nao publica por anuncio).
-- Fonte unica: google-ads-OzfZ (Prestex, conta 712-071-7819, camada vanguardamartech_prestex,
-- prefixo google_ads_prestex_). Gatilho: evento em google-ads-OzfZ (a fonte esta em manual).
--
-- POR QUE EXISTE E POR QUE NAO ENTRA NA trs_google_ads__insight_diario:
-- a conta Prestex e extraida em granularidade SEMANAL (performance_granularity da fonte).
-- Medido em 2026-10-16: 827 linhas em campaign_performance, TODAS com `date` numa segunda-feira
-- (zero fora), 146 semanas distintas de 2024-01-01 a 2026-10-12. As outras 40 fontes de Google Ads
-- sao diarias. Somar semana com dia na mesma tabela faria um `GROUP BY data` ou um
-- `WHERE data >= ...` tratar o investimento de sete dias como se fosse de um so.
-- A semana fica em tabela propria, com a coluna `semana_inicio` (nao `data`), de proposito.
--
-- GRAO MISTO, IGUAL AO DIARIO: ad_performance nao traz PERFORMANCE_MAX. Linhas ANUNCIO de
-- ad_performance + linhas CAMPANHA de campaign_performance so para os pares (campanha, semana)
-- ausentes dos anuncios. Medido: 827 pares (campanha, semana), 118 sem nenhuma linha de anuncio
-- (R$ 41.198,63), zero anuncio orfao, e custo_campanha - custo_sem_anuncio = custo_anuncio
-- (R$ 463.668,58 - R$ 41.198,63 = R$ 422.469,95) -- a uniao e exata, zero cobertura parcial.
-- Anti-join com DISTINCT (nao NOT EXISTS correlacionado).
--
-- `date` da origem e TIMESTAMP 00:00:00 UTC (zero linhas com hora): e data guardada como instante.
-- DATE(date) sem fuso devolve o dia certo; DATE(date,'America/Sao_Paulo') jogaria cada semana
-- para o domingo anterior. Nada e convertido.
-- A conta vem do resource_name da campanha (customers/<id>/...), nao de literal escrito a mao.
-- Cliente e moeda vem de trs_google_ads__conta (BRL, medido). LEFT JOIN + flag.
WITH
campanha_dim AS (
  SELECT
    SAFE_CAST(id AS INT64)                                   AS id_campanha,
    REGEXP_EXTRACT(resource_name, r'customers/([0-9]+)/')    AS id_conta,
    SAFE_CAST(advertising_channel_type AS STRING)            AS canal,
    SAFE_CAST(bidding_strategy_type AS STRING)               AS estrategia_lance
  FROM `vanguardamartech_prestex`.`google_ads_prestex_campaigns`
),
anuncio AS (
  SELECT
    'ANUNCIO'                                                    AS grao,
    SAFE_CAST(id AS STRING)                                      AS id_origem,
    campaign_id, campaign_name, campaign_status,
    SAFE_CAST(ad_group_id AS INT64)                              AS ad_group_id,
    NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),'')          AS ad_group_name,
    SAFE_CAST(ad_group_ad_ad_id AS INT64)                        AS ad_group_ad_ad_id,
    NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),'')    AS ad_group_ad_ad_name,
    date, metrics_cost_micros, metrics_impressions, metrics_clicks, metrics_interactions,
    metrics_video_views, metrics_conversions, metrics_conversions_value, metrics_all_conversions,
    metrics_all_conversions_value, metrics_view_through_conversions, metrics_ctr,
    metrics_interaction_rate, metrics_conversions_from_interactions_rate,
    metrics_absolute_top_impression_percentage, metrics_top_impression_percentage,
    metrics_average_cpc, metrics_average_cpm
  FROM `vanguardamartech_prestex`.`google_ads_prestex_ad_performance`
),
campanha AS (
  SELECT
    'CAMPANHA'                                                   AS grao,
    SAFE_CAST(id AS STRING)                                      AS id_origem,
    campaign_id, campaign_name, campaign_status,
    CAST(NULL AS INT64)                                          AS ad_group_id,
    CAST(NULL AS STRING)                                         AS ad_group_name,
    CAST(NULL AS INT64)                                          AS ad_group_ad_ad_id,
    CAST(NULL AS STRING)                                         AS ad_group_ad_ad_name,
    date, metrics_cost_micros, metrics_impressions, metrics_clicks, metrics_interactions,
    metrics_video_views, metrics_conversions, metrics_conversions_value, metrics_all_conversions,
    metrics_all_conversions_value, metrics_view_through_conversions, metrics_ctr,
    metrics_interaction_rate, metrics_conversions_from_interactions_rate,
    metrics_absolute_top_impression_percentage, metrics_top_impression_percentage,
    metrics_average_cpc, metrics_average_cpm
  FROM `vanguardamartech_prestex`.`google_ads_prestex_campaign_performance`
),
anuncio_chave AS (
  -- DISTINCT obrigatorio: sem ele o LEFT JOIN multiplica a linha de campanha
  -- pelo numero de anuncios do par (campanha, semana).
  SELECT DISTINCT SAFE_CAST(campaign_id AS INT64) AS id_campanha, DATE(date) AS semana
  FROM anuncio
),
crua AS (
  SELECT * FROM anuncio
  UNION ALL
  SELECT k.* FROM campanha k
  LEFT JOIN anuncio_chave a
    ON  a.id_campanha = SAFE_CAST(k.campaign_id AS INT64)
    AND a.semana      = DATE(k.date)
  WHERE a.id_campanha IS NULL
),
bruto AS (
  SELECT
    grao,
    id_origem,
    SAFE_CAST(campaign_id AS INT64)                                   AS id_campanha,
    NULLIF(TRIM(SAFE_CAST(campaign_name AS STRING)), '')              AS campanha,
    SAFE_CAST(campaign_status AS STRING)                              AS status_campanha,
    ad_group_id                                                       AS id_grupo,
    ad_group_name                                                     AS grupo,
    ad_group_ad_ad_id                                                 AS id_anuncio,
    ad_group_ad_ad_name                                               AS anuncio,
    DATE(date)                                                        AS semana_inicio,
    SAFE_CAST(metrics_cost_micros AS INT64)                           AS investimento_micros,
    SAFE_CAST(metrics_impressions AS INT64)                           AS impressoes,
    SAFE_CAST(metrics_clicks AS INT64)                                AS cliques,
    SAFE_CAST(metrics_interactions AS INT64)                          AS interacoes,
    SAFE_CAST(metrics_video_views AS INT64)                           AS visualizacoes_video,
    SAFE_CAST(metrics_conversions AS FLOAT64)                         AS conversoes,
    SAFE_CAST(metrics_conversions_value AS FLOAT64)                   AS valor_conversoes,
    SAFE_CAST(metrics_all_conversions AS FLOAT64)                     AS todas_conversoes,
    SAFE_CAST(metrics_all_conversions_value AS FLOAT64)               AS valor_todas_conversoes,
    SAFE_CAST(metrics_view_through_conversions AS INT64)              AS conversoes_view_through,
    SAFE_CAST(metrics_ctr AS FLOAT64)                                 AS ctr_fracao,
    SAFE_CAST(metrics_interaction_rate AS FLOAT64)                    AS taxa_interacao_fracao,
    SAFE_CAST(metrics_conversions_from_interactions_rate AS FLOAT64)  AS taxa_conversao_fracao,
    SAFE_CAST(metrics_absolute_top_impression_percentage AS FLOAT64)  AS impressao_topo_absoluto_fracao,
    SAFE_CAST(metrics_top_impression_percentage AS FLOAT64)           AS impressao_topo_fracao,
    SAFE_CAST(metrics_average_cpc AS FLOAT64)                         AS cpc_plataforma_micros,
    SAFE_CAST(metrics_average_cpm AS FLOAT64)                         AS cpm_plataforma_micros
  FROM crua
),
base AS (
  SELECT
    CONCAT('google-ads-OzfZ', '|', b.grao, '|', b.id_origem)          AS id_insight,
    b.*,
    TO_HEX(MD5(TO_JSON_STRING(b)))                                    AS _payload_hash
  FROM bruto b
  QUALIFY ROW_NUMBER() OVER (PARTITION BY b.grao, b.id_origem ORDER BY b.semana_inicio DESC) = 1
)
SELECT
  b.id_insight,
  c.id_conta,
  d.cliente,
  d.moeda,
  b.grao,

  b.id_campanha,
  b.campanha,
  b.status_campanha,
  c.canal,
  c.estrategia_lance,
  b.id_grupo,
  b.grupo,
  b.id_anuncio,
  b.anuncio,

  b.semana_inicio,
  DATE_ADD(b.semana_inicio, INTERVAL 6 DAY)                           AS semana_fim,
  -- A origem e semanal e a semana corrente chega parcial. A flag e gravada na CARGA
  -- (a tabela e reconstruida a cada execucao); regra de qualidade deve comparar contra
  -- DATE(_extraido_at), nunca contra CURRENT_DATE.
  DATE_ADD(b.semana_inicio, INTERVAL 6 DAY)
    >= DATE(CURRENT_TIMESTAMP(), 'America/Sao_Paulo')                 AS flag_semana_incompleta_na_carga,
  EXTRACT(DAYOFWEEK FROM b.semana_inicio) <> 2                        AS flag_semana_nao_comeca_na_segunda,

  IFNULL(b.investimento_micros, 0)                                    AS investimento_micros,
  IFNULL(b.investimento_micros, 0) / 1000000                          AS investimento,

  IFNULL(b.impressoes, 0)                                             AS impressoes,
  IFNULL(b.cliques, 0)                                                AS cliques,
  IFNULL(b.interacoes, 0)                                             AS interacoes,
  IFNULL(b.visualizacoes_video, 0)                                    AS visualizacoes_video,

  IFNULL(b.conversoes, 0)                                             AS conversoes,
  IFNULL(b.valor_conversoes, 0)                                       AS valor_conversoes,
  IFNULL(b.todas_conversoes, 0)                                       AS todas_conversoes,
  IFNULL(b.valor_todas_conversoes, 0)                                 AS valor_todas_conversoes,
  IFNULL(b.conversoes_view_through, 0)                                AS conversoes_view_through,

  b.ctr_fracao,
  b.taxa_interacao_fracao,
  b.taxa_conversao_fracao,
  b.impressao_topo_absoluto_fracao,
  b.impressao_topo_fracao,

  b.cpc_plataforma_micros,
  ROUND(SAFE_DIVIDE(b.cpc_plataforma_micros, 1000000), 4)             AS cpc_plataforma,
  b.cpm_plataforma_micros,
  ROUND(SAFE_DIVIDE(b.cpm_plataforma_micros, 1000000), 4)             AS cpm_plataforma,

  (IFNULL(b.impressoes, 0) = 0 AND IFNULL(b.investimento_micros, 0) = 0) AS sem_entrega,
  (d.id_conta IS NULL)                                                AS flag_conta_nao_catalogada,
  (c.id_campanha IS NULL)                                             AS flag_campanha_nao_catalogada,

  CURRENT_TIMESTAMP()                                                 AS _extraido_at,
  'google-ads-OzfZ'                                                   AS _fonte,
  b.id_origem,
  b._payload_hash
FROM base b
LEFT JOIN campanha_dim c
  ON c.id_campanha = b.id_campanha
LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__conta` d
  ON d.id_conta = c.id_conta
