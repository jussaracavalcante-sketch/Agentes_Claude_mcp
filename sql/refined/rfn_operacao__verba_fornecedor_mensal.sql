-- rfn_operacao__verba_fornecedor_mensal  (query-USve)
-- Refined / operacao, L3, gatilho de evento em query-erjG (trs_vjob__cronograma_verba).
-- Grao: competencia do contrato x fornecedor. A verba e a decomposicao do contrato por veiculo:
-- NAO soma com a parcela nem com o valor do contrato (duplicaria).
-- Medido em 06/10/2026: 18 linhas, 90 verbas, R$ 540.491,89 dos dois lados.
SELECT
  competencia_do_contrato AS mes_referencia,
  id_fornecedor,
  ARRAY_AGG(fornecedor_nome IGNORE NULLS ORDER BY atualizado_em DESC LIMIT 1)[SAFE_OFFSET(0)] AS fornecedor_nome,
  COUNT(*) AS qtd_verbas,
  COUNT(DISTINCT id_contrato) AS qtd_contratos,
  SUM(valor_verba) AS valor_verba,
  COUNTIF(flag_e_fornecedor_do_cabecalho) AS qtd_do_cabecalho,
  COUNTIF(flag_contrato_nao_catalogado) AS qtd_contrato_nao_catalogado,
  COUNTIF(flag_fornecedor_nao_catalogado) AS qtd_fornecedor_nao_catalogado,
  CURRENT_TIMESTAMP() AS _extraido_at,
  MAX(_extraido_at) AS _extraido_trusted
FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_verba`
GROUP BY 1, 2
