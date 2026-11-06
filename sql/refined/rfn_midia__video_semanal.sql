-- rfn_midia__video_semanal
-- Refined / MIDIA. Grao: CONTA x CAMPANHA x VIDEO x SEMANA (segunda-feira); grupo vira contagem. Chave id_video_semanal.
-- Origem: trs_google_ads__video_desempenho_semanal (Prestex, google-ads-OzfZ). Gatilho: evento em query-3DWD.
-- Espelha rfn_midia__video_mensal em SEMANA, sem dimensao de video (a Prestex nao tem o stream videos). Nao soma com a mensal.
-- Regras, limitacoes e validacao: na descricao da transformacao na Nekt.
WITH agg AS (
  SELECT
    id_conta, id_campanha, id_video, semana_inicio,
    ANY_VALUE(cliente)                                               AS cliente,
    ANY_VALUE(moeda)                                                 AS moeda,
    ANY_VALUE(campanha)                                              AS campanha,
    ANY_VALUE(titulo_video)                                          AS titulo_video,
    ANY_VALUE(id_canal)                                              AS id_canal,
    ANY_VALUE(duracao_video_segundos)                                AS duracao_video_segundos,
    COUNT(DISTINCT id_grupo_anuncio)                                 AS qtd_grupos_anuncio,
    SUM(investimento_micros)                                         AS investimento_micros,
    SUM(impressoes)                                                  AS impressoes,
    SUM(cliques)                                                     AS cliques,
    SUM(engajamentos)                                                AS engajamentos,
    SUM(visualizacoes_video)                                         AS visualizacoes_video,
    SUM(conversoes)                                                  AS conversoes,
    SUM(todas_conversoes)                                            AS todas_conversoes,
    SUM(valor_conversoes)                                            AS valor_conversoes,
    SUM(conversoes_view_through)                                     AS conversoes_view_through,
    -- REGRA 3 - quartil e taxa da plataforma: media PONDERADA por impressao, so onde a plataforma entrega (nunca media simples).
    SAFE_DIVIDE(SUM(IF(taxa_quartil_25_plataforma IS NOT NULL, taxa_quartil_25_plataforma * impressoes, 0)), SUM(IF(taxa_quartil_25_plataforma IS NOT NULL, impressoes, 0)))   AS taxa_quartil_25,
    SAFE_DIVIDE(SUM(IF(taxa_quartil_50_plataforma IS NOT NULL, taxa_quartil_50_plataforma * impressoes, 0)), SUM(IF(taxa_quartil_50_plataforma IS NOT NULL, impressoes, 0)))   AS taxa_quartil_50,
    SAFE_DIVIDE(SUM(IF(taxa_quartil_75_plataforma IS NOT NULL, taxa_quartil_75_plataforma * impressoes, 0)), SUM(IF(taxa_quartil_75_plataforma IS NOT NULL, impressoes, 0)))   AS taxa_quartil_75,
    SAFE_DIVIDE(SUM(IF(taxa_quartil_100_plataforma IS NOT NULL, taxa_quartil_100_plataforma * impressoes, 0)), SUM(IF(taxa_quartil_100_plataforma IS NOT NULL, impressoes, 0))) AS taxa_quartil_100,
    LOGICAL_OR(flag_semana_incompleta_na_carga)                      AS flag_semana_incompleta_na_carga,
    LOGICAL_OR(flag_conta_nao_catalogada)                            AS flag_conta_nao_catalogada
  FROM `vanguardamartech_trusted`.`trs_google_ads__video_desempenho_semanal`
  GROUP BY id_conta, id_campanha, id_video, semana_inicio
)
SELECT
  CONCAT(id_conta, '|', id_campanha, '|', id_video, '|', FORMAT_DATE('%Y%m%d', semana_inicio)) AS id_video_semanal,
  id_conta, cliente, moeda, id_campanha, campanha,
  id_video, titulo_video, id_canal, duracao_video_segundos,
  semana_inicio,
  DATE_ADD(semana_inicio, INTERVAL 6 DAY)                           AS semana_fim,
  qtd_grupos_anuncio,
  investimento_micros,
  ROUND(investimento_micros / 1000000, 2)                           AS investimento,
  impressoes, cliques, engajamentos, visualizacoes_video,
  conversoes, todas_conversoes, valor_conversoes, conversoes_view_through,
  -- REGRA 2 - derivadas recalculadas dos totais; sem denominador NULL, nunca zero.
  ROUND(SAFE_DIVIDE(visualizacoes_video, NULLIF(impressoes, 0)), 6)                              AS taxa_visualizacao,
  ROUND(SAFE_DIVIDE(investimento_micros / 1000000, NULLIF(visualizacoes_video, 0)), 4)           AS custo_por_visualizacao,
  ROUND(SAFE_DIVIDE(investimento_micros / 1000000, NULLIF(cliques, 0)), 4)                       AS custo_por_clique,
  ROUND(SAFE_DIVIDE(investimento_micros / 1000000, NULLIF(impressoes, 0)) * 1000, 4)             AS cpm,
  ROUND(SAFE_DIVIDE(cliques, NULLIF(impressoes, 0)), 6)                                          AS ctr,
  ROUND(SAFE_DIVIDE(engajamentos, NULLIF(impressoes, 0)), 6)                                     AS taxa_engajamento,
  ROUND(SAFE_DIVIDE(investimento_micros / 1000000, NULLIF(conversoes, 0)), 2)                    AS custo_por_conversao,
  taxa_quartil_25, taxa_quartil_50, taxa_quartil_75, taxa_quartil_100,
  (investimento_micros > 0 AND IFNULL(visualizacoes_video, 0) = 0)  AS flag_gasta_sem_visualizacao,
  flag_semana_incompleta_na_carga,
  flag_conta_nao_catalogada,
  CURRENT_TIMESTAMP()                                               AS _extraido_at,
  'trs_google_ads__video_desempenho_semanal'                        AS _fonte
FROM agg
