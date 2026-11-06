-- trs_vjob__dominio · query-OEnU · Trusted / VJOB · L2 INTERNAL. Grao: um item de dominio. Chave: (dominio, id_origem).
-- Origem: mysql-yIOn, 34 tabelas pequenas de dominio. Id sozinho NAO e chave: cada tabela tem a sua sequencia.
-- `dominio_pai` diz contra qual dominio `id_pai` resolve. Zero em id_pai e sentinela e vira NULL.
-- Status numerico sai cru (`status_origem`): o significado nao esta na base. Rotulo nao e chave.
WITH base AS (
SELECT 'tipo_desenvolvimento_advisory' AS dominio, 'advisory_tbtiposdesenvolvimento' AS tabela_origem, CAST(id AS INT64) AS id_origem, NULLIF(TRIM(CAST(nometipo AS STRING)),'') AS nome, NULL AS nome_completo, NULL AS codigo, NULL AS id_pai, NULL AS dominio_pai, NULL AS ordem, NULL AS ativo, CAST(status AS INT64) AS status_origem, NULL AS data_ref, NULL AS atributo_texto, NULL AS atributo_num, NULL AS criado_em FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_advisory_tbtiposdesenvolvimento`
UNION ALL
SELECT 'tipo_desenvolvimento_tarefas', 'tarefas_tbtiposdesenvolvimento', CAST(id AS INT64), NULLIF(TRIM(CAST(nometipo AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, CAST(status AS INT64), NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tarefas_tbtiposdesenvolvimento`
UNION ALL
SELECT 'tipo_desenvolvimento_legado', 'tbtiposdesenvolvimento', CAST(id AS INT64), NULLIF(TRIM(CAST(nometipo AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, CAST(status AS INT64), NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbtiposdesenvolvimento`
UNION ALL
SELECT 'tipo_geral', 'tbtiposgeral', CAST(id AS INT64), NULLIF(TRIM(CAST(nometipo AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULLIF(TRIM(CAST(ids_setores AS STRING)),''), NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbtiposgeral`
UNION ALL
SELECT 'categoria', 'tbcategoria', CAST(id AS INT64), NULLIF(TRIM(CAST(categoria AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbcategoria`
UNION ALL
SELECT 'etapa_a', 'tbetapas', CAST(id AS INT64), NULLIF(TRIM(CAST(etapa AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbetapas`
UNION ALL
SELECT 'etapa_b', 'tbetapas2', CAST(id AS INT64), NULLIF(TRIM(CAST(etapa AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbetapas2`
UNION ALL
SELECT 'etapa_onboarding', 'tbetapas_onboarding', CAST(id AS INT64), NULLIF(TRIM(CAST(etapa AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbetapas_onboarding`
UNION ALL
SELECT 'fase_checklist', 'tbfaseschecklist', CAST(id AS INT64), NULLIF(TRIM(CAST(nomefase AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbfaseschecklist`
UNION ALL
SELECT 'funcao', 'tbfuncao', CAST(id AS INT64), NULLIF(TRIM(CAST(funcao AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbfuncao`
UNION ALL
SELECT 'grupo_intranet', 'tbgrupo', CAST(id AS INT64), NULLIF(TRIM(CAST(grupo AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbgrupo`
UNION ALL
SELECT 'grupo_download', 'tbdownloadgrupo', CAST(id AS INT64), NULLIF(TRIM(CAST(grupo AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbdownloadgrupo`
UNION ALL
SELECT 'grupo_link', 'tblinkgrupo', CAST(id AS INT64), NULLIF(TRIM(CAST(grupo AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tblinkgrupo`
UNION ALL
SELECT 'grupo_link_2', 'tblinkgrupo2', CAST(id AS INT64), NULLIF(TRIM(CAST(grupo AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tblinkgrupo2`
UNION ALL
SELECT 'grupo_sgi', 'tbsgigrupo', CAST(id AS INT64), NULLIF(TRIM(CAST(grupo AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbsgigrupo`
UNION ALL
SELECT 'subgrupo_intranet', 'tbsubgrupo', CAST(id AS INT64), NULLIF(TRIM(CAST(subgrupo AS STRING)),''), NULL, NULL, NULLIF(CAST(grupo AS INT64),0), 'grupo_intranet', NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbsubgrupo`
UNION ALL
SELECT 'subgrupo_download', 'tbsubgrupodownload', CAST(id AS INT64), NULLIF(TRIM(CAST(subgrupo AS STRING)),''), NULL, NULL, NULLIF(CAST(grupo AS INT64),0), 'grupo_download', NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbsubgrupodownload`
UNION ALL
SELECT 'subgrupo_link', 'tbsubgrupolink', CAST(id AS INT64), NULLIF(TRIM(CAST(subgrupo AS STRING)),''), NULL, NULL, NULLIF(CAST(grupo AS INT64),0), 'grupo_link', NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbsubgrupolink`
UNION ALL
SELECT 'subgrupo_link_2', 'tbsubgrupolink2', CAST(id AS INT64), NULLIF(TRIM(CAST(subgrupo AS STRING)),''), NULL, NULL, NULLIF(CAST(grupo AS INT64),0), 'grupo_link_2', NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbsubgrupolink2`
UNION ALL
SELECT 'subgrupo_sgi', 'tbsgisubgrupo', CAST(id AS INT64), NULLIF(TRIM(CAST(subgrupo AS STRING)),''), NULL, NULL, NULLIF(CAST(grupo AS INT64),0), 'grupo_sgi', NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbsgisubgrupo`
UNION ALL
SELECT 'setor', 'tbsetor', CAST(id AS INT64), NULLIF(TRIM(CAST(setor AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbsetor`
UNION ALL
SELECT 'setor_checklist_diario', 'tbsetorckdiario', CAST(id AS INT64), NULLIF(TRIM(CAST(nome AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbsetorckdiario`
UNION ALL
SELECT 'categoria_servico', 'tb_categoria_servico', CAST(id AS INT64), NULLIF(TRIM(CAST(nome AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(created_at AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tb_categoria_servico`
UNION ALL
SELECT 'sub_servico', 'tb_sub_servicos_servico', CAST(id AS INT64), NULLIF(TRIM(CAST(nome AS STRING)),''), NULL, NULL, NULLIF(CAST(categoria AS INT64),0), 'categoria_servico', NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tb_sub_servicos_servico`
UNION ALL
SELECT 'servico_atendimento', 'tbservicoatendimento', CAST(id AS INT64), NULLIF(TRIM(CAST(nomeservico AS STRING)),''), NULL, NULL, NULLIF(CAST(setor AS INT64),0), 'setor', CAST(ordem AS INT64), NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbservicoatendimento`
UNION ALL
SELECT 'local_atuacao_rh', 'local_atuacao_rh', CAST(id AS INT64), NULLIF(TRIM(CAST(nome AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_local_atuacao_rh`
UNION ALL
SELECT 'quinzena', 'quinzena', CAST(id AS INT64), NULLIF(TRIM(CAST(nome AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_quinzena`
UNION ALL
SELECT 'rotina_tipo_prazo', 'rotinas_tipos_prazo', CAST(id AS INT64), NULLIF(TRIM(CAST(nome AS STRING)),''), NULLIF(TRIM(CAST(descricao AS STRING)),''), NULLIF(TRIM(CAST(codigo AS STRING)),''), NULL, NULL, NULL, CAST(ativo AS INT64)=1, NULL, NULL, NULL, NULL, CAST(criado_em AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_rotinas_tipos_prazo`
UNION ALL
SELECT 'canal_publicacao', 'tbcanalpublicacao', CAST(id AS INT64), NULLIF(TRIM(CAST(nome AS STRING)),''), NULL, NULLIF(TRIM(CAST(slug AS STRING)),''), NULL, NULL, CAST(ordem AS INT64), CAST(ativo AS INT64)=1, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbcanalpublicacao`
UNION ALL
SELECT 'tipo_cronograma', 'tiposcronograma', CAST(id AS INT64), NULLIF(TRIM(CAST(nomecronograma AS STRING)),''), NULLIF(TRIM(CAST(nomecompleto AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(datacadadastro AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tiposcronograma`
UNION ALL
SELECT 'empresa', 'tbempresa', CAST(id AS INT64), NULLIF(TRIM(CAST(empresa AS STRING)),''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbempresa`
UNION ALL
SELECT 'onboarding_servico', 'tbonboardingetapas', CAST(id AS INT64), NULLIF(TRIM(CAST(servico AS STRING)),''), NULL, NULL, NULLIF(CAST(area AS INT64),0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbonboardingetapas`
UNION ALL
SELECT 'onboarding_servico_2', 'tbonboardingetapas2', CAST(id AS INT64), NULLIF(TRIM(CAST(servico AS STRING)),''), NULL, NULL, NULLIF(CAST(id_area AS INT64),0), NULL, NULL, NULL, NULL, NULL, NULLIF(TRIM(CAST(quinzena AS STRING)),''), CAST(dmais AS INT64), NULL FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbonboardingetapas2`
UNION ALL
SELECT 'feriado', 'tbferiados', CAST(id AS INT64), NULLIF(TRIM(CAST(nome AS STRING)),''), NULL, NULL, NULL, NULL, NULL, CAST(ativo AS INT64)=1, NULL, CAST(data_feriado AS DATE), NULLIF(TRIM(CAST(abrangencia AS STRING)),''), NULL, CAST(criado_em AS TIMESTAMP) FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbferiados`
),
tratado AS (
  SELECT b.*,
    (b.id_pai IS NOT NULL AND b.dominio_pai IS NOT NULL AND p.id_origem IS NULL) AS flag_pai_nao_catalogado,
    (b.nome IS NULL) AS flag_sem_nome
  FROM base b
  LEFT JOIN (SELECT DISTINCT dominio, id_origem FROM base) p ON p.dominio = b.dominio_pai AND p.id_origem = b.id_pai
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
