-- trs_linear__projeto
-- Trusted do Linear: um PROJETO interno da agencia por linha. Chave id_projeto (slugId tambem unico).
-- Fonte: linear-byrt, stream `projects`, camada `Linear Vanguarda`,
-- tabela `vanguardamartech_linear_vanguarda.linear_vanguardaprojects` (prefixo `linear_vanguarda` + stream).
-- Nivel: L4 PERSONAL_DATA de intensidade baixa (lider e criador saem como id + nome, nunca e-mail),
-- o mesmo nivel da trs_linear__issue. A Refined que a le agrega sem nome e fica L2.
--
-- VOLUME E UNICIDADE -- medido em 2026-10-18
--   9 linhas, 9 `id` distintos, 9 `slugId` distintos. Grao = projeto.
--   Criados de 2026-04-02 a 2026-06-09; ultimo updatedAt 2026-08-24 23:45 UTC.
--   O stream e INCREMENTAL por updatedAt e a Trusted e reconstruida inteira a cada carga.
--
-- FUSO -- MEDIDO COLUNA A COLUNA (nao herdado)
--   createdAt / updatedAt / startedAt / completedAt / canceledAt sao INSTANTES em UTC:
--   9 de 9 createdAt tem hora != 00. Convertem com DATETIME(ts,'America/Sao_Paulo'),
--   NUNCA TIMESTAMP(dt,'America/Sao_Paulo') (essa soma 3 horas sobre relogio local).
--   targetDate e DATA disfarcada de TIMESTAMP: ZERO das 5 linhas preenchidas tem hora != 00:00:00
--   (mesma armadilha do `dueDate` da issue). DATE(targetDate) sem argumento de fuso:
--   DATE(targetDate,'America/Sao_Paulo') jogaria cada prazo um dia para tras.
--
-- LIMITACOES -- NAO CONTORNE
--   1. O Linear PAROU DE SER USADO (ultima issue criada 28/07/2026, ultima conclusao 25/06/2026);
--      projeto nenhum foi concluido (`completedAt` e `canceledAt` NULL em 9 de 9). Historico, nao
--      acompanhamento corrente.
--   2. `members` e `teams` chegam VAZIOS nos 9 projetos (nao ha membro nem equipe no payload do
--      stream) e por isso nao saem. Quem trabalha em um projeto NAO se le daqui: so o lider.
--   3. `lead` existe em 3 de 9 (6 sem lider). `startedAt` existe em 2 de 9, `targetDate` em 5 de 9 (4 sem prazo):
--      qualquer indicador de prazo ou de lideranca cobre uma fracao da base -- declare a cobertura.
--   4. `progress` PASSA COMO O LINEAR ENTREGA (0 a 1) e NAO e concluidas/escopo: nos projetos com
--      issues, 3 de 8 divergem (BI Hub v2 0,6645 contra 25/38 = 0,6579; SGQ v4.0 0,1164 contra
--      7/73 = 0,0959; Saneamento iClips 0,0132 contra 0/19). Nao recalcular; a conferencia contra as
--      issues esta na Refined.
--   5. `scope` e a contagem de issues NAO canceladas do projeto: 9 de 9 batem com a
--      `trs_linear__issue` (ex.: Saneamento tem 21 issues e scope 19, as 2 diferenca sao canceladas).
--      Nao e esforco nem pontos: `estimate` e 0% preenchido na issue.
--   6. Projeto e INTERNO da agencia (SGQ v4.0, BI Hub, E-mail Marketing, Fechamento Contabil...),
--      NAO e cliente de midia. Nao ligar a rfn_cadastro__cliente (casamento falso por rotulo).
--   7. `description` fica fora (texto livre). `icon`, `color`, `sortOrder` e `priority` de tela:
--      so a prioridade sai (0 = sem prioridade, 1 Urgent ... 4 Low; zero NAO e NULL).
--   8. Nome de lider/criador e dado pessoal de intensidade baixa: saem id e nome, nunca e-mail.
WITH base AS (
  SELECT
    'linear-byrt' AS _fonte,
    p.id, p.slugId, p.name, p.state, p.priority, p.progress, p.scope, p.url,
    p.targetDate, p.createdAt, p.updatedAt, p.startedAt, p.completedAt, p.canceledAt,
    p.lead, p.creator
  FROM `vanguardamartech_linear_vanguarda`.`linear_vanguardaprojects` p
)
SELECT
  b.id                                        AS id_projeto,
  b.slugId                                    AS slug_projeto,
  NULLIF(TRIM(b.name), '')                    AS nome,
  b.url,
  -- ESTADO: backlog / planned / started / paused / completed / canceled. A Trusted nao reclassifica.
  b.state                                     AS estado,
  (b.state = 'completed')                     AS is_concluido,
  (b.state = 'canceled')                      AS is_cancelado,
  b.priority                                  AS prioridade,
  b.progress                                  AS progresso_linear,
  b.scope                                     AS qtd_escopo_linear,
  b.lead.id                                   AS id_lider,
  b.lead.name                                 AS lider_nome,
  (b.lead.id IS NULL)                         AS flag_sem_lider,
  b.creator.id                                AS id_criador,
  b.creator.name                              AS criador_nome,
  DATETIME(b.createdAt,   'America/Sao_Paulo') AS criado_em,
  DATETIME(b.updatedAt,   'America/Sao_Paulo') AS atualizado_em,
  DATETIME(b.startedAt,   'America/Sao_Paulo') AS iniciado_em,
  DATETIME(b.completedAt, 'America/Sao_Paulo') AS concluido_em,
  DATETIME(b.canceledAt,  'America/Sao_Paulo') AS cancelado_em,
  -- DATA disfarcada de TIMESTAMP: sem argumento de fuso, de proposito.
  DATE(b.targetDate)                          AS dt_prazo,
  (b.targetDate IS NULL)                      AS flag_sem_prazo,
  CURRENT_TIMESTAMP()                         AS _extraido_at,
  b._fonte,
  TO_HEX(MD5(TO_JSON_STRING(b)))              AS _payload_hash
FROM base b
