-- trs_vjob__biblioteca_item · query-Bfgi · Trusted / VJOB · L2 INTERNAL. Grao: um item da biblioteca. Chave: (origem, id_origem).
-- Origem: mysql-yIOn, tblinks/tblinks2/tblinks3, tbdownloads, tbsgi, tbpdf_atas. Gatilho: evento em query-MZdN.
-- Grupo/subgrupo saem como id cru: os ids existem em todas as cinco tabelas de grupo, o pareamento nao e provavel.
-- Texto livre nao e emitido, so o tamanho. Datas: hora local, sem conversao.
-- Medido em 02/10/2026: 251 linhas, 251 chaves; 230 links com 186 pares (titulo,url) distintos (44 repetidos, nao removidos).
WITH base AS (
SELECT 'LINK' AS origem, CAST(id AS INT64) AS id_origem, NULLIF(CAST(grupo AS INT64),0) AS id_grupo, NULLIF(CAST(subgrupo AS INT64),0) AS id_subgrupo, NULLIF(TRIM(titulolink),'') AS titulo, NULLIF(TRIM(urllink),'') AS url, CAST(NULL AS STRING) AS arquivo, CAST(modo AS INT64) AS modo, LENGTH(textocompleto) AS texto_chars, CAST(NULL AS INT64) AS id_conta_atendimento, CAST(NULL AS STRING) AS mes_ref, CAST(NULL AS INT64) AS ano_ref, CAST(NULL AS INT64) AS id_setor, CAST(NULL AS INT64) AS id_usuario, CAST(datacadastro AS TIMESTAMP) AS cadastrado_em FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tblinks`
UNION ALL SELECT 'LINK_2', CAST(id AS INT64), NULLIF(CAST(grupo AS INT64),0), NULLIF(CAST(subgrupo AS INT64),0), NULLIF(TRIM(titulolink),''), NULLIF(TRIM(urllink),''), NULLIF(TRIM(arquivo),''), CAST(modo AS INT64), LENGTH(textocompleto), NULL, NULL, NULL, NULL, NULL, CAST(datacadastro AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tblinks2`
UNION ALL SELECT 'LINK_3', CAST(id AS INT64), NULLIF(CAST(grupo AS INT64),0), NULLIF(CAST(subgrupo AS INT64),0), NULLIF(TRIM(titulolink),''), NULLIF(TRIM(urllink),''), NULLIF(TRIM(arquivo),''), CAST(modo AS INT64), LENGTH(textocompleto), NULL, NULL, NULL, NULL, NULL, CAST(datacadastro AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tblinks3`
UNION ALL SELECT 'DOWNLOAD', CAST(id AS INT64), NULLIF(CAST(grupo AS INT64),0), NULLIF(CAST(subgrupo AS INT64),0), NULLIF(TRIM(nomearquivo),''), NULL, NULLIF(TRIM(arquivo),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(datacadastro AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbdownloads`
UNION ALL SELECT 'SGI', CAST(id AS INT64), NULLIF(CAST(grupo AS INT64),0), NULLIF(CAST(subgrupo AS INT64),0), NULLIF(TRIM(nomearquivo),''), IF(REGEXP_CONTAINS(arquivo, r'^https?://'), TRIM(arquivo), NULL), NULLIF(TRIM(IF(REGEXP_CONTAINS(arquivo, r'^https?://'), arquivo2, CONCAT(arquivo, ' ', IFNULL(arquivo2, '')))),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(datacadastro AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbsgi`
UNION ALL SELECT 'ATA', CAST(id AS INT64), NULL, NULL, CAST(NULL AS STRING), NULL, NULLIF(TRIM(arquivo),''), NULL, NULL, CAST(cliente AS INT64), NULLIF(TRIM(CAST(mes AS STRING)),''), CAST(ano AS INT64), CAST(setor AS INT64), CAST(nome_quemmarcou AS INT64), CAST(datacadastro AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbpdf_atas`
),
tratado AS (
  SELECT b.*,
    IF(REGEXP_CONTAINS(b.url, r'^https?://'), REGEXP_EXTRACT(b.url, r'^https?://([^/]+)'), NULL) AS url_host,
    REGEXP_CONTAINS(IFNULL(b.url, ''), r'^https?://') AS flag_url_http,
    (b.url IS NULL AND b.arquivo IS NULL) AS flag_sem_destino,
    (b.id_conta_atendimento IS NOT NULL AND a.id IS NULL) AS flag_conta_nao_catalogada
  FROM base b LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbclientesatedimentos` a ON a.id = b.id_conta_atendimento
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
