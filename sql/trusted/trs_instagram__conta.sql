-- trs_instagram__conta
-- Cadastro da conta Instagram de cada uma das 12 fontes instagram-* (uma camada por fonte, R-001).
-- Grao: uma CONTA Instagram. Chave: id_conta. Origem: instagram_user_details (FULL_SYNC,
-- fotografia) + instagram_follower_count_historical (so para datar a fotografia).
-- Gatilho: cron semanal, terca 14:00 America/Manaus. L2 INTERNAL (perfil publico; a
-- foto de perfil NAO e emitida: URL de CDN que expira).
-- As regras numeradas, os numeros da validacao e as limitacoes estao na descricao da
-- transformacao, que e parte da entrega.
WITH u AS (
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
),
h AS (
  SELECT _fonte, MAX(date) AS dt
  FROM (
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
  )
  GROUP BY _fonte
)
SELECT
  u.id                                  AS id_conta,
  u.username                            AS usuario,
  NULLIF(TRIM(u.name), '')              AS nome,
  u.ig_id,
  NULLIF(TRIM(u.biography), '')         AS biografia,
  NULLIF(TRIM(u.website), '')           AS website,
  u.followers_count                     AS seguidores,
  u.follows_count                       AS seguindo,
  u.media_count                         AS qtd_midias_na_conta,
  DATE(h.dt)                            AS data_snapshot_seguidores,
  (u.followers_count < 100)             AS flag_menos_de_100_seguidores,
  CURRENT_TIMESTAMP()                   AS _extraido_at,
  u._fonte,
  TO_HEX(MD5(TO_JSON_STRING(u)))        AS _payload_hash
FROM u
LEFT JOIN h ON h._fonte = u._fonte
