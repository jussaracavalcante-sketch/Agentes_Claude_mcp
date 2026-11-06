-- rfn_financeiro__extrato_saldo_mensal  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (saldo bancario da casa por empresa e mes; sem dado pessoal)
-- Grao: PERIODO (mes, texto 'AAAA-MM') x empresa (BRM | VD), somando as contas bancarias do extrato.
-- Le: trs_extrato__saldo_mensal (query-59n3). Gatilho: evento em query-59n3.
-- Identidade (19/10/2026): 27 pares (conta, periodo) = 27 · 6 contas · 3.841 lancamentos · movimento R$ -107.705,79 · 1 par nao fecha (itau_brm 2026-07, R$ -765,46) · 6 pares com saldo incompleto.
-- R1 saldo_anterior e saldo_final so se somam entre contas que TEM o saldo: qtd_contas_com_saldo_completo diz quantas entraram na soma; a conta sem saldo
--    (flag_saldo_incompleto) conta em qtd_contas e nao na soma -- comparar saldo entre meses com qtd diferente e comparar contas diferentes.
-- R2 movimento = soma dos lancamentos ingeridos no mes; mes sem arquivo tem movimento NULL (bb_brm 2026-05), nunca zero: qtd_contas_sem_movimento mostra.
-- R3 A identidade saldo_anterior + movimento = saldo_final e reproduzida por par na Trusted; aqui `diferenca_identidade` e a soma das diferencas dos pares avaliaveis e
--    qtd_pares_nao_fecha conta quantos falharam. bb_brm tem saldo zero e movimento zero em todo mes: e zero real (conta de passagem), nao ausencia.
-- LIMITACAO -- NAO CONTORNE: cobertura desigual por conta (nubank e Conta Azul IP so em parte dos meses: 2 periodos cada); 2026-08 tem so 2 contas. Nao e caixa realizado
--    (ver rfn_financeiro__fluxo_caixa) e nao soma com sweep nem transferencia, que ja estao DENTRO dos lancamentos.
WITH s AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_extrato__saldo_mensal`
),
agg AS (
  SELECT
    periodo,
    empresa,
    COUNT(*)                                                   AS qtd_contas,
    COUNTIF(NOT flag_saldo_incompleto)                         AS qtd_contas_com_saldo_completo,
    COUNTIF(movimento IS NULL)                                 AS qtd_contas_sem_movimento,
    ROUND(SUM(IF(NOT flag_saldo_incompleto, saldo_anterior, NULL)), 2) AS saldo_anterior,
    ROUND(SUM(IF(NOT flag_saldo_incompleto, saldo_final, NULL)), 2)    AS saldo_final,
    ROUND(SUM(movimento), 2)                                   AS movimento,
    SUM(qtd_lancamentos)                                       AS qtd_lancamentos,
    COUNTIF(flag_nao_fecha)                                    AS qtd_pares_nao_fecha,
    ROUND(SUM(diferenca_identidade), 2)                        AS diferenca_identidade,
    MAX(arquivo_lido_em)                                       AS arquivo_lido_em
  FROM s
  GROUP BY periodo, empresa
),
final AS (
  SELECT CONCAT(periodo, '|', empresa) AS id_extrato_mensal, g.*, 'L3_CONFIDENTIAL' AS classificacao_dado FROM agg g
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
