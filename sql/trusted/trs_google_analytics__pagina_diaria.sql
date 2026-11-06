WITH
propriedade_por_fonte AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<f STRING, id_propriedade STRING, propriedade STRING>>[
    ('bLbp', '401462672', 'Royal Enfield - Gtm Royal Enfield Manaus'),
    ('gJaQ', '380526642', 'CAA Alumínio - Comércio Amazonense de Alumínio'),
    ('bbNm', '425223490', 'CAA Alumínio - CAA UA GA4'),
    ('2x7P', '445324400', 'CAA Alumínio - CAA Ecomm'),
    ('ijeg', '487050363', 'CAA Tintas - CAA TINTAS G4'),
    ('u8zZ', '347041830', 'Braga Motos Yamaha (Vendas e Pós-vendas) - Gtm Braga Yamaha Motos'),
    ('UdTM', '328802399', 'Unipar - Unipar Construtora G4'),
    ('lBA2', '498940898', 'Unipar - UNIPAR'),
    ('ODY0', '545124965', 'Shizen - SHIZEN HONDA'),
    ('eGNL', '308779602', 'Braga Motors - bragamotors.com.br GA4'),
    ('hymC', '378530203', 'Targo Consultoria'),
    ('Fxvd', '538006848', 'Rodrix'),
    ('3exg', '540706645', 'Hage Alimentos'),
    ('MeSs', '325973640', 'BA Elétrica'),
    ('PTPr', '348669319', 'Hospital Santa Júlia'),
    ('eTRF', '540371777', 'Inforcell'),
    ('lVd7', '501654829', 'AC Display'),
    ('LCPI', '368695613', 'Amazoncopy GA4 1'),
    ('W6fo', '395734052', 'Amazoncopy GA4 2'),
    ('rCCq', '277713381', 'CDL'),
    ('4OdI', '322224288', 'Comac GA4 1'),
    ('dZ4N', '370919392', 'Comac GA4 2'),
    ('fFDC', '528618256', 'Steel Port'),
    ('Fr0m', '460612239', 'Rei das Mangueiras'),
    ('Z2tP', '484983246', 'Amazon Open Mall'),
    ('pDmt', '537610232', 'BAP Auto Parts'),
    ('Sg96', '491012362', 'Constroi subdomínio'),
    ('hrul', '530673633', 'Bigazine Shopify'),
    ('mtyI', '387843937', 'Bigazine Nuvemshop'),
    ('0SJi', '351774477', 'Vanguarda Comunicação'),
    ('e7as', '446649576', 'Construtora Colmeia'),
    ('A94Q', '345017970', 'Acesso Saúde'),
    ('qEP3', '441204296', 'Doctor Mais Saúde'),
    ('DbC8', '541003181', 'Best Car 1'),
    ('Yi7s', '541538196', 'Best Car 2'),
    ('h1qj', '540973147', 'KL Rent a Car 1'),
    ('rT4R', '541547490', 'KL Rent a Car 2'),
    ('zVOk', '354193847', 'PMZ Site'),
    ('Ugdg', '527691074', 'PMZ e-commerce B2C'),
    ('hrD4', '324068974', 'Braga Veículos'),
    ('G4nY', '368957793', 'Dr. José Cabral Jr.'),
    ('4Izx', '384426944', 'Arena Tintas'),
    ('QvZ9', '549933390', 'AMZ Geradores'),
    ('014l', '410228988', 'Braga Acessórios'),
    ('Jl9D', '527418264', 'Pneu Forte Distribuidora 1'),
    ('D8NP', '528392290', 'Pneu Forte Distribuidora 2'),
    ('5y8C', '472688179', 'Pneu Forte'),
    ('ymTH', '549905958', 'Move Rent a Cars'),
    ('hOMJ', '434198185', 'Santo Remédio VNG'),
    ('RDbV', '399440632', 'Drogaria Santo Remédio')
  ])
),
b_raw AS (
  SELECT 'bLbp' AS f, * FROM `vanguardamartech_ga_royal_enfield`.`google_analytics_ga4_royal_enfieldpages`
  UNION ALL SELECT 'gJaQ' AS f, * FROM `vanguardamartech_ga_caa_aluminio`.`google_analytics_ga4_caa_aluminiopages`
  UNION ALL SELECT 'bbNm' AS f, * FROM `vanguardamartech_ga_caa_aluminio_ii`.`google_analytics_ga4_caa_aluminio_2pages`
  UNION ALL SELECT '2x7P' AS f, * FROM `vanguardamartech_ga_caa_aluminio_3`.`google_analytics_ga4_caa_aluminio_3pages`
  UNION ALL SELECT 'ijeg' AS f, * FROM `vanguardamartech_ga_caa_tintas`.`google_analytics_ga4_caa_tintaspages`
  UNION ALL SELECT 'u8zZ' AS f, * FROM `vanguardamartech_ga_braga_motos_yamaha_pos_vendas`.`google_analytics_ga4_braga_motos_yamaha_pos_vendaspages`
  UNION ALL SELECT 'UdTM' AS f, * FROM `vanguardamartech_ga_unipar_construtora`.`google_analytics_ga4_unipar_construtorapages`
  UNION ALL SELECT 'lBA2' AS f, * FROM `vanguardamartech_ga_unipar_construtora_2`.`google_analytics_ga4_unipar_construtora_2pages`
  UNION ALL SELECT 'ODY0' AS f, * FROM `vanguardamartech_ga_shizen`.`google_analytics_ga4_shizenpages`
  UNION ALL SELECT 'eGNL' AS f, * FROM `vanguardamartech_ga_braga_motors`.`google_analytics_ga4_braga_motorspages`
  UNION ALL SELECT 'hymC' AS f, * FROM `vanguardamartech_ga_targo_consultoria`.`google_analytics_ga4_targo_consultoriapages`
  UNION ALL SELECT 'Fxvd' AS f, * FROM `vanguardamartech_ga_rodrix`.`google_analytics_ga4_rodrixpages`
  UNION ALL SELECT '3exg' AS f, * FROM `vanguardamartech_ga_hage_alimentos`.`google_analytics_ga4_hage_alimentospages`
  UNION ALL SELECT 'MeSs' AS f, * FROM `vanguardamartech_ga_ba_eletrica`.`google_analytics_ga4_ba_eletricapages`
  UNION ALL SELECT 'PTPr' AS f, * FROM `vanguardamartech_ga_hospital_santa_julia`.`google_analytics_ga4_hospital_santa_juliapages`
  UNION ALL SELECT 'eTRF' AS f, * FROM `vanguardamartech_ga_inforcell`.`google_analytics_ga4_inforcellpages`
  UNION ALL SELECT 'lVd7' AS f, * FROM `vanguardamartech_ga_ac_display`.`google_analytics_ga4_ac_displaypages`
  UNION ALL SELECT 'LCPI' AS f, * FROM `vanguardamartech_ga_amazoncopy_1`.`google_analytics_ga4_amazoncopy_1pages`
  UNION ALL SELECT 'W6fo' AS f, * FROM `vanguardamartech_ga_amazoncopy_2`.`google_analytics_ga4_amazoncopy_2pages`
  UNION ALL SELECT 'rCCq' AS f, * FROM `vanguardamartech_ga_cdl`.`google_analytics_ga4_cdlpages`
  UNION ALL SELECT '4OdI' AS f, * FROM `vanguardamartech_ga_comac_1`.`google_analytics_ga4_comac_1pages`
  UNION ALL SELECT 'dZ4N' AS f, * FROM `vanguardamartech_ga_comac_2`.`google_analytics_ga4_comac_2pages`
  UNION ALL SELECT 'fFDC' AS f, * FROM `vanguardamartech_ga_steel_port`.`google_analytics_ga4_steel_portpages`
  UNION ALL SELECT 'Fr0m' AS f, * FROM `vanguardamartech_ga_rei_das_mangueiras`.`google_analytics_ga4_rei_das_mangueiraspages`
  UNION ALL SELECT 'Z2tP' AS f, * FROM `vanguardamartech_ga_amazon_open_mall`.`google_analytics_ga4_amazon_open_mallpages`
  UNION ALL SELECT 'pDmt' AS f, * FROM `vanguardamartech_ga_bap`.`google_analytics_ga4_bappages`
  UNION ALL SELECT 'Sg96' AS f, * FROM `vanguardamartech_ga_constroi_incorporadora`.`google_analytics_ga4_constroi_incorporadorapages`
  UNION ALL SELECT 'hrul' AS f, * FROM `vanguardamartech_ga_bigazine_shopify`.`google_analytics_ga4_bigazine_shopifypages`
  UNION ALL SELECT 'mtyI' AS f, * FROM `vanguardamartech_ga_bigazine_nuvemshop`.`google_analytics_ga4_bigazine_nuvemshoppages`
  UNION ALL SELECT '0SJi' AS f, * FROM `vanguardamartech_ga_vanguarda_comunicacao`.`google_analytics_ga4_vanguarda_comunicacaopages`
  UNION ALL SELECT 'e7as' AS f, * FROM `vanguardamartech_ga_construtora_colmeia`.`google_analytics_ga4_construtora_colmeiapages`
  UNION ALL SELECT 'A94Q' AS f, * FROM `vanguardamartech_ga_acesso_saude`.`google_analytics_ga4_acesso_saudepages`
  UNION ALL SELECT 'qEP3' AS f, * FROM `vanguardamartech_ga_doctor_mais_saude`.`google_analytics_ga4_doctor_mais_saudepages`
  UNION ALL SELECT 'DbC8' AS f, * FROM `vanguardamartech_ga_best_car_1`.`google_analytics_ga4_best_car_1pages`
  UNION ALL SELECT 'Yi7s' AS f, * FROM `vanguardamartech_ga_best_car_2`.`google_analytics_ga4_best_car_2pages`
  UNION ALL SELECT 'h1qj' AS f, * FROM `vanguardamartech_ga_kl_rent_a_car_1`.`google_analytics_ga4_kl_rent_a_car_1pages`
  UNION ALL SELECT 'rT4R' AS f, * FROM `vanguardamartech_ga_kl_rent_a_car_2`.`google_analytics_ga4_kl_rent_a_car_2pages`
  UNION ALL SELECT 'zVOk' AS f, * FROM `vanguardamartech_ga_pmz_site`.`google_analytics_ga4_pmz_sitepages`
  UNION ALL SELECT 'Ugdg' AS f, * FROM `vanguardamartech_ga_pmz_ecommerce_b2c`.`google_analytics_ga4_pmz_ecommerce_b2cpages`
  UNION ALL SELECT 'hrD4' AS f, * FROM `vanguardamartech_ga_braga_veiculos`.`google_analytics_ga4_braga_veiculospages`
  UNION ALL SELECT 'G4nY' AS f, * FROM `vanguardamartech_ga_dr_jose_cabral_jr`.`google_analytics_ga4_dr_jose_cabral_jrpages`
  UNION ALL SELECT '4Izx' AS f, * FROM `vanguardamartech_ga_arena_tintas`.`google_analytics_ga4_arena_tintaspages`
  UNION ALL SELECT 'QvZ9' AS f, * FROM `vanguardamartech_ga_amz_geradores`.`google_analytics_ga4_amz_geradorespages`
  UNION ALL SELECT '014l' AS f, * FROM `vanguardamartech_ga_braga_acessorios`.`google_analytics_ga4_braga_acessoriospages`
  UNION ALL SELECT 'Jl9D' AS f, * FROM `vanguardamartech_ga_pneu_forte_distribuidora_1`.`google_analytics_ga4_pneu_forte_distribuidora_1pages`
  UNION ALL SELECT 'D8NP' AS f, * FROM `vanguardamartech_ga_pneu_forte_distribuidora_2`.`google_analytics_ga4_pneu_forte_distribuidora_2pages`
  UNION ALL SELECT '5y8C' AS f, * FROM `vanguardamartech_ga_pneu_forte`.`google_analytics_ga4_pneu_fortepages`
  UNION ALL SELECT 'ymTH' AS f, * FROM `vanguardamartech_ga_move_rental_cars`.`google_analytics_ga4_move_rental_carspages`
  UNION ALL SELECT 'hOMJ' AS f, * FROM `vanguardamartech_ga_santo_remedio_vng`.`google_analytics_ga4_santo_remedio_vngpages`
  UNION ALL SELECT 'RDbV' AS f, * FROM `vanguardamartech_ga_santo_remedio_drogaria`.`google_analytics_ga4_santo_remedio_drogariapages`
),
b AS (
  -- A Raw acumula uma leitura por carga ([2024-01-01 .. report_end_date]). A leitura do dia corrente (parcial) grava dimensao vazia como '' e a releitura fechada grava '(not set)': mantidas as duas, o mesmo dia contaria em dobro. Fica so a leitura de maior report_end_date por fonte e dia.
  SELECT * FROM b_raw
  QUALIFY report_end_date = MAX(report_end_date) OVER (PARTITION BY f, date)
)
SELECT
  CONCAT('google-analytics-ga4-', b.f, ':', b.date, ':', TO_HEX(MD5(TO_JSON_STRING([b.hostName, b.pagePath, b.sessionSource, b.sessionMedium])))) AS id_pagina_diaria,
  p.id_propriedade,
  p.propriedade,
  PARSE_DATE('%Y%m%d', b.date) AS data,
  DATE_TRUNC(PARSE_DATE('%Y%m%d', b.date), MONTH) AS mes_referencia,
  NULLIF(NULLIF(b.hostName, ''), '(not set)') AS host,
  REGEXP_REPLACE(REGEXP_REPLACE(NULLIF(NULLIF(b.pagePath, ''), '(not set)'), r'(?i)[a-z0-9._%+-]+(@|%40)([a-z0-9.-]+\.[a-z]{2,})', r'***@\2'), r'(?i)((?:gclid|fbclid|gbraid|wbraid|msclkid)=)[^&/]+', r'\1***') AS caminho_pagina,
  NULLIF(NULLIF(b.sessionSource, ''), '(not set)') AS origem_sessao,
  NULLIF(NULLIF(b.sessionMedium, ''), '(not set)') AS midia_sessao,
  b.activeUsers AS usuarios_ativos,
  b.engagedSessions AS sessoes_engajadas,
  b.eventCount AS eventos,
  b.screenPageViews AS visualizacoes,
  b.userEngagementDuration AS duracao_engajamento_seg,
  b.bounceRate AS taxa_rejeicao_plataforma,
  b.engagementRate AS taxa_engajamento_plataforma,
  b.screenPageViewsPerUser AS visualizacoes_por_usuario_plataforma,
  b.screenPageViewsPerSession AS visualizacoes_por_sessao_plataforma,
  (REGEXP_CONTAINS(b.pagePath, r'(?i)[a-z0-9._%+-]+(@|%40)([a-z0-9.-]+\.[a-z]{2,})') OR REGEXP_CONTAINS(b.pagePath, r'(?i)((?:gclid|fbclid|gbraid|wbraid|msclkid)=)[^&/]+')) AS flag_caminho_mascarado,
  ('(other)' IN (b.hostName, b.pagePath, b.sessionSource, b.sessionMedium)) AS flag_linha_agrupada_outros,
  CURRENT_TIMESTAMP() AS _extraido_at,
  CONCAT('google-analytics-ga4-', b.f) AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(b))) AS _payload_hash
FROM b
JOIN propriedade_por_fonte p ON p.f = b.f
