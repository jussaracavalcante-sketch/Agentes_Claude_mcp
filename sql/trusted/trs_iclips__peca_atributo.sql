-- trs_iclips__peca_atributo
-- Grao: uma linha por id_job_peca (peca de um job no iClips).
-- Origem: vanguardamartech_raw.supabase_public_fato_atividade (fonte supabase-x0tz).
-- ATENCAO: a origem NAO e grao de apontamento apesar do nome "fato_atividade".
-- Ela guarda UMA das ~3,9 etapas trabalhadas da peca. Ver bloco de limitacoes na descricao.

WITH base AS (
  SELECT * FROM `vanguardamartech_raw.supabase_public_fato_atividade`
),
limpo AS (
  SELECT
    -- chave e pai
    NULLIF(TRIM(t.job_peca_id), '')                       AS id_job_peca,
    NULLIF(TRIM(t.job_id), '')                            AS id_projeto,
    NULLIF(TRIM(t.project_name), '')                      AS nome_projeto,

    -- tipo de peca: piece_id tem 294 valores distintos em 54.056 linhas,
    -- e catalogo de tipo de peca, nao a instancia. A instancia e id_job_peca.
    NULLIF(TRIM(t.piece_id), '')                          AS id_tipo_peca,
    NULLIF(TRIM(t.piece_name), '')                        AS nome_tipo_peca,
    NULLIF(TRIM(t.task_piece), '')                        AS titulo_peca,

    -- cliente: identidade resolvida por id; client_name tem 203 grafias para 200 ids
    NULLIF(TRIM(t.client_id), '')                         AS id_cliente_iclips,
    NULLIF(TRIM(t.client_name), '')                       AS cliente_nome,
    NULLIF(REGEXP_REPLACE(IFNULL(t.client_cnpj, ''), r'[^0-9]', ''), '') AS cliente_cnpj,
    NULLIF(TRIM(t.client_group_name), '')                 AS cliente_grupo_nome,

    -- pessoas: id_executor tem 274 valores para 266 nomes; resolver por id
    NULLIF(TRIM(t.responsible_id), '')                    AS id_responsavel,
    NULLIF(TRIM(t.responsible), '')                       AS responsavel_nome,
    NULLIF(TRIM(t.assistant_id), '')                      AS id_assistente,
    NULLIF(TRIM(t.assistant), '')                         AS assistente_nome,
    NULLIF(TRIM(t.execution_responsible_id), '')          AS id_executor,
    NULLIF(TRIM(t.execution_responsible), '')             AS executor_nome,
    NULLIF(TRIM(t.nome_departamento), '')                 AS executor_departamento,

    -- status: string vazia e sentinela (2.405 linhas em job_peca_status)
    NULLIF(TRIM(t.status), '')                            AS status_projeto,
    NULLIF(TRIM(t.status_piece), '')                      AS status_peca,
    NULLIF(TRIM(t.job_peca_status), '')                   AS status_ou_etapa_corrente,

    -- datas (America/Sao_Paulo ja na origem; ver bloco de fuso na descricao)
    t.project_entry_date                                  AS projeto_entrada_em,
    t.project_approval_date                               AS projeto_aprovado_em,
    t.project_conclusion_estimate_date                    AS projeto_previsao_conclusao_em,
    t.project_status_change_date                          AS projeto_status_alterado_em,
    t.project_finished_date                               AS projeto_concluido_em,
    t.planned_initial_date                                AS peca_inicio_planejado,
    t.planned_end_date                                    AS peca_fim_planejado,
    t.data_inicio_peca_workflow                           AS peca_workflow_inicio,
    t.data_fim_peca_workflow                              AS peca_workflow_fim,

    -- etapa amostrada: prefixo declara que e UMA etapa, nao a peca inteira
    NULLIF(TRIM(t.workflow_id), '')                       AS etapa_amostrada_id,
    NULLIF(TRIM(t.workflow_normalizado), '')              AS etapa_amostrada_nome,
    NULLIF(TRIM(t.workflow), '')                          AS etapa_amostrada_nome_origem,
    t.play_start_date                                     AS etapa_amostrada_play_inicio,
    t.play_end_date                                       AS etapa_amostrada_play_fim,
    NULLIF(TRIM(t.refacao), '')                           AS etapa_amostrada_refacao_tipo,
    NULLIF(TRIM(t.refacao), '') IS NOT NULL               AS etapa_amostrada_refacao,

    -- medidas
    t.estimated_time                                      AS tempo_estimado_min,
    t.sla_time                                            AS sla_origem,
    t.employee_hourly_cost                                AS executor_valor_hora,

    -- linhagem
    t.processed_at                                        AS _extraido_at,
    TO_HEX(MD5(TO_JSON_STRING(t)))                        AS _payload_hash
  FROM base AS t
)
SELECT
  l.*,
  IFNULL(l.executor_valor_hora, 0) = 0                                       AS sem_custo_hora,
  l.cliente_cnpj IS NOT NULL AND LENGTH(l.cliente_cnpj) = 14                 AS cnpj_valido,
  TIMESTAMP_DIFF(l.etapa_amostrada_play_fim, l.etapa_amostrada_play_inicio, MINUTE) AS etapa_amostrada_duracao_min,
  DATE(l.etapa_amostrada_play_inicio)                                        AS data_etapa_amostrada,
  'America/Sao_Paulo'                                                        AS _fuso,
  'supabase.public.fato_atividade'                                           AS _fonte
FROM limpo AS l
