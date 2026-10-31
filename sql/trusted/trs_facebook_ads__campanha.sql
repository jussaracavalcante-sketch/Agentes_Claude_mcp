-- trs_facebook_ads__campanha
-- Dimensao de campanha consolidada de Facebook Ads. Grao: uma campanha. Chave: id_campanha.
--
-- 2026-10-29: ESTENDIDA DE 64 PARA 66 FONTES: entram tWIP (FARMABEM) e bU6W (CA Braga Motos 2), que recuperaram em 27/10
-- (antes 403/400); saem da lista de fora. Mesmas duas fontes da trs_facebook_ads__insight_diario.
--
-- 2026-10-16: ESTENDIDA DE 7 PARA 64 FONTES (a mesma lista da trs_facebook_ads__insight_diario:
-- 7 antigas explicitas + 57 novas com adsinsights e campaigns materializadas e linhas > 0).
-- As 57 novas entram pelo padrao compacto; colunas nomeadas uma vez em uniao_novas.
-- Padrao herdado das 9 dimensoes por cliente (query-MHyi e irmas), validado em 27/08/2026.
WITH uniao_antigas AS (
  SELECT
    'facebook-ads-Si4U' AS _fonte,
    c.id, c.account_id, c.name,
    c.objective, c.effective_status, c.configured_status, c.status,
    c.buying_type, c.bid_strategy, c.pacing_type, c.special_ad_categories,
    c.daily_budget, c.lifetime_budget, c.budget_remaining, c.spend_cap,
    c.start_time, c.stop_time, c.created_time, c.updated_time,
    TO_HEX(MD5(TO_JSON_STRING(c))) AS _payload_hash
  FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudecampaigns` c
  UNION ALL
  SELECT
    'facebook-ads-kQ2S' AS _fonte,
    c.id, c.account_id, c.name,
    c.objective, c.effective_status, c.configured_status, c.status,
    c.buying_type, c.bid_strategy, c.pacing_type, c.special_ad_categories,
    c.daily_budget, c.lifetime_budget, c.budget_remaining, c.spend_cap,
    c.start_time, c.stop_time, c.created_time, c.updated_time,
    TO_HEX(MD5(TO_JSON_STRING(c))) AS _payload_hash
  FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragacampaigns` c
  UNION ALL
  SELECT
    'facebook-ads-GWZ2' AS _fonte,
    c.id, c.account_id, c.name,
    c.objective, c.effective_status, c.configured_status, c.status,
    c.buying_type, c.bid_strategy, c.pacing_type, c.special_ad_categories,
    c.daily_budget, c.lifetime_budget, c.budget_remaining, c.spend_cap,
    c.start_time, c.stop_time, c.created_time, c.updated_time,
    TO_HEX(MD5(TO_JSON_STRING(c))) AS _payload_hash
  FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_campaigns` c
  UNION ALL
  SELECT
    'facebook-ads-x4yO' AS _fonte,
    c.id, c.account_id, c.name,
    c.objective, c.effective_status, c.configured_status, c.status,
    c.buying_type, c.bid_strategy, c.pacing_type, c.special_ad_categories,
    c.daily_budget, c.lifetime_budget, c.budget_remaining, c.spend_cap,
    c.start_time, c.stop_time, c.created_time, c.updated_time,
    TO_HEX(MD5(TO_JSON_STRING(c))) AS _payload_hash
  FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojacampaigns` c
  UNION ALL
  SELECT
    'facebook-ads-ln1a' AS _fonte,
    c.id, c.account_id, c.name,
    c.objective, c.effective_status, c.configured_status, c.status,
    c.buying_type, c.bid_strategy, c.pacing_type, c.special_ad_categories,
    c.daily_budget, c.lifetime_budget, c.budget_remaining, c.spend_cap,
    c.start_time, c.stop_time, c.created_time, c.updated_time,
    TO_HEX(MD5(TO_JSON_STRING(c))) AS _payload_hash
  FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiacampaigns` c
  UNION ALL
  SELECT
    'facebook-ads-E9RT' AS _fonte,
    c.id, c.account_id, c.name,
    c.objective, c.effective_status, c.configured_status, c.status,
    c.buying_type, c.bid_strategy, c.pacing_type, c.special_ad_categories,
    c.daily_budget, c.lifetime_budget, c.budget_remaining, c.spend_cap,
    c.start_time, c.stop_time, c.created_time, c.updated_time,
    TO_HEX(MD5(TO_JSON_STRING(c))) AS _payload_hash
  FROM `vanguardamartech_best_car`.`facebook_ads_best_carcampaigns` c
  UNION ALL
  SELECT
    'facebook-ads-oB7d' AS _fonte,
    c.id, c.account_id, c.name,
    c.objective, c.effective_status, c.configured_status, c.status,
    c.buying_type, c.bid_strategy, c.pacing_type, c.special_ad_categories,
    c.daily_budget, c.lifetime_budget, c.budget_remaining, c.spend_cap,
    c.start_time, c.stop_time, c.created_time, c.updated_time,
    TO_HEX(MD5(TO_JSON_STRING(c))) AS _payload_hash
  FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_campaigns` c
),

uniao_novas_raw AS (
SELECT 'facebook-ads-8RYU' AS _fonte, * FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-ezGP' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-b8KQ' AS _fonte, * FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-rCHw' AS _fonte, * FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-CebU' AS _fonte, * FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-jZBq' AS _fonte, * FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-5eAs' AS _fonte, * FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-aghZ' AS _fonte, * FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-Vgli' AS _fonte, * FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-WQmP' AS _fonte, * FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-nCGL' AS _fonte, * FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-K2kh' AS _fonte, * FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-TAqE' AS _fonte, * FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-omn8' AS _fonte, * FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-2vvw' AS _fonte, * FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-tzO2' AS _fonte, * FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-s8I1' AS _fonte, * FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-oVkz' AS _fonte, * FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-phtv' AS _fonte, * FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-rPr1' AS _fonte, * FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-p8vg' AS _fonte, * FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-ofJE' AS _fonte, * FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-aiXX' AS _fonte, * FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-ZYCB' AS _fonte, * FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-Hr6d' AS _fonte, * FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-oaSa' AS _fonte, * FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-tWUr' AS _fonte, * FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-d1nc' AS _fonte, * FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-Eo68' AS _fonte, * FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-SGls' AS _fonte, * FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-lDmk' AS _fonte, * FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-Ew4q' AS _fonte, * FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-oih2' AS _fonte, * FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-lk1y' AS _fonte, * FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-cETo' AS _fonte, * FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-mtAO' AS _fonte, * FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-pbon' AS _fonte, * FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-4Q1U' AS _fonte, * FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-DtiV' AS _fonte, * FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-yFhV' AS _fonte, * FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-Uu0D' AS _fonte, * FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-0rrE' AS _fonte, * FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-sHYk' AS _fonte, * FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-bIVn' AS _fonte, * FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-3vys' AS _fonte, * FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-xohe' AS _fonte, * FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-Tqjf' AS _fonte, * FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-ckhA' AS _fonte, * FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-smxd' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-elFk' AS _fonte, * FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-VJeY' AS _fonte, * FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-AJ09' AS _fonte, * FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-KBUT' AS _fonte, * FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-hIaw' AS _fonte, * FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-7NkZ' AS _fonte, * FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-I8ld' AS _fonte, * FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-GZtZ' AS _fonte, * FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneuscampaigns` UNION ALL
SELECT 'facebook-ads-tWIP' AS _fonte, * FROM `vanguardamartech_farmabem_fb_ads`.`facebook_ads_campaigns` UNION ALL
SELECT 'facebook-ads-bU6W' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_2_fb_ads`.`facebook_ads_campaigns`
),

uniao_novas AS (
  SELECT
    c._fonte,
    c.id, c.account_id, c.name,
    c.objective, c.effective_status, c.configured_status, c.status,
    c.buying_type, c.bid_strategy, c.pacing_type, c.special_ad_categories,
    c.daily_budget, c.lifetime_budget, c.budget_remaining, c.spend_cap,
    c.start_time, c.stop_time, c.created_time, c.updated_time,
    TO_HEX(MD5(TO_JSON_STRING((SELECT AS STRUCT c.* EXCEPT (_fonte))))) AS _payload_hash
  FROM uniao_novas_raw c
),

uniao AS (
  SELECT * FROM uniao_antigas
  UNION ALL
  SELECT * FROM uniao_novas
),

base AS (
  SELECT
    u._fonte,
    u.id                                      AS id_campanha,
    u.account_id                              AS id_conta,
    NULLIF(TRIM(u.name), '')                  AS campanha,
    u.objective                               AS objetivo,
    u.effective_status                        AS status_efetivo,
    u.configured_status                       AS status_configurado,
    u.status                                  AS status,
    u.buying_type                             AS tipo_compra,
    u.bid_strategy                            AS estrategia_lance,
    u.pacing_type                             AS ritmo,
    u.special_ad_categories                   AS categorias_especiais,
    SAFE_CAST(u.daily_budget AS INT64)        AS orc_diario,
    SAFE_CAST(u.lifetime_budget AS INT64)     AS orc_total,
    SAFE_CAST(u.budget_remaining AS INT64)    AS orc_restante,
    SAFE_CAST(u.spend_cap AS INT64)           AS teto_gasto,
    SAFE_CAST(u.start_time   AS TIMESTAMP)    AS inicio_utc,
    SAFE_CAST(u.stop_time    AS TIMESTAMP)    AS fim_utc,
    SAFE_CAST(u.created_time AS TIMESTAMP)    AS criado_utc,
    SAFE_CAST(u.updated_time AS TIMESTAMP)    AS atualizado_utc,
    u._payload_hash
  -- DEDUPLICACAO OBRIGATORIA: a chave do stream e [id, updated_time], entao a
  -- origem guarda mais de uma versao da mesma campanha. Sem o QUALIFY a dimensao
  -- multiplica o insight no join.
  FROM uniao u
  QUALIFY ROW_NUMBER() OVER (PARTITION BY u.id ORDER BY u.updated_time DESC) = 1
)

SELECT
  b.id_campanha,
  b.id_conta,
  b.campanha,

  b.objetivo,
  CASE
    WHEN b.objetivo IN ('OUTCOME_AWARENESS','REACH','PAGE_LIKES','BRAND_AWARENESS')                        THEN 'reconhecimento'
    WHEN b.objetivo IN ('OUTCOME_TRAFFIC','LINK_CLICKS')                                                   THEN 'trafego'
    WHEN b.objetivo IN ('OUTCOME_ENGAGEMENT','POST_ENGAGEMENT','VIDEO_VIEWS','MESSAGES','EVENT_RESPONSES') THEN 'engajamento'
    WHEN b.objetivo IN ('OUTCOME_LEADS','LEAD_GENERATION')                                                 THEN 'leads'
    WHEN b.objetivo IN ('OUTCOME_SALES','CONVERSIONS','PRODUCT_CATALOG_SALES','STORE_VISITS')              THEN 'vendas'
    WHEN b.objetivo IN ('OUTCOME_APP_PROMOTION','APP_INSTALLS')                                            THEN 'app'
    WHEN b.objetivo IS NULL                                                                                THEN NULL
    ELSE 'outro'
  END                                                                       AS objetivo_canonico,
  IF(b.objetivo IS NULL, NULL, IF(STARTS_WITH(b.objetivo, 'OUTCOME_'), 'odax', 'legado')) AS geracao_objetivo,
  (b.objetivo = 'MESSAGES')                                                 AS objetivo_eh_mensagem,

  b.status_efetivo,
  b.status_configurado,
  b.status,
  (b.status_efetivo = 'ACTIVE')                                             AS ativa,

  b.tipo_compra,
  b.estrategia_lance,
  b.ritmo,
  b.categorias_especiais,

  -- UNIDADE NAO VERIFICADA, NAO DIVIDA. O Meta documenta orcamento na menor
  -- unidade da moeda, mas o teste de 27/08/2026 na Best Car nao confirmou.
  -- A Trusted nao divide; conversao e regra de negocio da Refined.
  b.orc_diario                                                              AS orcamento_diario_unidade_menor,
  b.orc_total                                                               AS orcamento_total_unidade_menor,
  b.orc_restante                                                            AS orcamento_restante_unidade_menor,
  b.teto_gasto                                                              AS teto_gasto_unidade_menor,

  DATETIME(b.inicio_utc,     'America/Sao_Paulo')                           AS inicio,
  DATETIME(b.fim_utc,        'America/Sao_Paulo')                           AS fim,
  DATE(b.inicio_utc,         'America/Sao_Paulo')                           AS data_inicio,
  DATE(b.fim_utc,            'America/Sao_Paulo')                           AS data_fim,
  DATETIME(b.criado_utc,     'America/Sao_Paulo')                           AS criado_em,
  DATETIME(b.atualizado_utc, 'America/Sao_Paulo')                           AS atualizado_em,

  CURRENT_TIMESTAMP()                                                       AS _extraido_at,
  b._fonte,
  b._payload_hash
FROM base b
