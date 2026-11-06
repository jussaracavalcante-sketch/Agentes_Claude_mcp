-- rfn_financeiro__contazul_saldo_posicao_mensal  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (saldo e posicao a receber/pagar por empresa)
-- Grao: origem (SALDO_INICIAL | POSICAO_SNAPSHOT) x operacao x tipo x MES de referencia.
-- Le: trs_contazul__saldo_posicao (query-NMgm). Gatilho: evento em query-NMgm.
-- Identidade (19/10/2026): 34 linhas = 34 · saldo somado R$ 53.715.836,63 (16 SALDO_INICIAL = R$ 532.378,21; 18 POSICAO_SNAPSHOT = R$ 53.183.458,42) · 16 contas (15 resolvem em trs_contazul__apoio).
-- R1 As duas origens NAO se somam: SALDO_INICIAL e o saldo de abertura de uma conta financeira (data_competencia); POSICAO_SNAPSHOT e o saldo ABERTO a receber ou a pagar no fim do mes.
--    `saldo` continua uma coluna so, como na Trusted; a origem esta no grao e na chave. R2 Na posicao, vencido + a_vencer = saldo em 18 de 18 (zero quebras) -- qtd_identidade_quebrada guarda.
-- R3 POSICAO_SNAPSHOT e HISTORICO congelado (nao se recalcula): BRM receber R$ 25,79 mi em 5 meses (2026-06 a 2026-10), pagar R$ 20,90 mi; VD receber R$ 5,34 mi, pagar R$ 1,15 mi.
-- R4 SALDO_INICIAL tem 7 datas distintas (2026-05-31 a 2026-09-01): o mes agrupa 7 + 4 + ... -- `qtd_datas_distintas` diz quantas datas cabem na linha.
-- LIMITACAO -- NAO CONTORNE: nao e serie de caixa (ver rfn_financeiro__fluxo_caixa); posicao a receber inclui titulos vencidos e a vencer, ambos emitidos.
WITH s AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_contazul__saldo_posicao`
),
agg AS (
  SELECT
    origem,
    operacao,
    IFNULL(tipo, '(sem tipo)')                       AS tipo,
    DATE_TRUNC(ref_data, MONTH)                      AS mes_referencia,
    COUNT(*)                                         AS qtd_linhas,
    COUNT(DISTINCT ref_data)                         AS qtd_datas_distintas,
    COUNT(DISTINCT id_conta_financeira)              AS qtd_contas,
    ROUND(SUM(saldo), 2)                             AS saldo,
    SUM(qtd_titulos)                                 AS qtd_titulos,
    ROUND(SUM(vencido), 2)                           AS vencido,
    ROUND(SUM(a_vencer), 2)                          AS a_vencer,
    COUNTIF(origem = 'POSICAO_SNAPSHOT' AND ABS(IFNULL(vencido, 0) + IFNULL(a_vencer, 0) - saldo) > 0.01) AS qtd_identidade_quebrada,
    MAX(capturado_em)                                AS capturado_em
  FROM s
  GROUP BY origem, operacao, IFNULL(tipo, '(sem tipo)'), DATE_TRUNC(ref_data, MONTH)
),
final AS (
  SELECT CONCAT(origem, '|', operacao, '|', tipo, '|', CAST(mes_referencia AS STRING)) AS id_saldo_posicao_mensal, g.*, 'L3_CONFIDENTIAL' AS classificacao_dado FROM agg g
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
