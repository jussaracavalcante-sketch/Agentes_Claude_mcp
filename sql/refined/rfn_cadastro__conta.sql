-- rfn_cadastro__conta
-- Dimensao de conta de midia resolvida por ID, com identidade juridica vinda do iClips.
-- Grao: uma linha por (plataforma, id_conta_plataforma). Chave: id_conta.

WITH mapa_cliente AS (
  SELECT * FROM UNNEST([
    STRUCT('GOOGLE_ADS'   AS plataforma, '1752443056'      AS id_conta_plataforma,
           'ACESSO_SAUDE' AS id_cliente,
           'rotulo identico nas duas plataformas, corroborado pela razao social CLINICA MEDICA ACESSO SAUDE MANAUS LTDA (2026-09-15)' AS evidencia_do_vinculo),
    STRUCT('FACEBOOK_ADS', '261401095311098', 'ACESSO_SAUDE',
           'rotulo identico nas duas plataformas, corroborado pela razao social CLINICA MEDICA ACESSO SAUDE MANAUS LTDA (2026-09-15)')
  ])
),

-- PONTE JURIDICA DO ICLIPS ------------------------------------------------------
-- O iClips e a unica fonte da base que publica CNPJ de cliente. As duas tabelas
-- concordam integralmente depois de normalizar: zero nomes com CNPJ divergente.
ic_bruto AS (
  SELECT DISTINCT
    REGEXP_REPLACE(REGEXP_REPLACE(UPPER(TRIM(cliente_nome)),
      r'\s+(LTDA|S\s*A|S/A|SA|EIRELI|ME|EPP|SPE\s+LTDA|LIMITADA)\.?$', ''), r'\s+', ' ') AS nome_n,
    REGEXP_REPLACE(cliente_cnpj, r'[^0-9]', '')                                          AS cnpj
  FROM `vanguardamartech_trusted.trs_iclips__projeto`
  WHERE cliente_nome IS NOT NULL AND cliente_cnpj IS NOT NULL
  UNION DISTINCT
  SELECT DISTINCT
    REGEXP_REPLACE(REGEXP_REPLACE(UPPER(TRIM(cliente_nome)),
      r'\s+(LTDA|S\s*A|S/A|SA|EIRELI|ME|EPP|SPE\s+LTDA|LIMITADA)\.?$', ''), r'\s+', ' '),
    cliente_cnpj
  FROM `vanguardamartech_trusted.trs_iclips__peca_atributo`
  WHERE cliente_nome IS NOT NULL AND cnpj_valido
),
ic_valido AS (SELECT * FROM ic_bruto WHERE LENGTH(cnpj) = 14),
-- Nome que aponta para mais de um CNPJ NAO e desempatado: vira ausencia declarada.
ic_amb AS (SELECT nome_n FROM ic_valido GROUP BY 1 HAVING COUNT(DISTINCT cnpj) > 1),
ic AS (
  SELECT v.nome_n, ANY_VALUE(v.cnpj) AS cnpj
  FROM ic_valido v LEFT JOIN ic_amb a USING (nome_n)
  WHERE a.nome_n IS NULL
  GROUP BY 1
),

fb_integradas AS (
  SELECT id_conta, ANY_VALUE(_fonte) AS fonte_nekt
  FROM `vanguardamartech_trusted_facebook_ads.trs_facebook_ads__insight_diario`
  GROUP BY id_conta
),
google AS (
  SELECT
    'GOOGLE_ADS'                       AS plataforma,
    CAST(id_conta AS STRING)           AS id_conta_plataforma,
    conta                              AS conta,
    cliente                            AS cliente,
    CAST(NULL AS STRING)               AS razao_social,
    moeda                              AS moeda,
    CAST(NULL AS STRING)               AS fuso_conta,
    CAST(NULL AS STRING)               AS status_conta,
    CAST(NULL AS BOOL)                 AS ativa_na_plataforma,
    integrada_na_nekt                  AS integrada_na_nekt,
    fonte_nekt                         AS fonte_nekt,
    rotulo_customizado                 AS rotulo_customizado,
    rotulo_diverge_da_plataforma       AS rotulo_diverge_da_plataforma,
    FALSE                              AS dimensao_congelada,
    _extraido_at                       AS _extraido_at,
    _fonte                             AS _fonte
  FROM `vanguardamartech_trusted.trs_google_ads__conta`
),
facebook AS (
  SELECT
    'FACEBOOK_ADS',
    CAST(c.id_conta AS STRING),
    c.conta,
    c.cliente,
    NULLIF(TRIM(c.negocio), ''),
    c.moeda,
    c.fuso_conta,
    c.status_conta,
    c.ativa,
    i.id_conta IS NOT NULL,
    i.fonte_nekt,
    CAST(NULL AS BOOL),
    CAST(NULL AS BOOL),
    c.dimensao_congelada,
    c._extraido_at,
    c._fonte
  FROM `vanguardamartech_trusted_facebook_ads.trs_facebook_ads__conta` c
  LEFT JOIN fb_integradas i ON i.id_conta = c.id_conta
),
uniao AS (SELECT * FROM google UNION ALL SELECT * FROM facebook),
enriquecida AS (
  SELECT
    u.*,
    CASE WHEN u.razao_social IS NULL THEN NULL ELSE
      REGEXP_REPLACE(REGEXP_REPLACE(UPPER(u.razao_social),
        r'\s+(LTDA|S\s*A|S/A|SA|EIRELI|ME|EPP|SPE\s+LTDA|LIMITADA)\.?$', ''), r'\s+', ' ')
    END AS razao_social_normalizada,
    REGEXP_REPLACE(REGEXP_REPLACE(UPPER(TRIM(u.cliente)),
      r'\s+(LTDA|S\s*A|S/A|SA|EIRELI|ME|EPP|SPE\s+LTDA|LIMITADA)\.?$', ''), r'\s+', ' ') AS cliente_normalizado
  FROM uniao u
),
-- Razao social vence o rotulo: nome juridico e evidencia mais forte que rotulo editavel.
resolvida AS (
  SELECT
    e.*,
    COALESCE(por_rs.cnpj, por_rotulo.cnpj)                                AS cnpj,
    CASE WHEN por_rs.cnpj     IS NOT NULL THEN 'RAZAO_SOCIAL'
         WHEN por_rotulo.cnpj IS NOT NULL THEN 'ROTULO_DA_CONTA' END      AS cnpj_resolvido_por,
    (e.cliente_normalizado      IN (SELECT nome_n FROM ic_amb)
     OR e.razao_social_normalizada IN (SELECT nome_n FROM ic_amb))        AS cnpj_ambiguo_na_origem
  FROM enriquecida e
  LEFT JOIN ic por_rs     ON e.razao_social_normalizada = por_rs.nome_n
  LEFT JOIN ic por_rotulo ON e.cliente_normalizado      = por_rotulo.nome_n
)
SELECT
  CONCAT(r.plataforma, ':', r.id_conta_plataforma)                        AS id_conta,
  r.plataforma,
  r.id_conta_plataforma,
  r.conta,
  r.cliente,
  r.cliente_normalizado,
  r.razao_social,
  r.razao_social_normalizada,
  IF(r.razao_social_normalizada IS NULL, NULL,
     TO_HEX(MD5(r.razao_social_normalizada)))                             AS id_entidade_legal,
  r.cnpj,
  r.cnpj_resolvido_por,
  r.cnpj IS NOT NULL                                                      AS identidade_juridica_resolvida,
  r.cnpj_ambiguo_na_origem,
  m.id_cliente                                                            AS id_cliente,
  m.id_cliente IS NOT NULL                                                AS cliente_canonico_resolvido,
  m.evidencia_do_vinculo                                                  AS evidencia_do_vinculo,
  r.moeda,
  r.fuso_conta,
  r.status_conta,
  r.ativa_na_plataforma,
  r.integrada_na_nekt,
  r.fonte_nekt,
  r.rotulo_customizado,
  r.rotulo_diverge_da_plataforma,
  r.dimensao_congelada,
  r.razao_social IS NULL                                                  AS sem_razao_social,
  r._extraido_at,
  r._fonte,
  TO_HEX(MD5(TO_JSON_STRING(r)))                                          AS _payload_hash
FROM resolvida r
LEFT JOIN mapa_cliente m
  ON  m.plataforma          = r.plataforma
  AND m.id_conta_plataforma = r.id_conta_plataforma
