-- rfn_social__midia_mensal  ·  Refined / social  ·  L2
-- Grao: uma CONTA, um MES, um PRODUTO de midia (FEED, REELS, STORY).
-- Chave: id_midia_mensal = <id_conta>:<aaaa-mm>:<produto>.
-- Origem: trs_instagram__midia (L3). Gatilho: evento em trs_instagram__midia.
-- PROVA DE CLASSIFICACAO: a Trusted e L3 por `legenda`. Esta Refined NAO le `legenda`: so
-- as colunas derivadas (legenda_caracteres, qtd_hashtags), flags e metricas. Nenhum texto,
-- permalink, usuario de terceiro ou id de midia atravessa. Por isso L2.
-- Regras numeradas, validacao e limitacoes: na descricao da transformacao.
--
-- R1 alcance NAO e somado: media e maximo por midia · R2 taxa de interacao = soma das
-- interacoes / soma das visualizacoes, so sobre midias com insight · R3 curtida e
-- comentario de STORY sao NULL, nunca zero · R4 contagem e media sao da EXTRACAO, nao do
-- total de posts da conta.
SELECT
  CONCAT(id_conta, ':', FORMAT_DATE('%Y-%m', mes_referencia), ':', produto) AS id_midia_mensal,
  id_conta,
  ANY_VALUE(usuario)                                       AS usuario,
  mes_referencia,
  produto,

  COUNT(*)                                                 AS qtd_midias,
  COUNTIF(tem_insight)                                     AS qtd_midias_com_insight,
  COUNT(DISTINCT data_local)                               AS qtd_dias_com_publicacao,
  MIN(data_local)                                          AS primeira_publicacao_em,
  MAX(data_local)                                          AS ultima_publicacao_em,

  -- Aditivas (sobre as midias com insight).
  SUM(visualizacoes)                                       AS visualizacoes,
  SUM(interacoes_totais)                                   AS interacoes_totais,
  -- R3 - NULL quando o produto nao tem a metrica (SUM de tudo NULL = NULL).
  SUM(curtidas)                                            AS curtidas,
  SUM(comentarios)                                         AS comentarios,
  SUM(compartilhamentos)                                   AS compartilhamentos,
  SUM(salvamentos)                                         AS salvamentos,
  SUM(respostas)                                           AS respostas,
  SUM(seguimentos)                                         AS seguimentos,
  SUM(visitas_ao_perfil)                                   AS visitas_ao_perfil,

  -- R1 - alcance por midia: nunca somado.
  ROUND(AVG(alcance), 1)                                   AS alcance_medio_por_midia,
  MAX(alcance)                                             AS alcance_maximo_por_midia,
  ROUND(AVG(visualizacoes), 1)                             AS visualizacoes_medias_por_midia,

  -- R2 - denominador declarado: visualizacoes, ambas somadas sobre as mesmas midias.
  ROUND(SAFE_DIVIDE(SUM(interacoes_totais), NULLIF(SUM(visualizacoes), 0)), 4)
                                                           AS taxa_interacao_sobre_visualizacoes,

  -- Reels: tempo medio assistido (ms) so existe em reel; media simples das midias.
  ROUND(AVG(reels_tempo_medio_assistido_ms), 0)            AS reels_tempo_medio_assistido_ms,

  -- Derivadas da legenda (o texto NAO passa).
  ROUND(AVG(legenda_caracteres), 1)                        AS legenda_caracteres_media,
  ROUND(AVG(qtd_hashtags), 2)                              AS hashtags_media_por_midia,
  COUNTIF(legenda_caracteres = 0)                          AS qtd_sem_legenda,

  CURRENT_TIMESTAMP()                                      AS _extraido_at,
  'instagram'                                              AS _fonte,
  'America/Sao_Paulo'                                      AS _fuso
FROM `vanguardamartech_trusted`.`trs_instagram__midia`
GROUP BY id_conta, mes_referencia, produto
