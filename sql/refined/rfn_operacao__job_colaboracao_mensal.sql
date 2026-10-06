-- rfn_operacao__job_colaboracao_mensal  (query-x8md)
-- Refined / operacao, L2, gatilho de evento em query-tc97 (trs_vjob__job_responsavel). Grao: mes da PRIMEIRA linha de responsavel do job.
-- A contagem e por JOB, nao por linha. So responsavel interno existe (externo vazio nas 1.644 linhas). Colaboracao nao e esforco.
-- Medido em 06/10/2026: 5 meses, 1.530 jobs, 1.644 responsaveis, 101 jobs com mais de um (maximo 6), zero sem principal unico.
WITH j AS (
  SELECT
    id_job_unico,
    MIN(DATE(criado_em)) AS dt_inicio,
    COUNT(*) AS qtd_responsaveis,
    COUNTIF(is_principal) AS qtd_principais,
    MAX(_extraido_at) AS _extraido_at
  FROM `vanguardamartech_trusted`.`trs_vjob__job_responsavel`
  GROUP BY id_job_unico
),
p AS (
  SELECT DATE_TRUNC(DATE(criado_em), MONTH) AS mes_referencia, COUNT(DISTINCT id_usuario) AS qtd_pessoas
  FROM `vanguardamartech_trusted`.`trs_vjob__job_responsavel`
  GROUP BY 1
)
SELECT
  DATE_TRUNC(j.dt_inicio, MONTH) AS mes_referencia,
  COUNT(*) AS qtd_jobs,
  COUNTIF(j.qtd_responsaveis > 1) AS qtd_jobs_com_mais_de_um_responsavel,
  SAFE_DIVIDE(COUNTIF(j.qtd_responsaveis > 1), COUNT(*)) AS taxa_colaboracao,
  SUM(j.qtd_responsaveis) AS qtd_responsaveis,
  SAFE_DIVIDE(SUM(j.qtd_responsaveis), COUNT(*)) AS media_responsaveis_por_job,
  MAX(j.qtd_responsaveis) AS max_responsaveis_por_job,
  COUNTIF(j.qtd_principais <> 1) AS qtd_jobs_sem_principal_unico,
  ANY_VALUE(p.qtd_pessoas) AS qtd_pessoas_distintas,
  CURRENT_TIMESTAMP() AS _extraido_at,
  MAX(j._extraido_at) AS _extraido_trusted
FROM j
LEFT JOIN p ON p.mes_referencia = DATE_TRUNC(j.dt_inicio, MONTH)
GROUP BY 1
