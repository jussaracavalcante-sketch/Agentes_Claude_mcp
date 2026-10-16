-- rfn_qualidade__regra_prestex · 16 regras · L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA em uma execucao. Cobre a cadeia semanal da conta Prestex (google-ads-OzfZ):
--   Trusted trs_google_ads__insight_semanal (query-FzRx) e Refined rfn_midia__desempenho_semanal (query-vS7B).
-- Gatilho: evento em query-vS7B (ultimo elo). Alerta ligado. Cadencia: a da fonte (gatilho MANUAL; so roda quando a OzfZ roda).
-- Suite propria porque a suite de Midia (query-4tgF) mede as contas DIARIAS e dispara na cadeia da terca; a Prestex nao anda nela.
-- Todas medidas em 2026-10-16 sobre o MESMO codigo das duas tabelas rodado como subconsulta (as tabelas ainda nao tinham materializado).
-- A flag de semana incompleta e gravada na carga: a regra compara contra DATE(_extraido_at), nunca CURRENT_DATE.
WITH t AS (SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__insight_semanal`),
r_ AS (SELECT * FROM `vanguardamartech_refined`.`rfn_midia__desempenho_semanal`),
r AS (
  SELECT 'trs_google_ads__insight_semanal.id_insight_unico' AS id_regra, 'Trusted' AS camada, 'trs_google_ads__insight_semanal' AS tabela, 'GOOGLE_ADS' AS sistema, 'UNICIDADE' AS dimensao,
         'id_insight e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_insight) + COUNTIF(id_insight IS NULL) AS linhas_falha FROM t
  UNION ALL
  SELECT 'trs_google_ads__insight_semanal.semana_comeca_na_segunda', 'Trusted', 'trs_google_ads__insight_semanal', 'GOOGLE_ADS', 'VALIDADE',
         'toda semana_inicio e uma segunda-feira (a origem e semanal; DATE(date) sem fuso)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(EXTRACT(DAYOFWEEK FROM semana_inicio) <> 2 OR flag_semana_nao_comeca_na_segunda) FROM t
  UNION ALL
  SELECT 'trs_google_ads__insight_semanal.semana_fim_e_inicio_mais_6', 'Trusted', 'trs_google_ads__insight_semanal', 'GOOGLE_ADS', 'VALIDADE',
         'semana_fim = semana_inicio + 6 dias', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(semana_fim <> DATE_ADD(semana_inicio, INTERVAL 6 DAY)) FROM t
  UNION ALL
  SELECT 'trs_google_ads__insight_semanal.conta_catalogada', 'Trusted', 'trs_google_ads__insight_semanal', 'GOOGLE_ADS', 'INTEGRIDADE',
         'conta resolve em trs_google_ads__conta (cliente e moeda preenchidos)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_conta_nao_catalogada OR cliente IS NULL OR moeda IS NULL) FROM t
  UNION ALL
  SELECT 'trs_google_ads__insight_semanal.campanha_catalogada', 'Trusted', 'trs_google_ads__insight_semanal', 'GOOGLE_ADS', 'INTEGRIDADE',
         'campanha com desempenho existe no cadastro de campanhas da Prestex', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_campanha_nao_catalogada) FROM t
  UNION ALL
  SELECT 'trs_google_ads__insight_semanal.investimento_nao_negativo', 'Trusted', 'trs_google_ads__insight_semanal', 'GOOGLE_ADS', 'VALIDADE',
         'investimento_micros nunca e negativo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(investimento_micros < 0) FROM t
  UNION ALL
  SELECT 'trs_google_ads__insight_semanal.moeda_unica_brl', 'Trusted', 'trs_google_ads__insight_semanal', 'GOOGLE_ADS', 'VALIDADE',
         'a conta e BRL; outra moeda exige decidir antes de somar', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(moeda IS DISTINCT FROM 'BRL') FROM t
  UNION ALL
  -- O Google atribui clique e impressao por regras diferentes: linha de base, nao identidade.
  SELECT 'trs_google_ads__insight_semanal.clique_nao_excede_impressao', 'Trusted', 'trs_google_ads__insight_semanal', 'GOOGLE_ADS', 'VALIDADE',
         'cliques nao excedem impressoes na linha', 'ALERTA', 0.99,
         COUNT(*), COUNTIF(cliques > impressoes) FROM t
  UNION ALL
  -- A premissa do grao misto: nenhum par (campanha, semana) pode aparecer nos dois graos, senao o investimento conta duas vezes.
  SELECT 'trs_google_ads__insight_semanal.grao_sem_dupla_contagem', 'Trusted', 'trs_google_ads__insight_semanal', 'GOOGLE_ADS', 'UNICIDADE',
         'nenhum par (campanha, semana) em ANUNCIO e CAMPANHA ao mesmo tempo (grao misto exato)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_graos > 1)
  FROM (SELECT id_campanha, semana_inicio, COUNT(DISTINCT grao) AS qtd_graos FROM t GROUP BY id_campanha, semana_inicio)
  UNION ALL
  -- Identidade contra a ORIGEM: a Trusted nao perde nem duplica investimento, cliques ou conversoes em relacao a campaign_performance.
  SELECT 'trs_google_ads__insight_semanal.reproduz_a_origem', 'Trusted', 'trs_google_ads__insight_semanal', 'GOOGLE_ADS', 'INTEGRIDADE',
         'soma de investimento_micros, cliques e conversoes da Trusted = campaign_performance da origem (grao 1 linha)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(investimento_micros) FROM t) = (SELECT SUM(metrics_cost_micros) FROM `vanguardamartech_prestex`.`google_ads_prestex_campaign_performance`)
           AND (SELECT SUM(cliques) FROM t) = (SELECT SUM(metrics_clicks) FROM `vanguardamartech_prestex`.`google_ads_prestex_campaign_performance`)
           AND ABS((SELECT SUM(conversoes) FROM t) - (SELECT SUM(metrics_conversions) FROM `vanguardamartech_prestex`.`google_ads_prestex_campaign_performance`)) < 0.01, 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'trs_google_ads__insight_semanal.flag_incompleta_concorda_com_a_carga', 'Trusted', 'trs_google_ads__insight_semanal', 'GOOGLE_ADS', 'VALIDADE',
         'flag_semana_incompleta_na_carga = (semana_fim >= DATE(_extraido_at) em America/Sao_Paulo); nunca contra CURRENT_DATE', 'ALERTA', 0.99,
         COUNT(*), COUNTIF(flag_semana_incompleta_na_carga <> (semana_fim >= DATE(_extraido_at, 'America/Sao_Paulo'))) FROM t
  UNION ALL
  SELECT 'rfn_midia__desempenho_semanal.id_desempenho_semanal_unico', 'Refined', 'rfn_midia__desempenho_semanal', 'GOOGLE_ADS', 'UNICIDADE',
         'id_desempenho_semanal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_desempenho_semanal) + COUNTIF(id_desempenho_semanal IS NULL) FROM r_
  UNION ALL
  -- A Refined agrega campanha-semana e nao filtra: mesma cardinalidade e mesmo investimento da Trusted.
  SELECT 'rfn_midia__desempenho_semanal.reproduz_a_trusted', 'Refined', 'rfn_midia__desempenho_semanal', 'GOOGLE_ADS', 'INTEGRIDADE',
         'linhas e investimento_micros da Refined = pares (campanha, semana) e soma da Trusted (grao 1 linha)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT COUNT(*) FROM r_) = (SELECT COUNT(*) FROM (SELECT DISTINCT id_conta, id_campanha, semana_inicio FROM t))
           AND (SELECT SUM(investimento_micros) FROM r_) = (SELECT SUM(investimento_micros) FROM t), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_midia__desempenho_semanal.grao_nunca_misto', 'Refined', 'rfn_midia__desempenho_semanal', 'GOOGLE_ADS', 'VALIDADE',
         'grao_origem nunca e MISTO e flag_grao_misto concorda', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(grao_origem = 'MISTO' OR flag_grao_misto <> (grao_origem = 'MISTO')) FROM r_
  UNION ALL
  SELECT 'rfn_midia__desempenho_semanal.cpa_so_com_conversao', 'Refined', 'rfn_midia__desempenho_semanal', 'GOOGLE_ADS', 'VALIDADE',
         'cpa e NULL exatamente quando conversoes = 0 (nunca zero por falta de denominador)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF((conversoes = 0) <> (cpa IS NULL)) FROM r_
  UNION ALL
  SELECT 'rfn_midia__desempenho_semanal.confiavel_nao_convive_com_semana_incompleta', 'Refined', 'rfn_midia__desempenho_semanal', 'GOOGLE_ADS', 'VALIDADE',
         'registro_confiavel nunca e TRUE em semana incompleta, conta ou campanha nao catalogada', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(registro_confiavel AND (flag_semana_incompleta_na_carga OR flag_conta_nao_catalogada OR flag_campanha_nao_catalogada OR flag_grao_misto)) FROM r_
),
avaliado AS (
  SELECT r.*, (r.linhas_avaliadas - r.linhas_falha) AS linhas_conformes,
    SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, NULLIF(r.linhas_avaliadas, 0)) AS taxa_conformidade,
    IF(r.linhas_avaliadas = 0, NULL, SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, r.linhas_avaliadas) >= r.limiar) AS is_conforme,
    (r.linhas_avaliadas = 0) AS flag_sem_linha_para_avaliar
  FROM r
)
SELECT a.*,
  CASE WHEN a.flag_sem_linha_para_avaliar THEN 'SEM_DADO' WHEN a.is_conforme THEN 'CONFORME'
       WHEN a.severidade = 'BLOQUEANTE' THEN 'FALHA_BLOQUEANTE' ELSE 'FALHA_ALERTA' END AS resultado,
  'PRESTEX' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'google-ads-OzfZ' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a
