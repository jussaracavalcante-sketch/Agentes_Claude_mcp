-- trs_financeiro__parametro_auditoria
-- Trusted / Financeiro. Grao: um EVENTO DE AUDITORIA dos parametros financeiros do Supabase, em duas origens (coluna `origem`):
--   PARAM_DEPARA_AUDIT = uma edicao (insert/update) do de-para da DRE e do centro de custo (supabase_meta_param_depara_audit, 138) ·
--   CONTA_SEM_API = uma anotacao de evidencia sobre conta do iClips que a API nao devolve (supabase_meta_iclips_conta_sem_api, 4).
-- Chave: id_evento = PARAM_DEPARA_AUDIT|<id> ou CONTA_SEM_API|<conta> (142 linhas, 142 chaves; medido em 2026-10-19).
-- Fonte supabase-x0tz (diaria). Cadencia desta Trusted: semanal (segunda 07:10 America/Manaus). Nivel: L4 PERSONAL_DATA (e-mail do autor da edicao; 2 autores).
-- MEDIDO (2026-10-19): 138 edicoes de 2026-06-26 a 2026-09-04 (UTC; convertido para America/Sao_Paulo em `evento_em_local`): insert 107 · update 31; dimensao
--   classificacao_dre 26 (nos da arvore da DRE: id, eixo, nome, tipo, nivel, parent) · centro_custo 29 · subcategoria 83 (linhas de de-para por ERP: conta_azul 73, iclips 20,
--   vbot 8, `_no_` 37 = no da arvore). `valores_antes` e NULL nos 107 inserts (esperado). Os 4 de CONTA_SEM_API sao de 2026-07-17 e a evidencia cita R$ 3.616.506,97 em
--   1.016 lancamentos da conta `INATIVO BRM - CONTA AZUL - CC - BOLETOS` restaurados por inferencia (ja citado em trs_financeiro__mov_classif).
-- O JSON e preservado em `valores_antes_json` e `valores_depois_json`; `no_id_depois`, `status_depois`, `nome_no_depois`, `tipo_no_depois` e `nivel_no_depois` sao extraidos
--   do `depois` para leitura sem parse. `erp` = `_no_` significa no da arvore (nao e ERP) e sai como flag_e_no_da_arvore.
-- LIMITACOES - NAO CONTORNE: e trilha de auditoria, nao o de-para vigente (o vigente esta em trs_financeiro__dicionario); nao ha evento de delete na origem;
--   a evidencia de CONTA_SEM_API e texto livre e nao foi reavaliada aqui.
WITH au AS (
  SELECT
    'PARAM_DEPARA_AUDIT'                                             AS origem,
    CONCAT('PARAM_DEPARA_AUDIT|', CAST(id AS STRING))                AS id_evento,
    id                                                               AS id_origem,
    NULLIF(TRIM(erp), '')                                            AS erp,
    (erp = '_no_')                                                   AS flag_e_no_da_arvore,
    NULLIF(TRIM(dimensao), '')                                       AS dimensao,
    NULLIF(TRIM(valor_origem), '')                                   AS valor_origem,
    NULLIF(TRIM(acao), '')                                           AS acao,
    valores_antes                                                    AS valores_antes_json,
    valores_depois                                                   AS valores_depois_json,
    SAFE_CAST(COALESCE(JSON_VALUE(valores_depois, '$.no_id'), JSON_VALUE(valores_depois, '$.id')) AS INT64) AS no_id_depois,
    JSON_VALUE(valores_depois, '$.status')                           AS status_depois,
    JSON_VALUE(valores_depois, '$.nome')                             AS nome_no_depois,
    JSON_VALUE(valores_depois, '$.tipo')                             AS tipo_no_depois,
    SAFE_CAST(JSON_VALUE(valores_depois, '$.nivel') AS INT64)        AS nivel_no_depois,
    NULLIF(TRIM(mudado_por), '')                                     AS autor,
    mudado_em                                                        AS evento_em,
    CAST(NULL AS STRING)                                             AS conta_iclips,
    CAST(NULL AS STRING)                                             AS evidencia
  FROM `vanguardamartech_raw`.`supabase_meta_param_depara_audit`
),
cs AS (
  SELECT
    'CONTA_SEM_API'                                                  AS origem,
    CONCAT('CONTA_SEM_API|', conta)                                  AS id_evento,
    CAST(NULL AS INT64)                                              AS id_origem,
    'iclips'                                                         AS erp,
    FALSE                                                            AS flag_e_no_da_arvore,
    'conta_iclips'                                                   AS dimensao,
    conta                                                            AS valor_origem,
    'anotacao'                                                       AS acao,
    CAST(NULL AS STRING)                                             AS valores_antes_json,
    CAST(NULL AS STRING)                                             AS valores_depois_json,
    CAST(NULL AS INT64)                                              AS no_id_depois,
    CAST(NULL AS STRING)                                             AS status_depois,
    CAST(NULL AS STRING)                                             AS nome_no_depois,
    CAST(NULL AS STRING)                                             AS tipo_no_depois,
    CAST(NULL AS INT64)                                              AS nivel_no_depois,
    CAST(NULL AS STRING)                                             AS autor,
    criado_em                                                        AS evento_em,
    conta                                                            AS conta_iclips,
    NULLIF(TRIM(evidencia), '')                                      AS evidencia
  FROM `vanguardamartech_raw`.`supabase_meta_iclips_conta_sem_api`
),
uniao AS (
  SELECT * FROM au UNION ALL SELECT * FROM cs
),
final AS (
  SELECT
    u.*,
    DATETIME(u.evento_em, 'America/Sao_Paulo')                       AS evento_em_local,
    DATE_TRUNC(DATE(u.evento_em, 'America/Sao_Paulo'), MONTH)        AS mes_evento,
    (u.acao = 'insert' AND u.valores_antes_json IS NOT NULL)         AS flag_insert_com_antes,
    (u.acao = 'update' AND u.valores_antes_json IS NULL)             AS flag_update_sem_antes
  FROM uniao u
)
SELECT
  f.*,
  'L4_PERSONAL_DATA'                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
