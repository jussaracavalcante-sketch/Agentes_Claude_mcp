-- trs_instagram__midia
-- Uma MIDIA (post de feed, reel ou story) das 12 contas, com os insights da propria midia.
-- Grao: uma midia. Chave: id_midia (id global do Instagram). Origem: instagram_media +
-- instagram_media_insights (1:1 por media_id dentro da fonte). Gatilho: cron semanal,
-- terca 14:00 America/Manaus. L3 CONFIDENTIAL por carregar `legenda` (texto livre).
-- A extracao cobre SO uma janela curta (hoje 13-14/10/2026): ver a limitacao 1 na descricao.
WITH m AS (
  SELECT 'instagram-wRZ1' AS _fonte, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_media`
  UNION ALL SELECT 'instagram-CfH8', * FROM `vanguardamartech_braga_motors_instagram`.`instagram_media`
  UNION ALL SELECT 'instagram-IZTB', * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_media`
  UNION ALL SELECT 'instagram-bv3u', * FROM `vanguardamartech_bap_instagram`.`instagram_media`
  UNION ALL SELECT 'instagram-209E', * FROM `vanguardamartech_bajaj_instagram`.`instagram_media`
  UNION ALL SELECT 'instagram-JJJ4', * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_media`
  UNION ALL SELECT 'instagram-rdCK', * FROM `vanguardamartech_automaster_instagram`.`instagram_media`
  UNION ALL SELECT 'instagram-gWSW', * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_media`
  UNION ALL SELECT 'instagram-K8dK', * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_media`
  UNION ALL SELECT 'instagram-CeJD', * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_media`
  UNION ALL SELECT 'instagram-Wajn', * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_media`
  UNION ALL SELECT 'instagram-oMgW', * FROM `vanguardamartech_ac_display_instagram`.`instagram_media`
),
i AS (
  SELECT 'instagram-wRZ1' AS _fonte, * FROM `vanguardamartech_braga_veiculos_venda_direta_instagram`.`instagram_media_insights`
  UNION ALL SELECT 'instagram-CfH8', * FROM `vanguardamartech_braga_motors_instagram`.`instagram_media_insights`
  UNION ALL SELECT 'instagram-IZTB', * FROM `vanguardamartech_braga_acessorios_instagram`.`instagram_media_insights`
  UNION ALL SELECT 'instagram-bv3u', * FROM `vanguardamartech_bap_instagram`.`instagram_media_insights`
  UNION ALL SELECT 'instagram-209E', * FROM `vanguardamartech_bajaj_instagram`.`instagram_media_insights`
  UNION ALL SELECT 'instagram-JJJ4', * FROM `vanguardamartech_ba_eletrica_instagram`.`instagram_media_insights`
  UNION ALL SELECT 'instagram-gWSW', * FROM `vanguardamartech_amz_geradores_instagram`.`instagram_media_insights`
  UNION ALL SELECT 'instagram-K8dK', * FROM `vanguardamartech_amazoncopy_instagram`.`instagram_media_insights`
  UNION ALL SELECT 'instagram-CeJD', * FROM `vanguardamartech_amazon_open_mall_instagram`.`instagram_media_insights`
  UNION ALL SELECT 'instagram-Wajn', * FROM `vanguardamartech_acesso_saude_instagram`.`instagram_media_insights`
  UNION ALL SELECT 'instagram-oMgW', * FROM `vanguardamartech_ac_display_instagram`.`instagram_media_insights`
)
SELECT
  m.id                                                    AS id_midia,
  m.owner.id                                              AS id_conta,
  m.username                                              AS usuario,
  m.ig_id,
  m.shortcode,
  m.permalink,
  m.media_type                                            AS tipo_midia,
  m.media_product_type                                    AS produto,
  (m.media_product_type = 'STORY')                        AS is_story,
  (m.media_product_type = 'REELS')                        AS is_reel,
  (m.media_product_type = 'FEED')                         AS is_feed,

  m.timestamp                                             AS publicado_em,
  DATE(DATETIME(m.timestamp, 'America/Sao_Paulo'))        AS data_local,
  EXTRACT(HOUR FROM DATETIME(m.timestamp, 'America/Sao_Paulo')) AS hora_local,
  DATE_TRUNC(DATE(DATETIME(m.timestamp, 'America/Sao_Paulo')), MONTH) AS mes_referencia,

  NULLIF(m.caption, '')                                   AS legenda,
  IFNULL(LENGTH(NULLIF(m.caption, '')), 0)                AS legenda_caracteres,
  ARRAY_LENGTH(REGEXP_EXTRACT_ALL(IFNULL(m.caption, ''), r'#[\p{L}\p{N}_]+')) AS qtd_hashtags,
  ARRAY_LENGTH(REGEXP_EXTRACT_ALL(IFNULL(m.caption, ''), r'@[A-Za-z0-9_.]+'))      AS qtd_mencoes,

  m.is_comment_enabled                                    AS comentarios_habilitados,
  m.is_shared_to_feed                                     AS compartilhado_no_feed,
  m.boost_eligibility_info.eligible_to_boost              AS elegivel_para_impulsionar,

  -- Story nao tem curtida nem comentario no Instagram: a API devolve 0 e o insight devolve
  -- NULL (28 de 28 stories). Zero aqui e sentinela de "nao se aplica", nao medida.
  IF(m.media_product_type = 'STORY', NULL, m.like_count)      AS curtidas,
  IF(m.media_product_type = 'STORY', NULL, m.comments_count)  AS comentarios,

  i.reach                                                 AS alcance,
  i.views                                                 AS visualizacoes,
  i.total_interactions                                    AS interacoes_totais,
  i.shares                                                AS compartilhamentos,
  i.saved                                                 AS salvamentos,
  i.replies                                               AS respostas,
  i.follows                                               AS seguimentos,
  i.profile_visits                                        AS visitas_ao_perfil,
  i.ig_reels_avg_watch_time                               AS reels_tempo_medio_assistido_ms,
  i.ig_reels_video_view_total_time                        AS reels_tempo_total_assistido_ms,
  (i.media_id IS NOT NULL)                                AS tem_insight,

  CURRENT_TIMESTAMP()                                     AS _extraido_at,
  m._fonte,
  'America/Sao_Paulo'                                     AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(m)))                          AS _payload_hash
FROM m
LEFT JOIN i ON i._fonte = m._fonte AND i.media_id = m.id
