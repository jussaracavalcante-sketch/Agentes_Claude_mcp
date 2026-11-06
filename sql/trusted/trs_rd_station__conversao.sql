-- trs_rd_station__conversao  (query-ehQc)
-- Trusted RD Station: um evento de conversao. Chave id_conversao = _fonte|id.
-- Cron diario 13:20 America/Manaus. Par de trs_rd_station__contato (query-9dz7).
--
-- ATUALIZADO EM 2026-10-16 (idem ao deploy de query-ehQc): 48 FONTES = 30 antigas + 18 de 14/10/2026.
-- Medido: 125.914 -> 416.267 linhas, 416.267 id_conversao unicos. Colunas novas: id_evento, qtd_fontes_do_evento e
-- flag_evento_em_mais_de_uma_fonte (mesmo id de evento em >1 _fonte: 9.938 linhas; CAA TINTAS e CAA ALUMINIO = mesma conta).
-- Prefixo de Braga: 6Ir5 usa rd_station_braga_veiculos__contact_events, IOQX usa rd_station_braga_veiculoscontact_events.
-- Primeira carga com o codigo novo: 17/10 13:20 Manaus. Depois dela roda a Refined query-tESg (que le as colunas novas).
--
--
-- ARQUIVO RECUPERADO DE get_code EM 29/09/2026. Publicada em 01/09 e NUNCA teve
-- arquivo no repositorio -- registro com buraco nao e registro.
--
-- ATENCAO -- HA MAIS DE UMA TABELA COM ESTE NOME. A consolidada e
-- `vanguardamartech_trusted.trs_rd_station__conversao`; existem homonimas nas camadas
-- de cliente (ex.: `vanguardamartech_braga_veiculos`). Apontar para a camada errada
-- devolve UM cliente e parece a base inteira.
--
-- PAYLOAD SERIALIZADO DE PROPOSITO: unir 30 tabelas por STRUCT quebra se uma fonte
-- tiver formato diferente. O union carrega TO_JSON_STRING(payload) e os campos saem
-- depois com JSON_VALUE.
--
-- UTM VEM DENTRO DE UMA QUERY STRING, NAO EM CAMPO, e os valores extraidos continuam
-- PERCENT-ENCODED. Decodificar e regra de negocio e pertence a Refined
-- (rfn_marketing__conversao). Agrupar por utm_source sem decodificar racha a mesma
-- fonte em variantes.
--
-- NAO TRATAR NULL COMO "direto"/"organico": e desconhecido.
--
-- FUSO: event_timestamp chega em UTC e sai em America/Sao_Paulo.
--
-- JOIN COM CONTATO: LEFT, nunca INNER -- contato pode existir sem ter convertido, e
-- evento antigo pode apontar para contato que saiu da base.
-- Trusted RD Station - conversao consolidada, 48 fontes (30 antigas + 18 de 14/10/2026). Ver descricao da transformacao.
-- payload vai serializado em JSON no union de proposito: o STRUCT pode variar entre fontes.
WITH bruto AS (
  SELECT 'rd-station-pG4G' _fonte,'BEST CAR' cliente,id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) payload_json FROM `vanguardamartech_rd_marketing`.`rd_best_carcontact_events`
  UNION ALL
  SELECT 'rd-station-WHAa','BRAGA VEICULOS',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_braga_veiculoscontact_events`
  UNION ALL
  SELECT 'rd-station-bdVN','PMZ',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_pmz_contact_events`
  UNION ALL
  SELECT 'rd-station-VYbu','CONSTRUTORA COLMEIA',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_colmeia_contact_events`
  UNION ALL
  SELECT 'rd-station-CSrx','AMZ GERADORES',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_amz_geradorescontact_events`
  UNION ALL
  SELECT 'rd-station-Ozim','KL RENT A CAR',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_kl_rentcontact_events`
  UNION ALL
  SELECT 'rd-station-oYKw','RD_station_marketing',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_station_contact_events`
  UNION ALL
  SELECT 'rd-station-pDLk','RD_clientes_vanguarda',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_station_marketingcontact_events`
  UNION ALL
  SELECT 'rd-station-7K57','PNEU FORTE',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_pneuforte_contact_events`
  UNION ALL
  SELECT 'rd-station-Awhd','ACESSO SAUDE',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_acesso_saudecontact_events`
  UNION ALL
  SELECT 'rd-station-idF7','BRAGA MOTORS',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_braga_motorscontact_events`
  UNION ALL
  SELECT 'rd-station-5RPi','AC DISPLAY',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_acdisplay_contact_events`
  UNION ALL
  SELECT 'rd-station-9mbj','AMAZONCOPY',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_amazoncopy_contact_events`
  UNION ALL
  SELECT 'rd-station-CWtQ','MARAVILHA MOTOS',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_maravilha_contact_events`
  UNION ALL
  SELECT 'rd-station-L2Sl','DR. JOSE CABRAL JR',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_cabral_contact_events`
  UNION ALL
  SELECT 'rd-station-dvZx','DON WATCHES',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_watches_contact_events`
  UNION ALL
  SELECT 'rd-station-sPoP','MOVE',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_move_contact_events`
  UNION ALL
  SELECT 'rd-station-3k4Z','DMELLO',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_dmello_contact_events`
  UNION ALL
  SELECT 'rd-station-4b7D','MILLENIUM SHOPPING',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_millennium_shoppingcontact_events`
  UNION ALL
  SELECT 'rd-station-AqsD','AMAZON OPEN MALL',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_openwall_contact_events`
  UNION ALL
  SELECT 'rd-station-h3u2','REI DAS MANGUEIRAS',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_rei_mangueirascontact_events`
  UNION ALL
  SELECT 'rd-station-8Fqy','BRAGA ACESSORIOS',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_braga_acessorioscontact_events`
  UNION ALL
  SELECT 'rd-station-MzyH','BA ELETRICA',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_ba_eletricacontact_events`
  UNION ALL
  SELECT 'rd-station-STKa','HOSPITAL SANTA JULIA',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_hospital_santa_juliacontact_events`
  UNION ALL
  SELECT 'rd-station-HVbj','STEEL PORT',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_steel_portcontact_events`
  UNION ALL
  SELECT 'rd-station-HoWi','HOPE BAY',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_hope_baycontact_events`
  UNION ALL
  SELECT 'rd-station-uOAA','COMAC',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_comac_contact_events`
  UNION ALL
  SELECT 'rd-station-urW3','BIGAZINE MANAUS',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_bigazine_contact_events`
  UNION ALL
  SELECT 'rd-station-sLX1','INFORCELL',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_infocell_contact_events`
  UNION ALL
  SELECT 'rd-station-iJK3','VBOT',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_marketing`.`rd_vbot_contact_events`
  UNION ALL
  SELECT 'rd-station-5KKM','ARENA TINTAS',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintascontact_events`
  UNION ALL
  SELECT 'rd-station-YNpj','BAP',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_bap`.`rd_station_bapcontact_events`
  UNION ALL
  SELECT 'rd-station-6Ir5','BRAGA VEICULOS VAREJO',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculos__contact_events`
  UNION ALL
  SELECT 'rd-station-POZB','CAA ALUMINIO',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_caa_aluminio`.`rd_station_caa_aluminiocontact_events`
  UNION ALL
  SELECT 'rd-station-irou','CAA TINTAS',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_station_caa_tintas`.`rd_station_caa_tintascontact_events`
  UNION ALL
  SELECT 'rd-station-QcKP','CHARAO',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_station_charao`.`rd_station_charaocontact_events`
  UNION ALL
  SELECT 'rd-station-c9jU','CONSTROI INCORPORADORA',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_constroi_incorporadora`.`rd_station_constroi_incorporadoracontact_events`
  UNION ALL
  SELECT 'rd-station-1boX','PNEU FORTE DISTRIBUIDORA',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_distribuidora_pneu_forte`.`rd_station_pneu_fortecontact_events`
  UNION ALL
  SELECT 'rd-station-Fzvz','DOCTOR MAIS SAUDE',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_doctor_mais_saude`.`rd_station_doctor_mais_saudecontact_events`
  UNION ALL
  SELECT 'rd-station-fPd4','HAGE ALIMENTOS',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_hage_alimentos`.`rd_station_hage_alimentoscontact_events`
  UNION ALL
  SELECT 'rd-station-mEzQ','PMZ ESCOLA',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_pmz_escola`.`rd_station_pmz_escolacontact_events`
  UNION ALL
  SELECT 'rd-station-zxA3','RODRIX',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_rodrix`.`rd_station_rodrixcontact_events`
  UNION ALL
  SELECT 'rd-station-ypAe','ROYAL ENFIELD',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_station_royal_enfield`.`rd_station_royal_enfieldcontact_events`
  UNION ALL
  SELECT 'rd-station-f2o9','SANTO REMEDIO',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_station_santo_remedio`.`rd_station_santo_remediocontact_events`
  UNION ALL
  SELECT 'rd-station-Sys9','SHIZEN',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_station_shizen`.`rd_station_shizencontact_events`
  UNION ALL
  SELECT 'rd-station-409D','UNIPAR',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_unipar`.`rd_station_uniparcontact_events`
  UNION ALL
  SELECT 'rd-station-IOQX','BRAGA VEICULOS VENDA DIRETA',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculoscontact_events`
  UNION ALL
  SELECT 'rd-station-rlmE','BRAGA MOTOS YAMAHA POS VENDAS',id,contact_uuid,event_type,event_family,event_identifier,event_timestamp,TO_JSON_STRING(payload) FROM `vanguardamartech_rd_station_braga_motos`.`rd_station_braga_motoscontact_events`
),
base AS (
  SELECT b.*, TO_HEX(MD5(TO_JSON_STRING(b))) AS _payload_hash
  FROM bruto b
  QUALIFY ROW_NUMBER() OVER (PARTITION BY b._fonte, b.id ORDER BY b.event_timestamp DESC) = 1
)
SELECT
  CONCAT(_fonte,'|',id)                                        AS id_conversao,
  id                                                           AS id_evento,
  _fonte,
  cliente,
  contact_uuid                                                 AS uuid_contato,
  CONCAT(_fonte,'|',contact_uuid)                              AS id_contato,

  NULLIF(TRIM(event_type),'')                                  AS tipo_evento,
  NULLIF(TRIM(event_family),'')                                AS familia_evento,
  NULLIF(TRIM(event_identifier),'')                            AS identificador_evento,

  DATETIME(event_timestamp,'America/Sao_Paulo')                AS ocorrido_em,
  DATE(DATETIME(event_timestamp,'America/Sao_Paulo'))          AS ocorrido_data,
  DATE_TRUNC(DATE(DATETIME(event_timestamp,'America/Sao_Paulo')), MONTH) AS mes_referencia,

  NULLIF(JSON_VALUE(payload_json,'$.conversion_identifier'),'') AS identificador_conversao,
  NULLIF(JSON_VALUE(payload_json,'$.traffic_source'),'')        AS fonte_trafego_bruta,
  NULLIF(JSON_VALUE(payload_json,'$.traffic_medium'),'')        AS meio_trafego,
  NULLIF(JSON_VALUE(payload_json,'$.traffic_campaign'),'')      AS campanha_trafego,
  NULLIF(REGEXP_EXTRACT(JSON_VALUE(payload_json,'$.traffic_source'), r'utm_source=([^&]*)'),'')   AS utm_source,
  NULLIF(REGEXP_EXTRACT(JSON_VALUE(payload_json,'$.traffic_source'), r'utm_medium=([^&]*)'),'')   AS utm_medium,
  NULLIF(REGEXP_EXTRACT(JSON_VALUE(payload_json,'$.traffic_source'), r'utm_campaign=([^&]*)'),'') AS utm_campaign,
  NULLIF(JSON_VALUE(payload_json,'$.custom_fields'),'')         AS campos_conversao_json,
  payload_json,

  (JSON_VALUE(payload_json,'$.traffic_source') IS NOT NULL)     AS tem_origem_trafego,

  -- MESMO id de evento em mais de uma _fonte = o mesmo evento lido por duas conexoes (16/10/2026).
  -- NAO apaga nada: a escolha da linha canonica fica na Refined.
  COUNT(DISTINCT _fonte) OVER (PARTITION BY id)                 AS qtd_fontes_do_evento,
  (COUNT(DISTINCT _fonte) OVER (PARTITION BY id) > 1)           AS flag_evento_em_mais_de_uma_fonte,

  CURRENT_TIMESTAMP()                                          AS _extraido_at,
  _payload_hash
FROM base
