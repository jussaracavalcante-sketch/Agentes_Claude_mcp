-- trs_fiscal__simples_receita_declarada  ·  query-aQ8u  ·  Trusted  ·  gatilho: cron segunda 06:00 America/Manaus  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Trusted / FISCAL (VBOT). Grao: um PERIODO (mes) com a RECEITA BRUTA DECLARADA ao Simples Nacional (RPA) e a receita com ISS retido,
-- transcritas da apuracao. Chave: periodo. 13 distintos em 13 linhas (2025-06 a 2026-06), medido em 2026-10-19.
-- Nivel: L3 CONFIDENTIAL (receita declarada da casa). E O UNICO DADO DECLARADO desta familia; o resto e simulacao.
-- ORIGEM: supabase_meta_simples_rpa_declarada (13), tabela de parametro mantida a mao (atualizado_por ORI-535, 29/07/2026); fonte_documento
--   diz de que pagina da apuracao 06/2026 cada valor foi transcrito. Os 13 periodos batem com receita_declarada de trs_fiscal__simples_vbot_mes
--   (13 de 13, e receita_iss_retido 13 de 13).
-- ISS RETIDO so em 2026-06 (R$ 14.654,50, "Tabela 1" da apuracao); zero nos outros 12 e zero declarado, nao ausencia.
-- LIMITACAO - NAO CONTORNE: nao ha declaracao a partir de 2026-07; transcricao manual, sem conferencia por esta casa.
SELECT
  r.periodo                                                      AS id_periodo,
  r.periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(r.periodo, '-01'))          AS mes_referencia,
  CAST(r.receita AS FLOAT64)                                     AS receita_declarada,
  CAST(r.receita_iss_retido AS FLOAT64)                          AS receita_iss_retido,
  (CAST(r.receita_iss_retido AS FLOAT64) > 0)                    AS flag_iss_retido,
  NULLIF(TRIM(r.fonte), '')                                      AS fonte_documento,
  NULLIF(TRIM(r.obs), '')                                        AS observacao,
  NULLIF(TRIM(r.atualizado_por), '')                             AS atualizado_por,
  CAST(r.atualizado_em AS TIMESTAMP)                             AS atualizado_em,
  DATETIME(CAST(r.atualizado_em AS TIMESTAMP), 'America/Sao_Paulo') AS atualizado_em_local,
  'L3_CONFIDENTIAL'                                              AS classificacao_dado,
  CURRENT_TIMESTAMP()                                            AS _extraido_at,
  'supabase-x0tz'                                                AS _fonte,
  'America/Sao_Paulo'                                            AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(r)))                                 AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_meta_simples_rpa_declarada` r
