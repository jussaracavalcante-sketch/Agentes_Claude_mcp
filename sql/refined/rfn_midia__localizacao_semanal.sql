-- rfn_midia__localizacao_semanal
-- Refined / MIDIA. Grao: CONTA x PAIS x REGIAO x CIDADE x SEMANA (segunda-feira). Chave id_localizacao_semanal.
-- Origem: trs_google_ads__segmento_localizacao_usuario_semanal (Prestex, google-ads-OzfZ) + geo_alvo. Gatilho: evento em query-UAp8.
-- Espelha rfn_midia__localizacao_mensal em SEMANA; nao soma com a mensal. Regras, limitacoes e validacao: na descricao da transformacao na Nekt.
WITH geo AS (
  SELECT id_alvo_geo, MAX(nome) AS nome, MAX(tipo_alvo) AS tipo_alvo, MAX(codigo_pais) AS codigo_pais
  FROM `vanguardamartech_trusted`.`trs_google_ads__geo_alvo`
  GROUP BY id_alvo_geo
),
agg AS (
  SELECT
    id_conta, id_pais, id_regiao, id_cidade, semana_inicio,
    ANY_VALUE(cliente)                                       AS cliente,
    ANY_VALUE(moeda)                                         AS moeda,
    COUNT(DISTINCT id_campanha)                              AS qtd_campanhas,
    SUM(investimento_micros)                                 AS investimento_micros,
    SUM(IF(local_e_alvo, investimento_micros, 0))            AS investimento_em_local_alvo_micros,
    SUM(IF(NOT local_e_alvo, investimento_micros, 0))        AS investimento_fora_do_alvo_micros,
    SUM(impressoes)                                          AS impressoes,
    SUM(cliques)                                             AS cliques,
    SUM(interacoes)                                          AS interacoes,
    SUM(conversoes)                                          AS conversoes,
    SUM(todas_conversoes)                                    AS todas_conversoes,
    SUM(valor_conversoes)                                    AS valor_conversoes,
    SUM(valor_todas_conversoes)                              AS valor_todas_conversoes,
    LOGICAL_OR(flag_semana_incompleta_na_carga)              AS flag_semana_incompleta_na_carga
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_localizacao_usuario_semanal`
  GROUP BY 1, 2, 3, 4, 5
)
SELECT
  CONCAT(a.id_conta, ':', a.id_pais, ':', a.id_regiao, ':', a.id_cidade, ':', FORMAT_DATE('%Y%m%d', a.semana_inicio)) AS id_localizacao_semanal,
  a.id_conta, a.cliente, a.moeda,
  a.semana_inicio,
  DATE_ADD(a.semana_inicio, INTERVAL 6 DAY)                  AS semana_fim,
  a.id_pais,   gp.nome AS pais, gp.codigo_pais,
  a.id_regiao, gr.nome AS regiao, gr.tipo_alvo AS tipo_regiao,
  a.id_cidade, gc.nome AS cidade, gc.tipo_alvo AS tipo_cidade,
  a.qtd_campanhas,
  a.investimento_micros,
  ROUND(a.investimento_micros / 1000000, 2)                  AS investimento,
  ROUND(a.investimento_em_local_alvo_micros / 1000000, 2)    AS investimento_em_local_alvo,
  ROUND(a.investimento_fora_do_alvo_micros / 1000000, 2)     AS investimento_fora_do_alvo,
  ROUND(SAFE_DIVIDE(a.investimento_em_local_alvo_micros, NULLIF(a.investimento_micros, 0)), 6) AS participacao_local_alvo,
  a.impressoes, a.cliques, a.interacoes,
  a.conversoes, a.todas_conversoes, a.valor_conversoes, a.valor_todas_conversoes,
  ROUND(SAFE_DIVIDE(a.cliques, NULLIF(a.impressoes, 0)), 6)                              AS ctr,
  ROUND(SAFE_DIVIDE(a.investimento_micros / 1000000, NULLIF(a.cliques, 0)), 2)           AS cpc,
  ROUND(SAFE_DIVIDE(a.investimento_micros / 1000000, NULLIF(a.impressoes, 0)) * 1000, 2) AS cpm,
  ROUND(SAFE_DIVIDE(a.conversoes, NULLIF(a.cliques, 0)), 6)                              AS taxa_conversao,
  ROUND(SAFE_DIVIDE(a.investimento_micros / 1000000, NULLIF(a.conversoes, 0)), 2)        AS custo_por_conversao,
  ROUND(SAFE_DIVIDE(a.valor_conversoes, NULLIF(a.investimento_micros / 1000000, 0)), 4)  AS retorno_sobre_investimento,
  ROUND(SAFE_DIVIDE(a.investimento_micros,
    NULLIF(SUM(a.investimento_micros) OVER (PARTITION BY a.id_conta, a.semana_inicio), 0)), 6) AS participacao_investimento_na_conta_semana,
  (gp.id_alvo_geo IS NULL)                                   AS flag_pais_nao_catalogado,
  (gr.id_alvo_geo IS NULL)                                   AS flag_regiao_nao_catalogada,
  (gc.id_alvo_geo IS NULL)                                   AS flag_cidade_nao_catalogada,
  (a.investimento_micros > 0 AND IFNULL(a.conversoes, 0) = 0) AS flag_gasta_sem_converter,
  a.flag_semana_incompleta_na_carga,
  CURRENT_TIMESTAMP()                                        AS _extraido_at,
  'trs_google_ads__segmento_localizacao_usuario_semanal'     AS _fonte
FROM agg a
LEFT JOIN geo gp ON gp.id_alvo_geo = a.id_pais
LEFT JOIN geo gr ON gr.id_alvo_geo = a.id_regiao
LEFT JOIN geo gc ON gc.id_alvo_geo = a.id_cidade
