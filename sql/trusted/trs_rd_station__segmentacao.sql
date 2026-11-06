-- slug no deploy: query-w6Xi (esta linha existe so no arquivo)
-- Trusted RD Station - segmentacoes (stream segmentations: catalogo de segmentos). L2 INTERNAL (so metadados; sem contatos).
-- Grao: uma segmentacao por conta RD (_fonte). Chave id_segmentacao = _fonte|id.
-- Medido em 18/10/2026: 3.250 linhas = 3.250 chaves = soma bruta, 48 fontes; 336 segmentos padrao da RD.
-- process_status e constante 'processed' (nao emitido); links (URLs de API) nao emitido.
WITH cli AS (
  SELECT * FROM UNNEST([
    STRUCT('rd-station-1boX' AS _fonte, 'PNEU FORTE DISTRIBUIDORA' AS cliente),
    STRUCT('rd-station-3k4Z' AS _fonte, 'DMELLO' AS cliente),
    STRUCT('rd-station-409D' AS _fonte, 'UNIPAR' AS cliente),
    STRUCT('rd-station-4b7D' AS _fonte, 'MILLENIUM SHOPPING' AS cliente),
    STRUCT('rd-station-5KKM' AS _fonte, 'ARENA TINTAS' AS cliente),
    STRUCT('rd-station-5RPi' AS _fonte, 'AC DISPLAY' AS cliente),
    STRUCT('rd-station-6Ir5' AS _fonte, 'BRAGA VEICULOS VAREJO' AS cliente),
    STRUCT('rd-station-7K57' AS _fonte, 'PNEU FORTE' AS cliente),
    STRUCT('rd-station-8Fqy' AS _fonte, 'BRAGA ACESSORIOS' AS cliente),
    STRUCT('rd-station-9mbj' AS _fonte, 'AMAZONCOPY' AS cliente),
    STRUCT('rd-station-AqsD' AS _fonte, 'AMAZON OPEN MALL' AS cliente),
    STRUCT('rd-station-Awhd' AS _fonte, 'ACESSO SAUDE' AS cliente),
    STRUCT('rd-station-CSrx' AS _fonte, 'AMZ GERADORES' AS cliente),
    STRUCT('rd-station-CWtQ' AS _fonte, 'MARAVILHA MOTOS' AS cliente),
    STRUCT('rd-station-Fzvz' AS _fonte, 'DOCTOR MAIS SAUDE' AS cliente),
    STRUCT('rd-station-HVbj' AS _fonte, 'STEEL PORT' AS cliente),
    STRUCT('rd-station-HoWi' AS _fonte, 'HOPE BAY' AS cliente),
    STRUCT('rd-station-IOQX' AS _fonte, 'BRAGA VEICULOS VENDA DIRETA' AS cliente),
    STRUCT('rd-station-L2Sl' AS _fonte, 'DR. JOSE CABRAL JR' AS cliente),
    STRUCT('rd-station-MzyH' AS _fonte, 'BA ELETRICA' AS cliente),
    STRUCT('rd-station-Ozim' AS _fonte, 'KL RENT A CAR' AS cliente),
    STRUCT('rd-station-POZB' AS _fonte, 'CAA ALUMINIO' AS cliente),
    STRUCT('rd-station-QcKP' AS _fonte, 'CHARAO' AS cliente),
    STRUCT('rd-station-STKa' AS _fonte, 'HOSPITAL SANTA JULIA' AS cliente),
    STRUCT('rd-station-Sys9' AS _fonte, 'SHIZEN' AS cliente),
    STRUCT('rd-station-VYbu' AS _fonte, 'CONSTRUTORA COLMEIA' AS cliente),
    STRUCT('rd-station-WHAa' AS _fonte, 'BRAGA VEICULOS' AS cliente),
    STRUCT('rd-station-YNpj' AS _fonte, 'BAP' AS cliente),
    STRUCT('rd-station-bdVN' AS _fonte, 'PMZ' AS cliente),
    STRUCT('rd-station-c9jU' AS _fonte, 'CONSTROI INCORPORADORA' AS cliente),
    STRUCT('rd-station-dvZx' AS _fonte, 'DON WATCHES' AS cliente),
    STRUCT('rd-station-f2o9' AS _fonte, 'SANTO REMEDIO' AS cliente),
    STRUCT('rd-station-fPd4' AS _fonte, 'HAGE ALIMENTOS' AS cliente),
    STRUCT('rd-station-h3u2' AS _fonte, 'REI DAS MANGUEIRAS' AS cliente),
    STRUCT('rd-station-iJK3' AS _fonte, 'VBOT' AS cliente),
    STRUCT('rd-station-idF7' AS _fonte, 'BRAGA MOTORS' AS cliente),
    STRUCT('rd-station-irou' AS _fonte, 'CAA TINTAS' AS cliente),
    STRUCT('rd-station-mEzQ' AS _fonte, 'PMZ ESCOLA' AS cliente),
    STRUCT('rd-station-oYKw' AS _fonte, 'RD_station_marketing' AS cliente),
    STRUCT('rd-station-pDLk' AS _fonte, 'RD_clientes_vanguarda' AS cliente),
    STRUCT('rd-station-pG4G' AS _fonte, 'BEST CAR' AS cliente),
    STRUCT('rd-station-rlmE' AS _fonte, 'BRAGA MOTOS YAMAHA POS VENDAS' AS cliente),
    STRUCT('rd-station-sLX1' AS _fonte, 'INFORCELL' AS cliente),
    STRUCT('rd-station-sPoP' AS _fonte, 'MOVE' AS cliente),
    STRUCT('rd-station-uOAA' AS _fonte, 'COMAC' AS cliente),
    STRUCT('rd-station-urW3' AS _fonte, 'BIGAZINE MANAUS' AS cliente),
    STRUCT('rd-station-ypAe' AS _fonte, 'ROYAL ENFIELD' AS cliente),
    STRUCT('rd-station-zxA3' AS _fonte, 'RODRIX' AS cliente)
  ])
),
u AS (
    SELECT 'rd-station-1boX' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_distribuidora_pneu_forte`.`rd_station_pneu_fortesegmentations`
    UNION ALL BY NAME SELECT 'rd-station-3k4Z' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_dmello_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-409D' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_unipar`.`rd_station_uniparsegmentations`
    UNION ALL BY NAME SELECT 'rd-station-4b7D' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_millennium_shoppingsegmentations`
    UNION ALL BY NAME SELECT 'rd-station-5KKM' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintassegmentations`
    UNION ALL BY NAME SELECT 'rd-station-5RPi' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_acdisplay_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-6Ir5' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculos__segmentations`
    UNION ALL BY NAME SELECT 'rd-station-7K57' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_pneuforte_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-8Fqy' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_braga_acessoriossegmentations`
    UNION ALL BY NAME SELECT 'rd-station-9mbj' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_amazoncopy_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-AqsD' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_openwall_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-Awhd' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_acesso_saudesegmentations`
    UNION ALL BY NAME SELECT 'rd-station-CSrx' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_amz_geradoressegmentations`
    UNION ALL BY NAME SELECT 'rd-station-CWtQ' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_maravilha_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-Fzvz' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_doctor_mais_saude`.`rd_station_doctor_mais_saudesegmentations`
    UNION ALL BY NAME SELECT 'rd-station-HVbj' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_steel_portsegmentations`
    UNION ALL BY NAME SELECT 'rd-station-HoWi' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_hope_baysegmentations`
    UNION ALL BY NAME SELECT 'rd-station-IOQX' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculossegmentations`
    UNION ALL BY NAME SELECT 'rd-station-L2Sl' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_cabral_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-MzyH' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_ba_eletricasegmentations`
    UNION ALL BY NAME SELECT 'rd-station-Ozim' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_kl_rentsegmentations`
    UNION ALL BY NAME SELECT 'rd-station-POZB' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_caa_aluminio`.`rd_station_caa_aluminiosegmentations`
    UNION ALL BY NAME SELECT 'rd-station-QcKP' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_station_charao`.`rd_station_charaosegmentations`
    UNION ALL BY NAME SELECT 'rd-station-STKa' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_hospital_santa_juliasegmentations`
    UNION ALL BY NAME SELECT 'rd-station-Sys9' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_station_shizen`.`rd_station_shizensegmentations`
    UNION ALL BY NAME SELECT 'rd-station-VYbu' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_colmeia_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-WHAa' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_braga_veiculossegmentations`
    UNION ALL BY NAME SELECT 'rd-station-YNpj' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_bap`.`rd_station_bapsegmentations`
    UNION ALL BY NAME SELECT 'rd-station-bdVN' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_pmz_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-c9jU' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_constroi_incorporadora`.`rd_station_constroi_incorporadorasegmentations`
    UNION ALL BY NAME SELECT 'rd-station-dvZx' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_watches_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-f2o9' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_station_santo_remedio`.`rd_station_santo_remediosegmentations`
    UNION ALL BY NAME SELECT 'rd-station-fPd4' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_hage_alimentos`.`rd_station_hage_alimentossegmentations`
    UNION ALL BY NAME SELECT 'rd-station-h3u2' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_rei_mangueirassegmentations`
    UNION ALL BY NAME SELECT 'rd-station-iJK3' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_vbot_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-idF7' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_braga_motorssegmentations`
    UNION ALL BY NAME SELECT 'rd-station-irou' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_station_caa_tintas`.`rd_station_caa_tintassegmentations`
    UNION ALL BY NAME SELECT 'rd-station-mEzQ' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_pmz_escola`.`rd_station_pmz_escolasegmentations`
    UNION ALL BY NAME SELECT 'rd-station-oYKw' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_station_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-pDLk' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_station_marketingsegmentations`
    UNION ALL BY NAME SELECT 'rd-station-pG4G' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_best_carsegmentations`
    UNION ALL BY NAME SELECT 'rd-station-rlmE' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_station_braga_motos`.`rd_station_braga_motossegmentations`
    UNION ALL BY NAME SELECT 'rd-station-sLX1' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_infocell_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-sPoP' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_move_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-uOAA' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_comac_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-urW3' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_marketing`.`rd_bigazine_segmentations`
    UNION ALL BY NAME SELECT 'rd-station-ypAe' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_station_royal_enfield`.`rd_station_royal_enfieldsegmentations`
    UNION ALL BY NAME SELECT 'rd-station-zxA3' AS _fonte, id, name, standard, created_at, updated_at, process_status FROM `vanguardamartech_rd_rodrix`.`rd_station_rodrixsegmentations`
),
base AS (
  SELECT u.*, c.cliente, TO_HEX(MD5(TO_JSON_STRING(u))) AS _payload_hash
  FROM u LEFT JOIN cli c USING (_fonte)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY _fonte, CAST(id AS STRING) ORDER BY updated_at DESC) = 1
),
t AS (
SELECT
  CONCAT(_fonte,'|',CAST(id AS STRING)) AS id_segmentacao,
  _fonte,
  cliente,
  CAST(id AS STRING) AS id_segmentacao_origem,
  NULLIF(TRIM(name),'') AS nome_segmentacao,
  standard AS is_padrao_da_rd,
  DATETIME(SAFE_CAST(created_at AS TIMESTAMP),'America/Sao_Paulo') AS criada_em,
  DATETIME(SAFE_CAST(updated_at AS TIMESTAMP),'America/Sao_Paulo') AS atualizada_em,
  COUNT(DISTINCT _fonte) OVER (PARTITION BY CAST(id AS STRING)) AS qtd_fontes_da_segmentacao,
  (COUNT(DISTINCT _fonte) OVER (PARTITION BY CAST(id AS STRING)) > 1) AS flag_segmentacao_em_mais_de_uma_fonte,
  CURRENT_TIMESTAMP() AS _extraido_at,
  _payload_hash
FROM base
)
SELECT * FROM t
