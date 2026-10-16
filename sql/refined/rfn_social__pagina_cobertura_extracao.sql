WITH pg AS (
  SELECT _fonte AS fonte, id_pagina, nome, categoria, seguidores, flag_seguidores_zero, is_pode_postar, is_publicada
  FROM `vanguardamartech_trusted`.`trs_facebook_pages__pagina`
),
ins AS (
  SELECT _fonte AS fonte, id_pagina, COUNT(*) AS qtd_dias_insight,
         MIN(data_metrica) AS primeiro_dia_insight, MAX(data_metrica) AS ultimo_dia_insight,
         SUM(media_views) AS media_views_total
  FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario`
  GROUP BY 1, 2
),
po AS (
  SELECT _fonte AS fonte, id_pagina, COUNT(*) AS qtd_posts,
         MIN(data_local) AS primeira_postagem, MAX(data_local) AS ultima_postagem
  FROM `vanguardamartech_trusted`.`trs_facebook_pages__post`
  GROUP BY 1, 2
),
av AS (
  SELECT _fonte AS fonte, COUNT(*) AS qtd_avaliacoes,
         MIN(data_local) AS primeira_avaliacao, MAX(data_local) AS ultima_avaliacao
  FROM `vanguardamartech_trusted`.`trs_facebook_pages__avaliacao`
  GROUP BY 1
)
SELECT
  CONCAT(pg.fonte, ':', pg.id_pagina)                                        AS id_pagina_fonte,
  pg.fonte,
  pg.id_pagina,
  pg.nome                                                                    AS nome_pagina,
  pg.categoria                                                               AS categoria_pagina,
  pg.seguidores,
  pg.flag_seguidores_zero,
  pg.is_pode_postar,
  pg.is_publicada,
  IFNULL(ins.qtd_dias_insight, 0)                                            AS qtd_dias_insight,
  ins.primeiro_dia_insight,
  ins.ultimo_dia_insight,
  ins.media_views_total,
  IFNULL(po.qtd_posts, 0)                                                    AS qtd_posts,
  po.primeira_postagem,
  po.ultima_postagem,
  IFNULL(av.qtd_avaliacoes, 0)                                               AS qtd_avaliacoes,
  av.primeira_avaliacao,
  av.ultima_avaliacao,
  (IFNULL(ins.qtd_dias_insight, 0) = 0)                                      AS flag_sem_insight,
  (IFNULL(ins.qtd_dias_insight, 0) BETWEEN 1 AND 6)                          AS flag_janela_curta,
  (IFNULL(po.qtd_posts, 0) = 0)                                              AS flag_sem_post_na_janela,
  (IFNULL(av.qtd_avaliacoes, 0) = 0)                                         AS flag_sem_avaliacao,
  DATE_DIFF(DATE(CURRENT_TIMESTAMP()), ins.ultimo_dia_insight, DAY)          AS defasagem_dias_na_carga,
  CURRENT_TIMESTAMP()                                                        AS _extraido_at,
  'facebook-pages'                                                           AS _fonte
FROM pg
LEFT JOIN ins ON ins.fonte = pg.fonte AND ins.id_pagina = pg.id_pagina
LEFT JOIN po  ON po.fonte  = pg.fonte AND po.id_pagina  = pg.id_pagina
LEFT JOIN av  ON av.fonte  = pg.fonte
