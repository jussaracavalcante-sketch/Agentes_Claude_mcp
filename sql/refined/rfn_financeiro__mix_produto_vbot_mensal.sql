-- rfn_financeiro__mix_produto_vbot_mensal  ·  query-xWNR  ·  Refined  ·  gatilho: evento em query-uMba  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Refined / financeiro. Grao: um PERIODO (fechamento mensal) x FAMILIA de produto x TIPO (plano ou servico) do mix de produtos da VBOT.
-- Le: trs_vbot__mix_produto_mes (1.475). Gatilho: evento em query-uMba. Nivel: L3 CONFIDENTIAL (receita por familia; nenhum cliente nem produto atravessa).
-- Identidade (2026-10-19): 1.475 linhas da Trusted = SUM(qtd_linhas); MRR R$ 725.972,79 somado nos 4 fechamentos = SUM(mrr); 21 grupos (periodo x familia x tipo; nem toda familia existe em todo fechamento), 4 periodos.
-- R1 E FOTOGRAFIA: cada periodo e um retrato de fim de mes (captured_at). mrr NAO soma entre periodos (conta o mesmo cliente 4 vezes); dentro do periodo soma.
--   participacao_mrr_no_periodo e a fatia da familia no MRR daquele fechamento (soma 1 por periodo).
-- R2 tipo = plano (assinatura-base, familia 'Planos de Assinatura (Recorrente)') ou servico (as outras 6 familias). Servico tambem carrega mrr (894 linhas
--   com mrr > 0: servicos recorrentes); plano nunca tem receita_pontual (0 linhas).
-- R3 receita_pontual E ZERO EM TODOS OS PRODUTOS DOS FECHAMENTOS 2026-09 E 2026-10 (soma 0, contra R$ 102.882,98 e R$ 124.592,53 em 07 e 08):
--   flag_sem_pontual_no_periodo marca o periodo; nao e queda de venda, e a captura que nao trouxe (ou o periodo ainda aberto). Nao comparar sem a flag.
-- R4 qtd_clientes e distinto dentro do grao e NAO soma entre familias (o mesmo cliente tem plano e servico). Zero que e ausencia sai NULL: mrr e
--   receita_pontual saem NULL quando nenhum item do grupo tem valor.
-- LIMITACAO - NAO CONTORNE: so 4 fechamentos (2026-07 a 2026-10); assina_hoje e o estado na captura, nao no periodo; nao soma com
--   rfn_financeiro__receita_vbot_mensal (cobranca e venda do Conexa) nem com trs_conexa__contrato (outra medida de contrato).
WITH m AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vbot__mix_produto_mes`
),
agg AS (
  SELECT
    periodo,
    mes_referencia,
    familia,
    tipo,
    COUNT(*)                                                      AS qtd_linhas,
    COUNT(DISTINCT id_cliente_conexa)                             AS qtd_clientes,
    COUNT(DISTINCT id_produto)                                    AS qtd_produtos,
    COUNTIF(is_assina_hoje)                                       AS qtd_linhas_assina_hoje,
    ROUND(SUM(mrr), 2)                                            AS mrr_bruto,
    COUNTIF(mrr > 0)                                              AS qtd_linhas_com_mrr,
    SUM(qtd_assinaturas)                                          AS qtd_assinaturas,
    ROUND(SUM(receita_pontual), 2)                                AS receita_pontual_bruta,
    COUNTIF(receita_pontual > 0)                                  AS qtd_linhas_com_pontual,
    SUM(qtd_compras)                                              AS qtd_compras,
    MAX(captured_at)                                              AS captured_at
  FROM m
  GROUP BY periodo, mes_referencia, familia, tipo
),
final AS (
  SELECT
    CONCAT(periodo, '|', familia, '|', tipo)                      AS id_mix_mensal,
    periodo,
    mes_referencia,
    familia,
    tipo,
    qtd_linhas,
    qtd_clientes,
    qtd_produtos,
    qtd_linhas_assina_hoje,
    IF(qtd_linhas_com_mrr = 0, NULL, mrr_bruto)                   AS mrr,
    qtd_linhas_com_mrr,
    qtd_assinaturas,
    IF(qtd_linhas_com_pontual = 0, NULL, receita_pontual_bruta)   AS receita_pontual,
    qtd_linhas_com_pontual,
    qtd_compras,
    SAFE_DIVIDE(mrr_bruto, NULLIF(SUM(mrr_bruto) OVER (PARTITION BY periodo), 0)) AS participacao_mrr_no_periodo,
    (SUM(receita_pontual_bruta) OVER (PARTITION BY periodo) = 0)  AS flag_sem_pontual_no_periodo,
    captured_at,
    'L3_CONFIDENTIAL'                                             AS classificacao_dado
  FROM agg
)
SELECT x.*,
  CURRENT_TIMESTAMP()                                             AS _extraido_at,
  'supabase-x0tz'                                                 AS _fonte,
  'America/Sao_Paulo'                                             AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(x)))                                  AS _payload_hash
FROM final x
