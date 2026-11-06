-- trs_iclips__peca_grupo_cliente
-- Trusted / iClips. Grao: uma PECA (id_job_peca) com a atribuicao a GRUPO ECONOMICO de cliente que o Supabase calcula. Chave: id_job_peca.
-- Origem: vanguardamartech_raw.supabase_gold_vw_peca_cliente_ponte (fonte supabase-x0tz, diaria). Medido em 2026-10-19: 52.342 linhas, 52.342
-- job_peca_id distintos (uma linha por peca), 116 grupo_key, 261 executores, 293 tipos de peca.
-- O QUE ESTA PONTE ACRESCENTA, medido contra rfn_operacao__peca (134.883 pecas): 44.434 pecas casam por id_job_peca; dessas, 44.282 NAO tem
-- cliente_grupo na Refined de peca e so 152 tem (todas Grupo Nova Era, todas iguais). O grupo e o que entra; cliente por CNPJ ja existe na
-- trs_iclips__peca_atributo / rfn_operacao__peca e NAO e repetido aqui. 7.908 pecas desta ponte nao existem em trs_iclips__peca (flag) e 90.449 pecas
-- da Trusted nao estao na ponte: a ponte cobre 2024-2026 (por ano: 2024 704, 2025 27.432, 2026 22.858) e a Trusted cobre desde 2020.
-- A CHAVE DE GRUPO TEM CINCO FORMAS, medidas: 'G:<grupo>' 38.322 (grupo economico), raiz de CNPJ com 8 digitos 10.754 (todas existem como raiz em
-- rfn_cadastro__cliente), CPF com 11 digitos 644 (cliente pessoa fisica), 'N:<nome>' 350 (um cliente, por de-para) e SENTINELA 2.272 --
-- '(cliente sem receita)' 1.338, '(peca sem CNPJ)' 758, '(producao interna)' 176. `atribuivel` e exatamente NOT sentinela (zero divergencia).
-- ANO 1799 E SENTINELA DE DATA: 1.300 linhas com ano=1799 e mes=12 (a mesma sentinela 1800-01-01 do iClips, lida um mes antes). mes_referencia sai
-- NULL nelas, nunca uma data; ano_origem e mes_origem preservam o cru. Mes valido vai de 2021-06 a 2027-01 (1 linha em 2027).
-- O mes aqui NAO e o mes_referencia de rfn_operacao__peca: dos 44.434 pares, 37.189 coincidem e 6.961 diferem -- a ponte usa outro criterio de
-- data (nao declarado na origem). Para serie temporal de peca, a referencia continua sendo rfn_operacao__peca.
-- Nivel: L4 PERSONAL_DATA -- `executor_norm` e o nome normalizado de uma pessoa (261 valores). 46.780 linhas (89,4%) e 224 dos 261 executores
-- existem em meta_pessoa (pessoa canonica). A Refined (rfn_operacao__peca_grupo_mensal) conta executores distintos e nao emite nome.
WITH raw AS (
  SELECT
    job_peca_id                                                        AS id_job_peca,
    ano                                                                AS ano_origem,
    mes                                                                AS mes_origem,
    IF(ano < 2000, NULL, DATE(ano, mes, 1))                            AS mes_referencia,
    (ano < 2000)                                                       AS flag_mes_sentinela,
    grupo_key,
    grupo_nome,
    atribuivel,
    CASE WHEN STARTS_WITH(grupo_key, 'G:')                   THEN 'GRUPO'
         WHEN STARTS_WITH(grupo_key, 'N:')                   THEN 'NOME'
         WHEN REGEXP_CONTAINS(grupo_key, r'^\d{8}$')         THEN 'CNPJ_RAIZ'
         WHEN REGEXP_CONTAINS(grupo_key, r'^\d{11}$')        THEN 'CPF'
         WHEN STARTS_WITH(grupo_key, '(')                    THEN 'SENTINELA'
         ELSE 'OUTRO' END                                              AS tipo_chave_grupo,
    IF(REGEXP_CONTAINS(grupo_key, r'^\d{8}$'), grupo_key, NULL)        AS cnpj_raiz,
    piece_id                                                           AS id_peca_tipo,
    NULLIF(TRIM(piece_name), '')                                       AS nome_peca_tipo,
    NULLIF(TRIM(executor), '')                                         AS executor_norm
  FROM `vanguardamartech_raw`.`supabase_gold_vw_peca_cliente_ponte`
),
tratado AS (
  SELECT r.*,
    (p.id_job_peca IS NULL)                                            AS flag_peca_nao_catalogada,
    (t.id_peca IS NULL)                                                AS flag_peca_tipo_nao_catalogada,
    (pc.pessoa_norm IS NULL)                                           AS flag_executor_fora_da_pessoa_canonica,
    (r.atribuivel <> (r.tipo_chave_grupo <> 'SENTINELA'))              AS flag_atribuivel_diverge_da_chave
  FROM raw r
  LEFT JOIN (SELECT DISTINCT id_job_peca FROM `vanguardamartech_trusted`.`trs_iclips__peca`) p ON p.id_job_peca = r.id_job_peca
  LEFT JOIN (SELECT DISTINCT id_peca FROM `vanguardamartech_trusted`.`trs_iclips__peca_tipo`) t ON t.id_peca = r.id_peca_tipo
  LEFT JOIN (SELECT DISTINCT pessoa_norm FROM `vanguardamartech_raw`.`supabase_meta_pessoa`) pc ON pc.pessoa_norm = r.executor_norm
)
SELECT t.*, 'L4_PERSONAL_DATA' AS classificacao_dado, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte, 'UTC' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
