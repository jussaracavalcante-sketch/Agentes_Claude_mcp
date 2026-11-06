-- trs_vjob__usuario (query-GByA) · Trusted / VJOB · L4 por linhagem (nome de pessoa; escopo minimo desde 26/08/2026)
-- Recuperado de get_code em 18/10/2026: o arquivo nunca tinha sido gravado no repositorio. O codigo abaixo e identico ao deploy;
-- so este cabecalho de comentarios foi acrescentado. Gatilho: evento em supabase-x0tz. Alerta de falha DESLIGADO no deploy.
-- Medido em 18/10/2026: 278 linhas, ultima carga 2026-10-17 12:39 UTC (eram 270 em 26/08).
-- Escopo deliberadamente minimo: nenhum campo de RH do payload (admissao, demissao, regime, nivel, classe, lider, e-mail, setor,
-- funcao) e materializado. Le o DERIVADO Supabase (supabase_bronze_vjob__tbusuariointranet), nao o MySQL do VJOB.
SELECT
  SAFE_CAST(JSON_VALUE(payload, '$.id') AS INT64)          AS id_usuario,
  NULLIF(TRIM(JSON_VALUE(payload, '$.nome')), '')          AS nome,
  SAFE_CAST(JSON_VALUE(payload, '$.status') AS INT64) = 1  AS ativo,
  fetched_at                                               AS _extraido_at,
  'supabase-x0tz'                                          AS _fonte,
  payload_hash                                             AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_bronze_vjob__tbusuariointranet`
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY JSON_VALUE(payload, '$.id') ORDER BY fetched_at DESC
) = 1
