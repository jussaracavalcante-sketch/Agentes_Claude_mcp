-- trs_quickin__requisicao
-- Trusted / Recrutamento (Quickin). Grao: uma REQUISICAO de vaga (pedido interno de contratacao, ainda sem
-- virar vaga). Chave: id_requisicao. Nivel: L3 CONFIDENTIAL (remuneracao pedida, gestor).
--
-- ORIGEM. bronze_quickin__requisitions da supabase-x0tz: 322 linhas, 268 chaves (log de versoes, ate 7 por
-- requisicao); le a ultima versao por natural_key. NAO existe silver desta entidade.
-- Medido em 18/10/2026: 268 requisicoes (analyzing 90, archived 178), criadas de 14/11/2024 a 15/10/2026,
-- 42 com beneficios preenchidos.
--
-- O CAMPO job (vinculo com a vaga) e NULO nas 268 e nenhuma requisicao resolve contra supabase_silver_vaga:
-- NAO existe ponte requisicao -> vaga nesta base. Nao ligar por titulo (texto livre com emoji).
--
-- FUSO. created_at e updated_at sao UTC reais (ISO com Z): DATETIME(ts,'America/Sao_Paulo').
--
-- current_group e total_groups (fluxo de aprovacao) vem NULOS nas 268 e nao sao emitidos.
-- A descricao (HTML com requisitos da vaga) e os comentarios de justificativa NAO sao emitidos (texto livre).
--
-- LIMITACAO -- NAO CONTORNE: 'analyzing' (90) e o estado da ultima leitura, nao fila viva; a maior parte parou
-- quando o fluxo de aprovacao deixou de ser usado.
WITH ult AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT b.*, ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) rn,
           COUNT(*) OVER (PARTITION BY natural_key) qv
    FROM `vanguardamartech_raw`.`supabase_bronze_quickin__requisitions` b) WHERE rn = 1
)
SELECT
  natural_key                                                              AS id_requisicao,
  NULLIF(TRIM(JSON_VALUE(payload, '$.code')), '')                          AS codigo,
  NULLIF(TRIM(JSON_VALUE(payload, '$.title')), '')                         AS titulo,
  NULLIF(JSON_VALUE(payload, '$.status'), '')                              AS status,
  SAFE_CAST(JSON_VALUE(payload, '$.openings') AS INT64)                    AS qtd_posicoes,
  COALESCE(JSON_VALUE(payload, '$.company_id._id'), JSON_VALUE(payload, '$.company_id'))       AS id_empresa,
  JSON_VALUE(payload, '$.company_id.name')                                 AS empresa,
  COALESCE(JSON_VALUE(payload, '$.contract_id._id'), JSON_VALUE(payload, '$.contract_id'))     AS id_tipo_contrato,
  JSON_VALUE(payload, '$.contract_id.name')                                AS tipo_contrato,
  COALESCE(JSON_VALUE(payload, '$.departament_id._id'), JSON_VALUE(payload, '$.departament_id')) AS id_departamento,
  JSON_VALUE(payload, '$.departament_id.name')                             AS departamento,
  NULLIF(JSON_VALUE(payload, '$.owner_user_id'), '')                       AS id_responsavel,
  NULLIF(JSON_VALUE(payload, '$.author_user_id'), '')                      AS id_autor,
  NULLIF(TRIM(JSON_VALUE(payload, '$.hiring_manager_name')), '')           AS gestor_contratante,
  NULLIF(JSON_VALUE(payload, '$.experience_level'), '')                    AS nivel_experiencia,
  NULLIF(JSON_VALUE(payload, '$.education_degree'), '')                    AS escolaridade,
  NULLIF(JSON_VALUE(payload, '$.position_category'), '')                   AS categoria_posicao,
  NULLIF(JSON_VALUE(payload, '$.workplace_type'), '')                      AS tipo_local_trabalho,
  SAFE_CAST(JSON_VALUE(payload, '$.remuneration') AS FLOAT64)              AS remuneracao,
  SAFE_CAST(JSON_VALUE(payload, '$.remuneration_max') AS FLOAT64)          AS remuneracao_max,
  NULLIF(JSON_VALUE(payload, '$.remuneration_period'), '')                 AS periodo_remuneracao,
  NULLIF(JSON_VALUE(payload, '$.currency'), '')                            AS moeda,
  NULLIF(JSON_VALUE(payload, '$.city'), '')                                AS cidade,
  NULLIF(JSON_VALUE(payload, '$.region'), '')                              AS uf,
  ARRAY_LENGTH(JSON_QUERY_ARRAY(payload, '$.followers'))                   AS qtd_seguidores,
  (JSON_VALUE(payload, '$.job') IS NOT NULL)                               AS tem_vaga_vinculada,
  DATETIME(SAFE.TIMESTAMP(JSON_VALUE(payload, '$.created_at')), 'America/Sao_Paulo')  AS criada_em,
  DATETIME(SAFE.TIMESTAMP(JSON_VALUE(payload, '$.updated_at')), 'America/Sao_Paulo')  AS atualizada_na_origem_em,
  qv                                                                       AS qtd_versoes,
  DATE(fetched_at)                                                         AS versao_lida_em,
  CURRENT_TIMESTAMP()                                                      AS _extraido_at,
  'supabase-x0tz'                                                          AS _fonte,
  'America/Sao_Paulo'                                                      AS _fuso,
  payload_hash                                                             AS _payload_hash
FROM ult
