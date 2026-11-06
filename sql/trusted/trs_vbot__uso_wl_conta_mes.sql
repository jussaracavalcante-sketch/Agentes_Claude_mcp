-- trs_vbot__uso_wl_conta_mes  ·  query-uSUb  ·  Trusted  ·  gatilho: cron segunda 06:00 America/Manaus  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Trusted / VBOT (white-label). Grao: uma CONTA do white-label (conta_key) em um periodo (mes): USO que gera o custo
-- (apps de transcricao, Asaas e IA; instancia-dias; usuarios e canais por faixa de preco; vagas na faixa 1; dias de contrato).
-- Chave (periodo, conta_key): 572 distintos em 572 linhas, medido em 2026-10-19. Nivel: L3 CONFIDENTIAL (uso e custo por conta de cliente).
-- ORIGEM: supabase_gold_mvw_custo_wl_uso_conta_mes (572) JOIN supabase_gold_vw_consumo_vbot_faixas (572) por (periodo, conta_key):
--   as duas tem as MESMAS 572 chaves, as 7 colunas de faixa sao IDENTICAS nas 572 e inicio/fim_faturamento tambem (zero divergencias),
--   por isso viram UMA tabela. 8 periodos (2026-01 a 2026-08), 115 contas. As 572 existem em trs_vbot__conta_mes (595) e em
--   trs_custo_wl__conta_mensal (595); custo_helena aqui = custo_helena de trs_vbot__conta_mes em 572 de 572 (soma R$ 298.702,92).
-- ZERO E ZERO REAL, nao sentinela: dias_conta_ativa = 0 e instancia_dias = 0 em 294 das 572 (conta sem instancia Z-API no mes);
--   app_* = 0 em 425 (so 147 linhas tem algum app). Passam como vieram; flag_sem_instancia e flag_sem_app marcam.
-- LIGACAO COM CLIENTE E POR NOME (origem_match: RAZAO, FANTASIA, CURADORIA, INTERNA, SEM MATCH), nunca por documento.
-- NAO RECALCULA: custo_helena, vagas e faixas vem da origem. A unidade de app_* NAO e a unidade da tabela de preco
--   (app_* x preco da unidade = R$ 16.749,20 em 2026-01 contra custo_apps = R$ 651,30 em trs_vbot__consumo_wl_cliente_mes): nao multiplicar.
-- LIMITACAO - NAO CONTORNE: o uso so existe ate 2026-08 (ultima fatura apurada); dias_de_contrato e NULL em 3 linhas; fim_faturamento so em 27.
SELECT
  CONCAT(u.periodo, '|', u.conta_key)                            AS id_conta_mes,
  u.periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(u.periodo, '-01'))          AS mes_referencia,
  u.conta_key,
  NULLIF(TRIM(f.conta), '')                                      AS conta,
  NULLIF(TRIM(f.cliente), '')                                    AS cliente,
  NULLIF(TRIM(f.origem_match), '')                               AS origem_match,
  (f.origem_match = 'INTERNA')                                   AS is_conta_interna,
  f.ativa                                                        AS is_ativa,
  SAFE_CAST(u.inicio_faturamento AS DATE)                        AS inicio_faturamento,
  SAFE_CAST(u.fim_faturamento AS DATE)                           AS fim_faturamento,
  f.dias_de_contrato,
  SAFE_CAST(u.dias_conta_ativa AS INT64)                         AS dias_conta_ativa,
  SAFE_CAST(u.instancia_dias AS FLOAT64)                         AS instancia_dias,
  SAFE_CAST(u.app_transcricao AS INT64)                          AS qtd_app_transcricao,
  SAFE_CAST(u.app_asaas AS INT64)                                AS qtd_app_asaas,
  SAFE_CAST(u.app_ia AS INT64)                                   AS qtd_app_ia,
  f.usuarios_cortesia,
  f.usuarios_faixa1,
  f.usuarios_faixa2,
  f.usuarios_faixa3,
  f.usuarios_cortesia + f.usuarios_faixa1 + f.usuarios_faixa2 + f.usuarios_faixa3 AS qtd_usuarios,
  f.vagas_faixa1_usuarios,
  f.canais_cortesia,
  f.canais_faixa1,
  f.canais_faixa2,
  f.canais_cortesia + f.canais_faixa1 + f.canais_faixa2          AS qtd_canais,
  f.vagas_faixa1_canais,
  f.custo_helena,
  (SAFE_CAST(u.instancia_dias AS FLOAT64) = 0)                   AS flag_sem_instancia,
  (SAFE_CAST(u.app_transcricao AS INT64) = 0 AND SAFE_CAST(u.app_asaas AS INT64) = 0 AND SAFE_CAST(u.app_ia AS INT64) = 0) AS flag_sem_app,
  'L3_CONFIDENTIAL'                                              AS classificacao_dado,
  CURRENT_TIMESTAMP()                                            AS _extraido_at,
  'supabase-x0tz'                                                AS _fonte,
  'America/Sao_Paulo'                                            AS _fuso,
  TO_HEX(MD5(CONCAT(TO_JSON_STRING(u), '|', TO_JSON_STRING(f)))) AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_gold_mvw_custo_wl_uso_conta_mes` u
JOIN `vanguardamartech_raw`.`supabase_gold_vw_consumo_vbot_faixas` f
  ON f.periodo = u.periodo AND f.conta_key = u.conta_key
