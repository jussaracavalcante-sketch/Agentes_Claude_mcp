WITH p AS (
  SELECT 'GQ7o' f, * FROM `vanguardamartech_braga_motos_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'zjc0' f, * FROM `vanguardamartech_voike_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'SZXb' f, * FROM `vanguardamartech_vanguarda__facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'NO64' f, * FROM `vanguardamartech_unipar_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'fEB1' f, * FROM `vanguardamartech_targo_consultoria_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'rC0n' f, * FROM `vanguardamartech_smile_pneus_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'ywi1' f, * FROM `vanguardamartech_santo_remedio_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'FImY' f, * FROM `vanguardamartech_royal_enfield_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'wlWI' f, * FROM `vanguardamartech_rodrix_motos_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'dvNp' f, * FROM `vanguardamartech_rei_das_mangueiras_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'Mm0B' f, * FROM `vanguardamartech_pneu_forte_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'Dd1P' f, * FROM `vanguardamartech_arena_tintas_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'Pxtu' f, * FROM `vanguardamartech_distribuidora_pneu_forte_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'W1VR' f, * FROM `vanguardamartech_pneu_express_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'iUkb' f, * FROM `vanguardamartech_orla_92_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'myvP' f, * FROM `vanguardamartech_move_rental_cars_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'wcTq' f, * FROM `vanguardamartech_millennium_shopping_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'aSow' f, * FROM `vanguardamartech_maravilha_moto_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'Pkd8' f, * FROM `vanguardamartech_nome_do_cliente_legacy`.`facebook_pages_posts`
  UNION ALL SELECT 'DD2j' f, * FROM `vanguardamartech_leapmotor_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'bn97' f, * FROM `vanguardamartech_kl_rent_a_car_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'VH0u' f, * FROM `vanguardamartech_kiffer_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'lyto' f, * FROM `vanguardamartech_inforcell_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'dZrG' f, * FROM `vanguardamartech_hospital_santa_julia_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'HVTC' f, * FROM `vanguardamartech_grupo_pmz_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'hG1R' f, * FROM `vanguardamartech_eduardo_charao_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'f3Mn' f, * FROM `vanguardamartech_escola_pmz_facebook`.`facebook_pages_posts`
  UNION ALL SELECT '5M68' f, * FROM `vanguardamartech_dr_jose_cabral_jr_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'cWPC' f, * FROM `vanguardamartech_facebook_doctor_saude`.`facebook_pages_posts`
  UNION ALL SELECT 'wRty' f, * FROM `vanguardamartech_constroi_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'ZPCH' f, * FROM `vanguardamartech_comac_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'vfVI' f, * FROM `vanguardamartech_cdl_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'lOr1' f, * FROM `vanguardamartech_caa_tintas_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'tCaH' f, * FROM `vanguardamartech_caa_aluminio_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'GyYt' f, * FROM `vanguardamartech_braga_veiculos_venda_direta_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'nKAw' f, * FROM `vanguardamartech_braga_veiculos_varejo_e_vd_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'l1QS' f, * FROM `vanguardamartech_braga_acessorios_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'KJVl' f, * FROM `vanguardamartech_linvest_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'PPsY' f, * FROM `vanguardamartech_bragamotors_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'NnRq' f, * FROM `vanguardamartech_steel_port_facebook`.`facebook_pages_posts`
  UNION ALL SELECT '9O6v' f, * FROM `vanguardamartech_hage_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'hZNd' f, * FROM `vanguardamartech_vbot_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'qhR9' f, * FROM `vanguardamartech_amazon_open_mall_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'QnG2' f, * FROM `vanguardamartech_acdisplay_facebook`.`facebook_pages_posts`
  UNION ALL SELECT '9q2u' f, * FROM `vanguardamartech_bap_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'c7VF' f, * FROM `vanguardamartech_acesso_saude_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'Xedv' f, * FROM `vanguardamartech_animativ_facebook`.`facebook_pages_posts`
  UNION ALL SELECT 'ftS8' f, * FROM `vanguardamartech_leite_manaus`.`facebook_pages_posts`
),
i AS (
  SELECT 'GQ7o' f, * FROM `vanguardamartech_braga_motos_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'zjc0' f, * FROM `vanguardamartech_voike_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'SZXb' f, * FROM `vanguardamartech_vanguarda__facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'NO64' f, * FROM `vanguardamartech_unipar_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'fEB1' f, * FROM `vanguardamartech_targo_consultoria_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'rC0n' f, * FROM `vanguardamartech_smile_pneus_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'ywi1' f, * FROM `vanguardamartech_santo_remedio_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'FImY' f, * FROM `vanguardamartech_royal_enfield_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'wlWI' f, * FROM `vanguardamartech_rodrix_motos_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'dvNp' f, * FROM `vanguardamartech_rei_das_mangueiras_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'Mm0B' f, * FROM `vanguardamartech_pneu_forte_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'Dd1P' f, * FROM `vanguardamartech_arena_tintas_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'Pxtu' f, * FROM `vanguardamartech_distribuidora_pneu_forte_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'W1VR' f, * FROM `vanguardamartech_pneu_express_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'iUkb' f, * FROM `vanguardamartech_orla_92_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'myvP' f, * FROM `vanguardamartech_move_rental_cars_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'wcTq' f, * FROM `vanguardamartech_millennium_shopping_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'aSow' f, * FROM `vanguardamartech_maravilha_moto_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'Pkd8' f, * FROM `vanguardamartech_nome_do_cliente_legacy`.`facebook_pages_post_insights`
  UNION ALL SELECT 'DD2j' f, * FROM `vanguardamartech_leapmotor_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'bn97' f, * FROM `vanguardamartech_kl_rent_a_car_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'VH0u' f, * FROM `vanguardamartech_kiffer_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'lyto' f, * FROM `vanguardamartech_inforcell_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'dZrG' f, * FROM `vanguardamartech_hospital_santa_julia_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'HVTC' f, * FROM `vanguardamartech_grupo_pmz_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'hG1R' f, * FROM `vanguardamartech_eduardo_charao_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'f3Mn' f, * FROM `vanguardamartech_escola_pmz_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT '5M68' f, * FROM `vanguardamartech_dr_jose_cabral_jr_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'cWPC' f, * FROM `vanguardamartech_facebook_doctor_saude`.`facebook_pages_post_insights`
  UNION ALL SELECT 'wRty' f, * FROM `vanguardamartech_constroi_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'ZPCH' f, * FROM `vanguardamartech_comac_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'vfVI' f, * FROM `vanguardamartech_cdl_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'lOr1' f, * FROM `vanguardamartech_caa_tintas_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'tCaH' f, * FROM `vanguardamartech_caa_aluminio_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'GyYt' f, * FROM `vanguardamartech_braga_veiculos_venda_direta_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'nKAw' f, * FROM `vanguardamartech_braga_veiculos_varejo_e_vd_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'l1QS' f, * FROM `vanguardamartech_braga_acessorios_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'KJVl' f, * FROM `vanguardamartech_linvest_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'PPsY' f, * FROM `vanguardamartech_bragamotors_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'NnRq' f, * FROM `vanguardamartech_steel_port_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT '9O6v' f, * FROM `vanguardamartech_hage_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'hZNd' f, * FROM `vanguardamartech_vbot_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'qhR9' f, * FROM `vanguardamartech_amazon_open_mall_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'QnG2' f, * FROM `vanguardamartech_acdisplay_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT '9q2u' f, * FROM `vanguardamartech_bap_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'c7VF' f, * FROM `vanguardamartech_acesso_saude_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'Xedv' f, * FROM `vanguardamartech_animativ_facebook`.`facebook_pages_post_insights`
  UNION ALL SELECT 'ftS8' f, * FROM `vanguardamartech_leite_manaus`.`facebook_pages_post_insights`
),
br AS (
  SELECT 'GQ7o' f, * FROM `vanguardamartech_braga_motos_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'zjc0' f, * FROM `vanguardamartech_voike_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'SZXb' f, * FROM `vanguardamartech_vanguarda__facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'NO64' f, * FROM `vanguardamartech_unipar_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'fEB1' f, * FROM `vanguardamartech_targo_consultoria_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'rC0n' f, * FROM `vanguardamartech_smile_pneus_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'ywi1' f, * FROM `vanguardamartech_santo_remedio_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'FImY' f, * FROM `vanguardamartech_royal_enfield_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'wlWI' f, * FROM `vanguardamartech_rodrix_motos_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'dvNp' f, * FROM `vanguardamartech_rei_das_mangueiras_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'Mm0B' f, * FROM `vanguardamartech_pneu_forte_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'Dd1P' f, * FROM `vanguardamartech_arena_tintas_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'Pxtu' f, * FROM `vanguardamartech_distribuidora_pneu_forte_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'W1VR' f, * FROM `vanguardamartech_pneu_express_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'iUkb' f, * FROM `vanguardamartech_orla_92_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'myvP' f, * FROM `vanguardamartech_move_rental_cars_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'wcTq' f, * FROM `vanguardamartech_millennium_shopping_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'aSow' f, * FROM `vanguardamartech_maravilha_moto_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'Pkd8' f, * FROM `vanguardamartech_nome_do_cliente_legacy`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'DD2j' f, * FROM `vanguardamartech_leapmotor_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'bn97' f, * FROM `vanguardamartech_kl_rent_a_car_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'VH0u' f, * FROM `vanguardamartech_kiffer_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'lyto' f, * FROM `vanguardamartech_inforcell_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'dZrG' f, * FROM `vanguardamartech_hospital_santa_julia_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'HVTC' f, * FROM `vanguardamartech_grupo_pmz_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'hG1R' f, * FROM `vanguardamartech_eduardo_charao_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'f3Mn' f, * FROM `vanguardamartech_escola_pmz_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT '5M68' f, * FROM `vanguardamartech_dr_jose_cabral_jr_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'cWPC' f, * FROM `vanguardamartech_facebook_doctor_saude`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'wRty' f, * FROM `vanguardamartech_constroi_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'ZPCH' f, * FROM `vanguardamartech_comac_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'vfVI' f, * FROM `vanguardamartech_cdl_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'lOr1' f, * FROM `vanguardamartech_caa_tintas_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'tCaH' f, * FROM `vanguardamartech_caa_aluminio_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'GyYt' f, * FROM `vanguardamartech_braga_veiculos_venda_direta_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'nKAw' f, * FROM `vanguardamartech_braga_veiculos_varejo_e_vd_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'l1QS' f, * FROM `vanguardamartech_braga_acessorios_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'KJVl' f, * FROM `vanguardamartech_linvest_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'PPsY' f, * FROM `vanguardamartech_bragamotors_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'NnRq' f, * FROM `vanguardamartech_steel_port_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT '9O6v' f, * FROM `vanguardamartech_hage_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'hZNd' f, * FROM `vanguardamartech_vbot_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'qhR9' f, * FROM `vanguardamartech_amazon_open_mall_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'QnG2' f, * FROM `vanguardamartech_acdisplay_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT '9q2u' f, * FROM `vanguardamartech_bap_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'c7VF' f, * FROM `vanguardamartech_acesso_saude_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'Xedv' f, * FROM `vanguardamartech_animativ_facebook`.`facebook_pages_post_media_views_breakdown`
  UNION ALL SELECT 'ftS8' f, * FROM `vanguardamartech_leite_manaus`.`facebook_pages_post_media_views_breakdown`
),
brp AS (
  SELECT f, post_id,
    SUM(IF(breakdown_dimension = 'is_from_ads' AND breakdown_value = '1', media_view, NULL))       AS mv_anuncio,
    SUM(IF(breakdown_dimension = 'is_from_ads' AND breakdown_value = '0', media_view, NULL))       AS mv_organica,
    SUM(IF(breakdown_dimension = 'is_from_followers' AND breakdown_value = '1', media_view, NULL)) AS mv_seguidores,
    SUM(IF(breakdown_dimension = 'is_from_followers' AND breakdown_value = '0', media_view, NULL)) AS mv_nao_seguidores
  FROM br
  GROUP BY 1, 2
)
SELECT
  CONCAT('facebook-pages-', p.f, ':', p.id)                    AS id_post_fonte,
  p.id                                                         AS id_post,
  p.page_id                                                    AS id_pagina,
  p.created_time                                               AS criado_em,
  DATETIME(p.created_time, 'America/Sao_Paulo')                AS criado_em_local,
  DATE(p.created_time, 'America/Sao_Paulo')                    AS data_local,
  DATE_TRUNC(DATE(p.created_time, 'America/Sao_Paulo'), MONTH) AS mes_referencia,
  p.updated_time                                               AS atualizado_em,
  p.status_type                                                AS tipo_post,
  (p.status_type = 'added_video')                              AS is_video,
  NULLIF(TRIM(p.message), '')                                  AS mensagem,
  NULLIF(TRIM(p.story), '')                                    AS historia,
  p.permalink_url                                              AS link_permanente,
  p.is_published                                               AS is_publicado,
  p.is_hidden                                                  AS is_oculto,
  p.is_popular                                                 AS is_popular,
  p.is_expired                                                 AS is_expirado,
  p.is_eligible_for_promotion                                  AS is_elegivel_promocao,
  p.is_instagram_eligible                                      AS is_elegivel_instagram,
  p.shares.count                                               AS compartilhamentos,
  i.post_clicks                                                AS cliques,
  i.post_reactions_like_total                                  AS reacoes_curtir,
  i.post_reactions_love_total                                  AS reacoes_amei,
  i.post_reactions_wow_total                                   AS reacoes_uau,
  i.post_reactions_haha_total                                  AS reacoes_haha,
  i.post_reactions_sorry_total                                 AS reacoes_triste,
  i.post_reactions_anger_total                                 AS reacoes_grr,
  i.post_video_views_autoplayed                                AS video_views_autoplay,
  i.post_video_views_clicked_to_play                           AS video_views_clique_para_reproduzir,
  i.post_video_views_sound_on                                  AS video_views_com_som,
  i.post_video_views_15s                                       AS video_views_15s,
  i.post_video_views_60s_excludes_shorter                      AS video_views_60s,
  i.post_video_complete_views_organic                          AS video_views_completas_organicas,
  i.post_video_complete_views_organic_unique                   AS video_views_completas_organicas_unicas,
  i.post_video_complete_views_paid                             AS video_views_completas_pagas,
  i.post_video_complete_views_paid_unique                      AS video_views_completas_pagas_unicas,
  NULLIF(i.post_video_length, 0)                               AS duracao_video_ms,
  i.post_media_view                                            AS media_views,
  r.mv_anuncio                                                 AS media_views_de_anuncio,
  r.mv_organica                                                AS media_views_organicas,
  r.mv_seguidores                                              AS media_views_de_seguidores,
  r.mv_nao_seguidores                                          AS media_views_de_nao_seguidores,
  (i.post_id IS NULL)                                          AS flag_sem_insight,
  (r.post_id IS NULL)                                          AS flag_sem_breakdown,
  CURRENT_TIMESTAMP()                                          AS _extraido_at,
  CONCAT('facebook-pages-', p.f)                               AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(p)))                               AS _payload_hash
FROM p
LEFT JOIN i   ON i.f = p.f AND i.post_id = p.id
LEFT JOIN brp r ON r.f = p.f AND r.post_id = p.id
