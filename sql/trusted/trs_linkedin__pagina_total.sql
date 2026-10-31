-- trs_linkedin__pagina_total · Trusted / linkedin · L2 INTERNAL
-- Grao: uma PAGINA (fonte) na carga. Chave: _fonte. FOTOGRAFIA: smtotal_member_post_analytics e smlifetime_member_follower_count
--   sao FULL_SYNC e sobrescrevem; a linha vale na hora da extracao, sem historico. Gatilho: evento em linkedin-X9nQ (segunda 00:00 America/Manaus).
-- REGRAS: R1 `date` e NULO nas duas origens (100%): a data da fotografia e a da carga (_extraido_at), emitida como data_carga em America/Sao_Paulo.
--   R2 impressoes_acumuladas e membros_alcancados sao do periodo que o LinkedIn define para o total (nao declarado); NAO somam com a serie diaria.
--   R3 membros_alcancados e deduplicado pela API: nao somar entre paginas.
-- Medido em 2026-10-28: 3.355 impressoes, 625 membros alcancados, 63 reacoes, 9 comentarios, 636 seguidores.
WITH t AS (SELECT * FROM `vanguardamartech_linkedin_ac_display`.`linkedin_ac_display_smtotal_member_post_analytics`),
s AS (SELECT SUM(member_followers_count) AS seguidores_total, COUNT(*) AS qtd_linhas FROM `vanguardamartech_linkedin_ac_display`.`linkedin_ac_display_smlifetime_member_follower_count`)
SELECT
  'linkedin-X9nQ'                         AS _fonte,
  CURRENT_DATE('America/Sao_Paulo')       AS data_carga,
  t.impressions                           AS impressoes_acumuladas,
  t.members_reached                       AS membros_alcancados,
  t.reactions                             AS reacoes,
  t.comments                              AS comentarios,
  t.reshares                              AS compartilhamentos,
  t.post_saves                            AS salvamentos,
  t.post_sends                            AS envios,
  t.link_clicks                           AS cliques_em_links,
  t.premium_cta_clicks                    AS cliques_cta_premium,
  s.seguidores_total                      AS seguidores_total,
  CURRENT_TIMESTAMP()                     AS _extraido_at,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(t AS total, s AS seg)))) AS _payload_hash
FROM t CROSS JOIN s
