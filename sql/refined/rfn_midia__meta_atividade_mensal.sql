-- rfn_midia__meta_atividade_mensal (Refined / midia) - 2026-10-18 | 2026-10-29: tipo update_budget_flex_toggle_status entra em ORCAMENTO (3 eventos, 2 contas; antes caia em OUTRO e acendia a regra tipo_de_evento_mapeado)
-- Grao: conta de anuncios x mes (data local Sao Paulo) x tipo de evento x moeda do evento financeiro. Chave id_atividade_mensal.
-- Le trs_facebook_ads__atividade_conta (L4) e a dimensao trs_facebook_ads__conta. Nivel L2: NAO emite ator_id, ator_nome nem detalhe_json;
-- do ator so passa a CONTAGEM de atores distintos. Gatilho: evento na Trusted de atividade (query-VBXA).
WITH ev AS (
  SELECT
    a.id_conta,
    DATE_TRUNC(a.data_local, MONTH) AS mes_referencia,
    a.tipo_evento,
    CASE
      WHEN a.tipo_evento IN ('update_ad_run_status', 'update_ad_set_run_status', 'update_campaign_run_status', 'update_ad_run_status_to_be_set_after_review') THEN 'STATUS'
      WHEN a.tipo_evento = 'first_delivery_event' THEN 'ENTREGA'
      WHEN a.tipo_evento IN ('create_ad', 'create_ad_set', 'create_campaign_group') THEN 'CRIACAO'
      WHEN a.tipo_evento IN ('update_ad_set_budget', 'update_campaign_budget', 'update_campaign_budget_scheduling_state', 'update_campaign_group_budget_scheduling_state', 'update_ad_set_duration', 'update_budget_flex_toggle_status') THEN 'ORCAMENTO'
      WHEN a.tipo_evento IN ('update_ad_set_target_spec', 'update_ad_targets_spec') THEN 'SEGMENTACAO'
      WHEN a.tipo_evento IN ('update_ad_set_bid_strategy', 'update_ad_set_optimization_goal') THEN 'LANCE_OTIMIZACAO'
      WHEN a.tipo_evento IN ('update_ad_set_name', 'update_campaign_name', 'update_ad_friendly_name') THEN 'NOME'
      WHEN a.tipo_evento IN ('update_ad_creative', 'add_images', 'edit_images') THEN 'CRIATIVO'
      WHEN a.tipo_evento IN ('create_audience', 'update_audience', 'delete_audience') THEN 'PUBLICO'
      WHEN a.tipo_evento IN ('ad_account_billing_charge', 'ad_account_billing_refund', 'funding_event_successful') THEN 'COBRANCA'
      WHEN a.tipo_evento IN ('ad_account_add_user_to_role', 'ad_account_remove_user_from_role') THEN 'ACESSO'
      WHEN a.tipo_evento = 'ad_account_update_status' THEN 'CONTA'
      ELSE 'OUTRO'
    END AS grupo_evento,
    a.financeiro_moeda,
    a.flag_ator_sistema, a.ator_id, a.data_local, a.ocorrido_em, a.id_campanha_no_detalhe,
    a.flag_evento_financeiro, a.financeiro_valor_unidade_menor, a._extraido_at
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__atividade_conta` a
),
agg AS (
  SELECT
    id_conta, mes_referencia, tipo_evento, ANY_VALUE(grupo_evento) AS grupo_evento, financeiro_moeda,
    COUNT(*) AS qtd_eventos,
    COUNTIF(flag_ator_sistema) AS qtd_eventos_de_sistema,
    COUNTIF(NOT flag_ator_sistema) AS qtd_eventos_de_pessoa,
    COUNT(DISTINCT ator_id) AS qtd_atores_distintos,
    COUNT(DISTINCT data_local) AS qtd_dias_com_evento,
    MIN(ocorrido_em) AS primeiro_evento_em, MAX(ocorrido_em) AS ultimo_evento_em,
    COUNTIF(id_campanha_no_detalhe IS NOT NULL) AS qtd_eventos_com_campanha,
    COUNT(DISTINCT id_campanha_no_detalhe) AS qtd_campanhas_distintas_no_detalhe,
    COUNTIF(flag_evento_financeiro) AS qtd_eventos_financeiros,
    COUNTIF(financeiro_valor_unidade_menor IS NOT NULL) AS qtd_eventos_financeiros_com_valor,
    SUM(financeiro_valor_unidade_menor) AS soma_valor_unidade_menor,
    MAX(DATE(_extraido_at, 'America/Sao_Paulo')) AS data_da_carga
  FROM ev
  GROUP BY id_conta, mes_referencia, tipo_evento, financeiro_moeda
),
res AS (
SELECT
  CONCAT(g.id_conta, '|', FORMAT_DATE('%Y%m', g.mes_referencia), '|', g.tipo_evento, '|', IFNULL(g.financeiro_moeda, '-')) AS id_atividade_mensal,
  g.id_conta, d.conta, d.moeda AS moeda_conta, d.fuso_conta,
  (d.id_conta IS NULL) AS flag_conta_nao_catalogada,
  g.mes_referencia, g.tipo_evento, g.grupo_evento,
  (g.grupo_evento = 'OUTRO') AS flag_tipo_nao_mapeado,
  g.financeiro_moeda,
  g.qtd_eventos, g.qtd_eventos_de_sistema, g.qtd_eventos_de_pessoa, g.qtd_atores_distintos,
  g.qtd_dias_com_evento, g.primeiro_evento_em, g.ultimo_evento_em,
  g.qtd_eventos_com_campanha, g.qtd_campanhas_distintas_no_detalhe,
  g.qtd_eventos_financeiros, g.qtd_eventos_financeiros_com_valor, g.soma_valor_unidade_menor,
  (g.mes_referencia = DATE_TRUNC(g.data_da_carga, MONTH)) AS flag_mes_parcial_na_carga,
  CURRENT_TIMESTAMP() AS _extraido_at
FROM agg g
LEFT JOIN `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conta` d ON d.id_conta = g.id_conta
)
SELECT * FROM res
