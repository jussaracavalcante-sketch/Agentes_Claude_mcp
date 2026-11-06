-- trs_rh__recrutamento
-- Trusted / RH. Grao: uma linha de recrutamento (ATS Quickin), em QUATRO recortes que nao se somam, identificada por (origem, id):
--   FUNIL_ETAPA (657): vaga x etapa, com aplicacoes, qualificados, desclassificados e contratados | TEMPO_CONTRATACAO (139): vaga, com contratacoes e dias medios
--   CANDIDATURA_ABERTA (2.581): uma aplicacao em aberto, com a etapa e os dias nela | CONTRATACAO (150): uma contratacao e o pareamento com a pessoa do RH formal
-- 3.527 linhas, 3.527 chaves (medido em 2026-10-18). Origem: gold_funil_recrutamento, gold_time_to_hire, gold_pipeline_aberto, gold_ponte_contratacao (fonte supabase-x0tz).
-- Nivel: L3 CONFIDENTIAL. NAO emite nome de candidato, nome normalizado nem e-mail do RH (so tem_par_rh): ids de aplicacao e candidato sao opacos.
-- gold_roi_canal_captacao (1 linha, canal 'desconhecido') e gold_span_de_controle (21) sao derivadas e nao foram tratadas.
-- CONTRATACAO: criterio_pareamento (EMAIL, NOME_EXATO, NOME_CONTIDO, AMBIGUO, SEM_PAR) e confianca sao da ponte do Supabase, 104 de 150 com par. lag_dias = admissao - contratacao no ATS:
--   negativo grande = a pessoa ja estava na casa quando a vaga foi registrada (formalizacao retroativa), nao erro da ponte.
-- dias_na_etapa e dias_medio vem da origem, calculados na data da carga: nao se recalculam aqui. contratados do funil somam 150 = contratacoes do tempo de contratacao = linhas de CONTRATACAO.
SELECT
  a.*,
  'L3_CONFIDENTIAL'                  AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(a)))     AS _payload_hash
FROM (
  SELECT CONCAT('FUNIL_ETAPA|', job_id, '|', stage_id) AS id_linha, 'FUNIL_ETAPA' AS origem, job_id, NULLIF(TRIM(vaga), '') AS vaga, NULLIF(TRIM(etapa), '') AS etapa, etapa_ordem,
         CAST(NULL AS STRING) AS aplicacao_id, CAST(NULL AS STRING) AS candidato_id, CAST(NULL AS TIMESTAMP) AS data_etapa, CAST(NULL AS DATE) AS data_contratacao, CAST(NULL AS INT64) AS dias_na_etapa,
         aplicacoes AS qtd_aplicacoes, qualificados AS qtd_qualificados, desclassificados AS qtd_desclassificados, contratados AS qtd_contratados,
         CAST(NULL AS FLOAT64) AS dias_medio, CAST(NULL AS STRING) AS cargo_categoria, CAST(NULL AS BOOL) AS is_seletivo, CAST(NULL AS STRING) AS criterio_pareamento,
         CAST(NULL AS STRING) AS confianca_pareamento, CAST(NULL AS INT64) AS lag_dias, CAST(NULL AS BOOL) AS tem_par_rh, CAST(NULL AS STRING) AS motivo_sem_par, CAST(NULL AS TIMESTAMP) AS pareado_em
  FROM vanguardamartech_raw.supabase_gold_funil_recrutamento
  UNION ALL
  SELECT CONCAT('TEMPO_CONTRATACAO|', job_id), 'TEMPO_CONTRATACAO', job_id, NULLIF(TRIM(vaga), ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL,
         NULL, NULL, NULL, contratacoes, dias_medio, NULLIF(TRIM(cargo_categoria), ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL
  FROM vanguardamartech_raw.supabase_gold_time_to_hire
  UNION ALL
  SELECT CONCAT('CANDIDATURA_ABERTA|', quickin_aplicacao_id), 'CANDIDATURA_ABERTA', job_id, NULLIF(TRIM(vaga), ''), NULLIF(TRIM(etapa), ''), NULL, quickin_aplicacao_id, NULL, stage_date, NULL, dias_na_etapa,
         NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
  FROM vanguardamartech_raw.supabase_gold_pipeline_aberto
  UNION ALL
  SELECT CONCAT('CONTRATACAO|', aplicacao_id), 'CONTRATACAO', job_id, NULL, NULL, NULL, aplicacao_id, candidato_id, NULL, hired_date, NULL,
         NULL, NULL, NULL, 1, NULL, NULL, seletivo, NULLIF(TRIM(criterio), ''), NULLIF(TRIM(confianca), ''), lag_dias, (email_rh IS NOT NULL), NULLIF(TRIM(motivo_sem_par), ''), matched_at
  FROM vanguardamartech_raw.supabase_gold_ponte_contratacao
) a
