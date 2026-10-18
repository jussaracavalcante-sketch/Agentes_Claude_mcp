-- trs_vjob__orcamento_item (Trusted / VJOB) · L3 CONFIDENTIAL · Grao: um item da tabela de precos de orcamento.
-- Chave: id_orcamento_item. Origem: mysql-yIOn, stream `tborcamento` (tabela
-- `vanguardamartech_vjob_real_mysql.mysql_vjobvjob_2024_tborcamento`). Gatilho: evento em query-MZdN.
--
-- O QUE E: a TABELA DE PRECOS de servicos que a agencia usa para montar orcamento (Planejamento de Social
-- Media R$ 706,14; Card Factual R$ 60,94; Reels R$ 350,00; Gestao de Midia Performance R$ 2.000,00...).
-- Nao e orcamento de cliente: nao ha cabecalho, cliente, quantidade fechada nem data de proposta.
--
-- DECISAO DE 2026-10-18 (REVERTE A DE 24/09): este stream tinha sido deixado sem Trusted com o argumento de que
-- `subtotal` so tem 2 de 31 linhas. O argumento mirava as colunas mortas; as colunas VIVAS (descricao, valor,
-- datacricao) estao 31 de 31 preenchidas e sao o que importa. Colunas constantes/zero nao eram o caso.
--
-- MEDIDO em 2026-10-18: 31 linhas, 31 ids distintos, 31 descricoes distintas, valor > 0 em 31 de 31,
-- soma dos precos R$ 21.042,43. Janela: 2020-10-07 a 2025-03-11 (parada ha 19 meses). Os ids tem buracos
-- (4, 15, 22-25, 27-54, 56-64): itens apagados no sistema, o log nao guarda.
--
-- RESIDUO DE CALCULO: `subtotal` e `quantidade` so existem em 2 linhas (Card Animado 5 x 152,47 = 762,35 e
-- Blog Post 3 x 323,69 = 971,07; o produto bate nas duas). E estado de edicao esquecido, nao dado de proposta.
-- `subtotal = 0` e sentinela em 29 de 31 e sai NULL; os dois campos saem com o sufixo `_residual` para ninguem
-- somar como receita.
--
-- FUSO: `datacricao` e TIMESTAMP gravado pelo VJOB com relogio local (convencao medida em trs_vjob__job, 23/09);
-- nao ha como medir de novo aqui (31 linhas, em lotes de poucos minutos), entao se HERDA a convencao e nada se
-- converte: DATETIME(ts) sem argumento de fuso.
--
-- LIMITACOES -- NAO CONTORNE
--   1. E preco de TABELA, nao preco praticado: nao ha venda, cliente ou contrato aqui. Nao comparar com a receita
--      (rfn_financeiro__receita_cliente_mensal) nem com o custo por peca (rfn_operacao__custo_peca).
--   2. Nao liga a `trs_iclips__peca_tipo` (1.049 tipos, 147 com valor): sao catalogos diferentes, sem chave comum.
--   3. O nivel e L3 porque e a tabela de precos da casa (mesma classe da trs_iclips__peca_tipo).
--   4. Sem Refined: 31 linhas, parada desde 03/2025, e a propria Trusted ja responde "quanto a casa cobra por X".
WITH base AS (
  SELECT * FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tborcamento`
)
SELECT
  CAST(b.id AS INT64)                                       AS id_orcamento_item,
  NULLIF(TRIM(b.descricao), '')                             AS descricao,
  SAFE_CAST(b.valor AS NUMERIC)                             AS valor_unitario,
  NULLIF(SAFE_CAST(b.quantidade AS INT64), 0)               AS quantidade_residual,
  NULLIF(SAFE_CAST(b.subtotal AS NUMERIC), 0)               AS subtotal_residual,
  (NULLIF(SAFE_CAST(b.subtotal AS NUMERIC), 0) IS NOT NULL
   OR NULLIF(SAFE_CAST(b.quantidade AS INT64), 0) IS NOT NULL) AS flag_tem_calculo_residual,
  DATETIME(b.datacricao)                                    AS criado_em,
  CURRENT_TIMESTAMP()                                       AS _extraido_at,
  'mysql-yIOn'                                              AS _fonte,
  'America/Sao_Paulo'                                       AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(b)))                            AS _payload_hash
FROM base b
