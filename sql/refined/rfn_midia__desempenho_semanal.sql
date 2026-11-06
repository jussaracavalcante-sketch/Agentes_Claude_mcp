-- Refined / dominio Midia - rfn_midia__desempenho_semanal
-- Grao: uma linha por (id_conta, id_campanha, semana_inicio). Chave id_desempenho_semanal.
-- Le trs_google_ads__insight_semanal (conta Prestex, fonte google-ads-OzfZ, extracao SEMANAL).
-- Gatilho: evento em query-FzRx. Existe porque a Prestex e a unica conta de Google Ads em
-- granularidade semanal e NAO pode entrar em rfn_midia__desempenho_diario (somaria semana com dia).
-- Metricas derivadas sao recalculadas da razao dos totais, como na Refined diaria (regra 4).
WITH agg AS (
  SELECT
    id_conta,
    id_campanha,
    semana_inicio,
    MAX(cliente)                                                     AS cliente,
    MAX(moeda)                                                       AS moeda,
    MAX(campanha)                                                    AS campanha,
    MAX(status_campanha)                                             AS status_campanha_na_semana,
    MAX(canal)                                                       AS canal,
    MAX(estrategia_lance)                                            AS estrategia_lance,
    IF(COUNT(DISTINCT grao) > 1, 'MISTO', MAX(grao))                 AS grao_origem,
    COUNT(DISTINCT id_anuncio)                                       AS qtd_anuncios,
    SUM(investimento_micros)                                         AS investimento_micros,
    SUM(impressoes)                                                  AS impressoes,
    SUM(cliques)                                                     AS cliques,
    SUM(interacoes)                                                  AS interacoes,
    SUM(conversoes)                                                  AS conversoes,
    SUM(valor_conversoes)                                            AS valor_conversoes,
    SUM(todas_conversoes)                                            AS todas_conversoes,
    SUM(visualizacoes_video)                                         AS visualizacoes_video,
    LOGICAL_OR(flag_semana_incompleta_na_carga)                      AS flag_semana_incompleta_na_carga,
    LOGICAL_OR(flag_conta_nao_catalogada)                            AS flag_conta_nao_catalogada,
    LOGICAL_OR(flag_campanha_nao_catalogada)                         AS flag_campanha_nao_catalogada,
    MAX(_extraido_at)                                                AS _extraido_at,
    MAX(_fonte)                                                      AS _fonte
  FROM `vanguardamartech_trusted`.`trs_google_ads__insight_semanal`
  GROUP BY id_conta, id_campanha, semana_inicio
)
SELECT
  CONCAT(id_conta, '|', CAST(id_campanha AS STRING), '|', FORMAT_DATE('%Y%m%d', semana_inicio)) AS id_desempenho_semanal,
  'GOOGLE_ADS'                                                       AS plataforma,
  id_conta,
  cliente,
  moeda,
  id_campanha,
  campanha,
  status_campanha_na_semana,
  canal,
  estrategia_lance,
  semana_inicio,
  DATE_ADD(semana_inicio, INTERVAL 6 DAY)                            AS semana_fim,
  investimento_micros,
  ROUND(investimento_micros / 1000000, 2)                            AS investimento,
  impressoes,
  cliques,
  interacoes,
  conversoes,
  todas_conversoes,
  valor_conversoes,
  visualizacoes_video,
  ROUND(SAFE_DIVIDE(cliques,    impressoes) * 100, 2)                AS ctr_pct,
  ROUND(SAFE_DIVIDE(investimento_micros / 1000000, cliques), 2)      AS cpc,
  ROUND(SAFE_DIVIDE(investimento_micros / 1000000, impressoes) * 1000, 2) AS cpm,
  ROUND(SAFE_DIVIDE(investimento_micros / 1000000, conversoes), 2)   AS cpa,
  ROUND(SAFE_DIVIDE(valor_conversoes, investimento_micros / 1000000), 2) AS roas,
  grao_origem,
  qtd_anuncios,
  grao_origem = 'CAMPANHA'                                           AS sem_detalhe_por_anuncio,
  impressoes = 0                                                     AS sem_entrega,
  flag_semana_incompleta_na_carga,
  flag_conta_nao_catalogada,
  flag_campanha_nao_catalogada,
  grao_origem = 'MISTO'                                              AS flag_grao_misto,
  NOT (flag_conta_nao_catalogada OR flag_campanha_nao_catalogada
       OR grao_origem = 'MISTO' OR flag_semana_incompleta_na_carga)  AS registro_confiavel,
  _extraido_at,
  _fonte
FROM agg
