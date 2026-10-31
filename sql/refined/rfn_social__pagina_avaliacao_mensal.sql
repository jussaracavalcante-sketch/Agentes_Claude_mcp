WITH base AS (
  SELECT
    _fonte AS fonte, mes_referencia,
    COUNT(*)                         AS qtd_avaliacoes,
    COUNTIF(is_positiva)             AS qtd_positivas,
    COUNTIF(NOT is_positiva)         AS qtd_negativas,
    COUNTIF(tem_texto)               AS qtd_com_texto
  FROM `vanguardamartech_trusted`.`trs_facebook_pages__avaliacao`
  GROUP BY 1, 2
),
acc AS (
  SELECT
    b.*,
    SUM(b.qtd_avaliacoes) OVER w AS qtd_avaliacoes_acumulada,
    SUM(b.qtd_positivas)  OVER w AS qtd_positivas_acumulada
  FROM base b
  WINDOW w AS (PARTITION BY b.fonte ORDER BY b.mes_referencia ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
)
SELECT
  CONCAT(a.fonte, ':', CAST(a.mes_referencia AS STRING))                     AS id_pagina_mes,
  a.fonte,
  p.id_pagina,
  p.nome                                                                     AS nome_pagina,
  p.categoria                                                                AS categoria_pagina,
  a.mes_referencia,
  a.qtd_avaliacoes,
  a.qtd_positivas,
  a.qtd_negativas,
  a.qtd_com_texto,
  SAFE_DIVIDE(a.qtd_positivas, a.qtd_avaliacoes)                             AS taxa_recomendacao_no_mes,
  a.qtd_avaliacoes_acumulada,
  a.qtd_positivas_acumulada,
  SAFE_DIVIDE(a.qtd_positivas_acumulada, a.qtd_avaliacoes_acumulada)         AS taxa_recomendacao_acumulada,
  (p.id_pagina IS NULL)                                                      AS flag_pagina_nao_catalogada,
  CURRENT_TIMESTAMP()                                                        AS _extraido_at,
  'facebook-pages'                                                           AS _fonte
FROM acc a
LEFT JOIN `vanguardamartech_trusted`.`trs_facebook_pages__pagina` p ON p._fonte = a.fonte
