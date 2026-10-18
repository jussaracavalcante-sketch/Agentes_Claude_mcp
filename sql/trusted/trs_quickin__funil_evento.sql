-- trs_quickin__funil_evento (query-A8RA)
-- Trusted / Recrutamento (Quickin). Grao: uma MOVIMENTACAO de aplicacao entre etapas do funil. Chave: id_evento.
-- Nivel: L3 CONFIDENTIAL (ligada a aplicacao por id; sem dado do candidato).
-- Medido em 18/10/2026: 149 linhas, 149 chaves; 149 aplicacoes e 149 etapas (nova e anterior) resolvem; 100% tem
-- etapa anterior; eventos de 15/06/2026 (21:35 em Sao Paulo, 16/06 00:35 UTC) a 28/09/2026.
-- A captura de movimentacao so comecou em junho/2026: nao ha historico anterior, embora existam aplicacoes desde 2024-11.
-- FUSO: ts e instante UTC real -> DATETIME(ts,'America/Sao_Paulo').
-- LIMITACAO -- NAO CONTORNE: 149 eventos cobrem fracao minima das 4.013 aplicacoes; ausencia de evento nao e
-- ausencia de movimentacao.
SELECT
  CAST(e.id AS STRING)                                       AS id_evento,
  e.aplicacao_id                                             AS id_aplicacao,
  e.etapa_anterior_id                                        AS id_etapa_anterior,
  ea.name                                                    AS etapa_anterior,
  ea.type                                                    AS tipo_etapa_anterior,
  e.etapa_nova_id                                            AS id_etapa_nova,
  en.name                                                    AS etapa_nova,
  en.type                                                    AS tipo_etapa_nova,
  DATETIME(e.ts, 'America/Sao_Paulo')                        AS ocorrido_em,
  DATE(e.ts, 'America/Sao_Paulo')                            AS data_evento,
  DATETIME(e.processed_at, 'America/Sao_Paulo')              AS processado_em,
  CURRENT_TIMESTAMP()                                        AS _extraido_at,
  'supabase-x0tz'                                            AS _fonte,
  'America/Sao_Paulo'                                        AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(e)))                             AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_silver_evento_funil` e
LEFT JOIN `vanguardamartech_raw`.`supabase_silver_etapa_funil` ea ON ea.quickin_etapa_id = e.etapa_anterior_id
LEFT JOIN `vanguardamartech_raw`.`supabase_silver_etapa_funil` en ON en.quickin_etapa_id = e.etapa_nova_id
