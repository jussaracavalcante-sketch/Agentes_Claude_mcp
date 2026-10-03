-- trs_github__repositorio
-- Trusted do GitHub: um repositorio por linha. Chave id_repositorio.
-- Fonte: github-s0VO, stream `repositories`, tabela `vanguardamartech_raw.github_repositories`.
--
-- VOLUME E UNICIDADE -- medido em 2026-09-23
--   10 linhas, 10 `id` distintos, 10 `full_name` distintos. Grao = repositorio.
--
-- FUSO: todos os TIMESTAMP sao instantes de verdade em UTC (10 de 10 com hora != 00
--   em created_at e pushed_at) -- DATETIME(ts,'America/Sao_Paulo'). Nenhuma data
--   disfarcada aqui, ao contrario do `dueDate` do Linear.
--
-- O ESQUEMA TEM ~60 COLUNAS DE URL DE API (`branches_url`, `git_refs_url`,
-- `milestones_url`...). Sao template de endpoint, nao informacao -- ficam de fora.
-- Sobrevivem `html_url` (a pagina) e `clone_url` (o que alguem de fato usa).
--
-- `temp_clone_token` FICA DE FORA POR PRINCIPIO. Hoje e NULL nas 10 linhas, mas e
-- campo de credencial e nao entra em camada de consumo nem quando esta vazio.
-- `permissions` (pull/push/admin) tambem sai: descreve o token da extracao, nao o
-- repositorio.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **DOIS DOS 10 SAO FORK** (`system-prompts-and-models-of-ai-tools` e
--      `claude-user-memory`) e carregam **580 dos 790 commits (73,4%)** da base.
--      Isso e historico do repositorio de origem, nao trabalho da Vanguarda.
--      Qualquer indicador de produtividade filtra `is_fork = FALSE` -- sem isso,
--      tres de cada quatro commits sao de fora.
--   2. Um repositorio COM COMMIT nao aparece aqui:
--      `jussaracavalcante-sketch/ai-hub-agencia-aws`, 3 commits em 09/09/2026.
--      O stream `commits` alcanca 11 repositorios e o `repositories` cadastra 10.
--      Por isso a `trs_github__commit` usa LEFT JOIN e acende
--      `flag_repo_nao_catalogado` -- INNER descartaria esses commits em silencio.
--   3. 8 dos 10 repositorios nao tem descricao. Nao da para classificar repositorio
--      por conteudo a partir desta fonte.
--   4. `Governan-a_vanguarda` tem como branch padrao
--      `claude/prompts-repo-infrastructure-08dmf1`, uma branch de trabalho. O campo
--      esta fiel a origem; quem comparar "commits na branch padrao" entre repositorios
--      esta comparando coisas diferentes.
--   5. Os 10 repositorios sao publicos (`private = FALSE` em todos). Se a expectativa
--      era repositorio privado da casa, o lugar de checar e a origem, nao esta tabela.
SELECT
  r.id                                            AS id_repositorio,
  r.full_name                                     AS repositorio,
  r.name                                          AS nome,
  r.owner.login                                   AS dono_login,
  r.owner.id                                      AS id_dono,
  r.owner.type                                    AS dono_tipo,
  NULLIF(TRIM(IFNULL(r.description,'')), '')      AS descricao,
  r.html_url                                      AS url,
  r.clone_url                                     AS url_clone,
  NULLIF(r.homepage,'')                           AS homepage,
  NULLIF(r.language,'')                           AS linguagem,
  r.default_branch                                AS branch_padrao,
  r.visibility                                    AS visibilidade,
  r.private                                       AS is_privado,
  r.fork                                          AS is_fork,
  r.archived                                      AS is_arquivado,
  r.disabled                                      AS is_desabilitado,
  r.is_template                                   AS is_template,
  ARRAY_TO_STRING(ARRAY(SELECT t FROM UNNEST(r.topics) t ORDER BY t), ' | ') AS topicos,
  ARRAY_LENGTH(r.topics)                          AS qtd_topicos,
  r.size                                          AS tamanho_kb,
  r.forks_count                                   AS qtd_forks,
  r.stargazers_count                              AS qtd_estrelas,
  r.watchers_count                                AS qtd_observadores,
  r.open_issues_count                             AS qtd_issues_abertas,
  r.subscribers_count                             AS qtd_inscritos,
  r.license.spdx_id                               AS licenca,
  r.has_issues                                    AS tem_issues,
  r.has_wiki                                      AS tem_wiki,
  r.has_discussions                               AS tem_discussoes,
  DATETIME(r.created_at, 'America/Sao_Paulo')     AS criado_em,
  DATETIME(r.updated_at, 'America/Sao_Paulo')     AS atualizado_em,
  DATETIME(r.pushed_at,  'America/Sao_Paulo')     AS ultimo_push_em,
  DATE(DATETIME(r.pushed_at, 'America/Sao_Paulo')) AS dt_ultimo_push,
  CURRENT_TIMESTAMP()                             AS _extraido_at,
  'github-s0VO'                                   AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(r)))                  AS _payload_hash
FROM `vanguardamartech_raw`.`github_repositories` r
