-- rfn_midia__conta_estrutura (query-4JAW)
-- Refined / MIDIA. Grao: conta integrada. Origem: conta + campanha + grupo + anuncio + palavra_chave_cadastro + ativo + video + acao_conversao + orcamento_conta.
-- Regras numeradas, limitacoes e medicao: na descricao da transformacao na Nekt.
WITH campanhas AS (
  SELECT id_conta, COUNT(*) AS qtd_campanhas, COUNTIF(ativa) AS qtd_campanhas_ativas
  FROM `vanguardamartech_trusted`.`trs_google_ads__campanha`
  GROUP BY id_conta
),
grupos AS (
  SELECT id_conta, COUNT(*) AS qtd_grupos, COUNTIF(status = 'ENABLED') AS qtd_grupos_ativos
  FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio`
  GROUP BY id_conta
),
anuncios AS (
  SELECT id_conta,
    COUNT(*)                                                              AS qtd_anuncios,
    COUNTIF(status = 'ENABLED')                                           AS qtd_anuncios_ativos,
    COUNTIF(status = 'ENABLED' AND tipo = 'RESPONSIVE_SEARCH_AD')         AS qtd_anuncios_ativos_rsa,
    COUNTIF(status = 'ENABLED' AND forca_anuncio = 'POOR')                AS qtd_anuncios_ativos_forca_ruim,
    COUNTIF(status = 'ENABLED' AND tipo = 'RESPONSIVE_SEARCH_AD' AND forca_anuncio IN ('GOOD', 'EXCELLENT')) AS qtd_rsa_ativos_forca_boa
  FROM `vanguardamartech_trusted`.`trs_google_ads__anuncio`
  GROUP BY id_conta
),
palavras AS (
  SELECT id_conta,
    COUNTIF(NOT is_negativa AND status = 'ENABLED')                       AS qtd_palavras_ativas,
    COUNTIF(is_negativa AND status = 'ENABLED')                           AS qtd_negativas_ativas,
    COUNTIF(NOT is_negativa AND status = 'ENABLED' AND nivel_qualidade IS NOT NULL) AS qtd_palavras_ativas_com_nota,
    COUNTIF(NOT is_negativa AND status = 'ENABLED' AND nivel_qualidade <= 4)        AS qtd_palavras_ativas_nota_baixa
  FROM `vanguardamartech_trusted`.`trs_google_ads__palavra_chave_cadastro`
  GROUP BY id_conta
),
ativos AS (
  SELECT id_conta,
    COUNT(*)                          AS qtd_ativos,
    COUNTIF(tipo = 'SITELINK')        AS qtd_ativos_sitelink,
    COUNTIF(tipo = 'CALLOUT')         AS qtd_ativos_callout,
    COUNTIF(tipo = 'STRUCTURED_SNIPPET') AS qtd_ativos_snippet,
    COUNTIF(tipo = 'CALL')            AS qtd_ativos_chamada,
    COUNTIF(tipo = 'IMAGE')           AS qtd_ativos_imagem,
    COUNTIF(tipo IN ('YOUTUBE_VIDEO', 'YOUTUBE_VIDEO_LIST')) AS qtd_ativos_video
  FROM `vanguardamartech_trusted`.`trs_google_ads__ativo`
  GROUP BY id_conta
),
videos AS (
  SELECT id_conta, COUNT(*) AS qtd_videos_cadastrados
  FROM `vanguardamartech_trusted`.`trs_google_ads__video`
  GROUP BY id_conta
),
acoes AS (
  SELECT id_conta,
    COUNTIF(status = 'ENABLED')                                           AS qtd_acoes_conversao_ativas,
    COUNTIF(status = 'ENABLED' AND is_primaria_para_meta)                 AS qtd_acoes_conversao_primarias,
    COUNT(DISTINCT IF(status = 'ENABLED', categoria, NULL))               AS qtd_categorias_conversao_ativas
  FROM `vanguardamartech_trusted`.`trs_google_ads__acao_conversao`
  GROUP BY id_conta
),
orc AS (
  SELECT id_conta,
    COUNT(*)                                                              AS qtd_orcamentos,
    ARRAY_AGG(STRUCT(limite_aprovado_micros, tipo_limite_aprovado, limite_ajustado_micros, valor_servido_micros, aprovado_inicio, aprovado_fim)
              ORDER BY aprovado_inicio DESC LIMIT 1)[SAFE_OFFSET(0)]      AS u
  FROM `vanguardamartech_trusted`.`trs_google_ads__orcamento_conta`
  GROUP BY id_conta
)
SELECT
  k.id_conta, k.conta, k.cliente, k.moeda, k.fonte_nekt,
  c.qtd_campanhas, c.qtd_campanhas_ativas,
  g.qtd_grupos, g.qtd_grupos_ativos,
  a.qtd_anuncios, a.qtd_anuncios_ativos, a.qtd_anuncios_ativos_rsa, a.qtd_rsa_ativos_forca_boa, a.qtd_anuncios_ativos_forca_ruim,
  p.qtd_palavras_ativas, p.qtd_negativas_ativas, p.qtd_palavras_ativas_com_nota, p.qtd_palavras_ativas_nota_baixa,
  t.qtd_ativos, t.qtd_ativos_sitelink, t.qtd_ativos_callout, t.qtd_ativos_snippet, t.qtd_ativos_chamada, t.qtd_ativos_imagem, t.qtd_ativos_video,
  v.qtd_videos_cadastrados,
  ac.qtd_acoes_conversao_ativas, ac.qtd_acoes_conversao_primarias, ac.qtd_categorias_conversao_ativas,
  o.qtd_orcamentos,
  o.u.limite_aprovado_micros                 AS orcamento_limite_aprovado_micros,
  o.u.tipo_limite_aprovado                   AS orcamento_tipo_limite,
  o.u.limite_ajustado_micros                 AS orcamento_limite_ajustado_micros,
  o.u.valor_servido_micros                   AS orcamento_valor_servido_micros,
  o.u.aprovado_inicio                        AS orcamento_inicio,
  o.u.aprovado_fim                           AS orcamento_fim,
  (IFNULL(p.qtd_palavras_ativas, 0) > 0 AND IFNULL(p.qtd_negativas_ativas, 0) = 0)  AS flag_busca_sem_palavra_negativa,
  (IFNULL(c.qtd_campanhas_ativas, 0) > 0 AND IFNULL(t.qtd_ativos_sitelink, 0) = 0)  AS flag_ativa_sem_sitelink,
  (IFNULL(c.qtd_campanhas_ativas, 0) > 0 AND IFNULL(ac.qtd_acoes_conversao_ativas, 0) = 0) AS flag_ativa_sem_acao_de_conversao,
  (IFNULL(c.qtd_campanhas_ativas, 0) > 0 AND IFNULL(ac.qtd_acoes_conversao_primarias, 0) = 0) AS flag_ativa_sem_acao_primaria,
  (o.u.aprovado_fim IS NOT NULL)             AS flag_orcamento_com_data_de_fim,
  (c.id_conta IS NULL)                       AS flag_sem_campanha_no_trusted,
  CURRENT_TIMESTAMP()                        AS _extraido_at
FROM `vanguardamartech_trusted`.`trs_google_ads__conta` k
LEFT JOIN campanhas c USING (id_conta)
LEFT JOIN grupos g USING (id_conta)
LEFT JOIN anuncios a USING (id_conta)
LEFT JOIN palavras p USING (id_conta)
LEFT JOIN ativos t USING (id_conta)
LEFT JOIN videos v USING (id_conta)
LEFT JOIN acoes ac USING (id_conta)
LEFT JOIN orc o USING (id_conta)
WHERE k.integrada_na_nekt
