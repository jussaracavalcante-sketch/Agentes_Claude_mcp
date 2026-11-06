-- trs_quickin__vaga (query-6XFL)
-- Trusted / Recrutamento (Quickin). Grao: uma VAGA. Chave: id_vaga. Nivel: L3 CONFIDENTIAL
-- (remuneracao oferecida, gestor contratante).
--
-- ORIGEM. supabase_silver_vaga (217), da supabase-x0tz, ja tipada. bronze_quickin__jobs tem 1.076 linhas
-- para as mesmas 217 vagas (log de versoes, 5 por vaga) e nao foi usado. Medido em 18/10/2026: 217 vagas,
-- 217 chaves, 212 arquivadas e 5 abertas, abertas de 18/11/2024 a 08/10/2026, remuneracao em 181 de 217.
--
-- FUSO. date_open, date_close, created_at e quickin_updated_at sao instantes UTC reais (API do Quickin,
-- sufixo Z): DATETIME(ts,'America/Sao_Paulo').
--
-- pipeline_* sao contagens que a PLATAFORMA entrega e nao sao recalculadas. qtd_aplicacoes_na_base e a
-- contagem real em silver_aplicacao; a soma de pipeline_total (4.010) difere do total de aplicacoes (4.013)
-- em 3, e flag_pipeline_diverge marca as vagas em que as duas nao batem.
--
-- LIMITACAO -- NAO CONTORNE: date_close nao significa vaga preenchida: 212 vagas estao arquivadas e so 150
-- aplicacoes terminaram em contratacao (ver trs_quickin__aplicacao).
WITH ap AS (
  SELECT job_id, COUNT(*) qtd FROM `vanguardamartech_raw`.`supabase_silver_aplicacao` GROUP BY job_id
)
SELECT
  v.quickin_vaga_id                                           AS id_vaga,
  NULLIF(TRIM(v.code), '')                                    AS codigo,
  NULLIF(TRIM(v.title), '')                                   AS titulo,
  NULLIF(TRIM(v.status), '')                                  AS status,
  NULLIF(TRIM(v.publicate), '')                               AS publicada,
  v.openings                                                  AS qtd_posicoes,
  v.confidential                                              AS is_confidencial,
  v.company_id                                                AS id_empresa,
  NULLIF(TRIM(v.company_nome), '')                            AS empresa,
  v.departament_id                                            AS id_departamento,
  NULLIF(TRIM(v.departament_nome), '')                        AS departamento,
  v.contract_id                                               AS id_tipo_contrato,
  NULLIF(TRIM(v.contract_nome), '')                           AS tipo_contrato,
  v.owner_user_id                                             AS id_responsavel,
  NULLIF(TRIM(v.owner_nome), '')                              AS responsavel,
  v.author_user_id                                            AS id_autor,
  NULLIF(TRIM(v.hiring_manager_name), '')                     AS gestor_contratante,
  NULLIF(LOWER(TRIM(v.hiring_manager_email)), '')             AS gestor_contratante_email,
  NULLIF(TRIM(v.experience_level), '')                        AS nivel_experiencia,
  NULLIF(TRIM(v.education_degree), '')                        AS escolaridade,
  NULLIF(TRIM(v.position_category), '')                       AS categoria_posicao,
  v.remuneration                                              AS remuneracao,
  v.remuneration_max                                          AS remuneracao_max,
  NULLIF(TRIM(v.remuneration_period), '')                     AS periodo_remuneracao,
  NULLIF(TRIM(v.currency), '')                                AS moeda,
  NULLIF(TRIM(v.country), '')                                 AS pais,
  NULLIF(TRIM(v.region), '')                                  AS uf,
  NULLIF(TRIM(v.city), '')                                    AS cidade,
  NULLIF(TRIM(v.neighborhood), '')                            AS bairro,
  v.cancel_reason_id                                          AS id_motivo_cancelamento,
  NULLIF(TRIM(v.cancel_reason_nome), '')                      AS motivo_cancelamento,
  DATETIME(v.date_open, 'America/Sao_Paulo')                  AS aberta_em,
  DATETIME(v.date_close, 'America/Sao_Paulo')                 AS fechada_em,
  v.pipeline_total,
  v.pipeline_qualified,
  v.pipeline_disqualified,
  v.pipeline_new,
  v.pipeline_hired,
  IFNULL(a.qtd, 0)                                            AS qtd_aplicacoes_na_base,
  (IFNULL(a.qtd, 0) <> IFNULL(v.pipeline_total, 0))           AS flag_pipeline_diverge,
  (v.date_close < v.date_open)                                AS flag_fecha_antes_de_abrir,
  DATETIME(v.created_at, 'America/Sao_Paulo')                 AS criada_em,
  DATETIME(v.quickin_updated_at, 'America/Sao_Paulo')         AS atualizada_na_origem_em,
  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  'supabase-x0tz'                                             AS _fonte,
  'America/Sao_Paulo'                                         AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(v)))                              AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_silver_vaga` v
LEFT JOIN ap a ON a.job_id = v.quickin_vaga_id
