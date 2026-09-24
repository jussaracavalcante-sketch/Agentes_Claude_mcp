-- trs_vjob__job_recorrencia
-- Trusted / VJOB. Grao: uma regra de recorrencia. Chave: id_recorrencia.
-- Origem: mysql-yIOn, `tarefas_tbjobs_recorrencias`. L2 INTERNAL.
--
-- SO O MODULO DE TAREFAS TEM RECORRENCIA -- conferido, nao suposto: nao existe
--   `advisory_tbjobs_recorrencias` nem equivalente no modulo aposentado. A chave aqui
--   NAO precisa ser composta, ao contrario do comentario e do anexo, porque a origem e
--   uma so. Declarado para que ninguem "padronize" a chave por simetria e passe a
--   carregar um prefixo que nao significa nada.
--
-- UM POR JOB, E ISSO E MEDIDO: 30 linhas, 30 `job_id` distintos, **zero orfaos**. E
--   relacao 1:1 com o job hoje. Se um dia aparecer job com duas regras, a contagem de
--   recorrencia deixa de ser contagem de job recorrente -- por isso a unicidade de
--   `id_job_unico` vira regra da suite, nao comentario aqui.
--
-- 30 DE 1.585 JOBS DO MODULO VIVO (1,9%) SAO RECORRENTES. O recurso existe e quase nao
--   se usa. Quem ler esta tabela como "os jobs que se repetem" esta lendo 2% da
--   operacao -- a cobertura tem de viajar junto com o numero.
--
-- O VOCABULARIO E PEQUENO E ESTA TODO AQUI, medido em 2026-09-24:
--   `tipo` ......... `semanal`, `personalizada`
--   `unidade` ...... `semana` (valor unico -- dimensao morta hoje)
--   `termina_tipo` . `data` (6 linhas), `nunca` (24)
--   `modo_mensal` .. `dia_mes` (valor unico)
--   Nao ha tabela de dominio para nenhum deles; os valores saem crus e a leitura fica
--   declarada aqui, sem rotular o que a base nao rotula.
--
-- `termina_em` E DATA, NAO INSTANTE -- ja vem DATE da origem, entao nao ha fuso a
--   aplicar. `criado_em` e TIMESTAMP com relogio local: **nao converter**.
--
-- `ocorrencias` E CAMPO MORTO: zero nas 30 linhas. Sai como NULL (via `NULLIF(...,0)`),
--   nunca como zero -- zero e um numero e seria somado; NULL diz ausencia. A regra
--   "termina apos N ocorrencias" existe no formulario e ninguem usou: as unicas duas
--   formas em uso sao `nunca` (24) e `data` (6). Nao modelar como dimensao.
--
-- 24 DAS 30 REGRAS NAO TERMINAM NUNCA. `flag_sem_fim` marca. Sao elas que geram job
--   indefinidamente, e sao o mesmo padrao do escopo recorrente que ficou ligado depois
--   de a operacao acabar (o caso TESTE HUGO SENNA, ja registrado nesta casa).
WITH tratado AS (
  SELECT
    r.id                                            AS id_recorrencia,
    r.job_id                                        AS id_job,
    CONCAT('TAREFAS:', CAST(r.job_id AS STRING))    AS id_job_unico,

    NULLIF(TRIM(r.tipo), '')                        AS tipo,
    r.intervalo,
    NULLIF(TRIM(r.unidade), '')                     AS unidade,
    NULLIF(TRIM(r.dias_semana), '')                 AS dias_semana,
    NULLIF(TRIM(r.modo_mensal), '')                 AS modo_mensal,

    NULLIF(TRIM(r.termina_tipo), '')                AS termina_tipo,
    r.termina_em,
    NULLIF(r.ocorrencias, 0)                        AS ocorrencias,
    (TRIM(COALESCE(r.termina_tipo, '')) = 'nunca')  AS flag_sem_fim,

    r.data_base,
    NULLIF(TRIM(r.resumo), '')                      AS resumo,
    -- FUSO: relogio local da intranet. Nao converter.
    r.criado_em,

    (j.id_job_unico IS NULL)                        AS flag_job_nao_catalogado
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tarefas_tbjobs_recorrencias` r
  LEFT JOIN (SELECT DISTINCT id_job_unico FROM `vanguardamartech_trusted`.`trs_vjob__job_tarefa`) j
    ON j.id_job_unico = CONCAT('TAREFAS:', CAST(r.job_id AS STRING))
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                               AS _extraido_at,
  'mysql-yIOn'                                      AS _fonte,
  'America/Sao_Paulo'                               AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                    AS _payload_hash
FROM tratado t
