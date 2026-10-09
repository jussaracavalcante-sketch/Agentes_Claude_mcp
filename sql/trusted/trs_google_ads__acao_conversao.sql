-- trs_google_ads__acao_conversao
-- Trusted do CADASTRO DE ACOES DE CONVERSAO do Google Ads (dimensao), consolidada nas 42 fontes.
-- Grao: id_acao dentro da fonte (fotografia do estado atual). Origem: conversion_actions em cada camada de fonte.
-- Medido em 2026-10-06 antes de publicar: 536 acoes, 536 chaves (fonte, acao), 41 fontes, zero sem nome.
-- primary_for_goal e include_in_conversions_metric chegam como TEXTO e saem como BOOL (SAFE_CAST: valor estranho vira NULL, nao FALSE).
-- id_conta injetado de conta_por_fonte. O Trusted NAO escolhe qual acao e 'a conversao' do cliente (regra de negocio).
-- FORMA COMPACTA: o * depende de esquema identico; ao somar fonte nova rodar a uniao sob LIMIT 0.
WITH bruto AS (
  SELECT 'google-ads-cwt3' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_acesso_saude_google_ads`.`google_ads_acesso_saudeconversion_actions` x UNION ALL
  SELECT 'google-ads-DzVL' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_ola_casa_nova_g_ads`.`google_ads_ola_casa_novaconversion_actions` x UNION ALL
  SELECT 'google-ads-vfUV' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_move_rental_cars_g_ads`.`google_ads_move_rentalconversion_actions` x UNION ALL
  SELECT 'google-ads-QuKh' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_don_watches_conta_1_g_ads`.`google_ads_don_watches_2conversion_actions` x UNION ALL
  SELECT 'google-ads-vE2C' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_don_watches_conta_2`.`google_ads_watches_2conversion_actions` x UNION ALL
  SELECT 'google-ads-PmFB' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_varejo`.`google_ads_braga_varejoconversion_actions` x UNION ALL
  SELECT 'google-ads-5J1y' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_yamaha_consorcios_2`.`google_ads_yamaha_2conversion_actions` x UNION ALL
  SELECT 'google-ads-Pk69' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_yamaha_consorcios`.`google_ads_braga_yamaha_consorcconversion_actions` x UNION ALL
  SELECT 'google-ads-SyTu' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_royal_enfield`.`google_ads_royal_enfieldconversion_actions` x UNION ALL
  SELECT 'google-ads-6Z2v' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_acessorios`.`google_ads_braga_acessoriosconversion_actions` x UNION ALL
  SELECT 'google-ads-PsES' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_veiculos`.`google_ads_pos_vendasconversion_actions` x UNION ALL
  SELECT 'google-ads-RCRU' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_motors_mini`.`google_ads_braga_miniconversion_actions` x UNION ALL
  SELECT 'google-ads-VozJ' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_motorrad`.`google_ads_braga_motorradconversion_actions` x UNION ALL
  SELECT 'google-ads-cFrH' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_motors_bmw_g_ads`.`google_ads_braga_bmwconversion_actions` x UNION ALL
  SELECT 'google-ads-URNQ' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_dmelo`.`google_ads_dmeloconversion_actions` x UNION ALL
  SELECT 'google-ads-mEnk' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_caa`.`google_ads_caa_tintasconversion_actions` x UNION ALL
  SELECT 'google-ads-A1kM' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_caa_aluminio`.`google_ads_caa_aluminioconversion_actions` x UNION ALL
  SELECT 'google-ads-rYKp' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_rodrix_g_ads`.`google_ads_rodrix_motosconversion_actions` x UNION ALL
  SELECT 'google-ads-C4Aq' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_deb_transportadora_g_ads`.`google_ads_deb_transportadoraconversion_actions` x UNION ALL
  SELECT 'google-ads-PnyV' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_rei_das_mangueiras_g_ads`.`google_ads_rei_das_mangueirasconversion_actions` x UNION ALL
  SELECT 'google-ads-0B2k' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pneu_forte_distribuidora`.`google_ads_pneu_forte_distconversion_actions` x UNION ALL
  SELECT 'google-ads-GZ55' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_millenium_g_ads`.`google_ads_milleniumconversion_actions` x UNION ALL
  SELECT 'google-ads-802k' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pneu_express`.`google_ads_pneu_expressconversion_actions` x UNION ALL
  SELECT 'google-ads-Jl1R' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_smile_pneus`.`google_ads_smile_pneusconversion_actions` x UNION ALL
  SELECT 'google-ads-x20o' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_steel_port_g_ads`.`google_ads_steel_portconversion_actions` x UNION ALL
  SELECT 'google-ads-ZcMG' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_amz_geradores_g_ads`.`google_ads_amz_geradoresconversion_actions` x UNION ALL
  SELECT 'google-ads-wypN' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_dr_cabral_conta_1`.`google_ads_dr_cabral_1conversion_actions` x UNION ALL
  SELECT 'google-ads-AMd2' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_santo_remedio_g_ads`.`google_ads_santo_remedioconversion_actions` x UNION ALL
  SELECT 'google-ads-rSav' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_hospital_santa_julia_g_ads`.`google_ads_h_santa_juliaconversion_actions` x UNION ALL
  SELECT 'google-ads-jT4J' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_constroi_incorporadora_g_ads`.`google_ads_constroiconversion_actions` x UNION ALL
  SELECT 'google-ads-ABUl' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_doctor_mais_g_ads`.`google_ads_doctor_maisconversion_actions` x UNION ALL
  SELECT 'google-ads-R4be' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_colmeia`.`google_ads_colmeiaconversion_actions` x UNION ALL
  SELECT 'google-ads-fwxw' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_amazoncopy_g_ads`.`google_ads_amazoncopyconversion_actions` x UNION ALL
  SELECT 'google-ads-dMx7' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_bigazine_g_ads`.`google_ads_bigazineconversion_actions` x UNION ALL
  SELECT 'google-ads-x36N' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_arena_tintas_g_ads`.`google_ads_arena_tintasconversion_actions` x UNION ALL
  SELECT 'google-ads-WxA8' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_ba_eletrica_g_ads`.`google_ads_ba_eletricaconversion_actions` x UNION ALL
  SELECT 'google-ads-Llsu' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pmz_grupo_ecomm`.`google_ads_pmz_ecommconversion_actions` x UNION ALL
  SELECT 'google-ads-NP4k' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pmz_loja`.`google_pmz_grupo_lojaconversion_actions` x UNION ALL
  SELECT 'google-ads-PdSr' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pmz_escola_de_mecanicos`.`google_ads_pmz_escola_mecanicosconversion_actions` x UNION ALL
  SELECT 'google-ads-3eFc' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_unipar_boa_vista`.`google_ads_unipar_boa_vistaconversion_actions` x UNION ALL
  SELECT 'google-ads-mvUx' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_unipar_neo_vila`.`google_ads_unipar_neo_vilaconversion_actions` x UNION ALL
  SELECT 'google-ads-hBlk' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_unipar_torres`.`google_ads_unipar_torresconversion_actions` x
),
conta_por_fonte AS (
  SELECT 'google-ads-cwt3' AS _fonte, '1752443056' AS id_conta
  UNION ALL SELECT 'google-ads-DzVL', '6155043001'
  UNION ALL SELECT 'google-ads-vfUV', '5685989711'
  UNION ALL SELECT 'google-ads-QuKh', '9451726644'
  UNION ALL SELECT 'google-ads-vE2C', '8553733895'
  UNION ALL SELECT 'google-ads-PmFB', '8437632791'
  UNION ALL SELECT 'google-ads-5J1y', '4216086233'
  UNION ALL SELECT 'google-ads-Pk69', '1874995593'
  UNION ALL SELECT 'google-ads-SyTu', '1214474505'
  UNION ALL SELECT 'google-ads-6Z2v', '3193747131'
  UNION ALL SELECT 'google-ads-PsES', '1807325368'
  UNION ALL SELECT 'google-ads-RCRU', '8766638384'
  UNION ALL SELECT 'google-ads-VozJ', '6604892813'
  UNION ALL SELECT 'google-ads-cFrH', '9359858042'
  UNION ALL SELECT 'google-ads-URNQ', '3310579239'
  UNION ALL SELECT 'google-ads-mEnk', '8837950560'
  UNION ALL SELECT 'google-ads-A1kM', '9382044362'
  UNION ALL SELECT 'google-ads-rYKp', '9739407801'
  UNION ALL SELECT 'google-ads-C4Aq', '4032355891'
  UNION ALL SELECT 'google-ads-PnyV', '9580379854'
  UNION ALL SELECT 'google-ads-0B2k', '6666958748'
  UNION ALL SELECT 'google-ads-GZ55', '8904126755'
  UNION ALL SELECT 'google-ads-802k', '5921711317'
  UNION ALL SELECT 'google-ads-Jl1R', '1395906460'
  UNION ALL SELECT 'google-ads-x20o', '9870901843'
  UNION ALL SELECT 'google-ads-ZcMG', '3397886954'
  UNION ALL SELECT 'google-ads-wypN', '7381920209'
  UNION ALL SELECT 'google-ads-AMd2', '2819044460'
  UNION ALL SELECT 'google-ads-rSav', '2871944411'
  UNION ALL SELECT 'google-ads-jT4J', '2404777291'
  UNION ALL SELECT 'google-ads-ABUl', '6167711319'
  UNION ALL SELECT 'google-ads-R4be', '7494330271'
  UNION ALL SELECT 'google-ads-fwxw', '8887022182'
  UNION ALL SELECT 'google-ads-dMx7', '2494093513'
  UNION ALL SELECT 'google-ads-x36N', '3152479850'
  UNION ALL SELECT 'google-ads-WxA8', '3746529772'
  UNION ALL SELECT 'google-ads-Llsu', '5210673200'
  UNION ALL SELECT 'google-ads-NP4k', '8740065197'
  UNION ALL SELECT 'google-ads-PdSr', '7280103768'
  UNION ALL SELECT 'google-ads-3eFc', '3083428472'
  UNION ALL SELECT 'google-ads-mvUx', '6451568997'
  UNION ALL SELECT 'google-ads-hBlk', '1911984217'
)
SELECT
  c.id_conta,
  CAST(b.id AS STRING)                              AS id_acao,
  NULLIF(TRIM(b.name), '')                          AS nome,
  b.status                                          AS status,
  b.type                                            AS tipo,
  b.category                                        AS categoria,
  b.origin                                          AS origem,
  SAFE_CAST(LOWER(b.primary_for_goal) AS BOOL)      AS is_primaria_para_meta,
  SAFE_CAST(LOWER(b.include_in_conversions_metric) AS BOOL) AS is_na_metrica_conversoes,
  CURRENT_TIMESTAMP()                               AS _extraido_at,
  b._fonte,
  b._payload_hash
FROM bruto b LEFT JOIN conta_por_fonte c USING (_fonte)
