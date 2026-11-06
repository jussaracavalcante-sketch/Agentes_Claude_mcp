-- rfn_social__linkedin_pagina_mensal · Refined / social · L2 INTERNAL
-- Grao: uma PAGINA do LinkedIn em um MES (mes_referencia, calendario do dia da Trusted). Chave: id_pagina_mes = <fonte>:<AAAA-MM>.
-- Le trs_linkedin__pagina_dia. REGRAS: R1 agrega e nao filtra: a soma das medidas reproduz a Trusted. R2 taxa_engajamento = (reacoes+comentarios+compartilhamentos)/impressoes,
-- NULL quando impressoes = 0 (nunca zero). R3 qtd_dias conta os dias da serie no mes; mes parcial (flag_mes_parcial) e o da primeira data e o da carga.
-- LIMITACAO: serie curta (desde 13/10/2026); o acumulado da pagina esta em rfn_social__linkedin_pagina_resumo e nao se soma com esta tabela.
SELECT
  CONCAT(d._fonte, ':', FORMAT_DATE('%Y-%m', d.mes_referencia)) AS id_pagina_mes,
  d._fonte                                AS fonte,
  d.mes_referencia                        AS mes_referencia,
  COUNT(*)                                AS qtd_dias,
  MIN(d.data)                             AS primeiro_dia,
  MAX(d.data)                             AS ultimo_dia,
  SUM(d.impressoes)                       AS impressoes,
  SUM(d.reacoes)                          AS reacoes,
  SUM(d.comentarios)                      AS comentarios,
  SUM(d.compartilhamentos)                AS compartilhamentos,
  SUM(d.salvamentos)                      AS salvamentos,
  SUM(d.envios)                           AS envios,
  SUM(d.cliques_cta_premium)              AS cliques_cta_premium,
  SUM(d.seguidores_novos)                 AS seguidores_novos,
  SAFE_DIVIDE(SUM(d.reacoes) + SUM(d.comentarios) + SUM(d.compartilhamentos), NULLIF(SUM(d.impressoes), 0)) AS taxa_engajamento,
  (d.mes_referencia = DATE_TRUNC(DATE(MAX(d._extraido_at), 'America/Sao_Paulo'), MONTH)) AS flag_mes_parcial,
  MAX(d._extraido_at)                     AS _extraido_at,
  d._fonte                                AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(d._fonte, d.mes_referencia, COUNT(*), SUM(d.impressoes), SUM(d.reacoes), SUM(d.seguidores_novos))))) AS _payload_hash
FROM `vanguardamartech_trusted`.`trs_linkedin__pagina_dia` d
GROUP BY d._fonte, d.mes_referencia
