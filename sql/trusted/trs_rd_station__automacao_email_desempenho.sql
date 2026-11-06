-- slug no deploy: query-JVRe (esta linha existe so no arquivo)
-- Trusted RD Station - desempenho de e-mail das automacoes (stream analytics_workflow_email_stats). L3 CONFIDENTIAL (so contagem, sem contato).
-- Grao: uma acao de e-mail de uma automacao por conta RD (_fonte). Chave id_automacao_email = _fonte|automacao|acao|nome do e-mail.
-- NAO e serie temporal: a chave de origem nao tem data e a janela e de 1 dia em todas as linhas (ultima janela extraida por acao).
-- Uniao UNION ALL BY NAME. Medido em 18/10/2026: 354 linhas = 354 chaves, 31 fontes, 92 automacoes; 68 linhas em mais de uma _fonte.
-- Taxas como a RD entrega (*_origem). Fuso: created_at/updated_at UTC -> America/Sao_Paulo; janela = rotulo de data.
WITH u AS (
  SELECT 'rd-station-1boX' AS _fonte, 'PNEU FORTE DISTRIBUIDORA' AS cliente, * FROM `vanguardamartech_rd_distribuidora_pneu_forte`.`rd_station_pneu_forteanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-409D' AS _fonte, 'UNIPAR' AS cliente, * FROM `vanguardamartech_rd_unipar`.`rd_station_uniparanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-5KKM' AS _fonte, 'ARENA TINTAS' AS cliente, * FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintasanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-5RPi' AS _fonte, 'AC DISPLAY' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_acdisplay_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-6Ir5' AS _fonte, 'BRAGA VEICULOS VAREJO' AS cliente, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculos__analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-7K57' AS _fonte, 'PNEU FORTE' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_pneuforte_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-8Fqy' AS _fonte, 'BRAGA ACESSORIOS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_braga_acessoriosanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-9mbj' AS _fonte, 'AMAZONCOPY' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_amazoncopy_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-Awhd' AS _fonte, 'ACESSO SAUDE' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_acesso_saudeanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-CSrx' AS _fonte, 'AMZ GERADORES' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_amz_geradoresanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-CWtQ' AS _fonte, 'MARAVILHA MOTOS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_maravilha_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-Fzvz' AS _fonte, 'DOCTOR MAIS SAUDE' AS cliente, * FROM `vanguardamartech_rd_doctor_mais_saude`.`rd_station_doctor_mais_saudeanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-HoWi' AS _fonte, 'HOPE BAY' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_hope_bayanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-IOQX' AS _fonte, 'BRAGA VEICULOS VENDA DIRETA' AS cliente, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculosanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-L2Sl' AS _fonte, 'DR. JOSE CABRAL JR' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_cabral_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-Ozim' AS _fonte, 'KL RENT A CAR' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_kl_rentanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-POZB' AS _fonte, 'CAA ALUMINIO' AS cliente, * FROM `vanguardamartech_rd_caa_aluminio`.`rd_station_caa_aluminioanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-QcKP' AS _fonte, 'CHARAO' AS cliente, * FROM `vanguardamartech_rd_station_charao`.`rd_station_charaoanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-STKa' AS _fonte, 'HOSPITAL SANTA JULIA' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_hospital_santa_juliaanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-Sys9' AS _fonte, 'SHIZEN' AS cliente, * FROM `vanguardamartech_rd_station_shizen`.`rd_station_shizenanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-VYbu' AS _fonte, 'CONSTRUTORA COLMEIA' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_colmeia_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-WHAa' AS _fonte, 'BRAGA VEICULOS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_braga_veiculosanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-bdVN' AS _fonte, 'PMZ' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_pmz_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-c9jU' AS _fonte, 'CONSTROI INCORPORADORA' AS cliente, * FROM `vanguardamartech_rd_constroi_incorporadora`.`rd_station_constroi_incorporadoraanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-dvZx' AS _fonte, 'DON WATCHES' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_watches_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-f2o9' AS _fonte, 'SANTO REMEDIO' AS cliente, * FROM `vanguardamartech_rd_station_santo_remedio`.`rd_station_santo_remedioanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-fPd4' AS _fonte, 'HAGE ALIMENTOS' AS cliente, * FROM `vanguardamartech_rd_hage_alimentos`.`rd_station_hage_alimentosanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-iJK3' AS _fonte, 'VBOT' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_vbot_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-idF7' AS _fonte, 'BRAGA MOTORS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_braga_motorsanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-irou' AS _fonte, 'CAA TINTAS' AS cliente, * FROM `vanguardamartech_rd_station_caa_tintas`.`rd_station_caa_tintasanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-mEzQ' AS _fonte, 'PMZ ESCOLA' AS cliente, * FROM `vanguardamartech_rd_pmz_escola`.`rd_station_pmz_escolaanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-oYKw' AS _fonte, 'RD_station_marketing' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_station_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-pDLk' AS _fonte, 'RD_clientes_vanguarda' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_station_marketinganalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-pG4G' AS _fonte, 'BEST CAR' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_best_caranalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-rlmE' AS _fonte, 'BRAGA MOTOS YAMAHA POS VENDAS' AS cliente, * FROM `vanguardamartech_rd_station_braga_motos`.`rd_station_braga_motosanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-sLX1' AS _fonte, 'INFORCELL' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_infocell_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-sPoP' AS _fonte, 'MOVE' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_move_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-uOAA' AS _fonte, 'COMAC' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_comac_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-urW3' AS _fonte, 'BIGAZINE MANAUS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_bigazine_analytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-ypAe' AS _fonte, 'ROYAL ENFIELD' AS cliente, * FROM `vanguardamartech_rd_station_royal_enfield`.`rd_station_royal_enfieldanalytics_workflow_email_stats`
  UNION ALL BY NAME SELECT 'rd-station-zxA3' AS _fonte, 'RODRIX' AS cliente, * FROM `vanguardamartech_rd_rodrix`.`rd_station_rodrixanalytics_workflow_email_stats`
),
base AS (
  SELECT u.*, TO_HEX(MD5(TO_JSON_STRING(u))) AS _payload_hash
  FROM u
  QUALIFY ROW_NUMBER() OVER (PARTITION BY _fonte, CAST(workflow_id AS STRING), CAST(workflow_action_id AS STRING), email_name ORDER BY query_date_start DESC) = 1
),
t AS (
SELECT
  CONCAT(_fonte,'|',CAST(workflow_id AS STRING),'|',CAST(workflow_action_id AS STRING),'|',IFNULL(email_name,'')) AS id_automacao_email,
  _fonte,
  cliente,
  CAST(workflow_id AS STRING) AS id_automacao_origem,
  NULLIF(TRIM(workflow_name),'') AS nome_automacao,
  CAST(workflow_action_id AS STRING) AS id_acao_origem,
  NULLIF(TRIM(email_name),'') AS nome_email,
  DATETIME(SAFE_CAST(created_at AS TIMESTAMP),'America/Sao_Paulo') AS automacao_criada_em,
  DATETIME(SAFE_CAST(updated_at AS TIMESTAMP),'America/Sao_Paulo') AS automacao_atualizada_em,
  DATE(query_date_start) AS janela_inicio,
  DATE(query_date_end) AS janela_fim,
  DATE_TRUNC(DATE(query_date_start), MONTH) AS mes_referencia,
  SAFE_CAST(contacts_count AS INT64) AS qtd_contatos,
  SAFE_CAST(count_processed AS INT64) AS qtd_processados,
  SAFE_CAST(email_dropped_count AS INT64) AS qtd_descartados,
  SAFE_CAST(email_delivered_count AS INT64) AS qtd_entregues,
  SAFE_CAST(email_hard_bounced_unique_count AS INT64) AS qtd_rejeicao_permanente,
  SAFE_CAST(email_soft_bounced_unique_count AS INT64) AS qtd_rejeicao_temporaria,
  SAFE_CAST(email_bounced_unique_count AS INT64) AS qtd_rejeitados,
  SAFE_CAST(email_opened_unique_count AS INT64) AS qtd_abertos_unicos,
  SAFE_CAST(email_clicked_unique_count AS INT64) AS qtd_cliques_unicos,
  SAFE_CAST(email_unsubscribed_count AS INT64) AS qtd_descadastros,
  SAFE_CAST(email_spam_reported_count AS INT64) AS qtd_spam,
  SAFE_CAST(email_delivered_rate AS FLOAT64) AS taxa_entrega_origem,
  SAFE_CAST(email_opened_rate AS FLOAT64) AS taxa_abertura_origem,
  SAFE_CAST(email_clicked_rate AS FLOAT64) AS taxa_clique_origem,
  SAFE_CAST(email_spam_reported_rate AS FLOAT64) AS taxa_spam_origem,
  (COUNT(DISTINCT _fonte) OVER (PARTITION BY CAST(workflow_action_id AS STRING), email_name, query_date_start) > 1) AS flag_acao_em_mais_de_uma_fonte,
  (SAFE_CAST(email_opened_unique_count AS INT64) > SAFE_CAST(email_delivered_count AS INT64)) AS flag_abertos_maior_que_entregues,
  CURRENT_TIMESTAMP() AS _extraido_at,
  _payload_hash
FROM base
)
SELECT * FROM t
