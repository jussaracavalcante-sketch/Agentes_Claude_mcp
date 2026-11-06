-- rfn_qualidade__regra_meta_ativos - 64 regras - Refined / qualidade - L2 INTERNAL - 2026-10-18
-- Grao: uma REGRA em uma execucao. Cobre as 6 Trusted de ativos e atividade do Meta Ads (imagem, video, rotulo, publico_personalizado,
-- conversao_personalizada, atividade_conta) e as 2 Refined rfn_midia__meta_ativos_conta e rfn_midia__meta_atividade_mensal.
-- Gatilho: evento com regra all nas duas Refined (query-laCR e query-qeZA), o ultimo elo da cadeia (cron terca 13:40 America/Manaus).
-- Contrato de colunas identico ao das outras suites (UNION ALL da o painel unico; familia = META_ATIVOS). Alerta de falha ligado.
-- A lista de Raw (70 fontes desde 2026-10-29) e FIXA: conta nova integrada entra nas Trusted E aqui, senao a identidade por fonte nao a cobre.
-- Validada em 2026-10-18 reproduzindo a logica das Trusted e das Refined sobre a Raw de 3 fontes (AJ09, GZtZ, 2vvw): 64 regras, 64 conformes.
-- ATUALIZACAO 2026-10-29: tWIP (FARMABEM) e bU6W (CA Braga Motos 2) entraram nas Trusted de imagem (as duas), publico (as duas), video (so bU6W) e atividade (so bU6W); a lista de Raw acompanha: raw_img +2, raw_vid +1, raw_pub +2, raw_atv +1. Rotulo e conversao personalizada nao mudam (0 linhas nas duas).
WITH
raw_img AS (SELECT COUNT(DISTINCT k) AS n_raw FROM (
  SELECT id AS k FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudeadimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragaadimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojaadimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiaadimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_best_car`.`facebook_ads_best_caradimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneusadimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_ca2_move_rental_cars_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_millennium_shopping_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_acesso_saude_manoa_1_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_auto_master_consorcio_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_farmabem_fb_ads`.`facebook_ads_adimages` UNION ALL
  SELECT id AS k FROM `vanguardamartech_ca_braga_motos_2_fb_ads`.`facebook_ads_adimages`
)),
raw_vid AS (SELECT _fonte, COUNT(DISTINCT k) AS n_raw FROM (
  SELECT 'facebook-ads-Si4U' AS _fonte, id AS k FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudeadvideos` UNION ALL
  SELECT 'facebook-ads-kQ2S' AS _fonte, id AS k FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragaadvideos` UNION ALL
  SELECT 'facebook-ads-GWZ2' AS _fonte, id AS k FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_advideos` UNION ALL
  SELECT 'facebook-ads-x4yO' AS _fonte, id AS k FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojaadvideos` UNION ALL
  SELECT 'facebook-ads-ln1a' AS _fonte, id AS k FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiaadvideos` UNION ALL
  SELECT 'facebook-ads-E9RT' AS _fonte, id AS k FROM `vanguardamartech_best_car`.`facebook_ads_best_caradvideos` UNION ALL
  SELECT 'facebook-ads-oB7d' AS _fonte, id AS k FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-8RYU' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-ezGP' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-b8KQ' AS _fonte, id AS k FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-rCHw' AS _fonte, id AS k FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-CebU' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-jZBq' AS _fonte, id AS k FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-5eAs' AS _fonte, id AS k FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-aghZ' AS _fonte, id AS k FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-Vgli' AS _fonte, id AS k FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-WQmP' AS _fonte, id AS k FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-nCGL' AS _fonte, id AS k FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-K2kh' AS _fonte, id AS k FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-TAqE' AS _fonte, id AS k FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-omn8' AS _fonte, id AS k FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-2vvw' AS _fonte, id AS k FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-tzO2' AS _fonte, id AS k FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-s8I1' AS _fonte, id AS k FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-oVkz' AS _fonte, id AS k FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-phtv' AS _fonte, id AS k FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-rPr1' AS _fonte, id AS k FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-p8vg' AS _fonte, id AS k FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-ofJE' AS _fonte, id AS k FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-aiXX' AS _fonte, id AS k FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-ZYCB' AS _fonte, id AS k FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-Hr6d' AS _fonte, id AS k FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-oaSa' AS _fonte, id AS k FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-tWUr' AS _fonte, id AS k FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-d1nc' AS _fonte, id AS k FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-Eo68' AS _fonte, id AS k FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-SGls' AS _fonte, id AS k FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-lDmk' AS _fonte, id AS k FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-Ew4q' AS _fonte, id AS k FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-oih2' AS _fonte, id AS k FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-lk1y' AS _fonte, id AS k FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-cETo' AS _fonte, id AS k FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-mtAO' AS _fonte, id AS k FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-pbon' AS _fonte, id AS k FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-4Q1U' AS _fonte, id AS k FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-DtiV' AS _fonte, id AS k FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-yFhV' AS _fonte, id AS k FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-Uu0D' AS _fonte, id AS k FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-0rrE' AS _fonte, id AS k FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-sHYk' AS _fonte, id AS k FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-bIVn' AS _fonte, id AS k FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-3vys' AS _fonte, id AS k FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-xohe' AS _fonte, id AS k FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-Tqjf' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-ckhA' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-smxd' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-elFk' AS _fonte, id AS k FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-VJeY' AS _fonte, id AS k FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-AJ09' AS _fonte, id AS k FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-KBUT' AS _fonte, id AS k FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-hIaw' AS _fonte, id AS k FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-7NkZ' AS _fonte, id AS k FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-I8ld' AS _fonte, id AS k FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-GZtZ' AS _fonte, id AS k FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneusadvideos` UNION ALL
  SELECT 'facebook-ads-T0qp' AS _fonte, id AS k FROM `vanguardamartech_ca2_move_rental_cars_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-fK2P' AS _fonte, id AS k FROM `vanguardamartech_millennium_shopping_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-WOOU' AS _fonte, id AS k FROM `vanguardamartech_acesso_saude_manoa_1_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-wZuX' AS _fonte, id AS k FROM `vanguardamartech_auto_master_consorcio_fb_ads`.`facebook_ads_advideos` UNION ALL
  SELECT 'facebook-ads-bU6W' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_motos_2_fb_ads`.`facebook_ads_advideos`
) GROUP BY 1),
raw_rot AS (SELECT _fonte, COUNT(DISTINCT k) AS n_raw FROM (
  SELECT 'facebook-ads-Si4U' AS _fonte, id AS k FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudeadlabels` UNION ALL
  SELECT 'facebook-ads-kQ2S' AS _fonte, id AS k FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragaadlabels` UNION ALL
  SELECT 'facebook-ads-GWZ2' AS _fonte, id AS k FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_adlabels` UNION ALL
  SELECT 'facebook-ads-x4yO' AS _fonte, id AS k FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojaadlabels` UNION ALL
  SELECT 'facebook-ads-ln1a' AS _fonte, id AS k FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiaadlabels` UNION ALL
  SELECT 'facebook-ads-E9RT' AS _fonte, id AS k FROM `vanguardamartech_best_car`.`facebook_ads_best_caradlabels` UNION ALL
  SELECT 'facebook-ads-oB7d' AS _fonte, id AS k FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-8RYU' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-ezGP' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-b8KQ' AS _fonte, id AS k FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-rCHw' AS _fonte, id AS k FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-CebU' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-jZBq' AS _fonte, id AS k FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-5eAs' AS _fonte, id AS k FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-aghZ' AS _fonte, id AS k FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-Vgli' AS _fonte, id AS k FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-WQmP' AS _fonte, id AS k FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-nCGL' AS _fonte, id AS k FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-K2kh' AS _fonte, id AS k FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-TAqE' AS _fonte, id AS k FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-omn8' AS _fonte, id AS k FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-2vvw' AS _fonte, id AS k FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-tzO2' AS _fonte, id AS k FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-s8I1' AS _fonte, id AS k FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-oVkz' AS _fonte, id AS k FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-phtv' AS _fonte, id AS k FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-rPr1' AS _fonte, id AS k FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-p8vg' AS _fonte, id AS k FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-ofJE' AS _fonte, id AS k FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-aiXX' AS _fonte, id AS k FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-ZYCB' AS _fonte, id AS k FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-Hr6d' AS _fonte, id AS k FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-oaSa' AS _fonte, id AS k FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-tWUr' AS _fonte, id AS k FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-d1nc' AS _fonte, id AS k FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-Eo68' AS _fonte, id AS k FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-SGls' AS _fonte, id AS k FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-lDmk' AS _fonte, id AS k FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-Ew4q' AS _fonte, id AS k FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-oih2' AS _fonte, id AS k FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-lk1y' AS _fonte, id AS k FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-cETo' AS _fonte, id AS k FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-mtAO' AS _fonte, id AS k FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-pbon' AS _fonte, id AS k FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-4Q1U' AS _fonte, id AS k FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-DtiV' AS _fonte, id AS k FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-yFhV' AS _fonte, id AS k FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-Uu0D' AS _fonte, id AS k FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-0rrE' AS _fonte, id AS k FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-sHYk' AS _fonte, id AS k FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-bIVn' AS _fonte, id AS k FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-3vys' AS _fonte, id AS k FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-xohe' AS _fonte, id AS k FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-Tqjf' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-ckhA' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-smxd' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-elFk' AS _fonte, id AS k FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-VJeY' AS _fonte, id AS k FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-AJ09' AS _fonte, id AS k FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-KBUT' AS _fonte, id AS k FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-hIaw' AS _fonte, id AS k FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-7NkZ' AS _fonte, id AS k FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-I8ld' AS _fonte, id AS k FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-GZtZ' AS _fonte, id AS k FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneusadlabels` UNION ALL
  SELECT 'facebook-ads-T0qp' AS _fonte, id AS k FROM `vanguardamartech_ca2_move_rental_cars_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-fK2P' AS _fonte, id AS k FROM `vanguardamartech_millennium_shopping_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-WOOU' AS _fonte, id AS k FROM `vanguardamartech_acesso_saude_manoa_1_fb_ads`.`facebook_ads_adlabels` UNION ALL
  SELECT 'facebook-ads-wZuX' AS _fonte, id AS k FROM `vanguardamartech_auto_master_consorcio_fb_ads`.`facebook_ads_adlabels`
) GROUP BY 1),
raw_pub AS (SELECT _fonte, COUNT(DISTINCT k) AS n_raw FROM (
  SELECT 'facebook-ads-Si4U' AS _fonte, id AS k FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudecustomaudiences` UNION ALL
  SELECT 'facebook-ads-kQ2S' AS _fonte, id AS k FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragacustomaudiences` UNION ALL
  SELECT 'facebook-ads-GWZ2' AS _fonte, id AS k FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_customaudiences` UNION ALL
  SELECT 'facebook-ads-x4yO' AS _fonte, id AS k FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojacustomaudiences` UNION ALL
  SELECT 'facebook-ads-ln1a' AS _fonte, id AS k FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiacustomaudiences` UNION ALL
  SELECT 'facebook-ads-E9RT' AS _fonte, id AS k FROM `vanguardamartech_best_car`.`facebook_ads_best_carcustomaudiences` UNION ALL
  SELECT 'facebook-ads-oB7d' AS _fonte, id AS k FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-8RYU' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-ezGP' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-b8KQ' AS _fonte, id AS k FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-rCHw' AS _fonte, id AS k FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-CebU' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-jZBq' AS _fonte, id AS k FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-5eAs' AS _fonte, id AS k FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-aghZ' AS _fonte, id AS k FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-Vgli' AS _fonte, id AS k FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-WQmP' AS _fonte, id AS k FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-nCGL' AS _fonte, id AS k FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-K2kh' AS _fonte, id AS k FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-TAqE' AS _fonte, id AS k FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-omn8' AS _fonte, id AS k FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-2vvw' AS _fonte, id AS k FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-tzO2' AS _fonte, id AS k FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-s8I1' AS _fonte, id AS k FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-oVkz' AS _fonte, id AS k FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-phtv' AS _fonte, id AS k FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-rPr1' AS _fonte, id AS k FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-p8vg' AS _fonte, id AS k FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-ofJE' AS _fonte, id AS k FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-aiXX' AS _fonte, id AS k FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-ZYCB' AS _fonte, id AS k FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-Hr6d' AS _fonte, id AS k FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-oaSa' AS _fonte, id AS k FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-tWUr' AS _fonte, id AS k FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-d1nc' AS _fonte, id AS k FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-Eo68' AS _fonte, id AS k FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-SGls' AS _fonte, id AS k FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-lDmk' AS _fonte, id AS k FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-Ew4q' AS _fonte, id AS k FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-oih2' AS _fonte, id AS k FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-lk1y' AS _fonte, id AS k FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-cETo' AS _fonte, id AS k FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-mtAO' AS _fonte, id AS k FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-pbon' AS _fonte, id AS k FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-4Q1U' AS _fonte, id AS k FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-DtiV' AS _fonte, id AS k FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-yFhV' AS _fonte, id AS k FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-Uu0D' AS _fonte, id AS k FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-0rrE' AS _fonte, id AS k FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-sHYk' AS _fonte, id AS k FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-bIVn' AS _fonte, id AS k FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-3vys' AS _fonte, id AS k FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-xohe' AS _fonte, id AS k FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-Tqjf' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-ckhA' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-smxd' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-elFk' AS _fonte, id AS k FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-VJeY' AS _fonte, id AS k FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-AJ09' AS _fonte, id AS k FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-KBUT' AS _fonte, id AS k FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-hIaw' AS _fonte, id AS k FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-7NkZ' AS _fonte, id AS k FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-I8ld' AS _fonte, id AS k FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-GZtZ' AS _fonte, id AS k FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneuscustomaudiences` UNION ALL
  SELECT 'facebook-ads-T0qp' AS _fonte, id AS k FROM `vanguardamartech_ca2_move_rental_cars_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-fK2P' AS _fonte, id AS k FROM `vanguardamartech_millennium_shopping_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-WOOU' AS _fonte, id AS k FROM `vanguardamartech_acesso_saude_manoa_1_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-wZuX' AS _fonte, id AS k FROM `vanguardamartech_auto_master_consorcio_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-tWIP' AS _fonte, id AS k FROM `vanguardamartech_farmabem_fb_ads`.`facebook_ads_customaudiences` UNION ALL
  SELECT 'facebook-ads-bU6W' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_motos_2_fb_ads`.`facebook_ads_customaudiences`
) GROUP BY 1),
raw_cnv AS (SELECT _fonte, COUNT(DISTINCT k) AS n_raw FROM (
  SELECT 'facebook-ads-Si4U' AS _fonte, id AS k FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudecustomconversions` UNION ALL
  SELECT 'facebook-ads-kQ2S' AS _fonte, id AS k FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragacustomconversions` UNION ALL
  SELECT 'facebook-ads-GWZ2' AS _fonte, id AS k FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_customconversions` UNION ALL
  SELECT 'facebook-ads-x4yO' AS _fonte, id AS k FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojacustomconversions` UNION ALL
  SELECT 'facebook-ads-ln1a' AS _fonte, id AS k FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiacustomconversions` UNION ALL
  SELECT 'facebook-ads-E9RT' AS _fonte, id AS k FROM `vanguardamartech_best_car`.`facebook_ads_best_carcustomconversions` UNION ALL
  SELECT 'facebook-ads-oB7d' AS _fonte, id AS k FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-8RYU' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-ezGP' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-b8KQ' AS _fonte, id AS k FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-rCHw' AS _fonte, id AS k FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-CebU' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-jZBq' AS _fonte, id AS k FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-5eAs' AS _fonte, id AS k FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-aghZ' AS _fonte, id AS k FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-Vgli' AS _fonte, id AS k FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-WQmP' AS _fonte, id AS k FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-nCGL' AS _fonte, id AS k FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-K2kh' AS _fonte, id AS k FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-TAqE' AS _fonte, id AS k FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-omn8' AS _fonte, id AS k FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-2vvw' AS _fonte, id AS k FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-tzO2' AS _fonte, id AS k FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-s8I1' AS _fonte, id AS k FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-oVkz' AS _fonte, id AS k FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-phtv' AS _fonte, id AS k FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-rPr1' AS _fonte, id AS k FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-p8vg' AS _fonte, id AS k FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-ofJE' AS _fonte, id AS k FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-aiXX' AS _fonte, id AS k FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-ZYCB' AS _fonte, id AS k FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-Hr6d' AS _fonte, id AS k FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-oaSa' AS _fonte, id AS k FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-tWUr' AS _fonte, id AS k FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-d1nc' AS _fonte, id AS k FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-Eo68' AS _fonte, id AS k FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-SGls' AS _fonte, id AS k FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-lDmk' AS _fonte, id AS k FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-Ew4q' AS _fonte, id AS k FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-oih2' AS _fonte, id AS k FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-lk1y' AS _fonte, id AS k FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-cETo' AS _fonte, id AS k FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-mtAO' AS _fonte, id AS k FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-pbon' AS _fonte, id AS k FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-4Q1U' AS _fonte, id AS k FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-DtiV' AS _fonte, id AS k FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-yFhV' AS _fonte, id AS k FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-Uu0D' AS _fonte, id AS k FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-0rrE' AS _fonte, id AS k FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-sHYk' AS _fonte, id AS k FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-bIVn' AS _fonte, id AS k FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-3vys' AS _fonte, id AS k FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-xohe' AS _fonte, id AS k FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-Tqjf' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-ckhA' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-smxd' AS _fonte, id AS k FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-elFk' AS _fonte, id AS k FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-VJeY' AS _fonte, id AS k FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-AJ09' AS _fonte, id AS k FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-KBUT' AS _fonte, id AS k FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-hIaw' AS _fonte, id AS k FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-7NkZ' AS _fonte, id AS k FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-I8ld' AS _fonte, id AS k FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-GZtZ' AS _fonte, id AS k FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneuscustomconversions` UNION ALL
  SELECT 'facebook-ads-T0qp' AS _fonte, id AS k FROM `vanguardamartech_ca2_move_rental_cars_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-fK2P' AS _fonte, id AS k FROM `vanguardamartech_millennium_shopping_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-WOOU' AS _fonte, id AS k FROM `vanguardamartech_acesso_saude_manoa_1_fb_ads`.`facebook_ads_customconversions` UNION ALL
  SELECT 'facebook-ads-wZuX' AS _fonte, id AS k FROM `vanguardamartech_auto_master_consorcio_fb_ads`.`facebook_ads_customconversions`
) GROUP BY 1),
raw_atv AS (SELECT _fonte, COUNT(DISTINCT k) AS n_raw FROM (
  SELECT 'facebook-ads-Si4U' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudeactivities` UNION ALL
  SELECT 'facebook-ads-kQ2S' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragaactivities` UNION ALL
  SELECT 'facebook-ads-GWZ2' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_activities` UNION ALL
  SELECT 'facebook-ads-x4yO' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojaactivities` UNION ALL
  SELECT 'facebook-ads-ln1a' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiaactivities` UNION ALL
  SELECT 'facebook-ads-E9RT' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_best_car`.`facebook_ads_best_caractivities` UNION ALL
  SELECT 'facebook-ads-oB7d' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-8RYU' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-ezGP' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-b8KQ' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-rCHw' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-CebU' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-jZBq' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-5eAs' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-aghZ' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-Vgli' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-WQmP' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-nCGL' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-K2kh' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-TAqE' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-omn8' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-2vvw' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-tzO2' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-s8I1' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-oVkz' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-phtv' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-rPr1' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-p8vg' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-ofJE' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-aiXX' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-ZYCB' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-Hr6d' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-oaSa' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-tWUr' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-d1nc' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-Eo68' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-SGls' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-lDmk' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-Ew4q' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-oih2' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-lk1y' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-cETo' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-mtAO' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-pbon' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-4Q1U' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-DtiV' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-yFhV' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-Uu0D' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-0rrE' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-sHYk' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-bIVn' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-3vys' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-xohe' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-Tqjf' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-ckhA' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-smxd' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-elFk' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-VJeY' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-AJ09' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-KBUT' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-hIaw' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-7NkZ' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-I8ld' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-GZtZ' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneusactivities` UNION ALL
  SELECT 'facebook-ads-T0qp' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_ca2_move_rental_cars_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-fK2P' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_millennium_shopping_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-WOOU' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_acesso_saude_manoa_1_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-wZuX' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_auto_master_consorcio_fb_ads`.`facebook_ads_activities` UNION ALL
  SELECT 'facebook-ads-bU6W' AS _fonte, CONCAT(event_time, '|', event_type, '|', IFNULL(actor_id, ''), '|', IFNULL(extra_data, '')) AS k FROM `vanguardamartech_ca_braga_motos_2_fb_ads`.`facebook_ads_activities`
) GROUP BY 1),
cmp_vid AS (SELECT COALESCE(r._fonte, t._fonte) AS _fonte, r.n_raw, t.n_tr FROM raw_vid r FULL OUTER JOIN (SELECT _fonte, COUNT(*) AS n_tr FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__video` GROUP BY 1) t ON t._fonte = r._fonte),
cmp_rot AS (SELECT COALESCE(r._fonte, t._fonte) AS _fonte, r.n_raw, t.n_tr FROM raw_rot r FULL OUTER JOIN (SELECT _fonte, COUNT(*) AS n_tr FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__rotulo` GROUP BY 1) t ON t._fonte = r._fonte),
cmp_pub AS (SELECT COALESCE(r._fonte, t._fonte) AS _fonte, r.n_raw, t.n_tr FROM raw_pub r FULL OUTER JOIN (SELECT _fonte, COUNT(*) AS n_tr FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__publico_personalizado` GROUP BY 1) t ON t._fonte = r._fonte),
cmp_cnv AS (SELECT COALESCE(r._fonte, t._fonte) AS _fonte, r.n_raw, t.n_tr FROM raw_cnv r FULL OUTER JOIN (SELECT _fonte, COUNT(*) AS n_tr FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conversao_personalizada` GROUP BY 1) t ON t._fonte = r._fonte),
cmp_atv AS (SELECT COALESCE(r._fonte, t._fonte) AS _fonte, r.n_raw, t.n_tr FROM raw_atv r FULL OUTER JOIN (SELECT _fonte, COUNT(*) AS n_tr FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__atividade_conta` GROUP BY 1) t ON t._fonte = r._fonte),
ra AS (SELECT * FROM `vanguardamartech_refined`.`rfn_midia__meta_ativos_conta`),
rm AS (SELECT * FROM `vanguardamartech_refined`.`rfn_midia__meta_atividade_mensal`),
r AS (
  SELECT 'trs_facebook_ads__imagem.id_imagem_unico' AS id_regra, 'Trusted' AS camada, 'trs_facebook_ads__imagem' AS tabela, 'Meta Ads' AS sistema, 'UNICIDADE' AS dimensao,
         'id_imagem e unico e nunca nulo (a mesma imagem vem de uma so conta)' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_imagem) + COUNTIF(id_imagem IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__imagem`
  UNION ALL SELECT 'trs_facebook_ads__imagem.linhas_reproduzem_a_raw', 'Trusted', 'trs_facebook_ads__imagem', 'Meta Ads', 'VALIDADE',
         'as imagens distintas da Raw das 70 fontes reproduzem as linhas da Trusted (a consolidacao nao perde nem inventa imagem)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT n_raw FROM raw_img) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__imagem`), 1, 0)
  UNION ALL SELECT 'trs_facebook_ads__imagem.conta_preenchida', 'Trusted', 'trs_facebook_ads__imagem', 'Meta Ads', 'COMPLETUDE',
         'toda imagem tem conta (a do registro, ou a da fonte quando o registro nao traz)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(id_conta IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__imagem`
  UNION ALL SELECT 'trs_facebook_ads__imagem.conta_catalogada', 'Trusted', 'trs_facebook_ads__imagem', 'Meta Ads', 'INTEGRIDADE',
         'a conta da imagem existe em trs_facebook_ads__conta (linha de base: a dimensao e estatica)', 'ALERTA', 0.95,
         COUNT(*), COUNTIF(d.id_conta IS NULL)
  FROM (SELECT DISTINCT id_conta FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__imagem`) i LEFT JOIN `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conta` d ON d.id_conta = i.id_conta
  UNION ALL SELECT 'trs_facebook_ads__imagem.dimensao_positiva', 'Trusted', 'trs_facebook_ads__imagem', 'Meta Ads', 'VALIDADE',
         'largura e altura nunca sao zero nem negativas', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(largura <= 0 OR altura <= 0)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__imagem`
  UNION ALL SELECT 'trs_facebook_ads__imagem.criada_nao_futura', 'Trusted', 'trs_facebook_ads__imagem', 'Meta Ads', 'VALIDADE',
         'a imagem nao e criada no futuro', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(criada_utc > CURRENT_TIMESTAMP())
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__imagem`
  UNION ALL SELECT 'trs_facebook_ads__imagem.criativo_concorda_com_a_lista', 'Trusted', 'trs_facebook_ads__imagem', 'Meta Ads', 'VALIDADE',
         'tem_criativo e exatamente lista de criativos nao vazia (lista nula conta como vazia)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(tem_criativo IS DISTINCT FROM (IFNULL(ARRAY_LENGTH(ids_criativos), 0) > 0))
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__imagem`
  UNION ALL SELECT 'trs_facebook_ads__imagem.conta_do_registro_igual_a_da_fonte', 'Trusted', 'trs_facebook_ads__imagem', 'Meta Ads', 'INTEGRIDADE',
         'a imagem pertence a conta da fonte que a leu (linha de base: imagem compartilhada vem com outra conta)', 'ALERTA', 0.95,
         COUNT(*), COUNTIF(flag_conta_diverge_da_fonte)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__imagem`
  UNION ALL SELECT 'trs_facebook_ads__video.video_unico', 'Trusted', 'trs_facebook_ads__video', 'Meta Ads', 'UNICIDADE',
         'a chave (fonte, id_video) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(_fonte, "|", id_video)) + COUNTIF(id_video IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__video`
  UNION ALL SELECT 'trs_facebook_ads__video.linhas_por_fonte_reproduzem_a_raw', 'Trusted', 'trs_facebook_ads__video', 'Meta Ads', 'VALIDADE',
         'cada fonte tem na Trusted exatamente os videos distintos que tem na Raw', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(n_raw IS NULL OR n_tr IS NULL OR n_raw <> n_tr)
  FROM cmp_vid
  UNION ALL SELECT 'trs_facebook_ads__video.conta_preenchida', 'Trusted', 'trs_facebook_ads__video', 'Meta Ads', 'COMPLETUDE',
         'todo video tem conta (a da fonte)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(id_conta IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__video`
  UNION ALL SELECT 'trs_facebook_ads__video.metricas_nao_negativas', 'Trusted', 'trs_facebook_ads__video', 'Meta Ads', 'VALIDADE',
         'duracao e visualizacoes nunca sao negativas', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(duracao_seg < 0 OR visualizacoes < 0 OR visualizacoes_post < 0)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__video`
  UNION ALL SELECT 'trs_facebook_ads__video.criado_nao_futuro', 'Trusted', 'trs_facebook_ads__video', 'Meta Ads', 'VALIDADE',
         'o video nao e criado no futuro', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(criado_utc > CURRENT_TIMESTAMP())
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__video`
  UNION ALL SELECT 'trs_facebook_ads__rotulo.rotulo_unico', 'Trusted', 'trs_facebook_ads__rotulo', 'Meta Ads', 'UNICIDADE',
         'a chave (fonte, id_rotulo) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(_fonte, "|", id_rotulo)) + COUNTIF(id_rotulo IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__rotulo`
  UNION ALL SELECT 'trs_facebook_ads__rotulo.linhas_por_fonte_reproduzem_a_raw', 'Trusted', 'trs_facebook_ads__rotulo', 'Meta Ads', 'VALIDADE',
         'cada fonte tem na Trusted exatamente os rotulos distintos que tem na Raw', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(n_raw IS NULL OR n_tr IS NULL OR n_raw <> n_tr)
  FROM cmp_rot
  UNION ALL SELECT 'trs_facebook_ads__rotulo.automatico_concorda_com_o_nome', 'Trusted', 'trs_facebook_ads__rotulo', 'Meta Ads', 'VALIDADE',
         'rotulo automatico e exatamente nome que comeca com placement_asset_', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_rotulo_automatico_de_posicionamento IS DISTINCT FROM REGEXP_CONTAINS(nome, r"^placement_asset_"))
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__rotulo`
  UNION ALL SELECT 'trs_facebook_ads__rotulo.nome_preenchido', 'Trusted', 'trs_facebook_ads__rotulo', 'Meta Ads', 'COMPLETUDE',
         'todo rotulo tem nome', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(nome IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__rotulo`
  UNION ALL SELECT 'trs_facebook_ads__rotulo.conta_catalogada', 'Trusted', 'trs_facebook_ads__rotulo', 'Meta Ads', 'INTEGRIDADE',
         'a conta do rotulo existe em trs_facebook_ads__conta', 'ALERTA', 0.95,
         COUNT(*), COUNTIF(d.id_conta IS NULL)
  FROM (SELECT DISTINCT id_conta FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__rotulo`) i LEFT JOIN `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conta` d ON d.id_conta = i.id_conta
  UNION ALL SELECT 'trs_facebook_ads__publico_personalizado.publico_unico', 'Trusted', 'trs_facebook_ads__publico_personalizado', 'Meta Ads', 'UNICIDADE',
         'a chave (fonte, id_publico) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(_fonte, "|", id_publico)) + COUNTIF(id_publico IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__publico_personalizado`
  UNION ALL SELECT 'trs_facebook_ads__publico_personalizado.linhas_por_fonte_reproduzem_a_raw', 'Trusted', 'trs_facebook_ads__publico_personalizado', 'Meta Ads', 'VALIDADE',
         'cada fonte tem na Trusted exatamente os publicos distintos que tem na Raw', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(n_raw IS NULL OR n_tr IS NULL OR n_raw <> n_tr)
  FROM cmp_pub
  UNION ALL SELECT 'trs_facebook_ads__publico_personalizado.conta_da_fonte_preenchida', 'Trusted', 'trs_facebook_ads__publico_personalizado', 'Meta Ads', 'COMPLETUDE',
         'todo publico tem a conta da fonte que o enxerga (e a chave de agrupamento da Refined)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(id_conta_da_fonte IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__publico_personalizado`
  UNION ALL SELECT 'trs_facebook_ads__publico_personalizado.contagem_min_nao_excede_max', 'Trusted', 'trs_facebook_ads__publico_personalizado', 'Meta Ads', 'VALIDADE',
         'a contagem aproximada minima nunca passa da maxima', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_aprox_min > qtd_aprox_max)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__publico_personalizado`
  UNION ALL SELECT 'trs_facebook_ads__publico_personalizado.sentinela_nao_vaza', 'Trusted', 'trs_facebook_ads__publico_personalizado', 'Meta Ads', 'VALIDADE',
         'contagem -1, retencao zero e pixel 0 viram NULL e nunca chegam como valor', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_aprox_min < 0 OR qtd_aprox_max < 0 OR retencao_dias = 0 OR id_pixel = "0")
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__publico_personalizado`
  UNION ALL SELECT 'trs_facebook_ads__publico_personalizado.contagem_indisponivel_implica_nulo', 'Trusted', 'trs_facebook_ads__publico_personalizado', 'Meta Ads', 'VALIDADE',
         'flag_contagem_indisponivel so acende quando ao menos um dos limites ficou NULL', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_contagem_indisponivel AND qtd_aprox_min IS NOT NULL AND qtd_aprox_max IS NOT NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__publico_personalizado`
  UNION ALL SELECT 'trs_facebook_ads__publico_personalizado.semelhante_implica_a_flag', 'Trusted', 'trs_facebook_ads__publico_personalizado', 'Meta Ads', 'VALIDADE',
         'publico com razao de semelhanca sempre carrega is_semelhante', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(semelhante_razao IS NOT NULL AND NOT is_semelhante)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__publico_personalizado`
  UNION ALL SELECT 'trs_facebook_ads__conversao_personalizada.conversao_unica', 'Trusted', 'trs_facebook_ads__conversao_personalizada', 'Meta Ads', 'UNICIDADE',
         'a chave (fonte, id_conversao) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(_fonte, "|", id_conversao)) + COUNTIF(id_conversao IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conversao_personalizada`
  UNION ALL SELECT 'trs_facebook_ads__conversao_personalizada.linhas_por_fonte_reproduzem_a_raw', 'Trusted', 'trs_facebook_ads__conversao_personalizada', 'Meta Ads', 'VALIDADE',
         'cada fonte tem na Trusted exatamente as conversoes distintas que tem na Raw', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(n_raw IS NULL OR n_tr IS NULL OR n_raw <> n_tr)
  FROM cmp_cnv
  UNION ALL SELECT 'trs_facebook_ads__conversao_personalizada.nunca_disparou_concorda', 'Trusted', 'trs_facebook_ads__conversao_personalizada', 'Meta Ads', 'VALIDADE',
         'flag_nunca_disparou e exatamente ultimo disparo ausente', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_nunca_disparou IS DISTINCT FROM (ultimo_disparo_utc IS NULL))
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conversao_personalizada`
  UNION ALL SELECT 'trs_facebook_ads__conversao_personalizada.disparo_nao_antes_da_criacao', 'Trusted', 'trs_facebook_ads__conversao_personalizada', 'Meta Ads', 'VALIDADE',
         'o ultimo disparo nunca e anterior a criacao da conversao', 'ALERTA', 0.99,
         COUNT(*), COUNTIF(ultimo_disparo_utc < criada_utc)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conversao_personalizada`
  UNION ALL SELECT 'trs_facebook_ads__conversao_personalizada.conta_preenchida', 'Trusted', 'trs_facebook_ads__conversao_personalizada', 'Meta Ads', 'COMPLETUDE',
         'toda conversao tem conta', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(id_conta IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conversao_personalizada`
  UNION ALL SELECT 'trs_facebook_ads__atividade_conta.atividade_unica', 'Trusted', 'trs_facebook_ads__atividade_conta', 'Meta Ads', 'UNICIDADE',
         'id_atividade e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_atividade) + COUNTIF(id_atividade IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__atividade_conta`
  UNION ALL SELECT 'trs_facebook_ads__atividade_conta.linhas_por_fonte_reproduzem_a_raw', 'Trusted', 'trs_facebook_ads__atividade_conta', 'Meta Ads', 'VALIDADE',
         'cada fonte tem na Trusted exatamente os eventos distintos que tem na Raw', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(n_raw IS NULL OR n_tr IS NULL OR n_raw <> n_tr)
  FROM cmp_atv
  UNION ALL SELECT 'trs_facebook_ads__atividade_conta.conta_preenchida', 'Trusted', 'trs_facebook_ads__atividade_conta', 'Meta Ads', 'COMPLETUDE',
         'todo evento tem conta (a da fonte)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(id_conta IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__atividade_conta`
  UNION ALL SELECT 'trs_facebook_ads__atividade_conta.data_do_evento_valida', 'Trusted', 'trs_facebook_ads__atividade_conta', 'Meta Ads', 'VALIDADE',
         'event_time convertido: nenhum evento sem data e nenhum no futuro', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ocorrido_utc IS NULL OR ocorrido_utc > CURRENT_TIMESTAMP())
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__atividade_conta`
  UNION ALL SELECT 'trs_facebook_ads__atividade_conta.data_local_concorda_com_a_hora', 'Trusted', 'trs_facebook_ads__atividade_conta', 'Meta Ads', 'VALIDADE',
         'data_local e a data de ocorrido_em (o fuso Sao Paulo foi aplicado uma unica vez)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(data_local IS DISTINCT FROM DATE(ocorrido_em))
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__atividade_conta`
  UNION ALL SELECT 'trs_facebook_ads__atividade_conta.sistema_concorda_com_o_ator', 'Trusted', 'trs_facebook_ads__atividade_conta', 'Meta Ads', 'VALIDADE',
         'evento de sistema e exatamente evento sem ator (id zero na origem vira NULL)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_ator_sistema IS DISTINCT FROM (ator_id IS NULL))
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__atividade_conta`
  UNION ALL SELECT 'trs_facebook_ads__atividade_conta.valor_so_em_evento_financeiro', 'Trusted', 'trs_facebook_ads__atividade_conta', 'Meta Ads', 'VALIDADE',
         'valor e moeda financeiros so existem em evento de cobranca ou recarga', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF((financeiro_valor_unidade_menor IS NOT NULL OR financeiro_moeda IS NOT NULL) AND NOT flag_evento_financeiro)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__atividade_conta`
  UNION ALL SELECT 'trs_facebook_ads__atividade_conta.evento_financeiro_tem_valor', 'Trusted', 'trs_facebook_ads__atividade_conta', 'Meta Ads', 'COMPLETUDE',
         'evento financeiro traz valor e moeda extraidos do detalhe (linha de base: o conector nao os entrega)', 'ALERTA', 0.99,
         COUNTIF(flag_evento_financeiro), COUNTIF(flag_evento_financeiro AND (financeiro_valor_unidade_menor IS NULL OR financeiro_moeda IS NULL))
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__atividade_conta`
  UNION ALL SELECT 'rfn_midia__meta_atividade_mensal.chave_unica', 'Refined', 'rfn_midia__meta_atividade_mensal', 'Meta Ads', 'UNICIDADE',
         'id_atividade_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_atividade_mensal) + COUNTIF(id_atividade_mensal IS NULL)
  FROM rm
  UNION ALL SELECT 'rfn_midia__meta_atividade_mensal.eventos_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_atividade_mensal', 'Meta Ads', 'VALIDADE',
         'a soma de eventos reproduz a Trusted de atividade (a Refined agrega, nao filtra)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_eventos) FROM rm) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__atividade_conta`), 1, 0)
  UNION ALL SELECT 'rfn_midia__meta_atividade_mensal.eventos_por_conta_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_atividade_mensal', 'Meta Ads', 'VALIDADE',
         'os eventos de cada conta na Refined reproduzem os da Trusted (pega erro que se compensa entre contas)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(m.n IS NULL OR t.n IS NULL OR m.n <> t.n)
  FROM (SELECT id_conta, SUM(qtd_eventos) AS n FROM rm GROUP BY 1) m FULL OUTER JOIN (SELECT id_conta, COUNT(*) AS n FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__atividade_conta` GROUP BY 1) t ON t.id_conta = m.id_conta
  UNION ALL SELECT 'rfn_midia__meta_atividade_mensal.sistema_mais_pessoa_e_o_total', 'Refined', 'rfn_midia__meta_atividade_mensal', 'Meta Ads', 'VALIDADE',
         'eventos de sistema mais eventos de pessoa e exatamente o total da linha', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_eventos_de_sistema + qtd_eventos_de_pessoa <> qtd_eventos)
  FROM rm
  UNION ALL SELECT 'rfn_midia__meta_atividade_mensal.valor_reproduz_a_trusted', 'Refined', 'rfn_midia__meta_atividade_mensal', 'Meta Ads', 'VALIDADE',
         'a soma do valor financeiro reproduz a Trusted exatamente (menor unidade da moeda)', 'BLOQUEANTE', 1.00,
         1, IF(IFNULL((SELECT SUM(soma_valor_unidade_menor) FROM rm), 0) <> IFNULL((SELECT SUM(financeiro_valor_unidade_menor) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__atividade_conta`), 0), 1, 0)
  UNION ALL SELECT 'rfn_midia__meta_atividade_mensal.atores_nao_excedem_eventos_de_pessoa', 'Refined', 'rfn_midia__meta_atividade_mensal', 'Meta Ads', 'VALIDADE',
         'atores distintos nunca passam dos eventos de pessoa (so ha ator onde ha pessoa)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_atores_distintos > qtd_eventos_de_pessoa)
  FROM rm
  UNION ALL SELECT 'rfn_midia__meta_atividade_mensal.financeiro_com_valor_cabe_no_financeiro', 'Refined', 'rfn_midia__meta_atividade_mensal', 'Meta Ads', 'VALIDADE',
         'eventos financeiros com valor nunca passam dos financeiros, e valor so existe onde ha evento com valor', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_eventos_financeiros_com_valor > qtd_eventos_financeiros OR (soma_valor_unidade_menor IS NOT NULL AND qtd_eventos_financeiros_com_valor = 0))
  FROM rm
  UNION ALL SELECT 'rfn_midia__meta_atividade_mensal.mes_e_janela_coerentes', 'Refined', 'rfn_midia__meta_atividade_mensal', 'Meta Ads', 'VALIDADE',
         'o mes e o primeiro dia e os eventos da linha cabem dentro do mes', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(mes_referencia <> DATE_TRUNC(mes_referencia, MONTH) OR primeiro_evento_em < DATETIME(mes_referencia) OR ultimo_evento_em >= DATETIME(DATE_ADD(LAST_DAY(mes_referencia), INTERVAL 1 DAY)) OR qtd_dias_com_evento > DATE_DIFF(LAST_DAY(mes_referencia), mes_referencia, DAY) + 1)
  FROM rm
  UNION ALL SELECT 'rfn_midia__meta_atividade_mensal.conta_catalogada', 'Refined', 'rfn_midia__meta_atividade_mensal', 'Meta Ads', 'INTEGRIDADE',
         'toda linha resolve a conta na dimensao (conta nova sem dimensao acende aqui)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_conta_nao_catalogada)
  FROM rm
  UNION ALL SELECT 'rfn_midia__meta_atividade_mensal.tipo_de_evento_mapeado', 'Refined', 'rfn_midia__meta_atividade_mensal', 'Meta Ads', 'VALIDADE',
         'todo tipo de evento cai numa familia conhecida (a Meta cria tipos novos: o que cair em OUTRO pede ajuste do mapa)', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(flag_tipo_nao_mapeado)
  FROM rm
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.chave_unica', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'UNICIDADE',
         'id_conta e unico e nunca nulo (uma linha por conta)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_conta) + COUNTIF(id_conta IS NULL)
  FROM ra
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.imagens_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'VALIDADE',
         'a soma de imagens reproduz a Trusted de imagem (a Refined agrega, nao filtra)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_imagens) FROM ra) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__imagem`), 1, 0)
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.videos_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'VALIDADE',
         'a soma de videos reproduz a Trusted de video', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_videos) FROM ra) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__video`), 1, 0)
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.rotulos_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'VALIDADE',
         'a soma de rotulos reproduz a Trusted de rotulo', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_rotulos) FROM ra) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__rotulo`), 1, 0)
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.publicos_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'VALIDADE',
         'a soma de publicos visiveis reproduz a Trusted de publico', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_publicos_visiveis) FROM ra) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__publico_personalizado`), 1, 0)
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.conversoes_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'VALIDADE',
         'a soma de conversoes reproduz a Trusted de conversao', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_conversoes) FROM ra) <> (SELECT COUNT(*) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conversao_personalizada`), 1, 0)
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.imagens_por_conta_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'VALIDADE',
         'as imagens de cada conta na Refined reproduzem as da Trusted (pega erro que se compensa entre contas)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(m.n IS NULL OR t.n IS NULL OR m.n <> t.n)
  FROM (SELECT id_conta, SUM(qtd_imagens) AS n FROM ra WHERE qtd_imagens > 0 GROUP BY 1) m FULL OUTER JOIN (SELECT id_conta, COUNT(*) AS n FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__imagem` GROUP BY 1) t ON t.id_conta = m.id_conta
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.publicos_por_conta_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'VALIDADE',
         'os publicos de cada conta da fonte na Refined reproduzem os da Trusted', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(m.n IS NULL OR t.n IS NULL OR m.n <> t.n)
  FROM (SELECT id_conta, SUM(qtd_publicos_visiveis) AS n FROM ra WHERE qtd_publicos_visiveis > 0 GROUP BY 1) m FULL OUTER JOIN (SELECT id_conta_da_fonte AS id_conta, COUNT(*) AS n FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__publico_personalizado` GROUP BY 1) t ON t.id_conta = m.id_conta
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.imagem_com_mais_sem_criativo_e_o_total', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'VALIDADE',
         'imagens com criativo mais sem criativo e exatamente o total da linha', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_imagens_com_criativo + qtd_imagens_sem_criativo <> qtd_imagens)
  FROM ra
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.rotulo_automatico_mais_manual_e_o_total', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'VALIDADE',
         'rotulos automaticos mais manuais e exatamente o total da linha', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_rotulos_automaticos + qtd_rotulos_manuais <> qtd_rotulos)
  FROM ra
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.publico_proprio_mais_compartilhado_e_o_total', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'VALIDADE',
         'publicos proprios mais compartilhados e exatamente os visiveis', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_publicos_proprios + qtd_publicos_compartilhados <> qtd_publicos_visiveis)
  FROM ra
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.conversao_arquivada_mais_ativa_e_o_total', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'VALIDADE',
         'conversoes arquivadas mais ativas e exatamente o total da linha', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_conversoes_arquivadas + qtd_conversoes_ativas <> qtd_conversoes)
  FROM ra
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.taxa_entre_zero_e_um', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'VALIDADE',
         'a taxa de imagens com criativo fica entre 0 e 1 e e NULL so sem imagem', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(taxa_imagens_com_criativo < 0 OR taxa_imagens_com_criativo > 1 OR ((taxa_imagens_com_criativo IS NULL) <> (qtd_imagens = 0)))
  FROM ra
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.toda_conta_tem_ativo', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'VALIDADE',
         'toda linha tem ao menos um ativo de algum tipo (conta sem ativo nao entra)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_imagens + qtd_videos + qtd_rotulos + qtd_publicos_visiveis + qtd_conversoes = 0)
  FROM ra
  UNION ALL SELECT 'rfn_midia__meta_ativos_conta.conta_catalogada', 'Refined', 'rfn_midia__meta_ativos_conta', 'Meta Ads', 'INTEGRIDADE',
         'toda linha resolve a conta na dimensao (conta nova sem dimensao acende aqui)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_conta_nao_catalogada)
  FROM ra
  UNION ALL SELECT 'meta_ativos.carga_do_mesmo_dia', 'Refined', 'trs_facebook_ads__* e rfn_midia__meta_*', 'Meta Ads', 'VALIDADE',
         'as seis Trusted e as duas Refined foram escritas na mesma passada (mesma data de carga)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT COUNT(DISTINCT d) FROM (SELECT MAX(DATE(_extraido_at, "America/Sao_Paulo")) AS d FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__imagem` UNION ALL SELECT MAX(DATE(_extraido_at, "America/Sao_Paulo")) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__video` UNION ALL SELECT MAX(DATE(_extraido_at, "America/Sao_Paulo")) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__rotulo` UNION ALL SELECT MAX(DATE(_extraido_at, "America/Sao_Paulo")) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__publico_personalizado` UNION ALL SELECT MAX(DATE(_extraido_at, "America/Sao_Paulo")) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conversao_personalizada` UNION ALL SELECT MAX(DATE(_extraido_at, "America/Sao_Paulo")) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__atividade_conta` UNION ALL SELECT MAX(DATE(_extraido_at, "America/Sao_Paulo")) FROM rm UNION ALL SELECT MAX(DATE(_extraido_at, "America/Sao_Paulo")) FROM ra)) = 1, 0, 1)
),
avaliado AS (
  SELECT r.*, (r.linhas_avaliadas - r.linhas_falha) AS linhas_conformes,
    SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, NULLIF(r.linhas_avaliadas, 0)) AS taxa_conformidade,
    IF(r.linhas_avaliadas = 0, NULL, SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, r.linhas_avaliadas) >= r.limiar) AS is_conforme,
    (r.linhas_avaliadas = 0) AS flag_sem_linha_para_avaliar
  FROM r
)
SELECT a.*,
  CASE WHEN a.flag_sem_linha_para_avaliar THEN 'SEM_DADO' WHEN a.is_conforme THEN 'CONFORME'
       WHEN a.severidade = 'BLOQUEANTE' THEN 'FALHA_BLOQUEANTE' ELSE 'FALHA_ALERTA' END AS resultado,
  'META_ATIVOS' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'query-laCR' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a