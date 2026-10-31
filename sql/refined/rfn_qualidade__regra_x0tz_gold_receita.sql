-- rfn_qualidade__regra_x0tz_gold_receita  ·  12 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra. Gatilho: cron semanal segunda 08:05 America/Manaus (depois das Trusted de segunda 06:00 e
-- das Refined em cadeia de evento; gate de pos-carga). Irma pequena da rfn_qualidade__regra_x0tz_gold (64 regras, 40 KB): nasceu separada pelo motivo que a casa ja registrou
-- (update_transformation substitui o codigo inteiro).
-- Cobre 2 Trusted e 2 Refined: trs_financeiro__faturamento (query-AnwZ), trs_financeiro__receita_cliente (query-Garx), rfn_financeiro__faturamento_mensal (query-ANsN),
-- rfn_financeiro__receita_tipo_mensal (query-BolY). 4 chaves unicas + 4 identidades Trusted x Refined + 4 de validade (pago + sem baixa = valor; tipo_receita conhecido;
-- documento com 14 ou 11 digitos; is_pago concorda com a data).
-- VALIDACAO (18/10/2026, tabelas ainda nao materializadas: codigo das Trusted e Refined INLINE sobre a Raw): 12 de 12 CONFORME. Esperado na primeira execucao real: 12 conformes.
WITH
r_fx AS (
-- FATURAMENTO E RECEITA POR CLIENTE (2 Trusted + 2 Refined)
  SELECT 'trs_financeiro__faturamento.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_financeiro__faturamento' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_linha) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_linha) + COUNTIF(id_linha IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_financeiro__faturamento`

  UNION ALL
  SELECT 'trs_financeiro__receita_cliente.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_financeiro__receita_cliente' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_linha) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_linha) + COUNTIF(id_linha IS NULL) AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_financeiro__receita_cliente`

  UNION ALL
  SELECT 'rfn_financeiro__faturamento_mensal.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__faturamento_mensal' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_faturamento_mensal) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_faturamento_mensal) + COUNTIF(id_faturamento_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__faturamento_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__receita_tipo_mensal.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_financeiro__receita_tipo_mensal' AS tabela, 'Financeiro' AS sistema, 'UNICIDADE' AS dimensao,
         'a chave (id_receita_tipo_mensal) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_receita_tipo_mensal) + COUNTIF(id_receita_tipo_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_tipo_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__faturamento_mensal.titulos_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__faturamento_mensal', 'Financeiro', 'VALIDADE',
         'a soma de qtd_titulos reproduz os titulos da Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(qtd_titulos) FROM `vanguardamartech_refined`.`rfn_financeiro__faturamento_mensal`), 0) - IFNULL((SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_financeiro__faturamento`), 0)) <= 0, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__faturamento_mensal.valor_reproduz_a_trusted', 'Refined', 'rfn_financeiro__faturamento_mensal', 'Financeiro', 'VALIDADE',
         'a soma de valor reproduz o valor da Trusted (um centavo)', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(valor) FROM `vanguardamartech_refined`.`rfn_financeiro__faturamento_mensal`), 0) - IFNULL((SELECT SUM(valor) FROM `vanguardamartech_trusted`.`trs_financeiro__faturamento`), 0)) <= 0.01, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__receita_tipo_mensal.lancamentos_reproduzem_a_trusted', 'Refined', 'rfn_financeiro__receita_tipo_mensal', 'Financeiro', 'VALIDADE',
         'a soma de qtd_lancamentos reproduz os lancamentos da Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(qtd_lancamentos) FROM `vanguardamartech_refined`.`rfn_financeiro__receita_tipo_mensal`), 0) - IFNULL((SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_financeiro__receita_cliente`), 0)) <= 0, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__receita_tipo_mensal.valor_reproduz_a_trusted', 'Refined', 'rfn_financeiro__receita_tipo_mensal', 'Financeiro', 'VALIDADE',
         'a soma de valor reproduz o valor da Trusted (um centavo)', 'BLOQUEANTE', 1.00,
         1,
         IF(ABS(IFNULL((SELECT SUM(valor) FROM `vanguardamartech_refined`.`rfn_financeiro__receita_tipo_mensal`), 0) - IFNULL((SELECT SUM(valor) FROM `vanguardamartech_trusted`.`trs_financeiro__receita_cliente`), 0)) <= 0.01, 0, 1)

  UNION ALL
  SELECT 'rfn_financeiro__faturamento_mensal.pago_mais_sem_baixa_e_o_valor', 'Refined', 'rfn_financeiro__faturamento_mensal', 'Financeiro', 'VALIDADE',
         'em cada linha valor_pago mais valor_sem_baixa reproduz o valor (um centavo)', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(ABS(IFNULL(valor_pago, 0) + IFNULL(valor_sem_baixa, 0) - IFNULL(valor, 0)) > 0.01)
  FROM `vanguardamartech_refined`.`rfn_financeiro__faturamento_mensal`

  UNION ALL
  SELECT 'trs_financeiro__receita_cliente.tipo_receita_conhecido', 'Trusted', 'trs_financeiro__receita_cliente', 'Financeiro', 'VALIDADE',
         'tipo_receita e CLIENTE, BV ou CONTA_ORDEM (o BV so e separavel por aqui)', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(tipo_receita IS NULL OR tipo_receita NOT IN ('CLIENTE', 'BV', 'CONTA_ORDEM'))
  FROM `vanguardamartech_trusted`.`trs_financeiro__receita_cliente`

  UNION ALL
  SELECT 'trs_financeiro__receita_cliente.documento_tem_forma', 'Trusted', 'trs_financeiro__receita_cliente', 'Financeiro', 'VALIDADE',
         'documento preenchido tem 14 (CNPJ) ou 11 (CPF) digitos', 'BLOQUEANTE', 1.00,
         COUNTIF(documento IS NOT NULL),
         COUNTIF(documento IS NOT NULL AND LENGTH(documento) NOT IN (11, 14))
  FROM `vanguardamartech_trusted`.`trs_financeiro__receita_cliente`

  UNION ALL
  SELECT 'trs_financeiro__faturamento.pago_concorda_com_a_data', 'Trusted', 'trs_financeiro__faturamento', 'Financeiro', 'VALIDADE',
         'is_pago e exatamente data_pagamento preenchida', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(is_pago <> (data_pagamento IS NOT NULL))
  FROM `vanguardamartech_trusted`.`trs_financeiro__faturamento`
),
todas AS (
  SELECT * FROM r_fx
),
avaliado AS (
  SELECT
    t.*,
    (t.linhas_avaliadas - t.linhas_falha)                       AS linhas_conformes,
    SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, NULLIF(t.linhas_avaliadas, 0))
                                                                AS taxa_conformidade,
    IF(t.linhas_avaliadas = 0, NULL,
       SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, t.linhas_avaliadas) >= t.limiar)
                                                                AS is_conforme,
    (t.linhas_avaliadas = 0)                                    AS flag_sem_linha_para_avaliar
  FROM todas t
),
final AS (
  SELECT
    a.*,
    CASE
      WHEN a.flag_sem_linha_para_avaliar          THEN 'SEM_DADO'
      WHEN a.is_conforme                          THEN 'CONFORME'
      WHEN a.severidade = 'BLOQUEANTE'            THEN 'FALHA_BLOQUEANTE'
      ELSE                                             'FALHA_ALERTA'
    END                                           AS resultado,
    'X0TZ_GOLD'                                   AS familia,
    CURRENT_TIMESTAMP()                           AS _extraido_at,
    'multiplas'                                   AS _fonte,
    'America/Sao_Paulo'                           AS _fuso,
    TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
  FROM avaliado a
)
SELECT * FROM final
