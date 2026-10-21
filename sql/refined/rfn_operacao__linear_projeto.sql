-- rfn_operacao__linear_projeto
-- Refined / operacao. Grao: um PROJETO interno do Linear (ou o balde "(sem projeto)"). Chave id_unidade.
-- Nivel: L2 INTERNAL -- so contagem, taxa e nome de projeto. Nenhum nome de pessoa sai daqui (lider, criador e
-- responsavel ficam na Trusted, que e L4); `qtd_responsaveis_distintos` e so um numero.
-- Origem: trs_linear__projeto (9, query-HyD5) + trs_linear__issue (230, query-lhYJ). Gatilho: evento com regra
-- "all" nas duas Trusted (irmas, as duas disparam em linear-byrt) -- a Refined nunca roda antes de uma delas.
--
-- O QUE ELA COMPRA: a carteira de projetos internos da agencia COM a leitura de issue ao lado, e a conferencia
-- do que o proprio Linear declara (escopo, progresso) contra o que as issues dizem. A rfn_operacao__issue_mensal
-- mede o fluxo por projeto E MES; esta e o retrato por projeto, sem o eixo de tempo.
--
-- ATENCAO -- O LINEAR PAROU DE SER USADO: ultima issue criada 28/07/2026, ultima conclusao 25/06/2026, nenhum
-- projeto concluido. Esta tabela e HISTORICO, nao acompanhamento de trabalho corrente.
--
-- REGRAS
--   R1  Universo = os 9 projetos da Trusted MAIS o balde "(sem projeto)" (26 das 230 issues). Projeto sem issue
--       (IAFIRST#1) entra com zero. A soma de qtd_issues sobre as linhas e exatamente o total da Trusted de issue.
--   R2  taxa_conclusao = concluidas / (issues - canceladas). Issue cancelada saiu do trabalho, como o proprio
--       Linear faz no `scope`. Sem issue viva a taxa e NULL, NUNCA zero.
--   R3  `qtd_escopo_linear` e a contagem de issues nao canceladas segundo o Linear; `flag_escopo_bate` confere contra
--       as issues: 9 de 9 batem (hoje). Se divergir, a issue perdeu ou ganhou linha no caminho.
--   R4  `progresso_linear` PASSA como o Linear entrega e NAO e a taxa de conclusao: `flag_progresso_diverge` acende
--       quando |progresso - taxa| > 0,0005. Hoje 3 de 8 projetos com issue divergem (BI Hub v2, SGQ v4.0, Saneamento
--       iClips). A Refined mostra os dois numeros; nao escolhe qual vale.
--   R5  `ultima_atualizacao_issue_em` NAO e atividade de trabalho: 17 issues foram tocadas entre 30/09 e 13/10/2026
--       (medido em 2026-10-18) e 9 delas foram CANCELADAS entre 02/10 e 13/10 (limpeza de backlog: as canceladas
--       passaram de 13 para 22), sem criar nem concluir nada. Quem mede atividade usa `ultima_criacao_em` e
--       `ultima_conclusao_em`; a limpeza aparece em `qtd_canceladas`.
--
-- LIMITACOES -- NAO CONTORNE
--   1. Projeto e interno da agencia, nao cliente de midia: nao ligar a rfn_cadastro__cliente.
--   2. 6 de 9 projetos sem lider, 4 sem prazo, 2 iniciados (cobertura vai junto com qualquer indicador).
--   3. 85% das issues sem responsavel (196 de 230): qtd_com_responsavel e piso, nao carga de trabalho.
--   4. Nao existe estimativa de esforco (estimate 0%) nem ciclo (0 linhas): taxa e por contagem de issue, que tem pesos diferentes.
WITH projeto AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_linear__projeto`
),
issue AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_linear__issue`
),
unidade AS (
  SELECT
    p.id_projeto AS id_unidade, p.nome AS projeto, p.estado AS projeto_estado, p.prioridade,
    p.progresso_linear, p.qtd_escopo_linear, p.dt_prazo, p.flag_sem_prazo, p.flag_sem_lider,
    (p.iniciado_em IS NOT NULL) AS is_iniciado, FALSE AS flag_sem_projeto
  FROM projeto p
  UNION ALL
  SELECT '(sem projeto)', '(sem projeto)', CAST(NULL AS STRING), CAST(NULL AS INT64),
         CAST(NULL AS FLOAT64), CAST(NULL AS INT64), CAST(NULL AS DATE), CAST(NULL AS BOOL),
         CAST(NULL AS BOOL), CAST(NULL AS BOOL), TRUE
),
agg AS (
  SELECT
    IFNULL(i.id_projeto, '(sem projeto)')                  AS id_unidade,
    COUNT(*)                                               AS qtd_issues,
    COUNTIF(i.is_concluida)                                AS qtd_concluidas,
    COUNTIF(i.is_cancelada)                                AS qtd_canceladas,
    COUNTIF(NOT i.is_concluida AND NOT i.is_cancelada)     AS qtd_abertas,
    COUNTIF(i.estado_tipo = 'started')                     AS qtd_em_andamento,
    COUNTIF(i.is_subtarefa)                                AS qtd_subtarefas,
    COUNTIF(NOT i.flag_sem_responsavel)                    AS qtd_com_responsavel,
    COUNT(DISTINCT i.id_responsavel)                       AS qtd_responsaveis_distintos,
    COUNTIF(i.qtd_rotulos > 0)                             AS qtd_com_rotulo,
    IFNULL(SUM(i.qtd_rotulos), 0)                          AS qtd_aplicacoes_de_rotulo,
    COUNTIF(i.dt_prazo IS NOT NULL)                        AS qtd_com_prazo,
    MIN(i.dt_criacao)                                      AS primeira_criacao_em,
    MAX(i.dt_criacao)                                      AS ultima_criacao_em,
    MAX(DATE(i.concluida_em))                              AS ultima_conclusao_em,
    MAX(DATE(i.atualizada_em))                             AS ultima_atualizacao_issue_em
  FROM issue i
  GROUP BY id_unidade
),
base AS (
  SELECT
    u.*,
    IFNULL(a.qtd_issues, 0)                    AS qtd_issues,
    IFNULL(a.qtd_concluidas, 0)                AS qtd_concluidas,
    IFNULL(a.qtd_canceladas, 0)                AS qtd_canceladas,
    IFNULL(a.qtd_abertas, 0)                   AS qtd_abertas,
    IFNULL(a.qtd_em_andamento, 0)              AS qtd_em_andamento,
    IFNULL(a.qtd_subtarefas, 0)                AS qtd_subtarefas,
    IFNULL(a.qtd_com_responsavel, 0)           AS qtd_com_responsavel,
    IFNULL(a.qtd_responsaveis_distintos, 0)    AS qtd_responsaveis_distintos,
    IFNULL(a.qtd_com_rotulo, 0)                AS qtd_com_rotulo,
    IFNULL(a.qtd_aplicacoes_de_rotulo, 0)      AS qtd_aplicacoes_de_rotulo,
    IFNULL(a.qtd_com_prazo, 0)                 AS qtd_com_prazo,
    a.primeira_criacao_em, a.ultima_criacao_em, a.ultima_conclusao_em, a.ultima_atualizacao_issue_em
  FROM unidade u
  LEFT JOIN agg a USING (id_unidade)
)
SELECT
  b.id_unidade,
  b.projeto,
  b.flag_sem_projeto,
  b.projeto_estado,
  b.prioridade,
  b.is_iniciado,
  b.flag_sem_lider,
  b.dt_prazo,
  b.flag_sem_prazo,
  b.qtd_issues,
  b.qtd_concluidas,
  b.qtd_canceladas,
  b.qtd_abertas,
  b.qtd_em_andamento,
  (b.qtd_issues - b.qtd_canceladas)                         AS qtd_issues_nao_canceladas,
  b.qtd_subtarefas,
  b.qtd_com_responsavel,
  b.qtd_responsaveis_distintos,
  b.qtd_com_rotulo,
  b.qtd_aplicacoes_de_rotulo,
  b.qtd_com_prazo,
  -- R2: NULL, nunca zero, quando nao ha issue viva.
  SAFE_DIVIDE(b.qtd_concluidas, NULLIF(b.qtd_issues - b.qtd_canceladas, 0)) AS taxa_conclusao,
  b.qtd_escopo_linear,
  -- R3: so existe para projeto (o balde nao tem escopo no Linear).
  IF(b.flag_sem_projeto, CAST(NULL AS BOOL),
     b.qtd_escopo_linear = (b.qtd_issues - b.qtd_canceladas)) AS flag_escopo_bate,
  b.progresso_linear,
  -- R4: o numero do Linear contra a taxa das issues. NULL sem taxa.
  IF(b.flag_sem_projeto OR (b.qtd_issues - b.qtd_canceladas) = 0, CAST(NULL AS BOOL),
     ABS(b.progresso_linear
         - SAFE_DIVIDE(b.qtd_concluidas, b.qtd_issues - b.qtd_canceladas)) > 0.0005) AS flag_progresso_diverge,
  b.primeira_criacao_em,
  b.ultima_criacao_em,
  b.ultima_conclusao_em,
  b.ultima_atualizacao_issue_em,
  CURRENT_TIMESTAMP()                                       AS _extraido_at,
  'linear-byrt'                                             AS _fonte
FROM base b
