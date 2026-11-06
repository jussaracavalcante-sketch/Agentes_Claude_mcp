-- rfn_operacao__troca_analista_parcela_mensal  (query-2MQf)
-- Refined / operacao, L2, gatilho de evento em query-4eMU (trs_vjob__parcela_analista_alteracao). Grao: mes da troca (fluxo, nao estado).
-- A janela do log e de dois meses e cobre 2,2% das parcelas: ausencia de troca nao e permanencia do analista.
-- Medido em 06/10/2026: 3 meses, 286 trocas, 221 parcelas distintas, 43 parcelas nao catalogadas, zero sem efeito.
SELECT
  DATE_TRUNC(DATE(alterado_em), MONTH) AS mes_referencia,
  COUNT(*) AS qtd_alteracoes,
  COUNTIF(NOT flag_sem_efeito AND NOT flag_entrada_sem_anterior) AS qtd_trocas,
  COUNTIF(flag_sem_efeito) AS qtd_sem_efeito,
  COUNTIF(flag_entrada_sem_anterior) AS qtd_entradas_sem_anterior,
  COUNT(DISTINCT id_parcela) AS qtd_parcelas_distintas,
  COUNT(DISTINCT id_alterado_por) AS qtd_pessoas_que_alteraram,
  COUNT(DISTINCT id_analista_novo) AS qtd_analistas_que_receberam,
  COUNT(DISTINCT id_analista_anterior) AS qtd_analistas_que_sairam,
  COUNTIF(flag_parcela_nao_catalogada) AS qtd_parcela_nao_catalogada,
  COUNTIF(flag_contrato_diverge_da_parcela) AS qtd_contrato_diverge,
  MAX(qtd_trocas_na_parcela) AS max_trocas_na_mesma_parcela,
  CURRENT_TIMESTAMP() AS _extraido_at,
  MAX(_extraido_at) AS _extraido_trusted
FROM `vanguardamartech_trusted`.`trs_vjob__parcela_analista_alteracao`
GROUP BY 1
