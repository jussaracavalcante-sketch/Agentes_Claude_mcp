-- trs_facebook_ads__insight_diario
--
-- *** ESTE ARQUIVO ESTA A FRENTE DA PRODUCAO ***
-- Em 2026-09-04 as fontes passaram a rodar semanalmente (tercas). Com isso o
-- limiar de conta_defasada deveria subir de > 2 para > 9 dias, senao a flag
-- acusa TODA conta TODO dia e vira alarme constante -- pior que nao ter flag.
-- A mudanca esta aplicada aqui mas NAO foi publicada na query-QXqC, porque a
-- conta da Nekt esta sem saldo e nao se pode fazer deploy.
-- ATE O DEPLOY, A PRODUCAO USA > 2 E A FLAG conta_defasada NAO E CONFIAVEL:
-- ela vai marcar todas as 7 contas como defasadas a partir do segundo dia
-- depois de cada terca. Ignore-a ate isto ser publicado.
--
-- Trusted consolidada de Facebook Ads: 7 contas de 6 clientes numa tabela so.
-- Grao: um anuncio por dia. Chave (id_anuncio, data).
-- Padrao herdado de query-OTSI (Acesso Saude), validado em 26/08/2026.
WITH uniao AS (
  SELECT
    'facebook-ads-Si4U' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudeadsinsights` i
  UNION ALL
  SELECT
    'facebook-ads-kQ2S' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragaadsinsights` i
  UNION ALL
  SELECT
    'facebook-ads-GWZ2' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_adsinsights` i
  UNION ALL
  SELECT
    'facebook-ads-x4yO' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojaadsinsights` i
  UNION ALL
  SELECT
    'facebook-ads-ln1a' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiaadsinsights` i
  UNION ALL
  SELECT
    'facebook-ads-E9RT' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_best_car`.`facebook_ads_best_caradsinsights` i
  UNION ALL
  SELECT
    'facebook-ads-oB7d' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_adsinsights` i
),

base AS (
  SELECT
    u._fonte,
    u.id                                               AS id_insight,
    u.account_id                                       AS id_conta,
    u.account_name                                     AS conta,
    u.account_name                                     AS cliente,
    u.campaign_id                                      AS id_campanha,
    u.campaign_name                                    AS campanha,
    u.adset_id                                         AS id_conjunto,
    u.adset_name                                       AS conjunto,
    u.ad_id                                            AS id_anuncio,
    u.ad_name                                          AS anuncio,
    SAFE_CAST(u.date_start AS DATE)                    AS data,
    SAFE_CAST(u.date_stop AS DATE)                     AS data_fim,
    DATE_TRUNC(SAFE_CAST(u.date_start AS DATE), MONTH) AS mes_referencia,

    SAFE_CAST(u.spend AS FLOAT64)                      AS investimento,
    SAFE_CAST(u.impressions AS INT64)                  AS impressoes_raw,
    SAFE_CAST(u.reach AS INT64)                        AS alcance_raw,
    SAFE_CAST(u.clicks AS INT64)                       AS cliques_raw,
    SAFE_CAST(u.inline_link_clicks AS INT64)           AS cliques_no_link_raw,
    SAFE_CAST(u.inline_post_engagement AS INT64)       AS engajamento_post_raw,
    SAFE_CAST(u.frequency AS FLOAT64)                  AS frequencia,

    SAFE_CAST(u.cpc AS FLOAT64)                        AS cpc_plataforma,
    SAFE_CAST(u.cpm AS FLOAT64)                        AS cpm_plataforma,
    SAFE_CAST(u.cpp AS FLOAT64)                        AS cpp_plataforma,
    SAFE_CAST(u.ctr AS FLOAT64)                        AS ctr_plataforma,
    SAFE_CAST(u.inline_link_click_ctr AS FLOAT64)      AS ctr_link_plataforma,

    NULLIF(u.quality_ranking, 'UNKNOWN')               AS ranking_qualidade,
    NULLIF(u.engagement_rate_ranking, 'UNKNOWN')       AS ranking_engajamento,
    NULLIF(u.conversion_rate_ranking, 'UNKNOWN')       AS ranking_conversao,

    u.acoes,
    u.valores_acao,
    u._payload_hash
  FROM uniao u
),

-- ultima data COM ENTREGA por conta: e o que revela fonte parada.
-- Dia sem entrega nao conta como sinal de vida.
frescor AS (
  SELECT
    id_conta,
    MAX(IF(investimento > 0 OR impressoes_raw > 0, data, NULL)) AS ultima_data_com_entrega
  FROM base
  GROUP BY id_conta
)

SELECT
  b._fonte,
  b.id_insight,
  b.id_conta, b.conta, b.cliente,
  b.id_campanha, b.campanha,
  b.id_conjunto, b.conjunto,
  b.id_anuncio, b.anuncio,

  b.data, b.data_fim, b.mes_referencia,

  b.investimento,
  IF(b.investimento = 0, IFNULL(b.impressoes_raw, 0),       b.impressoes_raw)       AS impressoes,
  IF(b.investimento = 0, IFNULL(b.alcance_raw, 0),          b.alcance_raw)          AS alcance,
  IF(b.investimento = 0, IFNULL(b.cliques_raw, 0),          b.cliques_raw)          AS cliques,
  IF(b.investimento = 0, IFNULL(b.cliques_no_link_raw, 0),  b.cliques_no_link_raw)  AS cliques_no_link,
  IF(b.investimento = 0, IFNULL(b.engajamento_post_raw, 0), b.engajamento_post_raw) AS engajamento_post,
  b.frequencia,

  b.cpc_plataforma, b.cpm_plataforma, b.cpp_plataforma,
  b.ctr_plataforma, b.ctr_link_plataforma,

  b.ranking_qualidade, b.ranking_engajamento, b.ranking_conversao,

  b.acoes,

  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'onsite_conversion.messaging_conversation_started_7d')AS conversas_iniciadas_7d,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'onsite_conversion.messaging_first_reply')AS primeiras_respostas,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'onsite_conversion.total_messaging_connection')AS conexoes_mensagem,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'lead')                            AS leads,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'purchase')                        AS compras,
  (SELECT SUM(a.valor) FROM UNNEST(b.valores_acao) a WHERE a.tipo = 'purchase')                 AS receita_compras,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'link_click')                      AS cliques_link_acao,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'landing_page_view')               AS visitas_landing_page,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'video_view')                      AS visualizacoes_video,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'page_engagement')                 AS engajamento_pagina,

  (b.impressoes_raw IS NULL AND b.investimento = 0)                              AS sem_entrega,

  -- FLAG DE DEFASAGEM: o conserto do problema que deixou 4 clientes congelados
  -- sem ninguem notar. Quem le a tabela ve a conta parada, nao dado velho com
  -- cara de dado bom.
  f.ultima_data_com_entrega,
  DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), f.ultima_data_com_entrega, DAY)    AS dias_sem_entrega,
  (DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), f.ultima_data_com_entrega, DAY) > 9) AS conta_defasada,

  CURRENT_TIMESTAMP()                                                            AS _extraido_at,
  b._payload_hash
FROM base b
LEFT JOIN frescor f ON f.id_conta = b.id_conta
