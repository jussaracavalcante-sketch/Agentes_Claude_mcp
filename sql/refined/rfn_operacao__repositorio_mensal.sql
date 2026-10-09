-- rfn_operacao__repositorio_mensal
-- Trabalho tecnico da casa por repositorio e mes. Irma da rfn_operacao__issue_mensal.
--
-- A CLASSIFICACAO DE FORK ESTA INDISPONIVEL: a github-s0VO caiu com 401 em 24/09 e
-- a extracao esvaziou a DIMENSAO (`github_repositories` tem ZERO linhas, contra 10
-- em 23/09) deixando os FATOS intactos (790 commits, 16 PRs). Entao is_repo_fork sai
-- NULL e qtd_commits_proprios sai NULL -- nunca zero, nunca 790. Sem a dimensao,
-- 580 dos 790 commits (73,4%) que sao de fork ficam indistinguiveis dos 210 proprios.
WITH commit AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_github__commit`
),
pr AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_github__pull_request`
),
repo AS (
  SELECT DISTINCT repositorio, id_repositorio, is_fork, is_privado, linguagem, is_arquivado
  FROM `vanguardamartech_trusted`.`trs_github__repositorio`
),
-- REGRA 1 - populacao A: commit, pelo mes do COMMITTER (entrada na arvore).
por_commit AS (
  SELECT
    repositorio, dono, nome_repositorio,
    DATE_TRUNC(dt_commit, MONTH)                                AS mes_referencia,
    COUNT(*)                                                    AS qtd_commits,
    -- REGRA 4 da descricao: conta IDENTIDADE, nao pessoa.
    COUNT(DISTINCT IFNULL(autor_login, autor_nome))             AS qtd_autores,
    COUNTIF(is_merge)                                           AS qtd_commits_merge,
    COUNTIF(flag_reescrito)                                     AS qtd_commits_reescritos,
    COUNTIF(flag_autor_nao_resolvido)                           AS qtd_commits_sem_autor_resolvido,
    COUNTIF(is_verificado)                                      AS qtd_commits_verificados
  FROM commit
  GROUP BY repositorio, dono, nome_repositorio, mes_referencia
),
-- REGRA 1 - populacao B: PR pelo mes de ABERTURA. Daqui sai a coorte.
por_pr_abertura AS (
  SELECT
    repositorio,
    DATE_TRUNC(dt_abertura, MONTH)                              AS mes_referencia,
    COUNT(*)                                                    AS qtd_prs_abertos,
    COUNTIF(is_mesclado)                                        AS qtd_prs_abertos_ja_mesclados,
    COUNTIF(is_fechado_sem_merge)                               AS qtd_prs_fechados_sem_merge,
    COUNTIF(is_rascunho)                                        AS qtd_prs_rascunho
  FROM pr
  GROUP BY repositorio, mes_referencia
),
-- REGRA 1 - populacao C: PR pelo mes do MERGE. E fluxo, nao coorte.
por_pr_merge AS (
  SELECT
    repositorio,
    DATE_TRUNC(DATE(mesclado_em), MONTH)                        AS mes_referencia,
    COUNT(*)                                                    AS qtd_prs_mesclados,
    ROUND(AVG(dias_ate_merge), 2)                               AS dias_ate_merge_medio,
    MAX(dias_ate_merge)                                         AS dias_ate_merge_maximo
  FROM pr
  WHERE mesclado_em IS NOT NULL
  GROUP BY repositorio, mes_referencia
),
-- REGRA 4 - so as chaves com conteudo. A grade cheia seria 11 x 19 = 209.
chaves AS (
  SELECT repositorio, mes_referencia FROM por_commit
  UNION DISTINCT
  SELECT repositorio, mes_referencia FROM por_pr_abertura
  UNION DISTINCT
  SELECT repositorio, mes_referencia FROM por_pr_merge
),
prep AS (
  SELECT
    k.repositorio,
    k.mes_referencia,
    COALESCE(c.dono, SPLIT(k.repositorio, '/')[SAFE_OFFSET(0)])             AS dono,
    COALESCE(c.nome_repositorio, SPLIT(k.repositorio, '/')[SAFE_OFFSET(1)]) AS nome_repositorio,
    c.qtd_commits, c.qtd_autores, c.qtd_commits_merge, c.qtd_commits_reescritos,
    c.qtd_commits_sem_autor_resolvido, c.qtd_commits_verificados,
    a.qtd_prs_abertos, a.qtd_prs_abertos_ja_mesclados, a.qtd_prs_fechados_sem_merge,
    a.qtd_prs_rascunho,
    m.qtd_prs_mesclados, m.dias_ate_merge_medio, m.dias_ate_merge_maximo,
    -- REGRA 2 - fork vem da dimensao ou nao vem. Nunca de lista fixa de nome.
    r.is_fork, r.id_repositorio, r.linguagem, r.is_privado, r.is_arquivado
  FROM chaves k
  LEFT JOIN por_commit      c ON c.repositorio = k.repositorio AND c.mes_referencia = k.mes_referencia
  LEFT JOIN por_pr_abertura a ON a.repositorio = k.repositorio AND a.mes_referencia = k.mes_referencia
  LEFT JOIN por_pr_merge    m ON m.repositorio = k.repositorio AND m.mes_referencia = k.mes_referencia
  LEFT JOIN repo            r ON r.repositorio = k.repositorio
),
tratado AS (
  SELECT
    CONCAT(p.repositorio, ':', FORMAT_DATE('%Y-%m', p.mes_referencia)) AS id_repositorio_mensal,
    p.mes_referencia,
    p.repositorio,
    p.dono,
    p.nome_repositorio,
    p.id_repositorio,
    p.linguagem,
    p.is_privado,
    p.is_arquivado,

    -- REGRA 2 - NULL quando a dimensao nao responde. Nao e FALSE.
    p.is_fork                                                   AS is_repo_fork,
    (p.id_repositorio IS NULL)                                  AS flag_repo_nao_catalogado,
    (p.is_fork IS NULL)                                         AS flag_classificacao_fork_indisponivel,

    IFNULL(p.qtd_commits, 0)                                    AS qtd_commits,

    -- REGRA 3 - TRES estados: NULL sem classificacao, 0 em fork, qtd em proprio.
    CASE
      WHEN p.is_fork IS NULL THEN NULL
      WHEN p.is_fork         THEN 0
      ELSE IFNULL(p.qtd_commits, 0)
    END                                                         AS qtd_commits_proprios,

    IFNULL(p.qtd_autores, 0)                                    AS qtd_autores,
    IFNULL(p.qtd_commits_merge, 0)                              AS qtd_commits_merge,
    IFNULL(p.qtd_commits_reescritos, 0)                         AS qtd_commits_reescritos,
    IFNULL(p.qtd_commits_sem_autor_resolvido, 0)                AS qtd_commits_sem_autor_resolvido,
    IFNULL(p.qtd_commits_verificados, 0)                        AS qtd_commits_verificados,

    -- REGRA 1 - coorte: dos abertos NESTE mes, quantos ja foram mesclados.
    IFNULL(p.qtd_prs_abertos, 0)                                AS qtd_prs_abertos_no_mes,
    IFNULL(p.qtd_prs_abertos_ja_mesclados, 0)                   AS qtd_prs_abertos_no_mes_ja_mesclados,
    IFNULL(p.qtd_prs_fechados_sem_merge, 0)                     AS qtd_prs_fechados_sem_merge,
    IFNULL(p.qtd_prs_rascunho, 0)                               AS qtd_prs_rascunho,

    -- REGRA 1 - fluxo: mesclados NESTE mes, abertos quando for. NAO dividir um pelo outro.
    IFNULL(p.qtd_prs_mesclados, 0)                              AS qtd_prs_mesclados_no_mes,

    -- Zero de PR aberto e NULL na taxa, nunca zero.
    CASE
      WHEN IFNULL(p.qtd_prs_abertos, 0) = 0 THEN NULL
      ELSE ROUND(SAFE_DIVIDE(p.qtd_prs_abertos_ja_mesclados, p.qtd_prs_abertos), 4)
    END                                                         AS taxa_merge_coorte,

    p.dias_ate_merge_medio,
    p.dias_ate_merge_maximo,

    (IFNULL(p.qtd_commits, 0) > 0 AND IFNULL(p.qtd_prs_abertos, 0) = 0)
                                                                AS flag_mes_sem_pull_request
  FROM prep p
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'github-s0VO'                                                 AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                                AS _payload_hash
FROM tratado t
