-- trs_conexa__dominio
-- Trusted / Conexa (VBOT). Grao: um item de DOMINIO do Conexa (categoria de receita, conta financeira, fornecedor,
-- motivo de churn, plano, produto, subcategoria de despesa, usuario). Chave: id_chave = dominio:id_origem.
-- Nivel: L3 CONFIDENTIAL (preco de plano e produto, fornecedor com CNPJ); USUARIO traz nome de colaborador
-- (e-mail e telefone NAO sao emitidos).
--
-- ORIGEM. Oito dimensoes tipadas do Supabase (supabase-x0tz): dim_categoria_vbot (11), dim_conta_financeira_vbot (9),
-- dim_fornecedor_vbot (83), dim_motivo_churn_vbot (4), dim_plano_vbot (7), dim_produto_vbot (34),
-- dim_subcategoria_despesa_vbot (86), dim_usuario_vbot (95). Medido em 18/10/2026: 329 linhas, 329 chaves.
-- Os streams bronze_conexa__{accounts, service_categories, plans, products, suppliers, persons, bill_categories} (e
-- seus gemeos public_raw_conexa_*, identicos por fingerprint de payload_hash nos 12 pares medidos) tem as MESMAS chaves
-- distintas (9, 11, 7, 34, 83, 95) em log de versoes e nao foram usados.
--
-- ARMADILHA JA REGISTRADA E RESPEITADA: dim_categoria_vbot e catalogo de RECEITA (Receita Recorrente, Setup, Mídia On);
-- a despesa usa as subcategorias de outro plano de contas. Por isso os dominios CATEGORIA_RECEITA e SUBCATEGORIA_DESPESA
-- ficam separados e NENHUM junta com o outro por id: o id coincide por acaso numerico.
--
-- CAMPOS MORTOS: dim_motivo_churn_vbot.label e NULL nos 4 (so ha o id e conta_como_churn): o nome do motivo NAO existe
-- no Conexa publicado; fornecedor so tem CNPJ, razao social e ramo em 11 de 83 (e-mail e telefone em 3 de 83).
--
-- LIMITACAO -- NAO CONTORNE: dominio mapeia id para nome, nao e fato; nao somar valor_numerico entre dominios (preco de plano
-- e preco de produto sao catalogo, nao faturamento).
WITH uniao AS (
  SELECT 'CATEGORIA_RECEITA' AS dominio, CAST(conexa_id AS STRING) AS id_origem, nome, CAST(NULL AS STRING) AS id_pai,
         CAST(NULL AS STRING) AS nome_pai, is_ativo, CAST(NULL AS FLOAT64) AS valor_numerico, CAST(cnae_code AS STRING) AS atributo_texto,
         CAST(NULL AS STRING) AS documento_origem, CAST(NULL AS BOOL) AS exige_nf, CAST(NULL AS BOOL) AS sujeita_juros_atraso,
         CAST(NULL AS BOOL) AS conta_como_churn, processed_at
  FROM `vanguardamartech_raw`.`supabase_public_dim_categoria_vbot`
  UNION ALL
  SELECT 'CONTA_FINANCEIRA', CAST(conexa_id AS STRING), nome, NULL, NULL, is_ativo, NULL, CAST(accounting_code AS STRING), NULL, NULL, NULL, NULL, processed_at
  FROM `vanguardamartech_raw`.`supabase_public_dim_conta_financeira_vbot`
  UNION ALL
  SELECT 'FORNECEDOR', CAST(conexa_id AS STRING), nome, NULL, NULL, CAST(NULL AS BOOL), NULL, NULLIF(TRIM(CONCAT(IFNULL(razao_social, ''), IF(ramo_atividade IS NOT NULL, CONCAT(' | ', ramo_atividade), ''))), ''),
         CAST(cnpj AS STRING), NULL, NULL, NULL, processed_at
  FROM `vanguardamartech_raw`.`supabase_public_dim_fornecedor_vbot`
  UNION ALL
  SELECT 'MOTIVO_CHURN', CAST(end_reason_id AS STRING), CAST(label AS STRING), NULL, NULL, CAST(NULL AS BOOL), NULL, NULL, NULL, NULL, NULL, conta_como_churn, processed_at
  FROM `vanguardamartech_raw`.`supabase_public_dim_motivo_churn_vbot`
  UNION ALL
  SELECT 'PLANO', CAST(conexa_id AS STRING), nome, NULL, NULL, ativo, CAST(valor AS FLOAT64), CAST(ciclo AS STRING), NULL, NULL, NULL, NULL, processed_at
  FROM `vanguardamartech_raw`.`supabase_public_dim_plano_vbot`
  UNION ALL
  SELECT 'PRODUTO', CAST(conexa_id AS STRING), nome, CAST(service_category_id AS STRING), NULL, ativo, CAST(preco AS FLOAT64),
         IF(is_default, 'padrao', IF(is_consumivel, 'consumivel', NULL)), NULL, NULL, NULL, NULL, processed_at
  FROM `vanguardamartech_raw`.`supabase_public_dim_produto_vbot`
  UNION ALL
  SELECT 'SUBCATEGORIA_DESPESA', CAST(subcategory_id AS STRING), subcategory_nome, CAST(category_id AS STRING), category_nome, is_ativo, NULL, NULL, NULL,
         exige_nf, sujeita_juros_atraso, NULL, processed_at
  FROM `vanguardamartech_raw`.`supabase_public_dim_subcategoria_despesa_vbot`
  UNION ALL
  SELECT 'USUARIO', CAST(conexa_id AS STRING), nome, NULL, NULL, is_ativo, NULL, NULLIF(TRIM(CAST(funcao AS STRING)), ''), NULL, NULL, NULL, NULL, processed_at
  FROM `vanguardamartech_raw`.`supabase_public_dim_usuario_vbot`
)
SELECT
  CONCAT(dominio, ':', id_origem)                                        AS id_chave,
  dominio,
  id_origem,
  NULLIF(TRIM(nome), '')                                                 AS nome,
  NULLIF(id_pai, '')                                                     AS id_pai,
  NULLIF(TRIM(nome_pai), '')                                             AS nome_pai,
  is_ativo,
  valor_numerico,
  NULLIF(TRIM(atributo_texto), '')                                       AS atributo_texto,
  IF(LENGTH(REGEXP_REPLACE(IFNULL(documento_origem, ''), r'\D', '')) IN (11, 14), REGEXP_REPLACE(documento_origem, r'\D', ''), NULL) AS documento,
  (documento_origem IS NOT NULL AND documento_origem <> '' AND LENGTH(REGEXP_REPLACE(documento_origem, r'\D', '')) NOT IN (11, 14)) AS flag_documento_invalido,
  exige_nf,
  sujeita_juros_atraso,
  conta_como_churn,
  (nome IS NULL OR TRIM(nome) = '')                                      AS flag_sem_nome,
  DATE(processed_at, 'America/Sao_Paulo')                                AS derivado_atualizado_em,
  CURRENT_TIMESTAMP()                                                    AS _extraido_at,
  'supabase-x0tz'                                                        AS _fonte,
  'America/Sao_Paulo'                                                    AS _fuso,
  TO_HEX(MD5(CONCAT(dominio, id_origem, IFNULL(nome, ''), IFNULL(CAST(is_ativo AS STRING), ''), IFNULL(CAST(valor_numerico AS STRING), '')))) AS _payload_hash
FROM uniao
