-- rfn_qualidade__regra_midia_termo  ·  query-XAmt  ·  12 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra
-- (a execucao se le em _extraido_at).
-- Gatilho: evento em query-sGXo -- a propria transformacao que escreve a tabela medida.
-- Alerta ligado. Cadencia SEMANAL, na cadeia do Google Ads.
--
-- A LACUNA QUE ISTO FECHA, E ELA DESMENTE UMA AFIRMACAO MINHA DE 30/09.
--   Em 30/09 eu escrevi que "nao sobra tabela materializada sem regra nesta base". ERA
--   FALSO. Um inventario cruzando as 152 transformacoes ativas da Nekt contra o
--   repositorio, feito em 01/10, achou DUAS Refined materializadas com ZERO regra -- e
--   uma delas e a MAIOR tabela Refined da casa:
--     `rfn_midia__termo_busca_mensal`  1.368.269 linhas  (query-sGXo, de 28/09)
--     `rfn_cliente__contexto`                410 linhas  (query-2k3p, de 25/09)
--   As duas existem no deploy E no repositorio; o que faltava era o REGISTRO, e com ele
--   a cobertura. Cobertura se confere cruzando a plataforma contra o repositorio, nunca
--   pela memoria do que foi escrito.
--
-- POR QUE UMA SUITE PROPRIA, E A RAZAO NAO E TAMANHO -- E ACOPLAMENTO E ORDEM.
--   A suite de Midia (query-4tgF, 43 regras) dispara em `query-SGbQ`. MEDIDO: na passada
--   de 29/09 a `SGbQ` rodou as 13:52 e a `sGXo` as 16:49 -- TRES HORAS DEPOIS. Hospedar
--   estas 12 regras la faria a suite medir a tabela da SEMANA ANTERIOR: mediria certo e
--   mediria velho, que e o pior tipo de medicao porque nada denuncia.
--   A alternativa seria acrescentar `sGXo` ao conjunto "all" da 4tgF, como se fez com a
--   `query-BzKD` na suite do iClips em 30/09. NAO FOI TOMADA, e o motivo esta medido:
--   isso acoplaria as 43 regras que cobrem o NUCLEO do negocio da casa ao sucesso de UMA
--   Gold. Se a `sGXo` falhar, as 43 param junto. Com suite propria, cada uma cai sozinha.
--   O CONTRATO DE COLUNAS E IDENTICO ao das outras onze.
--
-- O QUE NAO ENTROU, E A AUSENCIA E A DECISAO:
--   Cobertura de verba -- a Gold declara que NAO FECHA A VERBA e que isso e da origem (o
--     Google omite termo abaixo do limiar de privacidade; de 15,7% a 86,8% por conta).
--     Regra de completude ali acusaria todo dia o que a plataforma decidiu nao publicar.
--   `flag_excluido_em_alguma_campanha` -- a Gold declara que NAO HA DATA DE NEGATIVACAO,
--     entao gasto de termo excluido nao prova vazamento. Nao ha invariante a testar.
--   Metrica derivada (custo_por_clique, taxa_conversao, retorno_sobre_investimento) --
--     e decisao de negocio calculada AQUI de proposito, e sai NULL sem denominador.
--     Testar a razao reproduziria a formula em vez de guardar premissa, e CPC e CPM ja
--     ficaram de fora da suite de Midia Gold por divergirem no arredondamento.
--
-- VALIDACAO: as 12 medidas na tabela materializada, e a query inteira rodada antes do
--   deploy UNIDA A UMA CTE DE OUTRA SUITE, para testar o alinhamento do UNION:
--   12 regras, 12 ids distintos, CONFORME 12, ZERO falhas.
--
-- CLASSIFICACAO: L2 INTERNAL. A Gold medida e L4 PERSONAL_DATA -- termo digitado por
--   pessoa pode conter nome, telefone ou endereco. NENHUM termo atravessa: so contagem,
--   taxa e nome de regra. Mesmo caminho da `rfn_operacao__custo_peca`.

WITH
-- ───────────────────── rfn_midia__termo_busca_mensal, dentro da tabela (11) ──────────
r_termo AS (
  SELECT 'rfn_midia__termo_busca_mensal.id_termo_mensal_unico' AS id_regra, 'Refined' AS camada,
         'rfn_midia__termo_busca_mensal' AS tabela, 'Google Ads' AS sistema,
         'UNICIDADE' AS dimensao,
         'id_termo_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade,
         1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_termo_mensal) + COUNTIF(id_termo_mensal IS NULL)
           AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_midia__termo_busca_mensal`

  UNION ALL
  -- A Gold declara que a chave NAO carrega o termo em texto: e conta:mes:MD5(termo),
  -- para manter a chave curta e nao enfiar texto livre de terceiro num identificador.
  -- Esta regra reconstroi o MD5 e confere.
  SELECT 'rfn_midia__termo_busca_mensal.chave_concorda_com_o_grao', 'Refined',
         'rfn_midia__termo_busca_mensal', 'Google Ads', 'VALIDADE',
         'a chave e conta mais mes mais o MD5 do termo, e o termo nunca e vazio',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(NULLIF(termo, '') IS NULL
              OR id_termo_mensal <> CONCAT(CAST(id_conta AS STRING), ':',
                                           CAST(mes_referencia AS STRING), ':',
                                           TO_HEX(MD5(termo))))
  FROM `vanguardamartech_refined`.`rfn_midia__termo_busca_mensal`

  UNION ALL
  SELECT 'rfn_midia__termo_busca_mensal.mes_concorda_com_ano_e_mes', 'Refined',
         'rfn_midia__termo_busca_mensal', 'Google Ads', 'VALIDADE',
         'mes_referencia e exatamente o primeiro dia do proprio ano e mes',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(mes_referencia <> DATE(ano, mes, 1))
  FROM `vanguardamartech_refined`.`rfn_midia__termo_busca_mensal`

  UNION ALL
  SELECT 'rfn_midia__termo_busca_mensal.caracteres_reproduz_o_termo', 'Refined',
         'rfn_midia__termo_busca_mensal', 'Google Ads', 'VALIDADE',
         'qtd_caracteres_do_termo reproduz o comprimento do proprio termo',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_caracteres_do_termo <> LENGTH(termo))
  FROM `vanguardamartech_refined`.`rfn_midia__termo_busca_mensal`

  UNION ALL
  SELECT 'rfn_midia__termo_busca_mensal.janela_cai_dentro_do_mes', 'Refined',
         'rfn_midia__termo_busca_mensal', 'Google Ads', 'VALIDADE',
         'primeiro e ultimo dia caem no mes, nao invertem, e os dias com registro cabem na janela',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(ultimo_dia < primeiro_dia
              OR primeiro_dia < mes_referencia OR ultimo_dia > LAST_DAY(mes_referencia)
              OR dias_com_registro < 1
              OR dias_com_registro > DATE_DIFF(ultimo_dia, primeiro_dia, DAY) + 1)
  FROM `vanguardamartech_refined`.`rfn_midia__termo_busca_mensal`

  UNION ALL
  -- Os quatro recortes que a tabela existe para oferecer. A regra 4 da Gold declara que
  -- 88,3% das linhas sao cauda com impressao e ZERO clique, e que elas ficam MARCADAS em
  -- vez de descartadas, "porque descartar esconderia o tamanho real da cauda, que e o
  -- proprio assunto da tabela". Se a flag soltar, o recorte some sem a contagem mudar.
  SELECT 'rfn_midia__termo_busca_mensal.flags_decompoem', 'Refined',
         'rfn_midia__termo_busca_mensal', 'Google Ads', 'VALIDADE',
         'tem_investimento, tem_conversao, flag_gasta_sem_converter e flag_so_impressao concordam com as metricas',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(tem_investimento <> (investimento > 0)
              OR tem_conversao <> (conversoes > 0)
              OR flag_gasta_sem_converter <> (investimento > 0 AND conversoes = 0)
              OR flag_so_impressao <> (impressoes > 0 AND cliques = 0))
  FROM `vanguardamartech_refined`.`rfn_midia__termo_busca_mensal`

  UNION ALL
  -- Inclui `investimento_variante_proxima > investimento`: a Gold mede que 30,1% do
  -- investimento BRL vai para variante proxima, e a parte nunca passa do todo.
  SELECT 'rfn_midia__termo_busca_mensal.metrica_nao_negativa', 'Refined',
         'rfn_midia__termo_busca_mensal', 'Google Ads', 'VALIDADE',
         'investimento, impressao, clique, conversao e valor nunca sao negativos, e a parte nunca passa do todo',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(investimento < 0 OR impressoes < 0 OR cliques < 0 OR conversoes < 0
              OR valor_conversoes < 0 OR investimento_variante_proxima < 0
              OR investimento_variante_proxima > investimento
              OR conversoes > todas_conversoes
              OR qtd_grupos_anuncio < qtd_campanhas)
  FROM `vanguardamartech_refined`.`rfn_midia__termo_busca_mensal`

  UNION ALL
  -- A Gold avisa em maiusculas para NUNCA SOMAR AS DUAS MOEDAS -- 39 contas em BRL e UMA
  -- em USD, e esta base nao tem taxa de cambio por dia. Moeda faltando quebraria o
  -- agrupamento obrigatorio em silencio.
  SELECT 'rfn_midia__termo_busca_mensal.moeda_conhecida', 'Refined',
         'rfn_midia__termo_busca_mensal', 'Google Ads', 'VALIDADE',
         'moeda e BRL ou USD e nunca falta', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(moeda IS NULL OR moeda NOT IN ('BRL', 'USD'))
  FROM `vanguardamartech_refined`.`rfn_midia__termo_busca_mensal`

  UNION ALL
  SELECT 'rfn_midia__termo_busca_mensal.conta_catalogada', 'Refined',
         'rfn_midia__termo_busca_mensal', 'Google Ads', 'INTEGRIDADE',
         'toda linha resolve a conta na dimensao', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_conta_nao_catalogada OR NULLIF(conta, '') IS NULL)
  FROM `vanguardamartech_refined`.`rfn_midia__termo_busca_mensal`

  UNION ALL
  -- A UNICA LINHA DE BASE, COM O LIMIAR MEDIDO NESTA TABELA E NAO HERDADO.
  -- 2.239 de 1.368.269 (0,16%). Investigado antes de virar limiar: maior excesso TRES
  -- cliques, media 1,01, e NENHUM caso com impressao zero. Sao as mesmas 2.239 linhas em
  -- que `interacoes` tambem excede -- zero de um lado so. E o arredondamento de
  -- atribuicao do proprio Google, a mesma familia ja medida em localizacao (273 de
  -- 161.613, limiar 0,998), segmento (3 de 7.886, 0,999) e desempenho diario (4 de
  -- 86.267). Limiar unico por simetria reprovaria o que e legitimo.
  SELECT 'rfn_midia__termo_busca_mensal.clique_nunca_excede_impressao', 'Refined',
         'rfn_midia__termo_busca_mensal', 'Google Ads', 'VALIDADE',
         'o clique nunca passa da impressao', 'ALERTA', 0.998,
         COUNT(*), COUNTIF(cliques > impressoes)
  FROM `vanguardamartech_refined`.`rfn_midia__termo_busca_mensal`

  UNION ALL
  SELECT 'rfn_midia__termo_busca_mensal.campanha_principal_preenchida', 'Refined',
         'rfn_midia__termo_busca_mensal', 'Google Ads', 'COMPLETUDE',
         'toda linha carrega a campanha de maior investimento no mes', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(NULLIF(campanha_principal, '') IS NULL
              OR NULLIF(CAST(id_campanha_principal AS STRING), '') IS NULL)
  FROM `vanguardamartech_refined`.`rfn_midia__termo_busca_mensal`
),

-- ─────────────────────── a DESIGUALDADE, com o GRUPO como grao (1) ───────────────────
-- O termo de busca e um RECORTE do investimento da conta: so campanha de busca gera
-- termo, e o Google nao publica termo abaixo do limiar de privacidade. Entao a soma por
-- (conta, mes) NUNCA pode passar do total da conta no mes. Se passar, o grao duplicou --
-- e nada na contagem de linhas denuncia, porque a chave continua unica.
-- GRAO DA REGRA: o GRUPO (conta, mes), nao a linha. Medido em 01/10: 531 grupos, ZERO
-- sem par no insight, ZERO excedendo, maior excesso ZERO. R$ 669.929,44 de termo contra
-- R$ 1.522.197,48 de insight -- 44%, consistente com a cobertura de 61,2% da verba de
-- BUSCA que a propria Gold declara (o insight carrega toda a verba, nao so a de busca).
r_desigualdade AS (
  SELECT 'rfn_midia__termo_busca_mensal.investimento_nao_excede_a_conta_no_mes' AS id_regra,
         'Refined' AS camada, 'rfn_midia__termo_busca_mensal' AS tabela,
         'Google Ads' AS sistema, 'VALIDADE' AS dimensao,
         'a soma do investimento de termo por conta-mes nunca passa do total da conta no mes'
           AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNTIF(t.inv_termo > IFNULL(i.inv_insight, 0) + 0.005) AS linhas_falha
  FROM (SELECT CAST(id_conta AS STRING) AS c, mes_referencia AS m,
               SUM(investimento) AS inv_termo
        FROM `vanguardamartech_refined`.`rfn_midia__termo_busca_mensal`
        GROUP BY 1, 2) t
  LEFT JOIN (SELECT CAST(id_conta AS STRING) AS c, DATE_TRUNC(data, MONTH) AS m,
                    SUM(investimento) AS inv_insight
             FROM `vanguardamartech_trusted`.`trs_google_ads__insight_diario`
             GROUP BY 1, 2) i
    USING (c, m)
),

todas AS (
  SELECT * FROM r_termo
  UNION ALL SELECT * FROM r_desigualdade
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
  'Midia Termo'                                 AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
