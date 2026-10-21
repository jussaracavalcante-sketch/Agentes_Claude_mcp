-- slug no deploy: query-7Rmj (esta linha existe so no arquivo)
-- Trusted RD Station - e-mails (stream emails: modelos e e-mails de campanha). L2 INTERNAL (so metadados, nenhum contato).
-- Grao: um e-mail por conta RD (_fonte). Chave id_email = _fonte|id.
-- Medido em 18/10/2026: 9.301 linhas = 9.301 chaves, 47 fontes; 7.363 campanhas e 1.938 modelos; 4.946 com envio datado.
-- send_at/created_at/updated_at em UTC -> America/Sao_Paulo. sending_is_imminent e behavior_score_info sao constantes (nao emitidos).
WITH u AS (
  SELECT 'rd-station-1boX' AS _fonte, 'PNEU FORTE DISTRIBUIDORA' AS cliente, * FROM `vanguardamartech_rd_distribuidora_pneu_forte`.`rd_station_pneu_forteemails`
  UNION ALL BY NAME SELECT 'rd-station-3k4Z' AS _fonte, 'DMELLO' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_dmello_emails`
  UNION ALL BY NAME SELECT 'rd-station-409D' AS _fonte, 'UNIPAR' AS cliente, * FROM `vanguardamartech_rd_unipar`.`rd_station_uniparemails`
  UNION ALL BY NAME SELECT 'rd-station-4b7D' AS _fonte, 'MILLENIUM SHOPPING' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_millennium_shoppingemails`
  UNION ALL BY NAME SELECT 'rd-station-5KKM' AS _fonte, 'ARENA TINTAS' AS cliente, * FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintasemails`
  UNION ALL BY NAME SELECT 'rd-station-5RPi' AS _fonte, 'AC DISPLAY' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_acdisplay_emails`
  UNION ALL BY NAME SELECT 'rd-station-6Ir5' AS _fonte, 'BRAGA VEICULOS VAREJO' AS cliente, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculos__emails`
  UNION ALL BY NAME SELECT 'rd-station-7K57' AS _fonte, 'PNEU FORTE' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_pneuforte_emails`
  UNION ALL BY NAME SELECT 'rd-station-8Fqy' AS _fonte, 'BRAGA ACESSORIOS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_braga_acessoriosemails`
  UNION ALL BY NAME SELECT 'rd-station-9mbj' AS _fonte, 'AMAZONCOPY' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_amazoncopy_emails`
  UNION ALL BY NAME SELECT 'rd-station-AqsD' AS _fonte, 'AMAZON OPEN MALL' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_openwall_emails`
  UNION ALL BY NAME SELECT 'rd-station-Awhd' AS _fonte, 'ACESSO SAUDE' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_acesso_saudeemails`
  UNION ALL BY NAME SELECT 'rd-station-CSrx' AS _fonte, 'AMZ GERADORES' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_amz_geradoresemails`
  UNION ALL BY NAME SELECT 'rd-station-CWtQ' AS _fonte, 'MARAVILHA MOTOS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_maravilha_emails`
  UNION ALL BY NAME SELECT 'rd-station-Fzvz' AS _fonte, 'DOCTOR MAIS SAUDE' AS cliente, * FROM `vanguardamartech_rd_doctor_mais_saude`.`rd_station_doctor_mais_saudeemails`
  UNION ALL BY NAME SELECT 'rd-station-HVbj' AS _fonte, 'STEEL PORT' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_steel_portemails`
  UNION ALL BY NAME SELECT 'rd-station-HoWi' AS _fonte, 'HOPE BAY' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_hope_bayemails`
  UNION ALL BY NAME SELECT 'rd-station-IOQX' AS _fonte, 'BRAGA VEICULOS VENDA DIRETA' AS cliente, * FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculosemails`
  UNION ALL BY NAME SELECT 'rd-station-L2Sl' AS _fonte, 'DR. JOSE CABRAL JR' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_cabral_emails`
  UNION ALL BY NAME SELECT 'rd-station-MzyH' AS _fonte, 'BA ELETRICA' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_ba_eletricaemails`
  UNION ALL BY NAME SELECT 'rd-station-Ozim' AS _fonte, 'KL RENT A CAR' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_kl_rentemails`
  UNION ALL BY NAME SELECT 'rd-station-POZB' AS _fonte, 'CAA ALUMINIO' AS cliente, * FROM `vanguardamartech_rd_caa_aluminio`.`rd_station_caa_aluminioemails`
  UNION ALL BY NAME SELECT 'rd-station-QcKP' AS _fonte, 'CHARAO' AS cliente, * FROM `vanguardamartech_rd_station_charao`.`rd_station_charaoemails`
  UNION ALL BY NAME SELECT 'rd-station-STKa' AS _fonte, 'HOSPITAL SANTA JULIA' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_hospital_santa_juliaemails`
  UNION ALL BY NAME SELECT 'rd-station-Sys9' AS _fonte, 'SHIZEN' AS cliente, * FROM `vanguardamartech_rd_station_shizen`.`rd_station_shizenemails`
  UNION ALL BY NAME SELECT 'rd-station-VYbu' AS _fonte, 'CONSTRUTORA COLMEIA' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_colmeia_emails`
  UNION ALL BY NAME SELECT 'rd-station-WHAa' AS _fonte, 'BRAGA VEICULOS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_braga_veiculosemails`
  UNION ALL BY NAME SELECT 'rd-station-YNpj' AS _fonte, 'BAP' AS cliente, * FROM `vanguardamartech_rd_bap`.`rd_station_bapemails`
  UNION ALL BY NAME SELECT 'rd-station-bdVN' AS _fonte, 'PMZ' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_pmz_emails`
  UNION ALL BY NAME SELECT 'rd-station-c9jU' AS _fonte, 'CONSTROI INCORPORADORA' AS cliente, * FROM `vanguardamartech_rd_constroi_incorporadora`.`rd_station_constroi_incorporadoraemails`
  UNION ALL BY NAME SELECT 'rd-station-dvZx' AS _fonte, 'DON WATCHES' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_watches_emails`
  UNION ALL BY NAME SELECT 'rd-station-f2o9' AS _fonte, 'SANTO REMEDIO' AS cliente, * FROM `vanguardamartech_rd_station_santo_remedio`.`rd_station_santo_remedioemails`
  UNION ALL BY NAME SELECT 'rd-station-fPd4' AS _fonte, 'HAGE ALIMENTOS' AS cliente, * FROM `vanguardamartech_rd_hage_alimentos`.`rd_station_hage_alimentosemails`
  UNION ALL BY NAME SELECT 'rd-station-h3u2' AS _fonte, 'REI DAS MANGUEIRAS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_rei_mangueirasemails`
  UNION ALL BY NAME SELECT 'rd-station-iJK3' AS _fonte, 'VBOT' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_vbot_emails`
  UNION ALL BY NAME SELECT 'rd-station-idF7' AS _fonte, 'BRAGA MOTORS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_braga_motorsemails`
  UNION ALL BY NAME SELECT 'rd-station-irou' AS _fonte, 'CAA TINTAS' AS cliente, * FROM `vanguardamartech_rd_station_caa_tintas`.`rd_station_caa_tintasemails`
  UNION ALL BY NAME SELECT 'rd-station-mEzQ' AS _fonte, 'PMZ ESCOLA' AS cliente, * FROM `vanguardamartech_rd_pmz_escola`.`rd_station_pmz_escolaemails`
  UNION ALL BY NAME SELECT 'rd-station-oYKw' AS _fonte, 'RD_station_marketing' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_station_emails`
  UNION ALL BY NAME SELECT 'rd-station-pDLk' AS _fonte, 'RD_clientes_vanguarda' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_station_marketingemails`
  UNION ALL BY NAME SELECT 'rd-station-pG4G' AS _fonte, 'BEST CAR' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_best_caremails`
  UNION ALL BY NAME SELECT 'rd-station-rlmE' AS _fonte, 'BRAGA MOTOS YAMAHA POS VENDAS' AS cliente, * FROM `vanguardamartech_rd_station_braga_motos`.`rd_station_braga_motosemails`
  UNION ALL BY NAME SELECT 'rd-station-sLX1' AS _fonte, 'INFORCELL' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_infocell_emails`
  UNION ALL BY NAME SELECT 'rd-station-sPoP' AS _fonte, 'MOVE' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_move_emails`
  UNION ALL BY NAME SELECT 'rd-station-uOAA' AS _fonte, 'COMAC' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_comac_emails`
  UNION ALL BY NAME SELECT 'rd-station-urW3' AS _fonte, 'BIGAZINE MANAUS' AS cliente, * FROM `vanguardamartech_rd_marketing`.`rd_bigazine_emails`
  UNION ALL BY NAME SELECT 'rd-station-ypAe' AS _fonte, 'ROYAL ENFIELD' AS cliente, * FROM `vanguardamartech_rd_station_royal_enfield`.`rd_station_royal_enfieldemails`
  UNION ALL BY NAME SELECT 'rd-station-zxA3' AS _fonte, 'RODRIX' AS cliente, * FROM `vanguardamartech_rd_rodrix`.`rd_station_rodrixemails`
),
base AS (
  SELECT u.*, TO_HEX(MD5(TO_JSON_STRING(u))) AS _payload_hash
  FROM u
  QUALIFY ROW_NUMBER() OVER (PARTITION BY _fonte, CAST(id AS STRING) ORDER BY updated_at DESC) = 1
),
t AS (
SELECT
  CONCAT(_fonte,'|',CAST(id AS STRING)) AS id_email,
  _fonte,
  cliente,
  CAST(id AS STRING) AS id_email_origem,
  NULLIF(TRIM(name),'') AS nome_email,
  NULLIF(TRIM(type),'') AS tipo_email,
  NULLIF(TRIM(status),'') AS status_email,
  DATETIME(SAFE_CAST(created_at AS TIMESTAMP),'America/Sao_Paulo') AS criado_em,
  DATETIME(SAFE_CAST(updated_at AS TIMESTAMP),'America/Sao_Paulo') AS atualizado_em,
  DATETIME(SAFE_CAST(send_at AS TIMESTAMP),'America/Sao_Paulo') AS enviado_em,
  DATE(DATETIME(SAFE_CAST(send_at AS TIMESTAMP),'America/Sao_Paulo')) AS enviado_data,
  DATE_TRUNC(DATE(DATETIME(SAFE_CAST(send_at AS TIMESTAMP),'America/Sao_Paulo')), MONTH) AS mes_envio,
  (send_at IS NOT NULL) AS flag_envio_datado,
  SAFE_CAST(leads_count AS INT64) AS qtd_leads_origem,
  is_predictive_sending AS is_envio_preditivo,
  CAST(campaign_id AS STRING) AS id_campanha_origem,
  CAST(component_template_id AS STRING) AS id_modelo_componente_origem,
  COUNT(DISTINCT _fonte) OVER (PARTITION BY CAST(id AS STRING)) AS qtd_fontes_do_email,
  (COUNT(DISTINCT _fonte) OVER (PARTITION BY CAST(id AS STRING)) > 1) AS flag_email_em_mais_de_uma_fonte,
  CURRENT_TIMESTAMP() AS _extraido_at,
  _payload_hash
FROM base
)
SELECT * FROM t
