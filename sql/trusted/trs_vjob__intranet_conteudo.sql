-- trs_vjob__intranet_conteudo (query-NlWT) · Trusted / VJOB · L2 INTERNAL. Grao: um conteudo publicado ou planejado. Chave: (origem, id_origem).
-- Origem: mysql-yIOn, tbnoticias, tbmaladireta, tbenquete(+respostas), tbquemsomos, tbgaleria(+fotos), postagemblog, tbmr.
-- Gatilho: evento em query-MZdN. Texto livre e nome de foto nao sao emitidos, so o tamanho. Datas: hora local.
WITH foto AS (SELECT CAST(idgaleria AS INT64) AS id_galeria, COUNT(*) AS qtd FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbgaleriafotos` GROUP BY 1),
base AS (
SELECT 'NOTICIA' AS origem, CAST(id AS INT64) AS id_origem, CAST(NULL AS INT64) AS id_pai, NULLIF(TRIM(titulo),'') AS titulo, NULLIF(TRIM(subtitulo),'') AS subtitulo, CAST(NULL AS INT64) AS id_conta_atendimento, CAST(NULL AS INT64) AS id_categoria, CAST(NULL AS INT64) AS id_usuario, CAST(NULL AS STRING) AS palavra_chave, CAST(NULL AS STRING) AS status_origem, CAST(NULL AS INT64) AS id_escopo, LENGTH(noticia) AS texto_chars, CAST(NULL AS INT64) AS qtd_itens, CAST(NULL AS INT64) AS total_votos, CAST(datainicio AS DATE) AS data_inicio, CAST(datafim AS DATE) AS data_fim, CAST(NULL AS TIMESTAMP) AS publicado_em, CAST(datacadastro AS TIMESTAMP) AS cadastrado_em FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbnoticias`
UNION ALL SELECT 'MALA_DIRETA', CAST(id AS INT64), NULL, NULLIF(TRIM(titulo),''), NULL, NULL, CAST(grupo AS INT64), NULL, NULL, NULL, NULL, LENGTH(noticia), NULL, NULL, NULL, NULL, NULL, CAST(datacadastro AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbmaladireta`
UNION ALL SELECT 'ENQUETE', CAST(e.id AS INT64), NULL, NULLIF(TRIM(e.pergunta),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, (IF(r.resposta1 IS NULL OR r.resposta1='',0,1)+IF(r.resposta2 IS NULL OR r.resposta2='',0,1)+IF(r.resposta3 IS NULL OR r.resposta3='',0,1)+IF(r.resposta4 IS NULL OR r.resposta4='',0,1)), CAST(r.qvotos1+r.qvotos2+r.qvotos3+r.qvotos4 AS INT64), CAST(e.datainicio AS DATE), CAST(e.datafim AS DATE), NULL, CAST(e.datacadastro AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbenquete` e LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbenqueterespostas` r ON r.idenquete = e.id
UNION ALL SELECT 'QUEM_SOMOS', CAST(id AS INT64), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, LENGTH(quemsomos), NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbquemsomos`
UNION ALL SELECT 'GALERIA', CAST(g.id AS INT64), NULL, NULLIF(TRIM(g.titulo),''), NULL, NULL, CAST(g.categoria AS INT64), NULL, NULL, NULL, NULL, NULL, IFNULL(f.qtd, 0), NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbgaleria` g LEFT JOIN foto f ON f.id_galeria = g.id
UNION ALL SELECT 'GALERIA_FOTO', CAST(id AS INT64), CAST(idgaleria AS INT64), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbgaleriafotos`
UNION ALL SELECT 'BLOG_POST', CAST(id AS INT64), CAST(id_postagem_wp AS INT64), NULLIF(TRIM(titulo),''), NULL, CAST(idempresa AS INT64), NULL, NULL, NULL, NULL, NULL, LENGTH(conteudo), NULL, NULL, NULL, NULL, CAST(data_postagem AS TIMESTAMP), CAST(datacadastro AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_postagemblog`
UNION ALL SELECT 'PAUTA_MR', CAST(id AS INT64), NULL, NULLIF(TRIM(pauta),''), NULL, CAST(cliente AS INT64), NULL, CAST(analista AS INT64), NULLIF(TRIM(palavrachave),''), NULLIF(TRIM(status),''), NULLIF(CAST(id_escopo AS INT64),0), NULL, NULL, NULL, CAST(mesano AS DATE), NULL, CAST(datapublicacao AS TIMESTAMP), CAST(datacadastro AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbmr`
),
tratado AS (
  SELECT b.*,
    (b.id_conta_atendimento IS NOT NULL AND a.id IS NULL) AS flag_conta_nao_catalogada,
    (b.origem = 'GALERIA_FOTO' AND g.id IS NULL) AS flag_galeria_nao_catalogada
  FROM base b
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbclientesatedimentos` a ON a.id = b.id_conta_atendimento
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbgaleria` g ON g.id = b.id_pai AND b.origem = 'GALERIA_FOTO'
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
