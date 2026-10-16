-- rfn_qualidade__regra_meta_ads · 23 regras · Refined / qualidade · L2 INTERNAL
-- Grao: uma REGRA em uma execucao. Cobre a familia Meta Ads (conector facebook-ads) ESTENDIDA em 2026-10-16:
-- trs_facebook_ads__insight_diario (64 contas), __campanha, __conta e a Refined rfn_midia__meta_campanha_mensal.
-- Gatilho: evento em query-QPS7 (rfn_midia__meta_campanha_mensal), o ULTIMO elo da cadeia Meta, que so roda
-- depois de query-QXqC e query-7aLj (cron terca 13:35 America/Manaus). Cadencia semanal. Alerta de falha ligado.
-- Contrato de colunas identico ao das outras suites de qualidade (UNION ALL da o painel unico; familia = META_ADS).
-- A lista de Raw (64 fontes) e FIXA: conta nova integrada entra na Trusted E aqui, senao a identidade nao a cobre.
-- NAO LE rfn_midia__desempenho_diario DE PROPOSITO: ele so reescreve depois da cadeia do Google Ads (>= 14:00),
-- entao compara-lo aqui mediria a passada anterior (o mesmo erro das suites irmas, 30/09 e 08/10).
WITH
raw_conta AS (
  SELECT id_conta, SUM(n) AS n_raw, SUM(inv) AS inv_raw FROM (
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudeadsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragaadsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojaadsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiaadsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_best_car`.`facebook_ads_best_caradsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_adsinsights` GROUP BY 1 UNION ALL
  SELECT account_id AS id_conta, COUNT(*) AS n, SUM(SAFE_CAST(spend AS FLOAT64)) AS inv FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneusadsinsights` GROUP BY 1
  ) GROUP BY 1
),
tr_conta AS (
  SELECT id_conta, COUNT(*) AS n_tr, SUM(investimento) AS inv_tr FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario` GROUP BY 1
),
cmp AS (
  SELECT r.id_conta, r.n_raw, r.inv_raw, t.n_tr, t.inv_tr
  FROM raw_conta r LEFT JOIN tr_conta t ON t.id_conta = r.id_conta
),
mensal AS (
  SELECT * FROM `vanguardamartech_refined`.`rfn_midia__meta_campanha_mensal`
),
r AS (
  -- ================= TRUSTED: insight diario =================
  SELECT 'trs_facebook_ads__insight_diario.anuncio_dia_unico' AS id_regra, 'Trusted' AS camada, 'trs_facebook_ads__insight_diario' AS tabela, 'Meta Ads' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_anuncio, data) e unica' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT CONCAT(id_anuncio, '|', CAST(data AS STRING))) AS linhas_falha
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`
  UNION ALL SELECT 'trs_facebook_ads__insight_diario.linhas_por_conta_reproduzem_a_raw', 'Trusted', 'trs_facebook_ads__insight_diario', 'Meta Ads', 'VALIDADE',
         'cada conta tem na Trusted exatamente as linhas que tem na Raw (a consolidacao nao perde nem inventa linha)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(n_tr IS NULL OR n_tr <> n_raw)
  FROM cmp
  UNION ALL SELECT 'trs_facebook_ads__insight_diario.investimento_por_conta_reproduz_a_raw', 'Trusted', 'trs_facebook_ads__insight_diario', 'Meta Ads', 'VALIDADE',
         'o investimento de cada conta reproduz a soma do spend da Raw dentro de um centavo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(inv_tr IS NULL OR ABS(inv_tr - inv_raw) > 0.01)
  FROM cmp
  UNION ALL SELECT 'trs_facebook_ads__insight_diario.conta_catalogada', 'Trusted', 'trs_facebook_ads__insight_diario', 'Meta Ads', 'INTEGRIDADE',
         'toda conta do insight existe em trs_facebook_ads__conta (a dimensao e lista estatica: conta nova precisa entrar la)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(d.id_conta IS NULL)
  FROM (SELECT DISTINCT id_conta FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`) i LEFT JOIN `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conta` d ON d.id_conta = i.id_conta
  UNION ALL SELECT 'trs_facebook_ads__insight_diario.conta_com_moeda_e_fuso', 'Trusted', 'trs_facebook_ads__insight_diario', 'Meta Ads', 'COMPLETUDE',
         'toda conta do insight tem moeda e fuso na dimensao (o insight nao carrega moeda: sem ela a verba mistura BRL e USD)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(d.moeda IS NULL OR d.fuso_conta IS NULL)
  FROM (SELECT DISTINCT id_conta FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`) i LEFT JOIN `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conta` d ON d.id_conta = i.id_conta
  UNION ALL SELECT 'trs_facebook_ads__insight_diario.conta_defasada_decompoe', 'Trusted', 'trs_facebook_ads__insight_diario', 'Meta Ads', 'VALIDADE',
         'conta_defasada e exatamente mais de 9 dias sem entrega (limiar derivado da cadencia semanal)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(conta_defasada IS DISTINCT FROM (dias_sem_entrega > 9))
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`
  -- LINHA DE BASE: 12 de 64 contas defasadas em 2026-10-16 (52 conformes, 81,25%), todas contas que pararam de veicular.
  -- Se a cadencia semanal quebrar (cron da terca falha), TODAS passam a defasada em 9 dias e a taxa despenca.
  UNION ALL SELECT 'trs_facebook_ads__insight_diario.contas_com_entrega_recente', 'Trusted', 'trs_facebook_ads__insight_diario', 'Meta Ads', 'VALIDADE',
         'ao menos 75% das contas tem entrega nos ultimos 9 dias (linha de base 81%; despenca se a carga semanal parar)', 'ALERTA', 0.75,
         COUNT(*), COUNTIF(d)
  FROM (SELECT id_conta, LOGICAL_OR(conta_defasada) AS d FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario` GROUP BY 1)
  UNION ALL SELECT 'trs_facebook_ads__insight_diario.conta_da_campanha_confere', 'Trusted', 'trs_facebook_ads__insight_diario', 'Meta Ads', 'INTEGRIDADE',
         'a campanha do insight pertence a mesma conta na dimensao de campanha (id de campanha e globalmente unico)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(c.id_conta IS NOT NULL AND c.id_conta <> i.id_conta)
  FROM (SELECT DISTINCT id_campanha, id_conta FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`) i LEFT JOIN `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__campanha` c ON c.id_campanha = i.id_campanha
  -- ================= TRUSTED: dimensoes =================
  UNION ALL SELECT 'trs_facebook_ads__conta.id_conta_unico', 'Trusted', 'trs_facebook_ads__conta', 'Meta Ads', 'UNICIDADE',
         'id_conta e unico e nunca nulo (snapshot + complemento Graph sem sobreposicao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_conta) + COUNTIF(id_conta IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conta`
  UNION ALL SELECT 'trs_facebook_ads__campanha.conta_catalogada', 'Trusted', 'trs_facebook_ads__campanha', 'Meta Ads', 'INTEGRIDADE',
         'toda campanha pertence a conta que existe em trs_facebook_ads__conta', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(d.id_conta IS NULL)
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__campanha` c LEFT JOIN `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conta` d ON d.id_conta = c.id_conta
  UNION ALL SELECT 'trs_facebook_ads__insight_diario.carga_do_mesmo_dia', 'Trusted', 'trs_facebook_ads__insight_diario', 'Meta Ads', 'VALIDADE',
         'insight e campanha foram escritos na mesma passada (data da carga) e a Refined mensal na mesma data', 'BLOQUEANTE', 1.00,
         1, IF((SELECT MAX(DATE(_extraido_at, 'America/Sao_Paulo')) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`) = (SELECT MAX(DATE(_extraido_at, 'America/Sao_Paulo')) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__campanha`)
               AND (SELECT MAX(DATE(_extraido_at, 'America/Sao_Paulo')) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`) = (SELECT MAX(DATE(_extraido_at, 'America/Sao_Paulo')) FROM mensal), 0, 1)
  -- ================= REFINED: rfn_midia__meta_campanha_mensal =================
  UNION ALL SELECT 'rfn_midia__meta_campanha_mensal.chave_unica', 'Refined', 'rfn_midia__meta_campanha_mensal', 'Meta Ads', 'UNICIDADE',
         'id_meta_campanha_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_meta_campanha_mensal) + COUNTIF(id_meta_campanha_mensal IS NULL)
  FROM mensal
  UNION ALL SELECT 'rfn_midia__meta_campanha_mensal.investimento_reproduz_a_trusted', 'Refined', 'rfn_midia__meta_campanha_mensal', 'Meta Ads', 'VALIDADE',
         'a soma de investimento reproduz trs_facebook_ads__insight_diario dentro de um centavo (a Refined agrega, nao filtra)', 'BLOQUEANTE', 1.00,
         1, IF(ABS((SELECT SUM(investimento_micros) / 1e6 FROM mensal) - (SELECT SUM(investimento) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`)) > 0.01, 1, 0)
  UNION ALL SELECT 'rfn_midia__meta_campanha_mensal.conversoes_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_campanha_mensal', 'Meta Ads', 'VALIDADE',
         'a soma de conversoes (leads + compras + conversas) reproduz a Trusted exatamente', 'BLOQUEANTE', 1.00,
         1, IF(ROUND((SELECT SUM(conversoes) FROM mensal)) <> ROUND((SELECT SUM(COALESCE(leads, 0) + COALESCE(compras, 0) + COALESCE(conversas_iniciadas_7d, 0)) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`)), 1, 0)
  UNION ALL SELECT 'rfn_midia__meta_campanha_mensal.impressoes_reproduzem_a_trusted', 'Refined', 'rfn_midia__meta_campanha_mensal', 'Meta Ads', 'VALIDADE',
         'a soma de impressoes reproduz a Trusted exatamente', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(impressoes) FROM mensal) <> (SELECT SUM(impressoes) FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`), 1, 0)
  -- grao CONTA: pega erro que se compensa entre contas e some no total
  UNION ALL SELECT 'rfn_midia__meta_campanha_mensal.investimento_por_conta_reproduz_a_trusted', 'Refined', 'rfn_midia__meta_campanha_mensal', 'Meta Ads', 'VALIDADE',
         'o investimento de cada conta na Refined reproduz o da Trusted dentro de um centavo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(m.inv IS NULL OR t.inv IS NULL OR ABS(m.inv - t.inv) > 0.01)
  FROM (SELECT id_conta, SUM(investimento_micros) / 1e6 AS inv FROM mensal GROUP BY 1) m
  FULL OUTER JOIN (SELECT id_conta, SUM(investimento) AS inv FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario` GROUP BY 1) t ON t.id_conta = m.id_conta
  UNION ALL SELECT 'rfn_midia__meta_campanha_mensal.conversao_decompoe', 'Refined', 'rfn_midia__meta_campanha_mensal', 'Meta Ads', 'VALIDADE',
         'conversoes e exatamente leads mais compras mais conversas (a escolha da regra 8 da Refined diaria)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(conversoes <> conversoes_leads + conversoes_compras + conversoes_conversas)
  FROM mensal
  UNION ALL SELECT 'rfn_midia__meta_campanha_mensal.mes_e_dias_coerentes', 'Refined', 'rfn_midia__meta_campanha_mensal', 'Meta Ads', 'VALIDADE',
         'mes e o primeiro dia, as datas da linha cabem no mes e os dias contados cabem no mes e nos dias com linha', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(mes_referencia <> DATE_TRUNC(mes_referencia, MONTH)
                           OR primeira_data < mes_referencia OR ultima_data > LAST_DAY(mes_referencia)
                           OR qtd_dias_com_linha > DATE_DIFF(LAST_DAY(mes_referencia), mes_referencia, DAY) + 1
                           OR qtd_dias_com_entrega > qtd_dias_com_linha)
  FROM mensal
  UNION ALL SELECT 'rfn_midia__meta_campanha_mensal.registro_confiavel_decompoe', 'Refined', 'rfn_midia__meta_campanha_mensal', 'Meta Ads', 'VALIDADE',
         'registro_confiavel e exatamente nao ter campanha nem conta sem catalogo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(registro_confiavel IS DISTINCT FROM NOT (flag_campanha_nao_catalogada OR flag_conta_nao_catalogada))
  FROM mensal
  UNION ALL SELECT 'rfn_midia__meta_campanha_mensal.moeda_preenchida', 'Refined', 'rfn_midia__meta_campanha_mensal', 'Meta Ads', 'COMPLETUDE',
         'toda linha tem moeda (existem contas em USD: sem moeda a verba mistura BRL e USD)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(moeda IS NULL)
  FROM mensal
  UNION ALL SELECT 'rfn_midia__meta_campanha_mensal.conta_catalogada', 'Refined', 'rfn_midia__meta_campanha_mensal', 'Meta Ads', 'INTEGRIDADE',
         'toda linha resolve a conta na dimensao (conta nova sem dimensao acende aqui)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_conta_nao_catalogada)
  FROM mensal
  -- LINHA DE BASE PROVISORIA: 98,6% nas 7 contas antigas (2.456 de 2.492 linhas), 98,42% no diario das 64. A dimensao de campanha
  -- e FOTOGRAFIA e o fato e HISTORICO (campanha excluida no Meta some do endpoint). Recalibrar depois da 1a execucao com 64 contas.
  UNION ALL SELECT 'rfn_midia__meta_campanha_mensal.campanha_catalogada', 'Refined', 'rfn_midia__meta_campanha_mensal', 'Meta Ads', 'INTEGRIDADE',
         'a campanha existe em trs_facebook_ads__campanha (linha de base provisoria; campanha excluida no Meta nao tem dimensao)', 'ALERTA', 0.95,
         COUNT(*), COUNTIF(flag_campanha_nao_catalogada)
  FROM mensal
  UNION ALL SELECT 'rfn_midia__meta_campanha_mensal.roas_so_com_receita', 'Refined', 'rfn_midia__meta_campanha_mensal', 'Meta Ads', 'VALIDADE',
         'roas so existe onde ha receita de compra; conta sem e-commerce fica NULL, nunca zero', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(roas IS NOT NULL AND valor_compras IS NULL)
  FROM mensal
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
  'META_ADS' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'query-QPS7' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a