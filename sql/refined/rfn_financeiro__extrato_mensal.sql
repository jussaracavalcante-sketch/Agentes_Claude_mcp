-- rfn_financeiro__extrato_mensal (query-0V6z)
-- Refined / financeiro. Grao: um mes de movimento x origem do extrato x conta x empresa.
-- Chave: (mes_referencia, origem, conta_ref, empresa). Nivel: L3 CONFIDENTIAL (movimento bancario por conta;
-- a contraparte, o historico e o documento NAO atravessam, so contagem).
--
-- LE: trs_extrato__lancamento (4.648 lancamentos, query-YPW3).
-- VALIDACAO (18/10/2026, reproduzindo a Trusted sobre a Raw porque ela ainda nao materializou): 36 linhas, 36 chaves,
-- soma de qtd_lancamentos 4.648 = total da Trusted; soma de valor_liquido -112.748,38 = soma de valor da Trusted;
-- entradas R$ 18.948.884,28, saidas R$ 19.061.632,66; zero lancamento de valor zero; meses 2026-01 a 2026-08.
--
-- REGRAS: (R1) entrada = valor > 0, saida = valor < 0, valores em modulo nas colunas valor_entradas/valor_saidas.
-- (R2) valor_liquido e a soma com sinal. (R3) conciliacao so existe onde a origem informa: 769 de 4.648; a taxa de
-- conciliacao divide por qtd_conciliacao_informada, nunca por qtd_lancamentos.
-- LIMITACAO -- NAO CONTORNE: e o extrato bancario, nao o razao: nao soma com trs_financeiro__movimento nem com o
-- Conta Azul. A serie comeca em janeiro/2026 (arquivos de extrato); nao ha caixa bancario anterior aqui.
-- Transferencia entre contas proprias aparece como entrada e saida: o liquido por conta e confiavel, o total da casa nao.
-- Correcao 18/10/2026: a agregacao foi para a CTE g e o _payload_hash passou a ler mes_referencia ja agrupado.
-- A versao anterior referenciava t.data_movimento dentro do hash com GROUP BY por ordinal e o BigQuery recusava
-- ("neither grouped nor aggregated"); falhou nas duas primeiras execucoes. Validado antes do deploy: 36 linhas,
-- 36 chaves, 4.648 lancamentos, liquido -112.748,38 (os mesmos numeros da descricao).
WITH g AS (
SELECT
  DATE_TRUNC(t.data_movimento, MONTH)                         AS mes_referencia,
  t.origem,
  t.conta_ref,
  t.empresa,
  COUNT(*)                                                    AS qtd_lancamentos,
  COUNTIF(t.sentido = 'ENTRADA')                              AS qtd_entradas,
  COUNTIF(t.sentido = 'SAIDA')                                AS qtd_saidas,
  COUNTIF(t.sentido = 'ZERO')                                 AS qtd_zero,
  SUM(IF(t.sentido = 'ENTRADA', t.valor_abs, 0))              AS valor_entradas,
  SUM(IF(t.sentido = 'SAIDA', t.valor_abs, 0))                AS valor_saidas,
  SUM(t.valor)                                                AS valor_liquido,
  COUNTIF(t.conciliacao IS NOT NULL)                          AS qtd_conciliacao_informada,
  COUNTIF(t.conciliacao = 'CONCILIADO')                       AS qtd_conciliado,
  COUNTIF(t.contraparte_documento IS NOT NULL)                AS qtd_com_documento_contraparte,
  MIN(t.data_movimento)                                       AS primeira_data,
  MAX(t.data_movimento)                                       AS ultima_data
FROM `vanguardamartech_trusted`.`trs_extrato__lancamento` t
GROUP BY 1, 2, 3, 4
)
SELECT
  g.*,
  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  'supabase-x0tz'                                             AS _fonte,
  'America/Sao_Paulo'                                         AS _fuso,
  TO_HEX(MD5(CONCAT(CAST(g.mes_referencia AS STRING), g.origem, IFNULL(g.conta_ref, ''), IFNULL(g.empresa, '')))) AS _payload_hash
FROM g
