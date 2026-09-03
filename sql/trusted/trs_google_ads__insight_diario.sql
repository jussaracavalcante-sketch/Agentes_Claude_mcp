WITH conta_raw AS (
  SELECT 'google-ads-cwt3' fonte,id,resource_name FROM `vanguardamartech_acesso_saude_google_ads`.`google_ads_acesso_saudecampaigns`
  UNION ALL
  SELECT 'google-ads-DzVL' fonte,id,resource_name FROM `vanguardamartech_ola_casa_nova_g_ads`.`google_ads_ola_casa_novacampaigns`
  UNION ALL
  SELECT 'google-ads-vfUV' fonte,id,resource_name FROM `vanguardamartech_move_rental_cars_g_ads`.`google_ads_move_rentalcampaigns`
  UNION ALL
  SELECT 'google-ads-QuKh' fonte,id,resource_name FROM `vanguardamartech_don_watches_conta_1_g_ads`.`google_ads_don_watches_2campaigns`
  UNION ALL
  SELECT 'google-ads-vE2C' fonte,id,resource_name FROM `vanguardamartech_don_watches_conta_2`.`google_ads_watches_2campaigns`
  UNION ALL
  SELECT 'google-ads-PmFB' fonte,id,resource_name FROM `vanguardamartech_braga_varejo`.`google_ads_braga_varejocampaigns`
  UNION ALL
  SELECT 'google-ads-5J1y' fonte,id,resource_name FROM `vanguardamartech_braga_yamaha_consorcios_2`.`google_ads_yamaha_2campaigns`
  UNION ALL
  SELECT 'google-ads-Pk69' fonte,id,resource_name FROM `vanguardamartech_braga_yamaha_consorcios`.`google_ads_braga_yamaha_consorccampaigns`
  UNION ALL
  SELECT 'google-ads-SyTu' fonte,id,resource_name FROM `vanguardamartech_royal_enfield`.`google_ads_royal_enfieldcampaigns`
  UNION ALL
  SELECT 'google-ads-6Z2v' fonte,id,resource_name FROM `vanguardamartech_braga_acessorios`.`google_ads_braga_acessorioscampaigns`
  UNION ALL
  SELECT 'google-ads-PsES' fonte,id,resource_name FROM `vanguardamartech_braga_veiculos`.`google_ads_pos_vendascampaigns`
  UNION ALL
  SELECT 'google-ads-RCRU' fonte,id,resource_name FROM `vanguardamartech_braga_motors_mini`.`google_ads_braga_minicampaigns`
  UNION ALL
  SELECT 'google-ads-VozJ' fonte,id,resource_name FROM `vanguardamartech_braga_motorrad`.`google_ads_braga_motorradcampaigns`
  UNION ALL
  SELECT 'google-ads-cFrH' fonte,id,resource_name FROM `vanguardamartech_braga_motors_bmw_g_ads`.`google_ads_braga_bmwcampaigns`
  UNION ALL
  SELECT 'google-ads-URNQ' fonte,id,resource_name FROM `vanguardamartech_dmelo`.`google_ads_dmelocampaigns`
  UNION ALL
  SELECT 'google-ads-mEnk' fonte,id,resource_name FROM `vanguardamartech_caa`.`google_ads_caa_tintascampaigns`
  UNION ALL
  SELECT 'google-ads-A1kM' fonte,id,resource_name FROM `vanguardamartech_caa_aluminio`.`google_ads_caa_aluminiocampaigns`
  UNION ALL
  SELECT 'google-ads-rYKp' fonte,id,resource_name FROM `vanguardamartech_rodrix_g_ads`.`google_ads_rodrix_motoscampaigns`
  UNION ALL
  SELECT 'google-ads-C4Aq' fonte,id,resource_name FROM `vanguardamartech_deb_transportadora_g_ads`.`google_ads_deb_transportadoracampaigns`
  UNION ALL
  SELECT 'google-ads-PnyV' fonte,id,resource_name FROM `vanguardamartech_rei_das_mangueiras_g_ads`.`google_ads_rei_das_mangueirascampaigns`
  UNION ALL
  SELECT 'google-ads-0B2k' fonte,id,resource_name FROM `vanguardamartech_pneu_forte_distribuidora`.`google_ads_pneu_forte_distcampaigns`
  UNION ALL
  SELECT 'google-ads-GZ55' fonte,id,resource_name FROM `vanguardamartech_millenium_g_ads`.`google_ads_milleniumcampaigns`
  UNION ALL
  SELECT 'google-ads-802k' fonte,id,resource_name FROM `vanguardamartech_pneu_express`.`google_ads_pneu_expresscampaigns`
  UNION ALL
  SELECT 'google-ads-Jl1R' fonte,id,resource_name FROM `vanguardamartech_smile_pneus`.`google_ads_smile_pneuscampaigns`
  UNION ALL
  SELECT 'google-ads-x20o' fonte,id,resource_name FROM `vanguardamartech_steel_port_g_ads`.`google_ads_steel_portcampaigns`
  UNION ALL
  SELECT 'google-ads-ZcMG' fonte,id,resource_name FROM `vanguardamartech_amz_geradores_g_ads`.`google_ads_amz_geradorescampaigns`
  UNION ALL
  SELECT 'google-ads-wypN' fonte,id,resource_name FROM `vanguardamartech_dr_cabral_conta_1`.`google_ads_dr_cabral_1campaigns`
  UNION ALL
  SELECT 'google-ads-AMd2' fonte,id,resource_name FROM `vanguardamartech_santo_remedio_g_ads`.`google_ads_santo_remediocampaigns`
  UNION ALL
  SELECT 'google-ads-rSav' fonte,id,resource_name FROM `vanguardamartech_hospital_santa_julia_g_ads`.`google_ads_h_santa_juliacampaigns`
  UNION ALL
  SELECT 'google-ads-jT4J' fonte,id,resource_name FROM `vanguardamartech_constroi_incorporadora_g_ads`.`google_ads_constroicampaigns`
  UNION ALL
  SELECT 'google-ads-ABUl' fonte,id,resource_name FROM `vanguardamartech_doctor_mais_g_ads`.`google_ads_doctor_maiscampaigns`
  UNION ALL
  SELECT 'google-ads-R4be' fonte,id,resource_name FROM `vanguardamartech_colmeia`.`google_ads_colmeiacampaigns`
  UNION ALL
  SELECT 'google-ads-fwxw' fonte,id,resource_name FROM `vanguardamartech_amazoncopy_g_ads`.`google_ads_amazoncopycampaigns`
  UNION ALL
  SELECT 'google-ads-dMx7' fonte,id,resource_name FROM `vanguardamartech_bigazine_g_ads`.`google_ads_bigazinecampaigns`
  UNION ALL
  SELECT 'google-ads-x36N' fonte,id,resource_name FROM `vanguardamartech_arena_tintas_g_ads`.`google_ads_arena_tintascampaigns`
  UNION ALL
  SELECT 'google-ads-WxA8' fonte,id,resource_name FROM `vanguardamartech_ba_eletrica_g_ads`.`google_ads_ba_eletricacampaigns`
  UNION ALL
  SELECT 'google-ads-Llsu' fonte,id,resource_name FROM `vanguardamartech_pmz_grupo_ecomm`.`google_ads_pmz_ecommcampaigns`
  UNION ALL
  SELECT 'google-ads-NP4k' fonte,id,resource_name FROM `vanguardamartech_pmz_loja`.`google_pmz_grupo_lojacampaigns`
  UNION ALL
  SELECT 'google-ads-PdSr' fonte,id,resource_name FROM `vanguardamartech_pmz_escola_de_mecanicos`.`google_ads_pmz_escola_mecanicoscampaigns`
),
conta AS (
  SELECT fonte,
         SAFE_CAST(id AS INT64) AS id_campanha,
         REGEXP_EXTRACT(resource_name, r'customers/([0-9]+)/') AS id_conta
  FROM conta_raw
),
anuncio AS (
  SELECT 'ANUNCIO' grao,'google-ads-cwt3' _fonte,SAFE_CAST(id AS STRING) id_origem,campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64) ad_group_id,NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),'') ad_group_name,SAFE_CAST(ad_group_ad_ad_id AS INT64) ad_group_ad_ad_id,NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),'') ad_group_ad_ad_name,date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_acesso_saude_google_ads`.`google_ads_acesso_saudead_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-DzVL',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_ola_casa_nova_g_ads`.`google_ads_ola_casa_novaad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-vfUV',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_move_rental_cars_g_ads`.`google_ads_move_rentalad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-QuKh',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_don_watches_conta_1_g_ads`.`google_ads_don_watches_2ad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-vE2C',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_don_watches_conta_2`.`google_ads_watches_2ad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-PmFB',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_varejo`.`google_ads_braga_varejoad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-5J1y',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_yamaha_consorcios_2`.`google_ads_yamaha_2ad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-Pk69',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_yamaha_consorcios`.`google_ads_braga_yamaha_consorcad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-SyTu',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_royal_enfield`.`google_ads_royal_enfieldad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-6Z2v',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_acessorios`.`google_ads_braga_acessoriosad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-PsES',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_veiculos`.`google_ads_pos_vendasad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-RCRU',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_motors_mini`.`google_ads_braga_miniad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-VozJ',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_motorrad`.`google_ads_braga_motorradad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-cFrH',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_motors_bmw_g_ads`.`google_ads_braga_bmwad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-URNQ',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_dmelo`.`google_ads_dmeload_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-mEnk',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_caa`.`google_ads_caa_tintasad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-A1kM',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_caa_aluminio`.`google_ads_caa_aluminioad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-rYKp',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_rodrix_g_ads`.`google_ads_rodrix_motosad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-C4Aq',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_deb_transportadora_g_ads`.`google_ads_deb_transportadoraad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-PnyV',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_rei_das_mangueiras_g_ads`.`google_ads_rei_das_mangueirasad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-0B2k',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_pneu_forte_distribuidora`.`google_ads_pneu_forte_distad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-GZ55',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_millenium_g_ads`.`google_ads_milleniumad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-802k',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_pneu_express`.`google_ads_pneu_expressad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-Jl1R',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_smile_pneus`.`google_ads_smile_pneusad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-x20o',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_steel_port_g_ads`.`google_ads_steel_portad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-ZcMG',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_amz_geradores_g_ads`.`google_ads_amz_geradoresad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-wypN',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_dr_cabral_conta_1`.`google_ads_dr_cabral_1ad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-AMd2',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_santo_remedio_g_ads`.`google_ads_santo_remedioad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-rSav',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_hospital_santa_julia_g_ads`.`google_ads_h_santa_juliaad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-jT4J',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_constroi_incorporadora_g_ads`.`google_ads_constroiad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-ABUl',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_doctor_mais_g_ads`.`google_ads_doctor_maisad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-R4be',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_colmeia`.`google_ads_colmeiaad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-fwxw',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_amazoncopy_g_ads`.`google_ads_amazoncopyad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-dMx7',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_bigazine_g_ads`.`google_ads_bigazinead_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-x36N',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_arena_tintas_g_ads`.`google_ads_arena_tintasad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-WxA8',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_ba_eletrica_g_ads`.`google_ads_ba_eletricaad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-Llsu',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_pmz_grupo_ecomm`.`google_ads_pmz_ecommad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-NP4k',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_pmz_loja`.`google_pmz_grupo_lojaad_performance`
  UNION ALL
  SELECT 'ANUNCIO','google-ads-PdSr',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,SAFE_CAST(ad_group_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_name AS STRING)),''),SAFE_CAST(ad_group_ad_ad_id AS INT64),NULLIF(TRIM(SAFE_CAST(ad_group_ad_ad_name AS STRING)),''),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_pmz_escola_de_mecanicos`.`google_ads_pmz_escola_mecanicosad_performance`
),
campanha AS (
  SELECT 'CAMPANHA' grao,'google-ads-cwt3' _fonte,SAFE_CAST(id AS STRING) id_origem,campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64) ad_group_id,CAST(NULL AS STRING) ad_group_name,CAST(NULL AS INT64) ad_group_ad_ad_id,CAST(NULL AS STRING) ad_group_ad_ad_name,date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_acesso_saude_google_ads`.`google_ads_acesso_saudecampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-DzVL',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_ola_casa_nova_g_ads`.`google_ads_ola_casa_novacampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-vfUV',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_move_rental_cars_g_ads`.`google_ads_move_rentalcampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-QuKh',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_don_watches_conta_1_g_ads`.`google_ads_don_watches_2campaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-vE2C',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_don_watches_conta_2`.`google_ads_watches_2campaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-PmFB',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_varejo`.`google_ads_braga_varejocampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-5J1y',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_yamaha_consorcios_2`.`google_ads_yamaha_2campaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-Pk69',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_yamaha_consorcios`.`google_ads_braga_yamaha_consorccampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-SyTu',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_royal_enfield`.`google_ads_royal_enfieldcampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-6Z2v',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_acessorios`.`google_ads_braga_acessorioscampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-PsES',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_veiculos`.`google_ads_pos_vendascampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-RCRU',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_motors_mini`.`google_ads_braga_minicampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-VozJ',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_motorrad`.`google_ads_braga_motorradcampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-cFrH',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_braga_motors_bmw_g_ads`.`google_ads_braga_bmwcampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-URNQ',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_dmelo`.`google_ads_dmelocampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-mEnk',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_caa`.`google_ads_caa_tintascampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-A1kM',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_caa_aluminio`.`google_ads_caa_aluminiocampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-rYKp',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_rodrix_g_ads`.`google_ads_rodrix_motoscampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-C4Aq',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_deb_transportadora_g_ads`.`google_ads_deb_transportadoracampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-PnyV',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_rei_das_mangueiras_g_ads`.`google_ads_rei_das_mangueirascampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-0B2k',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_pneu_forte_distribuidora`.`google_ads_pneu_forte_distcampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-GZ55',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_millenium_g_ads`.`google_ads_milleniumcampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-802k',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_pneu_express`.`google_ads_pneu_expresscampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-Jl1R',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_smile_pneus`.`google_ads_smile_pneuscampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-x20o',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_steel_port_g_ads`.`google_ads_steel_portcampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-ZcMG',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_amz_geradores_g_ads`.`google_ads_amz_geradorescampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-wypN',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_dr_cabral_conta_1`.`google_ads_dr_cabral_1campaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-AMd2',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_santo_remedio_g_ads`.`google_ads_santo_remediocampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-rSav',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_hospital_santa_julia_g_ads`.`google_ads_h_santa_juliacampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-jT4J',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_constroi_incorporadora_g_ads`.`google_ads_constroicampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-ABUl',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_doctor_mais_g_ads`.`google_ads_doctor_maiscampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-R4be',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_colmeia`.`google_ads_colmeiacampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-fwxw',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_amazoncopy_g_ads`.`google_ads_amazoncopycampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-dMx7',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_bigazine_g_ads`.`google_ads_bigazinecampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-x36N',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_arena_tintas_g_ads`.`google_ads_arena_tintascampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-WxA8',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_ba_eletrica_g_ads`.`google_ads_ba_eletricacampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-Llsu',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_pmz_grupo_ecomm`.`google_ads_pmz_ecommcampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-NP4k',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_pmz_loja`.`google_pmz_grupo_lojacampaign_performance`
  UNION ALL
  SELECT 'CAMPANHA','google-ads-PdSr',SAFE_CAST(id AS STRING),campaign_id,campaign_name,campaign_status,CAST(NULL AS INT64),CAST(NULL AS STRING),CAST(NULL AS INT64),CAST(NULL AS STRING),date,metrics_cost_micros,metrics_impressions,metrics_clicks,metrics_interactions,metrics_video_views,metrics_conversions,metrics_conversions_value,metrics_all_conversions,metrics_all_conversions_value,metrics_view_through_conversions,metrics_ctr,metrics_interaction_rate,metrics_conversions_from_interactions_rate,metrics_absolute_top_impression_percentage,metrics_top_impression_percentage,metrics_average_cpc,metrics_average_cpm FROM `vanguardamartech_pmz_escola_de_mecanicos`.`google_ads_pmz_escola_mecanicoscampaign_performance`
),
anuncio_chave AS (
  -- DISTINCT e obrigatorio: sem ele o LEFT JOIN abaixo multiplica a linha de campanha
  -- por quantos anuncios existirem naquele par (campanha, dia).
  SELECT DISTINCT _fonte, SAFE_CAST(campaign_id AS INT64) AS id_campanha, DATE(date) AS data
  FROM anuncio
),
crua AS (
  SELECT * FROM anuncio
  UNION ALL
  -- anti-join. Era NOT EXISTS correlacionado e o BigQuery nao descorrelaciona
  -- subconsulta que referencia CTE de uniao grande: "Correlated subqueries that
  -- reference other tables are not supported unless they can be de-correlated".
  SELECT k.* FROM campanha k
  LEFT JOIN anuncio_chave a
    ON  a._fonte      = k._fonte
    AND a.id_campanha = SAFE_CAST(k.campaign_id AS INT64)
    AND a.data        = DATE(k.date)
  WHERE a._fonte IS NULL
),
bruto AS (
  SELECT
    grao,
    _fonte,
    id_origem,
    SAFE_CAST(campaign_id AS INT64)                                   AS id_campanha,
    NULLIF(TRIM(SAFE_CAST(campaign_name AS STRING)), '')              AS campanha,
    SAFE_CAST(campaign_status AS STRING)                              AS status_campanha,
    ad_group_id                                                       AS id_grupo,
    ad_group_name                                                     AS grupo,
    ad_group_ad_ad_id                                                 AS id_anuncio,
    ad_group_ad_ad_name                                               AS anuncio,
    DATE(date)                                                        AS data,
    SAFE_CAST(metrics_cost_micros AS INT64)                           AS investimento_micros,
    SAFE_CAST(metrics_impressions AS INT64)                           AS impressoes,
    SAFE_CAST(metrics_clicks AS INT64)                                AS cliques,
    SAFE_CAST(metrics_interactions AS INT64)                          AS interacoes,
    SAFE_CAST(metrics_video_views AS INT64)                           AS visualizacoes_video,
    SAFE_CAST(metrics_conversions AS FLOAT64)                         AS conversoes,
    SAFE_CAST(metrics_conversions_value AS FLOAT64)                   AS valor_conversoes,
    SAFE_CAST(metrics_all_conversions AS FLOAT64)                     AS todas_conversoes,
    SAFE_CAST(metrics_all_conversions_value AS FLOAT64)               AS valor_todas_conversoes,
    SAFE_CAST(metrics_view_through_conversions AS INT64)              AS conversoes_view_through,
    SAFE_CAST(metrics_ctr AS FLOAT64)                                 AS ctr_fracao,
    SAFE_CAST(metrics_interaction_rate AS FLOAT64)                    AS taxa_interacao_fracao,
    SAFE_CAST(metrics_conversions_from_interactions_rate AS FLOAT64)  AS taxa_conversao_fracao,
    SAFE_CAST(metrics_absolute_top_impression_percentage AS FLOAT64)  AS impressao_topo_absoluto_fracao,
    SAFE_CAST(metrics_top_impression_percentage AS FLOAT64)           AS impressao_topo_fracao,
    SAFE_CAST(metrics_average_cpc AS FLOAT64)                         AS cpc_plataforma_micros,
    SAFE_CAST(metrics_average_cpm AS FLOAT64)                         AS cpm_plataforma_micros
  FROM crua
),
base AS (
  SELECT
    CONCAT(b._fonte, '|', b.grao, '|', b.id_origem)                   AS id_insight,
    b.*,
    TO_HEX(MD5(TO_JSON_STRING(b)))                                    AS _payload_hash
  FROM bruto b
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY b._fonte, b.grao, b.id_origem ORDER BY b.data DESC) = 1
)
SELECT
  b.id_insight,
  c.id_conta,
  -- cliente e moeda vem da dimensao trs_google_ads__conta, resolvidos por id_conta
  -- (extraido do resource_name). Eram literais escritos a mao, um par por fonte:
  -- 78 no total nesta query, cada um um lugar onde um erro de digitacao passaria
  -- despercebido. Agora ha uma fonte de verdade so, semeada da listagem do MCC.
  d.cliente,
  d.moeda,
  b.grao,

  b.id_campanha,
  b.campanha,
  b.status_campanha,
  b.id_grupo,
  b.grupo,
  b.id_anuncio,
  b.anuncio,

  b.data,
  DATE_TRUNC(b.data, MONTH)                                           AS mes_referencia,

  IFNULL(b.investimento_micros, 0)                                    AS investimento_micros,
  IFNULL(b.investimento_micros, 0) / 1000000                          AS investimento,

  IFNULL(b.impressoes, 0)                                             AS impressoes,
  IFNULL(b.cliques, 0)                                                AS cliques,
  IFNULL(b.interacoes, 0)                                             AS interacoes,
  IFNULL(b.visualizacoes_video, 0)                                    AS visualizacoes_video,

  IFNULL(b.conversoes, 0)                                             AS conversoes,
  IFNULL(b.valor_conversoes, 0)                                       AS valor_conversoes,
  IFNULL(b.todas_conversoes, 0)                                       AS todas_conversoes,
  IFNULL(b.valor_todas_conversoes, 0)                                 AS valor_todas_conversoes,
  IFNULL(b.conversoes_view_through, 0)                                AS conversoes_view_through,

  b.ctr_fracao,
  b.taxa_interacao_fracao,
  b.taxa_conversao_fracao,
  b.impressao_topo_absoluto_fracao,
  b.impressao_topo_fracao,

  b.cpc_plataforma_micros,
  ROUND(SAFE_DIVIDE(b.cpc_plataforma_micros, 1000000), 4)             AS cpc_plataforma,
  b.cpm_plataforma_micros,
  ROUND(SAFE_DIVIDE(b.cpm_plataforma_micros, 1000000), 4)             AS cpm_plataforma,

  (IFNULL(b.impressoes, 0) = 0 AND IFNULL(b.investimento_micros, 0) = 0) AS sem_entrega,
  -- Se a dimensao nao tiver a conta, cliente e moeda vem NULL. A flag existe para
  -- que isso apareca em vez de sumir dentro de um GROUP BY.
  (d.id_conta IS NULL)                                                AS flag_conta_nao_catalogada,

  CURRENT_TIMESTAMP()                                                 AS _extraido_at,
  b._fonte,
  b.id_origem,
  b._payload_hash
FROM base b
LEFT JOIN conta c
  ON c.id_campanha = b.id_campanha AND c.fonte = b._fonte
-- LEFT e proposital: INNER descartaria investimento em silencio se a dimensao
-- estivesse desatualizada. Aqui a linha fica e a flag acende.
LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__conta` d
  ON d.id_conta = c.id_conta
