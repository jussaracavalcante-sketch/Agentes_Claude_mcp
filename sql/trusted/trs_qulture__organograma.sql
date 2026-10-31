-- trs_qulture__organograma (query-pvTG)
-- Trusted / RH. Grao: um item do ORGANOGRAMA (setor -> departamento -> diretoria -> area) ou um mapa
-- CARGO -> SETOR. Chave: id_chave = origem:chave. Nivel: L2 INTERNAL (estrutura da empresa, sem pessoa).
--
-- ORIGEM. supabase_silver_dim_organograma (50) e supabase_silver_map_cargo_setor (37), da supabase-x0tz,
-- ja tipadas (cadastro mantido a mao pelo RH, atualizado em 16/06/2026). Medido em 18/10/2026:
-- organograma 50 setores, 18 departamentos, 5 diretorias, 4 areas; mapa 37 cargos em 19 setores.
-- Os 37 setores do mapa resolvem 37 de 37 contra o organograma (comparacao em maiusculas).
-- O mapa cobre o cargo de 135 dos 202 colaboradores com cargo na planilha de RH (67%).
--
-- LIMITACAO -- NAO CONTORNE: e cadastro parado em 16/06/2026; cargo novo depois dessa data nao esta no mapa.
-- O vinculo cargo -> setor e o que o RH cadastrou, nao o setor onde a pessoa trabalha hoje.
WITH uniao AS (
  SELECT 'ORGANOGRAMA' AS origem, NULLIF(TRIM(setor), '') AS chave, NULLIF(TRIM(setor), '') AS setor,
         NULLIF(TRIM(departamento), '') AS departamento, NULLIF(TRIM(diretoria), '') AS diretoria,
         NULLIF(TRIM(area), '') AS area, CAST(NULL AS STRING) AS cargo, atualizado_em
  FROM `vanguardamartech_raw`.`supabase_silver_dim_organograma`
  UNION ALL
  SELECT 'CARGO_SETOR', NULLIF(TRIM(cargo), ''), NULLIF(TRIM(setor), ''), CAST(NULL AS STRING), CAST(NULL AS STRING),
         CAST(NULL AS STRING), NULLIF(TRIM(cargo), ''), atualizado_em
  FROM `vanguardamartech_raw`.`supabase_silver_map_cargo_setor`
)
SELECT
  CONCAT(u.origem, ':', u.chave) AS id_chave,
  u.origem, u.chave, u.setor, u.departamento, u.diretoria, u.area, u.cargo,
  (u.origem = 'CARGO_SETOR' AND NOT EXISTS (
     SELECT 1 FROM `vanguardamartech_raw`.`supabase_silver_dim_organograma` o WHERE UPPER(TRIM(o.setor)) = UPPER(TRIM(u.setor)))) AS flag_setor_fora_do_organograma,
  DATE(u.atualizado_em, 'America/Sao_Paulo') AS atualizado_em,
  CURRENT_TIMESTAMP() AS _extraido_at,
  'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(u))) AS _payload_hash
FROM uniao u
