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
