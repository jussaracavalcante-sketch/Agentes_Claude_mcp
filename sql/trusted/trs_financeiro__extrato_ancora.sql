-- trs_financeiro__extrato_ancora
-- Trusted / Financeiro. Grao: uma ANCORA DE SALDO de extrato bancario (saldo anterior ou final declarado por um arquivo importado) de uma conta, enriquecida com o de-para da conta.
-- Chave: id_ancora = <conta_ref>|<arquivo>|<tipo> (48 linhas, 48 chaves; tambem unico por conta_ref x data_ref x tipo; medido em 2026-10-19).
-- Origens (fonte supabase-x0tz, diaria): supabase_gold_vw_eb_ancora_saldo (48) + supabase_meta_eb_conta_depara (6 contas; as 6 casam, zero ancora sem de-para).
--   Cadencia desta Trusted: semanal (segunda 06:55 America/Manaus).
-- Nivel: L3 CONFIDENTIAL (saldo bancario, agencia e numero da conta).
-- MEDIDO (2026-10-19): 6 contas (bb_brm, itau_brm, nubank_brm, ca_ip_brm, ca_ip_vd, itau_vd) · 24 arquivos · 2025-12-31 a 2026-08-06 · 3 ancoras de virada
--   (is_ancora_virada) · 17 ancoras com valor ZERO (as 14 do bb_brm e as de ca_ip_vd: conta sem saldo, nao sentinela - fica 0) · soma R$ 569.622,12 ·
--   as 48 casam com trs_financeiro__extrato_conta_mes por (conta_ref, mes da data_ref): esta tabela e o detalhe de origem daquele saldo.
-- LIMITACOES - NAO CONTORNE: saldo declarado pelo arquivo, nao calculado (a conferencia saldo declarado x calculado esta em trs_financeiro__extrato_conta_mes);
--   `anterior` e `final` do MESMO arquivo nao se somam; cobre 2025-12 a 2026-08 e so as 6 contas com extrato importado.
WITH a AS (
  SELECT * FROM `vanguardamartech_raw`.`supabase_gold_vw_eb_ancora_saldo`
),
d AS (
  SELECT * FROM `vanguardamartech_raw`.`supabase_meta_eb_conta_depara`
),
final AS (
  SELECT
    CONCAT(a.conta_ref, '|', a.arquivo, '|', a.tipo)                 AS id_ancora,
    a.conta_ref,
    a.empresa                                                        AS operacao,
    NULLIF(TRIM(a.nome_conta_ca), '')                                AS nome_conta_ca,
    a.data_ref,
    DATE_TRUNC(a.data_ref, MONTH)                                    AS mes_referencia,
    a.tipo                                                           AS tipo_ancora,
    (a.tipo = 'anterior')                                            AS is_saldo_anterior,
    (a.tipo = 'final')                                               AS is_saldo_final,
    a.valor                                                          AS saldo,
    (a.valor = 0)                                                    AS flag_saldo_zero,
    a.arquivo,
    a.is_ancora_virada,
    d.layout,
    d.agencia,
    d.conta_numero,
    d.fonte_banco,
    d.ativo                                                          AS is_conta_ativa,
    (d.conta_ref IS NULL)                                            AS flag_conta_sem_depara
  FROM a
  LEFT JOIN d ON d.conta_ref = a.conta_ref
)
SELECT
  f.*,
  'L3_CONFIDENTIAL'                  AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
