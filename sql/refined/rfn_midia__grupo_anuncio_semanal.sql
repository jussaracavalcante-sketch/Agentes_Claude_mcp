-- rfn_midia__grupo_anuncio_semanal
-- Refined / MIDIA. Grao: CONTA x CAMPANHA x GRUPO x SEMANA (segunda-feira) = o grao da Trusted. Chave id_grupo_semanal.
-- Origem: trs_google_ads__grupo_anuncio_semanal (Prestex, google-ads-OzfZ). Gatilho: evento em query-uQ44.
-- Espelha rfn_midia__grupo_anuncio_mensal em SEMANA, sem cadastro de grupo (a Prestex nao tem ad_groups/keywords/ad). Nao soma com a mensal.
-- Regras, limitacoes e validacao: na descricao da transformacao na Nekt.
WITH base AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio_semanal`
)
SELECT
  CONCAT(id_conta, '|', id_campanha, '|', id_grupo_anuncio, '|', FORMAT_DATE('%Y%m%d', semana_inicio)) AS id_grupo_semanal,
  id_conta, cliente, moeda, id_campanha, campanha, id_grupo_anuncio, grupo_anuncio,
  semana_inicio, semana_fim,
  investimento_micros,
  ROUND(investimento_micros / 1000000, 2)                           AS investimento,
  impressoes, cliques, interacoes,
  conversoes, todas_conversoes, valor_conversoes, valor_todas_conversoes,
  visualizacoes_video, engajamentos,
  -- REGRA 2 - derivadas recalculadas dos totais; sem denominador NULL, nunca zero.
  ROUND(SAFE_DIVIDE(investimento_micros / 1000000, NULLIF(cliques, 0)), 4)    AS custo_por_clique,
  ROUND(SAFE_DIVIDE(cliques, NULLIF(impressoes, 0)), 6)                       AS ctr,
  ROUND(SAFE_DIVIDE(conversoes, NULLIF(cliques, 0)), 6)                       AS taxa_conversao,
  ROUND(SAFE_DIVIDE(investimento_micros / 1000000, NULLIF(conversoes, 0)), 2) AS custo_por_conversao,
  pct_impressao_topo_plataforma                                     AS pct_impressao_topo,
  ROUND(SAFE_DIVIDE(investimento_micros,
    NULLIF(SUM(investimento_micros) OVER (PARTITION BY id_conta, semana_inicio), 0)), 6) AS participacao_investimento_conta_semana,
  (investimento_micros > 0 AND IFNULL(conversoes, 0) = 0)           AS flag_gasta_sem_converter,
  (investimento_micros = 0 AND IFNULL(cliques, 0) = 0)              AS flag_so_impressao,
  flag_semana_incompleta_na_carga,
  flag_conta_nao_catalogada,
  CURRENT_TIMESTAMP()                                               AS _extraido_at,
  'trs_google_ads__grupo_anuncio_semanal'                           AS _fonte
FROM base
