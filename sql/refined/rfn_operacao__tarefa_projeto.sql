-- rfn_operacao__tarefa_projeto  ·  Refined / operacao  ·  8.835 linhas  ·  L2 INTERNAL
-- Grao: uma TAREFA de projeto do iClips. Chave: id_tarefa_job.
-- Origens: trs_iclips__tarefa (8.835) · trs_iclips__projeto (12.106) ·
--          trs_iclips__apontamento (5.580, so o que liga a tarefa).
-- Gatilho: evento em query-8nEt + query-9nws + query-tF7c com `event_rule = "all"`.
--   As tres Trusted disparam EM PARALELO no `notebook-Rbpo` e esta Refined le as tres.
--   Em vez de linearizar a cadeia alheia (o que esta casa ja fez quatro vezes), aqui se
--   usa o primitivo que a propria Nekt oferece: **`all` espera as tres**. Nao foi
--   preciso mexer em nenhum gatilho publicado.
-- As regras numeradas e os numeros da validacao estao na descricao da transformacao.
--
-- O ACHADO: **`qtd_apontamentos` da Trusted NAO conta apontamento** -- e
--   `ARRAY_LENGTH($.atividades)`. Soma **13.353** sobre 8.835 tarefas, enquanto a
--   `trs_iclips__apontamento` inteira tem **5.580** linhas e **103 ligam a tarefa**.
--   Aqui ela sai como `qtd_atividades_no_payload`.
--
-- R1 tempo real cobre **0,9%** (83 tarefas, 15,6 h) e sao DUAS causas: o vinculo e
--   exclusivo (peca OU tarefa) **e** a tabela de apontamento e JANELA MOVEL de ~2 meses
--   (21/07 a 29/09/2026) contra tarefa de 2020 a 2027 · R2 zero e SENTINELA: 8.477 de
--   8.835 sem estimativa, sai NULL · **os dois conjuntos sao DISJUNTOS e
--   `razao_gasto_sobre_estimado` e NULL em 8.835 de 8.835** · R3 projeto resolve 100%,
--   CNPJ em 97,5% · R4 o mes e o do INICIO PLANEJADO (a tarefa nao tem execucao) ·
--   R5 ha tarefa planejada ate 2027.
--
-- LIMITACAO 1: **a tarefa nao tem status nem conclusao.** `status_do_projeto` e do
--   PROJETO, nao dela.
--
-- FUSO: o iClips JA entrega `America/Sao_Paulo` e a Trusted nao converte. NAO CONVERTER.
WITH tarefa AS (
  SELECT
    id_tarefa_job, id_projeto, titulo_atividade,
    -- R2 - zero e sentinela de "sem estimativa", nao estimativa de zero minuto.
    NULLIF(tempo_estimado_min, 0)                     AS tempo_estimado_min,
    inicio_planejado, fim_planejado, tarefa_pos,
    -- O ACHADO: o nome da coluna na Trusted mente. Aqui ela sai pelo que e.
    qtd_apontamentos                                  AS qtd_atividades_no_payload,
    origem_do_registro, registro_historico, sem_data_planejada
  FROM `vanguardamartech_trusted`.`trs_iclips__tarefa`
),
projeto AS (
  SELECT DISTINCT
    id_projeto, nome_projeto, status_projeto_raw, verba,
    NULLIF(cliente_cnpj, '')   AS cliente_cnpj,
    NULLIF(cliente_nome, '')   AS cliente_nome,
    NULLIF(grupo_cliente_nome, '') AS grupo_cliente_nome,
    NULLIF(responsavel_principal_nome, '') AS responsavel_projeto,
    data_entrada, data_conclusao
  FROM `vanguardamartech_trusted`.`trs_iclips__projeto`
),
-- R1 - so o que liga a TAREFA. 103 de 5.580, cobrindo 83 tarefas.
apontado AS (
  SELECT
    id_tarefa_job,
    COUNT(*)                                          AS qtd_apontamentos_reais,
    SUM(tempo_gasto_min)                              AS tempo_gasto_min,
    COUNT(DISTINCT executor_id)                       AS qtd_executores,
    ROUND(SUM(SAFE_CAST(custo_estimado AS FLOAT64)), 2) AS custo_apontado,
    MIN(inicio_play)                                  AS primeiro_play,
    MAX(fim_play)                                     AS ultimo_play
  FROM `vanguardamartech_trusted`.`trs_iclips__apontamento`
  WHERE NULLIF(id_tarefa_job, '') IS NOT NULL
  GROUP BY 1
)
SELECT
  t.id_tarefa_job,
  t.id_projeto,
  p.nome_projeto,
  p.status_projeto_raw                                AS status_do_projeto,
  p.verba                                             AS verba_do_projeto,
  p.responsavel_projeto,
  p.data_entrada                                      AS projeto_entrada_em,
  p.data_conclusao                                    AS projeto_concluido_em,

  -- R3 - o projeto resolve 100%; a flag existe para detectar perda futura.
  p.cliente_cnpj,
  p.cliente_nome,
  p.grupo_cliente_nome,
  (p.id_projeto IS NULL)                              AS flag_projeto_nao_catalogado,
  (p.cliente_cnpj IS NULL)                            AS flag_sem_cnpj,

  -- LIMITACAO 3 - texto livre, 7.204 valores. Nao e dimensao.
  t.titulo_atividade,
  t.tarefa_pos,

  -- R4 - o mes e o do INICIO PLANEJADO. A tarefa nao tem data de execucao.
  t.inicio_planejado,
  t.fim_planejado,
  DATE(t.inicio_planejado)                            AS data_inicio_planejado,
  DATE_TRUNC(DATE(t.inicio_planejado), MONTH)         AS mes_referencia,
  IF(t.inicio_planejado IS NULL OR t.fim_planejado IS NULL, NULL,
     DATE_DIFF(DATE(t.fim_planejado), DATE(t.inicio_planejado), DAY))
                                                      AS duracao_planejada_dias,
  t.sem_data_planejada                                AS flag_sem_data_planejada,
  -- R5 - ha tarefa planejada ate 2027.
  COALESCE(t.inicio_planejado > CURRENT_TIMESTAMP(), FALSE)
                                                      AS flag_inicio_futuro,

  -- R2 - NULL, nunca zero.
  t.tempo_estimado_min,
  ROUND(t.tempo_estimado_min / 60, 2)                 AS tempo_estimado_horas,
  (t.tempo_estimado_min IS NULL)                      AS flag_sem_estimativa,

  -- R1 - cobre 0,9%. NULL nas demais, nunca zero.
  a.qtd_apontamentos_reais,
  a.tempo_gasto_min,
  ROUND(a.tempo_gasto_min / 60, 2)                    AS tempo_gasto_horas,
  a.qtd_executores,
  a.custo_apontado,
  a.primeiro_play,
  a.ultimo_play,
  (a.id_tarefa_job IS NULL)                           AS flag_sem_tempo_apontado,
  -- OS DOIS CONJUNTOS SAO DISJUNTOS: hoje esta coluna e NULL em 8.835 de 8.835.
  -- Sai NULL e nao zero porque zero seria uma afirmacao que a base nao faz.
  -- 08/10: apontamento COM ZERO MINUTO tambem sai NULL. 38 tarefas tem estimativa e
  -- apontamento real sem minuto registrado -- razao 0 diria "gastou 0% do estimado", e o
  -- apontamento sem minuto prova que alguem abriu o play, nao que nao houve trabalho.
  IF(NULLIF(a.tempo_gasto_min, 0) IS NULL OR t.tempo_estimado_min IS NULL, NULL,
     ROUND(SAFE_DIVIDE(a.tempo_gasto_min, t.tempo_estimado_min), 4))
                                                      AS razao_gasto_sobre_estimado,

  -- O ACHADO: e atividade no payload, nao apontamento.
  t.qtd_atividades_no_payload,

  t.origem_do_registro,
  t.registro_historico                                AS flag_registro_historico,

  CURRENT_TIMESTAMP()                                 AS _extraido_at,
  'supabase-x0tz'                                     AS _fonte,
  'America/Sao_Paulo'                                 AS _fuso
FROM tarefa t
LEFT JOIN projeto  p ON p.id_projeto     = t.id_projeto
LEFT JOIN apontado a ON a.id_tarefa_job  = t.id_tarefa_job
