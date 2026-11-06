-- trs_google_ads__segmento_faixa_etaria
-- PUBLICADA em 2026-09-08 como query-HAB1, camada Trusted, folder google_ads.
-- Gatilho: evento na fonte google-ads-cwt3 (regra any) -- a fonte de cron mais
-- tarde das 39, as 12:43 America/Manaus, entao roda uma vez por terca depois
-- de todo o ciclo. Mesmo padrao da query-tL4g e da query-zF8L.
-- Trusted de segmentacao do Google Ads, consolidada nas 42 fontes -- as 39 originais
-- mais as 3 do Grupo Unipar (google-ads-3eFc, mvUx, hBlk), somadas em 18/09/2026.
-- Grao: id_campanha, id_grupo_anuncio, faixa_etaria, data.
-- Origem: age_range_performance em cada camada de fonte.
--
-- AS TABELAS DE BREAKDOWN NAO TEM IDENTIFICADOR DE CONTA. Nem account_id nem
-- resource_name. O id_conta vem da CTE `conta_por_fonte`, do mapeamento fonte ->
-- customer_id validado contra a API do Google Ads em 27/08/2026 (as 3 da Unipar em
-- 17/09/2026). Se uma fonte for repontada para outra conta, e essa CTE que passa a
-- mentir -- e o unico lugar a corrigir.
--
-- LIMITACAO MEDIDA -- NAO CONTORNE. Esta tabela NAO fecha o investimento total.
-- PERFORMANCE_MAX nao publica breakdown demografico. Medido em 2026-09-08 nas 36
-- contas com dado: cobertura = 100% - fatia de PMax, exata. No agregado, cobre
-- R$ 1.073.656,85 dos R$ 1.342.354,13 de verba BRL (80,0%) mais US$ 18.247,66
-- dos US$ 19.600,06 da unica conta em USD (93,1%). A verba nao-PMax e
-- R$ 1.072.265,93 em BRL e o delta de R$ 1.390,92 e o dia 03/09 parcial --
-- no USD o delta e ZERO, o que confirma a causa.
-- Pior conta: PMZ ESCOLA DE MECANICOS, 29,8% de cobertura (70,2% em PMax).
-- Nas 19 contas sem PMax a cobertura e 100%.
-- Serve para composicao relativa dentro da verba nao-PMax. Verba se soma na
-- rfn_midia__desempenho_diario. Detalhe: docs/nekt/breakdowns-cobertura-2026-09-08.md
-- FORMA COMPACTA desde 2026-09-18. Antes eram 39 blocos repetindo as colunas E o
-- literal de id_conta, 32 mil caracteres. Agora a uniao vem crua em `bruto`, o mapa
-- fonte -> id_conta virou UMA CTE conferivel (`conta_por_fonte`) e as colunas sao
-- nomeadas UMA vez em `uniao`.
-- O PRECO: o `*` depende de esquema identico entre as contas - conferido em 18/09/2026
-- nas 39 tabelas age_range_performance, em dois lotes sobrepostos, e nas 3
-- da Unipar contra a tabela de referencia no mesmo dia. Se uma conta divergir,
-- a uniao INTEIRA quebra, nao so aquela conta. Ao somar fonte nova, rodar
-- `SELECT f FROM (<uniao>) LIMIT 0` antes de publicar: falha no plano, sem custo.
-- O _payload_hash continua sendo MD5 da linha CRUA (alias x), calculado dentro de
-- `bruto` antes de qualquer coluna nova - por isso ele nao muda com a refatoracao.
WITH bruto AS (
  SELECT 'google-ads-cwt3' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_acesso_saude_google_ads`.`google_ads_acesso_saudeage_range_performance` x
  UNION ALL SELECT 'google-ads-DzVL' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_ola_casa_nova_g_ads`.`google_ads_ola_casa_novaage_range_performance` x
  UNION ALL SELECT 'google-ads-vfUV' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_move_rental_cars_g_ads`.`google_ads_move_rentalage_range_performance` x
  UNION ALL SELECT 'google-ads-QuKh' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_don_watches_conta_1_g_ads`.`google_ads_don_watches_2age_range_performance` x
  UNION ALL SELECT 'google-ads-vE2C' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_don_watches_conta_2`.`google_ads_watches_2age_range_performance` x
  UNION ALL SELECT 'google-ads-PmFB' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_varejo`.`google_ads_braga_varejoage_range_performance` x
  UNION ALL SELECT 'google-ads-5J1y' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_yamaha_consorcios_2`.`google_ads_yamaha_2age_range_performance` x
  UNION ALL SELECT 'google-ads-Pk69' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_yamaha_consorcios`.`google_ads_braga_yamaha_consorcage_range_performance` x
  UNION ALL SELECT 'google-ads-SyTu' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_royal_enfield`.`google_ads_royal_enfieldage_range_performance` x
  UNION ALL SELECT 'google-ads-6Z2v' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_acessorios`.`google_ads_braga_acessoriosage_range_performance` x
  UNION ALL SELECT 'google-ads-PsES' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_veiculos`.`google_ads_pos_vendasage_range_performance` x
  UNION ALL SELECT 'google-ads-RCRU' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_motors_mini`.`google_ads_braga_miniage_range_performance` x
  UNION ALL SELECT 'google-ads-VozJ' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_motorrad`.`google_ads_braga_motorradage_range_performance` x
  UNION ALL SELECT 'google-ads-cFrH' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_motors_bmw_g_ads`.`google_ads_braga_bmwage_range_performance` x
  UNION ALL SELECT 'google-ads-URNQ' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_dmelo`.`google_ads_dmeloage_range_performance` x
  UNION ALL SELECT 'google-ads-mEnk' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_caa`.`google_ads_caa_tintasage_range_performance` x
  UNION ALL SELECT 'google-ads-A1kM' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_caa_aluminio`.`google_ads_caa_aluminioage_range_performance` x
  UNION ALL SELECT 'google-ads-rYKp' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_rodrix_g_ads`.`google_ads_rodrix_motosage_range_performance` x
  UNION ALL SELECT 'google-ads-C4Aq' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_deb_transportadora_g_ads`.`google_ads_deb_transportadoraage_range_performance` x
  UNION ALL SELECT 'google-ads-PnyV' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_rei_das_mangueiras_g_ads`.`google_ads_rei_das_mangueirasage_range_performance` x
  UNION ALL SELECT 'google-ads-0B2k' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pneu_forte_distribuidora`.`google_ads_pneu_forte_distage_range_performance` x
  UNION ALL SELECT 'google-ads-GZ55' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_millenium_g_ads`.`google_ads_milleniumage_range_performance` x
  UNION ALL SELECT 'google-ads-802k' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pneu_express`.`google_ads_pneu_expressage_range_performance` x
  UNION ALL SELECT 'google-ads-Jl1R' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_smile_pneus`.`google_ads_smile_pneusage_range_performance` x
  UNION ALL SELECT 'google-ads-x20o' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_steel_port_g_ads`.`google_ads_steel_portage_range_performance` x
  UNION ALL SELECT 'google-ads-ZcMG' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_amz_geradores_g_ads`.`google_ads_amz_geradoresage_range_performance` x
  UNION ALL SELECT 'google-ads-wypN' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_dr_cabral_conta_1`.`google_ads_dr_cabral_1age_range_performance` x
  UNION ALL SELECT 'google-ads-AMd2' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_santo_remedio_g_ads`.`google_ads_santo_remedioage_range_performance` x
  UNION ALL SELECT 'google-ads-rSav' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_hospital_santa_julia_g_ads`.`google_ads_h_santa_juliaage_range_performance` x
  UNION ALL SELECT 'google-ads-jT4J' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_constroi_incorporadora_g_ads`.`google_ads_constroiage_range_performance` x
  UNION ALL SELECT 'google-ads-ABUl' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_doctor_mais_g_ads`.`google_ads_doctor_maisage_range_performance` x
  UNION ALL SELECT 'google-ads-R4be' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_colmeia`.`google_ads_colmeiaage_range_performance` x
  UNION ALL SELECT 'google-ads-fwxw' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_amazoncopy_g_ads`.`google_ads_amazoncopyage_range_performance` x
  UNION ALL SELECT 'google-ads-dMx7' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_bigazine_g_ads`.`google_ads_bigazineage_range_performance` x
  UNION ALL SELECT 'google-ads-x36N' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_arena_tintas_g_ads`.`google_ads_arena_tintasage_range_performance` x
  UNION ALL SELECT 'google-ads-WxA8' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_ba_eletrica_g_ads`.`google_ads_ba_eletricaage_range_performance` x
  UNION ALL SELECT 'google-ads-Llsu' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pmz_grupo_ecomm`.`google_ads_pmz_ecommage_range_performance` x
  UNION ALL SELECT 'google-ads-NP4k' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pmz_loja`.`google_pmz_grupo_lojaage_range_performance` x
  UNION ALL SELECT 'google-ads-PdSr' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pmz_escola_de_mecanicos`.`google_ads_pmz_escola_mecanicosage_range_performance` x
  UNION ALL SELECT 'google-ads-3eFc' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_unipar_boa_vista`.`google_ads_unipar_boa_vistaage_range_performance` x
  UNION ALL SELECT 'google-ads-mvUx' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_unipar_neo_vila`.`google_ads_unipar_neo_vilaage_range_performance` x
  UNION ALL SELECT 'google-ads-hBlk' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_unipar_torres`.`google_ads_unipar_torresage_range_performance` x
),
-- Mapa fonte -> customer_id, validado contra a API do Google Ads em 27/08/2026.
-- As tabelas de breakdown nao trazem account_id nem resource_name, entao o id_conta
-- PRECISA ser injetado. Antes estava escrito 39 vezes dentro dos blocos; agora esta
-- aqui, num lugar so. Se uma fonte for repontada para outra conta, e esta CTE que
-- passa a mentir - e o unico lugar a corrigir.
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
  SELECT
    b._fonte,
    c.id_conta,
    CAST(b.campaign_id AS STRING) AS id_campanha,
    b.campaign_name,
    b.campaign_status,
    CAST(b.ad_group_id AS STRING) AS id_grupo_anuncio,
    b.ad_group_name AS grupo_anuncio,
    b.age_range AS faixa_etaria,
    b.date,
    b.metrics_cost_micros,
    b.metrics_impressions,
    b.metrics_clicks,
    b.metrics_interactions,
    b.metrics_conversions,
    b.metrics_all_conversions,
    b.metrics_conversions_value,
    b.metrics_all_conversions_value,
    b.metrics_view_through_conversions,
    b.metrics_cross_device_conversions,
    b._payload_hash
  FROM bruto b
  LEFT JOIN conta_por_fonte c USING (_fonte)
)
SELECT
  u.id_conta,
  u.id_campanha,
  NULLIF(TRIM(u.campaign_name), '')          AS campanha,
  u.campaign_status                          AS status_campanha,
  u.id_grupo_anuncio,
  u.grupo_anuncio,
  u.faixa_etaria,
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

  CURRENT_TIMESTAMP()                        AS _extraido_at,
  u._fonte,
  u._payload_hash
FROM uniao u
