-- trs_instagram__insight_conta
-- Insights da CONTA Instagram em tres janelas moveis: DIA (1 dia), SEMANA (7) e 28_DIAS (28).
-- Grao: uma conta, uma janela, o ultimo dia da janela. Chave: id_insight_conta.
-- Origem: instagram_insights_rolling_day / _week / _days28 (INCREMENTAL por `date`).
-- Gatilho: cron semanal, terca 14:00 America/Manaus. L2 INTERNAL (agregado de conta).
-- NAO SOMAR entre linhas de janelas diferentes nem entre dias de SEMANA/28_DIAS: as janelas
-- se sobrepoem e `alcance` e `contas_engajadas` sao deduplicados pela API na janela inteira.
WITH j AS (
  SELECT 'instagram-wRZ1' AS _fonte, 'DIA' AS janela, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-CfH8', 'DIA' AS janela, * FROM `vanguardamartech_braga_motors_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-IZTB', 'DIA' AS janela, * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-bv3u', 'DIA' AS janela, * FROM `vanguardamartech_bap_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-209E', 'DIA' AS janela, * FROM `vanguardamartech_bajaj_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-JJJ4', 'DIA' AS janela, * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-rdCK', 'DIA' AS janela, * FROM `vanguardamartech_automaster_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-gWSW', 'DIA' AS janela, * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-K8dK', 'DIA' AS janela, * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-CeJD', 'DIA' AS janela, * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-Wajn', 'DIA' AS janela, * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-oMgW', 'DIA' AS janela, * FROM `vanguardamartech_ac_display_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-rRTe', 'DIA' AS janela, * FROM `vanguardamartech_santo_remedio_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-qZ4y', 'DIA' AS janela, * FROM `vanguardamartech_facilitti_motors_lovol_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-aXHi', 'DIA' AS janela, * FROM `vanguardamartech_linvest_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-O5dx', 'DIA' AS janela, * FROM `vanguardamartech_dr_bruno_maciel_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-yHk3', 'DIA' AS janela, * FROM `vanguardamartech_arena_tintas_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-A90g', 'DIA' AS janela, * FROM `vanguardamartech_braga_motos_consorcio_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-GM0j', 'DIA' AS janela, * FROM `vanguardamartech_braga_motos_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-0iTW', 'DIA' AS janela, * FROM `vanguardamartech_voike_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-nNtj', 'DIA' AS janela, * FROM `vanguardamartech_vbot_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-SOcs', 'DIA' AS janela, * FROM `vanguardamartech_vanguarda_growth_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-TjbI', 'DIA' AS janela, * FROM `vanguardamartech_unipar_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-Nez2', 'DIA' AS janela, * FROM `vanguardamartech_targo_consultoria_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-F6S4', 'DIA' AS janela, * FROM `vanguardamartech_steel_port_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-VhPH', 'DIA' AS janela, * FROM `vanguardamartech_smile_pneus_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-h56D', 'DIA' AS janela, * FROM `vanguardamartech_royal_enfield_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-TdQm', 'DIA' AS janela, * FROM `vanguardamartech_rodrix_motos_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-f6Fx', 'DIA' AS janela, * FROM `vanguardamartech_rei_das_mangueiras_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-0Eez', 'DIA' AS janela, * FROM `vanguardamartech_pneu_forte_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-pdgp', 'DIA' AS janela, * FROM `vanguardamartech_pneu_forte_distribuidora_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-2Xhl', 'DIA' AS janela, * FROM `vanguardamartech_pneu_express_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-6RO6', 'DIA' AS janela, * FROM `vanguardamartech_orla_92_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-LkfW', 'DIA' AS janela, * FROM `vanguardamartech_move_rental_cars_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-Wl0q', 'DIA' AS janela, * FROM `vanguardamartech_millennium_shopping_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-aRFK', 'DIA' AS janela, * FROM `vanguardamartech_maravilha_motos_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-Bir8', 'DIA' AS janela, * FROM `vanguardamartech_legacy_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-kmsm', 'DIA' AS janela, * FROM `vanguardamartech_leapmotor_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-Etq7', 'DIA' AS janela, * FROM `vanguardamartech_kl_rent_a_car_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-7DrB', 'DIA' AS janela, * FROM `vanguardamartech_kiffer_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-dFGL', 'DIA' AS janela, * FROM `vanguardamartech_inforcell_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-Zf3I', 'DIA' AS janela, * FROM `vanguardamartech_hospital_santa_julia_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-FIeB', 'DIA' AS janela, * FROM `vanguardamartech_hage_alimentos_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-8tL4', 'DIA' AS janela, * FROM `vanguardamartech_grupo_pmz_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-CBsl', 'DIA' AS janela, * FROM `vanguardamartech_charao_tributario_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-Juyc', 'DIA' AS janela, * FROM `vanguardamartech_charao_consultoria_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-zvUO', 'DIA' AS janela, * FROM `vanguardamartech_eduardo_charao_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-9JVu', 'DIA' AS janela, * FROM `vanguardamartech_escola_pmz_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-ZnP5', 'DIA' AS janela, * FROM `vanguardamartech_dr_jose_cabral_jr_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-2GLM', 'DIA' AS janela, * FROM `vanguardamartech_doctor_mais_saude_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-MBgH', 'DIA' AS janela, * FROM `vanguardamartech_constroi_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-jBXA', 'DIA' AS janela, * FROM `vanguardamartech_comac_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-2Ory', 'DIA' AS janela, * FROM `vanguardamartech_cdl_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-cyHw', 'DIA' AS janela, * FROM `vanguardamartech_caa_tintas_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-zCtu', 'DIA' AS janela, * FROM `vanguardamartech_caa_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-Y5iQ', 'DIA' AS janela, * FROM `vanguardamartech_braga_veiculos_varejo_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-FlJc', 'DIA' AS janela, * FROM `vanguardamartech_best_car_instagram`.`instagram_insights_rolling_day`
  UNION ALL SELECT 'instagram-gPUO', 'DIA' AS janela, * FROM `vanguardamartech_animativ_instagram`.`instagram_insights_rolling_day`
  UNION ALL
  SELECT 'instagram-wRZ1' AS _fonte, 'SEMANA' AS janela, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-CfH8', 'SEMANA' AS janela, * FROM `vanguardamartech_braga_motors_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-IZTB', 'SEMANA' AS janela, * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-bv3u', 'SEMANA' AS janela, * FROM `vanguardamartech_bap_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-209E', 'SEMANA' AS janela, * FROM `vanguardamartech_bajaj_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-JJJ4', 'SEMANA' AS janela, * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-rdCK', 'SEMANA' AS janela, * FROM `vanguardamartech_automaster_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-gWSW', 'SEMANA' AS janela, * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-K8dK', 'SEMANA' AS janela, * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-CeJD', 'SEMANA' AS janela, * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-Wajn', 'SEMANA' AS janela, * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-oMgW', 'SEMANA' AS janela, * FROM `vanguardamartech_ac_display_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-rRTe', 'SEMANA' AS janela, * FROM `vanguardamartech_santo_remedio_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-qZ4y', 'SEMANA' AS janela, * FROM `vanguardamartech_facilitti_motors_lovol_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-aXHi', 'SEMANA' AS janela, * FROM `vanguardamartech_linvest_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-O5dx', 'SEMANA' AS janela, * FROM `vanguardamartech_dr_bruno_maciel_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-yHk3', 'SEMANA' AS janela, * FROM `vanguardamartech_arena_tintas_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-A90g', 'SEMANA' AS janela, * FROM `vanguardamartech_braga_motos_consorcio_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-GM0j', 'SEMANA' AS janela, * FROM `vanguardamartech_braga_motos_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-0iTW', 'SEMANA' AS janela, * FROM `vanguardamartech_voike_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-nNtj', 'SEMANA' AS janela, * FROM `vanguardamartech_vbot_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-SOcs', 'SEMANA' AS janela, * FROM `vanguardamartech_vanguarda_growth_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-TjbI', 'SEMANA' AS janela, * FROM `vanguardamartech_unipar_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-Nez2', 'SEMANA' AS janela, * FROM `vanguardamartech_targo_consultoria_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-F6S4', 'SEMANA' AS janela, * FROM `vanguardamartech_steel_port_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-VhPH', 'SEMANA' AS janela, * FROM `vanguardamartech_smile_pneus_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-h56D', 'SEMANA' AS janela, * FROM `vanguardamartech_royal_enfield_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-TdQm', 'SEMANA' AS janela, * FROM `vanguardamartech_rodrix_motos_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-f6Fx', 'SEMANA' AS janela, * FROM `vanguardamartech_rei_das_mangueiras_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-0Eez', 'SEMANA' AS janela, * FROM `vanguardamartech_pneu_forte_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-pdgp', 'SEMANA' AS janela, * FROM `vanguardamartech_pneu_forte_distribuidora_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-2Xhl', 'SEMANA' AS janela, * FROM `vanguardamartech_pneu_express_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-6RO6', 'SEMANA' AS janela, * FROM `vanguardamartech_orla_92_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-LkfW', 'SEMANA' AS janela, * FROM `vanguardamartech_move_rental_cars_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-Wl0q', 'SEMANA' AS janela, * FROM `vanguardamartech_millennium_shopping_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-aRFK', 'SEMANA' AS janela, * FROM `vanguardamartech_maravilha_motos_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-Bir8', 'SEMANA' AS janela, * FROM `vanguardamartech_legacy_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-kmsm', 'SEMANA' AS janela, * FROM `vanguardamartech_leapmotor_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-Etq7', 'SEMANA' AS janela, * FROM `vanguardamartech_kl_rent_a_car_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-7DrB', 'SEMANA' AS janela, * FROM `vanguardamartech_kiffer_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-dFGL', 'SEMANA' AS janela, * FROM `vanguardamartech_inforcell_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-Zf3I', 'SEMANA' AS janela, * FROM `vanguardamartech_hospital_santa_julia_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-FIeB', 'SEMANA' AS janela, * FROM `vanguardamartech_hage_alimentos_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-8tL4', 'SEMANA' AS janela, * FROM `vanguardamartech_grupo_pmz_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-CBsl', 'SEMANA' AS janela, * FROM `vanguardamartech_charao_tributario_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-Juyc', 'SEMANA' AS janela, * FROM `vanguardamartech_charao_consultoria_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-zvUO', 'SEMANA' AS janela, * FROM `vanguardamartech_eduardo_charao_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-9JVu', 'SEMANA' AS janela, * FROM `vanguardamartech_escola_pmz_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-ZnP5', 'SEMANA' AS janela, * FROM `vanguardamartech_dr_jose_cabral_jr_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-2GLM', 'SEMANA' AS janela, * FROM `vanguardamartech_doctor_mais_saude_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-MBgH', 'SEMANA' AS janela, * FROM `vanguardamartech_constroi_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-jBXA', 'SEMANA' AS janela, * FROM `vanguardamartech_comac_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-2Ory', 'SEMANA' AS janela, * FROM `vanguardamartech_cdl_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-cyHw', 'SEMANA' AS janela, * FROM `vanguardamartech_caa_tintas_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-zCtu', 'SEMANA' AS janela, * FROM `vanguardamartech_caa_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-Y5iQ', 'SEMANA' AS janela, * FROM `vanguardamartech_braga_veiculos_varejo_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-FlJc', 'SEMANA' AS janela, * FROM `vanguardamartech_best_car_instagram`.`instagram_insights_rolling_week`
  UNION ALL SELECT 'instagram-gPUO', 'SEMANA' AS janela, * FROM `vanguardamartech_animativ_instagram`.`instagram_insights_rolling_week`
  UNION ALL
  SELECT 'instagram-wRZ1' AS _fonte, '28_DIAS' AS janela, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-CfH8', '28_DIAS' AS janela, * FROM `vanguardamartech_braga_motors_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-IZTB', '28_DIAS' AS janela, * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-bv3u', '28_DIAS' AS janela, * FROM `vanguardamartech_bap_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-209E', '28_DIAS' AS janela, * FROM `vanguardamartech_bajaj_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-JJJ4', '28_DIAS' AS janela, * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-rdCK', '28_DIAS' AS janela, * FROM `vanguardamartech_automaster_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-gWSW', '28_DIAS' AS janela, * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-K8dK', '28_DIAS' AS janela, * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-CeJD', '28_DIAS' AS janela, * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-Wajn', '28_DIAS' AS janela, * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-oMgW', '28_DIAS' AS janela, * FROM `vanguardamartech_ac_display_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-rRTe', '28_DIAS' AS janela, * FROM `vanguardamartech_santo_remedio_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-qZ4y', '28_DIAS' AS janela, * FROM `vanguardamartech_facilitti_motors_lovol_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-aXHi', '28_DIAS' AS janela, * FROM `vanguardamartech_linvest_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-O5dx', '28_DIAS' AS janela, * FROM `vanguardamartech_dr_bruno_maciel_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-yHk3', '28_DIAS' AS janela, * FROM `vanguardamartech_arena_tintas_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-A90g', '28_DIAS' AS janela, * FROM `vanguardamartech_braga_motos_consorcio_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-GM0j', '28_DIAS' AS janela, * FROM `vanguardamartech_braga_motos_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-0iTW', '28_DIAS' AS janela, * FROM `vanguardamartech_voike_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-nNtj', '28_DIAS' AS janela, * FROM `vanguardamartech_vbot_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-SOcs', '28_DIAS' AS janela, * FROM `vanguardamartech_vanguarda_growth_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-TjbI', '28_DIAS' AS janela, * FROM `vanguardamartech_unipar_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-Nez2', '28_DIAS' AS janela, * FROM `vanguardamartech_targo_consultoria_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-F6S4', '28_DIAS' AS janela, * FROM `vanguardamartech_steel_port_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-VhPH', '28_DIAS' AS janela, * FROM `vanguardamartech_smile_pneus_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-h56D', '28_DIAS' AS janela, * FROM `vanguardamartech_royal_enfield_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-TdQm', '28_DIAS' AS janela, * FROM `vanguardamartech_rodrix_motos_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-f6Fx', '28_DIAS' AS janela, * FROM `vanguardamartech_rei_das_mangueiras_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-0Eez', '28_DIAS' AS janela, * FROM `vanguardamartech_pneu_forte_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-pdgp', '28_DIAS' AS janela, * FROM `vanguardamartech_pneu_forte_distribuidora_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-2Xhl', '28_DIAS' AS janela, * FROM `vanguardamartech_pneu_express_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-6RO6', '28_DIAS' AS janela, * FROM `vanguardamartech_orla_92_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-LkfW', '28_DIAS' AS janela, * FROM `vanguardamartech_move_rental_cars_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-Wl0q', '28_DIAS' AS janela, * FROM `vanguardamartech_millennium_shopping_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-aRFK', '28_DIAS' AS janela, * FROM `vanguardamartech_maravilha_motos_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-Bir8', '28_DIAS' AS janela, * FROM `vanguardamartech_legacy_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-kmsm', '28_DIAS' AS janela, * FROM `vanguardamartech_leapmotor_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-Etq7', '28_DIAS' AS janela, * FROM `vanguardamartech_kl_rent_a_car_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-7DrB', '28_DIAS' AS janela, * FROM `vanguardamartech_kiffer_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-dFGL', '28_DIAS' AS janela, * FROM `vanguardamartech_inforcell_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-Zf3I', '28_DIAS' AS janela, * FROM `vanguardamartech_hospital_santa_julia_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-FIeB', '28_DIAS' AS janela, * FROM `vanguardamartech_hage_alimentos_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-8tL4', '28_DIAS' AS janela, * FROM `vanguardamartech_grupo_pmz_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-CBsl', '28_DIAS' AS janela, * FROM `vanguardamartech_charao_tributario_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-Juyc', '28_DIAS' AS janela, * FROM `vanguardamartech_charao_consultoria_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-zvUO', '28_DIAS' AS janela, * FROM `vanguardamartech_eduardo_charao_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-9JVu', '28_DIAS' AS janela, * FROM `vanguardamartech_escola_pmz_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-ZnP5', '28_DIAS' AS janela, * FROM `vanguardamartech_dr_jose_cabral_jr_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-2GLM', '28_DIAS' AS janela, * FROM `vanguardamartech_doctor_mais_saude_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-MBgH', '28_DIAS' AS janela, * FROM `vanguardamartech_constroi_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-jBXA', '28_DIAS' AS janela, * FROM `vanguardamartech_comac_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-2Ory', '28_DIAS' AS janela, * FROM `vanguardamartech_cdl_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-cyHw', '28_DIAS' AS janela, * FROM `vanguardamartech_caa_tintas_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-zCtu', '28_DIAS' AS janela, * FROM `vanguardamartech_caa_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-Y5iQ', '28_DIAS' AS janela, * FROM `vanguardamartech_braga_veiculos_varejo_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-FlJc', '28_DIAS' AS janela, * FROM `vanguardamartech_best_car_instagram`.`instagram_insights_rolling_days28`
  UNION ALL SELECT 'instagram-gPUO', '28_DIAS' AS janela, * FROM `vanguardamartech_animativ_instagram`.`instagram_insights_rolling_days28`
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

  CONCAT(c.id_conta, ':', j.janela, ':', FORMAT_DATE('%Y-%m-%d', DATE(j.date))) AS id_insight_conta,
  c.id_conta,
  j.janela,
  DATE(j.date)                          AS data_fim_janela,
  j.reach                               AS alcance,
  j.views                               AS visualizacoes,
  j.total_interactions                  AS interacoes_totais,
  j.accounts_engaged                    AS contas_engajadas,
  j.likes                               AS curtidas,
  j.shares                              AS compartilhamentos,
  j.replies                             AS respostas,
  j.follows_and_unfollows               AS seguimentos_liquidos,
  j.follows                             AS seguimentos,
  j.unfollows                           AS deixaram_de_seguir,
  j.profile_links_taps                  AS toques_em_links_do_perfil,
  j.website_clicks                      AS cliques_no_site,
  j.profile_views                       AS visitas_ao_perfil,

  -- Marca o dia em que a API nao reportou movimento de seguidores (follows e unfollows
  -- zerados). Nos 5 dias 14/10 medidos e zero em 5 de 5; nos 12 dias 13/10, zero em 0 de 12.
  (j.follows = 0 AND j.unfollows = 0)   AS flag_sem_movimento_de_seguidores,
  CURRENT_TIMESTAMP()                   AS _extraido_at,
  j._fonte,
  TO_HEX(MD5(TO_JSON_STRING(j)))        AS _payload_hash
FROM j
JOIN c ON c._fonte = j._fonte
