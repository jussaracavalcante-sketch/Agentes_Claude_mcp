-- trs_qulture__objetivo (query-Moqr)
-- Trusted / RH (Qulture). Grao: um OBJETIVO (OKR) da empresa ou de time. Chave: id_objetivo.
-- Nivel: L2 INTERNAL (objetivo corporativo, sem dado pessoal; o responsavel nao vem no payload).
--
-- ORIGEM. bronze_qulture__objectives da supabase-x0tz (GraphQL do Qulture). O bronze e LOG DE VERSOES:
-- 75 linhas para 28 objetivos; esta tabela le a ultima versao por natural_key (fetched_at) e emite
-- qtd_versoes. O silver_qulture_objetivo (28) tem as mesmas chaves, mas NAO traz score, pai, tipo nem
-- data de criacao, e por isso nao foi a origem.
--
-- score_pct: score.value da origem, em percentual (0 a 100), como a plataforma entrega; nao e recalculado
-- a partir dos key results (a Trusted nao recalcula metrica derivada). 75 de 75 versoes trazem score.
--
-- FUSO. createdAt traz offset -03:00 (hora local de Manaus ja explicita): TIMESTAMP() respeita o offset e
-- DATETIME(ts,'America/Sao_Paulo') entrega o relogio de Sao Paulo. Nao ha data de conclusao nem de prazo
-- no payload.
--
-- LIMITACAO -- NAO CONTORNE: o payload traz so os ids dos key results (qtd_key_results), nao o resultado
-- de cada um; progresso por KR nao existe aqui. Objetivo sem pai e objetivo de topo.
WITH ult AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT b.*, ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) rn,
           COUNT(*) OVER (PARTITION BY natural_key) qv
    FROM `vanguardamartech_raw`.`supabase_bronze_qulture__objectives` b) WHERE rn = 1
)
SELECT
  natural_key                                                         AS id_objetivo,
  NULLIF(TRIM(JSON_VALUE(payload, '$.name')), '')                     AS nome,
  NULLIF(JSON_VALUE(payload, '$.type'), '')                           AS tipo,
  NULLIF(JSON_VALUE(payload, '$.team.id'), '')                        AS id_time,
  NULLIF(JSON_VALUE(payload, '$.team.name'), '')                      AS nome_time,
  SAFE_CAST(JSON_VALUE(payload, '$.score.value') AS FLOAT64)          AS score_pct,
  NULLIF(JSON_VALUE(payload, '$.parent.id'), '')                      AS id_objetivo_pai,
  NULLIF(TRIM(JSON_VALUE(payload, '$.parent.name')), '')              AS nome_objetivo_pai,
  (JSON_VALUE(payload, '$.parent.id') IS NULL)                        AS is_objetivo_de_topo,
  ARRAY_LENGTH(JSON_QUERY_ARRAY(payload, '$.children'))               AS qtd_filhos,
  ARRAY_LENGTH(JSON_QUERY_ARRAY(payload, '$.keyResults'))             AS qtd_key_results,
  DATETIME(SAFE.TIMESTAMP(JSON_VALUE(payload, '$.createdAt')), 'America/Sao_Paulo') AS criado_em,
  qv                                                                  AS qtd_versoes,
  DATE(fetched_at)                                                    AS versao_lida_em,
  CURRENT_TIMESTAMP()                                                 AS _extraido_at,
  'supabase-x0tz'                                                     AS _fonte,
  'America/Sao_Paulo'                                                 AS _fuso,
  payload_hash                                                        AS _payload_hash
FROM ult
