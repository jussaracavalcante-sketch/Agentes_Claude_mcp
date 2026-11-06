-- trs_fiscal__simples_vbot_nf_mes  ·  query-AQ3H  ·  Trusted  ·  gatilho: cron segunda 06:00 America/Manaus  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Trusted / FISCAL (VBOT). Grao: um PERIODO (mes) da defasagem entre receita do Conexa e receita declarada ao Simples, explicada pela
-- emissao de nota fiscal: regime (NF na quitacao ate 2026-06, NF na competencia a partir de 2026-07), valor com NF, backlog a emitir,
-- pago sem NF e cobertura de NF nos pagos. Chave: periodo. 12 distintos em 12 linhas (2025-12 a 2026-11), medido em 2026-10-19.
-- Nivel: L3 CONFIDENTIAL (fiscal da casa). SIMULACAO/CONTROLE GERENCIAL, NAO APURACAO.
-- ORIGEM: supabase_gold_vw_simples_vbot_nf_defasagem (12; o catalogo dizia 10).
-- DECOMPOSICOES MEDIDAS (zero quebras em 12): qt_pago = qt_pago_com_nf + qt_pago_sem_nf; pct_pago_com_nf = qt_pago_com_nf / qt_pago x 100;
--   dif_mensal = receita_conexa - receita_declarada nos 11 comparaveis; regime_competencia <-> regime = 'NF na competencia'.
-- O BACKLOG DA ORIGEM INCLUI COBRANCA CANCELADA: qt_backlog bate com TODAS as linhas 'ABERTO SEM NF' de trs_fiscal__simples_vbot_nf_excecao
--   (inclusive status cancelled) em 8 de 8 periodos com backlog, e backlog_a_emitir e maior que a soma das vigentes em 5 deles
--   (ex.: 2026-06 backlog R$ 4.174,45 com ZERO cobranca aberta nao cancelada). Passa como veio; a Refined separa o backlog vigente.
-- pago_sem_nf e qt_pago_sem_nf batem EXATAMENTE com a excecao 'PAGO SEM NF' em 11 de 11 periodos a partir de 2026-01; em 2025-12 a
--   defasagem conta 5 pagos sem NF (R$ 8.309,20) e a tabela de excecoes nao tem linha desse periodo (comeca em 2026-01).
-- LIMITACAO - NAO CONTORNE: receita_declarada e NULL de 2026-07 em diante (aguardando_apuracao = TRUE em 5 periodos) e dif_mensal/acumulada
--   saem NULL ali; 2025-12 nao e comparavel (comparavel = FALSE). pct_pago_com_nf e NULL quando qt_pago = 0 (2026-11).
SELECT
  d.periodo                                                      AS id_periodo,
  d.periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(d.periodo, '-01'))          AS mes_referencia,
  d.comparavel                                                   AS is_comparavel,
  d.regime_competencia                                           AS is_regime_competencia,
  NULLIF(TRIM(d.regime), '')                                     AS regime_nf,
  d.aguardando_apuracao                                          AS is_aguardando_apuracao,
  d.receita_conexa,
  d.receita_declarada,
  d.dif_mensal,
  d.dif_acumulada,
  d.valor_com_nf,
  d.backlog_a_emitir                                             AS backlog_a_emitir_origem,
  d.qt_backlog                                                   AS qtd_backlog_origem,
  d.pago_sem_nf                                                  AS valor_pago_sem_nf,
  d.qt_pago_sem_nf                                               AS qtd_pago_sem_nf,
  d.qt_pago                                                      AS qtd_pago,
  d.qt_pago_com_nf                                               AS qtd_pago_com_nf,
  d.pct_pago_com_nf,
  'L3_CONFIDENTIAL'                                              AS classificacao_dado,
  CURRENT_TIMESTAMP()                                            AS _extraido_at,
  'supabase-x0tz'                                                AS _fonte,
  'America/Sao_Paulo'                                            AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(d)))                                 AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_gold_vw_simples_vbot_nf_defasagem` d
