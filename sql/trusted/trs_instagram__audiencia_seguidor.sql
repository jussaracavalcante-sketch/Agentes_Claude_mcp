-- trs_instagram__audiencia_seguidor
-- Demografia dos SEGUIDORES de cada conta: idade, genero, pais e cidade.
-- Grao: uma conta, uma dimensao, um valor. Chave: id_audiencia.
-- Origem: instagram_follower_demographics_{age,gender,country,city}_lifetime (FULL_SYNC,
-- fotografia sem data). Gatilho: cron semanal, terca 14:00 America/Manaus. L2 INTERNAL
-- (contagem agregada por segmento; nenhum seguidor e identificado).
WITH a AS (
  SELECT 'instagram-wRZ1' AS _fonte, 'IDADE' AS dimensao, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-CfH8', 'IDADE' AS dimensao, * FROM `vanguardamartech_braga_motors_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-IZTB', 'IDADE' AS dimensao, * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-bv3u', 'IDADE' AS dimensao, * FROM `vanguardamartech_bap_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-209E', 'IDADE' AS dimensao, * FROM `vanguardamartech_bajaj_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-JJJ4', 'IDADE' AS dimensao, * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-rdCK', 'IDADE' AS dimensao, * FROM `vanguardamartech_automaster_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-gWSW', 'IDADE' AS dimensao, * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-K8dK', 'IDADE' AS dimensao, * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-CeJD', 'IDADE' AS dimensao, * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-Wajn', 'IDADE' AS dimensao, * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL SELECT 'instagram-oMgW', 'IDADE' AS dimensao, * FROM `vanguardamartech_ac_display_instagram`.`instagram_follower_demographics_age_lifetime`
  UNION ALL
  SELECT 'instagram-wRZ1' AS _fonte, 'GENERO' AS dimensao, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-CfH8', 'GENERO' AS dimensao, * FROM `vanguardamartech_braga_motors_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-IZTB', 'GENERO' AS dimensao, * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-bv3u', 'GENERO' AS dimensao, * FROM `vanguardamartech_bap_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-209E', 'GENERO' AS dimensao, * FROM `vanguardamartech_bajaj_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-JJJ4', 'GENERO' AS dimensao, * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-rdCK', 'GENERO' AS dimensao, * FROM `vanguardamartech_automaster_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-gWSW', 'GENERO' AS dimensao, * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-K8dK', 'GENERO' AS dimensao, * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-CeJD', 'GENERO' AS dimensao, * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-Wajn', 'GENERO' AS dimensao, * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL SELECT 'instagram-oMgW', 'GENERO' AS dimensao, * FROM `vanguardamartech_ac_display_instagram`.`instagram_follower_demographics_gender_lifetime`
  UNION ALL
  SELECT 'instagram-wRZ1' AS _fonte, 'PAIS' AS dimensao, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-CfH8', 'PAIS' AS dimensao, * FROM `vanguardamartech_braga_motors_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-IZTB', 'PAIS' AS dimensao, * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-bv3u', 'PAIS' AS dimensao, * FROM `vanguardamartech_bap_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-209E', 'PAIS' AS dimensao, * FROM `vanguardamartech_bajaj_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-JJJ4', 'PAIS' AS dimensao, * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-rdCK', 'PAIS' AS dimensao, * FROM `vanguardamartech_automaster_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-gWSW', 'PAIS' AS dimensao, * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-K8dK', 'PAIS' AS dimensao, * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-CeJD', 'PAIS' AS dimensao, * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-Wajn', 'PAIS' AS dimensao, * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL SELECT 'instagram-oMgW', 'PAIS' AS dimensao, * FROM `vanguardamartech_ac_display_instagram`.`instagram_follower_demographics_country_lifetime`
  UNION ALL
  SELECT 'instagram-wRZ1' AS _fonte, 'CIDADE' AS dimensao, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-CfH8', 'CIDADE' AS dimensao, * FROM `vanguardamartech_braga_motors_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-IZTB', 'CIDADE' AS dimensao, * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-bv3u', 'CIDADE' AS dimensao, * FROM `vanguardamartech_bap_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-209E', 'CIDADE' AS dimensao, * FROM `vanguardamartech_bajaj_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-JJJ4', 'CIDADE' AS dimensao, * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-rdCK', 'CIDADE' AS dimensao, * FROM `vanguardamartech_automaster_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-gWSW', 'CIDADE' AS dimensao, * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-K8dK', 'CIDADE' AS dimensao, * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-CeJD', 'CIDADE' AS dimensao, * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-Wajn', 'CIDADE' AS dimensao, * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_follower_demographics_city_lifetime`
  UNION ALL SELECT 'instagram-oMgW', 'CIDADE' AS dimensao, * FROM `vanguardamartech_ac_display_instagram`.`instagram_follower_demographics_city_lifetime`
),
n AS (
  SELECT _fonte, dimensao, COUNT(*) AS qtd_valores
  FROM a GROUP BY _fonte, dimensao
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
  CONCAT(c.id_conta, ':', a.dimensao, ':', a.dimension_value) AS id_audiencia,
  c.id_conta,
  a.dimensao,
  a.dimension_value                     AS valor_dimensao,
  a.value                               AS qtd_seguidores,
  -- A API devolve no maximo 45 valores por dimensao de pais e de cidade: lista cheia = cortada.
  (a.dimensao IN ('PAIS', 'CIDADE') AND n.qtd_valores >= 45) AS flag_lista_truncada_no_top,
  CURRENT_TIMESTAMP()                   AS _extraido_at,
  a._fonte,
  TO_HEX(MD5(TO_JSON_STRING(a)))        AS _payload_hash
FROM a
JOIN n ON n._fonte = a._fonte AND n.dimensao = a.dimensao
JOIN c ON c._fonte = a._fonte
