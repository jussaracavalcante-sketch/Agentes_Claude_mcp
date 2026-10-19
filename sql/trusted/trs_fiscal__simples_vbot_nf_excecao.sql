-- trs_fiscal__simples_vbot_nf_excecao  ·  query-vSVV  ·  Trusted  ·  gatilho: cron segunda 06:00 America/Manaus  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Trusted / FISCAL (VBOT). Grao: uma COBRANCA do Conexa em excecao de nota fiscal em um periodo: PAGA SEM NF ou ABERTA SEM NF (a emitir na
-- quitacao). Chave (periodo, cobranca_id): 260 distintos em 260 linhas, 260 cobrancas distintas (nenhuma repete periodo), 11 periodos
-- (2026-01 a 2026-11), 78 clientes, medido em 2026-10-19. Nivel: L3 CONFIDENTIAL (cobranca por cliente; razao social, nao pessoa fisica identificavel).
-- ORIGEM: supabase_gold_vw_simples_vbot_nf_excecoes (260; o catalogo dizia 259). CONTROLE GERENCIAL da emissao de NF, nao apuracao.
-- INTEGRIDADE: as 260 cobrancas existem em trs_conexa__cobranca e as 260 sao vigentes la (id_cobranca e INT64 la e STRING aqui: comparar com CAST).
-- TIPO x STATUS, medido: PAGO SEM NF / paid 160 (R$ 240.010,01); ABERTO SEM NF / unpaid 74 (R$ 79.956,39), / negotiated 12 (R$ 16.029,39),
--   / cancelled 14 (R$ 18.213,86). COBRANCA CANCELADA CONTA COMO 'ABERTO SEM NF' NA ORIGEM e entra no backlog de trs_fiscal__simples_vbot_nf_mes:
--   is_cancelada separa; o backlog vigente (sem cancelada) e R$ 95.985,78 em 86 cobrancas.
-- due_date vem NULL em 1 linha. valor > 0 nas 260.
-- LIMITACAO - NAO CONTORNE: o periodo e o da COMPETENCIA da cobranca na simulacao, nao o do vencimento nem o do pagamento; 2025-12 nao
--   esta aqui embora a defasagem conte 5 pagos sem NF nesse mes.
SELECT
  CONCAT(e.periodo, '|', CAST(e.cobranca_id AS STRING))          AS id_excecao,
  e.periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(e.periodo, '-01'))          AS mes_referencia,
  CAST(e.cobranca_id AS STRING)                                  AS id_cobranca,
  NULLIF(TRIM(e.cliente), '')                                    AS cliente,
  e.valor,
  SAFE_CAST(e.due_date AS DATE)                                  AS data_vencimento,
  NULLIF(TRIM(e.status), '')                                     AS status_origem,
  NULLIF(TRIM(e.tipo), '')                                       AS tipo_origem,
  CASE WHEN e.tipo = 'PAGO SEM NF' THEN 'PAGO_SEM_NF'
       WHEN STARTS_WITH(e.tipo, 'ABERTO SEM NF') THEN 'ABERTO_SEM_NF'
       ELSE 'OUTRO' END                                          AS tipo_excecao,
  (e.status = 'paid')                                            AS is_paga,
  (e.status = 'cancelled')                                       AS is_cancelada,
  (STARTS_WITH(e.tipo, 'ABERTO SEM NF') AND e.status <> 'cancelled') AS is_backlog_vigente,
  'L3_CONFIDENTIAL'                                              AS classificacao_dado,
  CURRENT_TIMESTAMP()                                            AS _extraido_at,
  'supabase-x0tz'                                                AS _fonte,
  'America/Sao_Paulo'                                            AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(e)))                                 AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_gold_vw_simples_vbot_nf_excecoes` e
