-- rfn_operacao__job_prazo_mensal  (query-9pj3)
-- Refined / operacao, L2, gatilho de evento em query-l08y (trs_vjob__job_prazo_alteracao).
-- Grao: mes da ALTERACAO x origem. Fluxo de alteracoes, nao coorte de jobs.
-- O VJOB grava hora local: DATE(alterado_em) sem conversao de fuso.
-- Medido em 06/10/2026: 21 linhas, 267 alteracoes, 253 adiamentos, 14 antecipacoes.
SELECT
  DATE_TRUNC(DATE(alterado_em), MONTH) AS mes_referencia,
  origem,
  COUNT(*) AS qtd_alteracoes,
  COUNT(DISTINCT id_job_unico) AS qtd_jobs_distintos,
  COUNTIF(is_adiamento) AS qtd_adiamentos,
  COUNTIF(is_antecipacao) AS qtd_antecipacoes,
  COUNTIF(NOT is_adiamento AND NOT is_antecipacao) AS qtd_sem_deslocamento,
  SUM(IF(is_adiamento, dias_deslocados, NULL)) AS soma_dias_adiados,
  AVG(IF(is_adiamento, dias_deslocados, NULL)) AS adiamento_medio_dias,
  MAX(IF(is_adiamento, dias_deslocados, NULL)) AS adiamento_max_dias,
  COUNT(DISTINCT id_alterado_por) AS qtd_pessoas,
  COUNTIF(flag_job_nao_catalogado) AS qtd_job_nao_catalogado,
  CURRENT_TIMESTAMP() AS _extraido_at,
  MAX(_extraido_at) AS _extraido_trusted
FROM `vanguardamartech_trusted`.`trs_vjob__job_prazo_alteracao`
GROUP BY 1, 2
