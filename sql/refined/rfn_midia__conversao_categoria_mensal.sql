-- rfn_midia__conversao_categoria_mensal (query-yxEh)
-- Refined / MIDIA. Grao: conta, campanha, categoria de conversao, mes. Origem: as tres trs_google_ads__conversao_acao_* + acao_conversao + conta.
-- Regras numeradas, limitacoes e medicao: na descricao da transformacao na Nekt.
WITH camp AS (
  SELECT id_conta, id_campanha, mes_referencia, categoria_conversao,
    ARRAY_AGG(campanha ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)] AS campanha,
    SUM(conversoes)                         AS conversoes_campanha,
    SUM(todas_conversoes)                   AS todas_conversoes_campanha,
    SUM(valor_conversoes)                   AS valor_campanha,
    SUM(conversoes_por_data_conversao)      AS conversoes_por_data_conversao_campanha,
    MAX(_extraido_at)                       AS _extraido_trusted
  FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_campanha`
  GROUP BY id_conta, id_campanha, mes_referencia, categoria_conversao
),
grupo AS (
  SELECT id_conta, id_campanha, mes_referencia, categoria_conversao,
    ARRAY_AGG(campanha ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)] AS campanha,
    SUM(conversoes)                         AS conversoes_grupo,
    SUM(valor_conversoes)                   AS valor_grupo
  FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_grupo`
  GROUP BY id_conta, id_campanha, mes_referencia, categoria_conversao
),
anuncio AS (
  SELECT id_conta, id_campanha, mes_referencia, categoria_conversao,
    ARRAY_AGG(campanha ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)] AS campanha,
    SUM(conversoes)                         AS conversoes_anuncio,
    SUM(valor_conversoes)                   AS valor_anuncio
  FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_anuncio`
  GROUP BY id_conta, id_campanha, mes_referencia, categoria_conversao
),
chaves AS (
  SELECT id_conta, id_campanha, mes_referencia, categoria_conversao FROM camp
  UNION DISTINCT SELECT id_conta, id_campanha, mes_referencia, categoria_conversao FROM grupo
  UNION DISTINCT SELECT id_conta, id_campanha, mes_referencia, categoria_conversao FROM anuncio
),
acoes AS (
  SELECT id_conta, categoria,
    COUNTIF(status = 'ENABLED')                                        AS qtd_acoes_ativas_na_categoria,
    COUNTIF(status = 'ENABLED' AND is_primaria_para_meta)              AS qtd_acoes_primarias_na_categoria
  FROM `vanguardamartech_trusted`.`trs_google_ads__acao_conversao`
  GROUP BY id_conta, categoria
),
juntas AS (
  SELECT
    k.id_conta, k.id_campanha, k.mes_referencia, k.categoria_conversao,
    COALESCE(c.campanha, g.campanha, a.campanha) AS campanha,
    c.conversoes_campanha, c.todas_conversoes_campanha, c.valor_campanha, c.conversoes_por_data_conversao_campanha,
    g.conversoes_grupo, g.valor_grupo,
    a.conversoes_anuncio, a.valor_anuncio,
    (c.id_campanha IS NULL) AS flag_so_em_grao_inferior,
    ac.qtd_acoes_ativas_na_categoria, ac.qtd_acoes_primarias_na_categoria,
    d.cliente, d.moeda,
    (d.id_conta IS NULL) AS flag_conta_nao_catalogada,
    c._extraido_trusted
  FROM chaves k
  LEFT JOIN camp c USING (id_conta, id_campanha, mes_referencia, categoria_conversao)
  LEFT JOIN grupo g USING (id_conta, id_campanha, mes_referencia, categoria_conversao)
  LEFT JOIN anuncio a USING (id_conta, id_campanha, mes_referencia, categoria_conversao)
  LEFT JOIN acoes ac ON ac.id_conta = k.id_conta AND ac.categoria = k.categoria_conversao
  LEFT JOIN `vanguardamartech_trusted`.`trs_google_ads__conta` d ON d.id_conta = k.id_conta
)
SELECT
  CONCAT(id_conta, '|', id_campanha, '|', categoria_conversao, '|', FORMAT_DATE('%Y-%m', mes_referencia)) AS id_conversao_mensal,
  id_conta, cliente, moeda, id_campanha, campanha,
  mes_referencia,
  categoria_conversao,
  CASE
    WHEN categoria_conversao IN ('SUBMIT_LEAD_FORM', 'CONTACT', 'PHONE_CALL_LEAD', 'REQUEST_QUOTE', 'SIGNUP') THEN 'LEAD'
    WHEN categoria_conversao = 'PURCHASE' THEN 'VENDA'
    WHEN categoria_conversao IN ('STORE_VISIT', 'GET_DIRECTIONS') THEN 'LOJA'
    WHEN categoria_conversao IN ('ADD_TO_CART', 'BEGIN_CHECKOUT', 'PAGE_VIEW', 'DOWNLOAD') THEN 'FUNIL'
    WHEN categoria_conversao IN ('ENGAGEMENT', 'YOUTUBE_FOLLOW_ON_VIEWS') THEN 'ENGAJAMENTO'
    ELSE 'INDEFINIDA'
  END                                                              AS classe_conversao,
  conversoes_campanha, todas_conversoes_campanha, valor_campanha, conversoes_por_data_conversao_campanha,
  conversoes_grupo, valor_grupo,
  conversoes_anuncio, valor_anuncio,
  qtd_acoes_ativas_na_categoria, qtd_acoes_primarias_na_categoria,
  (ABS(IFNULL(conversoes_campanha, 0) - IFNULL(conversoes_grupo, 0)) > 0.01
   OR ABS(IFNULL(conversoes_campanha, 0) - IFNULL(conversoes_anuncio, 0)) > 0.01) AS flag_graos_divergem,
  flag_so_em_grao_inferior,
  flag_conta_nao_catalogada,
  CURRENT_TIMESTAMP()                                              AS _extraido_at,
  _extraido_trusted
FROM juntas
