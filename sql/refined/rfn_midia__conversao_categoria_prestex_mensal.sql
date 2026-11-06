-- rfn_midia__conversao_categoria_prestex_mensal
-- Refined / MIDIA. Grao: CONTA x CAMPANHA x CATEGORIA de conversao x MES (os streams de conversao da Prestex sao DIARIOS). Chave id_conversao_mensal.
-- Origem: trs_google_ads__conversao_acao_campanha_prestex + __anuncio_prestex (Prestex, google-ads-OzfZ). Gatilho: evento (regra all) em query-0vDH e query-JmIB.
-- Espelha rfn_midia__conversao_categoria_mensal. Os dois graos NAO somam o mesmo: flag_graos_divergem marca, nunca corrige.
-- Regras, limitacoes e validacao: na descricao da transformacao na Nekt.
WITH camp AS (
  SELECT id_conta, id_campanha, mes_referencia, categoria_conversao,
    ANY_VALUE(cliente)                      AS cliente,
    ANY_VALUE(moeda)                        AS moeda,
    ARRAY_AGG(campanha ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)] AS campanha,
    COUNT(DISTINCT data)                    AS dias_com_linha_campanha,
    SUM(conversoes)                         AS conversoes_campanha,
    SUM(todas_conversoes)                   AS todas_conversoes_campanha,
    SUM(valor_conversoes)                   AS valor_campanha,
    SUM(conversoes_por_data_conversao)      AS conversoes_por_data_conversao_campanha
  FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_campanha_prestex`
  GROUP BY id_conta, id_campanha, mes_referencia, categoria_conversao
),
anuncio AS (
  SELECT id_conta, id_campanha, mes_referencia, categoria_conversao,
    ANY_VALUE(cliente)                      AS cliente,
    ANY_VALUE(moeda)                        AS moeda,
    ARRAY_AGG(campanha ORDER BY data DESC LIMIT 1)[SAFE_OFFSET(0)] AS campanha,
    COUNT(DISTINCT id_anuncio)              AS qtd_anuncios,
    SUM(conversoes)                         AS conversoes_anuncio,
    SUM(todas_conversoes)                   AS todas_conversoes_anuncio,
    SUM(valor_conversoes)                   AS valor_anuncio
  FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_anuncio_prestex`
  GROUP BY id_conta, id_campanha, mes_referencia, categoria_conversao
),
chaves AS (
  SELECT id_conta, id_campanha, mes_referencia, categoria_conversao FROM camp
  UNION DISTINCT SELECT id_conta, id_campanha, mes_referencia, categoria_conversao FROM anuncio
),
juntas AS (
  SELECT
    k.id_conta, k.id_campanha, k.mes_referencia, k.categoria_conversao,
    COALESCE(c.cliente, a.cliente) AS cliente, COALESCE(c.moeda, a.moeda) AS moeda,
    COALESCE(c.campanha, a.campanha) AS campanha,
    c.dias_com_linha_campanha,
    c.conversoes_campanha, c.todas_conversoes_campanha, c.valor_campanha, c.conversoes_por_data_conversao_campanha,
    a.qtd_anuncios, a.conversoes_anuncio, a.todas_conversoes_anuncio, a.valor_anuncio,
    (c.id_campanha IS NULL) AS flag_so_em_grao_anuncio,
    (a.id_campanha IS NULL) AS flag_so_em_grao_campanha
  FROM chaves k
  LEFT JOIN camp c USING (id_conta, id_campanha, mes_referencia, categoria_conversao)
  LEFT JOIN anuncio a USING (id_conta, id_campanha, mes_referencia, categoria_conversao)
)
SELECT
  CONCAT(id_conta, '|', id_campanha, '|', categoria_conversao, '|', FORMAT_DATE('%Y-%m', mes_referencia)) AS id_conversao_mensal,
  id_conta, cliente, moeda, id_campanha, campanha,
  mes_referencia,
  categoria_conversao,
  -- REGRA 2 - classe de negocio sobre a CATEGORIA; a Trusted nao escolhe 'a conversao' do cliente, isto e leitura declarada (mesmo mapa da rfn_midia__conversao_categoria_mensal).
  CASE
    WHEN categoria_conversao IN ('SUBMIT_LEAD_FORM', 'CONTACT', 'PHONE_CALL_LEAD', 'REQUEST_QUOTE', 'SIGNUP') THEN 'LEAD'
    WHEN categoria_conversao = 'PURCHASE' THEN 'VENDA'
    WHEN categoria_conversao IN ('STORE_VISIT', 'GET_DIRECTIONS') THEN 'LOJA'
    WHEN categoria_conversao IN ('ADD_TO_CART', 'BEGIN_CHECKOUT', 'PAGE_VIEW', 'DOWNLOAD') THEN 'FUNIL'
    WHEN categoria_conversao IN ('ENGAGEMENT', 'YOUTUBE_FOLLOW_ON_VIEWS') THEN 'ENGAJAMENTO'
    ELSE 'INDEFINIDA'
  END                                                               AS classe_conversao,
  dias_com_linha_campanha,
  conversoes_campanha, todas_conversoes_campanha, valor_campanha, conversoes_por_data_conversao_campanha,
  qtd_anuncios, conversoes_anuncio, todas_conversoes_anuncio, valor_anuncio,
  -- REGRA 3 - os dois graos NAO somam o mesmo nesta conta (campanha 335,00 contra anuncio 7.773,27 de conversoes): a flag marca, nao corrige, e nunca some campanha com anuncio.
  (ABS(IFNULL(conversoes_campanha, 0) - IFNULL(conversoes_anuncio, 0)) > 0.01
   OR ABS(IFNULL(todas_conversoes_campanha, 0) - IFNULL(todas_conversoes_anuncio, 0)) > 0.01) AS flag_graos_divergem,
  flag_so_em_grao_anuncio,
  flag_so_em_grao_campanha,
  CURRENT_TIMESTAMP()                                               AS _extraido_at,
  'trs_google_ads__conversao_acao_{campanha,anuncio}_prestex'       AS _fonte
FROM juntas
