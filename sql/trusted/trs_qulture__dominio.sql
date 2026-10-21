-- trs_qulture__dominio (query-Wc5X)
-- Trusted / RH (Qulture). Grao: um item de DOMINIO do Qulture (competencia, ciclo, tag, time, pesquisa,
-- topico de pesquisa, pergunta de pulse, modelo de feedback). Chave: (dominio, id_origem).
-- Nivel: L2 INTERNAL. Catalogos da empresa, sem dado pessoal.
--
-- ORIGEM. bronze_qulture__{competencies, cycles, idp_cycles, feedback_templates, tags, teams, surveys,
-- survey_topics, pulse_questions, pulse_surveys}. Todos sao LOG DE VERSOES (teams 47 linhas para 36 chaves);
-- le a ultima versao por natural_key. silver_tag (21) e silver_equipe (36) sao as mesmas chaves e nao foram usados.
--
-- DESCRICAO de competencia chega em HTML (<p>...</p>) e sai sem tags. Descricao de pulse tambem.
-- pulse_surveys: 1 das 11 linhas do bronze chega com payload NULL (so o hash); fica fora, declarado.
-- Zero em pulse_questions/description e string vazia na origem e sai NULL.
--
-- LIMITACAO -- NAO CONTORNE: nao existem as respostas das pesquisas nem das perguntas de pulse nesta base:
-- so a estrutura (quais pesquisas, topicos e perguntas existem) e a participacao (trs_qulture__interacao,
-- origem PESQUISA). Nao ha como medir clima a partir daqui.
WITH
comp AS (SELECT 'COMPETENCIA' AS dominio, natural_key AS id_origem, JSON_VALUE(payload,'$.name') AS nome,
                REGEXP_REPLACE(JSON_VALUE(payload,'$.description'), r'<[^>]+>', '') AS descricao,
                CAST(NULL AS STRING) AS estado, CAST(NULL AS STRING) AS id_pai, fetched_at
         FROM `vanguardamartech_raw`.`supabase_bronze_qulture__competencies`
         WHERE TRUE QUALIFY ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) = 1),
ciclo AS (SELECT 'CICLO_AVALIACAO', natural_key, JSON_VALUE(payload,'$.name'), CAST(NULL AS STRING),
                 IF(JSON_VALUE(payload,'$.current')='true','ATUAL','ANTERIOR'), CAST(NULL AS STRING), fetched_at
          FROM `vanguardamartech_raw`.`supabase_bronze_qulture__cycles`
          WHERE TRUE QUALIFY ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) = 1),
idpc AS (SELECT 'CICLO_PDI', natural_key, JSON_VALUE(payload,'$.name'), CAST(NULL AS STRING),
                JSON_VALUE(payload,'$.state'), CAST(NULL AS STRING), fetched_at
         FROM `vanguardamartech_raw`.`supabase_bronze_qulture__idp_cycles`
         WHERE TRUE QUALIFY ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) = 1),
tmpl AS (SELECT 'MODELO_FEEDBACK', natural_key, JSON_VALUE(payload,'$.name'), CAST(NULL AS STRING),
                CAST(NULL AS STRING), CAST(NULL AS STRING), fetched_at
         FROM `vanguardamartech_raw`.`supabase_bronze_qulture__feedback_templates`
         WHERE TRUE QUALIFY ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) = 1),
tag AS (SELECT 'TAG', natural_key, JSON_VALUE(payload,'$.name'), CAST(NULL AS STRING),
               CAST(NULL AS STRING), CAST(NULL AS STRING), fetched_at
        FROM `vanguardamartech_raw`.`supabase_bronze_qulture__tags`
        WHERE TRUE QUALIFY ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) = 1),
team AS (SELECT 'TIME', natural_key, JSON_VALUE(payload,'$.name'), CAST(NULL AS STRING),
                CAST(NULL AS STRING), CAST(NULL AS STRING), fetched_at
         FROM `vanguardamartech_raw`.`supabase_bronze_qulture__teams`
         WHERE TRUE QUALIFY ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) = 1),
surv AS (SELECT 'PESQUISA', natural_key, JSON_VALUE(payload,'$.name'), CAST(NULL AS STRING),
                CAST(NULL AS STRING), CAST(NULL AS STRING), fetched_at
         FROM `vanguardamartech_raw`.`supabase_bronze_qulture__surveys`
         WHERE TRUE QUALIFY ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) = 1),
topc AS (SELECT 'TOPICO_PESQUISA', natural_key, JSON_VALUE(payload,'$.name'),
                CONCAT('peso ', IFNULL(JSON_VALUE(payload,'$.weight'),'?'), '; perguntas ', CAST(ARRAY_LENGTH(JSON_QUERY_ARRAY(payload,'$.questions')) AS STRING)),
                CAST(NULL AS STRING), JSON_VALUE(payload,'$.survey.id'), fetched_at
         FROM `vanguardamartech_raw`.`supabase_bronze_qulture__survey_topics`
         WHERE TRUE QUALIFY ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) = 1),
pq AS (SELECT 'PERGUNTA_PULSE', natural_key, JSON_VALUE(payload,'$.name'), NULLIF(JSON_VALUE(payload,'$.description'),''),
              CAST(NULL AS STRING), CAST(NULL AS STRING), fetched_at
       FROM `vanguardamartech_raw`.`supabase_bronze_qulture__pulse_questions`
       WHERE TRUE QUALIFY ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) = 1),
ps AS (SELECT 'PULSE_SURVEY', JSON_VALUE(payload,'$.id'), JSON_VALUE(payload,'$.name'), JSON_VALUE(payload,'$.description'),
              IF(JSON_VALUE(payload,'$.archived')='true','ARQUIVADA',JSON_VALUE(payload,'$.state')), CAST(NULL AS STRING), fetched_at
       FROM `vanguardamartech_raw`.`supabase_bronze_qulture__pulse_surveys`
       WHERE payload IS NOT NULL QUALIFY ROW_NUMBER() OVER (PARTITION BY JSON_VALUE(payload,'$.id') ORDER BY fetched_at DESC) = 1),
uniao AS (
  SELECT * FROM comp UNION ALL SELECT * FROM ciclo UNION ALL SELECT * FROM idpc UNION ALL SELECT * FROM tmpl
  UNION ALL SELECT * FROM tag UNION ALL SELECT * FROM team UNION ALL SELECT * FROM surv UNION ALL SELECT * FROM topc
  UNION ALL SELECT * FROM pq UNION ALL SELECT * FROM ps
)
SELECT
  CONCAT(dominio, ':', id_origem)          AS id_chave,
  dominio,
  id_origem,
  NULLIF(TRIM(nome), '')                   AS nome,
  NULLIF(TRIM(descricao), '')              AS descricao,
  estado,
  id_pai,
  DATE(fetched_at)                         AS versao_lida_em,
  CURRENT_TIMESTAMP()                      AS _extraido_at,
  'supabase-x0tz'                          AS _fonte,
  'America/Sao_Paulo'                      AS _fuso,
  TO_HEX(MD5(CONCAT(dominio, id_origem, IFNULL(nome, ''), IFNULL(estado, '')))) AS _payload_hash
FROM uniao
