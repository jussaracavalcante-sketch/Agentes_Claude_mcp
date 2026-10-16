-- Trusted Google Ads - dimensao de campanhas. 42 fontes.
-- FORMA COMPACTA: cada ramo por fonte e `SELECT '<slug>', * FROM <tabela>`, e as colunas
-- sao nomeadas UMA VEZ nas CTEs `bruto` e `orcamento`. Antes eram 39 blocos nomeando as
-- colunas duas vezes, 45 mil caracteres, impossivel de editar com seguranca.
-- O PRECO: o `*` depende de esquema identico entre as contas — conferido em 17/09/2026
-- nas 42 tabelas de `campaigns` e de `campaign_budget`. Se uma conta divergir, a uniao
-- INTEIRA quebra, nao so aquela conta. Ao somar fonte nova, rodar
-- `SELECT f FROM (<uniao>) LIMIT 0` antes de publicar: falha no plano, sem custo.
WITH campanha_bruto AS (
  SELECT 'google-ads-cwt3' _fonte,* FROM `vanguardamartech_acesso_saude_google_ads`.`google_ads_acesso_saudecampaigns`
  UNION ALL SELECT 'google-ads-DzVL' _fonte,* FROM `vanguardamartech_ola_casa_nova_g_ads`.`google_ads_ola_casa_novacampaigns`
  UNION ALL SELECT 'google-ads-vfUV' _fonte,* FROM `vanguardamartech_move_rental_cars_g_ads`.`google_ads_move_rentalcampaigns`
  UNION ALL SELECT 'google-ads-QuKh' _fonte,* FROM `vanguardamartech_don_watches_conta_1_g_ads`.`google_ads_don_watches_2campaigns`
  UNION ALL SELECT 'google-ads-vE2C' _fonte,* FROM `vanguardamartech_don_watches_conta_2`.`google_ads_watches_2campaigns`
  UNION ALL SELECT 'google-ads-PmFB' _fonte,* FROM `vanguardamartech_braga_varejo`.`google_ads_braga_varejocampaigns`
  UNION ALL SELECT 'google-ads-5J1y' _fonte,* FROM `vanguardamartech_braga_yamaha_consorcios_2`.`google_ads_yamaha_2campaigns`
  UNION ALL SELECT 'google-ads-Pk69' _fonte,* FROM `vanguardamartech_braga_yamaha_consorcios`.`google_ads_braga_yamaha_consorccampaigns`
  UNION ALL SELECT 'google-ads-SyTu' _fonte,* FROM `vanguardamartech_royal_enfield`.`google_ads_royal_enfieldcampaigns`
  UNION ALL SELECT 'google-ads-6Z2v' _fonte,* FROM `vanguardamartech_braga_acessorios`.`google_ads_braga_acessorioscampaigns`
  UNION ALL SELECT 'google-ads-PsES' _fonte,* FROM `vanguardamartech_braga_veiculos`.`google_ads_pos_vendascampaigns`
  UNION ALL SELECT 'google-ads-RCRU' _fonte,* FROM `vanguardamartech_braga_motors_mini`.`google_ads_braga_minicampaigns`
  UNION ALL SELECT 'google-ads-VozJ' _fonte,* FROM `vanguardamartech_braga_motorrad`.`google_ads_braga_motorradcampaigns`
  UNION ALL SELECT 'google-ads-cFrH' _fonte,* FROM `vanguardamartech_braga_motors_bmw_g_ads`.`google_ads_braga_bmwcampaigns`
  UNION ALL SELECT 'google-ads-URNQ' _fonte,* FROM `vanguardamartech_dmelo`.`google_ads_dmelocampaigns`
  UNION ALL SELECT 'google-ads-mEnk' _fonte,* FROM `vanguardamartech_caa`.`google_ads_caa_tintascampaigns`
  UNION ALL SELECT 'google-ads-A1kM' _fonte,* FROM `vanguardamartech_caa_aluminio`.`google_ads_caa_aluminiocampaigns`
  UNION ALL SELECT 'google-ads-rYKp' _fonte,* FROM `vanguardamartech_rodrix_g_ads`.`google_ads_rodrix_motoscampaigns`
  UNION ALL SELECT 'google-ads-C4Aq' _fonte,* FROM `vanguardamartech_deb_transportadora_g_ads`.`google_ads_deb_transportadoracampaigns`
  UNION ALL SELECT 'google-ads-PnyV' _fonte,* FROM `vanguardamartech_rei_das_mangueiras_g_ads`.`google_ads_rei_das_mangueirascampaigns`
  UNION ALL SELECT 'google-ads-0B2k' _fonte,* FROM `vanguardamartech_pneu_forte_distribuidora`.`google_ads_pneu_forte_distcampaigns`
  UNION ALL SELECT 'google-ads-GZ55' _fonte,* FROM `vanguardamartech_millenium_g_ads`.`google_ads_milleniumcampaigns`
  UNION ALL SELECT 'google-ads-802k' _fonte,* FROM `vanguardamartech_pneu_express`.`google_ads_pneu_expresscampaigns`
  UNION ALL SELECT 'google-ads-Jl1R' _fonte,* FROM `vanguardamartech_smile_pneus`.`google_ads_smile_pneuscampaigns`
  UNION ALL SELECT 'google-ads-x20o' _fonte,* FROM `vanguardamartech_steel_port_g_ads`.`google_ads_steel_portcampaigns`
  UNION ALL SELECT 'google-ads-ZcMG' _fonte,* FROM `vanguardamartech_amz_geradores_g_ads`.`google_ads_amz_geradorescampaigns`
  UNION ALL SELECT 'google-ads-wypN' _fonte,* FROM `vanguardamartech_dr_cabral_conta_1`.`google_ads_dr_cabral_1campaigns`
  UNION ALL SELECT 'google-ads-AMd2' _fonte,* FROM `vanguardamartech_santo_remedio_g_ads`.`google_ads_santo_remediocampaigns`
  UNION ALL SELECT 'google-ads-rSav' _fonte,* FROM `vanguardamartech_hospital_santa_julia_g_ads`.`google_ads_h_santa_juliacampaigns`
  UNION ALL SELECT 'google-ads-jT4J' _fonte,* FROM `vanguardamartech_constroi_incorporadora_g_ads`.`google_ads_constroicampaigns`
  UNION ALL SELECT 'google-ads-ABUl' _fonte,* FROM `vanguardamartech_doctor_mais_g_ads`.`google_ads_doctor_maiscampaigns`
  UNION ALL SELECT 'google-ads-R4be' _fonte,* FROM `vanguardamartech_colmeia`.`google_ads_colmeiacampaigns`
  UNION ALL SELECT 'google-ads-fwxw' _fonte,* FROM `vanguardamartech_amazoncopy_g_ads`.`google_ads_amazoncopycampaigns`
  UNION ALL SELECT 'google-ads-dMx7' _fonte,* FROM `vanguardamartech_bigazine_g_ads`.`google_ads_bigazinecampaigns`
  UNION ALL SELECT 'google-ads-x36N' _fonte,* FROM `vanguardamartech_arena_tintas_g_ads`.`google_ads_arena_tintascampaigns`
  UNION ALL SELECT 'google-ads-WxA8' _fonte,* FROM `vanguardamartech_ba_eletrica_g_ads`.`google_ads_ba_eletricacampaigns`
  UNION ALL SELECT 'google-ads-Llsu' _fonte,* FROM `vanguardamartech_pmz_grupo_ecomm`.`google_ads_pmz_ecommcampaigns`
  UNION ALL SELECT 'google-ads-NP4k' _fonte,* FROM `vanguardamartech_pmz_loja`.`google_pmz_grupo_lojacampaigns`
  UNION ALL SELECT 'google-ads-PdSr' _fonte,* FROM `vanguardamartech_pmz_escola_de_mecanicos`.`google_ads_pmz_escola_mecanicoscampaigns`
  UNION ALL SELECT 'google-ads-3eFc' _fonte,* FROM `vanguardamartech_unipar_boa_vista`.`google_ads_unipar_boa_vistacampaigns`
  UNION ALL SELECT 'google-ads-mvUx' _fonte,* FROM `vanguardamartech_unipar_neo_vila`.`google_ads_unipar_neo_vilacampaigns`
  UNION ALL SELECT 'google-ads-hBlk' _fonte,* FROM `vanguardamartech_unipar_torres`.`google_ads_unipar_torrescampaigns`
),
bruto AS (
  SELECT
    _fonte,
    SAFE_CAST(id AS INT64)                                       AS id_campanha,
    REGEXP_EXTRACT(resource_name, r'customers/([0-9]+)/')        AS id_conta,
    NULLIF(TRIM(SAFE_CAST(name AS STRING)),'')                   AS campanha,
    SAFE_CAST(status AS STRING)                                  AS status,
    SAFE_CAST(serving_status AS STRING)                          AS status_veiculacao,
    SAFE_CAST(primary_status AS STRING)                          AS status_primario,
    SAFE_CAST(advertising_channel_type AS STRING)                AS canal,
    SAFE_CAST(advertising_channel_sub_type AS STRING)            AS subcanal,
    SAFE_CAST(bidding_strategy_type AS STRING)                   AS estrategia_lance,
    SAFE_CAST(bidding_strategy_system_status AS STRING)          AS status_estrategia,
    SAFE_CAST(start_date AS DATE)                                AS data_inicio,
    SAFE_CAST(end_date AS DATE)                                  AS data_fim,
    SAFE_CAST(optimization_score AS FLOAT64)                     AS score_otimizacao,
    SAFE_CAST(experiment_type AS STRING)                         AS tipo_experimento
  FROM campanha_bruto
),
orcamento_bruto AS (
  SELECT 'google-ads-cwt3' fonte,* FROM `vanguardamartech_acesso_saude_google_ads`.`google_ads_acesso_saudecampaign_budget`
  UNION ALL SELECT 'google-ads-DzVL' fonte,* FROM `vanguardamartech_ola_casa_nova_g_ads`.`google_ads_ola_casa_novacampaign_budget`
  UNION ALL SELECT 'google-ads-vfUV' fonte,* FROM `vanguardamartech_move_rental_cars_g_ads`.`google_ads_move_rentalcampaign_budget`
  UNION ALL SELECT 'google-ads-QuKh' fonte,* FROM `vanguardamartech_don_watches_conta_1_g_ads`.`google_ads_don_watches_2campaign_budget`
  UNION ALL SELECT 'google-ads-vE2C' fonte,* FROM `vanguardamartech_don_watches_conta_2`.`google_ads_watches_2campaign_budget`
  UNION ALL SELECT 'google-ads-PmFB' fonte,* FROM `vanguardamartech_braga_varejo`.`google_ads_braga_varejocampaign_budget`
  UNION ALL SELECT 'google-ads-5J1y' fonte,* FROM `vanguardamartech_braga_yamaha_consorcios_2`.`google_ads_yamaha_2campaign_budget`
  UNION ALL SELECT 'google-ads-Pk69' fonte,* FROM `vanguardamartech_braga_yamaha_consorcios`.`google_ads_braga_yamaha_consorccampaign_budget`
  UNION ALL SELECT 'google-ads-SyTu' fonte,* FROM `vanguardamartech_royal_enfield`.`google_ads_royal_enfieldcampaign_budget`
  UNION ALL SELECT 'google-ads-6Z2v' fonte,* FROM `vanguardamartech_braga_acessorios`.`google_ads_braga_acessorioscampaign_budget`
  UNION ALL SELECT 'google-ads-PsES' fonte,* FROM `vanguardamartech_braga_veiculos`.`google_ads_pos_vendascampaign_budget`
  UNION ALL SELECT 'google-ads-RCRU' fonte,* FROM `vanguardamartech_braga_motors_mini`.`google_ads_braga_minicampaign_budget`
  UNION ALL SELECT 'google-ads-VozJ' fonte,* FROM `vanguardamartech_braga_motorrad`.`google_ads_braga_motorradcampaign_budget`
  UNION ALL SELECT 'google-ads-cFrH' fonte,* FROM `vanguardamartech_braga_motors_bmw_g_ads`.`google_ads_braga_bmwcampaign_budget`
  UNION ALL SELECT 'google-ads-URNQ' fonte,* FROM `vanguardamartech_dmelo`.`google_ads_dmelocampaign_budget`
  UNION ALL SELECT 'google-ads-mEnk' fonte,* FROM `vanguardamartech_caa`.`google_ads_caa_tintascampaign_budget`
  UNION ALL SELECT 'google-ads-A1kM' fonte,* FROM `vanguardamartech_caa_aluminio`.`google_ads_caa_aluminiocampaign_budget`
  UNION ALL SELECT 'google-ads-rYKp' fonte,* FROM `vanguardamartech_rodrix_g_ads`.`google_ads_rodrix_motoscampaign_budget`
  UNION ALL SELECT 'google-ads-C4Aq' fonte,* FROM `vanguardamartech_deb_transportadora_g_ads`.`google_ads_deb_transportadoracampaign_budget`
  UNION ALL SELECT 'google-ads-PnyV' fonte,* FROM `vanguardamartech_rei_das_mangueiras_g_ads`.`google_ads_rei_das_mangueirascampaign_budget`
  UNION ALL SELECT 'google-ads-0B2k' fonte,* FROM `vanguardamartech_pneu_forte_distribuidora`.`google_ads_pneu_forte_distcampaign_budget`
  UNION ALL SELECT 'google-ads-GZ55' fonte,* FROM `vanguardamartech_millenium_g_ads`.`google_ads_milleniumcampaign_budget`
  UNION ALL SELECT 'google-ads-802k' fonte,* FROM `vanguardamartech_pneu_express`.`google_ads_pneu_expresscampaign_budget`
  UNION ALL SELECT 'google-ads-Jl1R' fonte,* FROM `vanguardamartech_smile_pneus`.`google_ads_smile_pneuscampaign_budget`
  UNION ALL SELECT 'google-ads-x20o' fonte,* FROM `vanguardamartech_steel_port_g_ads`.`google_ads_steel_portcampaign_budget`
  UNION ALL SELECT 'google-ads-ZcMG' fonte,* FROM `vanguardamartech_amz_geradores_g_ads`.`google_ads_amz_geradorescampaign_budget`
  UNION ALL SELECT 'google-ads-wypN' fonte,* FROM `vanguardamartech_dr_cabral_conta_1`.`google_ads_dr_cabral_1campaign_budget`
  UNION ALL SELECT 'google-ads-AMd2' fonte,* FROM `vanguardamartech_santo_remedio_g_ads`.`google_ads_santo_remediocampaign_budget`
  UNION ALL SELECT 'google-ads-rSav' fonte,* FROM `vanguardamartech_hospital_santa_julia_g_ads`.`google_ads_h_santa_juliacampaign_budget`
  UNION ALL SELECT 'google-ads-jT4J' fonte,* FROM `vanguardamartech_constroi_incorporadora_g_ads`.`google_ads_constroicampaign_budget`
  UNION ALL SELECT 'google-ads-ABUl' fonte,* FROM `vanguardamartech_doctor_mais_g_ads`.`google_ads_doctor_maiscampaign_budget`
  UNION ALL SELECT 'google-ads-R4be' fonte,* FROM `vanguardamartech_colmeia`.`google_ads_colmeiacampaign_budget`
  UNION ALL SELECT 'google-ads-fwxw' fonte,* FROM `vanguardamartech_amazoncopy_g_ads`.`google_ads_amazoncopycampaign_budget`
  UNION ALL SELECT 'google-ads-dMx7' fonte,* FROM `vanguardamartech_bigazine_g_ads`.`google_ads_bigazinecampaign_budget`
  UNION ALL SELECT 'google-ads-x36N' fonte,* FROM `vanguardamartech_arena_tintas_g_ads`.`google_ads_arena_tintascampaign_budget`
  UNION ALL SELECT 'google-ads-WxA8' fonte,* FROM `vanguardamartech_ba_eletrica_g_ads`.`google_ads_ba_eletricacampaign_budget`
  UNION ALL SELECT 'google-ads-Llsu' fonte,* FROM `vanguardamartech_pmz_grupo_ecomm`.`google_ads_pmz_ecommcampaign_budget`
  UNION ALL SELECT 'google-ads-NP4k' fonte,* FROM `vanguardamartech_pmz_loja`.`google_pmz_grupo_lojacampaign_budget`
  UNION ALL SELECT 'google-ads-PdSr' fonte,* FROM `vanguardamartech_pmz_escola_de_mecanicos`.`google_ads_pmz_escola_mecanicoscampaign_budget`
  UNION ALL SELECT 'google-ads-3eFc' fonte,* FROM `vanguardamartech_unipar_boa_vista`.`google_ads_unipar_boa_vistacampaign_budget`
  UNION ALL SELECT 'google-ads-mvUx' fonte,* FROM `vanguardamartech_unipar_neo_vila`.`google_ads_unipar_neo_vilacampaign_budget`
  UNION ALL SELECT 'google-ads-hBlk' fonte,* FROM `vanguardamartech_unipar_torres`.`google_ads_unipar_torrescampaign_budget`
),
orcamento AS (
  -- O ANY_VALUE existia dentro de cada ramo, com GROUP BY por fonte. Agora a uniao vem
  -- crua e a agregacao acontece UMA VEZ, aqui. Mesmo resultado: o grupo continua sendo
  -- (fonte, id_campanha).
  SELECT
    fonte,
    SAFE_CAST(campaign_id AS INT64)                              AS id_campanha,
    ANY_VALUE(SAFE_CAST(amount_micros AS INT64))                 AS orc_diario_micros,
    ANY_VALUE(SAFE_CAST(total_amount_micros AS INT64))           AS orc_total_micros,
    ANY_VALUE(SAFE_CAST(period AS STRING))                       AS periodo,
    ANY_VALUE(SAFE_CAST(delivery_method AS STRING))              AS metodo_entrega,
    ANY_VALUE(SAFE_CAST(explicitly_shared AS BOOL))              AS compartilhado
  FROM orcamento_bruto
  GROUP BY 1,2
),

base AS (
  SELECT
    b.*,
    TO_HEX(MD5(TO_JSON_STRING(b)))                            AS _payload_hash
  FROM bruto b
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY b._fonte, b.id_campanha ORDER BY b.campanha) = 1
)
SELECT
  b.id_campanha,
  b.id_conta,
  -- cliente e moeda vem da dimensao trs_google_ads__conta, resolvidos por id_conta
  -- (extraido do resource_name). Eram literais escritos a mao, um par por fonte:
  -- 39 no total nesta query. Agora ha uma fonte de verdade so, semeada do MCC.
  d.cliente,
  d.moeda,
  b.campanha,

  b.status,
  b.status_veiculacao,
  b.status_primario,
  (b.status = 'ENABLED')                                      AS ativa,

  b.canal,
  b.subcanal,
  b.estrategia_lance,
  b.status_estrategia,

  b.data_inicio,
  IF(b.data_fim >= DATE '2037-01-01', NULL, b.data_fim)       AS data_fim,
  (b.data_fim >= DATE '2037-01-01')                           AS sem_fim_definido,

  orc.orc_diario_micros                                       AS orcamento_diario_micros,
  SAFE_DIVIDE(orc.orc_diario_micros, 1000000)                 AS orcamento_diario,
  orc.orc_total_micros                                        AS orcamento_total_micros,
  SAFE_DIVIDE(orc.orc_total_micros, 1000000)                  AS orcamento_total,
  orc.periodo                                                 AS periodo_orcamento,
  orc.metodo_entrega                                          AS metodo_entrega_orcamento,
  orc.compartilhado                                           AS orcamento_compartilhado,

  b.score_otimizacao,
  b.tipo_experimento,

  -- Se a dimensao nao tiver a conta, cliente e moeda vem NULL. A flag existe para
  -- que isso apareca em vez de sumir dentro de um GROUP BY.
  (d.id_conta IS NULL)                                        AS flag_conta_nao_catalogada,

  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  b._fonte,
  b._payload_hash
FROM base b
LEFT JOIN orcamento orc
  ON orc.id_campanha = b.id_campanha AND orc.fonte = b._fonte
-- LEFT e proposital: INNER descartaria campanha em silencio se a dimensao
-- estivesse desatualizada. Aqui a linha fica e a flag acende.
LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__conta` d
  ON d.id_conta = b.id_conta
