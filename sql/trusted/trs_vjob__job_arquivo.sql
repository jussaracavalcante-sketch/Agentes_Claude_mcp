-- trs_vjob__job_arquivo
-- Trusted / VJOB. Grao: um anexo de job. Chave: id_arquivo_unico.
-- Origem: mysql-yIOn (VJOB real). L2 INTERNAL -- nome de arquivo, caminho e tipo MIME.
-- O CONTEUDO do arquivo nao esta nesta base; o que ha e o ponteiro.
--
-- DUAS ORIGENS, e a segunda quase ficou de fora: `tarefas_tbjobs_arquivos` (293) e
--   `advisory_tbjobs_arquivos` (9). O modulo APOSENTADO nao tem tabela de arquivo --
--   conferido, nao suposto. Total 302.
--
-- O `upload_token` NAO E EMITIDO -- secao 31 do documento de arquitetura: secret e L5 e
--   nao deve estar no Data Lake. Mesmo tratamento que o `public_token` recebeu na
--   `trs_vjob__job`. O que sai e `flag_upload_por_token`, que diz que o caminho de
--   upload publico foi usado sem revelar a credencial.
--
-- OS 5 ANEXOS COM TOKEN SAO EXATAMENTE OS 5 SEM JOB -- e isso nao e coincidencia, e o
--   mecanismo. Medido em 2026-09-24: dos 302 anexos, 5 carregam `upload_token` e esses
--   mesmos 5 tem `job_id` **nulo**. Sao uploads feitos pelo fluxo de token publico que
--   nunca foram amarrados a um job (03/08, 18/08 e 27/08 de 2026, um PDF e quatro JPEG).
--   **Nao e o buraco de cadastro** que aparece no resto do VJOB -- ali a linha aponta
--   para um id que nao existe mais; aqui ela nao aponta para lugar nenhum. Sao coisas
--   diferentes e saem em flags diferentes: `flag_anexo_sem_job` (o caso daqui) e
--   `flag_job_nao_catalogado` (o caso do resto da base, hoje ZERO nesta tabela).
--
-- FUSO: relogio local da intranet. **NAO CONVERTER.**
--
-- MEDIDO EM 2026-09-24: 302 linhas · 302 chaves · 196 jobs com anexo · zero caminho
--   vazio · zero job orfao · 7 tipos MIME (PDF, XLSX, DOCX, ZIP, JPEG, PNG, TXT) ·
--   ultimo upload **24/09/2026 10:26:26**, de hoje -- e uma das tabelas mais vivas do
--   VJOB.
WITH base AS (
  SELECT 'TAREFAS' AS origem, id, job_id, upload_token, caminho, nome_arquivo,
         tipo_mime, data_upload
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tarefas_tbjobs_arquivos`
  UNION ALL
  SELECT 'ADVISORY', id, job_id, upload_token, caminho, nome_arquivo,
         tipo_mime, data_upload
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_advisory_tbjobs_arquivos`
),
jobs AS (SELECT DISTINCT id_job_unico FROM `vanguardamartech_trusted`.`trs_vjob__job_tarefa`),
tratado AS (
  SELECT
    CONCAT(b.origem, ':', CAST(b.id AS STRING))                  AS id_arquivo_unico,
    b.origem,
    b.id                                                         AS id_arquivo,
    b.job_id                                                     AS id_job,
    IF(b.job_id IS NULL, NULL,
       CONCAT(b.origem, ':', CAST(b.job_id AS STRING)))          AS id_job_unico,

    NULLIF(TRIM(b.nome_arquivo), '')                             AS nome_arquivo,
    NULLIF(TRIM(b.caminho), '')                                  AS caminho,
    NULLIF(TRIM(b.tipo_mime), '')                                AS tipo_mime,
    -- Familia do MIME, para agrupar sem repetir a cadeia inteira na leitura.
    CASE
      WHEN STARTS_WITH(COALESCE(b.tipo_mime, ''), 'image/') THEN 'IMAGEM'
      WHEN COALESCE(b.tipo_mime, '') = 'application/pdf'    THEN 'PDF'
      WHEN COALESCE(b.tipo_mime, '') LIKE '%spreadsheet%'   THEN 'PLANILHA'
      WHEN COALESCE(b.tipo_mime, '') LIKE '%wordprocessing%' THEN 'DOCUMENTO'
      WHEN COALESCE(b.tipo_mime, '') = 'application/zip'    THEN 'COMPACTADO'
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
