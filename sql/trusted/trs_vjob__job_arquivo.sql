-- trs_vjob__job_arquivo
-- Trusted / VJOB. Grao: um anexo de job. Chave: id_arquivo_unico.
-- Origem: mysql-yIOn (VJOB real). L2 INTERNAL -- nome de arquivo, caminho e tipo MIME.
-- O CONTEUDO do arquivo nao esta nesta base; o que ha e o ponteiro.
--
-- CORRIGIDA EM 2026-09-24, HORAS DEPOIS DE PUBLICADA, E O ERRO ERA MEU.
--   A primeira versao tinha 302 linhas e a descricao dizia, com todas as letras, que
--   "o modulo APOSENTADO nao tem tabela de arquivo -- conferido, nao suposto".
--   **Tem: `tbjobs_arquivos`, com 688 linhas** -- 69% do total. Eu pedi o DDL dela por
--   nome a `get_relevant_tables_ddl` e a ferramenta devolveu **outra tabela**, sem dizer
--   que a pedida nao estava no resultado; concluir ausencia dali foi o erro.
--   Achada no inventario dos 199 streams, por `COUNT(*)`.
--   **A LICAO, pela terceira vez nesta base:** `get_relevant_tables_ddl` com
--   `selected_tables` NAO e busca por nome -- ela filtra candidatos semanticos e
--   **omite em silencio** o que nao casou. Prova de ausencia e `COUNT(*)`, nunca uma
--   busca que voltou vazia. (Antes: `ia_geracoes` e `tbjobs_comentarios`.)
--
-- QUATRO ORIGENS, e as quatro foram contadas uma a uma:
--   `tarefas_tbjobs_arquivos` .... 293  modulo VIVO
--   `advisory_tbjobs_arquivos` ...   9  modulo VIVO
--   `tbjobs_arquivos` ............ 688  modulo APOSENTADO
--   `tbjobs_arquivos_geral` ......   0  modulo APOSENTADO (tbjobsgeral)
--   Total **990**, com **722 ids crus** -- 268 colisoes entre origens, por isso a
--   chave e composta.
--
-- `tbjobs_arquivos_geral` NAO TEM A COLUNA `upload_token`. Nao e nulo, e ausencia de
--   coluna: o fluxo de upload publico nunca existiu naquele modulo. Sai como NULL, com
--   `flag_upload_por_token` FALSE, e a tabela esta vazia hoje -- entra para que, se um
--   dia receber linha, ela nao fique fora em silencio.
--
-- O `upload_token` NAO E EMITIDO -- secao 31 do documento de arquitetura: secret e L5 e
--   nao deve estar no Data Lake. Mesmo tratamento que o `public_token` recebeu na
--   `trs_vjob__job`. O que sai e `flag_upload_por_token`, que diz que o caminho de
--   upload publico foi usado sem revelar a credencial.
--
-- OS ANEXOS COM TOKEN SAO EXATAMENTE OS ANEXOS SEM JOB -- e com as quatro origens a
--   igualdade continua exata: **28 com token, 28 sem `job_id`**, contra 5 e 5 na versao
--   parcial. Nao e coincidencia, e o mecanismo: upload pelo fluxo de token publico que
--   nunca foi amarrado a um job.
--   **Nao e o buraco de cadastro** que aparece no resto do VJOB -- ali a linha aponta
--   para um id que nao existe mais; aqui ela nao aponta para lugar nenhum. Sao coisas
--   diferentes e saem em flags diferentes: `flag_anexo_sem_job` (o caso daqui) e
--   `flag_job_nao_catalogado` (o caso do resto da base, hoje ZERO nesta tabela).
--
-- FUSO: relogio local da intranet. **NAO CONVERTER.**
--
-- MEDIDO EM 2026-09-24: 990 linhas · 990 chaves · 722 ids crus · 665 jobs com anexo ·
--   zero caminho vazio · zero job orfao · 8 tipos MIME · primeiro upload
--   **07/08/2025 11:48:30**, ultimo **24/09/2026 10:26:26** -- de hoje.
WITH base AS (
  SELECT 'TAREFAS' AS origem, id, job_id, upload_token, caminho, nome_arquivo,
         tipo_mime, data_upload
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tarefas_tbjobs_arquivos`
  UNION ALL
  SELECT 'ADVISORY', id, job_id, upload_token, caminho, nome_arquivo,
         tipo_mime, data_upload
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_advisory_tbjobs_arquivos`
  UNION ALL
  SELECT 'tbjobs', id, job_id, upload_token, caminho, nome_arquivo,
         tipo_mime, data_upload
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbjobs_arquivos`
  UNION ALL
  -- Esta origem NAO tem `upload_token` -- ausencia de coluna, nao valor nulo.
  SELECT 'tbjobsgeral', id, job_id, CAST(NULL AS STRING), caminho, nome_arquivo,
         tipo_mime, data_upload
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbjobs_arquivos_geral`
),
jobs AS (
  SELECT DISTINCT id_job_unico FROM `vanguardamartech_trusted`.`trs_vjob__job_tarefa`
  UNION DISTINCT
  SELECT DISTINCT id_job_unico FROM `vanguardamartech_trusted`.`trs_vjob__job`
),
tratado AS (
  SELECT
    CONCAT(b.origem, ':', CAST(b.id AS STRING))                  AS id_arquivo_unico,
    b.origem,
    b.id                                                         AS id_arquivo,
    b.job_id                                                     AS id_job,
    IF(b.job_id IS NULL, NULL,
       CONCAT(b.origem, ':', CAST(b.job_id AS STRING)))          AS id_job_unico,
    (b.origem IN ('tbjobs', 'tbjobsgeral'))                      AS is_modulo_aposentado,

    NULLIF(TRIM(b.nome_arquivo), '')                             AS nome_arquivo,
    NULLIF(TRIM(b.caminho), '')                                  AS caminho,
    NULLIF(TRIM(b.tipo_mime), '')                                AS tipo_mime,
    -- Familia do MIME, para agrupar sem repetir a cadeia inteira na leitura.
    CASE
      WHEN STARTS_WITH(COALESCE(b.tipo_mime, ''), 'image/') THEN 'IMAGEM'
      WHEN COALESCE(b.tipo_mime, '') = 'application/pdf'    THEN 'PDF'
      WHEN COALESCE(b.tipo_mime, '') LIKE '%spreadsheet%'   THEN 'PLANILHA'
      WHEN COALESCE(b.tipo_mime, '') LIKE '%wordprocessing%' THEN 'DOCUMENTO'
      WHEN COALESCE(b.tipo_mime, '') LIKE '%presentation%'  THEN 'APRESENTACAO'
      WHEN COALESCE(b.tipo_mime, '') = 'application/zip'    THEN 'COMPACTADO'
      WHEN STARTS_WITH(COALESCE(b.tipo_mime, ''), 'video/') THEN 'VIDEO'
      WHEN STARTS_WITH(COALESCE(b.tipo_mime, ''), 'text/')  THEN 'TEXTO'
      WHEN NULLIF(TRIM(b.tipo_mime), '') IS NULL            THEN NULL
      ELSE 'OUTRO'
    END                                                          AS categoria_arquivo,
    -- Extensao como a origem a escreveu, minuscula. Nao substitui o MIME.
    LOWER(NULLIF(REGEXP_EXTRACT(COALESCE(b.nome_arquivo, ''), r'\.([A-Za-z0-9]+)$'), '')) AS extensao,

    -- FUSO: relogio local. Nao converter.
    b.data_upload,

    -- O token em si NAO sai. So o fato de ter havido um.
    (NULLIF(TRIM(b.upload_token), '') IS NOT NULL)               AS flag_upload_por_token,
    -- Anexo que nao pertence a job nenhum -- diferente de apontar para job inexistente.
    (b.job_id IS NULL)                                           AS flag_anexo_sem_job,
    (b.job_id IS NOT NULL AND j.id_job_unico IS NULL)            AS flag_job_nao_catalogado
  FROM base b
  LEFT JOIN jobs j
    ON j.id_job_unico = CONCAT(b.origem, ':', CAST(b.job_id AS STRING))
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                            AS _extraido_at,
  'mysql-yIOn'                                                   AS _fonte,
  'America/Sao_Paulo'                                            AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                                 AS _payload_hash
FROM tratado t
