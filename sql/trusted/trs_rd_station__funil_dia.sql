-- slug no deploy: query-zkaX (esta linha existe so no arquivo)
-- Trusted RD Station - funil de marketing por dia (stream analytics_funnel). L2 INTERNAL (contagem diaria agregada).
-- Grao: um dia por conta RD (_fonte). Chave id_funil_dia = _fonte|AAAAMMDD. So 5 das 48 fontes expoem o stream.
-- Medido em 18/10/2026: 1.538 linhas = 1.538 chaves. reference_day = 03:00/04:00 UTC (meia-noite local): DATE em SP == DATE em UTC (0 divergencias).
-- Funil NAO monotonico (qualificados > leads em 35 dias etc.): flags *_maior_*; 381 dias com tudo zero (zero real, mantido).
-- iJK3 (VBOT) repete 47 dos 48 dias nao zerados de pDLk: qtd_fontes_com_mesmo_retrato marca, nada e apagado.
WITH u AS (
  SELECT 'rd-station-CWtQ' AS _fonte, 'MARAVILHA MOTOS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_maravilha_analytics_funnel`
  UNION ALL BY NAME SELECT 'rd-station-HoWi' AS _fonte, 'HOPE BAY' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_hope_bayanalytics_funnel`
  UNION ALL BY NAME SELECT 'rd-station-f2o9' AS _fonte, 'SANTO REMEDIO' AS cliente, * FROM `vanguardamartech_rd_station_santo_remedio`.`rd_station_santo_remedioanalytics_funnel`
  UNION ALL BY NAME SELECT 'rd-station-iJK3' AS _fonte, 'VBOT' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_vbot_analytics_funnel`
  UNION ALL BY NAME SELECT 'rd-station-pDLk' AS _fonte, 'RD_clientes_vanguarda' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_station_marketinganalytics_funnel`
),
base AS (
  SELECT u.*, TO_HEX(MD5(TO_JSON_STRING(u))) AS _payload_hash
  FROM u
  QUALIFY ROW_NUMBER() OVER (PARTITION BY _fonte, reference_day ORDER BY reference_day DESC) = 1
),
t AS (
SELECT
  CONCAT(_fonte,'|',FORMAT_TIMESTAMP('%Y%m%d',reference_day)) AS id_funil_dia,
  _fonte,
  cliente,
  DATE(DATETIME(SAFE_CAST(reference_day AS TIMESTAMP),'America/Sao_Paulo')) AS data_referencia,
  DATE_TRUNC(DATE(DATETIME(SAFE_CAST(reference_day AS TIMESTAMP),'America/Sao_Paulo')), MONTH) AS mes_referencia,
  SAFE_CAST(visitors_count AS INT64) AS qtd_visitantes,
  SAFE_CAST(contacts_count AS INT64) AS qtd_leads,
  SAFE_CAST(qualified_contacts_count AS INT64) AS qtd_leads_qualificados,
  SAFE_CAST(opportunities_count AS INT64) AS qtd_oportunidades,
  SAFE_CAST(sales_count AS INT64) AS qtd_vendas,
  (SAFE_CAST(qualified_contacts_count AS INT64) > SAFE_CAST(contacts_count AS INT64)) AS flag_qualificados_maior_que_leads,
  (SAFE_CAST(opportunities_count AS INT64) > SAFE_CAST(qualified_contacts_count AS INT64)) AS flag_oportunidades_maior_que_qualificados,
  (SAFE_CAST(sales_count AS INT64) > SAFE_CAST(opportunities_count AS INT64)) AS flag_vendas_maior_que_oportunidades,
  CURRENT_TIMESTAMP() AS _extraido_at,
  _payload_hash
FROM base
),
t2 AS (
SELECT t.*,
  (qtd_visitantes=0 AND qtd_leads=0 AND qtd_leads_qualificados=0 AND qtd_oportunidades=0 AND qtd_vendas=0) AS flag_dia_sem_atividade,
  COUNT(DISTINCT _fonte) OVER (PARTITION BY data_referencia, qtd_visitantes, qtd_leads, qtd_leads_qualificados, qtd_oportunidades, qtd_vendas) AS qtd_fontes_com_mesmo_retrato
FROM t
)
SELECT * FROM t2
