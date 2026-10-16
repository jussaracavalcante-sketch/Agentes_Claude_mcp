-- rfn_operacao__ia_uso_mensal  (query-Cb92)
-- Refined / operacao, L2, gatilho "all" nos Trusted trs_vjob__ia_solicitacao (GbCw), ia_geracao (awpp) e ia_geracao_arquivo (wZoc).
-- Grao: mes de criacao da solicitacao x tipo_peca x status. Nenhum texto (briefing, prompt, resultado) atravessa.
-- Custo em US$ e NULL (nunca zero) quando nenhuma geracao do grupo tem custo.
-- Medido em 06/10/2026: 13 linhas, 87 solicitacoes, 87 geracoes, 79 arquivos, US$ 14,257256 dos dois lados.
WITH s AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__ia_solicitacao`
),
g AS (
  SELECT id_solicitacao, COUNT(*) AS qtd_geracoes, SUM(custo_estimado_usd) AS custo_usd, COUNTIF(flag_sem_custo) AS qtd_sem_custo
  FROM `vanguardamartech_trusted`.`trs_vjob__ia_geracao`
  GROUP BY 1
),
a AS (
  SELECT id_solicitacao, COUNT(*) AS qtd_arquivos
  FROM `vanguardamartech_trusted`.`trs_vjob__ia_geracao_arquivo`
  GROUP BY 1
)
SELECT
  DATE_TRUNC(DATE(s.criado_em), MONTH) AS mes_referencia,
  IFNULL(s.tipo_peca, '(sem tipo)') AS tipo_peca,
  IFNULL(s.status, '(sem status)') AS status,
  COUNT(*) AS qtd_solicitacoes,
  COUNT(DISTINCT s.id_cliente) AS qtd_clientes,
  COUNTIF(s.is_concluido) AS qtd_concluidas,
  COUNTIF(s.is_erro) AS qtd_erro,
  SAFE_DIVIDE(COUNTIF(s.is_concluido), COUNT(*)) AS taxa_conclusao,
  SUM(IFNULL(g.qtd_geracoes, 0)) AS qtd_geracoes,
  SUM(IFNULL(a.qtd_arquivos, 0)) AS qtd_arquivos,
  SUM(g.custo_usd) AS custo_estimado_usd,
  SUM(IFNULL(g.qtd_sem_custo, 0)) AS qtd_geracoes_sem_custo,
  COUNTIF(s.flag_cliente_nao_catalogado) AS qtd_cliente_nao_catalogado,
  CURRENT_TIMESTAMP() AS _extraido_at,
  MAX(s._extraido_at) AS _extraido_trusted
FROM s
LEFT JOIN g USING (id_solicitacao)
LEFT JOIN a USING (id_solicitacao)
GROUP BY 1, 2, 3
