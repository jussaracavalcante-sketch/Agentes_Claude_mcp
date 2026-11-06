-- rfn_financeiro__caixa_bancario_mensal
-- Refined / financeiro. Grao: empresa x mes. Le trs_financeiro__extrato_conta_mes (extrato bancario importado de arquivo).
-- Nivel: L3 CONFIDENTIAL (saldo bancario agregado por empresa; nenhuma conta nominal atravessa).
-- REGRA 1: conta de PASSAGEM = conta cujo liquido e ~zero (|liquido| < R$ 1) em TODOS os meses com extrato (hoje bb_brm e ca_ip_vd): o dinheiro entra
--          e sai no mesmo mes (sweep). Entradas e saidas dela inflam o fluxo sem mudar o caixa; por isso as medidas vem em duas versoes:
--          com todas as contas e `_exceto_passagem`.
-- REGRA 2: saldo_final_calc = saldo anterior + liquido do extrato; saldo_fim_mes vem da origem de saldo e so existe onde ela cobre o mes. NAO se somam entre si.
-- REGRA 3: mes sem extrato (so saldo) tem entradas, saidas e liquido NULL, nunca zero; qtd_contas_com_extrato conta quem tem.
-- LIMITACOES - NAO CONTORNE: cobre 6 contas e 2025-12 a 2026-08; so BRM e VD; saldo de conta que ficou so com saldo nao tem entradas; nao soma
--   com rfn_financeiro__fluxo_caixa (outro regime de leitura do mesmo dinheiro: la a baixa do razao, aqui o banco).
WITH e AS (
  SELECT * FROM vanguardamartech_trusted.trs_financeiro__extrato_conta_mes
),
conta AS (
  SELECT conta_ref, LOGICAL_AND(ABS(IFNULL(liquido, 0)) < 1) AS is_conta_passagem
  FROM e
  WHERE tem_extrato
  GROUP BY conta_ref
)
SELECT
  CONCAT(e.empresa, '|', CAST(e.mes_referencia AS STRING))                       AS id_caixa_mensal,
  e.empresa,
  e.mes_referencia,
  COUNT(*)                                                                       AS qtd_contas,
  COUNTIF(e.tem_extrato)                                                         AS qtd_contas_com_extrato,
  COUNTIF(e.tem_extrato AND c.is_conta_passagem)                                 AS qtd_contas_passagem,
  COUNTIF(NOT IFNULL(e.is_mes_completo, FALSE))                                  AS qtd_contas_mes_incompleto,
  SUM(e.entradas)                                                                AS entradas,
  SUM(e.saidas)                                                                  AS saidas,
  SUM(e.liquido)                                                                 AS liquido,
  SUM(IF(c.is_conta_passagem, NULL, e.entradas))                                 AS entradas_exceto_passagem,
  SUM(IF(c.is_conta_passagem, NULL, e.saidas))                                   AS saidas_exceto_passagem,
  SUM(IF(c.is_conta_passagem, NULL, e.liquido))                                  AS liquido_exceto_passagem,
  SUM(e.saldo_final_calc)                                                        AS saldo_final_calc,
  SUM(e.saldo_fim_mes)                                                           AS saldo_fim_mes,
  SUM(e.n_lancamentos)                                                           AS n_lancamentos,
  'L3_CONFIDENTIAL'                                                              AS classificacao_dado,
  CURRENT_TIMESTAMP()                                                            AS _extraido_at,
  'supabase-x0tz'                                                                AS _fonte
FROM e
LEFT JOIN conta c ON c.conta_ref = e.conta_ref
GROUP BY e.empresa, e.mes_referencia
