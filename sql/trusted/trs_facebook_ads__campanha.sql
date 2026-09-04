-- trs_facebook_ads__campanha
-- Dimensao de campanha consolidada das 7 contas vivas de Facebook Ads.
-- Grao: uma campanha. Chave: id_campanha.
-- Padrao herdado das 9 dimensoes por cliente (query-MHyi e irmas), validado em 27/08/2026.
WITH uniao AS (
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
  -- origem guarda mais de uma versao da mesma campanha. Medido em 2026-09-04:
  -- 1.248 linhas para 1.231 ids nas 7 contas. Sem o QUALIFY a dimensao
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
