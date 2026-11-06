-- trs_financeiro__extrato_conta_mes
-- Trusted / Financeiro. Grao: uma conta bancaria (conta_ref) em um mes (periodo). Junta o resumo do EXTRATO BANCARIO importado de arquivo
-- (vw_eb_extrato_mes, 35 linhas) com o saldo de fim de mes e a cobertura da conta (vw_eb_saldo_conta_mes, 41 linhas): 41 linhas, 41 chaves,
-- 6 contas, 2025-12 a 2026-08 (medido em 2026-10-18); 35 com extrato e saldo, 6 so com saldo.
-- Origem: vanguardamartech_raw.supabase_gold_vw_eb_extrato_mes e _saldo_conta_mes (fonte supabase-x0tz). Nivel: L3 CONFIDENTIAL (saldo bancario).
-- E o unico caixa BANCARIO desta casa (vem do extrato, nao do razao): serve de conferencia do caixa do Conta Azul. dw_caixa_mes, recon_ca e dfc_ancora sao
-- derivadas dele cruzado com o razao e nao foram tratadas.
-- saldo_fim_mes (da origem de saldo) e saldo_final_calc (anterior + liquido do extrato) coincidem em 26 das 35 linhas com os dois; as outras 9 ficam visiveis.
-- mes_completo = a cobertura da conta alcanca o fim do mes (36 de 41).
SELECT
  CONCAT(IFNULL(e.conta_ref, s.conta_ref), '|', IFNULL(e.periodo, s.periodo))   AS id_conta_periodo,
  IFNULL(e.conta_ref, s.conta_ref)                                              AS conta_ref,
  IFNULL(e.empresa, s.empresa)                                                  AS empresa,
  IFNULL(e.nome_conta_ca, s.nome_conta_ca)                                      AS nome_conta_ca,
  IFNULL(e.periodo, s.periodo)                                                  AS periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(IFNULL(e.periodo, s.periodo), '-01'))      AS mes_referencia,
  e.saldo_anterior,
  e.entradas,
  e.saidas,
  e.liquido,
  e.saldo_final_calc,
  e.n_lancamentos,
  s.saldo_fim_mes,
  s.cobertura_conta,
  s.mes_completo                                                                AS is_mes_completo,
  (e.conta_ref IS NOT NULL)                                                     AS tem_extrato,
  (s.conta_ref IS NOT NULL)                                                     AS tem_saldo,
  'L3_CONFIDENTIAL'                                                             AS classificacao_dado,
  CURRENT_TIMESTAMP()                                                           AS _extraido_at,
  'supabase-x0tz'                                                               AS _fonte,
  TO_HEX(MD5(CONCAT(IFNULL(TO_JSON_STRING(e), ''), '|', IFNULL(TO_JSON_STRING(s), ''))))   AS _payload_hash
FROM vanguardamartech_raw.supabase_gold_vw_eb_extrato_mes e
FULL JOIN vanguardamartech_raw.supabase_gold_vw_eb_saldo_conta_mes s
  ON e.conta_ref = s.conta_ref AND e.periodo = s.periodo
