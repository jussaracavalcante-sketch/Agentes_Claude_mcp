-- trs_facebook_ads__insight_diario
--
-- 2026-10-29: ESTENDIDA DE 64 PARA 66 FONTES: entram tWIP (FARMABEM, camada vanguardamartech_farmabem_fb_ads) e
-- bU6W (CA Braga Motos 2, camada vanguardamartech_ca_braga_motos_2_fb_ads), que recuperaram em 27/10 (antes 403/400).
-- Saem da lista FICAM FORA abaixo. Mesmo padrao compacto; esquema identico verificado por execucao da uniao.
--
-- 2026-10-16: ESTENDIDA DE 7 PARA 64 FONTES = 7 antigas (ramos explicitos, INALTERADOS) + 57
-- das 77 fontes publicadas em 09 e 14/10 (uma camada por fonte, R-001), as que tem adsinsights
-- MATERIALIZADA e com linhas > 0. As 57 novas entram pelo padrao compacto
-- `SELECT '<slug>' AS _fonte, * FROM <tabela>` e as colunas sao nomeadas UMA vez em uniao_novas
-- (query grande demais nao se conserta: licao do Google Ads, 76 mil caracteres). Esquema das 57
-- verificado identico por execucao da uniao. FICAM FORA, por contrato: (a) 11 fontes com 403
-- ads_read (sem tabela materializada; tWIP e bU6W entraram em 2026-10-29); (b) 7 com tabela e ZERO linhas (KL NTkr, AMZ
-- Imports QtU1, Auto Master wZuX, Move CA2 T0qp, Acesso Saude manoa WOOU, Millennium Shopping
-- fK2P, Ola Casa Nova FKfU) -- entram quando tiverem linha: editar a uniao e rodar LIMIT 0;
-- (c) ex-clientes (Patio Gourmet, Mari Mari, Ola Casa Nova) e Nova Era: dado fica na Raw.
--
-- LIMIAR DE DEFASAGEM = 9 DIAS, e nao 2. As fontes de Facebook rodam semanalmente (tercas)
-- desde 2026-09-04. Com cadencia semanal, > 2 acusaria TODA conta a partir do segundo dia depois
-- de cada terca. 9 dias = a semana da cadencia + 2 de folga. SE A CADENCIA MUDAR, ESTE NUMERO
-- MUDA COM ELA -- o limiar e derivado do intervalo entre extracoes, nao arbitrario.
--
-- Trusted consolidada de Facebook Ads. Grao: um anuncio por dia. Chave (id_anuncio, data).
-- Padrao herdado de query-OTSI (Acesso Saude), validado em 26/08/2026.
WITH uniao_antigas AS (
  SELECT
    'facebook-ads-Si4U' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_acesso_saude`.`facebook_ads__acesso_saudeadsinsights` i
  UNION ALL
  SELECT
    'facebook-ads-kQ2S' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_braga_veiculos`.`facebook_ads_bragaadsinsights` i
  UNION ALL
  SELECT
    'facebook-ads-GWZ2' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_braga_veiculos`.`facebook_ads_braga_adsinsights` i
  UNION ALL
  SELECT
    'facebook-ads-x4yO' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_pmz_loja`.`facebook_ads_pmz_lojaadsinsights` i
  UNION ALL
  SELECT
    'facebook-ads-ln1a' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_colmeia`.`facebook_ads_colmeiaadsinsights` i
  UNION ALL
  SELECT
    'facebook-ads-E9RT' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_best_car`.`facebook_ads_best_caradsinsights` i
  UNION ALL
  SELECT
    'facebook-ads-oB7d' AS _fonte,
    i.id, i.account_id, i.account_name,
    i.campaign_id, i.campaign_name,
    i.adset_id, i.adset_name,
    i.ad_id, i.ad_name,
    i.date_start, i.date_stop,
    i.spend, i.impressions, i.reach, i.clicks,
    i.inline_link_clicks, i.inline_post_engagement, i.frequency,
    i.cpc, i.cpm, i.cpp, i.ctr, i.inline_link_click_ctr,
    i.quality_ranking, i.engagement_rate_ranking, i.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(i.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING(i)))                                        AS _payload_hash
  FROM `vanguardamartech_constroi_incorporadora`.`facebook_ads_adsinsights` i
),

uniao_novas_raw AS (
SELECT 'facebook-ads-8RYU' AS _fonte, * FROM `vanguardamartech_ca_braga_veiculos_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-ezGP' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_rey_mao_royal_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-b8KQ' AS _fonte, * FROM `vanguardamartech_neo_vila_adrianopolis_empreendimento_ads_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-rCHw' AS _fonte, * FROM `vanguardamartech_acesso_saude_manoa_2_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-CebU' AS _fonte, * FROM `vanguardamartech_ca_braga_veiculos_venda_direta_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-jZBq' AS _fonte, * FROM `vanguardamartech_parque_das_torres_ads_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-5eAs' AS _fonte, * FROM `vanguardamartech_ca_inforcell_oficial_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-aghZ' AS _fonte, * FROM `vanguardamartech_amazoncopy_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-Vgli' AS _fonte, * FROM `vanguardamartech_pmz_grupo_ecomm_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-WQmP' AS _fonte, * FROM `vanguardamartech_caa_aluminio_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-nCGL' AS _fonte, * FROM `vanguardamartech_amz_geradores_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-K2kh' AS _fonte, * FROM `vanguardamartech_caa_tintas_express_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-TAqE' AS _fonte, * FROM `vanguardamartech_animativ_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-omn8' AS _fonte, * FROM `vanguardamartech_arena_tintas_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-2vvw' AS _fonte, * FROM `vanguardamartech_pneu_express_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-tzO2' AS _fonte, * FROM `vanguardamartech_cabral_v2_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-s8I1' AS _fonte, * FROM `vanguardamartech_pneu_forte_distribuidora_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-oVkz' AS _fonte, * FROM `vanguardamartech_cdl_manaus_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-phtv' AS _fonte, * FROM `vanguardamartech_pneu_forte_varejo_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-rPr1' AS _fonte, * FROM `vanguardamartech_comac_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-p8vg' AS _fonte, * FROM `vanguardamartech_rei_das_mangueiras_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-ofJE' AS _fonte, * FROM `vanguardamartech_consorcio_chevrolet_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-aiXX' AS _fonte, * FROM `vanguardamartech_residencial_boa_vista_ads_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-ZYCB' AS _fonte, * FROM `vanguardamartech_deb_transportes_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-Hr6d' AS _fonte, * FROM `vanguardamartech_ba_eletrica_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-oaSa' AS _fonte, * FROM `vanguardamartech_best_car_2026_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-tWUr' AS _fonte, * FROM `vanguardamartech_bigazine_boleto_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-d1nc' AS _fonte, * FROM `vanguardamartech_rodrix_motos_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-Eo68' AS _fonte, * FROM `vanguardamartech_don_watches_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-SGls' AS _fonte, * FROM `vanguardamartech_braga_motors_carro_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-lDmk' AS _fonte, * FROM `vanguardamartech_dr_cabral_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-Ew4q' AS _fonte, * FROM `vanguardamartech_braga_motors_mini_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-oih2' AS _fonte, * FROM `vanguardamartech_escola_para_mecanicos_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-lk1y' AS _fonte, * FROM `vanguardamartech_braga_motors_motorrad_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-cETo' AS _fonte, * FROM `vanguardamartech_c_a02_cabral_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-mtAO' AS _fonte, * FROM `vanguardamartech_ca1_move_rental_cars_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-pbon' AS _fonte, * FROM `vanguardamartech_grupo_hage_alimentos_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-4Q1U' AS _fonte, * FROM `vanguardamartech_smile_pneus_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-DtiV' AS _fonte, * FROM `vanguardamartech_hospital_santa_julia_ads_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-yFhV' AS _fonte, * FROM `vanguardamartech_steel_port_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-Uu0D' AS _fonte, * FROM `vanguardamartech_kiffer_ads_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-0rrE' AS _fonte, * FROM `vanguardamartech_therezinha_ruiz_eleicao_2026_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-sHYk' AS _fonte, * FROM `vanguardamartech_leapmotor_via_marconi_manaus_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-bIVn' AS _fonte, * FROM `vanguardamartech_therezinha_ruiz_pre_campanha_2026_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-3vys' AS _fonte, * FROM `vanguardamartech_tropical_multiloja_ativo_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-xohe' AS _fonte, * FROM `vanguardamartech_ca_artrin_importadora_02_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-Tqjf' AS _fonte, * FROM `vanguardamartech_ca_braga_acessorios_mao_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-ckhA' AS _fonte, * FROM `vanguardamartech_ca_braga_consorcios_mao_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-smxd' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_pos_vendas_mao_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-elFk' AS _fonte, * FROM `vanguardamartech_leapmotor_vm_i_reserva_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-VJeY' AS _fonte, * FROM `vanguardamartech_unipar_ads_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-AJ09' AS _fonte, * FROM `vanguardamartech_vanguarda_comunicacao_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-KBUT' AS _fonte, * FROM `vanguardamartech_vbot_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-hIaw' AS _fonte, * FROM `vanguardamartech_millennium_ads_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-7NkZ' AS _fonte, * FROM `vanguardamartech_vega_bajaj_manaus_am_anuncios_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-I8ld' AS _fonte, * FROM `vanguardamartech_voike_ads_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-GZtZ' AS _fonte, * FROM `vanguardamartech_japura_pneus_facebook`.`facebook_ads_japura_pneusadsinsights` UNION ALL
SELECT 'facebook-ads-tWIP' AS _fonte, * FROM `vanguardamartech_farmabem_fb_ads`.`facebook_ads_adsinsights` UNION ALL
SELECT 'facebook-ads-bU6W' AS _fonte, * FROM `vanguardamartech_ca_braga_motos_2_fb_ads`.`facebook_ads_adsinsights`
),

-- colunas nomeadas UMA vez (mesma ordem e tipos dos ramos explicitos acima)
uniao_novas AS (
  SELECT
    n._fonte,
    n.id, n.account_id, n.account_name,
    n.campaign_id, n.campaign_name,
    n.adset_id, n.adset_name,
    n.ad_id, n.ad_name,
    n.date_start, n.date_stop,
    n.spend, n.impressions, n.reach, n.clicks,
    n.inline_link_clicks, n.inline_post_engagement, n.frequency,
    n.cpc, n.cpm, n.cpp, n.ctr, n.inline_link_click_ctr,
    n.quality_ranking, n.engagement_rate_ranking, n.conversion_rate_ranking,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(n.actions) a WHERE a.action_type IS NOT NULL)       AS acoes,
    ARRAY(SELECT AS STRUCT a.action_type AS tipo, SAFE_CAST(a.value AS FLOAT64) AS valor
          FROM UNNEST(n.action_values) a WHERE a.action_type IS NOT NULL) AS valores_acao,
    TO_HEX(MD5(TO_JSON_STRING((SELECT AS STRUCT n.* EXCEPT (_fonte))))) AS _payload_hash
  FROM uniao_novas_raw n
),

uniao AS (
  SELECT * FROM uniao_antigas
  UNION ALL
  SELECT * FROM uniao_novas
),

base AS (
  SELECT
    u._fonte,
    u.id                                               AS id_insight,
    u.account_id                                       AS id_conta,
    u.account_name                                     AS conta,
    u.account_name                                     AS cliente,
    u.campaign_id                                      AS id_campanha,
    u.campaign_name                                    AS campanha,
    u.adset_id                                         AS id_conjunto,
    u.adset_name                                       AS conjunto,
    u.ad_id                                            AS id_anuncio,
    u.ad_name                                          AS anuncio,
    SAFE_CAST(u.date_start AS DATE)                    AS data,
    SAFE_CAST(u.date_stop AS DATE)                     AS data_fim,
    DATE_TRUNC(SAFE_CAST(u.date_start AS DATE), MONTH) AS mes_referencia,

    SAFE_CAST(u.spend AS FLOAT64)                      AS investimento,
    SAFE_CAST(u.impressions AS INT64)                  AS impressoes_raw,
    SAFE_CAST(u.reach AS INT64)                        AS alcance_raw,
    SAFE_CAST(u.clicks AS INT64)                       AS cliques_raw,
    SAFE_CAST(u.inline_link_clicks AS INT64)           AS cliques_no_link_raw,
    SAFE_CAST(u.inline_post_engagement AS INT64)       AS engajamento_post_raw,
    SAFE_CAST(u.frequency AS FLOAT64)                  AS frequencia,

    SAFE_CAST(u.cpc AS FLOAT64)                        AS cpc_plataforma,
    SAFE_CAST(u.cpm AS FLOAT64)                        AS cpm_plataforma,
    SAFE_CAST(u.cpp AS FLOAT64)                        AS cpp_plataforma,
    SAFE_CAST(u.ctr AS FLOAT64)                        AS ctr_plataforma,
    SAFE_CAST(u.inline_link_click_ctr AS FLOAT64)      AS ctr_link_plataforma,

    NULLIF(u.quality_ranking, 'UNKNOWN')               AS ranking_qualidade,
    NULLIF(u.engagement_rate_ranking, 'UNKNOWN')       AS ranking_engajamento,
    NULLIF(u.conversion_rate_ranking, 'UNKNOWN')       AS ranking_conversao,

    u.acoes,
    u.valores_acao,
    u._payload_hash
  FROM uniao u
),

-- ultima data COM ENTREGA por conta: e o que revela fonte parada.
-- Dia sem entrega nao conta como sinal de vida.
frescor AS (
  SELECT
    id_conta,
    MAX(IF(investimento > 0 OR impressoes_raw > 0, data, NULL)) AS ultima_data_com_entrega
  FROM base
  GROUP BY id_conta
)

SELECT
  b._fonte,
  b.id_insight,
  b.id_conta, b.conta, b.cliente,
  b.id_campanha, b.campanha,
  b.id_conjunto, b.conjunto,
  b.id_anuncio, b.anuncio,

  b.data, b.data_fim, b.mes_referencia,

  b.investimento,
  IF(b.investimento = 0, IFNULL(b.impressoes_raw, 0),       b.impressoes_raw)       AS impressoes,
  IF(b.investimento = 0, IFNULL(b.alcance_raw, 0),          b.alcance_raw)          AS alcance,
  IF(b.investimento = 0, IFNULL(b.cliques_raw, 0),          b.cliques_raw)          AS cliques,
  IF(b.investimento = 0, IFNULL(b.cliques_no_link_raw, 0),  b.cliques_no_link_raw)  AS cliques_no_link,
  IF(b.investimento = 0, IFNULL(b.engajamento_post_raw, 0), b.engajamento_post_raw) AS engajamento_post,
  b.frequencia,

  b.cpc_plataforma, b.cpm_plataforma, b.cpp_plataforma,
  b.ctr_plataforma, b.ctr_link_plataforma,

  b.ranking_qualidade, b.ranking_engajamento, b.ranking_conversao,

  b.acoes,

  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'onsite_conversion.messaging_conversation_started_7d')AS conversas_iniciadas_7d,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'onsite_conversion.messaging_first_reply')AS primeiras_respostas,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'onsite_conversion.total_messaging_connection')AS conexoes_mensagem,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'lead')                            AS leads,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'purchase')                        AS compras,
  (SELECT SUM(a.valor) FROM UNNEST(b.valores_acao) a WHERE a.tipo = 'purchase')                 AS receita_compras,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'link_click')                      AS cliques_link_acao,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'landing_page_view')               AS visitas_landing_page,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'video_view')                      AS visualizacoes_video,
  (SELECT SUM(a.valor) FROM UNNEST(b.acoes) a WHERE a.tipo = 'page_engagement')                 AS engajamento_pagina,

  (b.impressoes_raw IS NULL AND b.investimento = 0)                              AS sem_entrega,

  -- FLAG DE DEFASAGEM: o conserto do problema que deixou 4 clientes congelados
  -- sem ninguem notar. Quem le a tabela ve a conta parada, nao dado velho com
  -- cara de dado bom.
  f.ultima_data_com_entrega,
  DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), f.ultima_data_com_entrega, DAY)    AS dias_sem_entrega,
  (DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), f.ultima_data_com_entrega, DAY) > 9) AS conta_defasada,

  CURRENT_TIMESTAMP()                                                            AS _extraido_at,
  b._payload_hash
FROM base b
LEFT JOIN frescor f ON f.id_conta = b.id_conta
