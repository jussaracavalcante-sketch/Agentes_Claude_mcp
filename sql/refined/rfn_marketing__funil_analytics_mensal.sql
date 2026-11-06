-- slug no deploy: query-QYE9 (esta linha existe so no arquivo)
-- Refined Marketing - funil do relatorio da RD por mes (stream analytics_funnel). L2 INTERNAL. Grao: mes x _fonte.
-- NAO e rfn_marketing__funil_mensal (query-9pcn). Validado 18/10/2026 sobre as 5 fontes (populacao completa): 1.538 dias -> 55 linhas, 47 retratos duplicados removidos.
WITH f AS (
  SELECT t.*,
    COUNT(*) OVER (PARTITION BY _fonte) AS qtd_dias_da_fonte
  FROM `vanguardamartech_trusted`.`trs_rd_station__funil_dia` t
),
c AS (
  SELECT * FROM f
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY data_referencia, qtd_visitantes, qtd_leads, qtd_leads_qualificados, qtd_oportunidades, qtd_vendas,
                 IF(flag_dia_sem_atividade, _fonte, '')
    ORDER BY qtd_dias_da_fonte DESC, _fonte) = 1
),
m AS (
  SELECT
    mes_referencia,
    _fonte,
    cliente,
    COUNT(*) AS qtd_dias,
    COUNTIF(NOT flag_dia_sem_atividade) AS qtd_dias_com_atividade,
    SUM(IF(NOT flag_dia_sem_atividade, qtd_fontes_com_mesmo_retrato - 1, 0)) AS qtd_retratos_duplicados_removidos,
    SUM(qtd_visitantes) AS qtd_visitantes,
    SUM(qtd_leads) AS qtd_leads,
    SUM(qtd_leads_qualificados) AS qtd_leads_qualificados,
    SUM(qtd_oportunidades) AS qtd_oportunidades,
    SUM(qtd_vendas) AS qtd_vendas,
    COUNTIF(flag_qualificados_maior_que_leads) AS qtd_dias_qualificados_maior_que_leads,
    COUNTIF(flag_oportunidades_maior_que_qualificados) AS qtd_dias_oportunidades_maior_que_qualificados,
    COUNTIF(flag_vendas_maior_que_oportunidades) AS qtd_dias_vendas_maior_que_oportunidades
  FROM c
  GROUP BY mes_referencia, _fonte, cliente
)
SELECT
  CONCAT(CAST(mes_referencia AS STRING),'|',_fonte) AS id_funil_mensal,
  mes_referencia,
  _fonte,
  cliente,
  qtd_dias,
  qtd_dias_com_atividade,
  qtd_retratos_duplicados_removidos,
  qtd_visitantes,
  qtd_leads,
  qtd_leads_qualificados,
  qtd_oportunidades,
  qtd_vendas,
  SAFE_DIVIDE(qtd_leads, qtd_visitantes) AS taxa_visitante_para_lead,
  SAFE_DIVIDE(qtd_leads_qualificados, qtd_leads) AS taxa_lead_para_qualificado,
  SAFE_DIVIDE(qtd_oportunidades, qtd_leads_qualificados) AS taxa_qualificado_para_oportunidade,
  SAFE_DIVIDE(qtd_vendas, qtd_oportunidades) AS taxa_oportunidade_para_venda,
  qtd_dias_qualificados_maior_que_leads,
  qtd_dias_oportunidades_maior_que_qualificados,
  qtd_dias_vendas_maior_que_oportunidades,
  CURRENT_TIMESTAMP() AS _extraido_at
FROM m
