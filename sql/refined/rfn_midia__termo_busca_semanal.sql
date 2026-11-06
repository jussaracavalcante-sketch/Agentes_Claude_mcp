-- rfn_midia__termo_busca_semanal
-- Refined / MIDIA. Grao: uma CONTA, um TERMO, uma SEMANA (segunda-feira). Chave id_termo_semanal.
-- Origem: trs_google_ads__termo_busca_semanal (Prestex, fonte google-ads-OzfZ). Gatilho: evento em query-0TbW.
-- Espelha rfn_midia__termo_busca_mensal em SEMANA (a Prestex e a unica conta semanal). NAO SOME com a tabela mensal nem com a Trusted diaria.
-- L4 PERSONAL_DATA herdado da Trusted (termo digitado). Regras numeradas, limitacoes e validacao: na descricao da transformacao na Nekt.
WITH base AS (
  SELECT id_conta, cliente, moeda, termo, semana_inicio, id_campanha, campanha, id_grupo_anuncio,
         tipo_correspondencia, status_termo, investimento_micros, impressoes, cliques, interacoes,
         conversoes, todas_conversoes, valor_conversoes, valor_todas_conversoes,
         flag_semana_incompleta_na_carga, flag_conta_nao_catalogada
  FROM `vanguardamartech_trusted`.`trs_google_ads__termo_busca_semanal`
),
-- REGRA 1 - agrega por campanha ANTES de escolher a principal (a campanha que mais gastou na semana, nao a da linha mais cara).
por_campanha AS (
  SELECT id_conta, termo, semana_inicio, id_campanha, campanha, SUM(investimento_micros) AS investimento_campanha_micros
  FROM base
  GROUP BY 1, 2, 3, 4, 5
),
campanha_principal AS (
  SELECT id_conta, termo, semana_inicio, id_campanha, campanha
  FROM por_campanha
  QUALIFY ROW_NUMBER() OVER (PARTITION BY id_conta, termo, semana_inicio
                             ORDER BY investimento_campanha_micros DESC, campanha) = 1
),
agregado AS (
  SELECT
    id_conta, termo, semana_inicio,
    ANY_VALUE(cliente)                                          AS cliente,
    ANY_VALUE(moeda)                                            AS moeda,
    COUNT(DISTINCT id_campanha)                                 AS qtd_campanhas,
    COUNT(DISTINCT id_grupo_anuncio)                            AS qtd_grupos_anuncio,
    STRING_AGG(DISTINCT tipo_correspondencia, ' | ' ORDER BY tipo_correspondencia) AS tipos_correspondencia,
    STRING_AGG(DISTINCT status_termo, ' | ' ORDER BY status_termo)                 AS status_termos,
    LOGICAL_OR(STARTS_WITH(tipo_correspondencia, 'NEAR_'))      AS flag_tem_variante_proxima,
    LOGICAL_OR(tipo_correspondencia = 'BROAD')                  AS flag_tem_ampla,
    LOGICAL_OR(tipo_correspondencia = 'AI_MAX')                 AS flag_tem_ai_max,
    LOGICAL_OR(status_termo IN ('EXCLUDED', 'ADDED_EXCLUDED'))  AS flag_excluido_em_alguma_campanha,
    LOGICAL_OR(status_termo IN ('ADDED', 'ADDED_EXCLUDED'))     AS flag_virou_palavra_chave,
    SUM(investimento_micros)                                    AS investimento_micros,
    SUM(IF(STARTS_WITH(tipo_correspondencia, 'NEAR_'), investimento_micros, 0)) AS investimento_variante_proxima_micros,
    SUM(impressoes)                                             AS impressoes,
    SUM(cliques)                                                AS cliques,
    SUM(interacoes)                                             AS interacoes,
    SUM(conversoes)                                             AS conversoes,
    SUM(todas_conversoes)                                       AS todas_conversoes,
    SUM(valor_conversoes)                                       AS valor_conversoes,
    SUM(valor_todas_conversoes)                                 AS valor_todas_conversoes,
    LOGICAL_OR(flag_semana_incompleta_na_carga)                 AS flag_semana_incompleta_na_carga,
    LOGICAL_OR(flag_conta_nao_catalogada)                       AS flag_conta_nao_catalogada
  FROM base
  GROUP BY id_conta, termo, semana_inicio
)
SELECT
  CONCAT(a.id_conta, '|', FORMAT_DATE('%Y%m%d', a.semana_inicio), '|', TO_HEX(MD5(a.termo))) AS id_termo_semanal,
  a.id_conta, a.cliente, a.moeda,
  a.termo,
  LENGTH(a.termo)                                               AS qtd_caracteres_do_termo,
  a.semana_inicio,
  DATE_ADD(a.semana_inicio, INTERVAL 6 DAY)                     AS semana_fim,
  a.qtd_campanhas, a.qtd_grupos_anuncio,
  cp.id_campanha                                                AS id_campanha_principal,
  cp.campanha                                                   AS campanha_principal,
  a.tipos_correspondencia, a.status_termos,
  a.flag_tem_variante_proxima, a.flag_tem_ampla, a.flag_tem_ai_max,
  a.flag_excluido_em_alguma_campanha, a.flag_virou_palavra_chave,
  a.investimento_micros,
  ROUND(a.investimento_micros / 1000000, 2)                     AS investimento,
  ROUND(a.investimento_variante_proxima_micros / 1000000, 2)    AS investimento_variante_proxima,
  a.impressoes, a.cliques, a.interacoes,
  a.conversoes, a.todas_conversoes, a.valor_conversoes, a.valor_todas_conversoes,
  -- REGRA 2 - derivada e decisao de negocio: mora aqui. Sem denominador, NULL (nunca zero, nunca infinito).
  ROUND(SAFE_DIVIDE(a.investimento_micros / 1000000, NULLIF(a.cliques, 0)), 4)      AS custo_por_clique,
  ROUND(SAFE_DIVIDE(a.investimento_micros / 1000000, NULLIF(a.conversoes, 0)), 2)   AS custo_por_conversao,
  ROUND(SAFE_DIVIDE(a.conversoes, NULLIF(a.cliques, 0)), 6)                         AS taxa_conversao,
  ROUND(SAFE_DIVIDE(a.cliques, NULLIF(a.impressoes, 0)), 6)                         AS taxa_clique,
  ROUND(SAFE_DIVIDE(a.valor_conversoes, NULLIF(a.investimento_micros / 1000000, 0)), 4) AS retorno_sobre_investimento,
  (a.investimento_micros > 0)                                   AS tem_investimento,
  (a.conversoes > 0)                                            AS tem_conversao,
  -- REGRA 3 - candidato a revisao, nunca veredicto.
  (a.investimento_micros > 0 AND IFNULL(a.conversoes, 0) = 0)   AS flag_gasta_sem_converter,
  -- REGRA 4 - a cauda fica, marcada.
  (a.impressoes > 0 AND IFNULL(a.cliques, 0) = 0)               AS flag_so_impressao,
  a.flag_semana_incompleta_na_carga,
  a.flag_conta_nao_catalogada,
  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'trs_google_ads__termo_busca_semanal'                         AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(a)))                                AS _payload_hash
FROM agregado a
LEFT JOIN campanha_principal cp
  ON cp.id_conta = a.id_conta AND cp.termo = a.termo AND cp.semana_inicio = a.semana_inicio
