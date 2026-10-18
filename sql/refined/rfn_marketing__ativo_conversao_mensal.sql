-- slug no deploy: query-e19u (esta linha existe so no arquivo)
-- Refined Marketing - conversao por ativo de captura por mes (RD Station). L2 INTERNAL. Grao: mes x _fonte x tipo de ativo.
-- Validado 18/10/2026 sobre a Raw em 12 fontes: 76.781 -> 113 linhas, visitas 35.303 = canonico, conversoes 7.142. O rotulo AMBIGUO foi acrescentado depois da validacao.
WITH ca AS (
  SELECT t.*,
    COUNT(*) OVER (PARTITION BY id_ativo_origem, data_referencia) AS qtd_linhas_do_ativo_dia
  FROM `vanguardamartech_trusted`.`trs_rd_station__ativo_conversao_dia` t
),
c AS (
  SELECT * FROM ca
  QUALIFY ROW_NUMBER() OVER (PARTITION BY id_ativo_origem, data_referencia ORDER BY qtd_visitas DESC, qtd_conversoes DESC, _fonte) = 1
),
cap AS (
  SELECT
    _fonte,
    identificador_conversao,
    MIN(tipo_ativo) AS tipo_ativo,
    COUNT(DISTINCT tipo_ativo) AS qtd_tipos
  FROM `vanguardamartech_trusted`.`trs_rd_station__captura`
  WHERE identificador_conversao IS NOT NULL
  GROUP BY _fonte, identificador_conversao
),
j AS (
  SELECT c.*, IF(cap.qtd_tipos > 1, 'AMBIGUO', cap.tipo_ativo) AS tipo_ativo, cap.qtd_tipos
  FROM c LEFT JOIN cap ON cap._fonte = c._fonte AND cap.identificador_conversao = c.identificador_ativo
),
m AS (
  SELECT
    mes_referencia,
    _fonte,
    cliente,
    IFNULL(tipo_ativo, 'NAO_CATALOGADO') AS tipo_ativo,
    COUNT(DISTINCT id_ativo_origem) AS qtd_ativos_listados,
    COUNT(DISTINCT IF(NOT flag_sem_atividade, id_ativo_origem, NULL)) AS qtd_ativos_com_atividade,
    SUM(qtd_visitas) AS qtd_visitas,
    SUM(qtd_conversoes) AS qtd_conversoes,
    COUNTIF(flag_conversoes_maior_que_visitas) AS qtd_linhas_conversoes_maior_que_visitas,
    COUNTIF(flag_janela_parcial) AS qtd_linhas_janela_parcial,
    COUNTIF(qtd_tipos > 1) AS qtd_linhas_tipo_ambiguo,
    SUM(qtd_linhas_do_ativo_dia - 1) AS qtd_linhas_duplicadas_removidas
  FROM j
  GROUP BY mes_referencia, _fonte, cliente, IFNULL(tipo_ativo, 'NAO_CATALOGADO')
)
SELECT
  CONCAT(CAST(mes_referencia AS STRING),'|',_fonte,'|',tipo_ativo) AS id_ativo_mensal,
  mes_referencia,
  _fonte,
  cliente,
  tipo_ativo,
  qtd_ativos_listados,
  qtd_ativos_com_atividade,
  qtd_visitas,
  qtd_conversoes,
  SAFE_DIVIDE(qtd_conversoes, qtd_visitas) AS taxa_conversao,
  qtd_linhas_conversoes_maior_que_visitas,
  qtd_linhas_janela_parcial,
  qtd_linhas_tipo_ambiguo,
  qtd_linhas_duplicadas_removidas,
  CURRENT_TIMESTAMP() AS _extraido_at
FROM m
