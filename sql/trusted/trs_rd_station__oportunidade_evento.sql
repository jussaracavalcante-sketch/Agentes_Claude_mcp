-- slug no deploy: query-KePD (esta linha existe so no arquivo)
-- Trusted RD Station - evento de oportunidade do contato (stream contact_opportunity_events). L4 PERSONAL_DATA (e-mail do contato).
-- Grao: um evento por conta RD (_fonte). Chave id_oportunidade_evento = _fonte|id do evento.
-- So rd-station-5KKM tem o stream com linha. Medido em 18/10/2026: 363 eventos = 363 chaves, 363 contatos, 2023 a 2026; 362 deles em contact_funnels com oportunidade verdadeira.
-- Fuso: event_timestamp chega em UTC e sai em America/Sao_Paulo.
-- Nao atravessa para a Refined: e-mail e uuid do contato.
WITH o0 AS (SELECT 'rd-station-5KKM' AS _fonte,'ARENA TINTAS' AS cliente,* FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintascontact_opportunity_events`),
ob AS (SELECT o0.*,TO_HEX(MD5(TO_JSON_STRING(o0))) AS _payload_hash FROM o0 QUALIFY ROW_NUMBER() OVER (PARTITION BY _fonte,id ORDER BY event_timestamp DESC)=1),
ot AS (SELECT CONCAT(_fonte,'|',CAST(id AS STRING)) AS id_oportunidade_evento, id AS id_evento_origem, _fonte, cliente, CONCAT(_fonte,'|',contact_uuid) AS id_contato, contact_uuid AS uuid_contato, LOWER(NULLIF(TRIM(email),'')) AS email, NULLIF(TRIM(event_type),'') AS tipo_evento, NULLIF(TRIM(event_family),'') AS familia_evento, NULLIF(TRIM(event_identifier),'') AS identificador_evento, NULLIF(TRIM(funnel_name),'') AS nome_funil, DATETIME(SAFE_CAST(event_timestamp AS TIMESTAMP),'America/Sao_Paulo') AS ocorrido_em, DATE(DATETIME(SAFE_CAST(event_timestamp AS TIMESTAMP),'America/Sao_Paulo')) AS ocorrido_data, DATE_TRUNC(DATE(DATETIME(SAFE_CAST(event_timestamp AS TIMESTAMP),'America/Sao_Paulo')),MONTH) AS mes_referencia, CURRENT_TIMESTAMP() AS _extraido_at, _payload_hash FROM ob)
SELECT * FROM ot
