-- trs_instagram__seguidores_dia
-- Serie de SEGUIDORES por conta: um ponto por extracao (a Raw e INCREMENTAL por `date`).
-- Grao: uma conta, uma data. Chave: id_seguidores_dia.
-- Origem: instagram_follower_count_historical. Gatilho: cron semanal, terca 14:00
-- America/Manaus. L2 INTERNAL. E a UNICA serie historica de seguidores desta familia:
-- instagram_user_details e FULL_SYNC e sobrescreve.
WITH f AS (
  SELECT 'instagram-wRZ1' AS _fonte, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-CfH8', * FROM `vanguardamartech_braga_motors_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-IZTB', * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-bv3u', * FROM `vanguardamartech_bap_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-209E', * FROM `vanguardamartech_bajaj_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-JJJ4', * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-rdCK', * FROM `vanguardamartech_automaster_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-gWSW', * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-K8dK', * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-CeJD', * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-Wajn', * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_follower_count_historical`
  UNION ALL SELECT 'instagram-oMgW', * FROM `vanguardamartech_ac_display_instagram`.`instagram_follower_count_historical`
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
  CONCAT(c.id_conta, ':', FORMAT_DATE('%Y-%m-%d', DATE(f.date))) AS id_seguidores_dia,
  c.id_conta,
  DATE(f.date)                          AS data,
  f.followers_count                     AS seguidores,
  CURRENT_TIMESTAMP()                   AS _extraido_at,
  f._fonte,
  TO_HEX(MD5(TO_JSON_STRING(f)))        AS _payload_hash
FROM f
JOIN c ON c._fonte = f._fonte
