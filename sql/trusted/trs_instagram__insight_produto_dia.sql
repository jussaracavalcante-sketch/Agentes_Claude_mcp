-- trs_instagram__insight_produto_dia
-- Insights da conta quebrados por TIPO DE PRODUTO (AD, POST, REEL, STORY, CAROUSEL_CONTAINER).
-- Grao: uma conta, um dia, um produto. Chave: id_insight_produto.
-- Origem: instagram_insights_by_media_product_type (INCREMENTAL por `date`).
-- Gatilho: cron semanal, terca 14:00 America/Manaus. L2 INTERNAL.
-- O vocabulario de `produto` aqui NAO e o de trs_instagram__midia (POST x FEED, REEL x REELS,
-- CAROUSEL_CONTAINER sem equivalente): a tabela nao mapeia um no outro.
WITH p AS (
  SELECT 'instagram-wRZ1' AS _fonte, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_insights_by_media_product_type`
  UNION ALL SELECT 'instagram-CfH8', * FROM `vanguardamartech_braga_motors_instagram`.`instagram_insights_by_media_product_type`
  UNION ALL SELECT 'instagram-IZTB', * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_insights_by_media_product_type`
  UNION ALL SELECT 'instagram-bv3u', * FROM `vanguardamartech_bap_instagram`.`instagram_insights_by_media_product_type`
  UNION ALL SELECT 'instagram-209E', * FROM `vanguardamartech_bajaj_instagram`.`instagram_insights_by_media_product_type`
  UNION ALL SELECT 'instagram-JJJ4', * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_insights_by_media_product_type`
  UNION ALL SELECT 'instagram-rdCK', * FROM `vanguardamartech_automaster_instagram`.`instagram_insights_by_media_product_type`
  UNION ALL SELECT 'instagram-gWSW', * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_insights_by_media_product_type`
  UNION ALL SELECT 'instagram-K8dK', * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_insights_by_media_product_type`
  UNION ALL SELECT 'instagram-CeJD', * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_insights_by_media_product_type`
  UNION ALL SELECT 'instagram-Wajn', * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_insights_by_media_product_type`
  UNION ALL SELECT 'instagram-oMgW', * FROM `vanguardamartech_ac_display_instagram`.`instagram_insights_by_media_product_type`
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
  CONCAT(c.id_conta, ':', FORMAT_DATE('%Y-%m-%d', DATE(p.date)), ':', p.media_product_type) AS id_insight_produto,
  c.id_conta,
  DATE(p.date)                          AS data,
  p.media_product_type                  AS produto,
  (p.media_product_type = 'AD')         AS is_anuncio,
  p.reach                               AS alcance,
  p.views                               AS visualizacoes,
  p.total_interactions                  AS interacoes_totais,
  p.likes                               AS curtidas,
  p.comments                            AS comentarios,
  p.shares                              AS compartilhamentos,
  p.saves                               AS salvamentos,
  -- `saves` e ajustado pela plataforma e pode vir NEGATIVO (-1 medido); passa como entregue.
  (p.saves < 0)                         AS flag_salvamentos_negativo,
  CURRENT_TIMESTAMP()                   AS _extraido_at,
  p._fonte,
  TO_HEX(MD5(TO_JSON_STRING(p)))        AS _payload_hash
FROM p
JOIN c ON c._fonte = p._fonte
