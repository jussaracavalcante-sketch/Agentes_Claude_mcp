-- rfn_financeiro__contazul_vendas_mensal
-- Refined / financeiro. Grao: origem (VENDA ou NOTA_FISCAL) x operacao x mes x situacao do registro x tipo.
-- Le trs_contazul__venda (mes de venda) e trs_contazul__nota_fiscal (mes de competencia). Nivel: L3 CONFIDENTIAL (agregado; nenhum cliente).
-- REGRA 1: VENDA separa VIGENTE de REMOVIDA (37% das vendas estao removidas na origem): toda leitura de valor comeca por VIGENTE.
-- REGRA 2: NOTA_FISCAL separa EMITIDA de CANCELADA; nota cancelada nao e faturamento.
-- REGRA 3: venda agendada (SCHEDULED_SALE) e promessa futura, nao venda feita: qtd_agendadas conta, nao exclui.
-- LIMITACOES - NAO CONTORNE: VENDA e NOTA_FISCAL medem coisas diferentes (pedido/contrato agendado x documento fiscal) e NAO se somam;
--   nao soma com trs_contazul__movimento (a parcela e a grandeza de dinheiro); so BRM e VD; mes NULL vira 'sem_mes' no id.
WITH u AS (
  SELECT 'VENDA' AS origem, operacao, mes_venda AS mes,
         IF(is_vigente, 'VIGENTE', 'REMOVIDA') AS situacao_registro,
         IFNULL(tipo, '(sem tipo)') AS tipo_registro, valor_total AS valor, is_agendada
  FROM vanguardamartech_trusted.trs_contazul__venda
  UNION ALL
  SELECT 'NOTA_FISCAL', operacao, mes_competencia,
         IF(is_cancelada, 'CANCELADA', 'EMITIDA'),
         IFNULL(tipo, '(sem tipo)'), valor, FALSE
  FROM vanguardamartech_trusted.trs_contazul__nota_fiscal
)
SELECT
  CONCAT(origem, '|', operacao, '|', IFNULL(CAST(mes AS STRING), 'sem_mes'), '|', situacao_registro, '|', tipo_registro) AS id_vendas_mensal,
  origem,
  operacao,
  mes,
  situacao_registro,
  tipo_registro,
  COUNT(*)                                  AS qtd_registros,
  SUM(valor)                                AS valor,
  COUNTIF(is_agendada)                      AS qtd_agendadas,
  'L3_CONFIDENTIAL'                         AS classificacao_dado,
  CURRENT_TIMESTAMP()                       AS _extraido_at,
  'supabase-x0tz'                           AS _fonte
FROM u
GROUP BY origem, operacao, mes, situacao_registro, tipo_registro
