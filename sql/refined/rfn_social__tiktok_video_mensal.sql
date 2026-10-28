WITH v AS (
  SELECT id_conta, mes_referencia,
         COUNT(*)                  AS qtd_videos,
         SUM(visualizacoes)        AS visualizacoes,
         SUM(curtidas)             AS curtidas,
         SUM(comentarios)          AS comentarios,
         SUM(compartilhamentos)    AS compartilhamentos,
         SUM(duracao_s)            AS duracao_total_s,
         MIN(data_local)           AS primeira_publicacao,
         MAX(data_local)           AS ultima_publicacao,
         ARRAY_AGG(_fonte LIMIT 1)[OFFSET(0)] AS _fonte
  FROM `vanguardamartech_trusted`.`trs_tiktok__video`
  GROUP BY id_conta, mes_referencia
)
SELECT
  CONCAT(v.id_conta, ':', FORMAT_DATE('%Y-%m', v.mes_referencia))        AS id_conta_mes,
  v.id_conta,
  c.usuario,
  v.mes_referencia,
  v.qtd_videos,
  v.visualizacoes,
  v.curtidas,
  v.comentarios,
  v.compartilhamentos,
  SAFE_DIVIDE(v.curtidas + v.comentarios + v.compartilhamentos, NULLIF(v.visualizacoes, 0)) AS taxa_engajamento,
  v.duracao_total_s,
  v.primeira_publicacao,
  v.ultima_publicacao,
  c.seguidores                                                           AS seguidores_na_carga,
  CURRENT_TIMESTAMP()                                                    AS _extraido_at,
  v._fonte                                                               AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(v)))                                         AS _payload_hash
FROM v
LEFT JOIN `vanguardamartech_trusted`.`trs_tiktok__conta` c ON c.id_conta = v.id_conta
