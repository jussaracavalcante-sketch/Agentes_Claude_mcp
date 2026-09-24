-- trs_vjob__comentario_arquivo
-- Trusted / VJOB. Grao: um anexo de COMENTARIO. Chave: id_arquivo_unico.
-- Origem: mysql-yIOn (VJOB real). L2 INTERNAL -- nome de arquivo, caminho e tipo MIME.
-- O CONTEUDO do arquivo nao esta nesta base; o que ha e o ponteiro.
--
-- NAO E A `trs_vjob__job_arquivo` -- O PAI E OUTRO. La o anexo pende do JOB; aqui ele
--   pende do COMENTARIO. Duas tabelas separadas de proposito: juntar as duas num grao
--   so exigiria uma coluna "tipo de pai" e um id que as vezes e job e as vezes e
--   comentario, que e a receita para somar anexo duas vezes. Quem quiser o total de
--   anexos do VJOB soma as duas: **990 + 754 = 1.744**.
--
-- QUATRO ORIGENS, todas achadas no inventario dos 199 streams e contadas uma a uma:
--   `tarefas_tbjobs_comentarios_arquivos` .... 498  modulo VIVO
--   `tbjobs_comentarios_arquivos` ............ 249  modulo APOSENTADO
--   `advisory_tbjobs_comentarios_arquivos` ...   6  modulo VIVO
--   `tbjobs_comentarios_arquivos_geral` ......   1  modulo APOSENTADO (`tbjobsgeral`)
--   Total **754**, com **499 ids crus** -- 255 colisoes entre origens, por isso a chave
--   e composta. O caminho fisico confirma o pareamento: `uploads/comentarios/<id>/` nas
--   tres primeiras e `uploads/comentarios_geral/<id>/` na quarta.
--
-- `tbjobs_comentarios_arquivos_geral` NAO TEM A COLUNA `upload_token` -- ausencia de
--   coluna, nao valor nulo. Mesmo padrao do `tbjobs_arquivos_geral`: o fluxo de upload
--   publico nunca existiu naquele modulo.
--
-- O `upload_token` NAO E EMITIDO -- secao 31: secret e L5 e nao deve estar no Data Lake.
--   Sai `flag_upload_por_token`, que diz que o caminho publico foi usado sem revelar a
--   credencial.
--
-- **A IGUALDADE TOKEN = SEM-PAI SE CONFIRMA PELA TERCEIRA VEZ, E AGORA POR ORIGEM.**
--   Dos 754 anexos, **85 carregam token e exatamente os mesmos 85 tem `comentario_id`
--   nulo** -- e a igualdade vale dentro de cada origem: TAREFAS 70 e 70, tbjobs 15 e 15,
--   ADVISORY 0 e 0, geral 0 e 0. E o mesmo mecanismo ja medido na `trs_vjob__job_arquivo`
--   (28 e 28): upload pelo fluxo de token publico que nunca foi amarrado ao registro.
--   **Aqui a taxa e MUITO maior: 11,3% contra 2,8% no anexo de job.**
--   `flag_anexo_sem_comentario` (o caso daqui, 85) e `flag_comentario_nao_catalogado`
--   (apontar para comentario inexistente, hoje ZERO) sao coisas diferentes e saem
--   separadas.
--
-- ZERO ORFAOS NAS QUATRO ORIGENS, medido contra as quatro tabelas de comentario. O join
--   fica LEFT mesmo assim, pelo motivo de sempre nesta base.
--
-- O MIME NAO CLASSIFICA SOZINHO -- 8 de 754 (1,1%) sao inuteis, e a EXTENSAO salva 7.
--   1. **3 anexos tem MIME CONCATENADO E TRUNCADO:**
--      `application/vnd.openxmlformats-officedocument.wordprocessingml.documentapplication/vnd.openxmlformat`
--      -- dois tipos colados e cortados no meio. E defeito da origem, nao do transporte.
--   2. **4 anexos tem `application/octet-stream`**, que e o generico de "nao sei".
--   3. 1 anexo tem `application/msword`, que e legitimo (.doc legado).
--   Os 7 dos casos 1 e 2 sao **todos .docx** pela extensao. Entao `categoria_arquivo`
--   usa o MIME quando ele e bem formado e **cai para a extensao** quando ele e
--   malformado ou generico. Medido: **ZERO linhas caem em OUTRO e ZERO ficam sem
--   categoria**, contra 8 que cairiam se o MIME mandasse sozinho.
--   `flag_mime_malformado` e `flag_mime_generico` marcam os casos, e `tipo_mime`
--   preserva o valor cru -- **marcar, nunca apagar**.
--
-- FUSO: relogio local da intranet. **NAO CONVERTER.**
--
-- MEDIDO EM 2026-09-24: 754 linhas · 754 chaves · 499 ids crus · **384 comentarios com
--   anexo** de 1.311 (29,3%) · zero caminho vazio · zero nome vazio · zero extensao
--   ausente · zero data nula · 9 tipos MIME · primeiro upload **08/08/2025 20:32:49**,
--   ultimo **22/09/2026 16:44:58**.
WITH base AS (
  SELECT 'TAREFAS' AS origem, id, comentario_id, upload_token, caminho, nome_arquivo,
         tipo_mime, data_upload
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tarefas_tbjobs_comentarios_arquivos`
  UNION ALL
  SELECT 'ADVISORY', id, comentario_id, upload_token, caminho, nome_arquivo,
         tipo_mime, data_upload
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_advisory_tbjobs_comentarios_arquivos`
  UNION ALL
  SELECT 'tbjobs', id, comentario_id, upload_token, caminho, nome_arquivo,
         tipo_mime, data_upload
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbjobs_comentarios_arquivos`
  UNION ALL
  -- Esta origem NAO tem `upload_token` -- ausencia de coluna, nao valor nulo.
  SELECT 'tbjobsgeral', id, comentario_id, CAST(NULL AS STRING), caminho, nome_arquivo,
         tipo_mime, data_upload
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbjobs_comentarios_arquivos_geral`
),
comentarios AS (
  SELECT DISTINCT id_comentario_unico
  FROM `vanguardamartech_trusted`.`trs_vjob__job_comentario`
),
prep AS (
  SELECT
    b.origem,
    b.id,
    b.comentario_id,
    b.caminho,
    b.nome_arquivo,
    b.data_upload,
    NULLIF(TRIM(b.upload_token), '')                                    AS token,
    NULLIF(TRIM(b.tipo_mime), '')                                       AS mime,
    LOWER(NULLIF(REGEXP_EXTRACT(COALESCE(b.nome_arquivo, ''), r'\.([A-Za-z0-9]+)$'), '')) AS ext
  FROM base b
),
tratado AS (
  SELECT
    CONCAT(p.origem, ':', CAST(p.id AS STRING))                         AS id_arquivo_unico,
    p.origem,
    p.id                                                                AS id_arquivo,
    p.comentario_id                                                     AS id_comentario,
    IF(p.comentario_id IS NULL, NULL,
       CONCAT(p.origem, ':', CAST(p.comentario_id AS STRING)))          AS id_comentario_unico,
    (p.origem IN ('tbjobs', 'tbjobsgeral'))                             AS is_modulo_aposentado,

    NULLIF(TRIM(p.nome_arquivo), '')                                    AS nome_arquivo,
    NULLIF(TRIM(p.caminho), '')                                         AS caminho,
    p.mime                                                              AS tipo_mime,
    p.ext                                                               AS extensao,

    -- MIME bem formado e exatamente `tipo/subtipo`. Os 3 concatenados tem dois `/`.
    NOT REGEXP_CONTAINS(COALESCE(p.mime, 'x/y'), r'^[^/]+/[^/]+$')      AS flag_mime_malformado,
    (p.mime = 'application/octet-stream')                               AS flag_mime_generico,

    -- Categoria: MIME quando confiavel, EXTENSAO quando ele e malformado ou generico.
    CASE
      WHEN REGEXP_CONTAINS(COALESCE(p.mime, 'x/y'), r'^[^/]+/[^/]+$')
           AND p.mime <> 'application/octet-stream' THEN
        CASE
          WHEN STARTS_WITH(p.mime, 'image/')          THEN 'IMAGEM'
          WHEN p.mime = 'application/pdf'             THEN 'PDF'
          WHEN p.mime LIKE '%spreadsheet%'            THEN 'PLANILHA'
          WHEN p.mime LIKE '%wordprocessing%'
            OR p.mime = 'application/msword'          THEN 'DOCUMENTO'
          WHEN p.mime LIKE '%presentation%'           THEN 'APRESENTACAO'
          WHEN p.mime = 'application/zip'             THEN 'COMPACTADO'
          WHEN STARTS_WITH(p.mime, 'video/')          THEN 'VIDEO'
          WHEN STARTS_WITH(p.mime, 'text/')           THEN 'TEXTO'
          ELSE 'OUTRO'
        END
      ELSE
        CASE
          WHEN p.ext IN ('png','jpg','jpeg','gif','webp','svg')  THEN 'IMAGEM'
          WHEN p.ext = 'pdf'                                     THEN 'PDF'
          WHEN p.ext IN ('xlsx','xls','csv')                     THEN 'PLANILHA'
          WHEN p.ext IN ('docx','doc')                           THEN 'DOCUMENTO'
          WHEN p.ext IN ('pptx','ppt')                           THEN 'APRESENTACAO'
          WHEN p.ext IN ('zip','rar','7z')                       THEN 'COMPACTADO'
          WHEN p.ext IN ('mp4','mov','avi')                      THEN 'VIDEO'
          WHEN p.ext IN ('txt','md')                             THEN 'TEXTO'
          WHEN p.ext IS NULL                                     THEN NULL
          ELSE 'OUTRO'
        END
    END                                                                 AS categoria_arquivo,
    -- Declara de onde a categoria veio, linha a linha.
    IF(REGEXP_CONTAINS(COALESCE(p.mime, 'x/y'), r'^[^/]+/[^/]+$')
       AND p.mime <> 'application/octet-stream', 'MIME', 'EXTENSAO')    AS origem_da_categoria,

    -- FUSO: relogio local. Nao converter.
    p.data_upload,

    -- O token em si NAO sai. So o fato de ter havido um.
    (p.token IS NOT NULL)                                               AS flag_upload_por_token,
    -- Anexo que nao pertence a comentario nenhum -- diferente de apontar para
    -- comentario inexistente.
    (p.comentario_id IS NULL)                                           AS flag_anexo_sem_comentario,
    (p.comentario_id IS NOT NULL AND c.id_comentario_unico IS NULL)     AS flag_comentario_nao_catalogado
  FROM prep p
  LEFT JOIN comentarios c
    ON c.id_comentario_unico = CONCAT(p.origem, ':', CAST(p.comentario_id AS STRING))
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                                   AS _extraido_at,
  'mysql-yIOn'                                                          AS _fonte,
  'America/Sao_Paulo'                                                   AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                                        AS _payload_hash
FROM tratado t
