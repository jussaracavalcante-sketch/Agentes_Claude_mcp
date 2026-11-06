-- rfn_operacao__orcamento_item_resumo  ·  Refined / operacao  ·  L3 CONFIDENTIAL (tabela de precos da casa, por linhagem)
-- Grao: ano de criacao do item da tabela de precos de orcamento do VJOB.
-- Le: trs_vjob__orcamento_item (query-bzyG, L3). Gatilho: evento em query-bzyG. Cadencia SEMANAL (mysql-yIOn, domingo).
-- Identidade (19/10/2026, contra a Trusted materializada): 31 itens = 31 · 4 linhas (2020, 2021, 2023, 2025), 4 chaves ·
--   soma dos precos R$ 21.042,43 = R$ 21.042,43 · 2 itens com calculo residual (subtotal R$ 1.733,42, quantidade 8), os dois de 2020.
-- R1 E PRECO DE TABELA, nao preco praticado: nao ha venda, cliente nem contrato. soma_valor_unitario e a soma dos precos
--    unitarios cadastrados no ano, nao receita. Nao comparar com rfn_financeiro__receita_cliente_mensal nem rfn_operacao__custo_peca.
-- R2 soma_subtotal_residual e soma_quantidade_residual saem NULL onde nao ha residuo (3 dos 4 anos): o residuo e estado de edicao
--    esquecido em 2 linhas, nunca proposta.
-- R3 A descricao do item (nome do servico) nao atravessa; qtd_descricoes_distintas = qtd_itens prova que nao ha item repetido.
-- LIMITACAO -- NAO CONTORNE: 31 linhas, parada desde 11/03/2025; a propria Trusted responde "quanto a casa cobra por X". Esta Refined
--   existe para a cobertura Trusted -> Refined e para a evolucao da tabela por ano, nao como indicador de negocio.
WITH o AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__orcamento_item`),
agg AS (
  SELECT
    EXTRACT(YEAR FROM criado_em) AS ano_criacao,
    COUNT(*) AS qtd_itens,
    COUNT(DISTINCT descricao) AS qtd_descricoes_distintas,
    SUM(valor_unitario) AS soma_valor_unitario,
    MIN(valor_unitario) AS menor_valor_unitario,
    MAX(valor_unitario) AS maior_valor_unitario,
    AVG(valor_unitario) AS media_valor_unitario,
    COUNTIF(flag_tem_calculo_residual) AS qtd_com_calculo_residual,
    IF(COUNTIF(subtotal_residual IS NOT NULL) = 0, NULL, SUM(subtotal_residual)) AS soma_subtotal_residual,
    IF(COUNTIF(quantidade_residual IS NOT NULL) = 0, NULL, SUM(quantidade_residual)) AS soma_quantidade_residual,
    MIN(criado_em) AS primeiro_item_em,
    MAX(criado_em) AS ultimo_item_em
  FROM o
  GROUP BY 1
),
final AS (
  SELECT CAST(ano_criacao AS STRING) AS id_orcamento_resumo, a.*, 'L3_CONFIDENTIAL' AS classificacao_dado FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
