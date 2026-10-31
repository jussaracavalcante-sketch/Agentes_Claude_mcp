-- trs_fiscal__simples_vbot_mes  ·  query-bJwI  ·  Trusted  ·  gatilho: cron segunda 06:00 America/Manaus  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Trusted / FISCAL (VBOT). Grao: um PERIODO (mes) da SIMULACAO do Simples Nacional da VBOT: receita declarada e do Conexa, RBT12,
-- faixa e aliquotas do Anexo III, DAS simulado (sobre a declarada e sobre o Conexa), PIS/COFINS suspenso (ZFM), DAS pago e as diferencas.
-- Chave: periodo. 18 distintos em 18 linhas (2025-06 a 2026-11), medido em 2026-10-19. Nivel: L3 CONFIDENTIAL (fiscal da casa).
--
-- ISTO E SIMULACAO, NAO APURACAO. NENHUM VALOR AQUI E TRIBUTO DEVIDO OU PAGO AO FISCO, EXCETO das_pago (9 periodos, informado a mao).
-- A TABELA DE FAIXAS (supabase_meta_simples_anexo3) ESTA MARCADA "NAO CONFERIDA CONTRA APURACAO" EM 5 DAS 6 FAIXAS; so a faixa 4 foi
-- conferida (apuracao 06/2026). NAO APRESENTAR COMO APURACAO, NAO USAR PARA RECOLHER, NAO USAR PARA PROVISIONAR SEM O CONTADOR.
--
-- ORIGEM: supabase_gold_vw_simples_vbot_mes (18) LEFT JOIN supabase_gold_vw_simples_vbot_conferencia (18) por periodo: mesmos 18 periodos
--   e as 6 colunas em comum IDENTICAS (zero divergencias); a conferencia acrescenta das_pago, pago_em e as duas diferencas. Viram UMA tabela.
-- METODO DA ORIGEM, MEDIDO (nao recalculado aqui): aliquota_efetiva = (rbt12 x aliquota_nominal/100 - parcela_deduzir) / rbt12 nas 17 linhas
--   com faixa (reproduz o Anexo III); aliq_pis_cofins = aliquota_efetiva x (p_pis + p_cofins)/100; aliq_iss = aliquota_efetiva x p_iss/100;
--   aliq_sem_pis_cofins = aliquota_efetiva - aliq_pis_cofins. das_simulado_conexa = receita_conexa x aliq_sem_pis_cofins/100 (12 de 12):
--   O MES APLICA A SUSPENSAO DE PIS/COFINS DA ZONA FRANCA A RECEITA INTEIRA, enquanto a simulacao por cliente so aplica aos clientes ZFM
--   (ver trs_fiscal__simples_vbot_cliente_mes): por isso SUM(simples_simulado dos clientes) > das_simulado_conexa em 11 de 12 periodos.
--   E diferenca de METODO entre duas views da origem, nao erro de extracao; a Refined mostra as duas lado a lado.
--   das_simulado_declarada = receita_declarada x aliq_sem_pis_cofins/100 - receita_iss_retido x aliq_iss/100 (12 de 12; so 2026-06 tem ISS retido).
--   pis_cofins_suspenso = receita_declarada x aliq_pis_cofins/100 (12 de 12).
-- SENTINELA -> NULL: a origem escreve das_simulado_conexa = 0 em 5 periodos (2025-07 a 2025-11) em que receita_conexa E NULL (o Conexa
--   ainda nao operava): aqui sai NULL, com flag_das_conexa_zerado_na_origem. dif_receita_conexa_declarada e dif_pago_simulado da origem
--   usam IFNULL(x, 0) e por isso saem como *_origem; as versoes sem sufixo so existem quando os dois lados existem.
-- fonte_rbt12: DECLARADA (13 periodos, 2025-06 a 2026-06) ou 'CONEXA (sem declaracao)' (5, 2026-07 em diante): a partir de 2026-07 nao ha
--   receita declarada e o RBT12 usa o Conexa. rbt12 proporcionalizado em 12 dos 18 (meses_janela < 12). 2025-06 nao tem faixa (janela 0).
-- LIMITACAO - NAO CONTORNE: receita_conexa e NULL de 2025-06 a 2025-11; receita_declarada e NULL de 2026-07 em diante; das_pago so em 9
--   periodos (2025-12 a 2026-08). Nao somar das_simulado_declarada com das_simulado_conexa: sao duas simulacoes do mesmo mes.
SELECT
  m.periodo                                                      AS id_periodo,
  m.periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(m.periodo, '-01'))          AS mes_referencia,
  'SIMULACAO_NAO_CONFERIDA'                                      AS natureza,
  m.receita_declarada,
  m.receita_iss_retido,
  m.receita_conexa,
  NULLIF(TRIM(m.fonte_rbt12), '')                                AS fonte_rbt12,
  (m.fonte_rbt12 <> 'DECLARADA')                                 AS is_sem_declaracao,
  m.meses_janela,
  (m.meses_janela >= 12)                                         AS is_janela_completa,
  m.rbt12,
  m.rbt12_proporcionalizado                                      AS is_rbt12_proporcionalizado,
  m.faixa                                                        AS faixa_anexo3,
  m.aliquota_efetiva                                             AS aliquota_efetiva_pct,
  m.aliq_pis_cofins                                              AS aliq_pis_cofins_pct,
  m.aliq_sem_pis_cofins                                          AS aliq_sem_pis_cofins_pct,
  m.aliq_iss                                                     AS aliq_iss_pct,
  m.das_simulado_declarada,
  IF(m.receita_conexa IS NULL, NULL, m.das_simulado_conexa)      AS das_simulado_conexa,
  (m.receita_conexa IS NULL AND m.das_simulado_conexa IS NOT NULL) AS flag_das_conexa_zerado_na_origem,
  m.pis_cofins_suspenso,
  c.das_pago,
  SAFE.PARSE_DATE('%Y-%m-%d', c.pago_em)                         AS das_pago_em,
  (c.das_pago IS NOT NULL)                                       AS flag_das_pago_informado,
  c.dif_pago_simulado                                            AS dif_pago_simulado_origem,
  IF(c.das_pago IS NULL OR m.das_simulado_declarada IS NULL, NULL, ROUND(c.das_pago - m.das_simulado_declarada, 2)) AS dif_pago_simulado,
  c.dif_receita_conexa_declarada                                 AS dif_receita_conexa_declarada_origem,
  IF(m.receita_conexa IS NULL OR m.receita_declarada IS NULL, NULL, ROUND(m.receita_conexa - m.receita_declarada, 2)) AS dif_receita_conexa_declarada,
  'L3_CONFIDENTIAL'                                              AS classificacao_dado,
  CURRENT_TIMESTAMP()                                            AS _extraido_at,
  'supabase-x0tz'                                                AS _fonte,
  'America/Sao_Paulo'                                            AS _fuso,
  TO_HEX(MD5(CONCAT(TO_JSON_STRING(m), '|', IFNULL(TO_JSON_STRING(c), '')))) AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_gold_vw_simples_vbot_mes` m
LEFT JOIN `vanguardamartech_raw`.`supabase_gold_vw_simples_vbot_conferencia` c
  ON c.periodo = m.periodo
