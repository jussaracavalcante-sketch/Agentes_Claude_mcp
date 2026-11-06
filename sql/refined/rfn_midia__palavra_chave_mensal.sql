-- rfn_midia__palavra_chave_mensal (query-wykH)
-- Refined / MIDIA. Grao: conta, campanha, grupo, criterio, mes. Origem: trs_google_ads__palavra_chave + _cadastro + conta.
-- Regras numeradas, limitacoes e medicao: na descricao da transformacao na Nekt.
WITH diario AS (
  SELECT
    id_conta, id_campanha, id_grupo_anuncio, id_criterio,
    DATE_TRUNC(data, MONTH)                                    AS mes_referencia,
    ARRAY_AGG(campanha ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)]       AS campanha,
    ARRAY_AGG(grupo_anuncio ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)]  AS grupo_anuncio,
    ARRAY_AGG(palavra_chave ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)]  AS palavra_chave,
    ARRAY_AGG(tipo_correspondencia ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)] AS tipo_correspondencia,
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
    SAFE_DIVIDE(SUM(IF(pct_impressao_topo_plataforma IS NOT NULL, pct_impressao_topo_plataforma * impressoes, 0)),
                SUM(IF(pct_impressao_topo_plataforma IS NOT NULL, impressoes, 0)))   AS pct_impressao_topo,
    MAX(nivel_qualidade)                                       AS nivel_qualidade_max_no_mes,
    MAX(_extraido_at)                                          AS _extraido_trusted
  FROM `vanguardamartech_trusted`.`trs_google_ads__palavra_chave`
  GROUP BY id_conta, id_campanha, id_grupo_anuncio, id_criterio, mes_referencia
),
com_dim AS (
  SELECT
    d.*,
    c.status                                    AS status_atual,
    c.nivel_qualidade                           AS nivel_qualidade_atual,
    c.lance_cpc_micros                          AS lance_cpc_atual_micros,
    (c.id_criterio IS NULL)                     AS flag_sem_cadastro,
    k.cliente,
    k.moeda,
    (k.id_conta IS NULL)                        AS flag_conta_nao_catalogada
  FROM diario d
  LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__palavra_chave_cadastro` c
    ON c.id_conta = d.id_conta AND c.id_grupo_anuncio = d.id_grupo_anuncio AND c.id_criterio = d.id_criterio
  LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__conta` k
    ON k.id_conta = d.id_conta
)
SELECT
  CONCAT(id_conta, '|', id_campanha, '|', id_grupo_anuncio, '|', id_criterio, '|', FORMAT_DATE('%Y-%m', mes_referencia)) AS id_palavra_mensal,
  id_conta, cliente, moeda, id_campanha, campanha, id_grupo_anuncio, grupo_anuncio, id_criterio,
  palavra_chave, tipo_correspondencia,
  mes_referencia,
  status_atual,
  dias_com_linha, dias_com_investimento,
  SAFE_DIVIDE(investimento_micros, 1000000)                         AS investimento,
  impressoes, cliques, interacoes,
  conversoes, todas_conversoes, valor_conversoes, valor_todas_conversoes,
  SAFE_DIVIDE(SAFE_DIVIDE(investimento_micros, 1000000), cliques)   AS custo_por_clique,
  SAFE_DIVIDE(cliques, impressoes)                                  AS ctr,
  SAFE_DIVIDE(conversoes, cliques)                                  AS taxa_conversao,
  IF(conversoes > 0, SAFE_DIVIDE(SAFE_DIVIDE(investimento_micros, 1000000), conversoes), NULL) AS custo_por_conversao,
  pct_impressao_topo,
  SAFE_DIVIDE(SAFE_DIVIDE(investimento_micros, 1000000),
              NULLIF(SUM(SAFE_DIVIDE(investimento_micros, 1000000)) OVER (PARTITION BY id_conta, mes_referencia), 0)) AS participacao_investimento_conta_mes,
  nivel_qualidade_max_no_mes,
  nivel_qualidade_atual,
  CASE
    WHEN nivel_qualidade_max_no_mes IS NULL THEN 'SEM_NOTA'
    WHEN nivel_qualidade_max_no_mes <= 4 THEN 'BAIXA'
    WHEN nivel_qualidade_max_no_mes <= 7 THEN 'MEDIA'
    ELSE 'ALTA'
  END                                                               AS faixa_qualidade,
  lance_cpc_atual_micros,
  (investimento_micros > 0 AND conversoes = 0)                      AS flag_gasta_sem_converter,
  (investimento_micros = 0 AND cliques = 0)                         AS flag_so_impressao,
  (status_atual IN ('REMOVED', 'PAUSED') AND investimento_micros > 0) AS flag_gasto_em_palavra_nao_ativa_hoje,
  flag_sem_cadastro,
  flag_conta_nao_catalogada,
  CURRENT_TIMESTAMP()                                               AS _extraido_at,
  _extraido_trusted
FROM com_dim
