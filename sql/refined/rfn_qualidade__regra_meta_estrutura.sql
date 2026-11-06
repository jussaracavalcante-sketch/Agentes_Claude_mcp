-- rfn_qualidade__regra_meta_estrutura · 39 regras · Refined / qualidade · L2 INTERNAL
-- Grao: uma REGRA em uma execucao. Cobre a familia ESTRUTURA do Meta Ads (criada em 2026-10-18): trs_facebook_ads__anuncio,
-- __conjunto_anuncio, __criativo e as Refined rfn_midia__meta_estrutura_conta e rfn_midia__meta_criativo_resumo.
-- Gatilho: evento nas DUAS Refined (query-gfMW e query-TLrb) com regra all, o ULTIMO elo da cadeia (cron terca 13:35 America/Manaus nas Trusted).
-- Cadencia semanal. Alerta de falha ligado. Contrato de colunas identico ao das outras suites de qualidade (UNION ALL da o painel unico;
-- familia = META_ESTRUTURA). Suite propria porque a principal esta em 57 KB e update_transformation substitui o codigo inteiro.
-- As listas de Raw sao FIXAS e iguais as das Trusted (66 contas; 65 em conjuntos: rCHw tem a tabela adsets vazia): conta nova entra na Trusted
-- E aqui, senao a identidade nao a cobre. Para as identidades Trusted x Raw so se le id e conta (nada de texto de terceiros).
-- Tres identidades entre camadas (a Refined agrega e nao filtra): anuncios, conjuntos e criativos somam o mesmo que a Trusted; mais a identidade
-- do investimento: B.investimento + A.investimento_sem_anuncio_cadastrado = A.investimento (ao micro).
-- NAO LE rfn_midia__desempenho_diario (reescreve depois da cadeia do Google Ads): comparar com ele mediria a passada anterior. A identidade de
-- campanhas e feita contra a propria Trusted de campanha (query-7aLj), que esta no gatilho das duas Refined.
-- VALIDACAO 2026-10-18: query inteira rodada reproduzindo as Trusted sobre a Raw de UMA conta (CA Braga Veiculos), porque as tres Trusted novas e as
-- duas Refined ainda nao materializaram: 39 regras, 39 ids, 37 conformes e 2 'falhas' que sao ARTEFATO da conta unica (a conta e so a 8RYU: campanha_catalogada
-- 53 de 988 (5,4%) nessa conta e 196 de 7.960 (2,5%) no total das 64; e investimento_reproduz_o_insight compara 1 conta contra o insight das 7 contas ja materializadas). No total das
-- 64 contas: campanha_catalogada = 196 de 7.960 (97,5%, acima do limiar 0,95) e investimento A = R$ 2.462.188,66 contra R$ 2.462.188,66 do insight (diferenca de 2 micros).
-- genero_codigo_conhecido: 0 'outro' em 7.960 conjuntos (os codigos 0 e 1,2 viram todos).
-- ATUALIZACAO 2026-10-29: facebook-ads-tWIP (FARMABEM) e facebook-ads-bU6W (CA Braga Motos 2) entraram nas Trusted de anuncio, conjunto e criativo (recuperaram em 2026-10-27);
-- as tres listas de Raw (raw_ads, raw_adsets, raw_cri) ganharam as duas fontes (64 -> 66; conjuntos 63 -> 65). As identidades reproduz_a_raw e cobre_as_contas_da_raw
-- DEPENDEM de a query-ArfZ (anuncio) tambem ter as duas fontes: se so conjunto e criativo forem implantados, a regra do anuncio acende BLOQUEANTE. As medicoes de 2026-10-18 acima sao historicas.
WITH
raw_ads AS (
  SELECT account_id AS id_conta, id FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudeads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragaads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojaads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiaads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_best_car`.`facebook_ads_best_carads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_farmabem_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_motos_2_fb_ads`.`facebook_ads_ads` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneusads`
),
raw_adsets AS (
  SELECT account_id AS id_conta, id FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudeadsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragaadsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojaadsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiaadsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_best_car`.`facebook_ads_best_caradsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_farmabem_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_motos_2_fb_ads`.`facebook_ads_adsets` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneusadsets`
),
raw_cri AS (
  SELECT account_id AS id_conta, id FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudecreatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragacreatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojacreatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiacreatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_best_car`.`facebook_ads_best_carcreatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_farmabem_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_ca_braga_motos_2_fb_ads`.`facebook_ads_creatives` UNION ALL
  SELECT account_id AS id_conta, id FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneuscreatives`
),
anuncio AS (SELECT * FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__anuncio`),
conjunto AS (SELECT * FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conjunto_anuncio`),
criativo AS (SELECT * FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__criativo`),
campanha AS (SELECT id_conta, id_campanha FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__campanha`),
est AS (SELECT * FROM `vanguardamartech_refined`.`rfn_midia__meta_estrutura_conta`),
res AS (SELECT * FROM `vanguardamartech_refined`.`rfn_midia__meta_criativo_resumo`),
ins AS (SELECT CAST(ROUND(SUM(investimento) * 1000000) AS INT64) AS micros FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`),
r AS (
  -- ===== TRUSTED ANUNCIO =====
  SELECT 'trs_facebook_ads__anuncio.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_facebook_ads__anuncio' AS tabela, 'Meta Ads' AS sistema, 'UNICIDADE' AS dimensao,
         '(id_conta, id_anuncio) e unica: a deduplicacao da versao de maior updated_time funcionou' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT CONCAT(id_conta, '|', id_anuncio)) AS linhas_falha
  FROM anuncio
  UNION ALL SELECT 'trs_facebook_ads__anuncio.reproduz_a_raw', 'Trusted', 'trs_facebook_ads__anuncio', 'Meta Ads', 'INTEGRIDADE',
         'a Trusted tem exatamente um anuncio por (conta, id) distinto da Raw das 66 fontes (a uniao nao perde nem inventa linha)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT COUNT(*) FROM anuncio) = (SELECT COUNT(DISTINCT CONCAT(id_conta, '|', id)) FROM raw_ads), 0, 1)
  UNION ALL SELECT 'trs_facebook_ads__anuncio.cobre_as_contas_da_raw', 'Trusted', 'trs_facebook_ads__anuncio', 'Meta Ads', 'INTEGRIDADE',
         'o numero de contas na Trusted e o das contas com anuncio na Raw (conta que sumiu da uniao acende aqui)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT COUNT(DISTINCT id_conta) FROM anuncio) = (SELECT COUNT(DISTINCT id_conta) FROM raw_ads), 0, 1)
  UNION ALL SELECT 'trs_facebook_ads__anuncio.ids_preenchidos', 'Trusted', 'trs_facebook_ads__anuncio', 'Meta Ads', 'COMPLETUDE',
         'conta, anuncio, conjunto, campanha e criativo sempre preenchidos (medido: zero nulos em 24.979)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(id_conta IS NULL OR id_anuncio IS NULL OR id_conjunto IS NULL OR id_campanha IS NULL OR id_criativo IS NULL)
  FROM anuncio
  UNION ALL SELECT 'trs_facebook_ads__anuncio.is_ativo_concorda_com_o_status', 'Trusted', 'trs_facebook_ads__anuncio', 'Meta Ads', 'VALIDADE',
         'is_ativo e exatamente status_efetivo = ACTIVE', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(is_ativo IS DISTINCT FROM (status_efetivo = 'ACTIVE'))
  FROM anuncio
  UNION ALL SELECT 'trs_facebook_ads__anuncio.criado_em_nao_futuro', 'Trusted', 'trs_facebook_ads__anuncio', 'Meta Ads', 'VALIDADE',
         'criado_em nunca depois de amanha (guarda o fuso: DATETIME(ts,SP) so muda a representacao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(criado_em IS NULL OR criado_em > DATETIME_ADD(CURRENT_DATETIME('America/Sao_Paulo'), INTERVAL 1 DAY))
  FROM anuncio
  -- LINHA DE BASE: 24.979 de 24.979 anuncios resolvem o criativo (zero orfaos em 2026-10-18). Criativo apagado no Meta pode quebrar isso sem ser defeito.
  UNION ALL SELECT 'trs_facebook_ads__anuncio.criativo_catalogado', 'Trusted', 'trs_facebook_ads__anuncio', 'Meta Ads', 'INTEGRIDADE',
         'o criativo do anuncio existe em trs_facebook_ads__criativo (linha de base: zero orfaos em 2026-10-18)', 'ALERTA', 0.995,
         COUNT(*), COUNTIF(k.id_criativo IS NULL)
  FROM anuncio a LEFT JOIN (SELECT DISTINCT id_conta, id_criativo FROM criativo) k USING (id_conta, id_criativo)
  -- ===== TRUSTED CONJUNTO =====
  UNION ALL SELECT 'trs_facebook_ads__conjunto_anuncio.chave_unica', 'Trusted', 'trs_facebook_ads__conjunto_anuncio', 'Meta Ads', 'UNICIDADE',
         '(id_conta, id_conjunto) e unica: a deduplicacao da versao de maior updated_time funcionou (ate 8 versoes na origem)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(id_conta, '|', id_conjunto))
  FROM conjunto
  UNION ALL SELECT 'trs_facebook_ads__conjunto_anuncio.reproduz_a_raw', 'Trusted', 'trs_facebook_ads__conjunto_anuncio', 'Meta Ads', 'INTEGRIDADE',
         'a Trusted tem exatamente um conjunto por (conta, id) distinto da Raw das 65 fontes com adsets', 'BLOQUEANTE', 1.00,
         1, IF((SELECT COUNT(*) FROM conjunto) = (SELECT COUNT(DISTINCT CONCAT(id_conta, '|', id)) FROM raw_adsets), 0, 1)
  UNION ALL SELECT 'trs_facebook_ads__conjunto_anuncio.orcamento_zero_vira_nulo', 'Trusted', 'trs_facebook_ads__conjunto_anuncio', 'Meta Ads', 'VALIDADE',
         'zero e sentinela de sem orcamento neste nivel: orcamento diario e total nunca valem 0 (ou sao NULL, ou positivos)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(orcamento_diario_unidade_menor = 0 OR orcamento_total_unidade_menor = 0)
  FROM conjunto
  UNION ALL SELECT 'trs_facebook_ads__conjunto_anuncio.valor_e_unidade_menor_sobre_100', 'Trusted', 'trs_facebook_ads__conjunto_anuncio', 'Meta Ads', 'VALIDADE',
         'orcamento_diario = orcamento_diario_unidade_menor / 100 (e o total igual): a unidade menor so se converte numa coluna', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(ABS(IFNULL(orcamento_diario, 0) - IFNULL(orcamento_diario_unidade_menor, 0) / 100) > 0.0001
                         OR ABS(IFNULL(orcamento_total, 0) - IFNULL(orcamento_total_unidade_menor, 0) / 100) > 0.0001
                         OR ((orcamento_diario IS NULL) <> (orcamento_diario_unidade_menor IS NULL)))
  FROM conjunto
  UNION ALL SELECT 'trs_facebook_ads__conjunto_anuncio.tem_orcamento_concorda', 'Trusted', 'trs_facebook_ads__conjunto_anuncio', 'Meta Ads', 'VALIDADE',
         'tem_orcamento_no_conjunto e exatamente orcamento diario OU total preenchido', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(tem_orcamento_no_conjunto IS DISTINCT FROM (orcamento_diario_unidade_menor IS NOT NULL OR orcamento_total_unidade_menor IS NOT NULL))
  FROM conjunto
  -- LINHA DE BASE: a Meta nao aceita os dois orcamentos no mesmo conjunto (medido: zero de 7.960).
  UNION ALL SELECT 'trs_facebook_ads__conjunto_anuncio.orcamento_nunca_nos_dois', 'Trusted', 'trs_facebook_ads__conjunto_anuncio', 'Meta Ads', 'VALIDADE',
         'conjunto nao tem orcamento diario E total ao mesmo tempo (regra da plataforma; linha de base zero)', 'ALERTA', 0.999,
         COUNT(*), COUNTIF(orcamento_diario_unidade_menor IS NOT NULL AND orcamento_total_unidade_menor IS NOT NULL)
  FROM conjunto
  UNION ALL SELECT 'trs_facebook_ads__conjunto_anuncio.idade_min_nao_excede_max', 'Trusted', 'trs_facebook_ads__conjunto_anuncio', 'Meta Ads', 'VALIDADE',
         'idade_min <= idade_max quando as duas existem', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(idade_min > idade_max)
  FROM conjunto
  UNION ALL SELECT 'trs_facebook_ads__conjunto_anuncio.genero_codigo_conhecido', 'Trusted', 'trs_facebook_ads__conjunto_anuncio', 'Meta Ads', 'VALIDADE',
         'genero_alvo so sai todos, masculino ou feminino (o codigo 0 da Meta e todos): codigo novo cai em outro e acende aqui', 'ALERTA', 0.999,
         COUNT(*), COUNTIF(genero_alvo = 'outro')
  FROM conjunto
  -- LINHA DE BASE: 196 de 7.960 conjuntos (2,46%) sem campanha na dimensao (campanha excluida no Meta some da dimensao-fotografia e o fato e historico).
  UNION ALL SELECT 'trs_facebook_ads__conjunto_anuncio.campanha_catalogada', 'Trusted', 'trs_facebook_ads__conjunto_anuncio', 'Meta Ads', 'INTEGRIDADE',
         'a campanha do conjunto existe em trs_facebook_ads__campanha (linha de base 97,5%; campanha excluida no Meta nao tem dimensao)', 'ALERTA', 0.95,
         COUNT(*), COUNTIF(c.id_campanha IS NULL)
  FROM conjunto j LEFT JOIN (SELECT DISTINCT id_conta, id_campanha FROM campanha) c USING (id_conta, id_campanha)
  -- ===== TRUSTED CRIATIVO =====
  UNION ALL SELECT 'trs_facebook_ads__criativo.chave_unica', 'Trusted', 'trs_facebook_ads__criativo', 'Meta Ads', 'UNICIDADE',
         '(id_conta, id_criativo) e unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(id_conta, '|', id_criativo))
  FROM criativo
  UNION ALL SELECT 'trs_facebook_ads__criativo.reproduz_a_raw', 'Trusted', 'trs_facebook_ads__criativo', 'Meta Ads', 'INTEGRIDADE',
         'a Trusted tem exatamente um criativo por (conta, id) distinto da Raw das 66 fontes', 'BLOQUEANTE', 1.00,
         1, IF((SELECT COUNT(*) FROM criativo) = (SELECT COUNT(DISTINCT CONCAT(id_conta, '|', id)) FROM raw_cri), 0, 1)
  UNION ALL SELECT 'trs_facebook_ads__criativo.flags_concordam_com_o_texto', 'Trusted', 'trs_facebook_ads__criativo', 'Meta Ads', 'VALIDADE',
         'tem_titulo, tem_corpo e tem_cta sao exatamente a presenca do campo, e os tamanhos so existem com texto', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(tem_titulo IS DISTINCT FROM (titulo IS NOT NULL) OR tem_corpo IS DISTINCT FROM (corpo IS NOT NULL) OR tem_cta IS DISTINCT FROM (tipo_cta IS NOT NULL)
                         OR (qtd_caracteres_corpo IS NULL) <> (corpo IS NULL) OR (qtd_caracteres_titulo IS NULL) <> (titulo IS NULL))
  FROM criativo
  UNION ALL SELECT 'trs_facebook_ads__criativo.texto_nunca_vazio', 'Trusted', 'trs_facebook_ads__criativo', 'Meta Ads', 'VALIDADE',
         'titulo, corpo, nome e URL nunca sao string vazia (o titulo de um espaco existe na origem e vira NULL)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(titulo = '' OR corpo = '' OR nome_criativo = '' OR url_destino = '' OR url_link = '')
  FROM criativo
  -- ===== REFINED ESTRUTURA DE CONTA =====
  UNION ALL SELECT 'rfn_midia__meta_estrutura_conta.chave_unica', 'Refined', 'rfn_midia__meta_estrutura_conta', 'Meta Ads', 'UNICIDADE',
         'id_conta e unica (grao: uma conta)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_conta)
  FROM est
  UNION ALL SELECT 'rfn_midia__meta_estrutura_conta.anuncios_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_estrutura_conta', 'Meta Ads', 'INTEGRIDADE',
         'a soma de qtd_anuncios por conta e o total da Trusted de anuncio (a Refined agrega e nao filtra)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT IFNULL(SUM(qtd_anuncios), 0) FROM est) = (SELECT COUNT(*) FROM anuncio), 0, 1)
  UNION ALL SELECT 'rfn_midia__meta_estrutura_conta.conjuntos_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_estrutura_conta', 'Meta Ads', 'INTEGRIDADE',
         'a soma de qtd_conjuntos por conta e o total da Trusted de conjunto', 'BLOQUEANTE', 1.00,
         1, IF((SELECT IFNULL(SUM(qtd_conjuntos), 0) FROM est) = (SELECT COUNT(*) FROM conjunto), 0, 1)
  UNION ALL SELECT 'rfn_midia__meta_estrutura_conta.criativos_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_estrutura_conta', 'Meta Ads', 'INTEGRIDADE',
         'a soma de qtd_criativos por conta e o total da Trusted de criativo', 'BLOQUEANTE', 1.00,
         1, IF((SELECT IFNULL(SUM(qtd_criativos), 0) FROM est) = (SELECT COUNT(*) FROM criativo), 0, 1)
  UNION ALL SELECT 'rfn_midia__meta_estrutura_conta.campanhas_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_estrutura_conta', 'Meta Ads', 'INTEGRIDADE',
         'a soma de qtd_campanhas por conta e o total da Trusted de campanha', 'BLOQUEANTE', 1.00,
         1, IF((SELECT IFNULL(SUM(qtd_campanhas), 0) FROM est) = (SELECT COUNT(*) FROM campanha), 0, 1)
  UNION ALL SELECT 'rfn_midia__meta_estrutura_conta.baldes_de_status_fecham_o_total', 'Refined', 'rfn_midia__meta_estrutura_conta', 'Meta Ads', 'VALIDADE',
         'em cada nivel, ativos + pausados + pausados por ancestral + com problema + outros = total da conta', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_conjuntos != qtd_conjuntos_ativos + qtd_conjuntos_pausados + qtd_conjuntos_pausados_por_ancestral + qtd_conjuntos_com_problema + qtd_conjuntos_outro_status
                         OR qtd_anuncios != qtd_anuncios_ativos + qtd_anuncios_pausados + qtd_anuncios_pausados_por_ancestral + qtd_anuncios_com_problema + qtd_anuncios_outro_status
                         OR qtd_campanhas != qtd_campanhas_ativas + qtd_campanhas_pausadas + qtd_campanhas_com_problema + qtd_campanhas_outro_status)
  FROM est
  UNION ALL SELECT 'rfn_midia__meta_estrutura_conta.conta_na_dimensao', 'Refined', 'rfn_midia__meta_estrutura_conta', 'Meta Ads', 'INTEGRIDADE',
         'toda conta resolve moeda e fuso na dimensao (conta nova sem dimensao mistura BRL e USD)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_sem_dimensao_conta OR moeda IS NULL)
  FROM est
  UNION ALL SELECT 'rfn_midia__meta_estrutura_conta.investimento_so_com_insight', 'Refined', 'rfn_midia__meta_estrutura_conta', 'Meta Ads', 'VALIDADE',
         'conta sem insight tem investimento NULL (nunca zero) e conta com insight tem valor: flag_sem_insight concorda com a coluna', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF((investimento_micros IS NULL) != flag_sem_insight)
  FROM est
  UNION ALL SELECT 'rfn_midia__meta_estrutura_conta.investimento_reproduz_o_insight', 'Refined', 'rfn_midia__meta_estrutura_conta', 'Meta Ads', 'INTEGRIDADE',
         'a soma do investimento por conta e o investimento total de trs_facebook_ads__insight_diario (ao micro: a Refined nao perde nem duplica verba)', 'BLOQUEANTE', 1.00,
         1, IF(ABS(IFNULL((SELECT SUM(investimento_micros) FROM est), 0) - IFNULL((SELECT micros FROM ins), 0)) <= 1000, 0, 1)
  UNION ALL SELECT 'rfn_midia__meta_estrutura_conta.orcamento_ativo_reproduz_a_trusted', 'Refined', 'rfn_midia__meta_estrutura_conta', 'Meta Ads', 'INTEGRIDADE',
         'a soma do orcamento diario dos conjuntos ativos e a da Trusted de conjunto (is_ativo)', 'BLOQUEANTE', 1.00,
         1, IF(IFNULL((SELECT SUM(orcamento_diario_ativo_unidade_menor) FROM est), 0) = IFNULL((SELECT SUM(IF(is_ativo, orcamento_diario_unidade_menor, NULL)) FROM conjunto), 0), 0, 1)
  -- ===== REFINED RESUMO DE CRIATIVO =====
  UNION ALL SELECT 'rfn_midia__meta_criativo_resumo.chave_unica', 'Refined', 'rfn_midia__meta_criativo_resumo', 'Meta Ads', 'UNICIDADE',
         'id_criativo_resumo (conta, formato, CTA) e unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_criativo_resumo)
  FROM res
  UNION ALL SELECT 'rfn_midia__meta_criativo_resumo.criativos_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_criativo_resumo', 'Meta Ads', 'INTEGRIDADE',
         'a soma de qtd_criativos e o total da Trusted de criativo', 'BLOQUEANTE', 1.00,
         1, IF((SELECT IFNULL(SUM(qtd_criativos), 0) FROM res) = (SELECT COUNT(*) FROM criativo), 0, 1)
  UNION ALL SELECT 'rfn_midia__meta_criativo_resumo.anuncios_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_criativo_resumo', 'Meta Ads', 'INTEGRIDADE',
         'a soma de qtd_anuncios e o total da Trusted de anuncio (todo anuncio cai em um formato)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT IFNULL(SUM(qtd_anuncios), 0) FROM res) = (SELECT COUNT(*) FROM anuncio), 0, 1)
  UNION ALL SELECT 'rfn_midia__meta_criativo_resumo.investimento_fecha_com_a_estrutura', 'Refined', 'rfn_midia__meta_criativo_resumo', 'Meta Ads', 'INTEGRIDADE',
         'investimento atribuido a formatos + investimento de anuncio sem cadastro = investimento total das contas (a identidade entre as duas Refined, ao micro)', 'BLOQUEANTE', 1.00,
         1, IF(ABS(IFNULL((SELECT SUM(investimento_micros) FROM res), 0) + IFNULL((SELECT SUM(investimento_sem_anuncio_cadastrado_micros) FROM est), 0) - IFNULL((SELECT SUM(investimento_micros) FROM est), 0)) <= 1000, 0, 1)
  UNION ALL SELECT 'rfn_midia__meta_criativo_resumo.rotulo_de_ausencia_na_chave', 'Refined', 'rfn_midia__meta_criativo_resumo', 'Meta Ads', 'COMPLETUDE',
         'tipo_objeto e tipo_cta nunca NULL: a ausencia vira rotulo (sem tipo / sem cta) e faz parte da chave', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(tipo_objeto IS NULL OR tipo_cta IS NULL)
  FROM res
  UNION ALL SELECT 'rfn_midia__meta_criativo_resumo.moeda_preenchida', 'Refined', 'rfn_midia__meta_criativo_resumo', 'Meta Ads', 'COMPLETUDE',
         'toda linha tem moeda (existem contas em USD: sem moeda o investimento mistura BRL e USD)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(moeda IS NULL OR flag_sem_dimensao_conta)
  FROM res
  UNION ALL SELECT 'rfn_midia__meta_criativo_resumo.media_corpo_so_com_corpo', 'Refined', 'rfn_midia__meta_criativo_resumo', 'Meta Ads', 'VALIDADE',
         'media_caracteres_corpo so existe onde ha corpo (razao de somas, nunca zero por ausencia)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF((media_caracteres_corpo IS NULL) != (qtd_com_corpo = 0))
  FROM res
  UNION ALL SELECT 'rfn_midia__meta_criativo_resumo.investimento_so_com_insight', 'Refined', 'rfn_midia__meta_criativo_resumo', 'Meta Ads', 'VALIDADE',
         'formato sem anuncio com insight tem investimento NULL (nunca zero)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF((investimento_micros IS NULL) != flag_sem_insight)
  FROM res
  -- ===== FRESCOR =====
  UNION ALL SELECT 'meta_estrutura.carga_do_mesmo_dia', 'Trusted', 'trs_facebook_ads__anuncio + conjunto + criativo', 'Meta Ads', 'INTEGRIDADE',
         'as tres Trusted de estrutura foram escritas na MESMA passada (mesma data de _extraido_at): uma que ficou na carga anterior faz as contagens das Refined divergirem', 'BLOQUEANTE', 1.00,
         1, IF((SELECT COUNT(DISTINCT d) FROM (SELECT MAX(DATE(_extraido_at)) d FROM anuncio UNION ALL SELECT MAX(DATE(_extraido_at)) FROM conjunto UNION ALL SELECT MAX(DATE(_extraido_at)) FROM criativo)) = 1, 0, 1)
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
  'META_ESTRUTURA' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'query-gfMW+query-TLrb' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a