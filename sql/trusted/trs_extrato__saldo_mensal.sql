-- trs_extrato__saldo_mensal
-- Trusted / Financeiro (extrato bancario). Grao: uma CONTA em um PERIODO (mes). Chave: (conta_ref, periodo).
-- Nivel: L3 CONFIDENTIAL (saldo bancario da casa). Sem dado pessoal.
--
-- ORIGEM. supabase_silver_eb_saldo (48 linhas: saldo 'anterior' e 'final' por arquivo) agregado por (conta_ref, periodo)
-- e cruzado com a soma dos lancamentos de supabase_silver_eb_lancamento. bronze_extrato_bancario__saldo (48/48) e
-- a mesma extracao e nao foi usado. Medido em 18/10/2026: 27 pares (conta, periodo), 6 contas.
--
-- IDENTIDADE CONTABIL (a regra que justifica a tabela): saldo_anterior + movimento = saldo_final.
-- Medida: dos 20 pares com os dois saldos e o movimento, 19 fecham ao centavo (diferenca zero). Nao fecha so
-- itau_brm 2026-07 (R$ -765,46). 6 pares tem saldo anterior ou final ausente (flag_saldo_incompleto) e nao entram na
-- identidade: nubank_brm 2026-01 e 2026-06, ca_ip_brm 2026-01 e 2026-08, ca_ip_vd 2026-06 e 2026-08.
-- flag_nao_fecha marca so os pares avaliaveis; nada e corrigido.
--
-- bb_brm tem saldo zero e movimento liquido zero em todos os meses (conta de passagem com aplicacao e resgate automaticos):
-- e zero real, nao ausencia.
--
-- LIMITACAO -- NAO CONTORNE: movimento = soma dos lancamentos ingeridos do mes; mes sem arquivo de lancamento
-- (bb_brm 2026-05) tem movimento NULL, nao zero. Nubank e Conta Azul IP so tem arquivos em parte dos meses.
WITH s AS (
  SELECT conta_ref, periodo, ANY_VALUE(empresa) AS empresa,
         MAX(IF(tipo = 'anterior', valor, NULL))    AS saldo_anterior,
         MAX(IF(tipo = 'final', valor, NULL))       AS saldo_final,
         MAX(IF(tipo = 'anterior', data_ref, NULL)) AS data_saldo_anterior,
         MAX(IF(tipo = 'final', data_ref, NULL))    AS data_saldo_final,
         ANY_VALUE(arquivo) AS arquivo,
         MAX(fetched_at) AS lido_em
  FROM `vanguardamartech_raw`.`supabase_silver_eb_saldo`
  GROUP BY conta_ref, periodo
),
l AS (
  SELECT conta_ref, periodo, ROUND(SUM(valor), 2) AS movimento, COUNT(*) AS qtd_lancamentos
  FROM `vanguardamartech_raw`.`supabase_silver_eb_lancamento`
  GROUP BY conta_ref, periodo
)
SELECT
  CONCAT(s.conta_ref, '|', s.periodo)                                   AS id_chave,
  s.conta_ref,
  s.empresa,
  s.periodo,
  s.saldo_anterior,
  s.saldo_final,
  s.data_saldo_anterior,
  s.data_saldo_final,
  l.movimento,
  IFNULL(l.qtd_lancamentos, 0)                                          AS qtd_lancamentos,
  IF(s.saldo_anterior IS NOT NULL AND s.saldo_final IS NOT NULL AND l.movimento IS NOT NULL,
     ROUND(s.saldo_anterior + l.movimento - s.saldo_final, 2), NULL)    AS diferenca_identidade,
  (s.saldo_anterior IS NOT NULL AND s.saldo_final IS NOT NULL AND l.movimento IS NOT NULL
     AND ABS(s.saldo_anterior + l.movimento - s.saldo_final) > 0.01)    AS flag_nao_fecha,
  (s.saldo_anterior IS NULL OR s.saldo_final IS NULL)                   AS flag_saldo_incompleto,
  s.arquivo,
  DATE(s.lido_em, 'America/Sao_Paulo')                                  AS arquivo_lido_em,
  CURRENT_TIMESTAMP()                                                   AS _extraido_at,
  'supabase-x0tz'                                                       AS _fonte,
  'America/Sao_Paulo'                                                   AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(s)))                                        AS _payload_hash
FROM s
LEFT JOIN l ON l.conta_ref = s.conta_ref AND l.periodo = s.periodo
