-- trs_linear__issue
-- Trusted do Linear: uma issue por linha. Chave id_issue (e identificador, tambem unico).
-- Fonte: linear-byrt, stream `issues`, camada `Linear Vanguarda`,
-- tabela `vanguardamartech_linear_vanguarda.linear_vanguardaissues`.
--
-- O prefixo de tabela NAO segue o nome da camada: a tabela e
-- `linear_vanguarda` + nome do stream = `linear_vanguardaissues`.
-- Foi por causa disso que esta fonte foi dada por vazia em 18/09/2026 --
-- procurou-se `linear_issues`, que nao existe. Ela tem 230 issues.
--
-- VOLUME E UNICIDADE -- medido em 2026-09-21
--   230 linhas, 230 `id` distintos, 230 `identifier` distintos.
--   Unicidade provada nas DUAS chaves. Grao = issue.
--   Janela de criacao: 2026-04-01 a 2026-07-28. Ultimo updatedAt: 2026-08-01 04:25:19 UTC.
--
-- FUSO -- MEDIDO COLUNA A COLUNA, e as colunas NAO se comportam igual.
--   createdAt / updatedAt / startedAt / completedAt / canceledAt sao INSTANTES
--   de verdade: 226 de 230 createdAt e 64 de 67 completedAt tem hora != 00.
--   A origem entrega UTC, entao convertem com DATETIME(ts,'America/Sao_Paulo')
--   -- o padrao da familia Facebook Ads.
--   NUNCA TIMESTAMP(dt,'America/Sao_Paulo'): essa nao converte, interpreta um
--   relogio de parede COMO SE fosse SP e soma 3 horas. Custou seis tabelas do
--   iClips entre 21/08 e 15/09/2026.
--
--   dueDate e O CONTRARIO: e DATA disfarcada de TIMESTAMP. ZERO das 83 linhas
--   preenchidas tem hora != 00:00:00, e TODAS AS 83 mudariam de dia se lidas com
--   DATE(dueDate,'America/Sao_Paulo') -- meia-noite UTC e 21h do dia anterior em SP.
--   Por isso DATE(dueDate) puro, que le em UTC e devolve o dia certo.
--   Mesma armadilha ja registrada em supabase_silver_pi_insercao; segundo caso
--   confirmado na base, agora em outro sistema.
--
-- EMAIL FICA FORA. O stream traz assignee.email, creator.email,
-- subscribers[].email e comments[].user.email. A Trusted emite id, nome e
-- displayName -- nunca o endereco. Precedente na casa: a descricao da camada
-- `Gestao de Projetos do iClips` manda descartar cpf e valorHora na leitura.
--
-- ARRAY NAO ENTRA. `rotulos` sai como texto separado por " | " em vez de
-- ARRAY<STRING>, porque o wrapper da Nekt exporta via EXPORT DATA e qualquer
-- SELECT * sobre coluna repetida quebra com "Only simple types may be exported
-- as CSV". Era o que impedia ler o stream cru.
--
-- LIMITACOES -- NAO CONTORNE
--   1. `cycle` e 100% NULL nas 230 linhas. Campo morto -- nao modelar sprint/ciclo
--      a partir desta fonte. Existe o stream `cycles`, que e outro assunto.
--   2. `estimate` e 0% preenchido. Nao existe indicador de esforco aqui.
--   3. 196 das 230 issues (85%) nao tem responsavel. Qualquer indicador por
--      responsavel cobre 15% da base -- declarar a cobertura junto com o numero.
--   4. Existe UMA equipe (`VAN`). `team` nao e dimensao util hoje; fica na tabela
--      para o dia em que houver a segunda.
--   5. `archivedAt` e 100% NULL, `previousIdentifiers` e 100% vazio e
--      `customerTicketCount` e 0 em todas as linhas. Os tres ficam fora.
--   6. `boardOrder` e `sortOrder` sao ordenacao de tela, nao informacao de
--      negocio. Ficam fora.
--   7. A issue NAO carrega cliente. `project.name` e projeto interno da agencia
--      (SGQ v4.0, Vanguarda BI Hub v2, App01 E-mail Marketing...), nao cliente de
--      midia. Nao ligar esta tabela a rfn_cadastro__cliente.
--   8. Nenhum campo data a acao de concluir alem de completedAt/canceledAt --
--      mudanca de estado intermediaria nao tem historico neste stream.
WITH base AS (
  SELECT
    'linear-byrt' AS _fonte,
    i.id,
    i.identifier,
    i.number,
    i.title,
    i.description,
    i.url,
    i.branchName,
    i.state,
    i.team,
    i.project,
    i.assignee,
    i.creator,
    i.parent,
    i.priority,
    i.priorityLabel,
    i.createdAt,
    i.updatedAt,
    i.startedAt,
    i.completedAt,
    i.canceledAt,
    i.dueDate,
    -- rotulos: 29 issues com 49 rotulos no total (2026-09-21)
    ARRAY_TO_STRING(ARRAY(SELECT l.name FROM UNNEST(i.labels.nodes) l ORDER BY l.name), ' | ') AS rotulos,
    ARRAY_LENGTH(i.labels.nodes)      AS qtd_rotulos,
    -- comentarios: 88 comentarios em 50 issues (2026-09-21). O corpo e o autor
    -- ficam fora: corpo e texto livre (assunto de camada semantica, nao de
    -- Trusted) e autor traz email.
    ARRAY_LENGTH(i.comments.nodes)    AS qtd_comentarios,
    (SELECT MAX(c.createdAt) FROM UNNEST(i.comments.nodes) c) AS ultimo_comentario_at,
    ARRAY_LENGTH(i.subscribers.nodes) AS qtd_inscritos
  FROM `vanguardamartech_linear_vanguarda`.`linear_vanguardaissues` i
)
SELECT
  b.id                                            AS id_issue,
  b.identifier                                    AS identificador,
  b.number                                        AS numero,
  b.title                                         AS titulo,
  NULLIF(TRIM(IFNULL(b.description,'')), '')      AS descricao,
  b.url,
  b.branchName                                    AS nome_branch,

  -- ESTADO. type e o estado canonico (5 valores, estaveis na API do Linear);
  -- name e o rotulo do board, que a equipe pode renomear. Medido em 2026-09-21:
  -- backlog/Backlog 77, completed/Done 67, unstarted/Todo 61, canceled/Canceled 13,
  -- started/In Progress 12 = 230. Indicador agrupa por estado_tipo, nunca por rotulo.
  b.state.id                                      AS id_estado,
  b.state.type                                    AS estado_tipo,
  b.state.name                                    AS estado_rotulo,
  (b.state.type = 'completed')                    AS is_concluida,
  (b.state.type = 'canceled')                     AS is_cancelada,

  -- PRIORIDADE. 0 = sem prioridade, 1 Urgent, 2 High, 3 Medium, 4 Low.
  -- Zero NAO e NULL: 14 issues estao explicitamente sem prioridade.
  b.priority                                      AS prioridade,
  b.priorityLabel                                 AS prioridade_rotulo,

  b.team.id                                       AS id_equipe,
  b.team.key                                      AS equipe_sigla,
  b.team.name                                     AS equipe_nome,

  b.project.id                                    AS id_projeto,
  NULLIF(b.project.name,'')                       AS projeto_nome,
  NULLIF(b.project.state,'')                      AS projeto_estado,
  (b.project.id IS NULL)                          AS flag_sem_projeto,

  b.assignee.id                                   AS id_responsavel,
  b.assignee.name                                 AS responsavel_nome,
  b.assignee.displayName                          AS responsavel_apelido,
  (b.assignee.id IS NULL)                         AS flag_sem_responsavel,

  b.creator.id                                    AS id_criador,
  b.creator.name                                  AS criador_nome,
  b.creator.displayName                           AS criador_apelido,

  -- HIERARQUIA. 72 das 230 sao subtarefas; o proprio stream ja traz identifier e
  -- title do pai, entao nao precisa de auto-join.
  b.parent.id                                     AS id_issue_pai,
  b.parent.identifier                             AS identificador_pai,
  b.parent.title                                  AS titulo_pai,
  (b.parent.id IS NOT NULL)                       AS is_subtarefa,

  b.rotulos,
  b.qtd_rotulos,
  b.qtd_comentarios,
  b.qtd_inscritos,

  -- INSTANTES -> hora local. Ver bloco FUSO no topo.
  DATETIME(b.createdAt,   'America/Sao_Paulo')    AS criada_em,
  DATETIME(b.updatedAt,   'America/Sao_Paulo')    AS atualizada_em,
  DATETIME(b.startedAt,   'America/Sao_Paulo')    AS iniciada_em,
  DATETIME(b.completedAt, 'America/Sao_Paulo')    AS concluida_em,
  DATETIME(b.canceledAt,  'America/Sao_Paulo')    AS cancelada_em,
  DATETIME(b.ultimo_comentario_at, 'America/Sao_Paulo') AS ultimo_comentario_em,
  DATE(DATETIME(b.createdAt, 'America/Sao_Paulo')) AS dt_criacao,

  -- DATA disfarcada de TIMESTAMP -- sem argumento de fuso, de proposito.
  DATE(b.dueDate)                                 AS dt_prazo,

  -- Duracao em dias corridos entre criacao e conclusao. Nao e lead time de
  -- processo (nao ha historico de mudanca de estado), e a distancia entre os
  -- dois unicos eventos dateaveis.
  IF(b.completedAt IS NULL, NULL,
     DATE_DIFF(DATE(DATETIME(b.completedAt,'America/Sao_Paulo')),
               DATE(DATETIME(b.createdAt,  'America/Sao_Paulo')), DAY)) AS dias_ate_conclusao,

  CURRENT_TIMESTAMP()                             AS _extraido_at,
  b._fonte,
  TO_HEX(MD5(TO_JSON_STRING(b)))                  AS _payload_hash
FROM base b
