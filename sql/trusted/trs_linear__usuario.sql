-- trs_linear__usuario
-- Trusted do Linear: um USUARIO do workspace por linha. Chave id_usuario.
-- Fonte: linear-byrt, stream `users`, camada `Linear Vanguarda`,
-- tabela `vanguardamartech_linear_vanguarda.linear_vanguardausers`.
-- Nivel: L4 PERSONAL_DATA (nome e atividade de pessoa identificada).
--
-- VOLUME E UNICIDADE -- medido em 2026-10-18
--   5 linhas, 5 `id` distintos: 4 pessoas e 1 aplicativo (o usuario `Linear`, `app = TRUE`).
--   Os ids de responsavel (3 distintos) e de criador (3) das 230 issues resolvem 100% aqui (zero orfaos).
--
-- NAO EMITIDO, DE PROPOSITO: `email` (endereco), `avatarUrl`, `calendarHash`, `url`, o id de GitHub
--   (`gitHubUserId`, preenchido em 2 de 5: sai so a flag `tem_github_vinculado`) e `isMe` (descreve quem
--   autenticou a extracao, nao o usuario). Mesmo precedente da trs_linear__issue: o e-mail nunca atravessa.
--
-- FUSO: createdAt/lastSeen/updatedAt sao instantes UTC (hora != 00) -> DATETIME(ts,'America/Sao_Paulo').
--
-- LIMITACOES -- NAO CONTORNE
--   1. `is_app = TRUE` em 1 de 5 (o bot do Linear): nao e pessoa. Contar "usuarios" sem `is_app = FALSE` soma o bot.
--   2. `createdIssueCount` PASSA como o Linear entrega (0 a 165) e so e conferivel contra a issue em parte:
--      3 pessoas criam issues, 2 tem zero, e a soma (55+165+10) e 230,
--      exatamente o total de issues da trs_linear__issue. Nao recalcular.
--   3. `lastSeen` e a ultima vez que o usuario abriu o Linear (ultimo: 2026-08-21 16:28 UTC, Mauro Souza). Nao e atividade
--      de trabalho. nenhum dos 5 foi visto depois de 21/08/2026: o Linear nao e usado desde entao.
--   4. Todos `active = TRUE`, `guest = FALSE`, `archivedAt` NULL: nao ha desligamento registrado. `admin = TRUE` em 4 de 5.
--   5. `teams.nodes` carrega 1 equipe (VAN) por pessoa, exceto o bot (0). O Linear tem UMA equipe.
--   6. Nao ligar este usuario a `trs_vjob__usuario` ou ao iClips por nome (casamento por rotulo): nao ha chave comum.
WITH base AS (
  SELECT 'linear-byrt' AS _fonte, u.id, u.name, u.displayName, u.initials, u.active, u.admin, u.guest, u.app,
         u.isAssignable, u.isMentionable, u.timezone, u.createdIssueCount, u.createdAt, u.updatedAt,
         u.lastSeen, u.archivedAt, u.disableReason, u.gitHubUserId, u.teams
  FROM `vanguardamartech_linear_vanguarda`.`linear_vanguardausers` u
)
SELECT
  b.id                                         AS id_usuario,
  NULLIF(TRIM(b.name), '')                     AS nome,
  NULLIF(TRIM(b.displayName), '')              AS apelido,
  NULLIF(TRIM(b.initials), '')                 AS iniciais,
  b.active                                     AS is_ativo,
  b.admin                                      AS is_admin,
  b.guest                                      AS is_convidado,
  b.app                                        AS is_app,
  (NOT b.app)                                  AS is_pessoa,
  b.isAssignable                               AS is_atribuivel,
  NULLIF(b.timezone, '')                       AS fuso_do_usuario,
  b.createdIssueCount                          AS qtd_issues_criadas,
  IFNULL(ARRAY_LENGTH(b.teams.nodes), 0)       AS qtd_equipes,
  (SELECT t.id FROM UNNEST(b.teams.nodes) t LIMIT 1) AS id_equipe,
  (b.gitHubUserId IS NOT NULL)                 AS tem_github_vinculado,
  NULLIF(b.disableReason, '')                  AS motivo_desativacao,
  DATETIME(b.createdAt,  'America/Sao_Paulo')  AS criado_em,
  DATETIME(b.updatedAt,  'America/Sao_Paulo')  AS atualizado_em,
  DATETIME(b.lastSeen,   'America/Sao_Paulo')  AS visto_por_ultimo_em,
  DATETIME(b.archivedAt, 'America/Sao_Paulo')  AS arquivado_em,
  CURRENT_TIMESTAMP()                          AS _extraido_at,
  b._fonte,
  TO_HEX(MD5(TO_JSON_STRING(b)))               AS _payload_hash
FROM base b
