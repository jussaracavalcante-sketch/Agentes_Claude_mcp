-- trs_tiktok__conta · query-KUUW · Trusted / tiktok · L2 INTERNAL · 14 contas (28/10/2026)
-- Grao: uma CONTA de TikTok lida por uma fonte. Chave: id_conta (open_id). Origem: stream user_info (FULL_SYNC) das fontes tiktok-*, uma camada por fonte (R-001).
-- Gatilho: cron semanal, terca 14:00 America/Manaus; as fontes rodam terca 01:00. Fonte nova entra so editando a uniao.
-- Nao emitidos: avatar_url, bio_description e union_id. Copia fiel do deploy (get_code, 28/10); o repositorio nao tinha este arquivo.
WITH u AS (
  SELECT 'tiktok-YF7S' AS f, * FROM `vanguardamartech_acesso_saude_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-SGs8', * FROM `vanguardamartech_bap_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-OolK', * FROM `vanguardamartech_amazoncopy_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-MA8p', * FROM `vanguardamartech_amazon_open_mall_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-ZYC5', * FROM `vanguardamartech_millennium_shopping_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-xA4g', * FROM `vanguardamartech_ba_eletrica_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-jPrf', * FROM `vanguardamartech_vanguarda_growth_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-HY3N', * FROM `vanguardamartech_santo_remedio_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-E0KJ', * FROM `vanguardamartech_rodrix_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-sc86', * FROM `vanguardamartech_comac_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-plcq', * FROM `vanguardamartech_cdl_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-GTbY', * FROM `vanguardamartech_constroi_incorporadora_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-mDQW', * FROM `vanguardamartech_unipar_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-HzZK', * FROM `vanguardamartech_braga_veiculos_tik_tok`.`tiktok_user_info`
)
SELECT
  u.open_id                                 AS id_conta,
  NULLIF(TRIM(u.username), '')              AS usuario,
  NULLIF(TRIM(u.display_name), '')          AS nome,
  u.profile_deep_link                       AS link_perfil,
  u.is_verified                             AS is_verificada,
  u.follower_count                          AS seguidores,
  u.following_count                         AS seguindo,
  u.likes_count                             AS curtidas_total,
  u.video_count                             AS qtd_videos_no_perfil,
  CURRENT_TIMESTAMP()                       AS _extraido_at,
  u.f                                       AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(u)))            AS _payload_hash
FROM u
