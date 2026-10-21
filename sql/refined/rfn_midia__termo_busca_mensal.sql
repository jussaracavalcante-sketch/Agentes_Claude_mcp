-- rfn_midia__termo_busca_mensal
-- Refined / dominio MIDIA. Grao: uma CONTA, um TERMO DE BUSCA, um MES.
-- Chave: id_termo_mensal. Origem: trs_google_ads__termo_busca + trs_google_ads__conta.
--
-- O QUE ELA RESPONDE: **em que o dinheiro de busca e realmente gasto, e o que
--   disso volta.** A `trs_google_ads__termo_busca` tem 3.096.346 linhas no grao
--   (campanha, grupo, termo, correspondencia, DIA) -- e nenhuma camada de consumo.
--   Era a maior tabela tratada da casa sem Refined, na maior area da casa.
--
-- **40,9% DO INVESTIMENTO DE TERMO VAI PARA TERMO QUE NAO CONVERTEU NO MES.**
--   Medido em 2026-09-28 no grao desta tabela: 159.552 linhas tem investimento e
--   **107.687 delas (67,5%) tem ZERO conversao**, somando **268.543,81** de
--   656.860,10. E a lista de negativacao que esta base nunca teve.
--
-- **30% DO INVESTIMENTO VAI PARA VARIANTE PROXIMA, NAO PARA O QUE FOI COMPRADO.**
--   `tipo_correspondencia` tem seis valores e dois deles sao do Google, nao do
--   anunciante: `NEAR_PHRASE` e `NEAR_EXACT` sao a correspondencia por variante
--   proxima. Medido: BRL **R$ 195.016,81 de R$ 647.380,10 (30,1%)** e USD
--   **US$ 2.273,38 de US$ 9.480,00 (24,0%)**. `flag_tem_variante_proxima` existe
--   para esse recorte ser um filtro, nao uma conta na mao.
--
-- **TERMO JA NEGATIVADO CONTINUA GASTANDO.** `status_termo = EXCLUDED` aparece em
--   15.598 linhas da Trusted somando 8.958,32, que viram **2.731 linhas aqui**. Pode
--   ser gasto ANTERIOR a negativacao -- a tabela nao data a exclusao -- mas
--   `flag_excluido_em_alguma_campanha` torna o caso visivel para quem for conferir.
--
-- **NUNCA SOMAR AS DUAS MOEDAS.** 39 contas em BRL e **uma em USD** (Move Rental
--   Cars). A Trusted NAO carrega moeda; ela vem de `trs_google_ads__conta`, que
--   resolve **40 de 40 contas, zero orfas**. `moeda` sai em toda linha e qualquer
--   soma tem de agrupar por ela.
--
-- LIMITACAO QUE MANDA -- **ESTA TABELA NAO FECHA A VERBA, E ISSO E DA ORIGEM.**
--   O Google nao publica termo com volume abaixo do limiar de privacidade. A
--   propria Trusted declara a medicao: cobre **61,2% da verba de busca em BRL** e
--   **47,7% em USD**, com faixa por conta de 15,7% (MILLENIUM) a 86,8% (SANTO
--   REMEDIO). **Serve para analise de query e negativacao, nunca para totalizar
--   verba** -- para total, a tabela e a `trs_google_ads__insight_diario`.
--
-- CLASSIFICACAO: **L4 PERSONAL_DATA, herdado da Trusted.** Termo digitado por
--   pessoa pode conter nome, telefone ou endereco. Nao publicar termo cru em
--   painel aberto.
--
-- REGRAS
--   1. GRAO = (conta, termo, mes). A Trusted tem campanha e grupo; aqui elas
--      viram CONTAGEM (`qtd_campanhas`, `qtd_grupos_anuncio`) mais a campanha de
--      maior investimento no mes (`campanha_principal`), escolhida agregando por
--      campanha ANTES de ordenar -- nao e a campanha da linha-dia mais cara.
--      **Negativar e por campanha ou grupo, entao a acao continua sendo na Trusted.**
--   2. METRICA DERIVADA E DECISAO DE NEGOCIO, e por isso ela existe AQUI e nao na
--      Trusted: `custo_por_clique`, `custo_por_conversao` e `taxa_conversao` saem
--      calculados. **Sem conversao, `custo_por_conversao` sai NULL -- nunca zero e
--      nunca infinito.** Zero seria somado; NULL obriga quem le a decidir.
--   3. ZERO CONVERSAO NAO E ZERO DESEMPENHO. A conversao aqui e a que a conta
--      declara ao Google, com a janela de atribuicao dela. Termo sem conversao
--      pode ter ajudado uma conversao atribuida a outro ponto do caminho.
--      `flag_gasta_sem_converter` e candidato a revisao, nao veredicto.
--   4. A CAUDA E A MAIORIA: **1.201.011 das 1.360.500 linhas (88,3%) tem impressao
--      e ZERO clique**, e 1.200.948 tem zero investimento. Elas ficam, marcadas com
--      `flag_so_impressao` -- descartar esconderia o tamanho real da cauda, que e o
--      proprio assunto da tabela.
--   5. `status_termo` e `tipo_correspondencia` variam DENTRO do grao, porque o mesmo
--      termo cai em campanhas diferentes. Por isso saem como AGREGADO
--      (`tipos_correspondencia`, `status_termos`) e como flag, nunca como valor
--      unico escolhido.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **Nao ha data de negativacao.** `EXCLUDED` diz o estado na extracao, nao
--      quando passou a valer. Gasto de termo excluido nao prova vazamento.
--   2. **Nao ha palavra-chave.** O termo e o que a pessoa digitou; a palavra-chave
--      comprada esta em `trs_google_ads__insight_diario` por outro caminho. Esta
--      tabela nao diz qual keyword acionou o termo.
--   3. A janela e **2025-01-01 a 2026-09-21** e depende da ultima carga do Google
--      Ads, que roda por evento na fonte de cron mais tardio das 42.
--   4. Somar `investimento` entre contas sem agrupar por `moeda` mistura real com
--      dolar. A tabela nao converte cambio -- converter exigiria uma taxa por dia
--      que esta base nao tem.
--
-- VALIDACAO 2026-09-28 (medida na Trusted materializada, antes de publicar)
--   1.360.500 linhas · 1.360.500 chaves distintas · 40 contas (39 BRL + 1 USD) ·
--   598.477 termos distintos · janela 2025-01 a 2026-09 · **zero contas sem
--   dimensao** · 159.552 linhas com investimento, das quais 107.687 sem conversao
--   (268.543,81) · 52.131 com conversao · 1.201.011 so com impressao · 2.731 com
--   termo excluido em alguma campanha · **zero linhas sem moeda, sem campanha
--   principal ou com conta orfa** · **zero `custo_por_conversao` nulo onde HA
--   conversao** -- a regra do NULL vale so onde deve · investimento BRL 647.380,10
--   e USD 9.480,00, os mesmos centavos da Trusted.
WITH base AS (
  SELECT
    t.id_conta,
    t.termo,
    t.mes_referencia,
    t.id_campanha,
    t.campanha,
    t.id_grupo_anuncio,
    t.tipo_correspondencia,
    t.status_termo,
    t.data,
    t.investimento,
    t.impressoes,
    t.cliques,
    t.interacoes,
    t.conversoes,
    t.todas_conversoes,
    t.valor_conversoes,
    t.valor_todas_conversoes
  FROM `vanguardamartech_trusted`.`trs_google_ads__termo_busca` t
),
-- REGRA 1 - agrega por campanha ANTES de escolher a principal. Escolher a campanha
-- da linha-dia de maior investimento daria outra coisa: a campanha de um dia, nao a
-- campanha que mais gastou no mes.
por_campanha AS (
  SELECT
    id_conta, termo, mes_referencia, id_campanha, campanha,
    SUM(investimento) AS investimento_campanha
  FROM base
  GROUP BY 1, 2, 3, 4, 5
),
campanha_principal AS (
  SELECT id_conta, termo, mes_referencia, id_campanha, campanha
  FROM (
    SELECT
      c.*,
      ROW_NUMBER() OVER (
        PARTITION BY c.id_conta, c.termo, c.mes_referencia
        ORDER BY c.investimento_campanha DESC, c.campanha
      ) AS rn
    FROM por_campanha c
  )
  WHERE rn = 1
),
agregado AS (
  SELECT
    b.id_conta,
    b.termo,
    b.mes_referencia,

    COUNT(DISTINCT b.id_campanha)                               AS qtd_campanhas,
    COUNT(DISTINCT b.id_grupo_anuncio)                          AS qtd_grupos_anuncio,
    COUNT(DISTINCT b.data)                                      AS dias_com_registro,
    MIN(b.data)                                                 AS primeiro_dia,
    MAX(b.data)                                                 AS ultimo_dia,

    -- REGRA 5 - correspondencia e status variam DENTRO do grao. Saem agregados.
    STRING_AGG(DISTINCT b.tipo_correspondencia, ' | '
               ORDER BY b.tipo_correspondencia)                 AS tipos_correspondencia,
    STRING_AGG(DISTINCT b.status_termo, ' | '
               ORDER BY b.status_termo)                         AS status_termos,
    LOGICAL_OR(STARTS_WITH(b.tipo_correspondencia, 'NEAR_'))    AS flag_tem_variante_proxima,
    LOGICAL_OR(b.tipo_correspondencia = 'BROAD')                AS flag_tem_ampla,
    LOGICAL_OR(b.status_termo IN ('EXCLUDED', 'ADDED_EXCLUDED')) AS flag_excluido_em_alguma_campanha,
    LOGICAL_OR(b.status_termo IN ('ADDED', 'ADDED_EXCLUDED'))   AS flag_virou_palavra_chave,

    SUM(b.investimento)                                         AS investimento,
    SUM(IF(STARTS_WITH(b.tipo_correspondencia, 'NEAR_'),
           b.investimento, 0))                                  AS investimento_variante_proxima,
    SUM(b.impressoes)                                           AS impressoes,
    SUM(b.cliques)                                              AS cliques,
    SUM(b.interacoes)                                           AS interacoes,
    SUM(b.conversoes)                                           AS conversoes,
    SUM(b.todas_conversoes)                                     AS todas_conversoes,
    SUM(b.valor_conversoes)                                     AS valor_conversoes,
    SUM(b.valor_todas_conversoes)                               AS valor_todas_conversoes
  FROM base b
  GROUP BY 1, 2, 3
)
SELECT
  CONCAT(a.id_conta, ':', a.mes_referencia_txt, ':', TO_HEX(MD5(a.termo))) AS id_termo_mensal,

  a.id_conta,
  -- A Trusted NAO carrega moeda; ela vem da dimensao, que resolve 40 de 40.
  d.conta,
  d.cliente,
  d.moeda,
  (d.id_conta IS NULL)                                          AS flag_conta_nao_catalogada,

  a.termo,
  LENGTH(a.termo)                                               AS qtd_caracteres_do_termo,
  a.mes_referencia,
  EXTRACT(YEAR  FROM a.mes_referencia)                          AS ano,
  EXTRACT(MONTH FROM a.mes_referencia)                          AS mes,

  a.qtd_campanhas,
  a.qtd_grupos_anuncio,
  cp.id_campanha                                                AS id_campanha_principal,
  cp.campanha                                                   AS campanha_principal,
  a.dias_com_registro,
  a.primeiro_dia,
  a.ultimo_dia,

  a.tipos_correspondencia,
  a.status_termos,
  a.flag_tem_variante_proxima,
  a.flag_tem_ampla,
  a.flag_excluido_em_alguma_campanha,
  a.flag_virou_palavra_chave,

  ROUND(a.investimento, 2)                                      AS investimento,
  ROUND(a.investimento_variante_proxima, 2)                     AS investimento_variante_proxima,
  a.impressoes,
  a.cliques,
  a.interacoes,
  a.conversoes,
  a.todas_conversoes,
  ROUND(a.valor_conversoes, 2)                                  AS valor_conversoes,
  ROUND(a.valor_todas_conversoes, 2)                            AS valor_todas_conversoes,

  -- REGRA 2 - metrica derivada e decisao de negocio, entao mora aqui.
  -- Sem denominador, sai NULL: zero seria somado, infinito nao existe.
  ROUND(SAFE_DIVIDE(a.investimento, NULLIF(a.cliques, 0)), 4)       AS custo_por_clique,
  ROUND(SAFE_DIVIDE(a.investimento, NULLIF(a.conversoes, 0)), 2)    AS custo_por_conversao,
  ROUND(SAFE_DIVIDE(a.conversoes, NULLIF(a.cliques, 0)), 6)         AS taxa_conversao,
  ROUND(SAFE_DIVIDE(a.cliques, NULLIF(a.impressoes, 0)), 6)         AS taxa_clique,
  ROUND(SAFE_DIVIDE(a.valor_conversoes, NULLIF(a.investimento, 0)), 4) AS retorno_sobre_investimento,

  (a.investimento > 0)                                          AS tem_investimento,
  (a.conversoes > 0)                                            AS tem_conversao,
  -- REGRA 3 - candidato a revisao, nunca veredicto.
  (a.investimento > 0 AND a.conversoes = 0)                     AS flag_gasta_sem_converter,
  -- REGRA 4 - a cauda fica, marcada.
  (a.impressoes > 0 AND a.cliques = 0)                          AS flag_so_impressao,

  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'trs_google_ads__termo_busca'                                 AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                                AS _payload_hash
FROM (SELECT ag.*, CAST(ag.mes_referencia AS STRING) AS mes_referencia_txt FROM agregado ag) a
LEFT JOIN campanha_principal cp
  ON  cp.id_conta       = a.id_conta
  AND cp.termo          = a.termo
  AND cp.mes_referencia = a.mes_referencia
LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__conta` d
  ON d.id_conta = a.id_conta
