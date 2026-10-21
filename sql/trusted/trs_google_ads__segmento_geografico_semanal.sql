-- trs_google_ads__segmento_geografico_semanal
-- Fonte unica: google-ads-OzfZ (Prestex, conta 712-071-7819), camada vanguardamartech_prestex, prefixo google_ads_prestex_.
-- Gatilho: evento em google-ads-OzfZ (a fonte esta em gatilho MANUAL; mesmo padrao da trs_google_ads__insight_semanal / query-FzRx).
-- NIVEL: L2 INTERNAL (agregado por pais). GRANULARIDADE SEMANAL: toda `date` da origem e uma SEGUNDA-FEIRA (medido em 2026-10-18: zero linhas fora da segunda, zero com hora
-- diferente de 00:00 = data guardada como instante UTC; DATE(date) sem fuso devolve a segunda certa). A semana corrente chega parcial
-- (flag_semana_incompleta_na_carga, gravada na CARGA: regra de qualidade compara contra DATE(_extraido_at), nunca CURRENT_DATE).
-- NAO SOMA COM A TRUSTED DIARIA: a coluna chama-se semana_inicio (nao `data`) de proposito; somar semana com dia trataria sete dias como um.
-- A conta vem do resource_name da campanha (customers/<id>/), nunca de literal; cliente e moeda de trs_google_ads__conta (LEFT JOIN + flag).
-- Chave: id_origem (id unico da origem, medido) = (campanha, pais, tipo de localizacao, semana).
-- Derivadas (ctr, cpc, taxas) passam COMO A PLATAFORMA ENTREGA, nao recalculadas; custo em MICROS. Dado ausente = NULL, nunca zero.
-- Unico breakdown que reconcilia com o total: R$ 464.135,61 = campaign_performance. MEDIDO NESTA CONTA: tipo_localizacao PARTICIONA o gasto
-- (LOCATION_OF_PRESENCE R$ 323.640,26 + AREA_OF_INTEREST R$ 140.495,34 = R$ 464.135,61), ao contrario das 40 contas diarias, onde os dois tipos somam MAIS que a verba
-- (duplicam). Nao herde a regra de uma conta para a outra sem medir; a Refined mantem os tipos separados em tipo_segmento de qualquer forma.
-- Medido em 2026-10-18 na tabela de origem ANTES de publicar: 1.364 linhas, 1.364 ids e chaves distintas, 1 pais (2076, Brasil resolve em trs_google_ads__geo_alvo), 2 tipos de localizacao, 2024-01-01 a 2026-10-12.
WITH campanha_dim AS (
  SELECT CAST(id AS STRING) AS id_campanha,
         REGEXP_EXTRACT(resource_name, r'customers/([0-9]+)/') AS id_conta
  FROM `vanguardamartech_prestex`.`google_ads_prestex_campaigns`
),
bruto AS (
  -- _payload_hash = MD5 da linha CRUA (alias x), calculado antes de qualquer coluna nova.
  SELECT TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.*
  FROM `vanguardamartech_prestex`.`google_ads_prestex_geographic_performance` x
)
SELECT
  CONCAT('google-ads-OzfZ|', b.id)                   AS id_registro,
  c.id_conta,
  d.cliente,
  d.moeda,
  CAST(b.campaign_id AS STRING)                      AS id_campanha,
  NULLIF(TRIM(b.campaign_name), '')                  AS campanha,
  b.campaign_status                                  AS status_campanha,
  CAST(b.country_criterion_id AS STRING)             AS id_pais,
  b.location_type                                    AS tipo_localizacao,
  DATE(b.date)                                       AS semana_inicio,
  DATE_ADD(DATE(b.date), INTERVAL 6 DAY)             AS semana_fim,
  DATE_ADD(DATE(b.date), INTERVAL 6 DAY)
    >= DATE(CURRENT_TIMESTAMP(), 'America/Sao_Paulo') AS flag_semana_incompleta_na_carga,
  EXTRACT(DAYOFWEEK FROM DATE(b.date)) <> 2          AS flag_semana_nao_comeca_na_segunda,
  b.metrics_cost_micros                              AS investimento_micros,
  b.metrics_impressions                              AS impressoes,
  b.metrics_clicks                                   AS cliques,
  b.metrics_interactions                             AS interacoes,
  b.metrics_conversions                              AS conversoes,
  b.metrics_all_conversions                          AS todas_conversoes,
  b.metrics_conversions_value                        AS valor_conversoes,
  b.metrics_all_conversions_value                    AS valor_todas_conversoes,
  b.metrics_view_through_conversions                 AS conversoes_view_through,
  b.metrics_cross_device_conversions                 AS conversoes_entre_dispositivos,
  ROUND(b.metrics_cost_micros / 1000000, 2)                AS investimento,
  (d.id_conta IS NULL)                               AS flag_conta_nao_catalogada,
  (c.id_campanha IS NULL)                            AS flag_campanha_nao_catalogada,
  CURRENT_TIMESTAMP()                                AS _extraido_at,
  'google-ads-OzfZ'                                  AS _fonte,
  b.id                                               AS id_origem,
  b._payload_hash
FROM bruto b
LEFT JOIN campanha_dim c ON c.id_campanha = CAST(b.campaign_id AS STRING)
LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__conta` d ON d.id_conta = c.id_conta
