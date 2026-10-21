-- trs_google_ads__palavra_chave
-- Trusted de PALAVRA-CHAVE do Google Ads, consolidada nas 42 fontes (as 39 originais mais as 3 da Unipar).
-- Grao: id_campanha, id_grupo_anuncio, id_criterio, data. Origem: keyword_performance em cada camada de fonte.
-- Medido em 2026-10-06 antes de publicar: 197.037 linhas, 197.037 chaves distintas, 40 das 42 fontes com dado,
-- 2025-01-01 a 2026-10-05, esquema identico nas 42 (a uniao x.* executou sem erro).
-- Eram 197 mil linhas lidas por NINGUEM: o stream keyword_performance estava habilitado nas 42 fontes e nao tinha Trusted.
--
-- REGRAS
-- 1. TABELA DE BREAKDOWN, SEM IDENTIFICADOR DE CONTA: o id_conta e injetado da CTE `conta_por_fonte` (mesmo mapa das
--    outras trusted de segmentacao). E o unico lugar a corrigir se uma fonte for repontada.
-- 2. NAO FECHA INVESTIMENTO. Palavra-chave so existe em campanha de pesquisa; PERFORMANCE_MAX e display nao tem. Serve
--    para ler desempenho por termo comprado, nunca para totalizar verba (o total e a rfn_midia__desempenho_diario).
-- 3. quality_score NULL e AUSENCIA DE NOTA (o Google nao pontua palavra sem volume), nao zero: 42% das linhas na conta de referencia.
-- 4. Derivadas passam como a plataforma entrega: ctr_plataforma, cpc_medio_micros_plataforma (em MICROS: medido
--    average_cpc = cost_micros/clicks, razao 1) e os dois percentuais de topo. CTR pode passar de 1 (clique > impressao, quirk do Google).
-- 5. is_negativa: a origem traz o flag; nenhuma linha de desempenho e negativa hoje, mas a coluna fica.
-- MOEDA: mistura BRL e USD (Move Rental Cars). Resolver por id_conta contra trs_google_ads__conta e agrupar por moeda.
-- FORMA COMPACTA: o * depende de esquema identico entre as contas; ao somar fonte nova rodar a uniao sob LIMIT 0 antes.
-- _payload_hash e o MD5 da linha CRUA (alias x), calculado em `bruto`.
WITH bruto AS (
  SELECT 'google-ads-cwt3' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_acesso_saude_google_ads`.`google_ads_acesso_saudekeyword_performance` x UNION ALL
  SELECT 'google-ads-DzVL' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_ola_casa_nova_g_ads`.`google_ads_ola_casa_novakeyword_performance` x UNION ALL
  SELECT 'google-ads-vfUV' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_move_rental_cars_g_ads`.`google_ads_move_rentalkeyword_performance` x UNION ALL
  SELECT 'google-ads-QuKh' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_don_watches_conta_1_g_ads`.`google_ads_don_watches_2keyword_performance` x UNION ALL
  SELECT 'google-ads-vE2C' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_don_watches_conta_2`.`google_ads_watches_2keyword_performance` x UNION ALL
  SELECT 'google-ads-PmFB' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_varejo`.`google_ads_braga_varejokeyword_performance` x UNION ALL
  SELECT 'google-ads-5J1y' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_yamaha_consorcios_2`.`google_ads_yamaha_2keyword_performance` x UNION ALL
  SELECT 'google-ads-Pk69' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_yamaha_consorcios`.`google_ads_braga_yamaha_consorckeyword_performance` x UNION ALL
  SELECT 'google-ads-SyTu' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_royal_enfield`.`google_ads_royal_enfieldkeyword_performance` x UNION ALL
  SELECT 'google-ads-6Z2v' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_acessorios`.`google_ads_braga_acessorioskeyword_performance` x UNION ALL
  SELECT 'google-ads-PsES' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_veiculos`.`google_ads_pos_vendaskeyword_performance` x UNION ALL
  SELECT 'google-ads-RCRU' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_motors_mini`.`google_ads_braga_minikeyword_performance` x UNION ALL
  SELECT 'google-ads-VozJ' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_motorrad`.`google_ads_braga_motorradkeyword_performance` x UNION ALL
  SELECT 'google-ads-cFrH' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_motors_bmw_g_ads`.`google_ads_braga_bmwkeyword_performance` x UNION ALL
  SELECT 'google-ads-URNQ' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_dmelo`.`google_ads_dmelokeyword_performance` x UNION ALL
  SELECT 'google-ads-mEnk' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_caa`.`google_ads_caa_tintaskeyword_performance` x UNION ALL
  SELECT 'google-ads-A1kM' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_caa_aluminio`.`google_ads_caa_aluminiokeyword_performance` x UNION ALL
  SELECT 'google-ads-rYKp' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_rodrix_g_ads`.`google_ads_rodrix_motoskeyword_performance` x UNION ALL
  SELECT 'google-ads-C4Aq' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_deb_transportadora_g_ads`.`google_ads_deb_transportadorakeyword_performance` x UNION ALL
  SELECT 'google-ads-PnyV' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_rei_das_mangueiras_g_ads`.`google_ads_rei_das_mangueiraskeyword_performance` x UNION ALL
  SELECT 'google-ads-0B2k' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pneu_forte_distribuidora`.`google_ads_pneu_forte_distkeyword_performance` x UNION ALL
  SELECT 'google-ads-GZ55' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_millenium_g_ads`.`google_ads_milleniumkeyword_performance` x UNION ALL
  SELECT 'google-ads-802k' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pneu_express`.`google_ads_pneu_expresskeyword_performance` x UNION ALL
  SELECT 'google-ads-Jl1R' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_smile_pneus`.`google_ads_smile_pneuskeyword_performance` x UNION ALL
  SELECT 'google-ads-x20o' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_steel_port_g_ads`.`google_ads_steel_portkeyword_performance` x UNION ALL
  SELECT 'google-ads-ZcMG' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_amz_geradores_g_ads`.`google_ads_amz_geradoreskeyword_performance` x UNION ALL
  SELECT 'google-ads-wypN' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_dr_cabral_conta_1`.`google_ads_dr_cabral_1keyword_performance` x UNION ALL
  SELECT 'google-ads-AMd2' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_santo_remedio_g_ads`.`google_ads_santo_remediokeyword_performance` x UNION ALL
  SELECT 'google-ads-rSav' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_hospital_santa_julia_g_ads`.`google_ads_h_santa_juliakeyword_performance` x UNION ALL
  SELECT 'google-ads-jT4J' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_constroi_incorporadora_g_ads`.`google_ads_constroikeyword_performance` x UNION ALL
  SELECT 'google-ads-ABUl' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_doctor_mais_g_ads`.`google_ads_doctor_maiskeyword_performance` x UNION ALL
  SELECT 'google-ads-R4be' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_colmeia`.`google_ads_colmeiakeyword_performance` x UNION ALL
  SELECT 'google-ads-fwxw' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_amazoncopy_g_ads`.`google_ads_amazoncopykeyword_performance` x UNION ALL
  SELECT 'google-ads-dMx7' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_bigazine_g_ads`.`google_ads_bigazinekeyword_performance` x UNION ALL
  SELECT 'google-ads-x36N' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_arena_tintas_g_ads`.`google_ads_arena_tintaskeyword_performance` x UNION ALL
  SELECT 'google-ads-WxA8' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_ba_eletrica_g_ads`.`google_ads_ba_eletricakeyword_performance` x UNION ALL
  SELECT 'google-ads-Llsu' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pmz_grupo_ecomm`.`google_ads_pmz_ecommkeyword_performance` x UNION ALL
  SELECT 'google-ads-NP4k' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pmz_loja`.`google_pmz_grupo_lojakeyword_performance` x UNION ALL
  SELECT 'google-ads-PdSr' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pmz_escola_de_mecanicos`.`google_ads_pmz_escola_mecanicoskeyword_performance` x UNION ALL
  SELECT 'google-ads-3eFc' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_unipar_boa_vista`.`google_ads_unipar_boa_vistakeyword_performance` x UNION ALL
  SELECT 'google-ads-mvUx' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_unipar_neo_vila`.`google_ads_unipar_neo_vilakeyword_performance` x UNION ALL
  SELECT 'google-ads-hBlk' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_unipar_torres`.`google_ads_unipar_torreskeyword_performance` x
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
),
uniao AS (
  SELECT b._fonte, c.id_conta,
    CAST(b.campaign_id AS STRING) AS id_campanha, b.campaign_name, b.campaign_status,
    CAST(b.ad_group_id AS STRING) AS id_grupo_anuncio, b.ad_group_name AS grupo_anuncio,
    CAST(b.criterion_id AS STRING) AS id_criterio, b.keyword_text, b.keyword_match_type,
    b.ad_group_criterion_status, b.ad_group_criterion_negative, b.quality_score, b.date,
    b.metrics_cost_micros, b.metrics_impressions, b.metrics_clicks, b.metrics_interactions,
    b.metrics_conversions, b.metrics_all_conversions, b.metrics_conversions_value, b.metrics_all_conversions_value,
    b.metrics_view_through_conversions, b.metrics_cross_device_conversions,
    b.metrics_ctr, b.metrics_average_cpc, b.metrics_absolute_top_impression_percentage, b.metrics_top_impression_percentage,
    b._payload_hash
  FROM bruto b LEFT JOIN conta_por_fonte c USING (_fonte)
)

SELECT
  u.id_conta,
  u.id_campanha,
  NULLIF(TRIM(u.campaign_name), '')          AS campanha,
  u.campaign_status                          AS status_campanha,
  u.id_grupo_anuncio,
  u.grupo_anuncio,
  u.id_criterio,
  u.keyword_text                             AS palavra_chave,
  u.keyword_match_type                       AS tipo_correspondencia,
  u.ad_group_criterion_status                AS status_palavra_chave,
  u.ad_group_criterion_negative              AS is_negativa,
  u.quality_score                            AS nivel_qualidade,
  DATE(u.date)                               AS data,
  DATE_TRUNC(DATE(u.date), MONTH)            AS mes_referencia,

  u.metrics_cost_micros                      AS investimento_micros,
  u.metrics_impressions                      AS impressoes,
  u.metrics_clicks                           AS cliques,
  u.metrics_interactions                     AS interacoes,
  u.metrics_conversions                      AS conversoes,
  u.metrics_all_conversions                  AS todas_conversoes,
  u.metrics_conversions_value                AS valor_conversoes,
  u.metrics_all_conversions_value            AS valor_todas_conversoes,
  u.metrics_view_through_conversions         AS conversoes_view_through,
  u.metrics_cross_device_conversions         AS conversoes_entre_dispositivos,
  ROUND(u.metrics_cost_micros / 1000000, 2)  AS investimento,

  u.metrics_ctr                              AS ctr_plataforma,
  u.metrics_average_cpc                      AS cpc_medio_micros_plataforma,
  u.metrics_absolute_top_impression_percentage AS pct_impressao_topo_absoluto_plataforma,
  u.metrics_top_impression_percentage        AS pct_impressao_topo_plataforma,

  CURRENT_TIMESTAMP()                        AS _extraido_at,
  u._fonte,
  u._payload_hash
FROM uniao u
