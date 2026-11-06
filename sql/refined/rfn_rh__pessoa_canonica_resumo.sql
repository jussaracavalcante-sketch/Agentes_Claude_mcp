-- rfn_rh__pessoa_canonica_resumo
-- Refined / rh. Grao: uma DIMENSAO x uma CHAVE -- ALIAS_POR_TIPO (um tipo de alias de trs_rh__pessoa_canonica) ou HOUSE_POR_SETOR (um setor de housing
-- de trs_rh__pessoa_house). Chave: id_resumo (dimensao | chave). Nivel: L2 INTERNAL -- so contagens; nenhum nome, e-mail, CPF ou chave de pessoa atravessa.
-- REGRA 1: ALIAS_POR_TIPO: qtd_linhas = aliases do tipo; qtd_pessoas_distintas = pessoas com ao menos um alias do tipo; qtd_pessoas_sem_este_alias =
--          total de pessoas canonicas (294) menos as cobertas -- e a COBERTURA da identidade por sistema: Qulture e-mail 294/294, iClips 256/294,
--          financeiro 176/294, contrato Qulture 144/294 (2026-10-19).
-- REGRA 2: HOUSE_POR_SETOR: qtd_linhas = pessoas (ou PJ) alocadas ao setor de housing; qtd_parece_pj e heuristica de texto (razao social), nao cadastro;
--          qtd_na_pessoa_canonica diz quantas das alocadas existem na semente de pessoas.
-- REGRA 3: as duas dimensoes NAO se somam entre si (a mesma pessoa esta nas duas); total de aliases = 1.272 e total de house = 68, separados.
-- LIMITACOES - NAO CONTORNE: a semente de pessoas e de 2026-08-10 e nunca foi editada; quem entrou depois nao esta aqui (nao e o headcount);
--   o setor de housing e centro de custo de CLIENTE (meta_param_no), nao departamento interno.
-- VALIDACAO 2026-10-19 (query inteira rodada sobre a Trusted materializada): 23 linhas, 23 chaves e hashes = 5 ALIAS_POR_TIPO (soma 1.272) + 18 HOUSE_POR_SETOR
--   (soma 68); cobertura por tipo FIN_CPF_CNPJ 176, ICLIPS_EXECUTOR_ID 256, NOME_NORM 294, QULTURE_CONTRACT 144, QULTURE_EMAIL 294 de 294 pessoas;
--   9 linhas parecem PJ, 51 existem na pessoa canonica, zero setor nao catalogado.
WITH alias AS (
  SELECT 'ALIAS_POR_TIPO' AS dimensao, match_tipo AS chave, match_tipo AS rotulo,
    COUNT(*)                                        AS qtd_linhas,
    COUNT(DISTINCT id_pessoa)                       AS qtd_pessoas_distintas,
    COUNTIF(tipo_documento = 'CPF')                 AS qtd_cpf,
    COUNTIF(tipo_documento = 'CNPJ')                AS qtd_cnpj,
    COUNTIF(tipo_documento = 'INVALIDO')            AS qtd_documento_invalido,
    COUNTIF(flag_pessoa_nao_catalogada)             AS qtd_pessoa_nao_catalogada,
    CAST(NULL AS INT64)                             AS qtd_parece_pj,
    CAST(NULL AS INT64)                             AS qtd_na_pessoa_canonica,
    CAST(NULL AS INT64)                             AS qtd_setor_nao_catalogado,
    MAX(_extraido_at)                               AS _extraido_trusted
  FROM `vanguardamartech_trusted`.`trs_rh__pessoa_canonica`
  GROUP BY match_tipo
),
house AS (
  SELECT 'HOUSE_POR_SETOR' AS dimensao, CAST(id_setor AS STRING) AS chave, ANY_VALUE(setor_nome) AS rotulo,
    COUNT(*)                                        AS qtd_linhas,
    COUNT(DISTINCT pessoa_norm)                     AS qtd_pessoas_distintas,
    CAST(NULL AS INT64)                             AS qtd_cpf,
    CAST(NULL AS INT64)                             AS qtd_cnpj,
    CAST(NULL AS INT64)                             AS qtd_documento_invalido,
    CAST(NULL AS INT64)                             AS qtd_pessoa_nao_catalogada,
    COUNTIF(flag_parece_pj)                         AS qtd_parece_pj,
    COUNTIF(flag_na_pessoa_canonica)                AS qtd_na_pessoa_canonica,
    COUNTIF(flag_setor_nao_catalogado)              AS qtd_setor_nao_catalogado,
    MAX(_extraido_at)                               AS _extraido_trusted
  FROM `vanguardamartech_trusted`.`trs_rh__pessoa_house`
  GROUP BY id_setor
),
agg AS (SELECT * FROM alias UNION ALL SELECT * FROM house),
total AS (SELECT COUNT(DISTINCT id_pessoa) AS total_pessoas_canonicas FROM `vanguardamartech_trusted`.`trs_rh__pessoa_canonica`),
calc AS (
  SELECT CONCAT(a.dimensao, '|', a.chave) AS id_resumo, a.*, t.total_pessoas_canonicas,
    IF(a.dimensao = 'ALIAS_POR_TIPO', t.total_pessoas_canonicas - a.qtd_pessoas_distintas, NULL) AS qtd_pessoas_sem_este_alias,
    IF(a.dimensao = 'ALIAS_POR_TIPO', SAFE_DIVIDE(a.qtd_pessoas_distintas, t.total_pessoas_canonicas), NULL) AS cobertura_da_identidade
  FROM agg a CROSS JOIN total t
)
SELECT c.*, 'L2_INTERNAL' AS classificacao_dado, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte, 'UTC' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(c))) AS _payload_hash
FROM calc c
