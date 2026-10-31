-- trs_instagram__seguidores_dia
-- Serie de SEGUIDORES por conta: um ponto por extracao (a Raw e INCREMENTAL por `date`).
-- Grao: uma conta, uma data. Chave: id_seguidores_dia.
-- Origem: instagram_follower_count_historical. Gatilho: cron semanal, terca 14:00
-- America/Manaus. L2 INTERNAL. E a UNICA serie historica de seguidores desta familia:
-- instagram_user_details e FULL_SYNC e sobrescreve.
WITH f AS (
  SELECT 'instagram-wRZ1' AS _fonte, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-CfH8', * FROM `vanguardamartech_braga_motors_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-IZTB', * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-bv3u', * FROM `vanguardamartech_bap_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-209E', * FROM `vanguardamartech_bajaj_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-JJJ4', * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-rdCK', * FROM `vanguardamartech_automaster_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-gWSW', * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-K8dK', * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-CeJD', * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-Wajn', * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-oMgW', * FROM `vanguardamartech_ac_display_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-rRTe', * FROM `vanguardamartech_santo_remedio_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-qZ4y', * FROM `vanguardamartech_facilitti_motors_lovol_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-aXHi', * FROM `vanguardamartech_linvest_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-O5dx', * FROM `vanguardamartech_dr_bruno_maciel_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-yHk3', * FROM `vanguardamartech_arena_tintas_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-A90g', * FROM `vanguardamartech_braga_motos_consorcio_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-GM0j', * FROM `vanguardamartech_braga_motos_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-0iTW', * FROM `vanguardamartech_voike_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-nNtj', * FROM `vanguardamartech_vbot_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-SOcs', * FROM `vanguardamartech_vanguarda_growth_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-TjbI', * FROM `vanguardamartech_unipar_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-Nez2', * FROM `vanguardamartech_targo_consultoria_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-F6S4', * FROM `vanguardamartech_steel_port_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-VhPH', * FROM `vanguardamartech_smile_pneus_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-h56D', * FROM `vanguardamartech_royal_enfield_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-TdQm', * FROM `vanguardamartech_rodrix_motos_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-f6Fx', * FROM `vanguardamartech_rei_das_mangueiras_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-0Eez', * FROM `vanguardamartech_pneu_forte_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-pdgp', * FROM `vanguardamartech_pneu_forte_distribuidora_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-2Xhl', * FROM `vanguardamartech_pneu_express_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-6RO6', * FROM `vanguardamartech_orla_92_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-LkfW', * FROM `vanguardamartech_move_rental_cars_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-Wl0q', * FROM `vanguardamartech_millennium_shopping_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-aRFK', * FROM `vanguardamartech_maravilha_motos_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-Bir8', * FROM `vanguardamartech_legacy_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-kmsm', * FROM `vanguardamartech_leapmotor_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-Etq7', * FROM `vanguardamartech_kl_rent_a_car_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-7DrB', * FROM `vanguardamartech_kiffer_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-dFGL', * FROM `vanguardamartech_inforcell_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-Zf3I', * FROM `vanguardamartech_hospital_santa_julia_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-FIeB', * FROM `vanguardamartech_hage_alimentos_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-8tL4', * FROM `vanguardamartech_grupo_pmz_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-CBsl', * FROM `vanguardamartech_charao_tributario_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-Juyc', * FROM `vanguardamartech_charao_consultoria_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-zvUO', * FROM `vanguardamartech_eduardo_charao_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-9JVu', * FROM `vanguardamartech_escola_pmz_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-ZnP5', * FROM `vanguardamartech_dr_jose_cabral_jr_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-2GLM', * FROM `vanguardamartech_doctor_mais_saude_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-MBgH', * FROM `vanguardamartech_constroi_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-jBXA', * FROM `vanguardamartech_comac_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-2Ory', * FROM `vanguardamartech_cdl_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-cyHw', * FROM `vanguardamartech_caa_tintas_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-zCtu', * FROM `vanguardamartech_caa_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-Y5iQ', * FROM `vanguardamartech_braga_veiculos_varejo_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-FlJc', * FROM `vanguardamartech_best_car_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-gPUO', * FROM `vanguardamartech_animativ_instagram`.`instagram_follower_count_historical`
),
c AS (
  SELECT _fonte, id AS id_conta
  FROM (
    SELECT 'instagram-wRZ1' AS _fonte, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-CfH8', * FROM `vanguardamartech_braga_motors_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-IZTB', * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-bv3u', * FROM `vanguardamartech_bap_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-209E', * FROM `vanguardamartech_bajaj_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-JJJ4', * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-rdCK', * FROM `vanguardamartech_automaster_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-gWSW', * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-K8dK', * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-CeJD', * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-Wajn', * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-oMgW', * FROM `vanguardamartech_ac_display_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-rRTe', * FROM `vanguardamartech_santo_remedio_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-qZ4y', * FROM `vanguardamartech_facilitti_motors_lovol_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-aXHi', * FROM `vanguardamartech_linvest_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-O5dx', * FROM `vanguardamartech_dr_bruno_maciel_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-yHk3', * FROM `vanguardamartech_arena_tintas_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-A90g', * FROM `vanguardamartech_braga_motos_consorcio_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-GM0j', * FROM `vanguardamartech_braga_motos_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-0iTW', * FROM `vanguardamartech_voike_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-nNtj', * FROM `vanguardamartech_vbot_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-SOcs', * FROM `vanguardamartech_vanguarda_growth_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-TjbI', * FROM `vanguardamartech_unipar_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-Nez2', * FROM `vanguardamartech_targo_consultoria_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-F6S4', * FROM `vanguardamartech_steel_port_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-VhPH', * FROM `vanguardamartech_smile_pneus_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-h56D', * FROM `vanguardamartech_royal_enfield_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-TdQm', * FROM `vanguardamartech_rodrix_motos_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-f6Fx', * FROM `vanguardamartech_rei_das_mangueiras_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-0Eez', * FROM `vanguardamartech_pneu_forte_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-pdgp', * FROM `vanguardamartech_pneu_forte_distribuidora_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-2Xhl', * FROM `vanguardamartech_pneu_express_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-6RO6', * FROM `vanguardamartech_orla_92_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-LkfW', * FROM `vanguardamartech_move_rental_cars_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-Wl0q', * FROM `vanguardamartech_millennium_shopping_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-aRFK', * FROM `vanguardamartech_maravilha_motos_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-Bir8', * FROM `vanguardamartech_legacy_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-kmsm', * FROM `vanguardamartech_leapmotor_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-Etq7', * FROM `vanguardamartech_kl_rent_a_car_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-7DrB', * FROM `vanguardamartech_kiffer_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-dFGL', * FROM `vanguardamartech_inforcell_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-Zf3I', * FROM `vanguardamartech_hospital_santa_julia_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-FIeB', * FROM `vanguardamartech_hage_alimentos_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-8tL4', * FROM `vanguardamartech_grupo_pmz_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-CBsl', * FROM `vanguardamartech_charao_tributario_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-Juyc', * FROM `vanguardamartech_charao_consultoria_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-zvUO', * FROM `vanguardamartech_eduardo_charao_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-9JVu', * FROM `vanguardamartech_escola_pmz_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-ZnP5', * FROM `vanguardamartech_dr_jose_cabral_jr_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-2GLM', * FROM `vanguardamartech_doctor_mais_saude_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-MBgH', * FROM `vanguardamartech_constroi_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-jBXA', * FROM `vanguardamartech_comac_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-2Ory', * FROM `vanguardamartech_cdl_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-cyHw', * FROM `vanguardamartech_caa_tintas_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-zCtu', * FROM `vanguardamartech_caa_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-Y5iQ', * FROM `vanguardamartech_braga_veiculos_varejo_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-FlJc', * FROM `vanguardamartech_best_car_instagram`.`instagram_user_details`
    UNION ALL SELECT 'instagram-gPUO', * FROM `vanguardamartech_animativ_instagram`.`instagram_user_details`
  )
)
SELECT
  CONCAT(c.id_conta, ':', FORMAT_DATE('%Y-%m-%d', DATE(f.date))) AS id_seguidores_dia,
  c.id_conta,
  DATE(f.date)                          AS data,
  f.followers_count                     AS seguidores,
  CURRENT_TIMESTAMP()                   AS _extraido_at,
  f._fonte,
  TO_HEX(MD5(TO_JSON_STRING(f)))        AS _payload_hash
FROM f
JOIN c ON c._fonte = f._fonte
