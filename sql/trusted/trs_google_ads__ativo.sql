-- trs_google_ads__ativo
-- Trusted do CADASTRO DE ATIVOS (assets) do Google Ads: imagens, textos, videos do YouTube, chamadas, sitelinks, callouts. 42 fontes.
-- Grao: (id_conta, id_ativo). Fotografia do estado atual; origem: assets. id_conta sai do resource name (customers/<conta>/assets/<id>).
-- O ativo e a PECA reutilizavel; o vinculo ativo-campanha/anuncio nao existe neste stream. FORMA COMPACTA: o * depende de esquema identico.
WITH bruto AS (
  SELECT 'google-ads-cwt3' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_acesso_saude_google_ads`.`google_ads_acesso_saudeassets` x UNION ALL
  SELECT 'google-ads-DzVL' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_ola_casa_nova_g_ads`.`google_ads_ola_casa_novaassets` x UNION ALL
  SELECT 'google-ads-vfUV' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_move_rental_cars_g_ads`.`google_ads_move_rentalassets` x UNION ALL
  SELECT 'google-ads-QuKh' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_don_watches_conta_1_g_ads`.`google_ads_don_watches_2assets` x UNION ALL
  SELECT 'google-ads-vE2C' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_don_watches_conta_2`.`google_ads_watches_2assets` x UNION ALL
  SELECT 'google-ads-PmFB' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_varejo`.`google_ads_braga_varejoassets` x UNION ALL
  SELECT 'google-ads-5J1y' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_yamaha_consorcios_2`.`google_ads_yamaha_2assets` x UNION ALL
  SELECT 'google-ads-Pk69' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_yamaha_consorcios`.`google_ads_braga_yamaha_consorcassets` x UNION ALL
  SELECT 'google-ads-SyTu' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_royal_enfield`.`google_ads_royal_enfieldassets` x UNION ALL
  SELECT 'google-ads-6Z2v' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_acessorios`.`google_ads_braga_acessoriosassets` x UNION ALL
  SELECT 'google-ads-PsES' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_veiculos`.`google_ads_pos_vendasassets` x UNION ALL
  SELECT 'google-ads-RCRU' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_motors_mini`.`google_ads_braga_miniassets` x UNION ALL
  SELECT 'google-ads-VozJ' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_motorrad`.`google_ads_braga_motorradassets` x UNION ALL
  SELECT 'google-ads-cFrH' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_braga_motors_bmw_g_ads`.`google_ads_braga_bmwassets` x UNION ALL
  SELECT 'google-ads-URNQ' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_dmelo`.`google_ads_dmeloassets` x UNION ALL
  SELECT 'google-ads-mEnk' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_caa`.`google_ads_caa_tintasassets` x UNION ALL
  SELECT 'google-ads-A1kM' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_caa_aluminio`.`google_ads_caa_aluminioassets` x UNION ALL
  SELECT 'google-ads-rYKp' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_rodrix_g_ads`.`google_ads_rodrix_motosassets` x UNION ALL
  SELECT 'google-ads-C4Aq' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_deb_transportadora_g_ads`.`google_ads_deb_transportadoraassets` x UNION ALL
  SELECT 'google-ads-PnyV' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_rei_das_mangueiras_g_ads`.`google_ads_rei_das_mangueirasassets` x UNION ALL
  SELECT 'google-ads-0B2k' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pneu_forte_distribuidora`.`google_ads_pneu_forte_distassets` x UNION ALL
  SELECT 'google-ads-GZ55' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_millenium_g_ads`.`google_ads_milleniumassets` x UNION ALL
  SELECT 'google-ads-802k' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pneu_express`.`google_ads_pneu_expressassets` x UNION ALL
  SELECT 'google-ads-Jl1R' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_smile_pneus`.`google_ads_smile_pneusassets` x UNION ALL
  SELECT 'google-ads-x20o' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_steel_port_g_ads`.`google_ads_steel_portassets` x UNION ALL
  SELECT 'google-ads-ZcMG' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_amz_geradores_g_ads`.`google_ads_amz_geradoresassets` x UNION ALL
  SELECT 'google-ads-wypN' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_dr_cabral_conta_1`.`google_ads_dr_cabral_1assets` x UNION ALL
  SELECT 'google-ads-AMd2' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_santo_remedio_g_ads`.`google_ads_santo_remedioassets` x UNION ALL
  SELECT 'google-ads-rSav' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_hospital_santa_julia_g_ads`.`google_ads_h_santa_juliaassets` x UNION ALL
  SELECT 'google-ads-jT4J' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_constroi_incorporadora_g_ads`.`google_ads_constroiassets` x UNION ALL
  SELECT 'google-ads-ABUl' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_doctor_mais_g_ads`.`google_ads_doctor_maisassets` x UNION ALL
  SELECT 'google-ads-R4be' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_colmeia`.`google_ads_colmeiaassets` x UNION ALL
  SELECT 'google-ads-fwxw' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_amazoncopy_g_ads`.`google_ads_amazoncopyassets` x UNION ALL
  SELECT 'google-ads-dMx7' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_bigazine_g_ads`.`google_ads_bigazineassets` x UNION ALL
  SELECT 'google-ads-x36N' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_arena_tintas_g_ads`.`google_ads_arena_tintasassets` x UNION ALL
  SELECT 'google-ads-WxA8' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_ba_eletrica_g_ads`.`google_ads_ba_eletricaassets` x UNION ALL
  SELECT 'google-ads-Llsu' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pmz_grupo_ecomm`.`google_ads_pmz_ecommassets` x UNION ALL
  SELECT 'google-ads-NP4k' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pmz_loja`.`google_pmz_grupo_lojaassets` x UNION ALL
  SELECT 'google-ads-PdSr' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_pmz_escola_de_mecanicos`.`google_ads_pmz_escola_mecanicosassets` x UNION ALL
  SELECT 'google-ads-3eFc' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_unipar_boa_vista`.`google_ads_unipar_boa_vistaassets` x UNION ALL
  SELECT 'google-ads-mvUx' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_unipar_neo_vila`.`google_ads_unipar_neo_vilaassets` x UNION ALL
  SELECT 'google-ads-hBlk' AS _fonte, TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash, x.* FROM `vanguardamartech_unipar_torres`.`google_ads_unipar_torresassets` x
)
SELECT
  REGEXP_EXTRACT(b.resource_name, r'customers/(\d+)/')   AS id_conta,
  CAST(b.id AS STRING)                                  AS id_ativo,
  b.type                                                AS tipo,
  b.source                                              AS origem,
  NULLIF(TRIM(b.name), '')                              AS nome,
  NULLIF(TRIM(b.text_asset.text), '')                   AS texto,
  b.image_asset.full_size.url                           AS imagem_url,
  b.image_asset.full_size.width_pixels                  AS imagem_largura_px,
  b.image_asset.full_size.height_pixels                 AS imagem_altura_px,
  b.image_asset.file_size                               AS imagem_bytes,
  b.image_asset.mime_type                               AS imagem_mime,
  b.youtube_video_asset.youtube_video_id                AS youtube_id,
  NULLIF(TRIM(b.youtube_video_asset.youtube_video_title), '') AS youtube_titulo,
  CURRENT_TIMESTAMP()                                   AS _extraido_at,
  b._fonte,
  b._payload_hash
FROM bruto b
