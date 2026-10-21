-- rfn_qualidade__regra_linear  ·  query-APFG  ·  19 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra
-- (a execucao se le em _extraido_at).
-- Gatilho: evento em query-v0NV, ultimo elo da cadeia DIARIA do Linear. Alerta ligado.
--
-- COM ESTA, NAO SOBRA TABELA MATERIALIZADA SEM REGRA NESTA BASE. A `trs_linear__issue`
--   (230 linhas) era a ultima. A casa passa a ter 380 regras em ONZE tabelas.
--
-- O QUE ELA NAO DUPLICA, e isso foi conferido CONSULTANDO a suite principal por `tabela`.
--   A `rfn_qualidade__regra` ja tem DUAS regras de Linear, as duas sobre a Refined:
--   `id_issue_mensal` (unicidade da chave) e `conclusao_nao_atravessa_mes`. Nenhuma das
--   19 repete essas duas. A mais proxima, `chave_concorda_com_o_grao`, mede coisa
--   diferente -- que a chave REPRODUZ o grao, nao que ela e unica -- e a
--   `media_nunca_sem_conclusao` verifica a COERENCIA de `flag_conclusao_atravessa_mes`
--   com `qtd_conclusoes_de_outro_mes`, enquanto a da principal afirma que a travessia
--   nunca acontece. Cobertura se confere consultando a suite, nunca pela memoria.
--
-- AS TRES IDENTIDADES, TODAS ENTRE CAMADAS, E ELAS SAO O PROPRIO TESTE DE FRESCOR.
--   `criadas_reproduzem_a_trusted` (230 dos dois lados), `concluidas_reproduzem_a_trusted`
--   (67) e `balde_sem_projeto_nao_perde_issue` (26). Uma Gold defasada divergiria da
--   Trusted na hora, entao NAO ha regra de carga aqui -- mesmo desenho da suite da VBOT.
--
-- A QUE GUARDA O FUSO, e ela tem historia NESTA tabela: `dt_criacao_reproduz_a_data_local`.
--   O Linear produziu o segundo caso confirmado desta base de DATA DISFARCADA DE
--   TIMESTAMP, e nele o dano seria de 100%: das 83 issues com `dueDate`, ZERO tem hora
--   diferente de 00:00:00 e TODAS AS 83 mudariam de dia se lidas com
--   `DATE(dueDate,'America/Sao_Paulo')`. Na mesma tabela `createdAt` e `completedAt` sao
--   instantes de verdade e PRECISAM da conversao. Os dois tratamentos convivem, e a
--   Trusted resolveu coluna a coluna. A regra fixa o resultado: `dt_criacao` e
--   `DATE(criada_em)` SEM segunda conversao -- se alguem reaplicar fuso sobre um valor ja
--   local, ela acende.
--
-- O QUE NAO ENTROU, E A AUSENCIA E A DECISAO:
--   Equipe unica -- ha UMA so equipe (VAN) nas 230, mas exigir isso transformaria
--     crescimento legitimo em falha. Entrou `equipe_preenchida`.
--   Os quatro campos mortos ja declarados na Trusted (`cycle`, `estimate`, `archivedAt`,
--     `previousIdentifiers`) -- nao sao emitidos, entao nao ha o que medir. Emitir para
--     depois medir seria o erro do `stats` do GitHub.
--   Responsavel -- 196 das 230 (85%) nao tem, e isso e da ORIGEM. Limiar ali acusaria o
--     que e legitimo.
--   FRESCOR DE CARGA -- a `linear-byrt` roda diaria com 100% de sucesso, mas o Linear
--     PAROU DE SER USADO: ultima issue criada 28/07/2026, ultima conclusao 25/06. Uma
--     regra de "dado recente" acusaria todo dia um fato ja conhecido: a fonte esta sa, o
--     que nao ha e atividade nova.
--
-- VALIDACAO: a query inteira foi rodada sobre as tabelas materializadas antes do deploy e
--   devolveu 19 regras, 19 ids distintos, CONFORME 19, ZERO falhas.
--
-- CLASSIFICACAO: L2 INTERNAL. So contagem, taxa e nome de regra. A `trs_linear__issue` e
--   L4 de intensidade baixa (nome de responsavel e de criador) e NADA disso atravessa.

WITH
-- ----------------------------------------------------------- trs_linear__issue (10)
r_iss AS (
  SELECT 'trs_linear__issue.id_issue_unico' AS id_regra, 'Trusted' AS camada,
         'trs_linear__issue' AS tabela, 'Linear' AS sistema, 'UNICIDADE' AS dimensao,
         'id_issue e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_issue) + COUNTIF(id_issue IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_linear__issue`

  UNION ALL
  -- `VAN-5` e a chave HUMANA -- a que aparece em branch, URL e em toda conversa.
  -- Duplicata ali quebra referencia SEM quebrar o `id_issue`.
  SELECT 'trs_linear__issue.identificador_unico', 'Trusted', 'trs_linear__issue', 'Linear',
         'UNICIDADE', 'o identificador humano (VAN-n) e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNT(*) - COUNT(DISTINCT identificador) + COUNTIF(identificador IS NULL)
  FROM `vanguardamartech_trusted`.`trs_linear__issue`

  UNION ALL
  -- Os cinco tipos canonicos do Linear. Tipo novo cairia FORA de toda leitura por estado
  -- sem a contagem de linhas mudar. A regra e segura porque o conjunto e FIXO na
  -- plataforma, ao contrario de um `tipo_evento` que a casa espera ver crescer.
  SELECT 'trs_linear__issue.estado_tipo_conhecido', 'Trusted', 'trs_linear__issue', 'Linear',
         'VALIDADE', 'estado_tipo e um dos cinco tipos canonicos do Linear', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(estado_tipo IS NULL OR estado_tipo NOT IN
                 ('backlog', 'unstarted', 'started', 'completed', 'canceled'))
  FROM `vanguardamartech_trusted`.`trs_linear__issue`

  UNION ALL
  SELECT 'trs_linear__issue.conclusao_concorda_com_o_carimbo', 'Trusted', 'trs_linear__issue',
         'Linear', 'VALIDADE',
         'is_concluida e is_cancelada concordam com os carimbos e nunca acendem juntas',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(is_concluida <> (concluida_em IS NOT NULL)
              OR is_cancelada <> (cancelada_em IS NOT NULL)
              OR (is_concluida AND is_cancelada))
  FROM `vanguardamartech_trusted`.`trs_linear__issue`

  UNION ALL
  SELECT 'trs_linear__issue.flags_concordam_com_os_ids', 'Trusted', 'trs_linear__issue',
         'Linear', 'VALIDADE',
         'flag_sem_projeto, flag_sem_responsavel e is_subtarefa concordam com os ids',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(flag_sem_projeto <> (id_projeto IS NULL)
              OR flag_sem_responsavel <> (id_responsavel IS NULL)
              OR is_subtarefa <> (id_issue_pai IS NOT NULL))
  FROM `vanguardamartech_trusted`.`trs_linear__issue`

  UNION ALL
  -- A GUARDA DO FUSO. Ver o bloco no cabecalho: nesta tabela convivem uma DATA disfarcada
  -- de TIMESTAMP (o `dueDate`, 83 de 83 mudariam de dia com conversao) e dois instantes
  -- de verdade que PRECISAM dela. `criada_em` ja e local, entao `dt_criacao` e
  -- `DATE(criada_em)` e mais nada.
  SELECT 'trs_linear__issue.dt_criacao_reproduz_a_data_local', 'Trusted', 'trs_linear__issue',
         'Linear', 'VALIDADE',
         'dt_criacao e a data do instante local de criacao, sem segunda conversao',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(dt_criacao <> DATE(criada_em))
  FROM `vanguardamartech_trusted`.`trs_linear__issue`

  UNION ALL
  SELECT 'trs_linear__issue.evento_nunca_antes_da_criacao', 'Trusted', 'trs_linear__issue',
         'Linear', 'VALIDADE', 'inicio, conclusao e atualizacao nunca antecedem a criacao',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(concluida_em < criada_em OR iniciada_em < criada_em
              OR atualizada_em < criada_em OR cancelada_em < criada_em)
  FROM `vanguardamartech_trusted`.`trs_linear__issue`

  UNION ALL
  -- Existe SO com conclusao -- nunca zero. Media de 1,88 dia e 40 das 67 no mesmo dia: se
  -- a coluna passar a sair zero onde nao ha conclusao, a media despenca e nada denuncia.
  SELECT 'trs_linear__issue.dias_ate_conclusao_reproduz_as_datas', 'Trusted', 'trs_linear__issue',
         'Linear', 'VALIDADE',
         'dias_ate_conclusao existe so com conclusao e reproduz a diferenca das datas',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF((dias_ate_conclusao IS NOT NULL) <> (concluida_em IS NOT NULL)
              OR (concluida_em IS NOT NULL
                  AND dias_ate_conclusao <> DATE_DIFF(DATE(concluida_em), DATE(criada_em), DAY)))
  FROM `vanguardamartech_trusted`.`trs_linear__issue`

  UNION ALL
  SELECT 'trs_linear__issue.contagem_nao_negativa', 'Trusted', 'trs_linear__issue', 'Linear',
         'VALIDADE', 'rotulos, comentarios, inscritos e dias nunca sao negativos',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(qtd_rotulos < 0 OR qtd_comentarios < 0 OR qtd_inscritos < 0
              OR dias_ate_conclusao < 0)
  FROM `vanguardamartech_trusted`.`trs_linear__issue`

  UNION ALL
  -- Entrou no lugar de "equipe unica": ha UMA so equipe hoje (VAN), mas exigir isso
  -- transformaria crescimento legitimo em falha.
  SELECT 'trs_linear__issue.equipe_preenchida', 'Trusted', 'trs_linear__issue', 'Linear',
         'COMPLETUDE', 'toda issue carrega equipe', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(id_equipe IS NULL OR equipe_sigla IS NULL)
  FROM `vanguardamartech_trusted`.`trs_linear__issue`
),

-- --------------------------------------------------- rfn_operacao__issue_mensal (6)
r_gold AS (
  SELECT 'rfn_operacao__issue_mensal.chave_concorda_com_o_grao' AS id_regra, 'Refined' AS camada,
         'rfn_operacao__issue_mensal' AS tabela, 'Linear' AS sistema, 'VALIDADE' AS dimensao,
         'a chave e <id_unidade>:<AAAA-MM> e id_unidade nunca e nulo' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNTIF(id_unidade IS NULL
              OR id_issue_mensal <> CONCAT(id_unidade, ':', FORMAT_DATE('%Y-%m', mes_referencia)))
           AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_operacao__issue_mensal`

  UNION ALL
  -- A SENTINELA E O DESENHO, NAO UM DESCUIDO. 26 das 230 issues nao tem projeto, e a
  -- Refined nao pode deixa-las de fora porque `id_unidade` e PARTE DA CHAVE. Em vez de
  -- NULL, ela usa o rotulo explicito `(sem projeto)` nas duas colunas.
  SELECT 'rfn_operacao__issue_mensal.sem_projeto_e_sentinela_e_nao_nulo', 'Refined',
         'rfn_operacao__issue_mensal', 'Linear', 'VALIDADE',
         'flag_sem_projeto concorda com a sentinela (sem projeto), que nunca e NULL',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(flag_sem_projeto <> (id_unidade = '(sem projeto)')
              OR projeto IS NULL
              OR flag_sem_projeto <> (projeto = '(sem projeto)'))
  FROM `vanguardamartech_refined`.`rfn_operacao__issue_mensal`

  UNION ALL
  -- COORTE e FLUXO sao populacoes diferentes e NAO se dividem uma pela outra -- a Gold
  -- declara isso. Esta regra guarda o lado que E comparavel: tudo o que e recorte da
  -- coorte cabe dentro dela.
  SELECT 'rfn_operacao__issue_mensal.parte_nunca_excede_a_coorte', 'Refined',
         'rfn_operacao__issue_mensal', 'Linear', 'VALIDADE',
         'concluidas da coorte, canceladas, subtarefas, responsavel e prazo nunca passam das criadas',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(qtd_criadas_no_mes_ja_concluidas > qtd_criadas_no_mes
              OR qtd_canceladas_no_mes > qtd_criadas_no_mes
              OR qtd_subtarefas_no_mes > qtd_criadas_no_mes
              OR qtd_com_responsavel > qtd_criadas_no_mes
              OR qtd_com_prazo > qtd_criadas_no_mes
              OR qtd_concluidas_no_mesmo_dia > qtd_concluidas_no_mes)
  FROM `vanguardamartech_refined`.`rfn_operacao__issue_mensal`

  UNION ALL
  -- A taxa e da COORTE (criadas no mes que ja concluiram), nunca fluxo sobre fluxo.
  SELECT 'rfn_operacao__issue_mensal.taxa_coorte_reproduz_a_razao', 'Refined',
         'rfn_operacao__issue_mensal', 'Linear', 'VALIDADE',
         'taxa_conclusao_coorte reproduz a razao da COORTE e nao existe sem denominador',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(taxa_conclusao_coorte IS NOT NULL
                 AND (qtd_criadas_no_mes = 0
                      OR ABS(taxa_conclusao_coorte
                             - SAFE_DIVIDE(qtd_criadas_no_mes_ja_concluidas, qtd_criadas_no_mes)) > 0.0001))
  FROM `vanguardamartech_refined`.`rfn_operacao__issue_mensal`

  UNION ALL
  SELECT 'rfn_operacao__issue_mensal.media_nunca_sem_conclusao', 'Refined',
         'rfn_operacao__issue_mensal', 'Linear', 'VALIDADE',
         'media e maximo de dias so existem com conclusao, e o maximo nunca fica abaixo da media',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF((dias_ate_conclusao_medio IS NOT NULL AND qtd_concluidas_no_mes = 0)
              OR dias_ate_conclusao_maximo < dias_ate_conclusao_medio
              OR flag_mes_sem_conclusao <> (qtd_concluidas_no_mes = 0)
              OR flag_conclusao_atravessa_mes <> (qtd_conclusoes_de_outro_mes > 0))
  FROM `vanguardamartech_refined`.`rfn_operacao__issue_mensal`

  UNION ALL
  SELECT 'rfn_operacao__issue_mensal.mes_referencia_e_o_primeiro_dia', 'Refined',
         'rfn_operacao__issue_mensal', 'Linear', 'VALIDADE',
         'mes_referencia e sempre o primeiro dia do mes', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(mes_referencia IS NULL OR mes_referencia <> DATE_TRUNC(mes_referencia, MONTH))
  FROM `vanguardamartech_refined`.`rfn_operacao__issue_mensal`
),

-- ------------------------------------- GOLD x TRUSTED: as tres identidades (3)
-- GRAO DA REGRA: UMA LINHA, nao a linha da tabela. Mesmo desenho do
-- `caixa_reproduz_o_razao` e das duas da VBOT: testa-se um TOTAL contra o total do outro
-- lado. As tres juntas sao TAMBEM o teste de frescor desta suite -- uma Gold defasada
-- divergiria da Trusted na hora.
r_gold_id AS (
  SELECT 'rfn_operacao__issue_mensal.criadas_reproduzem_a_trusted' AS id_regra, 'Refined' AS camada,
         'rfn_operacao__issue_mensal' AS tabela, 'Linear' AS sistema, 'INTEGRIDADE' AS dimensao,
         'a soma de qtd_criadas_no_mes reproduz o total de issues da Trusted' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar, 1 AS linhas_avaliadas,
         IF((SELECT IFNULL(SUM(qtd_criadas_no_mes), 0)
             FROM `vanguardamartech_refined`.`rfn_operacao__issue_mensal`)
            = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_linear__issue`), 0, 1) AS linhas_falha

  UNION ALL
  SELECT 'rfn_operacao__issue_mensal.concluidas_reproduzem_a_trusted', 'Refined',
         'rfn_operacao__issue_mensal', 'Linear', 'INTEGRIDADE',
         'a soma de qtd_concluidas_no_mes reproduz as issues concluidas da Trusted',
         'BLOQUEANTE', 1.00, 1,
         IF((SELECT IFNULL(SUM(qtd_concluidas_no_mes), 0)
             FROM `vanguardamartech_refined`.`rfn_operacao__issue_mensal`)
            = (SELECT COUNTIF(is_concluida) FROM `vanguardamartech_trusted`.`trs_linear__issue`), 0, 1)

  UNION ALL
  -- A QUE GUARDA A SENTINELA. Se o balde `(sem projeto)` perder issue, as outras duas
  -- identidades CONTINUAM fechando -- porque a issue some do balde e some do total do
  -- mesmo jeito -- e SO ESTA denuncia. 26 dos dois lados.
  SELECT 'rfn_operacao__issue_mensal.balde_sem_projeto_nao_perde_issue', 'Refined',
         'rfn_operacao__issue_mensal', 'Linear', 'INTEGRIDADE',
         'o balde (sem projeto) carrega exatamente as issues sem projeto da Trusted',
         'BLOQUEANTE', 1.00, 1,
         IF((SELECT IFNULL(SUM(IF(flag_sem_projeto, qtd_criadas_no_mes, 0)), 0)
             FROM `vanguardamartech_refined`.`rfn_operacao__issue_mensal`)
            = (SELECT COUNTIF(flag_sem_projeto) FROM `vanguardamartech_trusted`.`trs_linear__issue`), 0, 1)
),

todas AS (
  SELECT * FROM r_iss
  UNION ALL SELECT * FROM r_gold
  UNION ALL SELECT * FROM r_gold_id
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
  'Linear'                                      AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'linear-byrt'                                 AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
