-- trs_vjob__evento_sistema (query-4fJW) · Trusted / VJOB · L4 PERSONAL_DATA. Grao: um SMS registrado ou uma acao registrada. Chave: (origem, id_origem).
-- Origem: mysql-yIOn, sms_logs_dashboard, sms_logs_onboarding, tbhistorico. Gatilho: evento em query-MZdN.
-- L4 por causa do telefone. O CORPO DA MENSAGEM E O SQL EXECUTADO NAO SAEM: so tipo, tamanho e o que se extrai por padrao. SMS e registrado, nao entregue.
WITH base AS (
SELECT 'SMS_DASHBOARD' AS origem, CAST(id AS INT64) AS id_origem, CAST(`data` AS TIMESTAMP) AS ocorrido_em, CAST(NULL AS INT64) AS id_usuario, REGEXP_REPLACE(CAST(numero AS STRING), r'\D', '') AS telefone_digitos,
  IF(LOWER(mensagem) LIKE 'relatorio diario de atrasos%', 'RELATORIO_DIARIO_ATRASOS', 'OUTRO') AS texto_tipo, CAST(NULL AS STRING) AS etapa_rotulo, CAST(NULL AS INT64) AS id_alvo, LENGTH(mensagem) AS texto_chars, CAST(NULL AS INT64) AS id_quem_marcou
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_sms_logs_dashboard`
UNION ALL SELECT 'SMS_ONBOARDING', CAST(id AS INT64), CAST(`data` AS TIMESTAMP), NULL, REGEXP_REPLACE(CAST(numero AS STRING), r'\D', ''),
  IF(REGEXP_CONTAINS(mensagem, r'já foi finalizada'), 'ETAPA_FINALIZADA', 'OUTRO'), NULLIF(TRIM(REGEXP_EXTRACT(mensagem, r'A etapa (.+?) já foi finalizada')),''), NULL, LENGTH(mensagem), CAST(quemmarcou AS INT64)
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_sms_logs_onboarding`
UNION ALL SELECT 'HISTORICO', CAST(id AS INT64), CAST(`data` AS TIMESTAMP), CAST(id_usuario AS INT64), NULL,
  IF(REGEXP_CONTAINS(acao, r'^cadastro de arquivo do cliente'), 'CADASTRO_ARQUIVO_CLIENTE', 'OUTRO'), NULL, SAFE_CAST(REGEXP_EXTRACT(acao, r':\s*(\d+)\s*$') AS INT64), LENGTH(query_sql), NULL
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbhistorico`
),
tratado AS (
  SELECT b.*, (b.telefone_digitos IS NOT NULL AND LENGTH(b.telefone_digitos) NOT IN (12, 13)) AS flag_telefone_fora_de_forma
  FROM base b
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
