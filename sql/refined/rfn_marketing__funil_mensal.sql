-- rfn_marketing__funil_mensal  (query-9pcn)
-- Refined / marketing, L2 INTERNAL, gatilho de evento em query-tESg (rfn_marketing__conversao). Alerta de falha ligado.
-- Grao: uma _fonte (conta RD = um cliente) x mes de referencia x canal x carga em lote. Chave id_funil_mensal.
-- carga_em_lote e GRAO: linha LOTE nunca se mistura com CONVERSAO (para resultado de marketing, filtrar carga_em_lote = FALSE).
-- qtd_contatos_distintos NAO e aditivo. qtd_em_mais_de_uma_fonte conta eventos cujo id aparece em outra _fonte (mesma conta de RD lida
-- por mais de uma conexao); somar entre clientes duplica - total da casa = rfn_marketing__conversao.is_registro_canonico = TRUE.
-- Medido em 16/10/2026 sobre a Refined materializada: 1.636 linhas = 1.636 chaves, SUM(qtd_conversoes) = 125.914 = linhas da origem.
-- Depende so de colunas que existem hoje; a duplicidade e derivada do id de evento (id_conversao sem o prefixo da fonte).
WITH ev AS (
  SELECT r.*, COUNT(DISTINCT r._fonte) OVER (PARTITION BY SUBSTR(r.id_conversao, LENGTH(r._fonte) + 2)) AS _n_fontes
  FROM `vanguardamartech_refined`.`rfn_marketing__conversao` r
)
SELECT
  CONCAT(_fonte, '|', FORMAT_DATE('%Y-%m', mes_referencia), '|', canal, '|', IF(carga_em_lote, 'LOTE', 'CONVERSAO')) AS id_funil_mensal,
  _fonte,
  cliente,
  mes_referencia,
  canal,
  ANY_VALUE(canal_pago) AS canal_pago,
  carga_em_lote,
  COUNT(*) AS qtd_conversoes,
  COUNT(DISTINCT id_contato) AS qtd_contatos_distintos,
  COUNTIF(NOT sem_origem) AS qtd_com_origem,
  COUNTIF(registro_confiavel) AS qtd_registro_confiavel,
  COUNTIF(id_campanha_google IS NOT NULL) AS qtd_com_campanha_google,
  COUNTIF(_n_fontes > 1) AS qtd_em_mais_de_uma_fonte,
  MIN(data) AS primeira_data,
  MAX(data) AS ultima_data,
  CURRENT_TIMESTAMP() AS _extraido_at
FROM ev
GROUP BY _fonte, cliente, mes_referencia, canal, carga_em_lote
