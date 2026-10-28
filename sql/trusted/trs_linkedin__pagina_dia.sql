-- trs_linkedin__pagina_dia · Trusted / linkedin · L2 INTERNAL
-- Grao: uma PAGINA (fonte) em um DIA. Chave: id_pagina_dia = <fonte>:<AAAA-MM-DD>.
-- Origem: linkedin-X9nQ (LinkedIn AC Display), camada vanguardamartech_linkedin_ac_display (R-001), streams
--   smdaily_member_post_analytics e smdaily_member_follower_statistics (INCREMENTAIS por date). Gatilho: evento em linkedin-X9nQ (cron segunda 00:00 America/Manaus).
-- REGRAS: R1 FULL OUTER entre os dois streams pela data; um dia que so exista num deles sai com a flag do lado ausente (nenhum dos dois e subconjunto do outro por contrato).
--   R2 `date` ja chega como DATE: nenhuma conversao de fuso e aplicada (o fuso de corte do LinkedIn nao e declarado pela API).
--   R3 seguidores_novos e o GANHO LIQUIDO do dia, nao o estoque; o estoque esta em trs_linkedin__pagina_total.
--   R4 metricas zero ficam zero: o stream entrega o dia inteiro com zeros, nao ha sentinela.
-- LIMITACAO: a serie so existe desde 13/10/2026 (14 dias na primeira medicao) e traz 3 impressoes contra 3.355 acumuladas; nao e serie historica.
WITH p AS (SELECT * FROM `vanguardamartech_linkedin_ac_display`.`linkedin_ac_display_smdaily_member_post_analytics`),
f AS (SELECT * FROM `vanguardamartech_linkedin_ac_display`.`linkedin_ac_display_smdaily_member_follower_statistics`)
SELECT
  CONCAT('linkedin-X9nQ', ':', CAST(COALESCE(p.date, f.date) AS STRING)) AS id_pagina_dia,
  COALESCE(p.date, f.date)                           AS data,
  DATE_TRUNC(COALESCE(p.date, f.date), MONTH)        AS mes_referencia,
  p.impressions                                      AS impressoes,
  p.reactions                                        AS reacoes,
  p.comments                                         AS comentarios,
  p.reshares                                         AS compartilhamentos,
  p.post_saves                                       AS salvamentos,
  p.post_sends                                       AS envios,
  p.premium_cta_clicks                               AS cliques_cta_premium,
  f.member_followers_count                           AS seguidores_novos,
  (p.date IS NULL)                                   AS flag_sem_post_analytics,
  (f.date IS NULL)                                   AS flag_sem_seguidores,
  CURRENT_TIMESTAMP()                                AS _extraido_at,
  'linkedin-X9nQ'                                    AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(p AS post, f AS seg)))) AS _payload_hash
FROM p FULL OUTER JOIN f ON p.date = f.date
