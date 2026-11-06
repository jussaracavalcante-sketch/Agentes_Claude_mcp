-- trs_iclips__job_horas (query-hDS9)
-- Trusted / iClips. Grao: um JOB do iClips com as horas que o derivado do Supabase atribui a ele. Chave: id_job.
-- Nivel: L3 CONFIDENTIAL (horas por responsavel e filial; sem custo nem valor).
--
-- ORIGEM. supabase_public_fato_job (2.899), da supabase-x0tz (fato analitico montado pelo Supabase; as views
-- vw_bi_jobs e vw_jobs_performance, com 2.899 linhas cada, sao a mesma tabela e nao foram usadas).
-- Medido em 18/10/2026: 2.899 linhas, 2.899 chaves (iclips_job_id), jobs abertos de 18/04/2017 a 24/09/2026,
-- 50 responsaveis, 2.881 titulos distintos.
--
-- O QUE ESTA TABELA TRAZ QUE NINGUEM MAIS TRAZ: horas_realizadas por job (soma 21.017,7 h; maior job 379,72 h),
-- preenchida em 2.889 de 2.899. horas_estimadas existe em 214 jobs (681,1 h). A trs_iclips__apontamento mede
-- 2.334,7 h na janela movel de dois meses: as duas NAO se reconciliam, medem coisas diferentes. A origem de
-- horas_realizadas nao esta documentada no Supabase: tratar como medida declarada pelo derivado, nao auditada.
--
-- CAMPOS MORTOS NAO EMITIDOS: numero (0 de 2.899), pacote (0), valor_aprovado e valor_realizado (0 e 0),
-- data_previsao_entrega (3), data_aprovacao (1), data_encerramento (3), flag_projecao (FALSE em todos).
--
-- COBERTURA COM A Trusted DE PROJETO: 2.372 dos 2.899 jobs (82%) existem em trs_iclips__projeto
-- (flag_projeto_nao_catalogado marca os 527 restantes; a causa nao foi verificada: pode ser job sem projeto
-- na janela extraida ou id de universo diferente, e nao se deve ligar por titulo).
--
-- FUSO: data_abertura e DATE; processed_at e carimbo de sistema UTC (so linhagem).
--
-- LIMITACAO -- NAO CONTORNE: nao ha custo, valor nem prazo nesta tabela; horas_realizadas NAO vira custo (a casa decidiu
-- custo por peca, ver rfn_operacao__custo_peca). Job sem hora nao e job sem trabalho.
SELECT
  CAST(f.iclips_job_id AS STRING)                                  AS id_job,
  NULLIF(TRIM(f.titulo), '')                                       AS titulo,
  NULLIF(TRIM(f.cliente), '')                                      AS cliente_rotulo,
  CAST(f.iclips_cliente_id AS STRING)                              AS id_cliente_iclips,
  NULLIF(TRIM(f.status), '')                                       AS status,
  NULLIF(TRIM(f.filial), '')                                       AS filial,
  NULLIF(TRIM(f.responsavel), '')                                  AS responsavel,
  f.data_abertura,
  SAFE_CAST(CAST(f.horas_estimadas AS STRING) AS FLOAT64)          AS horas_estimadas,
  SAFE_CAST(CAST(f.horas_realizadas AS STRING) AS FLOAT64)         AS horas_realizadas,
  (SAFE_CAST(CAST(f.horas_estimadas AS STRING) AS FLOAT64) > 0)    AS tem_horas_estimadas,
  (p.id_projeto IS NULL)                                           AS flag_projeto_nao_catalogado,
  DATE(f.processed_at, 'America/Sao_Paulo')                        AS derivado_atualizado_em,
  CURRENT_TIMESTAMP()                                              AS _extraido_at,
  'supabase-x0tz'                                                  AS _fonte,
  'America/Sao_Paulo'                                              AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                                   AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_public_fato_job` f
LEFT JOIN (SELECT DISTINCT CAST(id_projeto AS STRING) AS id_projeto FROM `vanguardamartech_trusted`.`trs_iclips__projeto`) p
  ON p.id_projeto = CAST(f.iclips_job_id AS STRING)
