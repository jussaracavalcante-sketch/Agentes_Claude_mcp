-- rfn_qualidade__regra_midia_refined (query-x2az) · 23 regras · Refined / qualidade · L2 INTERNAL
-- Grao: uma REGRA em uma execucao. Cobre as 6 Refined de midia de 06/10 (palavra_chave_mensal, grupo_anuncio_mensal, conversao_categoria_mensal, conta_estrutura, video_mensal, alcance_mensal).
-- Gatilho: evento nas 6 Refined com regra "all" (query-wykH, Qepg, yxEh, 4JAW, CTe7, O7Qi). Alerta ligado. Cadencia semanal (terca, google-ads-cwt3).
-- Identidades: o que a Refined soma tem de reproduzir a Trusted de que le (a Refined agrega, nao filtra).
WITH r AS (
  SELECT 'rfn_midia__palavra_chave_mensal.chave_unica' AS id_regra, 'Refined' AS camada, 'rfn_midia__palavra_chave_mensal' AS tabela, 'Google Ads' AS sistema, 'UNICIDADE' AS dimensao,
         'id_palavra_mensal e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_palavra_mensal) + COUNTIF(id_palavra_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_midia__palavra_chave_mensal`
  UNION ALL SELECT 'rfn_midia__grupo_anuncio_mensal.chave_unica', 'Refined', 'rfn_midia__grupo_anuncio_mensal', 'Google Ads', 'UNICIDADE',
         'id_grupo_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_grupo_mensal) + COUNTIF(id_grupo_mensal IS NULL)
  FROM `vanguardamartech_refined`.`rfn_midia__grupo_anuncio_mensal`
  UNION ALL SELECT 'rfn_midia__conversao_categoria_mensal.chave_unica', 'Refined', 'rfn_midia__conversao_categoria_mensal', 'Google Ads', 'UNICIDADE',
         'id_conversao_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_conversao_mensal) + COUNTIF(id_conversao_mensal IS NULL)
  FROM `vanguardamartech_refined`.`rfn_midia__conversao_categoria_mensal`
  UNION ALL SELECT 'rfn_midia__conta_estrutura.chave_unica', 'Refined', 'rfn_midia__conta_estrutura', 'Google Ads', 'UNICIDADE',
         'id_conta e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_conta) + COUNTIF(id_conta IS NULL)
  FROM `vanguardamartech_refined`.`rfn_midia__conta_estrutura`
  UNION ALL SELECT 'rfn_midia__video_mensal.chave_unica', 'Refined', 'rfn_midia__video_mensal', 'Google Ads', 'UNICIDADE',
         'id_video_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_video_mensal) + COUNTIF(id_video_mensal IS NULL)
  FROM `vanguardamartech_refined`.`rfn_midia__video_mensal`
  UNION ALL SELECT 'rfn_midia__alcance_mensal.chave_unica', 'Refined', 'rfn_midia__alcance_mensal', 'Google Ads', 'UNICIDADE',
         'id_alcance_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_alcance_mensal) + COUNTIF(id_alcance_mensal IS NULL)
  FROM `vanguardamartech_refined`.`rfn_midia__alcance_mensal`
  -- IDENTIDADES: a soma da Refined reproduz a da Trusted (grao: a tabela inteira, 1 linha avaliada)
  UNION ALL SELECT 'rfn_midia__palavra_chave_mensal.investimento_reproduz_a_trusted', 'Refined', 'rfn_midia__palavra_chave_mensal', 'Google Ads', 'VALIDADE',
         'a soma de investimento reproduz trs_google_ads__palavra_chave dentro de um centavo', 'BLOQUEANTE', 1.00,
         1, IF(ABS((SELECT SUM(investimento) FROM `vanguardamartech_refined`.`rfn_midia__palavra_chave_mensal`) - (SELECT SUM(investimento_micros) / 1e6 FROM `vanguardamartech_trusted`.`trs_google_ads__palavra_chave`)) > 0.01, 1, 0)
  UNION ALL SELECT 'rfn_midia__grupo_anuncio_mensal.investimento_reproduz_a_trusted', 'Refined', 'rfn_midia__grupo_anuncio_mensal', 'Google Ads', 'VALIDADE',
         'a soma de investimento reproduz trs_google_ads__grupo_anuncio_diario dentro de um centavo', 'BLOQUEANTE', 1.00,
         1, IF(ABS((SELECT SUM(investimento) FROM `vanguardamartech_refined`.`rfn_midia__grupo_anuncio_mensal`) - (SELECT SUM(investimento_micros) / 1e6 FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio_diario`)) > 0.01, 1, 0)
  UNION ALL SELECT 'rfn_midia__video_mensal.investimento_reproduz_a_trusted', 'Refined', 'rfn_midia__video_mensal', 'Google Ads', 'VALIDADE',
         'a soma de investimento reproduz trs_google_ads__video_desempenho_diario dentro de um centavo', 'BLOQUEANTE', 1.00,
         1, IF(ABS((SELECT SUM(investimento) FROM `vanguardamartech_refined`.`rfn_midia__video_mensal`) - (SELECT SUM(investimento_micros) / 1e6 FROM `vanguardamartech_trusted`.`trs_google_ads__video_desempenho_diario`)) > 0.01, 1, 0)
  UNION ALL SELECT 'rfn_midia__alcance_mensal.impressoes_reproduzem_a_trusted', 'Refined', 'rfn_midia__alcance_mensal', 'Google Ads', 'VALIDADE',
         'a soma de impressoes reproduz trs_google_ads__alcance_frequencia_campanha exatamente', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(impressoes) FROM `vanguardamartech_refined`.`rfn_midia__alcance_mensal`) <> (SELECT SUM(impressoes) FROM `vanguardamartech_trusted`.`trs_google_ads__alcance_frequencia_campanha`), 1, 0)
  UNION ALL SELECT 'rfn_midia__conversao_categoria_mensal.conversoes_reproduzem_a_trusted', 'Refined', 'rfn_midia__conversao_categoria_mensal', 'Google Ads', 'VALIDADE',
         'a soma de conversoes_campanha reproduz trs_google_ads__conversao_acao_campanha dentro de 0,01', 'BLOQUEANTE', 1.00,
         1, IF(ABS((SELECT SUM(conversoes_campanha) FROM `vanguardamartech_refined`.`rfn_midia__conversao_categoria_mensal`) - (SELECT SUM(conversoes) FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_campanha`)) > 0.01, 1, 0)
  UNION ALL SELECT 'rfn_midia__conta_estrutura.uma_linha_por_conta_integrada', 'Refined', 'rfn_midia__conta_estrutura', 'Google Ads', 'INTEGRIDADE',
         'o numero de linhas e o numero de contas integradas na Nekt em trs_google_ads__conta', 'BLOQUEANTE', 1.00,
         1, IF((SELECT COUNT(*) FROM `vanguardamartech_refined`.`rfn_midia__conta_estrutura`) <> (SELECT COUNTIF(integrada_na_nekt) FROM `vanguardamartech_trusted`.`trs_google_ads__conta`), 1, 0)
  -- VALIDADE
  UNION ALL SELECT 'rfn_midia__palavra_chave_mensal.investimento_nao_negativo', 'Refined', 'rfn_midia__palavra_chave_mensal', 'Google Ads', 'VALIDADE',
         'investimento nunca e negativo', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(investimento < 0)
  FROM `vanguardamartech_refined`.`rfn_midia__palavra_chave_mensal`
  UNION ALL SELECT 'rfn_midia__grupo_anuncio_mensal.investimento_nao_negativo', 'Refined', 'rfn_midia__grupo_anuncio_mensal', 'Google Ads', 'VALIDADE',
         'investimento nunca e negativo', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(investimento < 0)
  FROM `vanguardamartech_refined`.`rfn_midia__grupo_anuncio_mensal`
  UNION ALL SELECT 'rfn_midia__palavra_chave_mensal.dias_dentro_do_mes', 'Refined', 'rfn_midia__palavra_chave_mensal', 'Google Ads', 'VALIDADE',
         'dias_com_linha esta entre 1 e o numero de dias do mes', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(dias_com_linha < 1 OR dias_com_linha > EXTRACT(DAY FROM LAST_DAY(mes_referencia)))
  FROM `vanguardamartech_refined`.`rfn_midia__palavra_chave_mensal`
  UNION ALL SELECT 'rfn_midia__grupo_anuncio_mensal.dias_dentro_do_mes', 'Refined', 'rfn_midia__grupo_anuncio_mensal', 'Google Ads', 'VALIDADE',
         'dias_com_linha esta entre 1 e o numero de dias do mes', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(dias_com_linha < 1 OR dias_com_linha > EXTRACT(DAY FROM LAST_DAY(mes_referencia)))
  FROM `vanguardamartech_refined`.`rfn_midia__grupo_anuncio_mensal`
  UNION ALL SELECT 'rfn_midia__alcance_mensal.dias_dentro_do_mes', 'Refined', 'rfn_midia__alcance_mensal', 'Google Ads', 'VALIDADE',
         'dias_com_dado esta entre 1 e o numero de dias do mes', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF(dias_com_dado < 1 OR dias_com_dado > EXTRACT(DAY FROM LAST_DAY(mes_referencia)))
  FROM `vanguardamartech_refined`.`rfn_midia__alcance_mensal`
  -- PARTICIPACAO: dentro de (conta, mes) as participacoes somam 1 quando ha investimento (grao: o grupo conta-mes)
  UNION ALL SELECT 'rfn_midia__palavra_chave_mensal.participacao_soma_um_na_conta_mes', 'Refined', 'rfn_midia__palavra_chave_mensal', 'Google Ads', 'VALIDADE',
         'a participacao no investimento da conta soma 1 em cada (conta, mes) com investimento', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(ABS(s - 1) > 0.0001)
  FROM (SELECT id_conta, mes_referencia, SUM(participacao_investimento_conta_mes) AS s FROM `vanguardamartech_refined`.`rfn_midia__palavra_chave_mensal` GROUP BY 1, 2 HAVING SUM(investimento) > 0)
  UNION ALL SELECT 'rfn_midia__grupo_anuncio_mensal.participacao_soma_um_na_conta_mes', 'Refined', 'rfn_midia__grupo_anuncio_mensal', 'Google Ads', 'VALIDADE',
         'a participacao no investimento da conta soma 1 em cada (conta, mes) com investimento', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(ABS(s - 1) > 0.0001)
  FROM (SELECT id_conta, mes_referencia, SUM(participacao_investimento_conta_mes) AS s FROM `vanguardamartech_refined`.`rfn_midia__grupo_anuncio_mensal` GROUP BY 1, 2 HAVING SUM(investimento) > 0)
  -- INTEGRIDADE: conta catalogada (linha de base; dimensao e fotografia)
  UNION ALL SELECT 'rfn_midia__palavra_chave_mensal.conta_catalogada', 'Refined', 'rfn_midia__palavra_chave_mensal', 'Google Ads', 'INTEGRIDADE',
         'a conta existe em trs_google_ads__conta', 'ALERTA', 0.99, COUNT(*), COUNTIF(flag_conta_nao_catalogada)
  FROM `vanguardamartech_refined`.`rfn_midia__palavra_chave_mensal`
  UNION ALL SELECT 'rfn_midia__grupo_anuncio_mensal.conta_catalogada', 'Refined', 'rfn_midia__grupo_anuncio_mensal', 'Google Ads', 'INTEGRIDADE',
         'a conta existe em trs_google_ads__conta', 'ALERTA', 0.99, COUNT(*), COUNTIF(flag_conta_nao_catalogada)
  FROM `vanguardamartech_refined`.`rfn_midia__grupo_anuncio_mensal`
  UNION ALL SELECT 'rfn_midia__video_mensal.conta_catalogada', 'Refined', 'rfn_midia__video_mensal', 'Google Ads', 'INTEGRIDADE',
         'a conta existe em trs_google_ads__conta', 'ALERTA', 0.99, COUNT(*), COUNTIF(flag_conta_nao_catalogada)
  FROM `vanguardamartech_refined`.`rfn_midia__video_mensal`
  UNION ALL SELECT 'rfn_midia__alcance_mensal.conta_catalogada', 'Refined', 'rfn_midia__alcance_mensal', 'Google Ads', 'INTEGRIDADE',
         'a conta existe em trs_google_ads__conta', 'ALERTA', 0.99, COUNT(*), COUNTIF(flag_conta_nao_catalogada)
  FROM `vanguardamartech_refined`.`rfn_midia__alcance_mensal`
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
  'MIDIA_REFINED' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'google-ads-cwt3' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a
