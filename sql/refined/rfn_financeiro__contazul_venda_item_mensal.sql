-- rfn_financeiro__contazul_venda_item_mensal  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (valor vendido por mes e empresa; nome e descricao do item NAO atravessam)
-- Grao: MES da venda x operacao do item x vigencia da venda (is_venda_vigente).
-- Le: trs_contazul__venda_item (query-UiQy) + trs_contazul__venda (mes e vigencia). Gatilho: evento em query-UiQy.
-- Identidade (19/10/2026): 3.454 itens = 3.454 · R$ 21.158.141,98 · 3.070 vendas · 3.454 de 3.454 encontram a venda · vigentes 2.290 itens / R$ 9.913.422,29.
-- R1 Agrega, nao filtra: item de venda REMOVIDA fica na tabela com is_venda_vigente = FALSE (R$ 11.244.719,69 em 1.164 itens) -- toda leitura de valor comeca por is_venda_vigente = TRUE.
-- R2 quantidade = 1 em 3.454 de 3.454 e valor_unitario x quantidade = valor_total em 3.454 de 3.454: o item e a venda inteira, nao ha "linha de produto" de verdade.
-- R3 A operacao do item e 'VGD-BRM' em 3.056 e 'BRM' em 398: codigo que a dimensao trs_financeiro__operacao nao tem (ver rfn_financeiro__operacao_resumo); sai cru.
-- R4 id_produto (48 distintos) resolve ZERO de 3.454 contra SERVICO de trs_contazul__apoio (29 produtos): a Trusted dizia que ligava a ca_dim_servico e NAO LIGA -- qtd_produtos_distintos
--    fica como contagem; nao ha nome de produto confiavel para agrupar. R5 164 itens tem centro de custo, 164 de 164 resolvem em trs_contazul__apoio.
-- R6 mes_venda vai ate 2028-09 (vendas agendadas, is_agendada da venda): mes futuro e agenda, nao faturamento -- qtd_vendas_agendadas separa.
-- LIMITACAO -- NAO CONTORNE: valor da venda nao e receita recebida nem competencia do razao; nao somar com trs_contazul__movimento nem com rfn_financeiro__fluxo_caixa.
WITH i AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_contazul__venda_item`
),
v AS (
  SELECT id_venda, mes_venda, is_vigente, is_agendada FROM `vanguardamartech_trusted`.`trs_contazul__venda`
),
j AS (
  SELECT i.*, v.mes_venda, IFNULL(v.is_vigente, FALSE) AS is_venda_vigente, IFNULL(v.is_agendada, FALSE) AS is_venda_agendada, (v.id_venda IS NULL) AS venda_nao_catalogada
  FROM i LEFT JOIN v ON v.id_venda = i.id_venda
),
agg AS (
  SELECT
    DATE_TRUNC(mes_venda, MONTH)             AS mes_venda,
    operacao,
    is_venda_vigente,
    COUNT(*)                                 AS qtd_itens,
    COUNT(DISTINCT id_venda)                 AS qtd_vendas,
    COUNT(DISTINCT id_produto)               AS qtd_produtos_distintos,
    ROUND(SUM(valor_total), 2)               AS valor_total,
    ROUND(AVG(valor_total), 2)               AS valor_medio_item,
    COUNTIF(id_centro_custo IS NOT NULL)     AS qtd_com_centro_custo,
    COUNT(DISTINCT IF(is_venda_agendada, id_venda, NULL)) AS qtd_vendas_agendadas,
    COUNTIF(venda_nao_catalogada)            AS qtd_venda_nao_catalogada
  FROM j
  GROUP BY DATE_TRUNC(mes_venda, MONTH), operacao, is_venda_vigente
),
final AS (
  SELECT CONCAT(IFNULL(CAST(mes_venda AS STRING), '(sem mes)'), '|', operacao, '|', CAST(is_venda_vigente AS STRING)) AS id_venda_item_mensal, g.*, 'L3_CONFIDENTIAL' AS classificacao_dado FROM agg g
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
