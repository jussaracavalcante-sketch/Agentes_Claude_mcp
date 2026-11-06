-- rfn_midia__segmento_mensal
-- PUBLICADA em 2026-09-28 como query-mkcu, camada Refined, folder midia.
-- Grao: uma CONTA, um TIPO de segmento, um VALOR de segmento, um MES. 7.886 linhas,
-- 7.886 chaves distintas, 40 contas, 21 meses (2025-01 a 2026-09).
-- Responde: QUEM viu e clicou -- por idade, por genero e por pais.
-- Origem: tres Trusted de breakdown do Google Ads que nao tinham camada de consumo --
-- trs_google_ads__segmento_faixa_etaria (296.566), __segmento_genero (143.895) e
-- __segmento_geografico (74.245). Mais a dimensao trs_google_ads__geo_alvo e a
-- trs_google_ads__conta.
--
-- A REGRA QUE DECIDE TUDO: `tipo_segmento` E FILTRO, NUNCA GROUP BY PARA SOMAR ENTRE
-- TIPOS. A MESMA verba aparece em cada tipo -- o Google quebra o mesmo gasto por idade
-- E por genero E por pais. Somar as 7.886 linhas devolve ~4x o investimento real.
-- Dentro de UM tipo_segmento a soma e correta e fecha com a Trusted.
--
-- POR ISSO O TIPO DE LOCALIZACAO ENTROU NO `tipo_segmento`, e nao numa coluna a parte.
-- A Trusted geografica tem `tipo_localizacao` com dois valores que TAMBEM quebram o
-- mesmo gasto: medido em 2026-09-28, LOCATION_OF_PRESENCE R$ 1.224.598,99 e
-- AREA_OF_INTEREST R$ 295.528,43, somando R$ 1.520.127,42 -- mais que o investimento
-- da conta. Deixar os dois como um recorte interno convidaria a somar; dobrados dentro
-- do proprio `tipo_segmento` (PAIS_PRESENCA e PAIS_INTERESSE), a regra passa a ser UMA
-- SO, sem excecao: some dentro do tipo, nunca entre tipos.
--   PAIS_PRESENCA  -- onde a pessoa estava fisicamente.
--   PAIS_INTERESSE -- o lugar sobre o qual ela demonstrou interesse.
--
-- REGRAS DE NEGOCIO
-- 1. MOEDA VEM POR LINHA, da trs_google_ads__conta, e NAO SE SOMA ENTRE MOEDAS.
--    39 contas em BRL e 1 em USD. Toda leitura de valor agrupa por `moeda`.
-- 2. `valor_segmento` e o CODIGO cru da origem; `rotulo_segmento` e a leitura humana.
--    O codigo fica porque rotulo nao e chave -- doutrina ja registrada nesta base.
-- 3. Metrica derivada e CALCULADA AQUI, da razao de somas, nunca da media de razoes.
--    Na Trusted ela passa como a plataforma entrega (ADR-0009); Refined e onde a
--    regra de negocio mora.
-- 4. ZERO CONVERSAO NAO E CUSTO POR CONVERSAO ZERO: `custo_por_conversao` sai NULL
--    quando nao houve conversao, nunca zero. Zero seria somado; NULL obriga a decidir.
--    Mesma doutrina de `taxa_conclusao` em rfn_operacao__escopo_mensal.
-- 5. `participacao_investimento` e a fatia da linha DENTRO de (conta, tipo, mes) --
--    e a pergunta que o setor faz ("quanto do meu dinheiro foi para 25-34?"). Por
--    construcao soma 1,0 dentro do tipo, e por isso mesmo nao faz sentido entre tipos.
-- 6. `flag_segmento_nao_identificado` marca UNDETERMINED e AGE_RANGE_UNDETERMINED.
--    NAO e um publico: e a parte que o Google nao consegue atribuir. Ler "o publico
--    e X%" sem separa-la distorce o denominador.
--
-- LIMITACOES MEDIDAS -- NAO CONTORNE
-- 1. ESTA TABELA NAO FECHA O INVESTIMENTO TOTAL DA CONTA, e o motivo e do Google:
--    campanha sem sinal demografico (PMax, parte de Display e Video) nao publica
--    breakdown. Medido em 2026-09-28 contra trs_google_ads__insight_diario:
--      BRL -- total R$ 1.498.466,27; faixa etaria R$ 1.210.247,70 (80,8%);
--             genero R$ 1.210.246,53 (80,8%); pais presenca R$ 1.208.269,86 (80,6%).
--      USD -- total US$ 21.661,59; faixa etaria US$ 20.314,47 (93,8%);
--             pais presenca US$ 16.329,13 (75,4%).
--    Serve para ler PERFIL, nunca para totalizar verba. O total e a insight_diario.
-- 2. Faixa etaria e genero cobrem quase exatamente o mesmo dinheiro (diferenca de
--    R$ 1,16 em 1,2 milhao). Isso NAO e duplicidade: sao dois recortes do mesmo gasto.
-- 3. 15 das 2.436 linhas de pais apontam para id de alvo que a dimensao nao traz.
--    O join e LEFT e `flag_pais_nao_catalogado` acende. Com INNER elas sumiriam sem
--    sinal -- orfao e melhor que falso par.
-- 4. Nao ha recorte por campanha aqui: `qtd_campanhas` conta quantas contribuiram, e
--    so. Para campanha, a tabela e a rfn_midia__desempenho_diario.
--
-- L4 PERSONAL_DATA por prudencia de linhagem? NAO -- L2 INTERNAL. Idade, genero e pais
-- aqui sao AGREGADOS de conta e mes, nunca de pessoa: o menor grao possivel e
-- "as mulheres de 25-34 desta conta neste mes". Nao ha identificador individual em
-- nenhuma das tres origens.
--
-- VALIDACAO (2026-09-28, antes de publicar, reproduzindo a dimensao geo sobre a Raw
-- porque a Trusted ainda nao materializou): 7.886 linhas, 7.886 chaves, ZERO contas
-- orfas, 199 paises, e os totais por tipo reproduzem a Trusted ao centavo.
--
-- Gatilho: evento em query-Jn5l (trs_google_ads__geo_alvo), ultimo elo da cadeia
-- LINEARIZADA da segmentacao: google-ads-cwt3 -> query-HAB1 -> query-C8qO ->
-- query-tmws -> query-pYmL -> query-Jn5l -> esta. Antes os quatro breakdowns
-- disparavam EM PARALELO na fonte, e evento em paralelo nao garante ordem: esta query
-- podia rodar antes de um deles materializar e cair inteira.
WITH conta AS (
  SELECT id_conta, cliente, conta, moeda
  FROM `vanguardamartech_trusted`.`trs_google_ads__conta`
),
geo AS (
  SELECT id_alvo_geo, nome
  FROM `vanguardamartech_trusted`.`trs_google_ads__geo_alvo`
),
fe AS (
  SELECT id_conta, 'FAIXA_ETARIA' AS tipo_segmento, faixa_etaria AS valor_segmento,
         mes_referencia, id_campanha, investimento, impressoes, cliques, interacoes,
         conversoes, todas_conversoes, valor_conversoes, valor_todas_conversoes
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_faixa_etaria`
),
gn AS (
  SELECT id_conta, 'GENERO', genero, mes_referencia, id_campanha, investimento,
         impressoes, cliques, interacoes, conversoes, todas_conversoes,
         valor_conversoes, valor_todas_conversoes
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_genero`
),
-- O tipo de localizacao entra no PROPRIO tipo_segmento. Ver o bloco de cabecalho:
-- e o que torna "some dentro do tipo, nunca entre tipos" uma regra sem excecao.
ge AS (
  SELECT id_conta,
         CASE tipo_localizacao
           WHEN 'LOCATION_OF_PRESENCE' THEN 'PAIS_PRESENCA'
           WHEN 'AREA_OF_INTEREST'     THEN 'PAIS_INTERESSE'
           ELSE CONCAT('PAIS_', COALESCE(tipo_localizacao, 'SEM_TIPO')) END,
         id_pais, mes_referencia, id_campanha, investimento, impressoes, cliques,
         interacoes, conversoes, todas_conversoes, valor_conversoes,
         valor_todas_conversoes
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_geografico`
),
uniao AS (
  SELECT * FROM fe
  UNION ALL SELECT * FROM gn
  UNION ALL SELECT * FROM ge
),
agg AS (
  SELECT
    id_conta, tipo_segmento, valor_segmento, mes_referencia,
    COUNT(DISTINCT id_campanha)          AS qtd_campanhas,
    ROUND(SUM(investimento), 2)          AS investimento,
    SUM(impressoes)                      AS impressoes,
    SUM(cliques)                         AS cliques,
    SUM(interacoes)                      AS interacoes,
    ROUND(SUM(conversoes), 2)            AS conversoes,
    ROUND(SUM(todas_conversoes), 2)      AS todas_conversoes,
    ROUND(SUM(valor_conversoes), 2)      AS valor_conversoes,
    ROUND(SUM(valor_todas_conversoes), 2) AS valor_todas_conversoes
  FROM uniao
  GROUP BY 1, 2, 3, 4
)
SELECT
  CONCAT(a.id_conta, ':', a.tipo_segmento, ':', a.valor_segmento, ':',
         FORMAT_DATE('%Y-%m', a.mes_referencia))                  AS id_segmento_mensal,
  a.id_conta,
  c.cliente,
  c.conta                                                         AS conta_rotulo,
  c.moeda,
  a.mes_referencia,
  a.tipo_segmento,
  a.valor_segmento,

  -- Rotulo humano. O codigo cru permanece em `valor_segmento`: rotulo nao e chave.
  CASE
    WHEN a.tipo_segmento = 'FAIXA_ETARIA' THEN
      CASE a.valor_segmento
        WHEN 'AGE_RANGE_18_24' THEN '18-24'
        WHEN 'AGE_RANGE_25_34' THEN '25-34'
        WHEN 'AGE_RANGE_35_44' THEN '35-44'
        WHEN 'AGE_RANGE_45_54' THEN '45-54'
        WHEN 'AGE_RANGE_55_64' THEN '55-64'
        WHEN 'AGE_RANGE_65_UP' THEN '65 ou mais'
        WHEN 'AGE_RANGE_UNDETERMINED' THEN 'Nao identificado'
        ELSE a.valor_segmento END
    WHEN a.tipo_segmento = 'GENERO' THEN
      CASE a.valor_segmento
        WHEN 'FEMALE' THEN 'Feminino'
        WHEN 'MALE' THEN 'Masculino'
        WHEN 'UNDETERMINED' THEN 'Nao identificado'
        ELSE a.valor_segmento END
    ELSE g.nome
  END                                                             AS rotulo_segmento,

  a.qtd_campanhas,
  a.investimento,
  a.impressoes,
  a.cliques,
  a.interacoes,
  a.conversoes,
  a.todas_conversoes,
  a.valor_conversoes,
  a.valor_todas_conversoes,

  -- REGRA 3 -- razao de somas, nunca media de razoes.
  ROUND(SAFE_DIVIDE(a.cliques, NULLIF(a.impressoes, 0)), 6)       AS ctr,
  ROUND(SAFE_DIVIDE(a.investimento, NULLIF(a.cliques, 0)), 2)     AS cpc,
  ROUND(SAFE_DIVIDE(a.investimento, NULLIF(a.impressoes, 0)) * 1000, 2) AS cpm,
  ROUND(SAFE_DIVIDE(a.conversoes, NULLIF(a.cliques, 0)), 6)       AS taxa_conversao,
  -- REGRA 4 -- sem conversao, NULL. Nunca zero.
  ROUND(SAFE_DIVIDE(a.investimento, NULLIF(a.conversoes, 0)), 2)  AS custo_por_conversao,
  ROUND(SAFE_DIVIDE(a.valor_conversoes, NULLIF(a.investimento, 0)), 4) AS retorno_sobre_investimento,

  -- REGRA 5 -- fatia DENTRO de (conta, tipo, mes). Soma 1,0 por construcao.
  ROUND(SAFE_DIVIDE(
    a.investimento,
    NULLIF(SUM(a.investimento) OVER (
      PARTITION BY a.id_conta, a.tipo_segmento, a.mes_referencia), 0)), 6)
                                                                  AS participacao_investimento,

  (a.tipo_segmento LIKE 'PAIS%')                                  AS flag_e_geografico,
  (a.tipo_segmento LIKE 'PAIS%' AND g.id_alvo_geo IS NULL)        AS flag_pais_nao_catalogado,
  (a.valor_segmento IN ('UNDETERMINED', 'AGE_RANGE_UNDETERMINED')) AS flag_segmento_nao_identificado,
  (a.investimento > 0 AND a.conversoes = 0)                       AS flag_gasta_sem_converter,

  CURRENT_TIMESTAMP()                                             AS _extraido_at
FROM agg a
LEFT JOIN conta c ON c.id_conta = a.id_conta
LEFT JOIN geo   g ON g.id_alvo_geo = a.valor_segmento
                 AND a.tipo_segmento LIKE 'PAIS%'
