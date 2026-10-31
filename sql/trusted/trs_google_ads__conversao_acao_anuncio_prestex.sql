-- trs_google_ads__conversao_acao_anuncio_prestex
-- Fonte unica: google-ads-OzfZ (Prestex, conta 712-071-7819), camada vanguardamartech_prestex, prefixo google_ads_prestex_.
-- Gatilho: evento em google-ads-OzfZ (fonte em gatilho MANUAL; padrao da query-FzRx).
-- NIVEL: L2 INTERNAL. ATENCAO - ESTE E O UNICO STREAM DA PRESTEX EM GRANULARIDADE DIARIA: as tabelas *_conversion_actions trazem 951-970 dias distintos
-- (medido em 2026-10-18; dia comum, nao so segunda), ao contrario das outras 9 tabelas de desempenho, que sao semanais. Por isso a coluna e `data` e ha mes_referencia,
-- e a tabela e DIARIA (o nome carrega _prestex em vez de _semanal). `date` e TIMESTAMP 00:00 UTC (zero linhas com hora): DATE(date) sem fuso.
-- Chave: id_origem (id unico da origem, medido). conversion_action_name e 100% NULL na origem e nao e emitida; a categoria e o campo confiavel.
-- NAO escolhe qual categoria vale como 'a conversao' (regra de negocio, ADR-0009). NAO FECHA o total de conversoes e NAO soma com campaign_performance (semanal).
-- ad_conversion_actions: conversoes 7.773,27 contra 9.504,60 de ad_performance (81,8%); todas_conversoes 35.840,26 contra 44.259,91 (81,0%). Grao do anuncio (campanha, grupo, anuncio): NAO e o mesmo total do grao da campanha (335,00): as granularidades nao somam o mesmo.
-- Medido em 2026-10-18 na origem ANTES de publicar: 6.658 linhas, 6.658 ids e chaves distintas (campanha, grupo, anuncio, categoria, dia), 951 dias de 2024-01-02 a 2026-10-16, zero campanha fora do cadastro.
WITH campanha_dim AS (
  SELECT CAST(id AS STRING) AS id_campanha,
         REGEXP_EXTRACT(resource_name, r'customers/([0-9]+)/') AS id_conta
  FROM `vanguardamartech_prestex`.`google_ads_prestex_campaigns`
),
bruto AS (
  -- _payload_hash = MD5 da linha CRUA (alias x), calculado antes de qualquer coluna nova.
  SELECT TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.*
  FROM `vanguardamartech_prestex`.`google_ads_prestex_ad_conversion_actions` x
)
SELECT
  CONCAT('google-ads-OzfZ|', b.id)                   AS id_registro,
  c.id_conta,
  d.cliente,
  d.moeda,
  CAST(b.campaign_id AS STRING)                      AS id_campanha,
  NULLIF(TRIM(b.campaign_name), '')                  AS campanha,
  b.campaign_status                                  AS status_campanha,
  CAST(b.ad_group_id AS STRING)                      AS id_grupo_anuncio,
  NULLIF(TRIM(b.ad_group_name), '')                  AS grupo_anuncio,
  CAST(b.ad_group_ad_ad_id AS STRING)                AS id_anuncio,
  NULLIF(TRIM(b.ad_group_ad_ad_name), '')            AS anuncio,
  b.conversion_action_category                       AS categoria_conversao,
  DATE(b.date)                                       AS data,
  DATE_TRUNC(DATE(b.date), MONTH)                    AS mes_referencia,
  b.metrics_conversions                              AS conversoes,
  b.metrics_all_conversions                          AS todas_conversoes,
  b.metrics_conversions_value                        AS valor_conversoes,
  b.metrics_all_conversions_value                    AS valor_todas_conversoes,
  b.metrics_conversions_by_conversion_date           AS conversoes_por_data_conversao,
  b.metrics_all_conversions_by_conversion_date       AS todas_conversoes_por_data_conversao,
  b.metrics_view_through_conversions                 AS conversoes_view_through,
  (d.id_conta IS NULL)                               AS flag_conta_nao_catalogada,
  (c.id_campanha IS NULL)                            AS flag_campanha_nao_catalogada,
  CURRENT_TIMESTAMP()                                AS _extraido_at,
  'google-ads-OzfZ'                                  AS _fonte,
  b.id                                               AS id_origem,
  b._payload_hash
FROM bruto b
LEFT JOIN campanha_dim c ON c.id_campanha = CAST(b.campaign_id AS STRING)
LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__conta` d ON d.id_conta = c.id_conta
