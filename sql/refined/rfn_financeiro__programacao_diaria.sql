-- rfn_financeiro__programacao_diaria
-- Refined / financeiro. Grao: dia do snapshot x empresa x tipo (pagar/receber) x faixa de vencimento. Le trs_financeiro__programacao_snapshot.
-- Nivel: L3 CONFIDENTIAL (agregado; nenhuma contraparte ou categoria nominal atravessa).
-- REGRA 1: a faixa compara data_vencimento com o DIA DO SNAPSHOT (nunca com o relogio de quem le): vencida | a_vencer_0_30 |
--          a_vencer_31_90 | a_vencer_mais_90. Dia de vencimento igual ao do snapshot cai em a_vencer_0_30.
-- REGRA 2: valor_nao_pago e o saldo em aberto; valor e a face da parcela. Nao somar snapshots entre dias: a mesma parcela reaparece.
-- REGRA 3: flag_snapshot_parcial = o dia tem menos de 90% da media dos dias vizinhos (anterior e seguinte; so um vizinho nas pontas).
--          Marca, nunca exclui. Medido: 7 dias parciais (341 a 1.712 parcelas) entre 69.
-- LIMITACOES - NAO CONTORNE: historico so de 2026-08-10 em diante; a origem tem exatamente 140.000 linhas e o ultimo dia parece cortado;
--   BRM e VD apenas; e posicao em aberto, nao caixa realizado (ver rfn_financeiro__fluxo_caixa); limiar de 90% e escolha desta tabela.
WITH p AS (
  SELECT
    snapshot_date, empresa, tipo, contraparte, valor, valor_nao_pago, qtd_parcelas_no_snapshot,
    CASE
      WHEN data_vencimento < snapshot_date THEN 'vencida'
      WHEN DATE_DIFF(data_vencimento, snapshot_date, DAY) <= 30 THEN 'a_vencer_0_30'
      WHEN DATE_DIFF(data_vencimento, snapshot_date, DAY) <= 90 THEN 'a_vencer_31_90'
      ELSE 'a_vencer_mais_90'
    END AS faixa_vencimento
  FROM vanguardamartech_trusted.trs_financeiro__programacao_snapshot
),
dias AS (
  SELECT snapshot_date, ANY_VALUE(qtd_parcelas_no_snapshot) AS n FROM p GROUP BY snapshot_date
),
dias_ref AS (
  SELECT
    snapshot_date, n,
    SAFE_DIVIDE(
      IFNULL(LAG(n) OVER w, 0) + IFNULL(LEAD(n) OVER w, 0),
      IF(LAG(n) OVER w IS NULL, 0, 1) + IF(LEAD(n) OVER w IS NULL, 0, 1)
    ) AS n_vizinhos
  FROM dias
  WINDOW w AS (ORDER BY snapshot_date)
)
SELECT
  CONCAT(CAST(p.snapshot_date AS STRING), '|', IFNULL(p.empresa, '(sem empresa)'), '|', IFNULL(p.tipo, '(sem tipo)'), '|', p.faixa_vencimento) AS id_programacao_diaria,
  p.snapshot_date,
  IFNULL(p.empresa, '(sem empresa)')            AS empresa,
  IFNULL(p.tipo, '(sem tipo)')                  AS tipo,
  p.faixa_vencimento,
  COUNT(*)                                      AS qtd_parcelas,
  SUM(p.valor)                                  AS valor,
  SUM(p.valor_nao_pago)                         AS valor_nao_pago,
  COUNTIF(p.contraparte IS NULL)                AS qtd_sem_contraparte,
  ANY_VALUE(d.n)                                AS qtd_parcelas_no_snapshot,
  ANY_VALUE(d.n_vizinhos)                       AS media_parcelas_dias_vizinhos,
  ANY_VALUE(d.n < 0.9 * d.n_vizinhos)           AS flag_snapshot_parcial,
  'L3_CONFIDENTIAL'                             AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz'                               AS _fonte
FROM p
JOIN dias_ref d ON d.snapshot_date = p.snapshot_date
GROUP BY p.snapshot_date, p.empresa, p.tipo, p.faixa_vencimento
