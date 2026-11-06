-- rfn_financeiro__contazul_contrato_mensal  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (valor de contrato por mes; cliente_nome e id_pessoa NAO atravessam)
-- Grao: um MES DE INICIO x operacao x status do contrato recorrente nativo do Conta Azul.
-- Le: trs_contazul__contrato (query-F2ov). Gatilho: evento em query-F2ov.
-- Identidade (19/10/2026): 390 contratos = 390 · valor_total R$ 2.256.720,34 · 91 ATIVO (R$ 558.059,77) + 299 INATIVO (R$ 1.698.660,57) · 28 meses de inicio (2023-10 a 2026-09).
-- R1 Agrega, nao filtra: INATIVO fica na tabela, separado por status. R2 valor_total e o total do contrato no payload, NAO a parcela nem receita do
--    mes -- nao somar com trs_contazul__movimento nem com trs_vjob__cronograma. R3 proximo_vencimento so existe em 92 de 390 (os ativos + 1):
--    valor_proximo_vencimento soma R$ 520.630,29 e e NULL onde nao ha. R4 76 contratos comecam em 2026-06, a virada do ERP para o Conta Azul.
-- R5 tipo_expiracao NUNCA (55) nao tem fim real: data_fim vem preenchida em 390 de 390 mesmo assim -- ler data_fim junto com qtd_expira_nunca.
-- LIMITACAO -- NAO CONTORNE: mes de INICIO, nao de vigencia: contrato vigente em um mes nao se le aqui; 44 contratos sem tipo_pagamento (NULL, nao 'outro').
WITH c AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_contazul__contrato`
),
agg AS (
  SELECT
    DATE_TRUNC(data_inicio, MONTH)                 AS mes_inicio,
    operacao,
    IFNULL(status_origem, '(sem status)')          AS status_origem,
    COUNT(*)                                       AS qtd_contratos,
    COUNT(DISTINCT id_pessoa)                      AS qtd_clientes_distintos,
    COUNTIF(is_ativo)                              AS qtd_ativos,
    ROUND(SUM(valor_total), 2)                     AS valor_total,
    COUNTIF(tipo_expiracao = 'NUNCA')              AS qtd_expira_nunca,
    COUNTIF(tipo_pagamento = 'BOLETO_BANCARIO')    AS qtd_boleto,
    COUNTIF(tipo_pagamento IS NULL)                AS qtd_sem_tipo_pagamento,
    COUNTIF(proximo_vencimento IS NOT NULL)        AS qtd_com_proximo_vencimento,
    NULLIF(ROUND(SUM(valor_proximo_vencimento), 2), 0) AS valor_proximo_vencimento,
    MIN(data_fim)                                  AS data_fim_minima,
    MAX(data_fim)                                  AS data_fim_maxima,
    ROUND(AVG(vigencia_total), 1)                  AS vigencia_total_media
  FROM c
  GROUP BY DATE_TRUNC(data_inicio, MONTH), operacao, IFNULL(status_origem, '(sem status)')
),
final AS (
  SELECT CONCAT(CAST(mes_inicio AS STRING), '|', operacao, '|', status_origem) AS id_contrato_mensal, g.*, 'L3_CONFIDENTIAL' AS classificacao_dado FROM agg g
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
