-- rfn_midia__segmento_semanal
-- Refined / MIDIA. Grao: CONTA x TIPO de segmento x VALOR x SEMANA (segunda-feira). Chave id_segmento_semanal.
-- Origem: trs_google_ads__segmento_faixa_etaria_semanal + __genero_semanal + __geografico_semanal (Prestex, google-ads-OzfZ) + geo_alvo.
-- Gatilho: evento (regra all) em query-7CXS, query-I47r e query-sb9y. tipo_segmento E FILTRO, nunca group by para somar entre tipos.
-- Espelha rfn_midia__segmento_mensal em SEMANA; nao soma com a mensal. Regras, limitacoes e validacao: na descricao da transformacao na Nekt.
WITH geo AS (
  SELECT id_alvo_geo, MAX(nome) AS nome
  FROM `vanguardamartech_trusted`.`trs_google_ads__geo_alvo`
  GROUP BY id_alvo_geo
),
fe AS (
  SELECT id_conta, cliente, moeda, 'FAIXA_ETARIA' AS tipo_segmento, faixa_etaria AS valor_segmento, semana_inicio, id_campanha,
         investimento_micros, impressoes, cliques, interacoes, conversoes, todas_conversoes, valor_conversoes, valor_todas_conversoes,
         flag_semana_incompleta_na_carga
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_faixa_etaria_semanal`
),
gn AS (
  SELECT id_conta, cliente, moeda, 'GENERO', genero, semana_inicio, id_campanha,
         investimento_micros, impressoes, cliques, interacoes, conversoes, todas_conversoes, valor_conversoes, valor_todas_conversoes,
         flag_semana_incompleta_na_carga
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_genero_semanal`
),
-- O tipo de localizacao entra no PROPRIO tipo_segmento: a regra "some dentro do tipo, nunca entre tipos" fica uma so, sem excecao.
ge AS (
  SELECT id_conta, cliente, moeda,
         CASE tipo_localizacao
           WHEN 'LOCATION_OF_PRESENCE' THEN 'PAIS_PRESENCA'
           WHEN 'AREA_OF_INTEREST'     THEN 'PAIS_INTERESSE'
           ELSE CONCAT('PAIS_', COALESCE(tipo_localizacao, 'SEM_TIPO')) END,
         id_pais, semana_inicio, id_campanha,
         investimento_micros, impressoes, cliques, interacoes, conversoes, todas_conversoes, valor_conversoes, valor_todas_conversoes,
         flag_semana_incompleta_na_carga
  FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_geografico_semanal`
),
uniao AS (
  SELECT * FROM fe
  UNION ALL SELECT * FROM gn
  UNION ALL SELECT * FROM ge
),
agg AS (
  SELECT
    id_conta, tipo_segmento, valor_segmento, semana_inicio,
    ANY_VALUE(cliente)                    AS cliente,
    ANY_VALUE(moeda)                      AS moeda,
    COUNT(DISTINCT id_campanha)           AS qtd_campanhas,
    SUM(investimento_micros)              AS investimento_micros,
    SUM(impressoes)                       AS impressoes,
    SUM(cliques)                          AS cliques,
    SUM(interacoes)                       AS interacoes,
    SUM(conversoes)                       AS conversoes,
    SUM(todas_conversoes)                 AS todas_conversoes,
    SUM(valor_conversoes)                 AS valor_conversoes,
    SUM(valor_todas_conversoes)           AS valor_todas_conversoes,
    LOGICAL_OR(flag_semana_incompleta_na_carga) AS flag_semana_incompleta_na_carga
  FROM uniao
  GROUP BY 1, 2, 3, 4
)
SELECT
  CONCAT(a.id_conta, ':', a.tipo_segmento, ':', a.valor_segmento, ':', FORMAT_DATE('%Y%m%d', a.semana_inicio)) AS id_segmento_semanal,
  a.id_conta, a.cliente, a.moeda,
  a.semana_inicio,
  DATE_ADD(a.semana_inicio, INTERVAL 6 DAY)                       AS semana_fim,
  a.tipo_segmento,
  a.valor_segmento,
  -- REGRA 2 - o codigo cru fica em valor_segmento (rotulo nao e chave); rotulo_segmento e a leitura humana.
  CASE
    WHEN a.tipo_segmento = 'FAIXA_ETARIA' THEN
      CASE a.valor_segmento
        WHEN 'AGE_RANGE_18_24' THEN '18-24' WHEN 'AGE_RANGE_25_34' THEN '25-34' WHEN 'AGE_RANGE_35_44' THEN '35-44'
        WHEN 'AGE_RANGE_45_54' THEN '45-54' WHEN 'AGE_RANGE_55_64' THEN '55-64' WHEN 'AGE_RANGE_65_UP' THEN '65 ou mais'
        WHEN 'AGE_RANGE_UNDETERMINED' THEN 'Nao identificado' ELSE a.valor_segmento END
    WHEN a.tipo_segmento = 'GENERO' THEN
      CASE a.valor_segmento WHEN 'FEMALE' THEN 'Feminino' WHEN 'MALE' THEN 'Masculino' WHEN 'UNDETERMINED' THEN 'Nao identificado' ELSE a.valor_segmento END
    ELSE g.nome
  END                                                             AS rotulo_segmento,
  a.qtd_campanhas,
  a.investimento_micros,
  ROUND(a.investimento_micros / 1000000, 2)                       AS investimento,
  a.impressoes, a.cliques, a.interacoes,
  a.conversoes, a.todas_conversoes, a.valor_conversoes, a.valor_todas_conversoes,
  -- REGRA 3 - razao de somas, nunca media de razoes. REGRA 4 - sem denominador, NULL (nunca zero).
  ROUND(SAFE_DIVIDE(a.cliques, NULLIF(a.impressoes, 0)), 6)                                 AS ctr,
  ROUND(SAFE_DIVIDE(a.investimento_micros / 1000000, NULLIF(a.cliques, 0)), 2)              AS cpc,
  ROUND(SAFE_DIVIDE(a.investimento_micros / 1000000, NULLIF(a.impressoes, 0)) * 1000, 2)    AS cpm,
  ROUND(SAFE_DIVIDE(a.conversoes, NULLIF(a.cliques, 0)), 6)                                 AS taxa_conversao,
  ROUND(SAFE_DIVIDE(a.investimento_micros / 1000000, NULLIF(a.conversoes, 0)), 2)           AS custo_por_conversao,
  ROUND(SAFE_DIVIDE(a.valor_conversoes, NULLIF(a.investimento_micros / 1000000, 0)), 4)     AS retorno_sobre_investimento,
  -- REGRA 5 - fatia DENTRO de (conta, tipo, semana); soma 1,0 por construcao, e so dentro do tipo.
  ROUND(SAFE_DIVIDE(a.investimento_micros,
    NULLIF(SUM(a.investimento_micros) OVER (PARTITION BY a.id_conta, a.tipo_segmento, a.semana_inicio), 0)), 6) AS participacao_investimento,
  (a.tipo_segmento LIKE 'PAIS%')                                  AS flag_e_geografico,
  (a.tipo_segmento LIKE 'PAIS%' AND g.id_alvo_geo IS NULL)        AS flag_pais_nao_catalogado,
  -- REGRA 6 - UNDETERMINED nao e publico, e ausencia de atribuicao.
  (a.valor_segmento IN ('UNDETERMINED', 'AGE_RANGE_UNDETERMINED')) AS flag_segmento_nao_identificado,
  (a.investimento_micros > 0 AND IFNULL(a.conversoes, 0) = 0)     AS flag_gasta_sem_converter,
  a.flag_semana_incompleta_na_carga,
  CURRENT_TIMESTAMP()                                             AS _extraido_at,
  'trs_google_ads__segmento_{faixa_etaria,genero,geografico}_semanal' AS _fonte
FROM agg a
LEFT JOIN geo g ON g.id_alvo_geo = a.valor_segmento AND a.tipo_segmento LIKE 'PAIS%'
