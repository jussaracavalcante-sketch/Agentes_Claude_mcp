-- rfn_qualidade__regra_linear_estrutura  ·  26 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra
-- (a execucao se le em _extraido_at).
-- Cobre as QUATRO Trusted da estrutura do Linear (trs_linear__projeto, __rotulo, __usuario, __equipe) e a Refined
-- rfn_operacao__linear_projeto, todas publicadas em 2026-10-18. A suite do Linear que ja existe
-- (rfn_qualidade__regra_linear, query-APFG, 19 regras) cobre trs_linear__issue e rfn_operacao__issue_mensal;
-- NENHUMA das 26 repete aquelas.
-- Gatilho: evento com regra "all" em query-cFzx (Refined), query-rJgF (rotulo), query-pdft (usuario) e
-- query-aVpr (equipe) -- a suite so roda depois de TODAS terem reescrito. Alerta ligado. Cadencia: diaria
-- (a linear-byrt roda 03:20 America/Manaus).
--
-- VALIDACAO (2026-10-18): as tabelas novas AINDA NAO MATERIALIZARAM (a primeira carga e a agendada), entao a query
-- foi validada reproduzindo a logica das quatro Trusted sobre a Raw (linear_vanguarda*) e a Refined sobre a
-- trs_linear__issue ja materializada. Resultado esperado na primeira execucao real: 26 regras, 26 ids, CONFORME 26,
-- ZERO falhas (as quatro linhas de base de ALERTA estao dentro do limiar).
--
-- O QUE GUARDA PREMISSA DE VERDADE
--   * `projeto.dt_prazo_sem_deslocamento` -- targetDate e DATA disfarcada de TIMESTAMP (zero das 5 com hora != 00);
--     compara a Trusted contra DATE(targetDate) da Raw. Se alguem aplicar fuso, todo prazo anda um dia.
--   * `refined.issues_reproduzem_a_trusted` e `balde_sem_projeto_nao_perde_issue` -- identidades entre camadas
--     (230 e 26); a segunda guarda a sentinela "(sem projeto)".
--   * `refined.taxa_null_sem_issue_viva` -- zero de conclusao nao e zero, e NULL (IAFIRST#1 tem zero issue).
--
-- LINHAS DE BASE (ALERTA, limiar medido, nao herdado)
--   * `projeto.escopo_bate_com_issues` 0,80 -- 9 de 9 hoje. O `scope` do Linear sai da LINHA de projeto, que so e
--     relida quando o projeto muda (ultimo updatedAt 24/08), enquanto as issues mudam todo dia: se alguem cancelar uma
--     issue de projeto sem tocar no projeto, a linha diverge sem ser defeito do tratamento.
--   * `usuario.issues_criadas_reproduzem_a_issue` 1,00 -- 230 de 230 hoje (55+165+10).
--   * `rotulo.rotulo_aplicado_existe` e `usuario.responsavel_e_criador_existem` 0,98 -- zero orfaos hoje.
--
-- O QUE NAO ENTROU, E A AUSENCIA E A DECISAO: frescor de carga (o Linear parou de ser usado: ultima issue criada
-- 28/07/2026, ultima conclusao 25/06; regra de "dado recente" acusaria todo dia um fato conhecido); equipe unica
-- (exigir `COUNT = 1` transformaria crescimento legitimo em falha); `progresso_linear = taxa` (3 de 8 divergem POR
-- DESENHO do Linear, a Refined emite `flag_progresso_diverge` para isso).
--
-- CLASSIFICACAO: L2 INTERNAL. So contagem, taxa e nome de regra; nada das Trusted L4 atravessa.
WITH
projeto AS (SELECT * FROM `vanguardamartech_trusted`.`trs_linear__projeto`),
rotulo  AS (SELECT * FROM `vanguardamartech_trusted`.`trs_linear__rotulo`),
usuario AS (SELECT * FROM `vanguardamartech_trusted`.`trs_linear__usuario`),
equipe  AS (SELECT * FROM `vanguardamartech_trusted`.`trs_linear__equipe`),
issue   AS (SELECT * FROM `vanguardamartech_trusted`.`trs_linear__issue`),
rfn     AS (SELECT * FROM `vanguardamartech_refined`.`rfn_operacao__linear_projeto`),
-- Ids de rotulo realmente aplicados nas issues (Raw, DISTINCT no lado direito do anti-join).
rotulo_aplicado AS (
  SELECT l.id AS id_rotulo, COUNT(*) AS qtd
  FROM `vanguardamartech_linear_vanguarda`.`linear_vanguardaissues` i, UNNEST(i.labels.nodes) l
  GROUP BY l.id
),
r_proj AS (
  SELECT 'trs_linear__projeto.id_projeto_unico' AS id_regra, 'Trusted' AS camada, 'trs_linear__projeto' AS tabela,
         'Linear' AS sistema, 'UNICIDADE' AS dimensao, 'id_projeto e unico e nunca nulo' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar, COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_projeto) + COUNTIF(id_projeto IS NULL) AS linhas_falha
  FROM projeto
  UNION ALL
  SELECT 'trs_linear__projeto.slug_projeto_unico', 'Trusted', 'trs_linear__projeto', 'Linear', 'UNICIDADE',
         'slug_projeto (a chave humana que aparece na URL) e unico e nunca nulo', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNT(*) - COUNT(DISTINCT slug_projeto) + COUNTIF(slug_projeto IS NULL)
  FROM projeto
  UNION ALL
  SELECT 'trs_linear__projeto.estado_conhecido', 'Trusted', 'trs_linear__projeto', 'Linear', 'VALIDADE',
         'estado e um dos seis estados de projeto do Linear', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(estado IS NULL OR estado NOT IN ('backlog', 'planned', 'started', 'paused', 'completed', 'canceled'))
  FROM projeto
  UNION ALL
  SELECT 'trs_linear__projeto.flags_concordam_com_as_colunas', 'Trusted', 'trs_linear__projeto', 'Linear', 'VALIDADE',
         'is_concluido, is_cancelado, flag_sem_lider e flag_sem_prazo concordam com estado, id_lider e dt_prazo',
         'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(is_concluido <> (estado = 'completed') OR is_cancelado <> (estado = 'canceled')
              OR flag_sem_lider <> (id_lider IS NULL) OR flag_sem_prazo <> (dt_prazo IS NULL))
  FROM projeto
  UNION ALL
  SELECT 'trs_linear__projeto.progresso_entre_zero_e_um', 'Trusted', 'trs_linear__projeto', 'Linear', 'VALIDADE',
         'progresso_linear fica entre 0 e 1 quando preenchido', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(progresso_linear < 0 OR progresso_linear > 1)
  FROM projeto
  UNION ALL
  -- A GUARDA DO FUSO: dt_prazo tem de ser a data da Raw SEM conversao. 5 de 5 hoje.
  SELECT 'trs_linear__projeto.dt_prazo_sem_deslocamento', 'Trusted', 'trs_linear__projeto', 'Linear', 'VALIDADE',
         'dt_prazo e DATE(targetDate) da origem, sem conversao de fuso (data disfarcada de timestamp)',
         'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(p.dt_prazo IS DISTINCT FROM DATE(r.targetDate))
  FROM projeto p
  JOIN `vanguardamartech_linear_vanguarda`.`linear_vanguardaprojects` r ON r.id = p.id_projeto
  WHERE r.targetDate IS NOT NULL
  UNION ALL
  -- LINHA DE BASE. Ver o cabecalho: a linha de projeto e relida so quando o projeto muda.
  SELECT 'trs_linear__projeto.escopo_bate_com_issues', 'Trusted', 'trs_linear__projeto', 'Linear', 'INTEGRIDADE',
         'qtd_escopo_linear e igual as issues nao canceladas do projeto (linha de base)', 'ALERTA', 0.80, COUNT(*),
         COUNTIF(p.qtd_escopo_linear <> IFNULL(c.qtd_vivas, 0))
  FROM projeto p
  LEFT JOIN (SELECT id_projeto, COUNTIF(NOT is_cancelada) AS qtd_vivas FROM issue GROUP BY id_projeto) c
         ON c.id_projeto = p.id_projeto
  UNION ALL
  SELECT 'trs_linear__issue.projeto_existe_no_cadastro', 'Trusted', 'trs_linear__issue', 'Linear', 'INTEGRIDADE',
         'toda issue com projeto aponta para projeto catalogado (anti-join)', 'ALERTA', 0.98, COUNT(*),
         COUNTIF(p.id_projeto IS NULL)
  FROM issue i
  LEFT JOIN (SELECT DISTINCT id_projeto FROM projeto) p ON p.id_projeto = i.id_projeto
  WHERE i.id_projeto IS NOT NULL
),
r_rot AS (
  SELECT 'trs_linear__rotulo.id_rotulo_unico' AS id_regra, 'Trusted' AS camada, 'trs_linear__rotulo' AS tabela,
         'Linear' AS sistema, 'UNICIDADE' AS dimensao, 'id_rotulo e unico e nunca nulo' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar, COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_rotulo) + COUNTIF(id_rotulo IS NULL) AS linhas_falha
  FROM rotulo
  UNION ALL
  SELECT 'trs_linear__rotulo.flag_workspace_concorda_com_a_equipe', 'Trusted', 'trs_linear__rotulo', 'Linear',
         'VALIDADE', 'flag_rotulo_de_workspace e exatamente "sem equipe"', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(flag_rotulo_de_workspace <> (id_equipe IS NULL))
  FROM rotulo
  UNION ALL
  SELECT 'trs_linear__rotulo.nome_preenchido', 'Trusted', 'trs_linear__rotulo', 'Linear', 'COMPLETUDE',
         'nome do rotulo preenchido', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(nome IS NULL)
  FROM rotulo
  UNION ALL
  SELECT 'trs_linear__rotulo.rotulo_aplicado_existe', 'Trusted', 'trs_linear__rotulo', 'Linear', 'INTEGRIDADE',
         'todo rotulo aplicado em issue (49 aplicacoes) existe no cadastro de rotulos', 'ALERTA', 0.98,
         SUM(a.qtd), SUM(IF(r.id_rotulo IS NULL, a.qtd, 0))
  FROM rotulo_aplicado a
  LEFT JOIN (SELECT DISTINCT id_rotulo FROM rotulo) r ON r.id_rotulo = a.id_rotulo
),
r_usr AS (
  SELECT 'trs_linear__usuario.id_usuario_unico' AS id_regra, 'Trusted' AS camada, 'trs_linear__usuario' AS tabela,
         'Linear' AS sistema, 'UNICIDADE' AS dimensao, 'id_usuario e unico e nunca nulo' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar, COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_usuario) + COUNTIF(id_usuario IS NULL) AS linhas_falha
  FROM usuario
  UNION ALL
  SELECT 'trs_linear__usuario.pessoa_e_o_contrario_de_app', 'Trusted', 'trs_linear__usuario', 'Linear', 'VALIDADE',
         'is_pessoa e exatamente NOT is_app (o bot do Linear nao e pessoa)', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(is_pessoa <> (NOT is_app))
  FROM usuario
  UNION ALL
  SELECT 'trs_linear__usuario.responsavel_e_criador_existem', 'Trusted', 'trs_linear__usuario', 'Linear', 'INTEGRIDADE',
         'responsavel e criador de toda issue existem no cadastro de usuarios (anti-join)', 'ALERTA', 0.98,
         COUNT(*), COUNTIF(u.id_usuario IS NULL)
  FROM (SELECT id_responsavel AS id FROM issue WHERE id_responsavel IS NOT NULL
        UNION ALL SELECT id_criador FROM issue WHERE id_criador IS NOT NULL) x
  LEFT JOIN (SELECT DISTINCT id_usuario FROM usuario) u ON u.id_usuario = x.id
  UNION ALL
  -- LINHA DE BASE com limiar 1,00: hoje a soma 55+165+10 e exatamente as 230 issues.
  SELECT 'trs_linear__usuario.issues_criadas_reproduzem_a_issue', 'Trusted', 'trs_linear__usuario', 'Linear',
         'INTEGRIDADE', 'a soma de qtd_issues_criadas reproduz o total de issues da Trusted (linha de base)',
         'ALERTA', 1.00, 1,
         IF((SELECT IFNULL(SUM(qtd_issues_criadas), 0) FROM usuario) = (SELECT COUNT(*) FROM issue), 0, 1)
),
r_eqp AS (
  SELECT 'trs_linear__equipe.id_equipe_unico' AS id_regra, 'Trusted' AS camada, 'trs_linear__equipe' AS tabela,
         'Linear' AS sistema, 'UNICIDADE' AS dimensao, 'id_equipe e unico e nunca nulo' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar, COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_equipe) + COUNTIF(id_equipe IS NULL) AS linhas_falha
  FROM equipe
  UNION ALL
  SELECT 'trs_linear__equipe.equipe_da_issue_e_do_usuario_existe', 'Trusted', 'trs_linear__equipe', 'Linear',
         'INTEGRIDADE', 'toda issue e todo usuario com equipe apontam para equipe catalogada (anti-join)',
         'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(e.id_equipe IS NULL)
  FROM (SELECT id_equipe FROM issue WHERE id_equipe IS NOT NULL
        UNION ALL SELECT id_equipe FROM usuario WHERE id_equipe IS NOT NULL) x
  LEFT JOIN (SELECT DISTINCT id_equipe FROM equipe) e ON e.id_equipe = x.id_equipe
),
r_rfn AS (
  SELECT 'rfn_operacao__linear_projeto.id_unidade_unico' AS id_regra, 'Refined' AS camada,
         'rfn_operacao__linear_projeto' AS tabela, 'Linear' AS sistema, 'UNICIDADE' AS dimensao,
         'id_unidade e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_unidade) + COUNTIF(id_unidade IS NULL) AS linhas_falha
  FROM rfn
  UNION ALL
  SELECT 'rfn_operacao__linear_projeto.taxa_null_sem_issue_viva', 'Refined', 'rfn_operacao__linear_projeto', 'Linear',
         'VALIDADE', 'taxa_conclusao e NULL exatamente quando nao ha issue viva e fica entre 0 e 1 nos demais (R2)',
         'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF((qtd_issues_nao_canceladas = 0) <> (taxa_conclusao IS NULL)
              OR taxa_conclusao < 0 OR taxa_conclusao > 1)
  FROM rfn
  UNION ALL
  SELECT 'rfn_operacao__linear_projeto.partes_nunca_excedem_o_total', 'Refined', 'rfn_operacao__linear_projeto',
         'Linear', 'VALIDADE',
         'concluidas + canceladas + abertas = issues, e concluidas, subtarefas e com responsavel nunca passam das issues',
         'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(qtd_concluidas + qtd_canceladas + qtd_abertas <> qtd_issues
              OR qtd_subtarefas > qtd_issues OR qtd_com_responsavel > qtd_issues
              OR qtd_com_rotulo > qtd_issues OR qtd_com_prazo > qtd_issues)
  FROM rfn
  UNION ALL
  SELECT 'rfn_operacao__linear_projeto.projeto_sem_issue_entra_com_zero', 'Refined', 'rfn_operacao__linear_projeto',
         'Linear', 'INTEGRIDADE', 'a Refined tem exatamente uma linha por projeto da Trusted mais o balde (R1)',
         'BLOQUEANTE', 1.00, 1,
         IF((SELECT COUNTIF(NOT flag_sem_projeto) FROM rfn) = (SELECT COUNT(*) FROM projeto)
            AND (SELECT COUNTIF(flag_sem_projeto) FROM rfn) = 1, 0, 1)
),
-- ------------------------------------- GOLD x TRUSTED: as identidades (4)
-- GRAO DA REGRA: UMA LINHA, um total contra o total do outro lado. Sao tambem o teste de frescor desta suite:
-- uma Refined defasada divergiria da Trusted na hora.
r_id AS (
  SELECT 'rfn_operacao__linear_projeto.issues_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada,
         'rfn_operacao__linear_projeto' AS tabela, 'Linear' AS sistema, 'INTEGRIDADE' AS dimensao,
         'a soma de qtd_issues reproduz o total de issues da Trusted' AS regra, 'BLOQUEANTE' AS severidade,
         1.00 AS limiar, 1 AS linhas_avaliadas,
         IF((SELECT IFNULL(SUM(qtd_issues), 0) FROM rfn) = (SELECT COUNT(*) FROM issue), 0, 1) AS linhas_falha
  UNION ALL
  SELECT 'rfn_operacao__linear_projeto.concluidas_reproduzem_a_trusted', 'Refined', 'rfn_operacao__linear_projeto',
         'Linear', 'INTEGRIDADE', 'a soma de qtd_concluidas reproduz as issues concluidas da Trusted',
         'BLOQUEANTE', 1.00, 1,
         IF((SELECT IFNULL(SUM(qtd_concluidas), 0) FROM rfn) = (SELECT COUNTIF(is_concluida) FROM issue), 0, 1)
  UNION ALL
  SELECT 'rfn_operacao__linear_projeto.canceladas_reproduzem_a_trusted', 'Refined', 'rfn_operacao__linear_projeto',
         'Linear', 'INTEGRIDADE', 'a soma de qtd_canceladas reproduz as issues canceladas da Trusted',
         'BLOQUEANTE', 1.00, 1,
         IF((SELECT IFNULL(SUM(qtd_canceladas), 0) FROM rfn) = (SELECT COUNTIF(is_cancelada) FROM issue), 0, 1)
  UNION ALL
  -- A QUE GUARDA A SENTINELA: se o balde "(sem projeto)" perder issue, as outras identidades podem continuar
  -- fechando; so esta denuncia. 26 dos dois lados hoje.
  SELECT 'rfn_operacao__linear_projeto.balde_sem_projeto_nao_perde_issue', 'Refined', 'rfn_operacao__linear_projeto',
         'Linear', 'INTEGRIDADE', 'o balde (sem projeto) carrega exatamente as issues sem projeto da Trusted',
         'BLOQUEANTE', 1.00, 1,
         IF((SELECT IFNULL(SUM(IF(flag_sem_projeto, qtd_issues, 0)), 0) FROM rfn)
            = (SELECT COUNTIF(flag_sem_projeto) FROM issue), 0, 1)
),
todas AS (
  SELECT * FROM r_proj
  UNION ALL SELECT * FROM r_rot
  UNION ALL SELECT * FROM r_usr
  UNION ALL SELECT * FROM r_eqp
  UNION ALL SELECT * FROM r_rfn
  UNION ALL SELECT * FROM r_id
),
avaliado AS (
  SELECT
    t.*,
    (t.linhas_avaliadas - t.linhas_falha)                       AS linhas_conformes,
    SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, NULLIF(t.linhas_avaliadas, 0))
                                                                AS taxa_conformidade,
    -- Regra sem linha para avaliar NAO passa: sai NULL, nunca TRUE.
    IF(t.linhas_avaliadas = 0, NULL,
       SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, t.linhas_avaliadas) >= t.limiar)
                                                                AS is_conforme,
    (t.linhas_avaliadas = 0)                                    AS flag_sem_linha_para_avaliar
  FROM todas t
)
SELECT
  a.*,
  CASE
    WHEN a.flag_sem_linha_para_avaliar          THEN 'SEM_DADO'
    WHEN a.is_conforme                          THEN 'CONFORME'
    WHEN a.severidade = 'BLOQUEANTE'            THEN 'FALHA_BLOQUEANTE'
    ELSE                                             'FALHA_ALERTA'
  END                                           AS resultado,
  'LinearEstrutura'                             AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'linear-byrt'                                 AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
