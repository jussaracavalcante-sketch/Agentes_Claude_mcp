-- rfn_social__conta_mensal  ·  Refined / social  ·  L2
-- Grao: uma CONTA Instagram em um MES. Chave: id_conta_mes = <id_conta>:<aaaa-mm>.
-- Origem: trs_instagram__insight_conta (janela DIA), trs_instagram__midia (so as flags e a
-- contagem; `legenda` NAO e lida), trs_instagram__seguidores_dia, trs_instagram__conta.
-- Gatilho: evento (regra all) nas quatro.
-- As regras numeradas, os numeros da validacao e as limitacoes estao na descricao da
-- transformacao, que e parte da entrega.
--
-- R1 so a janela DIA e aditiva entre dias · R2 alcance NAO e somado: so media e maximo dos
-- alcances diarios · R3 taxa de interacao = interacoes / visualizacoes, ambas somadas nos
-- mesmos dias · R4 movimento de seguidores exclui os dias sem movimento reportado ·
-- R5 mes parcial e cobertura de dias declarados em toda linha · R7 seguidores vem da serie
-- (trs_instagram__seguidores_dia), com a variacao no mes so quando ha dois pontos.
WITH d AS (
  SELECT
    id_conta,
    DATE_TRUNC(data_fim_janela, MONTH)                         AS mes_referencia,
    COUNT(DISTINCT data_fim_janela)                            AS qtd_dias_com_dado,
    COUNTIF(flag_sem_movimento_de_seguidores)                  AS qtd_dias_sem_movimento_de_seguidores,
    SUM(visualizacoes)                                         AS visualizacoes,
    SUM(interacoes_totais)                                     AS interacoes_totais,
    SUM(curtidas)                                              AS curtidas,
    SUM(compartilhamentos)                                     AS compartilhamentos,
    SUM(respostas)                                             AS respostas,
    SUM(visitas_ao_perfil)                                     AS visitas_ao_perfil,
    SUM(cliques_no_site)                                       AS cliques_no_site,
    SUM(toques_em_links_do_perfil)                             AS toques_em_links_do_perfil,
    SUM(IF(flag_sem_movimento_de_seguidores, NULL, seguimentos))          AS seguimentos,
    SUM(IF(flag_sem_movimento_de_seguidores, NULL, deixaram_de_seguir))   AS deixaram_de_seguir,
    SUM(IF(flag_sem_movimento_de_seguidores, NULL, seguimentos_liquidos)) AS seguimentos_liquidos,
    ROUND(AVG(alcance), 1)                                     AS alcance_medio_diario,
    MAX(alcance)                                               AS alcance_maximo_diario,
    ROUND(AVG(contas_engajadas), 1)                            AS contas_engajadas_media_diaria
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta`
  WHERE janela = 'DIA'
  GROUP BY id_conta, mes_referencia
),
j28 AS (
  SELECT
    id_conta,
    DATE_TRUNC(data_fim_janela, MONTH)                         AS mes_referencia,
    ARRAY_AGG(STRUCT(data_fim_janela AS data, alcance AS alcance)
              ORDER BY data_fim_janela DESC LIMIT 1)[OFFSET(0)] AS ultima
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta`
  WHERE janela = '28_DIAS'
  GROUP BY id_conta, mes_referencia
),
m AS (
  SELECT
    id_conta,
    mes_referencia,
    COUNT(*)                                                   AS qtd_midias_extraidas,
    COUNTIF(is_feed)                                           AS qtd_feed_extraidos,
    COUNTIF(is_reel)                                           AS qtd_reels_extraidos,
    COUNTIF(is_story)                                          AS qtd_stories_extraidos
  FROM `vanguardamartech_trusted`.`trs_instagram__midia`
  GROUP BY id_conta, mes_referencia
),
sg AS (
  SELECT
    id_conta,
    DATE_TRUNC(data, MONTH)                                    AS mes_referencia,
    COUNT(*)                                                   AS qtd_pontos_de_seguidores_no_mes,
    ARRAY_AGG(STRUCT(data AS data, seguidores AS seguidores)
              ORDER BY data DESC LIMIT 1)[OFFSET(0)]           AS ultimo,
    ARRAY_AGG(STRUCT(data AS data, seguidores AS seguidores)
              ORDER BY data ASC LIMIT 1)[OFFSET(0)]            AS primeiro
  FROM `vanguardamartech_trusted`.`trs_instagram__seguidores_dia`
  GROUP BY id_conta, mes_referencia
),
base AS (
  SELECT
    id_conta,
    mes_referencia,
    d.qtd_dias_com_dado, d.qtd_dias_sem_movimento_de_seguidores,
    d.visualizacoes, d.interacoes_totais, d.curtidas, d.compartilhamentos, d.respostas,
    d.visitas_ao_perfil, d.cliques_no_site, d.toques_em_links_do_perfil,
    d.seguimentos, d.deixaram_de_seguir, d.seguimentos_liquidos,
    d.alcance_medio_diario, d.alcance_maximo_diario, d.contas_engajadas_media_diaria,
    m.qtd_midias_extraidas, m.qtd_feed_extraidos, m.qtd_reels_extraidos, m.qtd_stories_extraidos,
    sg.qtd_pontos_de_seguidores_no_mes, sg.ultimo, sg.primeiro
  FROM d
  FULL OUTER JOIN m USING (id_conta, mes_referencia)
  FULL OUTER JOIN sg USING (id_conta, mes_referencia)
)
SELECT
  CONCAT(b.id_conta, ':', FORMAT_DATE('%Y-%m', b.mes_referencia)) AS id_conta_mes,
  b.id_conta,
  c.usuario,
  b.mes_referencia,

  -- R5 - cobertura de dias e mes parcial, em toda linha.
  IFNULL(b.qtd_dias_com_dado, 0)                               AS qtd_dias_com_dado,
  EXTRACT(DAY FROM LAST_DAY(b.mes_referencia))                 AS qtd_dias_no_mes,
  ROUND(SAFE_DIVIDE(IFNULL(b.qtd_dias_com_dado, 0),
                    EXTRACT(DAY FROM LAST_DAY(b.mes_referencia))), 4) AS cobertura_dias_no_mes,
  (IFNULL(b.qtd_dias_com_dado, 0) < EXTRACT(DAY FROM LAST_DAY(b.mes_referencia))) AS flag_mes_parcial,

  -- R1 - contagens aditivas, somadas so sobre a janela DIA.
  b.visualizacoes,
  b.interacoes_totais,
  b.curtidas,
  b.compartilhamentos,
  b.respostas,
  b.visitas_ao_perfil,
  b.cliques_no_site,
  b.toques_em_links_do_perfil,

  -- R3 - o denominador e a visualizacao, somada nos MESMOS dias que as interacoes.
  ROUND(SAFE_DIVIDE(b.interacoes_totais, NULLIF(b.visualizacoes, 0)), 4) AS taxa_interacao_sobre_visualizacoes,

  -- R2 - alcance NAO se soma: media e maximo dos alcances diarios, e a janela de 28 dias
  -- do ultimo dia com dado (um instante, nao uma soma).
  b.alcance_medio_diario,
  b.alcance_maximo_diario,
  b.contas_engajadas_media_diaria,
  j.ultima.alcance                                             AS alcance_28_dias_no_ultimo_dia,
  j.ultima.data                                                AS data_do_alcance_28_dias,

  -- R4 - seguidores: dias sem movimento reportado ficam FORA da soma (NULL, nao zero).
  b.seguimentos,
  b.deixaram_de_seguir,
  b.seguimentos_liquidos,
  IFNULL(b.qtd_dias_sem_movimento_de_seguidores, 0)            AS qtd_dias_sem_movimento_de_seguidores,
  (IFNULL(b.qtd_dias_com_dado, 0) - IFNULL(b.qtd_dias_sem_movimento_de_seguidores, 0))
                                                               AS qtd_dias_com_movimento_de_seguidores,

  -- Contexto da extracao de midia no mes. NAO e o total de posts do mes na conta.
  IFNULL(b.qtd_midias_extraidas, 0)                            AS qtd_midias_extraidas,
  IFNULL(b.qtd_feed_extraidos, 0)                              AS qtd_feed_extraidos,
  IFNULL(b.qtd_reels_extraidos, 0)                             AS qtd_reels_extraidos,
  IFNULL(b.qtd_stories_extraidos, 0)                           AS qtd_stories_extraidos,

  -- R7 - seguidores: ultimo ponto da serie no mes (estoque, nao soma) e a variacao no mes
  -- (NULL com menos de dois pontos: um ponto so nao mede variacao).
  b.ultimo.seguidores                                          AS seguidores_no_ultimo_ponto_do_mes,
  b.ultimo.data                                                AS data_do_ultimo_ponto_de_seguidores,
  IFNULL(b.qtd_pontos_de_seguidores_no_mes, 0)                 AS qtd_pontos_de_seguidores_no_mes,
  IF(b.qtd_pontos_de_seguidores_no_mes >= 2,
     b.ultimo.seguidores - b.primeiro.seguidores, NULL)        AS variacao_de_seguidores_no_mes,

  CURRENT_TIMESTAMP()                                          AS _extraido_at,
  'instagram'                                                  AS _fonte,
  'America/Sao_Paulo'                                          AS _fuso
FROM base b
LEFT JOIN j28 j ON j.id_conta = b.id_conta AND j.mes_referencia = b.mes_referencia
LEFT JOIN `vanguardamartech_trusted`.`trs_instagram__conta` c ON c.id_conta = b.id_conta
