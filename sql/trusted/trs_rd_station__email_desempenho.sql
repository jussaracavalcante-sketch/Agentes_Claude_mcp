-- slug no deploy: query-rtu4 (esta linha existe so no arquivo)
-- Trusted RD Station - desempenho de e-mail por campanha (stream analytics_email_stats). L3 CONFIDENTIAL (so contagem, sem contato).
-- Grao: um envio de campanha por conta RD (_fonte). Chave id_email_desempenho = _fonte|id_campanha|instante do envio.
-- 38 das 41 fontes com o stream tem linha (as demais, vazias); contas so com segmentation_contacts nao trazem este stream.
-- Uniao UNION ALL BY NAME (colunas por nome, nao por posicao). Medido em 18/10/2026: 327 linhas = 327 chaves; 86 linhas de campanha em mais de uma _fonte (conta RD lida por duas conexoes).
-- Taxas ficam como a RD entrega (*_origem): a Trusted nao recalcula metrica derivada. Fuso: send_at chega em UTC e sai em America/Sao_Paulo; query_date_* e rotulo de janela (data), sem conversao.
WITH u AS (
  SELECT 'rd-station-1boX' AS _fonte, 'PNEU FORTE DISTRIBUIDORA' AS cliente, * FROM `vanguardamartech_rd_distribuidora_pneu_forte`.`rd_station_pneu_forteanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-409D' AS _fonte, 'UNIPAR' AS cliente, * FROM `vanguardamartech_rd_unipar`.`rd_station_uniparanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-5KKM' AS _fonte, 'ARENA TINTAS' AS cliente, * FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintasanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-5RPi' AS _fonte, 'AC DISPLAY' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_acdisplay_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-6Ir5' AS _fonte, 'BRAGA VEICULOS VAREJO' AS cliente, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculos__analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-7K57' AS _fonte, 'PNEU FORTE' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_pneuforte_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-8Fqy' AS _fonte, 'BRAGA ACESSORIOS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_braga_acessoriosanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-9mbj' AS _fonte, 'AMAZONCOPY' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_amazoncopy_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-Awhd' AS _fonte, 'ACESSO SAUDE' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_acesso_saudeanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-CSrx' AS _fonte, 'AMZ GERADORES' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_amz_geradoresanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-CWtQ' AS _fonte, 'MARAVILHA MOTOS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_maravilha_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-Fzvz' AS _fonte, 'DOCTOR MAIS SAUDE' AS cliente, * FROM `vanguardamartech_rd_doctor_mais_saude`.`rd_station_doctor_mais_saudeanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-HoWi' AS _fonte, 'HOPE BAY' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_hope_bayanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-IOQX' AS _fonte, 'BRAGA VEICULOS VENDA DIRETA' AS cliente, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculosanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-L2Sl' AS _fonte, 'DR. JOSE CABRAL JR' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_cabral_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-Ozim' AS _fonte, 'KL RENT A CAR' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_kl_rentanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-POZB' AS _fonte, 'CAA ALUMINIO' AS cliente, * FROM `vanguardamartech_rd_caa_aluminio`.`rd_station_caa_aluminioanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-QcKP' AS _fonte, 'CHARAO' AS cliente, * FROM `vanguardamartech_rd_station_charao`.`rd_station_charaoanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-STKa' AS _fonte, 'HOSPITAL SANTA JULIA' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_hospital_santa_juliaanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-Sys9' AS _fonte, 'SHIZEN' AS cliente, * FROM `vanguardamartech_rd_station_shizen`.`rd_station_shizenanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-VYbu' AS _fonte, 'CONSTRUTORA COLMEIA' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_colmeia_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-WHAa' AS _fonte, 'BRAGA VEICULOS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_braga_veiculosanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-bdVN' AS _fonte, 'PMZ' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_pmz_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-c9jU' AS _fonte, 'CONSTROI INCORPORADORA' AS cliente, * FROM `vanguardamartech_rd_constroi_incorporadora`.`rd_station_constroi_incorporadoraanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-dvZx' AS _fonte, 'DON WATCHES' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_watches_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-f2o9' AS _fonte, 'SANTO REMEDIO' AS cliente, * FROM `vanguardamartech_rd_station_santo_remedio`.`rd_station_santo_remedioanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-fPd4' AS _fonte, 'HAGE ALIMENTOS' AS cliente, * FROM `vanguardamartech_rd_hage_alimentos`.`rd_station_hage_alimentosanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-iJK3' AS _fonte, 'VBOT' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_vbot_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-idF7' AS _fonte, 'BRAGA MOTORS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_braga_motorsanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-irou' AS _fonte, 'CAA TINTAS' AS cliente, * FROM `vanguardamartech_rd_station_caa_tintas`.`rd_station_caa_tintasanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-mEzQ' AS _fonte, 'PMZ ESCOLA' AS cliente, * FROM `vanguardamartech_rd_pmz_escola`.`rd_station_pmz_escolaanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-oYKw' AS _fonte, 'RD_station_marketing' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_station_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-pDLk' AS _fonte, 'RD_clientes_vanguarda' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_station_marketinganalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-pG4G' AS _fonte, 'BEST CAR' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_best_caranalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-rlmE' AS _fonte, 'BRAGA MOTOS YAMAHA POS VENDAS' AS cliente, * FROM `vanguardamartech_rd_station_braga_motos`.`rd_station_braga_motosanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-sLX1' AS _fonte, 'INFORCELL' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_infocell_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-sPoP' AS _fonte, 'MOVE' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_move_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-uOAA' AS _fonte, 'COMAC' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_comac_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-urW3' AS _fonte, 'BIGAZINE MANAUS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_bigazine_analytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-ypAe' AS _fonte, 'ROYAL ENFIELD' AS cliente, * FROM `vanguardamartech_rd_station_royal_enfield`.`rd_station_royal_enfieldanalytics_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-zxA3' AS _fonte, 'RODRIX' AS cliente, * FROM `vanguardamartech_rd_rodrix`.`rd_station_rodrixanalytics_email_stats`
),
base AS (
  SELECT u.*, TO_HEX(MD5(TO_JSON_STRING(u))) AS _payload_hash
  FROM u
  QUALIFY ROW_NUMBER() OVER (PARTITION BY _fonte, CAST(campaign_id AS STRING), send_at ORDER BY query_date_start DESC) = 1
),
t AS (
SELECT
  CONCAT(_fonte,'|',CAST(campaign_id AS STRING),'|',FORMAT_TIMESTAMP('%Y%m%dT%H%M%S',send_at)) AS id_email_desempenho,
  _fonte,
  cliente,
  CAST(campaign_id AS STRING) AS id_campanha_origem,
  NULLIF(TRIM(campaign_name),'') AS nome_campanha,
  DATETIME(SAFE_CAST(send_at AS TIMESTAMP),'America/Sao_Paulo') AS enviado_em,
  DATE(DATETIME(SAFE_CAST(send_at AS TIMESTAMP),'America/Sao_Paulo')) AS enviado_data,
  DATE_TRUNC(DATE(DATETIME(SAFE_CAST(send_at AS TIMESTAMP),'America/Sao_Paulo')), MONTH) AS mes_referencia,
  DATE(query_date_start) AS janela_inicio,
  DATE(query_date_end) AS janela_fim,
  SAFE_CAST(contacts_count AS INT64) AS qtd_contatos,
  SAFE_CAST(email_dropped_count AS INT64) AS qtd_descartados,
  SAFE_CAST(email_delivered_count AS INT64) AS qtd_entregues,
  SAFE_CAST(email_bounced_count AS INT64) AS qtd_rejeitados,
  SAFE_CAST(email_opened_count AS INT64) AS qtd_abertos,
  SAFE_CAST(email_clicked_count AS INT64) AS qtd_cliques,
  SAFE_CAST(email_unsubscribed_count AS INT64) AS qtd_descadastros,
  SAFE_CAST(email_spam_reported_count AS INT64) AS qtd_spam,
  SAFE_CAST(email_delivered_rate AS FLOAT64) AS taxa_entrega_origem,
  SAFE_CAST(email_opened_rate AS FLOAT64) AS taxa_abertura_origem,
  SAFE_CAST(email_clicked_rate AS FLOAT64) AS taxa_clique_origem,
  SAFE_CAST(email_spam_reported_rate AS FLOAT64) AS taxa_spam_origem,
  COUNT(DISTINCT _fonte) OVER (PARTITION BY CAST(campaign_id AS STRING), send_at) AS qtd_fontes_da_campanha,
  (COUNT(DISTINCT _fonte) OVER (PARTITION BY CAST(campaign_id AS STRING), send_at) > 1) AS flag_campanha_em_mais_de_uma_fonte,
  (SAFE_CAST(email_opened_count AS INT64) > SAFE_CAST(email_delivered_count AS INT64)) AS flag_abertos_maior_que_entregues,
  CURRENT_TIMESTAMP() AS _extraido_at,
  _payload_hash
FROM base
)
SELECT * FROM t
