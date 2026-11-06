-- rfn_operacao__linear_estrutura_resumo  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: entidade (EQUIPE / ROTULO / USUARIO) x grupo (sigla da equipe; rotulo de WORKSPACE ou de EQUIPE; USUARIO PESSOA ou APP).
-- Le: trs_linear__equipe (query-aVpr), trs_linear__rotulo (query-rJgF), trs_linear__usuario (query-pdft) e, para medir o USO do
--   rotulo, trs_linear__issue (query-lhYJ). Gatilho: evento com regra "all" nas quatro (todas disparam na linear-byrt, diaria 03:20).
-- Por que UMA Refined para tres dimensoes: 1, 8 e 5 linhas; uma tabela por dimensao nao agregaria nada (a propria Trusted de
--   equipe declara isso). O grao entidade x grupo da leitor as tres e mede o que as Trusted deixaram para a Refined: o uso do rotulo.
-- Identidade (19/10/2026, contra as Trusted materializadas): 1 equipe = 1 · 8 rotulos = 8 · 5 usuarios = 5 · 5 linhas, 5 chaves ·
--   49 aplicacoes de rotulo = SUM(qtd_rotulos) das 230 issues · 3 rotulos sem uso · 230 issues criadas = 230 issues.
-- R1 NADA PESSOAL ATRAVESSA: nome, apelido, iniciais e criador ficam na Trusted (L4). Aqui so contagem.
-- R2 O uso do rotulo e medido pela coluna rotulos da issue (texto ' | '), casando pelo NOME do rotulo: no Linear o nome e unico
--    por workspace, por isso aqui o casamento por rotulo e legitimo. qtd_issues_com_rotulo conta issues distintas.
-- R3 Colunas que nao se aplicam a entidade saem NULL (nao zero): qtd_com_ciclos so em EQUIPE, qtd_aplicacoes_em_issues so em
--    ROTULO, qtd_issues_criadas/qtd_admins/qtd_com_github/ultimo_visto_em so em USUARIO.
-- R4 is_pessoa separa gente do bot: contar "usuarios" sem o grupo PESSOA soma o aplicativo `Linear`.
-- LIMITACAO -- NAO CONTORNE: o Linear PAROU DE SER USADO (ultima issue criada 28/07/2026, ultima conclusao 25/06/2026, nenhum
--   usuario visto depois de 21/08/2026): esta tabela e historico. Uma equipe so (VAN); rotulo nao e categoria de negocio.
WITH e AS (SELECT * FROM `vanguardamartech_trusted`.`trs_linear__equipe`),
r AS (SELECT * FROM `vanguardamartech_trusted`.`trs_linear__rotulo`),
u AS (SELECT * FROM `vanguardamartech_trusted`.`trs_linear__usuario`),
uso AS (
  SELECT nome_rotulo, COUNT(*) AS qtd_aplicacoes, COUNT(DISTINCT id_issue) AS qtd_issues
  FROM `vanguardamartech_trusted`.`trs_linear__issue`, UNNEST(SPLIT(rotulos, ' | ')) AS nome_rotulo
  WHERE rotulos IS NOT NULL
  GROUP BY 1
),
r_uso AS (
  SELECT r.*, IFNULL(uso.qtd_aplicacoes, 0) AS qtd_aplicacoes, IFNULL(uso.qtd_issues, 0) AS qtd_issues
  FROM r LEFT JOIN uso ON uso.nome_rotulo = r.nome
),
linhas AS (
  SELECT 'EQUIPE' AS entidade, sigla AS grupo,
         COUNT(*) AS qtd_itens, COUNT(DISTINCT id_equipe) AS qtd_ids_distintos,
         COUNTIF(arquivada_em IS NOT NULL) AS qtd_arquivados,
         COUNTIF(usa_ciclos) AS qtd_com_ciclos, COUNTIF(usa_triagem) AS qtd_com_triagem,
         COUNTIF(tipo_estimativa IS NOT NULL AND tipo_estimativa <> 'notUsed') AS qtd_com_estimativa,
         CAST(NULL AS INT64) AS qtd_sem_criador, CAST(NULL AS INT64) AS qtd_sem_descricao,
         CAST(NULL AS INT64) AS qtd_aplicacoes_em_issues, CAST(NULL AS INT64) AS qtd_issues_com_rotulo, CAST(NULL AS INT64) AS qtd_itens_sem_uso,
         CAST(NULL AS INT64) AS qtd_admins, CAST(NULL AS INT64) AS qtd_com_github, CAST(NULL AS INT64) AS qtd_issues_criadas,
         MIN(criada_em) AS primeiro_criado_em, MAX(criada_em) AS ultimo_criado_em, CAST(NULL AS DATETIME) AS ultimo_visto_em
  FROM e GROUP BY 1, 2
  UNION ALL
  SELECT 'ROTULO', IF(flag_rotulo_de_workspace, 'WORKSPACE', 'EQUIPE'),
         COUNT(*), COUNT(DISTINCT id_rotulo), COUNTIF(arquivado_em IS NOT NULL),
         NULL, NULL, NULL,
         COUNTIF(id_criador IS NULL), COUNTIF(descricao IS NULL),
         SUM(qtd_aplicacoes), SUM(qtd_issues), COUNTIF(qtd_aplicacoes = 0),
         NULL, NULL, NULL,
         MIN(criado_em), MAX(criado_em), NULL
  FROM r_uso GROUP BY 1, 2
  UNION ALL
  SELECT 'USUARIO', IF(is_app, 'APP', 'PESSOA'),
         COUNT(*), COUNT(DISTINCT id_usuario), COUNTIF(arquivado_em IS NOT NULL),
         NULL, NULL, NULL,
         NULL, NULL,
         NULL, NULL, NULL,
         COUNTIF(is_admin), COUNTIF(tem_github_vinculado), SUM(qtd_issues_criadas),
         MIN(criado_em), MAX(criado_em), MAX(visto_por_ultimo_em)
  FROM u GROUP BY 1, 2
),
final AS (
  SELECT CONCAT(entidade, '|', grupo) AS id_linear_estrutura, l.*, 'L2_INTERNAL' AS classificacao_dado
  FROM linhas l
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'linear-byrt' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
