-- Refined / dominio Midia - rfn_midia__desempenho_diario
-- Grao: uma linha por (plataforma, id_conta, id_campanha, data). Chave id_desempenho.
--
-- DUAS PLATAFORMAS:
--   GOOGLE_ADS   <- trs_google_ads__insight_diario + __campanha + __conta   (Trusted)
--   FACEBOOK_ADS <- trs_facebook_ads__insight_diario + __campanha + __conta (Trusted Facebook Ads)
--
-- Toda coluna que so uma das plataformas tem sai NULL na outra, de proposito.
-- Nada e preenchido por analogia: a ausencia e informacao.
--
-- CADENCIA SEMANAL: desde 2026-09-04 as fontes de Google Ads e de Facebook Ads
-- rodam as tercas-feiras, nao mais diariamente. Por isso o limiar de
-- conta_defasada e > 9 dias e nao > 2: com carga na terca, o dado de uma
-- segunda fica legitimamente 8 dias sem atualizacao ate a terca seguinte.
-- Limiar menor acusaria operacao normal; maior deixaria de pegar fonte parada.
WITH

-- ============================ GOOGLE ADS ============================
fato_g AS (
  SELECT
    id_conta,
    id_campanha,
    data,
    -- MAX para ser deterministico quando as linhas de anuncio do mesmo par
    -- (campanha, dia) divergem no rotulo.
    MAX(campanha)                                                      AS campanha_no_dia,
    MAX(status_campanha)                                               AS status_campanha_no_dia,
    MAX(moeda)                                                         AS moeda_no_fato,
    -- ANUNCIO  = o Google publicou desempenho por anuncio naquele dia.
    -- CAMPANHA = nao publicou (PERFORMANCE_MAX) e a linha e o residuo de campanha.
    -- MISTO    = nao deve existir: a ausencia e sempre por campanha-dia inteiro
    --            (verificado nas 39 contas em 01/09/2026, zero pares parciais).
    IF(COUNT(DISTINCT grao) > 1, 'MISTO', MAX(grao))                   AS grao_origem,
    COUNT(DISTINCT id_anuncio)                                         AS qtd_anuncios,
    SUM(investimento_micros)                                           AS investimento_micros,
    SUM(impressoes)                                                    AS impressoes,
    SUM(cliques)                                                       AS cliques,
    SUM(interacoes)                                                    AS interacoes,
    SUM(conversoes)                                                    AS conversoes,
    SUM(todas_conversoes)                                              AS todas_conversoes,
    SUM(valor_conversoes)                                              AS valor_conversoes,
    SUM(valor_todas_conversoes)                                        AS valor_todas_conversoes,
    SUM(conversoes_view_through)                                       AS conversoes_view_through,
    SUM(visualizacoes_video)                                           AS visualizacoes_video,
    MAX(_extraido_at)                                                  AS _extraido_at,
    MAX(_fonte)                                                        AS _fonte
  FROM `vanguardamartech_trusted`.`trs_google_ads__insight_diario`
  GROUP BY id_conta, id_campanha, data
),

-- Frescor por conta, calculado AQUI e igual para as duas plataformas.
-- Usa a ultima data COM ENTREGA, nao MAX(data): dia sem entrega nao e sinal de
-- vida. Existe porque fonte parada nao falha nem alerta - a tabela so devolve
-- dado velho com cara de dado bom.
frescor_g AS (
  SELECT
    id_conta,
    MAX(IF(investimento_micros > 0 OR impressoes > 0, data, NULL))      AS ultima_data_com_entrega
  FROM fato_g
  GROUP BY id_conta
),

google AS (
  SELECT
    CONCAT(f.id_conta, '|', CAST(f.id_campanha AS STRING), '|',
           FORMAT_DATE('%Y%m%d', f.data))                              AS id_desempenho,

    'GOOGLE_ADS'                                                       AS plataforma,
    f.id_conta,
    a.conta                                                            AS conta_na_plataforma,
    a.cliente,
    COALESCE(a.moeda, f.moeda_no_fato)                                 AS moeda,
    a.rotulo_customizado,
    a.rotulo_diverge_da_plataforma,

    f.data,
    DATE_TRUNC(f.data, MONTH)                                          AS mes_referencia,

    f.id_campanha,
    COALESCE(c.campanha, f.campanha_no_dia)                            AS campanha,
    f.campanha_no_dia,
    c.canal,
    c.subcanal,
    c.estrategia_lance,
    c.status                                                           AS status_campanha_atual,
    f.status_campanha_no_dia,
    c.ativa                                                            AS campanha_ativa,
    c.data_inicio                                                      AS campanha_data_inicio,
    c.data_fim                                                         AS campanha_data_fim,

    f.investimento_micros,
    ROUND(f.investimento_micros / 1000000, 2)                          AS investimento,
    f.impressoes,
    f.cliques,
    f.interacoes,
    f.conversoes,
    f.todas_conversoes,
    f.valor_conversoes,
    f.valor_todas_conversoes,
    f.conversoes_view_through,
    f.visualizacoes_video,

    ROUND(SAFE_DIVIDE(f.cliques,     f.impressoes) * 100, 2)           AS ctr_pct,
    ROUND(SAFE_DIVIDE(f.interacoes,  f.impressoes) * 100, 2)           AS taxa_interacao_pct,
    ROUND(SAFE_DIVIDE(f.conversoes,  f.interacoes) * 100, 2)           AS taxa_conversao_pct,
    ROUND(SAFE_DIVIDE(f.investimento_micros / 1000000, f.cliques),    2) AS cpc,
    ROUND(SAFE_DIVIDE(f.investimento_micros / 1000000, f.impressoes) * 1000, 2) AS cpm,
    ROUND(SAFE_DIVIDE(f.investimento_micros / 1000000, f.conversoes), 2) AS cpa,
    ROUND(SAFE_DIVIDE(f.valor_conversoes, f.investimento_micros / 1000000), 2) AS roas,

    c.orcamento_diario,
    c.orcamento_compartilhado,
    IF(c.orcamento_compartilhado IS TRUE, NULL,
       ROUND(SAFE_DIVIDE(f.investimento_micros, c.orcamento_diario_micros) * 100, 1)
    )                                                                  AS consumo_orcamento_diario_pct,

    f.grao_origem,
    f.qtd_anuncios,
    f.grao_origem = 'CAMPANHA'                                         AS sem_detalhe_por_anuncio,
    f.impressoes = 0                                                   AS sem_entrega,
    c.id_campanha IS NULL                                              AS flag_campanha_nao_catalogada,
    a.id_conta   IS NULL                                               AS flag_conta_nao_catalogada,
    COALESCE(a.moeda <> f.moeda_no_fato, FALSE)                        AS flag_moeda_divergente,
    f.grao_origem = 'MISTO'                                            AS flag_grao_misto,
    NOT (c.id_campanha IS NULL
         OR a.id_conta IS NULL
         OR COALESCE(a.moeda <> f.moeda_no_fato, FALSE)
         OR f.grao_origem = 'MISTO')                                   AS registro_confiavel,

    f._extraido_at,
    f._fonte,

    -- ---------- colunas so do Facebook: NULL aqui, de proposito ----------
    CAST(NULL AS STRING)                                               AS objetivo,
    CAST(NULL AS STRING)                                               AS objetivo_canonico,
    CAST(NULL AS STRING)                                               AS geracao_objetivo,
    CAST(NULL AS BOOL)                                                 AS objetivo_eh_mensagem,
    CAST(NULL AS FLOAT64)                                              AS conversoes_leads,
    CAST(NULL AS FLOAT64)                                              AS conversoes_compras,
    CAST(NULL AS FLOAT64)                                              AS conversoes_conversas,
    CAST(NULL AS STRING)                                               AS fuso_conta,

    -- ---------- frescor: nas duas plataformas ----------
    fr.ultima_data_com_entrega,
    DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), fr.ultima_data_com_entrega, DAY)       AS dias_sem_entrega,
    (DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), fr.ultima_data_com_entrega, DAY) > 9) AS conta_defasada,
    FALSE                                                              AS dimensao_conta_congelada
  FROM fato_g f
  LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__campanha` c
    ON  c.id_conta    = f.id_conta
    AND c.id_campanha = f.id_campanha
  LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__conta`    a
    ON  a.id_conta    = f.id_conta
  LEFT JOIN frescor_g fr
    ON  fr.id_conta   = f.id_conta
),

-- =========================== FACEBOOK ADS ===========================
fato_f AS (
  SELECT
    id_conta,
    id_campanha,
    data,
    MAX(campanha)                                                      AS campanha_no_dia,
    COUNT(DISTINCT id_anuncio)                                         AS qtd_anuncios,
    -- O Facebook entrega spend em unidade de moeda com 2 decimais, nao em
    -- micros. A multiplicacao por 1e6 e conversao exata de unidade, nao
    -- precisao inventada, e existe para a coluna somar igual a do Google.
    CAST(ROUND(SUM(investimento) * 1000000) AS INT64)                  AS investimento_micros,
    SUM(impressoes)                                                    AS impressoes,
    SUM(cliques)                                                       AS cliques,
    -- REGRA 8: conversao no Facebook = soma das acoes comerciais.
    SUM(COALESCE(leads, 0))                                            AS conversoes_leads,
    SUM(COALESCE(compras, 0))                                          AS conversoes_compras,
    SUM(COALESCE(conversas_iniciadas_7d, 0))                           AS conversoes_conversas,
    SUM(COALESCE(leads, 0) + COALESCE(compras, 0)
        + COALESCE(conversas_iniciadas_7d, 0))                         AS conversoes,
    SUM(COALESCE(receita_compras, 0))                                  AS valor_conversoes,
    SUM(COALESCE(visualizacoes_video, 0))                              AS visualizacoes_video,
    MAX(_extraido_at)                                                  AS _extraido_at,
    MAX(_fonte)                                                        AS _fonte
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__insight_diario`
  GROUP BY id_conta, id_campanha, data
),

frescor_f AS (
  SELECT
    id_conta,
    MAX(IF(investimento_micros > 0 OR impressoes > 0, data, NULL))      AS ultima_data_com_entrega
  FROM fato_f
  GROUP BY id_conta
),

facebook AS (
  SELECT
    -- Mesma forma da chave do Google. Verificado em 2026-09-04: zero id_conta
    -- em comum entre as plataformas e os ids tem tamanhos estruturalmente
    -- diferentes (Google 10 digitos, Facebook 15 a 17), entao nao colide.
    CONCAT(f.id_conta, '|', CAST(f.id_campanha AS STRING), '|',
           FORMAT_DATE('%Y%m%d', f.data))                              AS id_desempenho,

    'FACEBOOK_ADS'                                                     AS plataforma,
    f.id_conta,
    a.conta                                                            AS conta_na_plataforma,
    a.cliente,
    a.moeda,
    -- Nao existe rotulo curado da Vanguarda para o Facebook, ao contrario do
    -- Google Ads. Sem rotulo nao ha divergencia a apontar.
    CAST(NULL AS BOOL)                                                 AS rotulo_customizado,
    CAST(NULL AS BOOL)                                                 AS rotulo_diverge_da_plataforma,

    f.data,
    DATE_TRUNC(f.data, MONTH)                                          AS mes_referencia,

    f.id_campanha,
    COALESCE(c.campanha, f.campanha_no_dia)                            AS campanha,
    f.campanha_no_dia,
    -- canal/subcanal sao do Google (advertising_channel_type). O equivalente
    -- do Facebook e o objetivo, que sai nas colunas objetivo* abaixo.
    CAST(NULL AS STRING)                                               AS canal,
    CAST(NULL AS STRING)                                               AS subcanal,
    c.estrategia_lance,
    c.status_efetivo                                                   AS status_campanha_atual,
    -- O insight do Facebook nao carrega status por dia, so o atual.
    CAST(NULL AS STRING)                                               AS status_campanha_no_dia,
    c.ativa                                                            AS campanha_ativa,
    c.data_inicio                                                      AS campanha_data_inicio,
    c.data_fim                                                         AS campanha_data_fim,

    f.investimento_micros,
    ROUND(f.investimento_micros / 1000000, 2)                          AS investimento,
    f.impressoes,
    f.cliques,
    -- interacoes e conceito do Google (interactions). Sem equivalente fiel.
    CAST(NULL AS INT64)                                                AS interacoes,
    f.conversoes,
    -- todas_conversoes e conversoes_view_through sao conceitos do Google.
    CAST(NULL AS FLOAT64)                                              AS todas_conversoes,
    f.valor_conversoes,
    CAST(NULL AS FLOAT64)                                              AS valor_todas_conversoes,
    CAST(NULL AS FLOAT64)                                              AS conversoes_view_through,
    f.visualizacoes_video,

    ROUND(SAFE_DIVIDE(f.cliques, f.impressoes) * 100, 2)               AS ctr_pct,
    -- sem interacoes nao ha taxa de interacao
    CAST(NULL AS FLOAT64)                                              AS taxa_interacao_pct,
    -- no Facebook a base da taxa e clique, nao interacao
    ROUND(SAFE_DIVIDE(f.conversoes, f.cliques) * 100, 2)               AS taxa_conversao_pct,
    ROUND(SAFE_DIVIDE(f.investimento_micros / 1000000, f.cliques),    2) AS cpc,
    ROUND(SAFE_DIVIDE(f.investimento_micros / 1000000, f.impressoes) * 1000, 2) AS cpm,
    ROUND(SAFE_DIVIDE(f.investimento_micros / 1000000, f.conversoes), 2) AS cpa,
    ROUND(SAFE_DIVIDE(f.valor_conversoes, f.investimento_micros / 1000000), 2) AS roas,

    -- ORCAMENTO FICA NULL DE PROPOSITO. A unidade do orcamento do Facebook nao
    -- esta verificada (ver trs_facebook_ads__campanha) - dividir por 100 sem
    -- prova produziria um numero errado com cara de certo.
    CAST(NULL AS FLOAT64)                                              AS orcamento_diario,
    CAST(NULL AS BOOL)                                                 AS orcamento_compartilhado,
    CAST(NULL AS FLOAT64)                                              AS consumo_orcamento_diario_pct,

    -- O Facebook publica desempenho por anuncio sempre: nao ha o problema de
    -- grao misto que o PERFORMANCE_MAX cria no Google.
    'ANUNCIO'                                                          AS grao_origem,
    f.qtd_anuncios,
    FALSE                                                              AS sem_detalhe_por_anuncio,
    f.impressoes = 0                                                   AS sem_entrega,
    c.id_campanha IS NULL                                              AS flag_campanha_nao_catalogada,
    a.id_conta   IS NULL                                               AS flag_conta_nao_catalogada,
    -- o insight do Facebook nao carrega moeda, entao nao ha o que divergir
    FALSE                                                              AS flag_moeda_divergente,
    FALSE                                                              AS flag_grao_misto,
    NOT (c.id_campanha IS NULL OR a.id_conta IS NULL)                  AS registro_confiavel,

    f._extraido_at,
    f._fonte,

    c.objetivo,
    c.objetivo_canonico,
    c.geracao_objetivo,
    c.objetivo_eh_mensagem,
    f.conversoes_leads,
    f.conversoes_compras,
    f.conversoes_conversas,
    -- O date_start do Facebook vem NO FUSO DA CONTA. As 7 contas vivas estao em
    -- 4 fusos, entao "dia" nao significa exatamente a mesma coisa entre elas.
    a.fuso_conta,

    fr.ultima_data_com_entrega,
    DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), fr.ultima_data_com_entrega, DAY)       AS dias_sem_entrega,
    (DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), fr.ultima_data_com_entrega, DAY) > 9) AS conta_defasada,
    -- A dimensao de conta do Facebook e um snapshot de 26/08/2026 de fonte
    -- excluida. TRUE aqui e aviso permanente, nao alerta.
    a.dimensao_congelada                                               AS dimensao_conta_congelada
  FROM fato_f f
  LEFT JOIN `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__campanha` c
    ON  c.id_campanha = f.id_campanha
  LEFT JOIN `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conta`    a
    ON  a.id_conta    = f.id_conta
  LEFT JOIN frescor_f fr
    ON  fr.id_conta   = f.id_conta
)

SELECT * FROM google
UNION ALL
SELECT * FROM facebook
