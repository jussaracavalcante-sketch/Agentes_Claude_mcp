-- trs_github__commit
-- Trusted do GitHub: um commit por linha. Chave sha.
-- Fonte: github-s0VO, stream `commits`, tabela `vanguardamartech_raw.github_commits`.
--
-- VOLUME E UNICIDADE -- medido em 2026-09-23
--   790 linhas, 790 `sha` distintos -- unicidade GLOBAL, nao so por repositorio
--   (a chave composta owner/repo/sha tambem da 790). 11 repositorios.
--   Janela: 26/03/2025 a 21/09/2026.
--
-- FUSO: instantes de verdade em UTC -- 786 dos 790 tem hora != 00.
--   DATETIME(ts,'America/Sao_Paulo'). Nunca TIMESTAMP(dt,'America/Sao_Paulo'),
--   que soma 3 horas em vez de converter.
--
-- DUAS DATAS, E ELAS NAO SAO A MESMA COISA. `commit.author.date` e quando o codigo
-- foi escrito; `commit.committer.date` e quando entrou na arvore. Medido: o campo
-- `committed_at` da fonte e IGUAL ao committer em 790 de 790, e difere do author em
-- 3 linhas -- rebase ou cherry-pick. As duas ficam na tabela; quem mede entrega usa
-- `commitado_em` (committer), quem mede autoria usa `escrito_em`.
--
-- EMAIL FICA FORA. `commit.author.email` e `commit.committer.email` trazem endereco
-- de pessoa. A Trusted emite nome e, quando o GitHub resolveu a identidade, o login.
-- Mesmo criterio da `trs_linear__issue` e o precedente do `Gestao de Projetos do
-- iClips` (cpf e valorHora descartados na leitura).
--
-- LIMITACOES -- NAO CONTORNE
--   1. **`stats` e 100% NULL nas 790 linhas.** Nao ha adicoes nem delecoes por commit
--      nesta fonte -- o endpoint de listagem nao preenche. Volume de codigo NAO se
--      mede aqui, e a `github_pull_requests` tambem nao ajuda (additions, deletions e
--      changed_files sao NULL nas 16 linhas dela).
--   2. **580 dos 790 commits (73,4%) sao de repositorio FORK** -- 518 de
--      `system-prompts-and-models-of-ai-tools` e 62 de `claude-user-memory`. Isso e
--      historico do repositorio de origem, nao trabalho da casa. `flag_repo_fork`
--      existe para filtrar; contagem sem ela e tres quartos ruido.
--   3. 18 commits nao tem usuario GitHub resolvido (`author`/`committer` NULL) --
--      o e-mail do commit nao casou com nenhuma conta. Sobra o nome digitado no git,
--      que nao e identidade. Nao somar por `autor_nome` esperando pessoa unica.
--   4. 3 commits sao de `ai-hub-agencia-aws`, repositorio que o stream `repositories`
--      NAO cadastra. `flag_repo_nao_catalogado` acende neles. O join e LEFT de
--      proposito: INNER sumiria com os 3 sem nenhum sinal.
--   5. Nao ha branch no dado. O stream traz commits alcancaveis, sem dizer de qual
--      branch -- entao nao da para separar trabalho em branch de trabalho na principal.
WITH base AS (
  SELECT
    c.sha,
    c.html_url,
    c.owner,
    c.repo,
    c.commit.message                                   AS mensagem,
    c.commit.author.name                               AS autor_nome,
    c.commit.author.date                               AS escrito_at,
    c.commit.committer.name                            AS commitador_nome,
    c.committed_at,
    c.author.login                                     AS autor_login,
    c.author.id                                        AS id_autor,
    c.committer.login                                  AS commitador_login,
    c.committer.id                                     AS id_commitador,
    c.commit.verification.verified                     AS is_verificado,
    c.commit.verification.reason                       AS verificacao_motivo,
    c.commit.comment_count                             AS qtd_comentarios,
    ARRAY_LENGTH(c.parents)                            AS qtd_pais
  FROM `vanguardamartech_raw`.`github_commits` c
)
SELECT
  b.sha                                           AS sha,
  SUBSTR(b.sha, 1, 7)                             AS sha_curto,
  CONCAT(b.owner, '/', b.repo)                    AS repositorio,
  b.owner                                         AS dono,
  b.repo                                          AS nome_repositorio,
  r.id_repositorio,

  -- Primeira linha da mensagem: e o assunto do commit. A mensagem inteira fica
  -- em `mensagem` -- corpo de commit e texto livre e nao vira dimensao.
  TRIM(SPLIT(b.mensagem, '\n')[SAFE_OFFSET(0)])   AS assunto,
  b.mensagem,

  b.autor_nome,
  b.autor_login,
  b.id_autor,
  b.commitador_nome,
  b.commitador_login,
  b.id_commitador,
  (b.autor_login IS NULL)                         AS flag_autor_nao_resolvido,

  b.qtd_pais,
  (b.qtd_pais > 1)                                AS is_merge,
  b.is_verificado,
  b.verificacao_motivo,
  b.qtd_comentarios,
  b.html_url                                      AS url,

  -- Ver o bloco DUAS DATAS no topo: committer e entrega, author e autoria.
  DATETIME(b.committed_at, 'America/Sao_Paulo')   AS commitado_em,
  DATETIME(b.escrito_at,   'America/Sao_Paulo')   AS escrito_em,
  DATE(DATETIME(b.committed_at, 'America/Sao_Paulo')) AS dt_commit,
  (b.committed_at != b.escrito_at)                AS flag_reescrito,

  -- Denormalizado do repositorio para que o filtro de fork nao exija join.
  IFNULL(r.is_fork, FALSE)                        AS flag_repo_fork,
  (r.id_repositorio IS NULL)                      AS flag_repo_nao_catalogado,

  CURRENT_TIMESTAMP()                             AS _extraido_at,
  'github-s0VO'                                   AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(b)))                  AS _payload_hash
FROM base b
-- LEFT e proposital: 3 commits de `ai-hub-agencia-aws` nao tem cadastro de
-- repositorio. Com INNER eles sumiriam sem nenhum sinal.
LEFT JOIN `vanguardamartech_trusted`.`trs_github__repositorio` r
  ON r.repositorio = CONCAT(b.owner, '/', b.repo)
