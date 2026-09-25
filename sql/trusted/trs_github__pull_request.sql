-- trs_github__pull_request
-- Trusted do GitHub: um pull request por linha. Chave id_pr.
-- Fonte: github-s0VO, stream `pull_requests`, tabela
-- `vanguardamartech_raw.github_pull_requests`.
--
-- VOLUME E UNICIDADE -- medido em 2026-09-23
--   16 linhas, 16 `id` distintos, 16 pares (repositorio, numero) distintos.
--   Grao = pull request. 4 abertos, 12 fechados, 11 desses mesclados.
--   Janela: 07/08/2026 a 21/09/2026. 3 repositorios com PR, de 11 com commit.
--
-- FUSO: instantes de verdade em UTC (16 de 16 em created_at, 11 de 11 em merged_at)
--   -- DATETIME(ts,'America/Sao_Paulo').
--
-- O ESQUEMA CARREGA O REPOSITORIO INTEIRO DUAS VEZES. `head` e `base` sao structs
-- que embutem o objeto de repositorio completo (~90 campos cada, com owner dentro).
-- Da Trusted saem so `ref` e `sha` de cada lado -- que e a informacao: de onde para
-- onde. O repositorio se resolve por `repositorio` contra a trs_github__repositorio.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **TODO CONTADOR DESTA FONTE E NULO.** Medido nas 16 linhas: `additions`,
--      `deletions`, `changed_files`, `commits`, `comments` e `review_comments` sao
--      NULL em todas. E os arrays tambem vem vazios: `labels`, `assignees`,
--      `requested_reviewers`, `milestone` e `auto_merge` -- zero linhas com conteudo.
--      E a assinatura do endpoint de LISTAGEM do GitHub, que nao devolve esses campos;
--      so a chamada por PR individual devolveria. **Desta fonte da para contar PR e
--      medir o ciclo de vida dele, e mais nada** -- nem tamanho, nem revisao, nem
--      responsavel. As colunas nao entram na tabela justamente para nao parecerem
--      zero quando sao ausencia.
--   2. Nao existe indicador de revisao aqui. Quem aprovou, quantas rodadas e quanto
--      tempo levou exigiriam o stream `reviews`, que a fonte nao traz.
--   3. `assignee` e NULL nos 16. Nao ha responsavel por PR nesta base.
--   4. PR fechado sem merge e PR abandonado ou substituido: 1 dos 12 fechados nao tem
--      `merged_at`. `is_mesclado` separa os dois casos -- `state = 'closed'` sozinho
--      nao separa.
--   5. `dias_ate_merge` conta dias corridos, nao uteis, e mede da abertura ao merge --
--      nao e tempo de revisao, porque nao ha carimbo de quando a revisao comecou.
WITH base AS (
  SELECT
    p.id,
    p.number,
    p.owner,
    p.repo,
    p.title,
    p.body,
    p.state,
    p.draft,
    p.locked,
    p.user.login                                     AS autor_login,
    p.user.id                                        AS id_autor,
    p.author_association,
    p.head.ref                                       AS head_ref,
    p.head.sha                                       AS head_sha,
    p.base.ref                                       AS base_ref,
    p.base.sha                                       AS base_sha,
    p.merge_commit_sha,
    p.html_url,
    p.created_at,
    p.updated_at,
    p.closed_at,
    p.merged_at
  FROM `vanguardamartech_raw`.`github_pull_requests` p
)
SELECT
  b.id                                            AS id_pr,
  b.number                                        AS numero,
  CONCAT(b.owner, '/', b.repo)                    AS repositorio,
  CONCAT(b.owner, '/', b.repo, '#', CAST(b.number AS STRING)) AS identificador,
  r.id_repositorio,
  b.owner                                         AS dono,
  b.repo                                          AS nome_repositorio,

  b.title                                         AS titulo,
  NULLIF(TRIM(IFNULL(b.body,'')), '')             AS descricao,
  b.html_url                                      AS url,

  b.state                                         AS estado,
  b.draft                                         AS is_rascunho,
  b.locked                                        AS is_travado,
  (b.merged_at IS NOT NULL)                       AS is_mesclado,
  -- Fechado sem merge: PR abandonado ou substituido. `state` sozinho nao separa.
  (b.state = 'closed' AND b.merged_at IS NULL)    AS is_fechado_sem_merge,

  b.autor_login,
  b.id_autor,
  b.author_association                            AS vinculo_autor,

  b.head_ref                                      AS branch_origem,
  b.base_ref                                      AS branch_destino,
  b.head_sha,
  b.base_sha,
  b.merge_commit_sha                              AS sha_merge,

  DATETIME(b.created_at, 'America/Sao_Paulo')     AS aberto_em,
  DATETIME(b.updated_at, 'America/Sao_Paulo')     AS atualizado_em,
  DATETIME(b.closed_at,  'America/Sao_Paulo')     AS fechado_em,
  DATETIME(b.merged_at,  'America/Sao_Paulo')     AS mesclado_em,
  DATE(DATETIME(b.created_at, 'America/Sao_Paulo')) AS dt_abertura,

  -- Dias corridos da abertura ao merge. NAO e tempo de revisao: ver limitacao 5.
  IF(b.merged_at IS NULL, NULL,
     DATE_DIFF(DATE(DATETIME(b.merged_at,  'America/Sao_Paulo')),
               DATE(DATETIME(b.created_at, 'America/Sao_Paulo')), DAY)) AS dias_ate_merge,

  IFNULL(r.is_fork, FALSE)                        AS flag_repo_fork,
  (r.id_repositorio IS NULL)                      AS flag_repo_nao_catalogado,

  CURRENT_TIMESTAMP()                             AS _extraido_at,
  'github-s0VO'                                   AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(b)))                  AS _payload_hash
FROM base b
LEFT JOIN `vanguardamartech_trusted`.`trs_github__repositorio` r
  ON r.repositorio = CONCAT(b.owner, '/', b.repo)
