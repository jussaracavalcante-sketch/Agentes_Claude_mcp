-- trs_vjob__compromisso (query-QDMA) · Trusted / VJOB · L2 INTERNAL. Grao: um compromisso, atividade ou horario de rotina. Chave: (origem, id_origem).
-- Origem: mysql-yIOn, tbagenda, tarefas, tbatividades, tbatividades2, tbcheck_atividade, tbcheck_horarios. Gatilho: evento em query-MZdN.
-- Hora do dia sai como texto 'HH:MM:SS'. Descricao longa nao e emitida, so o tamanho. Datas: hora local, sem conversao.
WITH base AS (
SELECT 'AGENDA' AS origem, CAST(id AS INT64) AS id_origem, CAST(NULL AS INT64) AS id_pai, NULLIF(TRIM(title),'') AS titulo, CAST(tipo AS STRING) AS tipo, CAST(NULL AS INT64) AS descricao_chars, CAST(NULL AS INT64) AS id_responsavel, CAST(NULL AS INT64) AS id_cadastrou, CAST(NULL AS INT64) AS id_conta_atendimento, CAST(NULL AS INT64) AS id_setor, CAST(NULL AS STRING) AS status_origem, CAST(NULL AS INT64) AS dia_semana, CAST(NULL AS STRING) AS hora_inicio, CAST(NULL AS STRING) AS hora_fim, CAST(NULL AS DATE) AS data_entrega, CAST(NULL AS DATE) AS data_especifica, CAST(`start` AS TIMESTAMP) AS inicio, CAST(`end` AS TIMESTAMP) AS fim, CAST(NULL AS BOOL) AS ativo, CAST(NULL AS TIMESTAMP) AS cadastrado_em FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbagenda`
UNION ALL SELECT 'TAREFA_PADRAO', CAST(id AS INT64), NULL, NULLIF(TRIM(descricao),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(horario_inicio AS STRING), CAST(horario_fim AS STRING), NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tarefas`
UNION ALL SELECT 'ATIVIDADE', CAST(id AS INT64), NULL, NULLIF(TRIM(titulo),''), NULL, LENGTH(descricao), CAST(responsavel AS INT64), CAST(quemcadastrou AS INT64), NULL, NULL, NULLIF(TRIM(status),''), NULL, NULL, NULL, CAST(dataentrega AS DATE), NULL, NULL, NULL, NULL, CAST(datacadastro AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbatividades`
UNION ALL SELECT 'ATIVIDADE_2', CAST(id AS INT64), NULL, NULLIF(TRIM(titulo),''), NULL, LENGTH(descricao), CAST(responsavel AS INT64), CAST(quemcadastrou AS INT64), CAST(cliente AS INT64), NULL, NULLIF(TRIM(status),''), NULL, NULL, NULL, CAST(dataentrega AS DATE), NULL, NULL, NULL, NULL, CAST(datacadastro AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbatividades2`
UNION ALL SELECT 'CHECK_ATIVIDADE', CAST(id AS INT64), NULL, NULLIF(TRIM(nome),''), NULLIF(TRIM(tipo),''), NULL, CAST(responsavel_id AS INT64), CAST(criado_por AS INT64), NULL, CAST(setor_id AS INT64), NULL, NULL, CAST(hora AS STRING), NULL, NULL, CAST(data_especifica AS DATE), NULL, NULL, CAST(ativo AS INT64)=1, CAST(criado_em AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbcheck_atividade`
UNION ALL SELECT 'CHECK_HORARIO', CAST(id AS INT64), CAST(atividade_id AS INT64), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(dia_semana AS INT64), CAST(hora AS STRING), NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbcheck_horarios`
),
tratado AS (
  SELECT b.*,
    (b.id_conta_atendimento IS NOT NULL AND a.id IS NULL) AS flag_conta_nao_catalogada,
    (b.origem = 'CHECK_HORARIO' AND c.id IS NULL) AS flag_atividade_nao_catalogada,
    (b.fim IS NOT NULL AND b.inicio IS NOT NULL AND b.fim < b.inicio) AS flag_fim_antes_do_inicio
  FROM base b
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbclientesatedimentos` a ON a.id = b.id_conta_atendimento
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbcheck_atividade` c ON c.id = b.id_pai AND b.origem = 'CHECK_HORARIO'
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
