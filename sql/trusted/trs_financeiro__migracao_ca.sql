-- trs_financeiro__migracao_ca
-- Trusted / Financeiro. Grao: um REGISTRO DE AUDITORIA DA MIGRACAO iClips -> Conta Azul, em duas origens lado a lado (coluna `origem`):
--   DUPLICIDADE_CA = um GRUPO de parcelas duplicadas no Conta Azul (mesma pessoa, valor e vencimento; supabase_public_vw_ca_duplicidades, 324 grupos / 748 parcelas) ·
--   LACUNA_MIGRACAO = um LANCAMENTO do iClips avaliado quanto a migracao (supabase_public_vw_migracao_ca_gaps, 292 lancamentos).
-- Chave: id_registro = DUPLICIDADE_CA|<hash dos ids das parcelas> ou LACUNA_MIGRACAO|<codigo> (616 linhas, 616 chaves; medido em 2026-10-19).
-- Fonte supabase-x0tz (diaria). Cadencia desta Trusted: semanal (segunda 07:05 America/Manaus). Nivel: L4 PERSONAL_DATA (razao social, inclusive MEI com nome de pessoa).
-- MEDIDO (2026-10-19) - DUPLICIDADE: 748 ids de parcela, TODOS existem em trs_contazul__movimento (748 de 748); grupos de 2 a 8 parcelas; valor da parcela R$ 2.596.087,69
--   e EXCEDENTE (valor x (qtd - 1)) R$ 3.558.048,19 - e o que estaria contado a mais se cada grupo fosse uma parcela so; 26 grupos SEM pessoa; 66 grupos com ao menos uma
--   parcela marcada como migrada; 12 combinacoes de status. LACUNA: 292 codigos, TODOS em trs_financeiro__movimento (292 de 292); 2 populacoes (POP1_INADIMPLENTE_CUTOVER 149,
--   POP2_VENDA_MAIO 143); situacao: OK_MIGRADO 128 · NAO_MIGRADO_CLIENTE_EXISTE 150 · NAO_MIGRADO_CLIENTE_AUSENTE 6 · OK_MIGRADO_VENC_AJUSTADO 5 · PROVAVEL_CADASTRO_DIVERGENTE 3;
--   R$ 792.470,94; 291 com CNPJ de 14 digitos, 1 sem documento.
-- DOCUMENTO: so 14 (CNPJ) ou 11 (CPF) digitos; nao ha 13 digitos nas duas origens (zero repadronizacao). `(sem pessoa)` e sentinela e vira NULL (flag_sem_pessoa).
-- LIMITACOES - NAO CONTORNE: duplicidade e lacuna sao JULGAMENTO do Supabase (regra de negocio da migracao), nao fato do razao - esta Trusted os PRESERVA e nao os
--   recalcula; as duas origens tem graos diferentes e NAO SE SOMAM; `nivel` (0-4) e a escala do Supabase e nao tem tabela de dominio; `statuses` e `flags_migrado` sao
--   arrays por grupo (status distintos, nao alinhados com ids_parcelas).
WITH dup AS (
  SELECT
    'DUPLICIDADE_CA'                                                 AS origem,
    CONCAT('DUPLICIDADE_CA|', TO_HEX(MD5(TO_JSON_STRING(ids_parcelas))))        AS id_registro,
    CAST(NULL AS STRING)                                             AS codigo_lancamento_iclips,
    CAST(NULL AS STRING)                                             AS populacao,
    CAST(NULL AS STRING)                                             AS situacao,
    CAST(NULL AS INT64)                                              AS nivel,
    IF(cliente = '(sem pessoa)', NULL, NULLIF(TRIM(cliente), ''))    AS cliente_nome,
    (cliente = '(sem pessoa)' OR documento IS NULL)                  AS flag_sem_pessoa,
    NULLIF(REGEXP_REPLACE(IFNULL(documento, ''), r'[^0-9]', ''), '') AS documento_origem,
    valor                                                            AS valor_parcela,
    ROUND(valor * (qtd_parcelas - 1), 2)                             AS valor_excedente,
    data_vencimento,
    CAST(NULL AS DATE)                                               AS competencia,
    qtd_parcelas,
    statuses,
    flags_migrado,
    ids_parcelas
  FROM `vanguardamartech_raw`.`supabase_public_vw_ca_duplicidades`
),
gap AS (
  SELECT
    'LACUNA_MIGRACAO'                                                AS origem,
    CONCAT('LACUNA_MIGRACAO|', CAST(codigo AS STRING))               AS id_registro,
    CAST(codigo AS STRING)                                           AS codigo_lancamento_iclips,
    populacao,
    situacao,
    nivel,
    NULLIF(TRIM(razao_social), '')                                   AS cliente_nome,
    FALSE                                                            AS flag_sem_pessoa,
    NULLIF(REGEXP_REPLACE(IFNULL(cpf_cnpj, ''), r'[^0-9]', ''), '')  AS documento_origem,
    valor                                                            AS valor_parcela,
    CAST(NULL AS FLOAT64)                                            AS valor_excedente,
    vencimento                                                       AS data_vencimento,
    competencia,
    CAST(NULL AS INT64)                                              AS qtd_parcelas,
    CAST(NULL AS ARRAY<STRING>)                                      AS statuses,
    CAST(NULL AS ARRAY<BOOL>)                                        AS flags_migrado,
    CAST(NULL AS ARRAY<STRING>)                                      AS ids_parcelas
  FROM `vanguardamartech_raw`.`supabase_public_vw_migracao_ca_gaps`
),
uniao AS (
  SELECT * FROM dup UNION ALL SELECT * FROM gap
),
final AS (
  SELECT
    u.id_registro,
    u.origem,
    u.codigo_lancamento_iclips,
    u.populacao,
    u.situacao,
    (u.situacao LIKE 'OK_MIGRADO%')                                  AS is_migrado,
    u.nivel,
    u.cliente_nome,
    u.flag_sem_pessoa,
    IF(LENGTH(u.documento_origem) IN (11, 14), u.documento_origem, NULL) AS documento,
    u.documento_origem,
    (u.documento_origem IS NOT NULL AND LENGTH(u.documento_origem) NOT IN (11, 14)) AS flag_documento_invalido,
    u.valor_parcela,
    u.valor_excedente,
    u.data_vencimento,
    DATE_TRUNC(u.data_vencimento, MONTH)                             AS mes_vencimento,
    u.competencia,
    u.qtd_parcelas,
    u.statuses,
    u.flags_migrado,
    u.ids_parcelas,
    (u.origem = 'DUPLICIDADE_CA' AND TRUE IN UNNEST(u.flags_migrado)) AS flag_grupo_com_parcela_migrada
  FROM uniao u
)
SELECT
  f.*,
  (LENGTH(f.documento) = 14)         AS is_pj,
  (LENGTH(f.documento) = 11)         AS is_pf,
  'L4_PERSONAL_DATA'                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
