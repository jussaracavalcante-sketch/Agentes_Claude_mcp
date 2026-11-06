-- trs_financeiro__dicionario
-- Trusted / Financeiro. Grao: uma entrada de DICIONARIO/PARAMETRO da gestao financeira do Supabase, identificada por (origem, chave, chave_2).
-- Reune 17 tabelas pequenas de de-para e criterios (meta_*): PARAM_NO (arvore de centros de custo e classificacao de DRE, 507), PARAM_DEPARA (valor de
-- origem -> no da arvore, 629), CLIENTE_GRUPO (75), CLIENTE_HOUSING (22), DEPARA_CLIENTE (27), PI_CLIENTE_GRUPO (46), PECA_CLIENTE (8),
-- VBOT_GRUPO (6), VBOT_GRUPO_CLIENTE (17), FIN_VEICULO (93), MIDIAOFF_BUCKET (20), DEPARA_CUSTO_CONTA (29), CATEGORIA_COMPONENTE (6),
-- DRE_CLIENTE_CRITERIO (57), CADASTRO_CLIENTE_ICLIPS (202), PARAM_PENDENTE (4), DRE_NAO_RECORRENTE (1). Origem: vanguardamartech_raw.supabase_meta_* (fonte supabase-x0tz).
-- Nivel: L3 CONFIDENTIAL (agrupamento de clientes, documento de veiculos de midia). O esquema e COMUM por convencao (chave, chave_2, valor, valor_2) e o
-- significado de cada coluna esta no mapa abaixo; atributos_json guarda o resto, sem perder coluna.
--   PARAM_NO: chave=id, chave_2=parent_id, valor=nome, valor_2=eixo|nivel|tipo, status=ativo/inativo; JSON: dre_bucket, grupo_fcx, fcx_subgrupo, dre_incluir, is_conta_ordem, ordem
--   PARAM_DEPARA: chave=erp|dimensao, chave_2=valor_origem, valor=no_id, valor_2=eixo, status
--   CLIENTE_GRUPO: chave=raiz de CNPJ (8 digitos), valor=grupo, valor_2=nome_exibicao | CLIENTE_HOUSING: chave=setor_id, chave_2=alvo_tipo, valor=alvo_key, valor_2=origem
--   DEPARA_CLIENTE: chave=cliente do PI normalizado, chave_2=id_pessoa (Conta Azul), valor=nome no Conta Azul, valor_2=match_tipo | PI_CLIENTE_GRUPO: chave=cliente do PI, valor=grupo_key
--   PECA_CLIENTE: chave=match_tipo, chave_2=padrao, valor=destino | VBOT_GRUPO: chave=tag_id, valor=nome | VBOT_GRUPO_CLIENTE: chave=customer_id, chave_2=tag_id
--   FIN_VEICULO: chave=documento (CNPJ do veiculo), valor=nome | MIDIAOFF_BUCKET: chave=origem, chave_2=valor, valor=bucket | DEPARA_CUSTO_CONTA: chave=conta_key, chave_2=customer_id, valor=conta
--   CATEGORIA_COMPONENTE: chave=componente, chave_2=categoria_id, valor=categoria_nome, valor_2=confianca | DRE_CLIENTE_CRITERIO: chave=setor_id, chave_2=tipo, valor=direcionador
--   CADASTRO_CLIENTE_ICLIPS: chave=CNPJ (so digitos), chave_2=nome normalizado, valor=nome, valor_2=grupo | PARAM_PENDENTE: chave=erp|dimensao, valor=valor_origem, valor_2=n_linhas
-- id_linha = origem|chave|chave_2|ordinal (chave composta por prevenção: nem todas as tabelas de origem tem chave unica declarada).
-- grupo e a decisao do SUPABASE: NAO vale como chave de conta (R-003). Ficam de fora, de proposito: meta_bi_acesso (e-mails e permissoes de painel),
-- meta_eb_conta_depara (numero de agencia e conta bancaria) e as tabelas de RH (tratadas a parte).
SELECT
  CONCAT(origem, '|', IFNULL(chave, ''), '|', IFNULL(chave_2, ''), '|', CAST(ROW_NUMBER() OVER (PARTITION BY origem, IFNULL(chave, ''), IFNULL(chave_2, '') ORDER BY IFNULL(valor, '')) AS STRING)) AS id_linha,
  a.*,
  'L3_CONFIDENTIAL'                  AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(a)))     AS _payload_hash
FROM (
  SELECT 'PARAM_NO' AS origem, CAST(id AS STRING) AS chave, CAST(parent_id AS STRING) AS chave_2, nome AS valor, CONCAT(IFNULL(eixo, ''), '|', IFNULL(CAST(nivel AS STRING), ''), '|', IFNULL(tipo, '')) AS valor_2,
         IF(ativo, 'ativo', 'inativo') AS status, CAST(NULL AS STRING) AS obs,
         TO_JSON_STRING(STRUCT(dre_bucket, grupo_fcx, fcx_subgrupo, dre_incluir, is_conta_ordem, ordem)) AS atributos_json,
         atualizado_em, atualizado_por
  FROM vanguardamartech_raw.supabase_meta_param_no
  UNION ALL
  SELECT 'PARAM_DEPARA', CONCAT(IFNULL(erp, ''), '|', IFNULL(dimensao, '')), valor_origem, CAST(no_id AS STRING), eixo, status, obs, NULL, atualizado_em, atualizado_por
  FROM vanguardamartech_raw.supabase_meta_param_depara
  UNION ALL
  SELECT 'CLIENTE_GRUPO', raiz, NULL, grupo, nome_exibicao, status, obs, TO_JSON_STRING(STRUCT(origem)), atualizado_em, atualizado_por
  FROM vanguardamartech_raw.supabase_meta_cliente_grupo
  UNION ALL
  SELECT 'CLIENTE_HOUSING', CAST(setor_id AS STRING), alvo_tipo, alvo_key, origem, IF(revisar, 'revisar', NULL), obs, NULL, atualizado_em, atualizado_por
  FROM vanguardamartech_raw.supabase_meta_cliente_housing
  UNION ALL
  SELECT 'DEPARA_CLIENTE', pi_cliente_norm, id_pessoa, nome_ca, match_tipo, status, obs, TO_JSON_STRING(STRUCT(score)), atualizado_em, atualizado_por
  FROM vanguardamartech_raw.supabase_meta_depara_cliente
  UNION ALL
  SELECT 'PI_CLIENTE_GRUPO', cliente_pi, NULL, grupo_key, origem, NULL, observacao, NULL, atualizado_em, atualizado_por
  FROM vanguardamartech_raw.supabase_meta_pi_cliente_depara
  UNION ALL
  SELECT 'PECA_CLIENTE', match_tipo, padrao, destino_grupo_key, origem, NULL, obs, NULL, atualizado_em, atualizado_por
  FROM vanguardamartech_raw.supabase_meta_peca_cliente_depara
  UNION ALL
  SELECT 'VBOT_GRUPO', CAST(tag_id AS STRING), NULL, nome, origem, NULL, obs, NULL, atualizado_em, atualizado_por
  FROM vanguardamartech_raw.supabase_meta_vbot_grupo
  UNION ALL
  SELECT 'VBOT_GRUPO_CLIENTE', CAST(customer_id AS STRING), CAST(tag_id AS STRING), NULL, NULL, NULL, obs, NULL, atualizado_em, atualizado_por
  FROM vanguardamartech_raw.supabase_meta_vbot_grupo_cliente
  UNION ALL
  SELECT 'FIN_VEICULO', NULLIF(REGEXP_REPLACE(IFNULL(documento, ''), r'[^0-9]', ''), ''), NULL, nome, origem, IF(ativo, 'ativo', 'inativo'), NULL, NULL, CAST(NULL AS TIMESTAMP), CAST(NULL AS STRING)
  FROM vanguardamartech_raw.supabase_meta_fin_veiculo
  UNION ALL
  SELECT 'MIDIAOFF_BUCKET', origem, valor, bucket, NULL, NULL, NULL, NULL, CAST(NULL AS TIMESTAMP), CAST(NULL AS STRING)
  FROM vanguardamartech_raw.supabase_meta_midiaoff_bucket
  UNION ALL
  SELECT 'DEPARA_CUSTO_CONTA', conta_key, CAST(customer_id AS STRING), conta_exemplo, IF(sem_cliente, 'sem_cliente', NULL), NULL, obs, TO_JSON_STRING(STRUCT(motivo)), atualizado_em, atualizado_por
  FROM vanguardamartech_raw.supabase_meta_depara_custo_conta
  UNION ALL
  SELECT 'CATEGORIA_COMPONENTE', componente, CAST(categoria_id AS STRING), categoria_nome, confianca, NULL, obs, TO_JSON_STRING(STRUCT(componente_label)), atualizado_em, atualizado_por
  FROM vanguardamartech_raw.supabase_meta_depara_categoria_componente
  UNION ALL
  SELECT 'DRE_CLIENTE_CRITERIO', CAST(setor_id AS STRING), tipo, direcionador, origem, NULL, obs, NULL, atualizado_em, atualizado_por
  FROM vanguardamartech_raw.supabase_meta_dre_cliente_criterio
  UNION ALL
  SELECT 'CADASTRO_CLIENTE_ICLIPS', NULLIF(REGEXP_REPLACE(IFNULL(cnpj, ''), r'[^0-9]', ''), ''), nome_norm, nome, NULLIF(TRIM(grupo), ''), NULL, NULL, TO_JSON_STRING(STRUCT(uf, cidade)), carregado_em, CAST(NULL AS STRING)
  FROM vanguardamartech_raw.supabase_meta_iclips_cadastro_cliente
  UNION ALL
  SELECT 'PARAM_PENDENTE', CONCAT(IFNULL(erp, ''), '|', IFNULL(dimensao, '')), NULL, valor_origem, CAST(n_linhas AS STRING), NULL, NULL, TO_JSON_STRING(STRUCT(valor_total)), CAST(NULL AS TIMESTAMP), CAST(NULL AS STRING)
  FROM vanguardamartech_raw.supabase_meta_param_pendente
  UNION ALL
  SELECT 'DRE_NAO_RECORRENTE', subcategoria, NULL, NULL, NULL, IF(ativo, 'ativo', 'inativo'), NULL, NULL, criado_em, CAST(NULL AS STRING)
  FROM vanguardamartech_raw.supabase_meta_dre_nao_recorrente
) a
