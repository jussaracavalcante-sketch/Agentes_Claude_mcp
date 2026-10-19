-- trs_financeiro__mrr_projetado
-- Trusted / Financeiro. Grao: uma operacao em um mes - MRR PROJETADO pelo Supabase a partir das parcelas recorrentes do Conta Azul.
-- Chave: id_mrr_mes = <operacao>|<mes> (41 linhas, 41 chaves; medido em 2026-10-19).
-- Origem: vanguardamartech_raw.supabase_conta_azul_vw_mrr_mensal (fonte supabase-x0tz, diaria). Cadencia desta Trusted: semanal (segunda 06:40 America/Manaus).
-- Nivel: L3 CONFIDENTIAL.
-- MEDIDO (2026-10-19): 2 operacoes (BRM, VD), 2026-06 a 2028-09 (31 meses posteriores a hoje) · SUM(mrr) R$ 10.624.390,80 · SUM(contratos_ativos) 1.001 ·
--   `arpa` = mrr / contratos_ativos em 41 de 41 (passa como a origem entrega; nao e recalculado).
-- O QUE ESTE MRR NAO E (declarado na triagem de 18/10 e mantido): NAO reproduz o snapshot de MRR do Conta Azul (trs_contazul__mrr_snapshot /
--   rfn_financeiro__contazul_mrr_mensal, R$ 4,29 mi) nem o movimento (BRM 2027-04: 293.393,49 aqui contra 311.714,00 e 290.119,21 das vendas). Sao TRES definicoes
--   de MRR com tres bases de calculo. Esta e a projecao do Supabase sobre parcela recorrente; use-a como tal e nunca some com as outras.
-- LIMITACOES - NAO CONTORNE: projecao, nao realizado; comeca em 2026-06 (handoff); cadencia semanal.
WITH origem AS (
  SELECT
    m.*,
    NULLIF(REGEXP_REPLACE(IFNULL(m.cnpj, ''), r'[^0-9]', ''), '')   AS cnpj_operacao_digitos
  FROM `vanguardamartech_raw`.`supabase_conta_azul_vw_mrr_mensal` m
),
final AS (
  SELECT
    CONCAT(operacao, '|', CAST(mes AS STRING))                      AS id_mrr_mes,
    operacao,
    cnpj_operacao_digitos                                           AS cnpj_operacao,
    mes                                                             AS mes_referencia,
    mrr,
    contratos_ativos,
    arpa,
    (contratos_ativos = 0)                                          AS flag_sem_contrato
  FROM origem
)
SELECT
  f.*,
  'L3_CONFIDENTIAL'                  AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
