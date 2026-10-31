-- trs_instagram__audiencia_seguidor
-- Demografia dos SEGUIDORES de cada conta: idade, genero, pais e cidade.
-- Grao: uma conta, uma dimensao, um valor. Chave: id_audiencia.
-- Origem: instagram_follower_demographics_{age,gender,country,city}_lifetime (FULL_SYNC,
-- fotografia sem data). Gatilho: cron semanal, terca 14:00 America/Manaus. L2 INTERNAL
-- (contagem agregada por segmento; nenhum seguidor e identificado).
WITH a AS (
  SELECT 'instagram-wRZ1' AS _fonte, 'IDADE' AS dimensao, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-CfH8', 'IDADE' AS dimensao, * FROM `vanguardamartech_braga_motors_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-IZTB', 'IDADE' AS dimensao, * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-bv3u', 'IDADE' AS dimensao, * FROM `vanguardamartech_bap_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-209E', 'IDADE' AS dimensao, * FROM `vanguardamartech_bajaj_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-JJJ4', 'IDADE' AS dimensao, * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-rdCK', 'IDADE' AS dimensao, * FROM `vanguardamartech_automaster_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-gWSW', 'IDADE' AS dimensao, * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-K8dK', 'IDADE' AS dimensao, * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-CeJD', 'IDADE' AS dimensao, * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-Wajn', 'IDADE' AS dimensao, * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-oMgW', 'IDADE' AS dimensao, * FROM `vanguardamartech_ac_display_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-rRTe', 'IDADE' AS dimensao, * FROM `vanguardamartech_santo_remedio_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-qZ4y', 'IDADE' AS dimensao, * FROM `vanguardamartech_facilitti_motors_lovol_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-aXHi', 'IDADE' AS dimensao, * FROM `vanguardamartech_linvest_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-O5dx', 'IDADE' AS dimensao, * FROM `vanguardamartech_dr_bruno_maciel_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-yHk3', 'IDADE' AS dimensao, * FROM `vanguardamartech_arena_tintas_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-A90g', 'IDADE' AS dimensao, * FROM `vanguardamartech_braga_motos_consorcio_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-GM0j', 'IDADE' AS dimensao, * FROM `vanguardamartech_braga_motos_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-0iTW', 'IDADE' AS dimensao, * FROM `vanguardamartech_voike_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-nNtj', 'IDADE' AS dimensao, * FROM `vanguardamartech_vbot_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-SOcs', 'IDADE' AS dimensao, * FROM `vanguardamartech_vanguarda_growth_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-TjbI', 'IDADE' AS dimensao, * FROM `vanguardamartech_unipar_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-Nez2', 'IDADE' AS dimensao, * FROM `vanguardamartech_targo_consultoria_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-F6S4', 'IDADE' AS dimensao, * FROM `vanguardamartech_steel_port_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-VhPH', 'IDADE' AS dimensao, * FROM `vanguardamartech_smile_pneus_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-h56D', 'IDADE' AS dimensao, * FROM `vanguardamartech_royal_enfield_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-TdQm', 'IDADE' AS dimensao, * FROM `vanguardamartech_rodrix_motos_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-f6Fx', 'IDADE' AS dimensao, * FROM `vanguardamartech_rei_das_mangueiras_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-0Eez', 'IDADE' AS dimensao, * FROM `vanguardamartech_pneu_forte_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-pdgp', 'IDADE' AS dimensao, * FROM `vanguardamartech_pneu_forte_distribuidora_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-2Xhl', 'IDADE' AS dimensao, * FROM `vanguardamartech_pneu_express_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-6RO6', 'IDADE' AS dimensao, * FROM `vanguardamartech_orla_92_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-LkfW', 'IDADE' AS dimensao, * FROM `vanguardamartech_move_rental_cars_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-Wl0q', 'IDADE' AS dimensao, * FROM `vanguardamartech_millennium_shopping_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-aRFK', 'IDADE' AS dimensao, * FROM `vanguardamartech_maravilha_motos_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-Bir8', 'IDADE' AS dimensao, * FROM `vanguardamartech_legacy_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-kmsm', 'IDADE' AS dimensao, * FROM `vanguardamartech_leapmotor_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-Etq7', 'IDADE' AS dimensao, * FROM `vanguardamartech_kl_rent_a_car_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-7DrB', 'IDADE' AS dimensao, * FROM `vanguardamartech_kiffer_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-dFGL', 'IDADE' AS dimensao, * FROM `vanguardamartech_inforcell_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-Zf3I', 'IDADE' AS dimensao, * FROM `vanguardamartech_hospital_santa_julia_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-FIeB', 'IDADE' AS dimensao, * FROM `vanguardamartech_hage_alimentos_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-8tL4', 'IDADE' AS dimensao, * FROM `vanguardamartech_grupo_pmz_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-CBsl', 'IDADE' AS dimensao, * FROM `vanguardamartech_charao_tributario_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-Juyc', 'IDADE' AS dimensao, * FROM `vanguardamartech_charao_consultoria_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-zvUO', 'IDADE' AS dimensao, * FROM `vanguardamartech_eduardo_charao_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-9JVu', 'IDADE' AS dimensao, * FROM `vanguardamartech_escola_pmz_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-ZnP5', 'IDADE' AS dimensao, * FROM `vanguardamartech_dr_jose_cabral_jr_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-2GLM', 'IDADE' AS dimensao, * FROM `vanguardamartech_doctor_mais_saude_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-MBgH', 'IDADE' AS dimensao, * FROM `vanguardamartech_constroi_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-jBXA', 'IDADE' AS dimensao, * FROM `vanguardamartech_comac_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-2Ory', 'IDADE' AS dimensao, * FROM `vanguardamartech_cdl_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-cyHw', 'IDADE' AS dimensao, * FROM `vanguardamartech_caa_tintas_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-zCtu', 'IDADE' AS dimensao, * FROM `vanguardamartech_caa_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-Y5iQ', 'IDADE' AS dimensao, * FROM `vanguardamartech_braga_veiculos_varejo_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-FlJc', 'IDADE' AS dimensao, * FROM `vanguardamartech_best_car_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-gPUO', 'IDADE' AS dimensao, * FROM `vanguardamartech_animativ_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL
  SELECT 'instagram-wRZ1' AS _fonte, 'GENERO' AS dimensao, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-CfH8', 'GENERO' AS dimensao, * FROM `vanguardamartech_braga_motors_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-IZTB', 'GENERO' AS dimensao, * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-bv3u', 'GENERO' AS dimensao, * FROM `vanguardamartech_bap_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-209E', 'GENERO' AS dimensao, * FROM `vanguardamartech_bajaj_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-JJJ4', 'GENERO' AS dimensao, * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-rdCK', 'GENERO' AS dimensao, * FROM `vanguardamartech_automaster_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-gWSW', 'GENERO' AS dimensao, * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-K8dK', 'GENERO' AS dimensao, * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-CeJD', 'GENERO' AS dimensao, * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-Wajn', 'GENERO' AS dimensao, * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-oMgW', 'GENERO' AS dimensao, * FROM `vanguardamartech_ac_display_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-rRTe', 'GENERO' AS dimensao, * FROM `vanguardamartech_santo_remedio_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-qZ4y', 'GENERO' AS dimensao, * FROM `vanguardamartech_facilitti_motors_lovol_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-aXHi', 'GENERO' AS dimensao, * FROM `vanguardamartech_linvest_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-O5dx', 'GENERO' AS dimensao, * FROM `vanguardamartech_dr_bruno_maciel_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-yHk3', 'GENERO' AS dimensao, * FROM `vanguardamartech_arena_tintas_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-A90g', 'GENERO' AS dimensao, * FROM `vanguardamartech_braga_motos_consorcio_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-GM0j', 'GENERO' AS dimensao, * FROM `vanguardamartech_braga_motos_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-0iTW', 'GENERO' AS dimensao, * FROM `vanguardamartech_voike_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-nNtj', 'GENERO' AS dimensao, * FROM `vanguardamartech_vbot_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-SOcs', 'GENERO' AS dimensao, * FROM `vanguardamartech_vanguarda_growth_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-TjbI', 'GENERO' AS dimensao, * FROM `vanguardamartech_unipar_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-Nez2', 'GENERO' AS dimensao, * FROM `vanguardamartech_targo_consultoria_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-F6S4', 'GENERO' AS dimensao, * FROM `vanguardamartech_steel_port_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-VhPH', 'GENERO' AS dimensao, * FROM `vanguardamartech_smile_pneus_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-h56D', 'GENERO' AS dimensao, * FROM `vanguardamartech_royal_enfield_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-TdQm', 'GENERO' AS dimensao, * FROM `vanguardamartech_rodrix_motos_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-f6Fx', 'GENERO' AS dimensao, * FROM `vanguardamartech_rei_das_mangueiras_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-0Eez', 'GENERO' AS dimensao, * FROM `vanguardamartech_pneu_forte_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-pdgp', 'GENERO' AS dimensao, * FROM `vanguardamartech_pneu_forte_distribuidora_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-2Xhl', 'GENERO' AS dimensao, * FROM `vanguardamartech_pneu_express_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-6RO6', 'GENERO' AS dimensao, * FROM `vanguardamartech_orla_92_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-LkfW', 'GENERO' AS dimensao, * FROM `vanguardamartech_move_rental_cars_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-Wl0q', 'GENERO' AS dimensao, * FROM `vanguardamartech_millennium_shopping_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-aRFK', 'GENERO' AS dimensao, * FROM `vanguardamartech_maravilha_motos_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-Bir8', 'GENERO' AS dimensao, * FROM `vanguardamartech_legacy_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-kmsm', 'GENERO' AS dimensao, * FROM `vanguardamartech_leapmotor_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-Etq7', 'GENERO' AS dimensao, * FROM `vanguardamartech_kl_rent_a_car_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-7DrB', 'GENERO' AS dimensao, * FROM `vanguardamartech_kiffer_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-dFGL', 'GENERO' AS dimensao, * FROM `vanguardamartech_inforcell_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-Zf3I', 'GENERO' AS dimensao, * FROM `vanguardamartech_hospital_santa_julia_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-FIeB', 'GENERO' AS dimensao, * FROM `vanguardamartech_hage_alimentos_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-8tL4', 'GENERO' AS dimensao, * FROM `vanguardamartech_grupo_pmz_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-CBsl', 'GENERO' AS dimensao, * FROM `vanguardamartech_charao_tributario_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-Juyc', 'GENERO' AS dimensao, * FROM `vanguardamartech_charao_consultoria_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-zvUO', 'GENERO' AS dimensao, * FROM `vanguardamartech_eduardo_charao_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-9JVu', 'GENERO' AS dimensao, * FROM `vanguardamartech_escola_pmz_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-ZnP5', 'GENERO' AS dimensao, * FROM `vanguardamartech_dr_jose_cabral_jr_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-2GLM', 'GENERO' AS dimensao, * FROM `vanguardamartech_doctor_mais_saude_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-MBgH', 'GENERO' AS dimensao, * FROM `vanguardamartech_constroi_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-jBXA', 'GENERO' AS dimensao, * FROM `vanguardamartech_comac_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-2Ory', 'GENERO' AS dimensao, * FROM `vanguardamartech_cdl_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-cyHw', 'GENERO' AS dimensao, * FROM `vanguardamartech_caa_tintas_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-zCtu', 'GENERO' AS dimensao, * FROM `vanguardamartech_caa_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-Y5iQ', 'GENERO' AS dimensao, * FROM `vanguardamartech_braga_veiculos_varejo_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-FlJc', 'GENERO' AS dimensao, * FROM `vanguardamartech_best_car_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-gPUO', 'GENERO' AS dimensao, * FROM `vanguardamartech_animativ_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL
  SELECT 'instagram-wRZ1' AS _fonte, 'PAIS' AS dimensao, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-CfH8', 'PAIS' AS dimensao, * FROM `vanguardamartech_braga_motors_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-IZTB', 'PAIS' AS dimensao, * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-bv3u', 'PAIS' AS dimensao, * FROM `vanguardamartech_bap_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-209E', 'PAIS' AS dimensao, * FROM `vanguardamartech_bajaj_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-JJJ4', 'PAIS' AS dimensao, * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-rdCK', 'PAIS' AS dimensao, * FROM `vanguardamartech_automaster_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-gWSW', 'PAIS' AS dimensao, * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-K8dK', 'PAIS' AS dimensao, * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-CeJD', 'PAIS' AS dimensao, * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-Wajn', 'PAIS' AS dimensao, * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-oMgW', 'PAIS' AS dimensao, * FROM `vanguardamartech_ac_display_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-rRTe', 'PAIS' AS dimensao, * FROM `vanguardamartech_santo_remedio_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-qZ4y', 'PAIS' AS dimensao, * FROM `vanguardamartech_facilitti_motors_lovol_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-aXHi', 'PAIS' AS dimensao, * FROM `vanguardamartech_linvest_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-O5dx', 'PAIS' AS dimensao, * FROM `vanguardamartech_dr_bruno_maciel_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-yHk3', 'PAIS' AS dimensao, * FROM `vanguardamartech_arena_tintas_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-A90g', 'PAIS' AS dimensao, * FROM `vanguardamartech_braga_motos_consorcio_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-GM0j', 'PAIS' AS dimensao, * FROM `vanguardamartech_braga_motos_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-0iTW', 'PAIS' AS dimensao, * FROM `vanguardamartech_voike_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-nNtj', 'PAIS' AS dimensao, * FROM `vanguardamartech_vbot_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-SOcs', 'PAIS' AS dimensao, * FROM `vanguardamartech_vanguarda_growth_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-TjbI', 'PAIS' AS dimensao, * FROM `vanguardamartech_unipar_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-Nez2', 'PAIS' AS dimensao, * FROM `vanguardamartech_targo_consultoria_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-F6S4', 'PAIS' AS dimensao, * FROM `vanguardamartech_steel_port_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-VhPH', 'PAIS' AS dimensao, * FROM `vanguardamartech_smile_pneus_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-h56D', 'PAIS' AS dimensao, * FROM `vanguardamartech_royal_enfield_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-TdQm', 'PAIS' AS dimensao, * FROM `vanguardamartech_rodrix_motos_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-f6Fx', 'PAIS' AS dimensao, * FROM `vanguardamartech_rei_das_mangueiras_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-0Eez', 'PAIS' AS dimensao, * FROM `vanguardamartech_pneu_forte_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-pdgp', 'PAIS' AS dimensao, * FROM `vanguardamartech_pneu_forte_distribuidora_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-2Xhl', 'PAIS' AS dimensao, * FROM `vanguardamartech_pneu_express_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-6RO6', 'PAIS' AS dimensao, * FROM `vanguardamartech_orla_92_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-LkfW', 'PAIS' AS dimensao, * FROM `vanguardamartech_move_rental_cars_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-Wl0q', 'PAIS' AS dimensao, * FROM `vanguardamartech_millennium_shopping_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-aRFK', 'PAIS' AS dimensao, * FROM `vanguardamartech_maravilha_motos_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-Bir8', 'PAIS' AS dimensao, * FROM `vanguardamartech_legacy_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-kmsm', 'PAIS' AS dimensao, * FROM `vanguardamartech_leapmotor_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-Etq7', 'PAIS' AS dimensao, * FROM `vanguardamartech_kl_rent_a_car_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-7DrB', 'PAIS' AS dimensao, * FROM `vanguardamartech_kiffer_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-dFGL', 'PAIS' AS dimensao, * FROM `vanguardamartech_inforcell_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-Zf3I', 'PAIS' AS dimensao, * FROM `vanguardamartech_hospital_santa_julia_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-FIeB', 'PAIS' AS dimensao, * FROM `vanguardamartech_hage_alimentos_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-8tL4', 'PAIS' AS dimensao, * FROM `vanguardamartech_grupo_pmz_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-CBsl', 'PAIS' AS dimensao, * FROM `vanguardamartech_charao_tributario_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-Juyc', 'PAIS' AS dimensao, * FROM `vanguardamartech_charao_consultoria_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-zvUO', 'PAIS' AS dimensao, * FROM `vanguardamartech_eduardo_charao_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-9JVu', 'PAIS' AS dimensao, * FROM `vanguardamartech_escola_pmz_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-ZnP5', 'PAIS' AS dimensao, * FROM `vanguardamartech_dr_jose_cabral_jr_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-2GLM', 'PAIS' AS dimensao, * FROM `vanguardamartech_doctor_mais_saude_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-MBgH', 'PAIS' AS dimensao, * FROM `vanguardamartech_constroi_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-jBXA', 'PAIS' AS dimensao, * FROM `vanguardamartech_comac_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-2Ory', 'PAIS' AS dimensao, * FROM `vanguardamartech_cdl_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-cyHw', 'PAIS' AS dimensao, * FROM `vanguardamartech_caa_tintas_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-zCtu', 'PAIS' AS dimensao, * FROM `vanguardamartech_caa_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-Y5iQ', 'PAIS' AS dimensao, * FROM `vanguardamartech_braga_veiculos_varejo_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-FlJc', 'PAIS' AS dimensao, * FROM `vanguardamartech_best_car_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-gPUO', 'PAIS' AS dimensao, * FROM `vanguardamartech_animativ_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL
  SELECT 'instagram-wRZ1' AS _fonte, 'CIDADE' AS dimensao, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-CfH8', 'CIDADE' AS dimensao, * FROM `vanguardamartech_braga_motors_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-IZTB', 'CIDADE' AS dimensao, * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-bv3u', 'CIDADE' AS dimensao, * FROM `vanguardamartech_bap_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-209E', 'CIDADE' AS dimensao, * FROM `vanguardamartech_bajaj_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-JJJ4', 'CIDADE' AS dimensao, * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-rdCK', 'CIDADE' AS dimensao, * FROM `vanguardamartech_automaster_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-gWSW', 'CIDADE' AS dimensao, * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-K8dK', 'CIDADE' AS dimensao, * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-CeJD', 'CIDADE' AS dimensao, * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-Wajn', 'CIDADE' AS dimensao, * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-oMgW', 'CIDADE' AS dimensao, * FROM `vanguardamartech_ac_display_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-rRTe', 'CIDADE' AS dimensao, * FROM `vanguardamartech_santo_remedio_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-qZ4y', 'CIDADE' AS dimensao, * FROM `vanguardamartech_facilitti_motors_lovol_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-aXHi', 'CIDADE' AS dimensao, * FROM `vanguardamartech_linvest_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-O5dx', 'CIDADE' AS dimensao, * FROM `vanguardamartech_dr_bruno_maciel_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-yHk3', 'CIDADE' AS dimensao, * FROM `vanguardamartech_arena_tintas_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-A90g', 'CIDADE' AS dimensao, * FROM `vanguardamartech_braga_motos_consorcio_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-GM0j', 'CIDADE' AS dimensao, * FROM `vanguardamartech_braga_motos_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-0iTW', 'CIDADE' AS dimensao, * FROM `vanguardamartech_voike_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-nNtj', 'CIDADE' AS dimensao, * FROM `vanguardamartech_vbot_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-SOcs', 'CIDADE' AS dimensao, * FROM `vanguardamartech_vanguarda_growth_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-TjbI', 'CIDADE' AS dimensao, * FROM `vanguardamartech_unipar_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-Nez2', 'CIDADE' AS dimensao, * FROM `vanguardamartech_targo_consultoria_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-F6S4', 'CIDADE' AS dimensao, * FROM `vanguardamartech_steel_port_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-VhPH', 'CIDADE' AS dimensao, * FROM `vanguardamartech_smile_pneus_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-h56D', 'CIDADE' AS dimensao, * FROM `vanguardamartech_royal_enfield_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-TdQm', 'CIDADE' AS dimensao, * FROM `vanguardamartech_rodrix_motos_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-f6Fx', 'CIDADE' AS dimensao, * FROM `vanguardamartech_rei_das_mangueiras_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-0Eez', 'CIDADE' AS dimensao, * FROM `vanguardamartech_pneu_forte_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-pdgp', 'CIDADE' AS dimensao, * FROM `vanguardamartech_pneu_forte_distribuidora_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-2Xhl', 'CIDADE' AS dimensao, * FROM `vanguardamartech_pneu_express_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-6RO6', 'CIDADE' AS dimensao, * FROM `vanguardamartech_orla_92_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-LkfW', 'CIDADE' AS dimensao, * FROM `vanguardamartech_move_rental_cars_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-Wl0q', 'CIDADE' AS dimensao, * FROM `vanguardamartech_millennium_shopping_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-aRFK', 'CIDADE' AS dimensao, * FROM `vanguardamartech_maravilha_motos_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-Bir8', 'CIDADE' AS dimensao, * FROM `vanguardamartech_legacy_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-kmsm', 'CIDADE' AS dimensao, * FROM `vanguardamartech_leapmotor_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-Etq7', 'CIDADE' AS dimensao, * FROM `vanguardamartech_kl_rent_a_car_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-7DrB', 'CIDADE' AS dimensao, * FROM `vanguardamartech_kiffer_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-dFGL', 'CIDADE' AS dimensao, * FROM `vanguardamartech_inforcell_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-Zf3I', 'CIDADE' AS dimensao, * FROM `vanguardamartech_hospital_santa_julia_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-FIeB', 'CIDADE' AS dimensao, * FROM `vanguardamartech_hage_alimentos_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-8tL4', 'CIDADE' AS dimensao, * FROM `vanguardamartech_grupo_pmz_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-CBsl', 'CIDADE' AS dimensao, * FROM `vanguardamartech_charao_tributario_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-Juyc', 'CIDADE' AS dimensao, * FROM `vanguardamartech_charao_consultoria_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-zvUO', 'CIDADE' AS dimensao, * FROM `vanguardamartech_eduardo_charao_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-9JVu', 'CIDADE' AS dimensao, * FROM `vanguardamartech_escola_pmz_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-ZnP5', 'CIDADE' AS dimensao, * FROM `vanguardamartech_dr_jose_cabral_jr_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-2GLM', 'CIDADE' AS dimensao, * FROM `vanguardamartech_doctor_mais_saude_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-MBgH', 'CIDADE' AS dimensao, * FROM `vanguardamartech_constroi_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-jBXA', 'CIDADE' AS dimensao, * FROM `vanguardamartech_comac_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-2Ory', 'CIDADE' AS dimensao, * FROM `vanguardamartech_cdl_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-cyHw', 'CIDADE' AS dimensao, * FROM `vanguardamartech_caa_tintas_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-zCtu', 'CIDADE' AS dimensao, * FROM `vanguardamartech_caa_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-Y5iQ', 'CIDADE' AS dimensao, * FROM `vanguardamartech_braga_veiculos_varejo_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-FlJc', 'CIDADE' AS dimensao, * FROM `vanguardamartech_best_car_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-gPUO', 'CIDADE' AS dimensao, * FROM `vanguardamartech_animativ_instagram`.`instagram_follower_demographics_city_lifetime`
),
n AS (
  SELECT _fonte, dimensao, COUNT(*) AS qtd_valores
  FROM a GROUP BY _fonte, dimensao
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
  CONCAT(c.id_conta, ':', a.dimensao, ':', a.dimension_value) AS id_audiencia,
  c.id_conta,
  a.dimensao,
  a.dimension_value                     AS valor_dimensao,
  a.value                               AS qtd_seguidores,
  -- A API devolve no maximo 45 valores por dimensao de pais e de cidade: lista cheia = cortada.
  (a.dimensao IN ('PAIS', 'CIDADE') AND n.qtd_valores >= 45) AS flag_lista_truncada_no_top,
  CURRENT_TIMESTAMP()                   AS _extraido_at,
  a._fonte,
  TO_HEX(MD5(TO_JSON_STRING(a)))        AS _payload_hash
FROM a
JOIN n ON n._fonte = a._fonte AND n.dimensao = a.dimensao
JOIN c ON c._fonte = a._fonte
