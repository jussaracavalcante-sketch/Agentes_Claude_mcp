-- trs_vjob__job_aprovacao_inicial
-- O porteiro do job do modulo vivo: quem pediu, quem decidiu, quando.
-- FUSO: o VJOB grava relogio local. Nada se converte.
WITH origem AS (
  SELECT
    id                                                          AS id_aprovacao,
    job_id                                                      AS id_job,
    NULLIF(TRIM(regra), '')                                     AS regra_na_origem,
    NULLIF(TRIM(status), '')                                    AS status_na_origem,
    NULLIF(decidida_por, 0)                                     AS id_decidida_por,
    decidida_em,
    NULLIF(TRIM(motivo_recusa), '')                             AS motivo_recusa,
    criada_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tarefas_tbjobs_aprovacao_inicial`
),
job AS (
  SELECT DISTINCT id_job, atividade, status AS status_do_job, data_cadastro
  FROM `vanguardamartech_trusted`.`trs_vjob__job_tarefa`
  WHERE origem = 'TAREFAS'
),
usuarios AS (
  SELECT DISTINCT id_usuario, NULLIF(TRIM(nome), '') AS nome
  FROM `vanguardamartech_trusted`.`trs_vjob__usuario`
),
prep AS (
  SELECT
    o.*,
    j.atividade                                                 AS job_atividade,
    j.status_do_job,
    j.data_cadastro                                             AS job_cadastrado_em,
    (j.id_job IS NULL)                                          AS job_ausente,
    u.nome                                                      AS decidida_por_nome,
    (o.id_decidida_por IS NOT NULL AND u.id_usuario IS NULL)    AS decisor_ausente
  FROM origem o
  -- ANTI-JOIN por CTE DISTINCT, nao `NOT EXISTS` correlacionado.
  LEFT JOIN job      j ON j.id_job     = o.id_job
  LEFT JOIN usuarios u ON u.id_usuario = o.id_decidida_por
),
tratado AS (
  SELECT
    p.id_aprovacao,
    p.id_job,
    p.job_atividade,
    p.status_do_job,
    p.job_cadastrado_em,

    -- REGRA 1 - `regra` e um NOME DE PESSOA em texto livre (`breno`, `jessica`),
    -- nao um criterio de roteamento. Sai cru: casar com o cadastro de usuario
    -- seria casamento por rotulo, e esta base nao trata rotulo como prova.
    p.regra_na_origem,

    p.status_na_origem,
    (p.status_na_origem = 'aprovada')                           AS flag_aprovada,
    (p.status_na_origem = 'recusada')                           AS flag_recusada,
    (p.status_na_origem = 'pendente')                           AS flag_pendente,

    p.id_decidida_por,
    p.decidida_por_nome,
    -- FUSO: relogio local. Nao converter.
    p.decidida_em,
    p.criada_em,

    -- REGRA 4 - motivo so existe na recusa, e ha uma so.
    p.motivo_recusa,

    -- REGRA 2 - duas invariantes, as duas hoje em ZERO. Se acenderem, o status
    -- deixa de concordar com o carimbo e a serie temporal passa a mentir.
    (p.status_na_origem IS NOT NULL
      AND p.status_na_origem <> 'pendente'
      AND p.decidida_em IS NULL)                                AS flag_decidida_sem_data,
    (p.status_na_origem = 'pendente'
      AND p.decidida_em IS NOT NULL)                            AS flag_pendente_com_data,

    -- Tempo ate a decisao, so onde a decisao existe.
    CASE
      WHEN p.decidida_em IS NULL THEN NULL
      ELSE TIMESTAMP_DIFF(p.decidida_em, p.criada_em, MINUTE)
    END                                                         AS minutos_ate_a_decisao,

    p.job_ausente                                               AS flag_job_nao_catalogado,
    p.decisor_ausente                                           AS flag_decisor_nao_catalogado
  FROM prep p
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'mysql-yIOn'                                                  AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                                AS _payload_hash
FROM tratado t
