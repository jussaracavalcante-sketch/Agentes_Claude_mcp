-- trs_tiktok__video · query-jgxK · Trusted / tiktok · L3 CONFIDENTIAL (legenda e texto publicado) · 1.379 videos, 14 fontes (28/10/2026)
-- Grao: um VIDEO. Chave: id_video. Origem: stream videos (FULL_SYNC); a conta vem do user_info da mesma fonte (uma conta por fonte).
-- FUSO: create_time e epoch em segundos UTC; publicado_em = TIMESTAMP_SECONDS; data_local/hora_local/mes_referencia em America/Sao_Paulo.
-- Metricas sao fotografia da extracao (FULL_SYNC), nao serie. link_video sai sem parametros de rastreio. Nao emitidos: embed_html, embed_link, cover_image_url.
-- Gatilho: cron semanal, terca 14:00 America/Manaus. Copia fiel do deploy (get_code, 28/10); o repositorio nao tinha este arquivo.
WITH v AS (
  SELECT 'tiktok-YF7S' AS f, * FROM `vanguardamartech_acesso_saude_tik_tok`.`tiktok_videos`
  UNION ALL SELECT 'tiktok-SGs8', * FROM `vanguardamartech_bap_tik_tok`.`tiktok_videos`
  UNION ALL SELECT 'tiktok-OolK', * FROM `vanguardamartech_amazoncopy_tik_tok`.`tiktok_videos`
  UNION ALL SELECT 'tiktok-MA8p', * FROM `vanguardamartech_amazon_open_mall_tik_tok`.`tiktok_videos`
  UNION ALL SELECT 'tiktok-ZYC5', * FROM `vanguardamartech_millennium_shopping_tik_tok`.`tiktok_videos`
  UNION ALL SELECT 'tiktok-xA4g', * FROM `vanguardamartech_ba_eletrica_tik_tok`.`tiktok_videos`
  UNION ALL SELECT 'tiktok-jPrf', * FROM `vanguardamartech_vanguarda_growth_tik_tok`.`tiktok_videos`
  UNION ALL SELECT 'tiktok-HY3N', * FROM `vanguardamartech_santo_remedio_tik_tok`.`tiktok_videos`
  UNION ALL SELECT 'tiktok-E0KJ', * FROM `vanguardamartech_rodrix_tik_tok`.`tiktok_videos`
  UNION ALL SELECT 'tiktok-sc86', * FROM `vanguardamartech_comac_tik_tok`.`tiktok_videos`
  UNION ALL SELECT 'tiktok-plcq', * FROM `vanguardamartech_cdl_tik_tok`.`tiktok_videos`
  UNION ALL SELECT 'tiktok-GTbY', * FROM `vanguardamartech_constroi_incorporadora_tik_tok`.`tiktok_videos`
  UNION ALL SELECT 'tiktok-mDQW', * FROM `vanguardamartech_unipar_tik_tok`.`tiktok_videos`
  UNION ALL SELECT 'tiktok-HzZK', * FROM `vanguardamartech_braga_veiculos_tik_tok`.`tiktok_videos`
),
c AS (
  SELECT 'tiktok-YF7S' AS f, open_id FROM `vanguardamartech_acesso_saude_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-SGs8', open_id FROM `vanguardamartech_bap_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-OolK', open_id FROM `vanguardamartech_amazoncopy_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-MA8p', open_id FROM `vanguardamartech_amazon_open_mall_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-ZYC5', open_id FROM `vanguardamartech_millennium_shopping_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-xA4g', open_id FROM `vanguardamartech_ba_eletrica_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-jPrf', open_id FROM `vanguardamartech_vanguarda_growth_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-HY3N', open_id FROM `vanguardamartech_santo_remedio_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-E0KJ', open_id FROM `vanguardamartech_rodrix_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-sc86', open_id FROM `vanguardamartech_comac_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-plcq', open_id FROM `vanguardamartech_cdl_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-GTbY', open_id FROM `vanguardamartech_constroi_incorporadora_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-mDQW', open_id FROM `vanguardamartech_unipar_tik_tok`.`tiktok_user_info`
  UNION ALL SELECT 'tiktok-HzZK', open_id FROM `vanguardamartech_braga_veiculos_tik_tok`.`tiktok_user_info`
)
SELECT
  v.id                                                                   AS id_video,
  c.open_id                                                              AS id_conta,
  TIMESTAMP_SECONDS(v.create_time)                                       AS publicado_em,
  DATE(TIMESTAMP_SECONDS(v.create_time), 'America/Sao_Paulo')            AS data_local,
  EXTRACT(HOUR FROM DATETIME(TIMESTAMP_SECONDS(v.create_time), 'America/Sao_Paulo')) AS hora_local,
  DATE_TRUNC(DATE(TIMESTAMP_SECONDS(v.create_time), 'America/Sao_Paulo'), MONTH)     AS mes_referencia,
  NULLIF(TRIM(v.title), '')                                              AS titulo,
  NULLIF(TRIM(v.video_description), '')                                  AS legenda,
  REGEXP_REPLACE(v.share_url, r'\?.*$', '')                              AS link_video,
  v.duration                                                             AS duracao_s,
  v.height                                                               AS altura,
  v.width                                                                AS largura,
  v.view_count                                                           AS visualizacoes,
  v.like_count                                                           AS curtidas,
  v.comment_count                                                        AS comentarios,
  v.share_count                                                          AS compartilhamentos,
  CURRENT_TIMESTAMP()                                                    AS _extraido_at,
  v.f                                                                    AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(v)))                                         AS _payload_hash
FROM v
JOIN c ON c.f = v.f
