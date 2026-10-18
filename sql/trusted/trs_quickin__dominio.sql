-- trs_quickin__dominio
-- Trusted / Recrutamento (Quickin). Grao: um item de DOMINIO (etapa do funil, canal de origem, avaliador,
-- departamento, tipo de contrato, empresa). Chave: id_chave = dominio:id_origem.
-- Nivel: L4 PERSONAL_DATA so pelo dominio AVALIADOR (nome e e-mail de quem avalia); os demais sao L2.
--
-- ORIGEM. silver_etapa_funil (10), silver_canal_origem (15), silver_avaliador (27) e os cadastros que NAO tem
-- silver: bronze_quickin__departaments (15 chaves), __contracts (4), __companies (1), ultima versao por natural_key.
-- bronze_quickin__sources (85 linhas, 15 chaves), __stages (10) e __users (27) sao as mesmas chaves de
-- canal_origem, etapa_funil e avaliador (versoes) e nao foram usados.
-- Medido em 18/10/2026: 72 linhas, 72 chaves.
--
-- FUSO. created_at e quickin_updated_at sao UTC reais: DATETIME(ts,'America/Sao_Paulo').
--
-- LIMITACAO -- NAO CONTORNE: nao existe cadastro de motivo de desqualificacao nem de cancelamento de vaga aqui;
-- trs_quickin__aplicacao traz so o id do motivo.
WITH
ult_dep AS (SELECT * FROM `vanguardamartech_raw`.`supabase_bronze_quickin__departaments` WHERE TRUE
            QUALIFY ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) = 1),
ult_ctr AS (SELECT * FROM `vanguardamartech_raw`.`supabase_bronze_quickin__contracts` WHERE TRUE
            QUALIFY ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) = 1),
ult_emp AS (SELECT * FROM `vanguardamartech_raw`.`supabase_bronze_quickin__companies` WHERE TRUE
            QUALIFY ROW_NUMBER() OVER (PARTITION BY natural_key ORDER BY fetched_at DESC) = 1),
uniao AS (
  SELECT 'ETAPA_FUNIL' AS dominio, quickin_etapa_id AS id_origem, name AS nome, type AS tipo,
         CAST(position AS STRING) AS ordem, IF(active, 'ATIVA', 'INATIVA') AS estado, CAST(NULL AS STRING) AS email,
         CAST(NULL AS TIMESTAMP) AS criado_em_utc
  FROM `vanguardamartech_raw`.`supabase_silver_etapa_funil`
  UNION ALL
  SELECT 'CANAL_ORIGEM', quickin_canal_id, name, CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING),
         CAST(NULL AS STRING), created_at
  FROM `vanguardamartech_raw`.`supabase_silver_canal_origem`
  UNION ALL
  SELECT 'AVALIADOR', quickin_user_id, name, CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING),
         LOWER(TRIM(email)), CAST(NULL AS TIMESTAMP)
  FROM `vanguardamartech_raw`.`supabase_silver_avaliador`
  UNION ALL
  SELECT 'DEPARTAMENTO', natural_key, JSON_VALUE(payload, '$.name'), CAST(NULL AS STRING), CAST(NULL AS STRING),
         CAST(NULL AS STRING), CAST(NULL AS STRING), SAFE.TIMESTAMP(JSON_VALUE(payload, '$.created_at'))
  FROM ult_dep
  UNION ALL
  SELECT 'TIPO_CONTRATO', natural_key, JSON_VALUE(payload, '$.name'), CAST(NULL AS STRING), CAST(NULL AS STRING),
         CAST(NULL AS STRING), CAST(NULL AS STRING), SAFE.TIMESTAMP(JSON_VALUE(payload, '$.created_at'))
  FROM ult_ctr
  UNION ALL
  SELECT 'EMPRESA', natural_key, JSON_VALUE(payload, '$.name'), CAST(NULL AS STRING), CAST(NULL AS STRING),
         CAST(NULL AS STRING), CAST(NULL AS STRING), SAFE.TIMESTAMP(JSON_VALUE(payload, '$.created_at'))
  FROM ult_emp
)
SELECT
  CONCAT(dominio, ':', id_origem)                        AS id_chave,
  dominio,
  id_origem,
  NULLIF(TRIM(nome), '')                                 AS nome,
  NULLIF(TRIM(tipo), '')                                 AS tipo,
  ordem,
  estado,
  email,
  DATETIME(criado_em_utc, 'America/Sao_Paulo')           AS criado_em,
  CURRENT_TIMESTAMP()                                    AS _extraido_at,
  'supabase-x0tz'                                        AS _fonte,
  'America/Sao_Paulo'                                    AS _fuso,
  TO_HEX(MD5(CONCAT(dominio, id_origem, IFNULL(nome, ''), IFNULL(tipo, ''), IFNULL(estado, '')))) AS _payload_hash
FROM uniao
