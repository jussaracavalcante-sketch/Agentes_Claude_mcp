-- trs_linkedin_ads__conta (query-nEH4) · Trusted / linkedin_ads · L2 INTERNAL
-- Grao: uma conta de anuncios do LinkedIn Ads. Chave: id_conta. Fonte: linkedin-ads-xiWu.
-- Gatilho: evento em linkedin-ads-xiWu (fonte manual). Criada em 2026-11-03.
-- LIMITACAO: a fonte entrega so a conta (campanhas, criativos e analytics com zero linhas). Sem Refined.
-- Nome divergente: descricao da fonte diz Grupo PMZ, a conta lida e Dislub Equador (513002261).
WITH a AS (SELECT * FROM `vanguardamartech_grupo_pmz_linkedin`.`linkedin_ads_ad_accounts`)
SELECT
  'linkedin-ads-xiWu' AS _fonte,
  CAST(a.id AS STRING) AS id_conta,
  a.name AS nome_conta,
  a.status AS status,
  a.currency AS moeda,
  a.type AS tipo,
  CAST(a.test AS STRING) = 'true' AS is_teste,
  a.reference AS referencia_organizacao,
  REGEXP_EXTRACT(a.reference, r'urn:li:organization:(\d+)') AS id_organizacao,
  ARRAY_TO_STRING(a.servingStatuses, ',') AS serving_statuses,
  a.version.versionTag AS versao,
  TIMESTAMP_MILLIS(CAST(a.changeAuditStamps.created.time AS INT64)) AS criada_em,
  TIMESTAMP_MILLIS(CAST(a.changeAuditStamps.lastModified.time AS INT64)) AS alterada_em,
  CURRENT_TIMESTAMP() AS _extraido_at,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM a
