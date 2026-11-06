-- slug no deploy: query-SQfa (esta linha existe so no arquivo)
-- Trusted RD Station - conversao por ativo de captura por dia (stream analytics_conversion_assets). L3 CONFIDENTIAL (so contagem).
-- Grao: um ativo em um dia por conta RD (_fonte). Chave id_ativo_dia = _fonte|id_ativo|janela.
-- Uniao UNION ALL BY NAME. Medido em 18/10/2026: 94.785 linhas = 94.785 chaves, 39 fontes, 853 ativos; 93,5% das linhas sem atividade (visitas 0 e conversoes 0).
-- asset_type e NULL em 100% (campo morto, nao emitido). query_date_start e rotulo de dia: DATE() sem conversao de fuso. Taxa como a RD entrega.
WITH u AS (
  SELECT 'rd-station-1boX' AS _fonte, 'PNEU FORTE DISTRIBUIDORA' AS cliente, * FROM `vanguardamartech_rd_distribuidora_pneu_forte`.`rd_station_pneu_forteanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-409D' AS _fonte, 'UNIPAR' AS cliente, * FROM `vanguardamartech_rd_unipar`.`rd_station_uniparanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-5KKM' AS _fonte, 'ARENA TINTAS' AS cliente, * FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintasanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-5RPi' AS _fonte, 'AC DISPLAY' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_acdisplay_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-6Ir5' AS _fonte, 'BRAGA VEICULOS VAREJO' AS cliente, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculos__analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-7K57' AS _fonte, 'PNEU FORTE' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_pneuforte_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-8Fqy' AS _fonte, 'BRAGA ACESSORIOS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_braga_acessoriosanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-9mbj' AS _fonte, 'AMAZONCOPY' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_amazoncopy_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-Awhd' AS _fonte, 'ACESSO SAUDE' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_acesso_saudeanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-CSrx' AS _fonte, 'AMZ GERADORES' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_amz_geradoresanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-CWtQ' AS _fonte, 'MARAVILHA MOTOS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_maravilha_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-Fzvz' AS _fonte, 'DOCTOR MAIS SAUDE' AS cliente, * FROM `vanguardamartech_rd_doctor_mais_saude`.`rd_station_doctor_mais_saudeanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-HoWi' AS _fonte, 'HOPE BAY' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_hope_bayanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-IOQX' AS _fonte, 'BRAGA VEICULOS VENDA DIRETA' AS cliente, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculosanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-L2Sl' AS _fonte, 'DR. JOSE CABRAL JR' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_cabral_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-Ozim' AS _fonte, 'KL RENT A CAR' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_kl_rentanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-POZB' AS _fonte, 'CAA ALUMINIO' AS cliente, * FROM `vanguardamartech_rd_caa_aluminio`.`rd_station_caa_aluminioanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-QcKP' AS _fonte, 'CHARAO' AS cliente, * FROM `vanguardamartech_rd_station_charao`.`rd_station_charaoanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-STKa' AS _fonte, 'HOSPITAL SANTA JULIA' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_hospital_santa_juliaanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-Sys9' AS _fonte, 'SHIZEN' AS cliente, * FROM `vanguardamartech_rd_station_shizen`.`rd_station_shizenanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-VYbu' AS _fonte, 'CONSTRUTORA COLMEIA' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_colmeia_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-WHAa' AS _fonte, 'BRAGA VEICULOS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_braga_veiculosanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-bdVN' AS _fonte, 'PMZ' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_pmz_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-c9jU' AS _fonte, 'CONSTROI INCORPORADORA' AS cliente, * FROM `vanguardamartech_rd_constroi_incorporadora`.`rd_station_constroi_incorporadoraanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-dvZx' AS _fonte, 'DON WATCHES' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_watches_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-f2o9' AS _fonte, 'SANTO REMEDIO' AS cliente, * FROM `vanguardamartech_rd_station_santo_remedio`.`rd_station_santo_remedioanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-fPd4' AS _fonte, 'HAGE ALIMENTOS' AS cliente, * FROM `vanguardamartech_rd_hage_alimentos`.`rd_station_hage_alimentosanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-iJK3' AS _fonte, 'VBOT' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_vbot_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-idF7' AS _fonte, 'BRAGA MOTORS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_braga_motorsanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-irou' AS _fonte, 'CAA TINTAS' AS cliente, * FROM `vanguardamartech_rd_station_caa_tintas`.`rd_station_caa_tintasanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-mEzQ' AS _fonte, 'PMZ ESCOLA' AS cliente, * FROM `vanguardamartech_rd_pmz_escola`.`rd_station_pmz_escolaanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-oYKw' AS _fonte, 'RD_station_marketing' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_station_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-pDLk' AS _fonte, 'RD_clientes_vanguarda' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_station_marketinganalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-pG4G' AS _fonte, 'BEST CAR' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_best_caranalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-rlmE' AS _fonte, 'BRAGA MOTOS YAMAHA POS VENDAS' AS cliente, * FROM `vanguardamartech_rd_station_braga_motos`.`rd_station_braga_motosanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-sLX1' AS _fonte, 'INFORCELL' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_infocell_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-sPoP' AS _fonte, 'MOVE' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_move_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-uOAA' AS _fonte, 'COMAC' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_comac_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-urW3' AS _fonte, 'BIGAZINE MANAUS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_bigazine_analytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-ypAe' AS _fonte, 'ROYAL ENFIELD' AS cliente, * FROM `vanguardamartech_rd_station_royal_enfield`.`rd_station_royal_enfieldanalytics_conversion_assets`
  UNION ALL BY NAME SELECT 'rd-station-zxA3' AS _fonte, 'RODRIX' AS cliente, * FROM `vanguardamartech_rd_rodrix`.`rd_station_rodrixanalytics_conversion_assets`
),
base AS (
  SELECT u.*, TO_HEX(MD5(TO_JSON_STRING(u))) AS _payload_hash
  FROM u
  QUALIFY ROW_NUMBER() OVER (PARTITION BY _fonte, CAST(asset_id AS STRING), query_date_start ORDER BY query_date_end DESC) = 1
),
t AS (
SELECT
  CONCAT(_fonte,'|',CAST(asset_id AS STRING),'|',FORMAT_TIMESTAMP('%Y%m%dT%H%M',query_date_start)) AS id_ativo_dia,
  _fonte,
  cliente,
  CAST(asset_id AS STRING) AS id_ativo_origem,
  NULLIF(TRIM(asset_identifier),'') AS identificador_ativo,
  DATETIME(SAFE_CAST(asset_created_at AS TIMESTAMP),'America/Sao_Paulo') AS ativo_criado_em,
  DATETIME(SAFE_CAST(asset_updated_at AS TIMESTAMP),'America/Sao_Paulo') AS ativo_atualizado_em,
  DATE(query_date_start) AS data_referencia,
  DATE_TRUNC(DATE(query_date_start), MONTH) AS mes_referencia,
  (EXTRACT(HOUR FROM query_date_start) <> 0) AS flag_janela_parcial,
  SAFE_CAST(visits_count AS INT64) AS qtd_visitas,
  SAFE_CAST(conversion_count AS INT64) AS qtd_conversoes,
  SAFE_CAST(conversion_rate AS FLOAT64) AS taxa_conversao_origem,
  (SAFE_CAST(visits_count AS INT64) = 0 AND SAFE_CAST(conversion_count AS INT64) = 0) AS flag_sem_atividade,
  (SAFE_CAST(conversion_count AS INT64) > SAFE_CAST(visits_count AS INT64)) AS flag_conversoes_maior_que_visitas,
  COUNT(DISTINCT _fonte) OVER (PARTITION BY CAST(asset_id AS STRING), query_date_start) AS qtd_fontes_do_ativo_dia,
  (COUNT(DISTINCT _fonte) OVER (PARTITION BY CAST(asset_id AS STRING), query_date_start) > 1) AS flag_ativo_em_mais_de_uma_fonte,
  CURRENT_TIMESTAMP() AS _extraido_at,
  _payload_hash
FROM base
)
SELECT * FROM t
