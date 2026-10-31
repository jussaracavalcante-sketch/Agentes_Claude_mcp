-- rfn_midia__grupo_anuncio_mensal (query-Qepg)
-- Refined / MIDIA. Grao: conta, campanha, grupo, mes. Origem: grupo_anuncio_diario + grupo_anuncio + palavra_chave_cadastro + anuncio + conta.
-- Regras numeradas, limitacoes e medicao: na descricao da transformacao na Nekt.
WITH diario AS (
  SELECT
    id_conta, id_campanha, id_grupo_anuncio,
    DATE_TRUNC(data, MONTH)                                    AS mes_referencia,
    ARRAY_AGG(campanha ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)]       AS campanha,
    ARRAY_AGG(grupo_anuncio ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)]  AS grupo_anuncio,
    COUNT(DISTINCT data)                                       AS dias_com_linha,
    COUNT(DISTINCT IF(investimento_micros > 0, data, NULL))    AS dias_com_investimento,
    SUM(investimento_micros)                                   AS investimento_micros,
    SUM(impressoes)                                            AS impressoes,
    SUM(cliques)                                               AS cliques,
    SUM(interacoes)                                            AS interacoes,
    SUM(conversoes)                                            AS conversoes,
    SUM(todas_conversoes)                                      AS todas_conversoes,
    SUM(valor_conversoes)                                      AS valor_conversoes,
    SUM(valor_todas_conversoes)                                AS valor_todas_conversoes,
    SUM(visualizacoes_video)                                   AS visualizacoes_video,
    SUM(engajamentos)                                          AS engajamentos,
    SAFE_DIVIDE(SUM(IF(pct_impressao_topo_plataforma IS NOT NULL, pct_impressao_topo_plataforma * impressoes, 0)),
                SUM(IF(pct_impressao_topo_plataforma IS NOT NULL, impressoes, 0)))   AS pct_impressao_topo,
    MAX(_extraido_at)                                          AS _extraido_trusted
  FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio_diario`
  GROUP BY id_conta, id_campanha, id_grupo_anuncio, mes_referencia
),
palavras AS (
  SELECT id_conta, id_grupo_anuncio,
    COUNTIF(NOT is_negativa AND status = 'ENABLED')  AS qtd_palavras_ativas,
    COUNTIF(is_negativa AND status = 'ENABLED')      AS qtd_negativas_ativas
  FROM `vanguardamartech_trusted`.`trs_google_ads__palavra_chave_cadastro`
  GROUP BY id_conta, id_grupo_anuncio
),
anuncios AS (
  SELECT id_conta, id_grupo_anuncio,
    COUNTIF(status = 'ENABLED')                           AS qtd_anuncios_ativos,
    COUNTIF(status = 'ENABLED' AND forca_anuncio = 'POOR') AS qtd_anuncios_ativos_forca_ruim
  FROM `vanguardamartech_trusted`.`trs_google_ads__anuncio`
  GROUP BY id_conta, id_grupo_anuncio
),
com_dim AS (
  SELECT
    d.*,
    g.status                                     AS status_grupo_atual,
    g.tipo                                       AS tipo_grupo,
    g.lance_cpc_micros                           AS lance_cpc_atual_micros,
    g.meta_cpa_micros                            AS meta_cpa_micros,
    g.is_segmentacao_otimizada,
    (g.id_grupo_anuncio IS NULL)                 AS flag_grupo_nao_catalogado,
    p.qtd_palavras_ativas, p.qtd_negativas_ativas,
    a.qtd_anuncios_ativos, a.qtd_anuncios_ativos_forca_ruim,
    k.cliente, k.moeda,
    (k.id_conta IS NULL)                         AS flag_conta_nao_catalogada
  FROM diario d
  LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio` g
    ON g.id_conta = d.id_conta AND g.id_grupo_anuncio = d.id_grupo_anuncio
  LEFT JOIN palavras p ON p.id_conta = d.id_conta AND p.id_grupo_anuncio = d.id_grupo_anuncio
  LEFT JOIN anuncios a ON a.id_conta = d.id_conta AND a.id_grupo_anuncio = d.id_grupo_anuncio
  LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__conta` k ON k.id_conta = d.id_conta
)
SELECT
  CONCAT(id_conta, '|', id_campanha, '|', id_grupo_anuncio, '|', FORMAT_DATE('%Y-%m', mes_referencia)) AS id_grupo_mensal,
  id_conta, cliente, moeda, id_campanha, campanha, id_grupo_anuncio, grupo_anuncio,
  mes_referencia,
  status_grupo_atual, tipo_grupo,
  dias_com_linha, dias_com_investimento,
  SAFE_DIVIDE(investimento_micros, 1000000)                         AS investimento,
  impressoes, cliques, interacoes,
  conversoes, todas_conversoes, valor_conversoes, valor_todas_conversoes,
  visualizacoes_video, engajamentos,
  SAFE_DIVIDE(SAFE_DIVIDE(investimento_micros, 1000000), cliques)   AS custo_por_clique,
  SAFE_DIVIDE(cliques, impressoes)                                  AS ctr,
  SAFE_DIVIDE(conversoes, cliques)                                  AS taxa_conversao,
  IF(conversoes > 0, SAFE_DIVIDE(SAFE_DIVIDE(investimento_micros, 1000000), conversoes), NULL) AS custo_por_conversao,
  pct_impressao_topo,
  SAFE_DIVIDE(SAFE_DIVIDE(investimento_micros, 1000000),
              NULLIF(SUM(SAFE_DIVIDE(investimento_micros, 1000000)) OVER (PARTITION BY id_conta, mes_referencia), 0)) AS participacao_investimento_conta_mes,
  lance_cpc_atual_micros,
  meta_cpa_micros,
  is_segmentacao_otimizada,
  qtd_palavras_ativas, qtd_negativas_ativas,
  qtd_anuncios_ativos, qtd_anuncios_ativos_forca_ruim,
  (meta_cpa_micros IS NOT NULL AND conversoes > 0
     AND SAFE_DIVIDE(investimento_micros, conversoes) > meta_cpa_micros) AS flag_cpa_acima_da_meta,
  (investimento_micros > 0 AND conversoes = 0)                      AS flag_gasta_sem_converter,
  (status_grupo_atual IN ('REMOVED', 'PAUSED') AND investimento_micros > 0) AS flag_gasto_em_grupo_nao_ativo_hoje,
  flag_grupo_nao_catalogado,
  flag_conta_nao_catalogada,
  CURRENT_TIMESTAMP()                                               AS _extraido_at,
  _extraido_trusted
FROM com_dim
