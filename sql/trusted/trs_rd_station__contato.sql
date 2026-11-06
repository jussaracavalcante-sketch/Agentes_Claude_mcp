-- trs_rd_station__contato  (query-9dz7)
-- Trusted RD Station: um contato por fonte. Chave id_contato = _fonte|uuid.
-- Cron diario 13:10 America/Manaus. Par de trs_rd_station__conversao (query-ehQc).
--
-- ATUALIZADO EM 2026-10-16 (idem ao deploy de query-9dz7): 48 FONTES = 30 antigas + 18 publicadas em 14/10/2026
-- (16 com contacts_details, 2 so com segmentation_contacts). Medido: 111.550 -> 260.033 linhas, 260.033 id_contato unicos.
-- Colunas novas: qtd_fontes_do_contato e flag_contato_em_mais_de_uma_fonte (mesmo uuid em >1 _fonte: 3.433 uuids,
-- 6.991 linhas, e-mail identico em todos; NADA e apagado). Fora, com motivo: jSLj (BAJAJ, nao materializou), socq, YLIU, O2oe.
-- Mapa slug -> dataset -> prefixo das 18 novas: ver a descricao da transformacao. Primeira carga com o codigo novo: 17/10 13:10 Manaus.
--
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
-- Trusted RD Station - contato consolidado, 48 fontes (30 antigas + 18 de 14/10/2026). Ver descricao da transformacao.
-- Grao misto por disponibilidade: contacts_details (24 fontes, completo) + segmentation_contacts (24, minimo).
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
  UNION ALL
  SELECT 'rd-station-5KKM','ARENA TINTAS',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintascontacts_details`
  UNION ALL
  SELECT 'rd-station-YNpj','BAP',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_bap`.`rd_station_bapcontacts_details`
  UNION ALL
  SELECT 'rd-station-6Ir5','BRAGA VEICULOS VAREJO',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculos__contacts_details`
  UNION ALL
  SELECT 'rd-station-POZB','CAA ALUMINIO',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_caa_aluminio`.`rd_station_caa_aluminiocontacts_details`
  UNION ALL
  SELECT 'rd-station-irou','CAA TINTAS',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_station_caa_tintas`.`rd_station_caa_tintascontacts_details`
  UNION ALL
  SELECT 'rd-station-QcKP','CHARAO',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_station_charao`.`rd_station_charaocontacts_details`
  UNION ALL
  SELECT 'rd-station-c9jU','CONSTROI INCORPORADORA',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_constroi_incorporadora`.`rd_station_constroi_incorporadoracontacts_details`
  UNION ALL
  SELECT 'rd-station-1boX','PNEU FORTE DISTRIBUIDORA',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_distribuidora_pneu_forte`.`rd_station_pneu_fortecontacts_details`
  UNION ALL
  SELECT 'rd-station-Fzvz','DOCTOR MAIS SAUDE',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_doctor_mais_saude`.`rd_station_doctor_mais_saudecontacts_details`
  UNION ALL
  SELECT 'rd-station-fPd4','HAGE ALIMENTOS',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_hage_alimentos`.`rd_station_hage_alimentoscontacts_details`
  UNION ALL
  SELECT 'rd-station-mEzQ','PMZ ESCOLA',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_pmz_escola`.`rd_station_pmz_escolacontacts_details`
  UNION ALL
  SELECT 'rd-station-zxA3','RODRIX',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_rodrix`.`rd_station_rodrixcontacts_details`
  UNION ALL
  SELECT 'rd-station-ypAe','ROYAL ENFIELD',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_station_royal_enfield`.`rd_station_royal_enfieldcontacts_details`
  UNION ALL
  SELECT 'rd-station-f2o9','SANTO REMEDIO',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_station_santo_remedio`.`rd_station_santo_remediocontacts_details`
  UNION ALL
  SELECT 'rd-station-Sys9','SHIZEN',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_station_shizen`.`rd_station_shizencontacts_details`
  UNION ALL
  SELECT 'rd-station-409D','UNIPAR',uuid,name,email,job_title,birthdate,bio,website,personal_phone,mobile_phone,city,state,country,twitter,facebook,linkedin,TO_JSON_STRING(tags),TO_JSON_STRING(extra_emails),TO_JSON_STRING(legal_bases),custom_fields,updated_at FROM `vanguardamartech_rd_unipar`.`rd_station_uniparcontacts_details`
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
  UNION ALL
  SELECT 'rd-station-IOQX','BRAGA VEICULOS VENDA DIRETA',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_braga_veiculos`.`rd_station_braga_veiculossegmentation_contacts`
  UNION ALL
  SELECT 'rd-station-rlmE','BRAGA MOTOS YAMAHA POS VENDAS',uuid,name,email,last_conversion_date,created_at,updated_at FROM `vanguardamartech_rd_station_braga_motos`.`rd_station_braga_motossegmentation_contacts`
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

  -- MESMO uuid em mais de uma _fonte = o mesmo registro de contato lido por duas conexoes (16/10/2026).
  -- NAO apaga nada: _fonte e id_contato ficam intactos. A escolha de qual linha conta fica na Refined.
  COUNT(DISTINCT _fonte) OVER (PARTITION BY uuid)           AS qtd_fontes_do_contato,
  (COUNT(DISTINCT _fonte) OVER (PARTITION BY uuid) > 1)     AS flag_contato_em_mais_de_uma_fonte,

  CURRENT_TIMESTAMP()                                       AS _extraido_at,
  _payload_hash
FROM base
