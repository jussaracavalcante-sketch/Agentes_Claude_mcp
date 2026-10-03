-- trs_rd_station__contato  (query-9dz7)
-- Trusted RD Station: um contato por fonte. Chave id_contato = _fonte|uuid.
-- Cron diario 13:10 America/Manaus. Par de trs_rd_station__conversao (query-ehQc).
--
-- ARQUIVO RECUPERADO DE get_code EM 29/09/2026. Esta transformacao foi publicada em
-- 01/09 e NUNCA teve arquivo no repositorio -- registro com buraco nao e registro.
--
-- ATENCAO -- HA MAIS DE UMA TABELA COM ESTE NOME. A consolidada e
-- `vanguardamartech_trusted.trs_rd_station__contato`; existem homonimas nas camadas
-- de cliente (ex.: `vanguardamartech_braga_veiculos`), geradas pelas queries por
-- cliente. Apontar para a camada errada devolve UM cliente e parece a base inteira --
-- mesma armadilha ja registrada no Facebook Ads.
--
-- GRAO MISTO POR DISPONIBILIDADE. `contacts_details` traz 21 campos; a
-- `segmentation_contacts` traz 4. `tem_detalhe` separa os dois -- NAO tratar NULL
-- como "nao tem" antes de filtrar por ele.
--
-- TRES FONTES FORA: rd-station-1eaJ e bjQx (subconjuntos estritos da pDLk) e
-- rd-station-socq (nunca materializou).
--
-- FUSO: a origem devolve UTC e as datas saem em America/Sao_Paulo.
--
-- Ver a descricao na Nekt para o inventario completo de fontes e prefixos.
-- Trusted RD Station - contato consolidado, 30 fontes. Ver descricao da transformacao.
-- Grao misto por disponibilidade: contacts_details (8 fontes, completo) + segmentation_contacts (22, minimo).
WITH detalhe AS (
  SELECT 'rd-station-pG4G' _fonte,'BEST CAR' cliente,uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags) tags_json,TO_JSON_STRING(extra_emails) emails_extras_json,TO_JSON_STRING(legal_bases) bases_legais_json,custom_fields,updated_at FROM `vanguardamartech_rd_marketing`.`rd_best_carcontacts_details`
  UNION ALL
  SELECT 'rd-station-WHAa','BRAGA VEICULOS',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_marketing`.`rd_braga_veiculoscontacts_details`
  UNION ALL
  SELECT 'rd-station-bdVN','PMZ',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_marketing`.`rd_pmz_contacts_details`
  UNION ALL
  SELECT 'rd-station-VYbu','CONSTRUTORA COLMEIA',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_marketing`.`rd_colmeia_contacts_details`
  UNION ALL
  SELECT 'rd-station-CSrx','AMZ GERADORES',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_marketing`.`rd_amz_geradorescontacts_details`
  UNION ALL
  SELECT 'rd-station-Ozim','KL RENT A CAR',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_marketing`.`rd_kl_rentcontacts_details`
  UNION ALL
  SELECT 'rd-station-oYKw','RD_station_marketing',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_marketing`.`rd_station_contacts_details`
  UNION ALL
  SELECT 'rd-station-pDLk','RD_clientes_vanguarda',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_marketing`.`rd_station_marketingcontacts_details`
),
segmento AS (
  SELECT 'rd-station-7K57' _fonte,'PNEU FORTE' cliente,uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_pneuforte_segmentation_contacts`
  UNION ALL
  SELECT 'rd-station-Awhd','ACESSO SAUDE',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_acesso_saudesegmentation_contacts`
  UNION ALL
  SELECT 'rd-station-idF7','BRAGA MOTORS',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_braga_motorssegmentation_contacts`
  UNION ALL
  SELECT 'rd-station-5RPi','AC DISPLAY',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_acdisplay_segmentation_contacts`
  UNION ALL
  SELECT 'rd-station-9mbj','AMAZONCOPY',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_amazoncopy_segmentation_contacts`
  UNION ALL
  SELECT 'rd-station-CWtQ','MARAVILHA MOTOS',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_maravilha_segmentation_contacts`
  UNION ALL
  SELECT 'rd-station-L2Sl','DR. JOSE CABRAL JR',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_cabral_segmentation_contacts`
  UNION ALL
  SELECT 'rd-station-dvZx','DON WATCHES',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_watches_segmentation_contacts`
  UNION ALL
  SELECT 'rd-station-sPoP','MOVE',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_move_segmentation_contacts`
  UNION ALL
  SELECT 'rd-station-3k4Z','DMELLO',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_dmello_segmentation_contacts`
  UNION ALL
  SELECT 'rd-station-4b7D','MILLENIUM SHOPPING',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_millennium_shoppingsegmentation_contacts`
  UNION ALL
  SELECT 'rd-station-AqsD','AMAZON OPEN MALL',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_openwall_segmentation_contacts`
  UNION ALL
  SELECT 'rd-station-h3u2','REI DAS MANGUEIRAS',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_rei_mangueirassegmentation_contacts`
  UNION ALL
  SELECT 'rd-station-8Fqy','BRAGA ACESSORIOS',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_braga_acessoriossegmentation_contacts`
  UNION ALL
  SELECT 'rd-station-MzyH','BA ELETRICA',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_ba_eletricasegmentation_contacts`
  UNION ALL
  SELECT 'rd-station-STKa','HOSPITAL SANTA JULIA',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_hospital_santa_juliasegmentation_contacts`
  UNION ALL
  SELECT 'rd-station-HVbj','STEEL PORT',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_steel_portsegmentation_contacts`
  UNION ALL
  SELECT 'rd-station-HoWi','HOPE BAY',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_hope_baysegmentation_contacts`
  UNION ALL
  SELECT 'rd-station-uOAA','COMAC',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_comac_segmentation_contacts`
  UNION ALL
  SELECT 'rd-station-urW3','BIGAZINE MANAUS',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_bigazine_segmentation_contacts`
  UNION ALL
  SELECT 'rd-station-sLX1','INFORCELL',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_infocell_segmentation_contacts`
  UNION ALL
  SELECT 'rd-station-iJK3','VBOT',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_marketing`.`rd_vbot_segmentation_contacts`
),
bruto AS (
  SELECT 'contacts_details' origem_contato,_fonte,cliente,uuid,name,email,
    job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,
    twitter,facebook,linkedin,tags_json,emails_extras_json,bases_legais_json,custom_fields,
    CAST(NULL AS TIMESTAMP) last_conversion_date,CAST(NULL AS TIMESTAMP) created_at,updated_at
  FROM detalhe
  UNION ALL
  SELECT 'segmentation_contacts',_fonte,cliente,uuid,name,email,
    CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),
    last_conversion_date,created_at,updated_at
  FROM segmento
),
base AS (
  SELECT b.*, TO_HEX(MD5(TO_JSON_STRING(b))) AS _payload_hash
  FROM bruto b
  QUALIFY ROW_NUMBER() OVER (PARTITION BY b._fonte, b.uuid ORDER BY b.updated_at DESC) = 1
)
SELECT
  CONCAT(_fonte,'|',uuid)                                   AS id_contato,
  _fonte,
  cliente,
  origem_contato,
  uuid                                                      AS uuid_contato,

  NULLIF(TRIM(name),'')                                     AS nome,
  LOWER(NULLIF(TRIM(email),''))                             AS email,
  LOWER(NULLIF(SPLIT(email,'@')[SAFE_OFFSET(1)],''))        AS dominio_email,

  NULLIF(TRIM(job_title),'')                                AS cargo,
  NULLIF(TRIM(birthdate),'')                                AS aniversario,
  NULLIF(TRIM(bio),'')                                      AS bio,
  NULLIF(TRIM(website),'')                                  AS site,
  NULLIF(TRIM(personal_phone),'')                           AS telefone_pessoal,
  NULLIF(TRIM(mobile_phone),'')                             AS telefone_movel,
  NULLIF(TRIM(city),'')                                     AS cidade,
  NULLIF(TRIM(state),'')                                    AS estado,
  NULLIF(TRIM(country),'')                                  AS pais,
  NULLIF(TRIM(twitter),'')                                  AS twitter,
  NULLIF(TRIM(facebook),'')                                 AS facebook,
  NULLIF(TRIM(linkedin),'')                                 AS linkedin,

  NULLIF(tags_json,'[]')                                    AS tags_json,
  NULLIF(emails_extras_json,'[]')                           AS emails_extras_json,
  NULLIF(bases_legais_json,'[]')                            AS bases_legais_json,
  NULLIF(custom_fields,'{}')                                AS campos_customizados_json,

  DATETIME(created_at,'America/Sao_Paulo')                  AS criado_em,
  DATETIME(updated_at,'America/Sao_Paulo')                  AS atualizado_em,
  DATETIME(last_conversion_date,'America/Sao_Paulo')        AS ultima_conversao_em,
  DATE(DATETIME(updated_at,'America/Sao_Paulo'))            AS atualizado_data,

  (origem_contato='contacts_details')                       AS tem_detalhe,
  (personal_phone IS NOT NULL OR mobile_phone IS NOT NULL)  AS tem_telefone,
  (city IS NOT NULL OR state IS NOT NULL)                   AS tem_localizacao,

  CURRENT_TIMESTAMP()                                       AS _extraido_at,
  _payload_hash
FROM base
