-- trs_qulture__interacao (query-bCo5)
-- Trusted / RH (Qulture). Grao: um EVENTO DE GENTE por pessoa-destino: elogio, feedback, 1:1, PDI,
-- pesquisa respondida, check-in de humor e tarefa de reuniao. Chave: id_chave = origem:id_evento:destino.
-- Nivel: L4 PERSONAL_DATA (quem elogiou/avaliou quem, nome, humor individual). NAO atravessa nominal
-- para a Refined. O TEXTO do elogio, o titulo livre e a descricao da tarefa NAO sao emitidos (minimizacao):
-- a Trusted guarda o fato (quem, o que, quando) e nao o conteudo que a pessoa escreveu.
--
-- ORIGEM. bronze_qulture__* da supabase-x0tz (GraphQL do Qulture). O bronze e LOG DE VERSOES: elogio
-- 110 linhas para 80 chaves, feedback 80 para 77, 1:1 769 para 326, PDI 1.306 para 1.280. A Trusted le a
-- ULTIMA versao por natural_key (fetched_at) e emite qtd_versoes. Os silver_qulture_* (77, 80, 558, 1.280)
-- sao as mesmas chaves ja tipadas e NAO foram usados: o silver_qulture_one_on_one tem 558 linhas para 326
-- eventos (uma por participante), e esta tabela mantem uma por evento.
--
-- SEM DATA DE EVENTO. Os payloads de elogio, feedback, 1:1, PDI, pesquisa e humor NAO trazem timestamp
-- do evento; so a tarefa de reuniao traz dueDate. Por isso nao existe serie temporal desta tabela e
-- data_referencia sai NULL fora da origem TAREFA_REUNIAO. versao_lida_em e a data da LEITURA, nao do evento.
--
-- HUMOR. rate NAO e numero: e o rotulo do emoji (GRINNING_FACE_WITH_STAR_EYES 59, BLUSH 46,
-- THINKING_FACE 11, PERSEVERE 8, NEUTRAL_FACE 8, DISAPPOINTED 5). Vem preenchido em 137 das 2.529 linhas
-- (5,4%); as outras 2.392 chegam com string vazia e saem NULL, nunca zero. Sai como rotulo_humor, sem nota.
--
-- LIMITACAO -- NAO CONTORNE: estado e a foto da ultima leitura (14/09/2026 a 18/10/2026 conforme a origem).
WITH
elogio AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT b.*, ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) rn,
           COUNT(*) OVER (PARTITION BY natural_key) qv
    FROM `vanguardamartech_raw`.`supabase_bronze_qulture__praises` b) WHERE rn = 1
),
feedback AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT b.*, ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) rn,
           COUNT(*) OVER (PARTITION BY natural_key) qv
    FROM `vanguardamartech_raw`.`supabase_bronze_qulture__sent_feedbacks` b) WHERE rn = 1
),
um_a_um AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT b.*, ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) rn,
           COUNT(*) OVER (PARTITION BY natural_key) qv
    FROM `vanguardamartech_raw`.`supabase_bronze_qulture__one_on_ones` b) WHERE rn = 1
),
pdi AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT b.*, ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) rn,
           COUNT(*) OVER (PARTITION BY natural_key) qv
    FROM `vanguardamartech_raw`.`supabase_bronze_qulture__idps` b) WHERE rn = 1
),
pesquisa AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT b.*, ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) rn,
           COUNT(*) OVER (PARTITION BY natural_key) qv
    FROM `vanguardamartech_raw`.`supabase_bronze_qulture__survey_participations` b) WHERE rn = 1
),
humor AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT b.*, ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) rn,
           COUNT(*) OVER (PARTITION BY natural_key) qv
    FROM `vanguardamartech_raw`.`supabase_bronze_qulture__feelings` b) WHERE rn = 1
),
tarefa AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT b.*, ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) rn,
           COUNT(*) OVER (PARTITION BY natural_key) qv
    FROM `vanguardamartech_raw`.`supabase_bronze_qulture__meeting_tasks` b) WHERE rn = 1
),
uniao AS (
  SELECT 'ELOGIO' AS origem, natural_key AS id_evento,
         JSON_VALUE(payload, '$.sender.id') AS id_contrato_origem,
         JSON_VALUE(rc, '$.id') AS id_contrato_destino,
         JSON_VALUE(payload, '$.sender.name') AS nome_origem,
         JSON_VALUE(rc, '$.name') AS nome_destino,
         CAST(NULL AS STRING) AS estado, CAST(NULL AS STRING) AS id_ciclo, CAST(NULL AS STRING) AS nome_ciclo,
         (SELECT STRING_AGG(JSON_VALUE(bh, '$.name'), ' | ' ORDER BY JSON_VALUE(bh, '$.name'))
            FROM UNNEST(JSON_QUERY_ARRAY(payload, '$.behaviors')) bh) AS comportamentos,
         CAST(NULL AS STRING) AS assuntos, CAST(NULL AS STRING) AS rotulo_humor,
         CAST(NULL AS DATE) AS data_referencia, CAST(NULL AS BOOL) AS is_concluida,
         qv AS qtd_versoes, fetched_at
  FROM elogio, UNNEST(IF(ARRAY_LENGTH(JSON_QUERY_ARRAY(payload, '$.recipients')) > 0, JSON_QUERY_ARRAY(payload, '$.recipients'), ['{}'])) rc
  UNION ALL
  SELECT 'FEEDBACK', natural_key, JSON_VALUE(payload, '$.from.id'), JSON_VALUE(payload, '$.to.id'),
         JSON_VALUE(payload, '$.from.name'), JSON_VALUE(payload, '$.to.name'),
         NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, qv, fetched_at
  FROM feedback
  UNION ALL
  SELECT 'UM_A_UM', natural_key, JSON_VALUE(payload, '$._contract_id'), CAST(NULL AS STRING),
         CAST(NULL AS STRING), CAST(NULL AS STRING),
         JSON_VALUE(payload, '$.state'), NULL, NULL, NULL,
         (SELECT STRING_AGG(JSON_VALUE(s, '$.name'), ' | ' ORDER BY JSON_VALUE(s, '$.name'))
            FROM UNNEST(JSON_QUERY_ARRAY(payload, '$.subjects.nodes')) s),
         NULL, NULL, NULL, qv, fetched_at
  FROM um_a_um
  UNION ALL
  SELECT 'PDI', natural_key, JSON_VALUE(payload, '$.contract.id'), CAST(NULL AS STRING),
         JSON_VALUE(payload, '$.contract.name'), CAST(NULL AS STRING),
         NULL, JSON_VALUE(payload, '$.idpCycle.id'), JSON_VALUE(payload, '$.idpCycle.name'),
         NULL, NULL, NULL, NULL, NULL, qv, fetched_at
  FROM pdi
  UNION ALL
  SELECT 'PESQUISA', natural_key, JSON_VALUE(payload, '$.contract.id'), CAST(NULL AS STRING),
         CAST(NULL AS STRING), CAST(NULL AS STRING),
         NULL, JSON_VALUE(payload, '$.survey.id'), CAST(NULL AS STRING),
         NULL, NULL, NULL, NULL, NULL, qv, fetched_at
  FROM pesquisa
  UNION ALL
  SELECT 'HUMOR', natural_key, JSON_VALUE(payload, '$.contract.id'), CAST(NULL AS STRING),
         CAST(NULL AS STRING), CAST(NULL AS STRING),
         NULL, NULL, NULL, NULL, NULL,
         NULLIF(JSON_VALUE(payload, '$.rate'), ''), NULL, NULL, qv, fetched_at
  FROM humor
  UNION ALL
  SELECT 'TAREFA_REUNIAO', natural_key, CAST(NULL AS STRING), CAST(NULL AS STRING),
         CAST(NULL AS STRING), CAST(NULL AS STRING),
         IF(JSON_VALUE(payload, '$.done') = 'true', 'FEITA', 'ABERTA'), NULL, NULL, NULL, NULL, NULL,
         SAFE_CAST(JSON_VALUE(payload, '$.dueDate') AS DATE),
         JSON_VALUE(payload, '$.done') = 'true', qv, fetched_at
  FROM tarefa
)
SELECT
  CONCAT(origem, ':', id_evento, ':', IFNULL(id_contrato_destino, '')) AS id_chave,
  origem,
  id_evento,
  NULLIF(id_contrato_origem, '')  AS id_contrato_origem,
  NULLIF(id_contrato_destino, '') AS id_contrato_destino,
  NULLIF(nome_origem, '')         AS nome_origem,
  NULLIF(nome_destino, '')        AS nome_destino,
  estado,
  id_ciclo,
  nome_ciclo,
  comportamentos,
  assuntos,
  rotulo_humor,
  data_referencia,
  is_concluida,
  (origem = 'ELOGIO' AND id_contrato_destino IS NULL)  AS flag_elogio_sem_destinatario,
  qtd_versoes,
  DATE(fetched_at)                AS versao_lida_em,
  CURRENT_TIMESTAMP()             AS _extraido_at,
  'supabase-x0tz'                 AS _fonte,
  'America/Sao_Paulo'             AS _fuso,
  TO_HEX(MD5(CONCAT(origem, id_evento, IFNULL(id_contrato_destino, ''), IFNULL(estado, ''), IFNULL(rotulo_humor, ''), IFNULL(CAST(data_referencia AS STRING), '')))) AS _payload_hash
FROM uniao
