-- rfn_social__produto_mensal  ·  Refined / social  ·  L2
-- Grao: uma CONTA, um MES, um PRODUTO do insight de conta (AD, POST, REEL, STORY,
-- CAROUSEL_CONTAINER). Chave: id_produto_mensal = <id_conta>:<aaaa-mm>:<produto>.
-- Origem: trs_instagram__insight_produto_dia. Gatilho: evento nessa Trusted.
-- DIFERENTE de rfn_social__midia_mensal: aqui o dado e da CONTA por produto e cobre TODOS os
-- posts vistos no dia (inclusive anuncio), nao so as midias extraidas. O vocabulario de
-- produto e outro (POST x FEED, REEL x REELS): as duas Refined nao se juntam por produto.
-- Regras numeradas, validacao e limitacoes: na descricao da transformacao.
--
-- R1 contagens somam; alcance NAO (media e maximo diarios) · R2 participacao nas
-- visualizacoes tem como denominador a soma dos produtos da conta no mes, que reproduz a
-- janela DIA da conta · R3 AD e o pago · R4 salvamentos pode ser negativo e passa.
WITH s AS (
  SELECT
    id_conta,
    DATE_TRUNC(data, MONTH)                                AS mes_referencia,
    produto,
    ANY_VALUE(is_anuncio)                                  AS is_anuncio,
    COUNT(DISTINCT data)                                   AS qtd_dias_com_linha,
    SUM(visualizacoes)                                     AS visualizacoes,
    SUM(interacoes_totais)                                 AS interacoes_totais,
    SUM(curtidas)                                          AS curtidas,
    SUM(comentarios)                                       AS comentarios,
    SUM(compartilhamentos)                                 AS compartilhamentos,
    SUM(salvamentos)                                       AS salvamentos,
    COUNTIF(flag_salvamentos_negativo)                     AS qtd_dias_salvamentos_negativo,
    ROUND(AVG(alcance), 1)                                 AS alcance_medio_diario,
    MAX(alcance)                                           AS alcance_maximo_diario
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_produto_dia`
  GROUP BY id_conta, mes_referencia, produto
)
SELECT
  CONCAT(s.id_conta, ':', FORMAT_DATE('%Y-%m', s.mes_referencia), ':', s.produto) AS id_produto_mensal,
  s.id_conta,
  c.usuario,
  s.mes_referencia,
  s.produto,
  s.is_anuncio,
  s.qtd_dias_com_linha,
  s.visualizacoes,
  s.interacoes_totais,
  s.curtidas,
  s.comentarios,
  s.compartilhamentos,
  s.salvamentos,
  s.qtd_dias_salvamentos_negativo,
  s.alcance_medio_diario,
  s.alcance_maximo_diario,
  ROUND(SAFE_DIVIDE(s.interacoes_totais, NULLIF(s.visualizacoes, 0)), 4) AS taxa_interacao_sobre_visualizacoes,
  -- R2 - participacao do produto nas visualizacoes da conta no mes.
  SUM(s.visualizacoes) OVER (PARTITION BY s.id_conta, s.mes_referencia) AS visualizacoes_da_conta_no_mes,
  ROUND(SAFE_DIVIDE(s.visualizacoes,
        NULLIF(SUM(s.visualizacoes) OVER (PARTITION BY s.id_conta, s.mes_referencia), 0)), 4)
                                                           AS participacao_nas_visualizacoes_da_conta,
  CURRENT_TIMESTAMP()                                      AS _extraido_at,
  'instagram'                                              AS _fonte,
  'America/Sao_Paulo'                                      AS _fuso
FROM s
LEFT JOIN `vanguardamartech_trusted`.`trs_instagram__conta` c ON c.id_conta = s.id_conta
