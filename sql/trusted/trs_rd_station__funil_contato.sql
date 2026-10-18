-- slug no deploy: query-BHFg (esta linha existe so no arquivo)
-- Trusted RD Station - contato no funil (stream contact_funnels). L4 PERSONAL_DATA (e-mail do contato).
-- Grao: um contato por conta RD (_fonte). Chave id_contato = _fonte|uuid_contato.
-- So a conta rd-station-5KKM (ARENA TINTAS) tem este stream habilitado com linha; as demais contas nao o trazem (medido por get_resource e COUNT em 18/10/2026).
-- Medido: 4.344 linhas = 4.344 chaves; 2.500 com registro em contacts_details; 362 oportunidades; interesse zero e sentinela -> NULL (4.343 de 4.344); contact_owner_email 100% vazio e fit 100% zero: campos mortos, nao emitidos.
-- Nao atravessa para a Refined: e-mail. A Refined so conta por estagio.
WITH f0 AS (SELECT 'rd-station-5KKM' AS _fonte,'ARENA TINTAS' AS cliente,* FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintascontact_funnels`),
fb AS (SELECT f0.*,TO_HEX(MD5(TO_JSON_STRING(f0))) AS _payload_hash FROM f0 QUALIFY ROW_NUMBER() OVER (PARTITION BY _fonte,contact_uuid ORDER BY contact_uuid)=1),
cd AS (SELECT DISTINCT uuid FROM `vanguardamartech_rd_arena_tintas`.`rd_station_arena_tintascontacts_details`),
ft AS (SELECT CONCAT(fb._fonte,'|',fb.contact_uuid) AS id_contato, fb._fonte, fb.cliente, fb.contact_uuid AS uuid_contato, LOWER(NULLIF(TRIM(fb.email),'')) AS email, NULLIF(TRIM(fb.lifecycle_stage),'') AS estagio_funil, fb.opportunity AS is_oportunidade, NULLIF(SAFE_CAST(fb.interest AS INT64),0) AS interesse, NULLIF(TRIM(fb.origin),'') AS origem, (cd.uuid IS NOT NULL) AS tem_contato_detalhado, CURRENT_TIMESTAMP() AS _extraido_at, fb._payload_hash FROM fb LEFT JOIN cd ON cd.uuid=fb.contact_uuid)
SELECT * FROM ft
