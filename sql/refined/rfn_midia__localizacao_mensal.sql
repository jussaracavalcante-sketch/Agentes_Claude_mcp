-- rfn_midia__localizacao_mensal
-- PUBLICADA em 2026-09-28 como query-SGbQ, camada Refined, folder midia.
-- Grao: uma CONTA, um PAIS, uma REGIAO, uma CIDADE, um MES. 161.041 linhas,
-- 161.041 chaves, 40 contas, 9.965 cidades, 21 meses (2025-01 a 2026-09).
-- Responde: ONDE o dinheiro foi gasto, com NOME de cidade e de estado.
-- Origem: trs_google_ads__segmento_localizacao_usuario (827.446 linhas, o maior dos
-- quatro breakdowns), mais trs_google_ads__geo_alvo e trs_google_ads__conta.
--
-- ATE HOJE ESTE BREAKDOWN ERA ILEGIVEL. A Trusted carrega SO ID NUMERICO -- 9.965
-- cidades e 1.467 regioes, nenhum nome. A dimensao trs_google_ads__geo_alvo, publicada
-- no mesmo dia, e o que torna esta tabela possivel.
--
-- POR QUE ESTA TABELA E SEPARADA DA rfn_midia__segmento_mensal, e nao mais um
-- `tipo_segmento` dentro dela: a localizacao do usuario e HIERARQUICA (pais, regiao,
-- cidade) e as outras tres sao planas. Espremer tres niveis num unico `valor_segmento`
-- obrigaria a escolher um nivel e perder os outros dois. Sao duas tabelas de proposito,
-- pelo mesmo precedente do anexo de job e do anexo de comentario no VJOB.
-- E PELA MESMA RAZAO NAO SE SOMAM: as duas quebram o MESMO gasto por eixos diferentes.
--
-- REGRAS DE NEGOCIO
-- 1. MOEDA VEM POR LINHA e NAO SE SOMA ENTRE MOEDAS. 39 contas BRL, 1 USD.
-- 2. Nome de pais, regiao e cidade vem da dimensao por LEFT JOIN, sempre com flag.
--    Os ids crus ficam: o id e a chave, o nome e rotulo -- e rotulo nao e chave.
-- 3. `local_e_alvo` NAO entra no grao, vira duas medidas. Ele PARTICIONA o gasto --
--    medido em 2026-09-28: R$ 1.172.578,73 dentro do alvo + R$ 247.031,45 fora =
--    R$ 1.419.610,18, exatamente o total da Trusted. Como particiona, somar as duas
--    medidas e correto e `investimento` continua sendo o total da linha.
--    Ler: "quanto do que gastei nesta cidade caiu em localizacao que eu mirei".
-- 4. Metrica derivada calculada aqui, da razao de somas, nunca da media de razoes.
-- 5. ZERO CONVERSAO NAO E CPA ZERO: `custo_por_conversao` sai NULL, nunca zero.
-- 6. `participacao_investimento_na_conta_mes` e a fatia da linha dentro de
--    (conta, mes) -- por construcao soma 1,0 no mes da conta.
--
-- LIMITACOES MEDIDAS -- NAO CONTORNE
-- 1. NAO FECHA O INVESTIMENTO TOTAL DA CONTA. Medido contra
--    trs_google_ads__insight_diario em 2026-09-28: BRL R$ 1.399.131,92 de
--    R$ 1.498.466,27 (93,4%); USD US$ 20.478,26 de US$ 21.661,59 (94,5%).
--    E a melhor cobertura dos quatro breakdowns, e ainda assim nao e o total.
-- 2. O "pais" aqui e do USUARIO, nao da campanha. 99,3% da verba cai em alvo do
--    Brasil (R$ 1.409.626,23 de R$ 1.419.610,18); o resto e trafego de fora.
-- 3. A REGIAO NAO E SEMPRE "ESTADO" e a CIDADE NEM SEMPRE E "CIDADE". Medido pelos
--    tipos de alvo da dimensao: no nivel de regiao ha State (137.935 linhas), Region
--    (10.811), Province (6.657), Department (2.493), Governorate, County, Canton,
--    Prefecture; no nivel de cidade ha City (160.027) e Municipality (886). Sao as
--    divisoes administrativas de cada pais -- `tipo_regiao` e `tipo_cidade` saem na
--    tabela para que ninguem escreva "UF" onde o Google nao disse UF.
-- 4. 128 linhas tem cidade e 52 tem regiao que a dimensao nao traz (0,08% e 0,03%).
--    Join LEFT com flag: com INNER sumiriam sem sinal.
-- 5. NOME DE CIDADE NAO E CHAVE. Medido em 2026-09-28: 9.965 ids de cidade para
--    9.098 nomes distintos -- ha homonimo entre estados e entre paises. Agrupar por
--    `cidade` funde lugares diferentes em silencio; a chave e `id_cidade`. Mesma
--    armadilha ja medida em trs_vjob__municipio (506 municipios repetem nome no BR).
-- 6. NAO SOMAR COM rfn_midia__segmento_mensal. Sao recortes do mesmo gasto.
--
-- L2 INTERNAL. Cidade e regiao aqui sao agregados de conta e mes, nunca de pessoa.
--
-- VALIDACAO (2026-09-28, antes de publicar, reproduzindo a dimensao geo sobre a Raw
-- porque a Trusted ainda nao materializou): 161.041 linhas, 161.041 chaves, total
-- R$/US$ 1.419.610,18 reproduzindo a Trusted ao centavo, ZERO contas orfas.
--
-- Gatilho: evento em query-mkcu (rfn_midia__segmento_mensal), mantendo a cadeia da
-- segmentacao LINEAR ate o fim: google-ads-cwt3 -> query-HAB1 -> query-C8qO ->
-- query-tmws -> query-pYmL -> query-Jn5l -> query-mkcu -> esta.
WITH conta AS (
  SELECT id_conta, cliente, conta, moeda
  FROM `vanguardamartech_trusted`.`trs_google_ads__conta`
),
geo AS (
  SELECT id_alvo_geo, nome, tipo_alvo, codigo_pais
  FROM `vanguardamartech_trusted`.`trs_google_ads__geo_alvo`
),
agg AS (
  SELECT
    id_conta, id_pais, id_regiao, id_cidade, mes_referencia,
    COUNT(DISTINCT id_campanha)              AS qtd_campanhas,
    ROUND(SUM(investimento), 2)              AS investimento,
    -- REGRA 3 -- `local_e_alvo` particiona; vira medida, nao grao.
    ROUND(SUM(IF(local_e_alvo, investimento, 0)), 2)       AS investimento_em_local_alvo,
    ROUND(SUM(IF(NOT local_e_alvo, investimento, 0)), 2)   AS investimento_fora_do_alvo,
    SUM(impressoes)                          AS impressoes,
    SUM(cliques)                             AS cliques,
    SUM(interacoes)                          AS interacoes,
    ROUND(SUM(conversoes), 2)                AS conversoes,
    ROUND(SUM(todas_conversoes), 2)          AS todas_conversoes,
    ROUND(SUM(valor_conversoes), 2)          AS valor_conversoes,
    ROUND(SUM(valor_todas_conversoes), 2)    AS valor_todas_conversoes
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_localizacao_usuario`
  GROUP BY 1, 2, 3, 4, 5
)
SELECT
  CONCAT(a.id_conta, ':', a.id_pais, ':', a.id_regiao, ':', a.id_cidade, ':',
         FORMAT_DATE('%Y-%m', a.mes_referencia))            AS id_localizacao_mensal,
  a.id_conta,
  c.cliente,
  c.conta                                                   AS conta_rotulo,
  c.moeda,
  a.mes_referencia,

  a.id_pais,
  gp.nome                                                   AS pais,
  gp.codigo_pais,
  a.id_regiao,
  gr.nome                                                   AS regiao,
  gr.tipo_alvo                                              AS tipo_regiao,
  a.id_cidade,
  gc.nome                                                   AS cidade,
  gc.tipo_alvo                                              AS tipo_cidade,

  a.qtd_campanhas,
  a.investimento,
  a.investimento_em_local_alvo,
  a.investimento_fora_do_alvo,
  ROUND(SAFE_DIVIDE(a.investimento_em_local_alvo, NULLIF(a.investimento, 0)), 6)
                                                            AS participacao_local_alvo,
  a.impressoes,
  a.cliques,
  a.interacoes,
  a.conversoes,
  a.todas_conversoes,
  a.valor_conversoes,
  a.valor_todas_conversoes,

  -- REGRA 4 -- razao de somas.
  ROUND(SAFE_DIVIDE(a.cliques, NULLIF(a.impressoes, 0)), 6)       AS ctr,
  ROUND(SAFE_DIVIDE(a.investimento, NULLIF(a.cliques, 0)), 2)     AS cpc,
  ROUND(SAFE_DIVIDE(a.investimento, NULLIF(a.impressoes, 0)) * 1000, 2) AS cpm,
  ROUND(SAFE_DIVIDE(a.conversoes, NULLIF(a.cliques, 0)), 6)       AS taxa_conversao,
  -- REGRA 5 -- sem conversao, NULL. Nunca zero.
  ROUND(SAFE_DIVIDE(a.investimento, NULLIF(a.conversoes, 0)), 2)  AS custo_por_conversao,
  ROUND(SAFE_DIVIDE(a.valor_conversoes, NULLIF(a.investimento, 0)), 4)
                                                            AS retorno_sobre_investimento,

  -- REGRA 6 -- fatia dentro de (conta, mes). Soma 1,0 por construcao.
  ROUND(SAFE_DIVIDE(
    a.investimento,
    NULLIF(SUM(a.investimento) OVER (
      PARTITION BY a.id_conta, a.mes_referencia), 0)), 6)   AS participacao_investimento_na_conta_mes,

  (gp.id_alvo_geo IS NULL)                                  AS flag_pais_nao_catalogado,
  (gr.id_alvo_geo IS NULL)                                  AS flag_regiao_nao_catalogada,
  (gc.id_alvo_geo IS NULL)                                  AS flag_cidade_nao_catalogada,
  (a.investimento > 0 AND a.conversoes = 0)                 AS flag_gasta_sem_converter,

  CURRENT_TIMESTAMP()                                       AS _extraido_at
FROM agg a
LEFT JOIN conta c ON c.id_conta   = a.id_conta
LEFT JOIN geo   gp ON gp.id_alvo_geo = a.id_pais
LEFT JOIN geo   gr ON gr.id_alvo_geo = a.id_regiao
LEFT JOIN geo   gc ON gc.id_alvo_geo = a.id_cidade
