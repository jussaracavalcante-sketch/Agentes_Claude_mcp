-- trs_vjob__job_comentario_cliente
-- A VOZ DO CLIENTE. As quatro origens de trs_vjob__job_comentario sao todas
-- internas; esta e a unica em que quem escreve esta do outro lado.
--
-- Total de comentario de job = 1.311 internos + 22 de cliente = 1.333.
-- Duas tabelas de proposito; quem contar conversa por job precisa das duas.
--
-- FUSO: o VJOB grava relogio local. Nada se converte.
WITH origem AS (
  SELECT
    id                                                          AS id_comentario_cliente,
    job_id                                                      AS id_job,
    NULLIF(cliente_at_id, 0)                                    AS id_atendimento,
    NULLIF(TRIM(autor_nome), '')                                AS autor_nome_na_origem,
    comentario                                                  AS comentario_html,
    created_at                                                  AS comentado_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_advisory_tbjobs_comentarios_clientes`
),
job AS (
  SELECT DISTINCT id_job, atividade, status AS status_do_job
  FROM `vanguardamartech_trusted`.`trs_vjob__job_tarefa`
  WHERE origem = 'ADVISORY'
),
conta AS (
  SELECT DISTINCT id_atendimento, nome_conta, id_cliente AS id_cliente_juridico
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`
),
prep AS (
  SELECT
    o.*,
    j.atividade                                                 AS job_atividade,
    j.status_do_job,
    (j.id_job IS NULL)                                          AS job_ausente,
    c.nome_conta,
    c.id_cliente_juridico,
    (o.id_atendimento IS NOT NULL AND c.id_atendimento IS NULL) AS conta_ausente,
    -- REGRA 4 - texto sem marcacao, so para leitura e contagem.
    NULLIF(TRIM(REGEXP_REPLACE(
      REGEXP_REPLACE(o.comentario_html, r'<[^>]*>', ' '), r'&nbsp;|&amp;|&lt;|&gt;', ' ')), '')
                                                                AS comentario_texto
  FROM origem o
  -- ANTI-JOIN por CTE DISTINCT, nao `NOT EXISTS` correlacionado.
  LEFT JOIN job   j ON j.id_job        = o.id_job
  LEFT JOIN conta c ON c.id_atendimento = o.id_atendimento
),
tratado AS (
  SELECT
    p.id_comentario_cliente,

    -- REGRA 3 - job_id sozinho NAO identifica o job: os mesmos ids existem em
    -- TAREFAS. O pai e ADVISORY, pelo modulo da propria tabela de origem.
    'ADVISORY'                                                  AS origem_do_job,
    p.id_job,
    CONCAT('ADVISORY:', CAST(p.id_job AS STRING))               AS id_job_unico,
    p.job_atividade,
    p.status_do_job,

    -- REGRA 2 - a conta de atendimento resolve 100%; a ponte juridica sai ao lado.
    p.id_atendimento,
    p.nome_conta,
    p.id_cliente_juridico,

    -- REGRA 1 - autor e TEXTO, nao id. A casa nao inventa identidade a partir dele.
    p.autor_nome_na_origem,

    -- REGRA 4 - o HTML cru sai inteiro; o texto limpo e derivado, nunca substituto.
    p.comentario_html,
    p.comentario_texto,
    LENGTH(IFNULL(p.comentario_texto, ''))                      AS qtd_caracteres,
    (p.comentario_texto IS NULL)                                AS flag_comentario_vazio,

    -- FUSO: relogio local. Nao converter.
    p.comentado_em,

    p.job_ausente                                               AS flag_job_nao_catalogado,
    p.conta_ausente                                             AS flag_conta_nao_catalogada
  FROM prep p
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'mysql-yIOn'                                                  AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                                AS _payload_hash
FROM tratado t
