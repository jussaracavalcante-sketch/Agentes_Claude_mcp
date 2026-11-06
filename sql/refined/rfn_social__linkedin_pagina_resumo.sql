-- rfn_social__linkedin_pagina_resumo · Refined / social · L2 INTERNAL
-- Grao: uma PAGINA do LinkedIn na carga. Chave: fonte. Le trs_linkedin__pagina_total (acumulado) e trs_linkedin__pagina_dia (cobertura da serie).
-- REGRAS: R1 acumulado e serie sao grandezas diferentes: cobertura_impressoes_pela_serie = impressoes da serie / impressoes acumuladas (0,09% na primeira medicao: 3 de 3.355)
--   mostra quanto do acumulado a serie diaria explica; nao e erro, e a idade da extracao. R2 taxa_engajamento_acumulada = (reacoes+comentarios+compartilhamentos)/impressoes_acumuladas, NULL se zero.
--   R3 seguidores_total e o estoque; seguidores_novos_na_serie e o ganho liquido so da janela da serie. R4 membros_alcancados nao soma entre paginas.
SELECT
  t._fonte                                AS fonte,
  t.data_carga                            AS data_carga,
  t.impressoes_acumuladas, t.membros_alcancados, t.reacoes, t.comentarios, t.compartilhamentos,
  t.salvamentos, t.envios, t.cliques_em_links, t.cliques_cta_premium, t.seguidores_total,
  SAFE_DIVIDE(t.reacoes + t.comentarios + t.compartilhamentos, NULLIF(t.impressoes_acumuladas, 0)) AS taxa_engajamento_acumulada,
  d.qtd_dias_serie, d.primeiro_dia_serie, d.ultimo_dia_serie, d.impressoes_na_serie, d.seguidores_novos_na_serie,
  SAFE_DIVIDE(d.impressoes_na_serie, NULLIF(t.impressoes_acumuladas, 0)) AS cobertura_impressoes_pela_serie,
  t._extraido_at                          AS _extraido_at,
  t._fonte                                AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(t._fonte, t.data_carga, t.impressoes_acumuladas, t.seguidores_total, d.qtd_dias_serie)))) AS _payload_hash
FROM `vanguardamartech_trusted`.`trs_linkedin__pagina_total` t
LEFT JOIN (
  SELECT _fonte, COUNT(*) AS qtd_dias_serie, MIN(data) AS primeiro_dia_serie, MAX(data) AS ultimo_dia_serie,
         SUM(impressoes) AS impressoes_na_serie, SUM(seguidores_novos) AS seguidores_novos_na_serie
  FROM `vanguardamartech_trusted`.`trs_linkedin__pagina_dia` GROUP BY _fonte
) d ON d._fonte = t._fonte
