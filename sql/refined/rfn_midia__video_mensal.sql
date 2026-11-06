-- rfn_midia__video_mensal (query-CTe7)
-- Refined / MIDIA. Grao: conta, campanha, video, mes. Origem: video_desempenho_diario + video + conta.
-- Regras numeradas, limitacoes e medicao: na descricao da transformacao na Nekt.
WITH diario AS (
  SELECT
    id_conta, id_campanha, id_video,
    DATE_TRUNC(data, MONTH)                                          AS mes_referencia,
    ARRAY_AGG(campanha ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)]   AS campanha,
    ARRAY_AGG(titulo_video ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)] AS titulo_video,
    ARRAY_AGG(id_canal ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)]   AS id_canal,
    ARRAY_AGG(duracao_video_segundos ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)] AS duracao_video_segundos,
    COUNT(DISTINCT id_grupo_anuncio)                                 AS qtd_grupos_anuncio,
    COUNT(DISTINCT data)                                             AS dias_com_linha,
    SUM(investimento_micros)                                         AS investimento_micros,
    SUM(impressoes)                                                  AS impressoes,
    SUM(cliques)                                                     AS cliques,
    SUM(engajamentos)                                                AS engajamentos,
    SUM(visualizacoes_video)                                         AS visualizacoes_video,
    SUM(conversoes)                                                  AS conversoes,
    SUM(todas_conversoes)                                            AS todas_conversoes,
    SUM(valor_conversoes)                                            AS valor_conversoes,
    SUM(conversoes_view_through)                                     AS conversoes_view_through,
    SAFE_DIVIDE(SUM(IF(taxa_quartil_25_plataforma IS NOT NULL, taxa_quartil_25_plataforma * impressoes, 0)), SUM(IF(taxa_quartil_25_plataforma IS NOT NULL, impressoes, 0)))   AS taxa_quartil_25,
    SAFE_DIVIDE(SUM(IF(taxa_quartil_50_plataforma IS NOT NULL, taxa_quartil_50_plataforma * impressoes, 0)), SUM(IF(taxa_quartil_50_plataforma IS NOT NULL, impressoes, 0)))   AS taxa_quartil_50,
    SAFE_DIVIDE(SUM(IF(taxa_quartil_75_plataforma IS NOT NULL, taxa_quartil_75_plataforma * impressoes, 0)), SUM(IF(taxa_quartil_75_plataforma IS NOT NULL, impressoes, 0)))   AS taxa_quartil_75,
    SAFE_DIVIDE(SUM(IF(taxa_quartil_100_plataforma IS NOT NULL, taxa_quartil_100_plataforma * impressoes, 0)), SUM(IF(taxa_quartil_100_plataforma IS NOT NULL, impressoes, 0))) AS taxa_quartil_100,
    MAX(_extraido_at)                                                AS _extraido_trusted
  FROM `vanguardamartech_trusted`.`trs_google_ads__video_desempenho_diario`
  GROUP BY id_conta, id_campanha, id_video, mes_referencia
),
com_dim AS (
  SELECT
    d.*,
    v.titulo                                   AS titulo_cadastro,
    (v.id_video IS NULL)                       AS flag_video_sem_cadastro,
    k.cliente, k.moeda,
    (k.id_conta IS NULL)                       AS flag_conta_nao_catalogada
  FROM diario d
  LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__video` v ON v.id_conta = d.id_conta AND v.id_video = d.id_video
  LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__conta` k ON k.id_conta = d.id_conta
)
SELECT
  CONCAT(id_conta, '|', id_campanha, '|', id_video, '|', FORMAT_DATE('%Y-%m', mes_referencia)) AS id_video_mensal,
  id_conta, cliente, moeda, id_campanha, campanha,
  id_video, COALESCE(titulo_cadastro, titulo_video) AS titulo_video, id_canal, duracao_video_segundos,
  mes_referencia,
  qtd_grupos_anuncio, dias_com_linha,
  SAFE_DIVIDE(investimento_micros, 1000000)                         AS investimento,
  impressoes, cliques, engajamentos, visualizacoes_video,
  conversoes, todas_conversoes, valor_conversoes, conversoes_view_through,
  SAFE_DIVIDE(visualizacoes_video, impressoes)                      AS taxa_visualizacao,
  SAFE_DIVIDE(SAFE_DIVIDE(investimento_micros, 1000000), visualizacoes_video) AS custo_por_visualizacao,
  SAFE_DIVIDE(SAFE_DIVIDE(investimento_micros, 1000000), cliques)   AS custo_por_clique,
  SAFE_DIVIDE(SAFE_DIVIDE(investimento_micros, 1000000), impressoes) * 1000 AS cpm,
  SAFE_DIVIDE(cliques, impressoes)                                  AS ctr,
  SAFE_DIVIDE(engajamentos, impressoes)                             AS taxa_engajamento,
  IF(conversoes > 0, SAFE_DIVIDE(SAFE_DIVIDE(investimento_micros, 1000000), conversoes), NULL) AS custo_por_conversao,
  taxa_quartil_25, taxa_quartil_50, taxa_quartil_75, taxa_quartil_100,
  (investimento_micros > 0 AND visualizacoes_video = 0)             AS flag_gasta_sem_visualizacao,
  flag_video_sem_cadastro,
  flag_conta_nao_catalogada,
  CURRENT_TIMESTAMP()                                               AS _extraido_at,
  _extraido_trusted
FROM com_dim
