-- rfn_qualidade__regra_prestex_breakdowns · 61 regras · L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA em uma execucao. Cobre os 11 streams da Prestex (google-ads-OzfZ) que ganharam Trusted em 18/10/2026
-- (termo de busca, localizacao do usuario, faixa etaria, genero, geografico, palavra-chave, grupo de anuncios, video, alcance, conversao por categoria campanha e anuncio)
-- e as 8 Refined mensais/semanais por cima delas. Suite propria: a principal esta em 57 KB e a rfn_qualidade__regra_prestex mede so a cadeia insight_semanal.
-- Gatilho: evento (regra all) nas 8 Refined. Cadencia: a da fonte (gatilho MANUAL; so roda quando a google-ads-OzfZ roda e a cadeia inteira termina).
-- A flag de semana incompleta e gravada na carga: a regra compara contra DATE(_extraido_at), nunca CURRENT_DATE. Regra sobre o DADO (nunca futuro) pode usar o relogio.
-- Validadas em 2026-10-18 reproduzindo as 11 Trusted e as 8 Refined sobre a Raw (as tabelas novas ainda nao tinham materializado).
WITH
t_termo AS (SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__termo_busca_semanal`),
t_local AS (SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_localizacao_usuario_semanal`),
t_idade AS (SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_faixa_etaria_semanal`),
t_genero AS (SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_genero_semanal`),
t_geo AS (SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__segmento_geografico_semanal`),
t_kw AS (SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__palavra_chave_semanal`),
t_grupo AS (SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio_semanal`),
t_video AS (SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__video_desempenho_semanal`),
t_alcance AS (SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__alcance_frequencia_campanha_semanal`),
t_cc AS (SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_campanha_prestex`),
t_ca AS (SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_anuncio_prestex`),
r_termo AS (SELECT * FROM `vanguardamartech_refined`.`rfn_midia__termo_busca_semanal`),
r_seg AS (SELECT * FROM `vanguardamartech_refined`.`rfn_midia__segmento_semanal`),
r_local AS (SELECT * FROM `vanguardamartech_refined`.`rfn_midia__localizacao_semanal`),
r_kw AS (SELECT * FROM `vanguardamartech_refined`.`rfn_midia__palavra_chave_semanal`),
r_grupo AS (SELECT * FROM `vanguardamartech_refined`.`rfn_midia__grupo_anuncio_semanal`),
r_video AS (SELECT * FROM `vanguardamartech_refined`.`rfn_midia__video_semanal`),
r_alcance AS (SELECT * FROM `vanguardamartech_refined`.`rfn_midia__alcance_semanal`),
r_conv AS (SELECT * FROM `vanguardamartech_refined`.`rfn_midia__conversao_categoria_prestex_mensal`),
geo AS (SELECT DISTINCT id_alvo_geo FROM `vanguardamartech_trusted`.`trs_google_ads__geo_alvo`),
ins AS (SELECT semana_inicio, SUM(investimento_micros) AS micros FROM `vanguardamartech_trusted`.`trs_google_ads__insight_semanal` GROUP BY semana_inicio),
u AS (
  SELECT CAST(NULL AS STRING) AS tabela, CAST(NULL AS STRING) AS id_registro, CAST(NULL AS STRING) AS chave, CAST(NULL AS DATE) AS d, CAST(NULL AS DATE) AS d2, CAST(NULL AS BOOL) AS fs, CAST(NULL AS BOOL) AS fi, CAST(NULL AS BOOL) AS fc, CAST(NULL AS BOOL) AS fk, CAST(NULL AS INT64) AS micros, CAST(NULL AS TIMESTAMP) AS ext FROM UNNEST([1]) WHERE FALSE
  UNION ALL
  SELECT 'trs_google_ads__termo_busca_semanal', id_registro, TO_JSON_STRING(STRUCT(id_campanha, id_grupo_anuncio, termo, tipo_correspondencia, semana_inicio)), semana_inicio, semana_fim, flag_semana_nao_comeca_na_segunda, flag_semana_incompleta_na_carga, (flag_conta_nao_catalogada OR cliente IS NULL OR moeda IS NULL), flag_campanha_nao_catalogada, investimento_micros, _extraido_at FROM t_termo
  UNION ALL
  SELECT 'trs_google_ads__segmento_localizacao_usuario_semanal', id_registro, TO_JSON_STRING(STRUCT(id_campanha, id_regiao, id_cidade, local_e_alvo, semana_inicio)), semana_inicio, semana_fim, flag_semana_nao_comeca_na_segunda, flag_semana_incompleta_na_carga, (flag_conta_nao_catalogada OR cliente IS NULL OR moeda IS NULL), flag_campanha_nao_catalogada, investimento_micros, _extraido_at FROM t_local
  UNION ALL
  SELECT 'trs_google_ads__segmento_faixa_etaria_semanal', id_registro, TO_JSON_STRING(STRUCT(id_campanha, id_grupo_anuncio, faixa_etaria, semana_inicio)), semana_inicio, semana_fim, flag_semana_nao_comeca_na_segunda, flag_semana_incompleta_na_carga, (flag_conta_nao_catalogada OR cliente IS NULL OR moeda IS NULL), flag_campanha_nao_catalogada, investimento_micros, _extraido_at FROM t_idade
  UNION ALL
  SELECT 'trs_google_ads__segmento_genero_semanal', id_registro, TO_JSON_STRING(STRUCT(id_campanha, id_grupo_anuncio, genero, semana_inicio)), semana_inicio, semana_fim, flag_semana_nao_comeca_na_segunda, flag_semana_incompleta_na_carga, (flag_conta_nao_catalogada OR cliente IS NULL OR moeda IS NULL), flag_campanha_nao_catalogada, investimento_micros, _extraido_at FROM t_genero
  UNION ALL
  SELECT 'trs_google_ads__segmento_geografico_semanal', id_registro, TO_JSON_STRING(STRUCT(id_campanha, id_pais, tipo_localizacao, semana_inicio)), semana_inicio, semana_fim, flag_semana_nao_comeca_na_segunda, flag_semana_incompleta_na_carga, (flag_conta_nao_catalogada OR cliente IS NULL OR moeda IS NULL), flag_campanha_nao_catalogada, investimento_micros, _extraido_at FROM t_geo
  UNION ALL
  SELECT 'trs_google_ads__palavra_chave_semanal', id_registro, TO_JSON_STRING(STRUCT(id_campanha, id_grupo_anuncio, id_criterio, semana_inicio)), semana_inicio, semana_fim, flag_semana_nao_comeca_na_segunda, flag_semana_incompleta_na_carga, (flag_conta_nao_catalogada OR cliente IS NULL OR moeda IS NULL), flag_campanha_nao_catalogada, investimento_micros, _extraido_at FROM t_kw
  UNION ALL
  SELECT 'trs_google_ads__grupo_anuncio_semanal', id_registro, TO_JSON_STRING(STRUCT(id_campanha, id_grupo_anuncio, semana_inicio)), semana_inicio, semana_fim, flag_semana_nao_comeca_na_segunda, flag_semana_incompleta_na_carga, (flag_conta_nao_catalogada OR cliente IS NULL OR moeda IS NULL), flag_campanha_nao_catalogada, investimento_micros, _extraido_at FROM t_grupo
  UNION ALL
  SELECT 'trs_google_ads__video_desempenho_semanal', id_registro, TO_JSON_STRING(STRUCT(id_campanha, id_grupo_anuncio, id_video, semana_inicio)), semana_inicio, semana_fim, flag_semana_nao_comeca_na_segunda, flag_semana_incompleta_na_carga, (flag_conta_nao_catalogada OR cliente IS NULL OR moeda IS NULL), flag_campanha_nao_catalogada, investimento_micros, _extraido_at FROM t_video
  UNION ALL
  SELECT 'trs_google_ads__alcance_frequencia_campanha_semanal', id_registro, TO_JSON_STRING(STRUCT(id_campanha, semana_inicio)), semana_inicio, semana_fim, flag_semana_nao_comeca_na_segunda, flag_semana_incompleta_na_carga, (flag_conta_nao_catalogada OR cliente IS NULL OR moeda IS NULL), flag_campanha_nao_catalogada, CAST(NULL AS INT64), _extraido_at FROM t_alcance
  UNION ALL
  SELECT 'trs_google_ads__conversao_acao_campanha_prestex', id_registro, TO_JSON_STRING(STRUCT(id_campanha, categoria_conversao, data)), data, CAST(NULL AS DATE), CAST(NULL AS BOOL), CAST(NULL AS BOOL), (flag_conta_nao_catalogada OR cliente IS NULL OR moeda IS NULL), flag_campanha_nao_catalogada, CAST(NULL AS INT64), _extraido_at FROM t_cc
  UNION ALL
  SELECT 'trs_google_ads__conversao_acao_anuncio_prestex', id_registro, TO_JSON_STRING(STRUCT(id_campanha, id_grupo_anuncio, id_anuncio, categoria_conversao, data)), data, CAST(NULL AS DATE), CAST(NULL AS BOOL), CAST(NULL AS BOOL), (flag_conta_nao_catalogada OR cliente IS NULL OR moeda IS NULL), flag_campanha_nao_catalogada, CAST(NULL AS INT64), _extraido_at FROM t_ca
),
raw AS (
  SELECT CAST(NULL AS STRING) AS tabela, CAST(NULL AS INT64) AS raw_n, CAST(NULL AS INT64) AS raw_micros FROM UNNEST([1]) WHERE FALSE
  UNION ALL
  SELECT 'trs_google_ads__termo_busca_semanal', COUNT(*), SUM(metrics_cost_micros) FROM `vanguardamartech_prestex`.`google_ads_prestex_search_term_performance`
  UNION ALL
  SELECT 'trs_google_ads__segmento_localizacao_usuario_semanal', COUNT(*), SUM(metrics_cost_micros) FROM `vanguardamartech_prestex`.`google_ads_prestex_user_location_performance`
  UNION ALL
  SELECT 'trs_google_ads__segmento_faixa_etaria_semanal', COUNT(*), SUM(metrics_cost_micros) FROM `vanguardamartech_prestex`.`google_ads_prestex_age_range_performance`
  UNION ALL
  SELECT 'trs_google_ads__segmento_genero_semanal', COUNT(*), SUM(metrics_cost_micros) FROM `vanguardamartech_prestex`.`google_ads_prestex_gender_performance`
  UNION ALL
  SELECT 'trs_google_ads__segmento_geografico_semanal', COUNT(*), SUM(metrics_cost_micros) FROM `vanguardamartech_prestex`.`google_ads_prestex_geographic_performance`
  UNION ALL
  SELECT 'trs_google_ads__palavra_chave_semanal', COUNT(*), SUM(metrics_cost_micros) FROM `vanguardamartech_prestex`.`google_ads_prestex_keyword_performance`
  UNION ALL
  SELECT 'trs_google_ads__grupo_anuncio_semanal', COUNT(*), SUM(metrics_cost_micros) FROM `vanguardamartech_prestex`.`google_ads_prestex_ad_group_performance`
  UNION ALL
  SELECT 'trs_google_ads__video_desempenho_semanal', COUNT(*), SUM(metrics_cost_micros) FROM `vanguardamartech_prestex`.`google_ads_prestex_video_performance`
  UNION ALL
  SELECT 'trs_google_ads__alcance_frequencia_campanha_semanal', COUNT(*), CAST(NULL AS INT64) FROM `vanguardamartech_prestex`.`google_ads_prestex_campaign_reach_frequency`
  UNION ALL
  SELECT 'trs_google_ads__conversao_acao_campanha_prestex', COUNT(*), CAST(NULL AS INT64) FROM `vanguardamartech_prestex`.`google_ads_prestex_campaign_conversion_actions`
  UNION ALL
  SELECT 'trs_google_ads__conversao_acao_anuncio_prestex', COUNT(*), CAST(NULL AS INT64) FROM `vanguardamartech_prestex`.`google_ads_prestex_ad_conversion_actions`
),
m_trs AS (
  SELECT u.tabela, COUNT(*) AS n,
    (COUNT(*) - COUNT(DISTINCT chave)) + (COUNT(*) - COUNT(DISTINCT id_registro)) AS falha_chave,
    IF(LOGICAL_OR(d2 IS NOT NULL), COUNTIF(EXTRACT(DAYOFWEEK FROM d) <> 2 OR fs OR d2 <> DATE_ADD(d, INTERVAL 6 DAY)), NULL) AS falha_seg,
    COUNTIF(fc) AS falha_conta, COUNTIF(fk) AS falha_campanha,
    IF(LOGICAL_OR(micros IS NOT NULL), COUNTIF(micros < 0), NULL) AS falha_neg,
    IF(LOGICAL_OR(d2 IS NOT NULL), COUNTIF(fi <> (d2 >= DATE(ext, 'America/Sao_Paulo'))), NULL) AS falha_incompleta,
    COUNTIF(d > CURRENT_DATE()) AS falha_futuro,
    MAX(DATE(ext, 'America/Sao_Paulo')) AS dt_carga,
    ANY_VALUE(raw.raw_n) AS raw_n, SUM(micros) AS micros, ANY_VALUE(raw.raw_micros) AS raw_micros
  FROM u JOIN raw USING (tabela)
  GROUP BY u.tabela
)
,
r AS (
  SELECT CAST(NULL AS STRING) AS id_regra, CAST(NULL AS STRING) AS camada, CAST(NULL AS STRING) AS tabela, CAST(NULL AS STRING) AS dimensao, CAST(NULL AS STRING) AS regra,
         CAST(NULL AS STRING) AS severidade, CAST(NULL AS FLOAT64) AS limiar, CAST(NULL AS INT64) AS linhas_avaliadas, CAST(NULL AS INT64) AS linhas_falha FROM UNNEST([1]) WHERE FALSE
  UNION ALL
  SELECT CONCAT(tabela, '.chave_natural_unica'), 'Trusted', tabela, 'UNICIDADE', 'a chave natural da origem e o id_registro sao unicos (zero repeticao)', 'BLOQUEANTE', 1.00, CAST(n AS INT64), CAST(falha_chave AS INT64) FROM m_trs
  UNION ALL
  SELECT CONCAT(tabela, '.semana_comeca_na_segunda'), 'Trusted', tabela, 'VALIDADE', 'toda semana_inicio e segunda-feira e semana_fim = inicio + 6 (a origem e semanal; DATE(date) sem fuso)', 'BLOQUEANTE', 1.00, CAST(n AS INT64), CAST(falha_seg AS INT64) FROM m_trs WHERE falha_seg IS NOT NULL
  UNION ALL
  SELECT CONCAT(tabela, '.conta_catalogada'), 'Trusted', tabela, 'INTEGRIDADE', 'conta resolve em trs_google_ads__conta (cliente e moeda preenchidos)', 'BLOQUEANTE', 1.00, CAST(n AS INT64), CAST(falha_conta AS INT64) FROM m_trs
  UNION ALL
  SELECT CONCAT(tabela, '.campanha_catalogada'), 'Trusted', tabela, 'INTEGRIDADE', 'campanha existe no cadastro de campanhas da Prestex', 'BLOQUEANTE', 1.00, CAST(n AS INT64), CAST(falha_campanha AS INT64) FROM m_trs
  UNION ALL
  SELECT CONCAT(tabela, '.investimento_nao_negativo'), 'Trusted', tabela, 'VALIDADE', 'investimento_micros nunca e negativo', 'BLOQUEANTE', 1.00, CAST(n AS INT64), CAST(falha_neg AS INT64) FROM m_trs WHERE falha_neg IS NOT NULL
  UNION ALL
  SELECT CONCAT(tabela, '.flag_incompleta_concorda_com_a_carga'), 'Trusted', tabela, 'VALIDADE', 'flag_semana_incompleta_na_carga = (semana_fim >= DATE(_extraido_at)); nunca contra CURRENT_DATE', 'ALERTA', 0.99, CAST(n AS INT64), CAST(falha_incompleta AS INT64) FROM m_trs WHERE falha_incompleta IS NOT NULL
  UNION ALL
  SELECT CONCAT(tabela, '.dado_nao_futuro'), 'Trusted', tabela, 'VALIDADE', 'a data do dado nunca passa de hoje (regra sobre o DADO, segura contra o relogio)', 'BLOQUEANTE', 1.00, CAST(n AS INT64), CAST(falha_futuro AS INT64) FROM m_trs
  UNION ALL
  SELECT CONCAT(tabela, '.reproduz_a_origem'), 'Trusted', tabela, 'INTEGRIDADE', 'linhas e investimento_micros da Trusted = tabela de origem da Prestex (grao 1 linha)', 'BLOQUEANTE', 1.00, CAST(1 AS INT64), CAST(IF(n = raw_n AND COALESCE(micros, 0) = COALESCE(raw_micros, 0), 0, 1) AS INT64) FROM m_trs
  UNION ALL
  SELECT 'prestex_breakdowns.carga_do_mesmo_dia', 'Trusted', 'trs_google_ads__*_semanal e *_prestex', 'FRESCOR', 'as 11 Trusted foram escritas na mesma passada (mesma data de carga)', 'ALERTA', 1.00, 1, IF((SELECT COUNT(DISTINCT dt_carga) FROM m_trs) = 1, 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'trs_google_ads__termo_busca_semanal.termo_preenchido', 'Trusted', 'trs_google_ads__termo_busca_semanal', 'VALIDADE', 'o termo de busca nunca e vazio', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(termo IS NULL OR TRIM(termo) = '') AS INT64) FROM t_termo
  UNION ALL
  SELECT 'trs_google_ads__termo_busca_semanal.clique_nao_excede_impressao', 'Trusted', 'trs_google_ads__termo_busca_semanal', 'VALIDADE', 'cliques nao excedem impressoes na linha (o Google atribui as duas por regras diferentes: linha de base)', 'ALERTA', 0.995, CAST(COUNT(*) AS INT64), CAST(COUNTIF(cliques > impressoes) AS INT64) FROM t_termo
  UNION ALL
  SELECT 'trs_google_ads__segmento_localizacao_usuario_semanal.clique_nao_excede_impressao', 'Trusted', 'trs_google_ads__segmento_localizacao_usuario_semanal', 'VALIDADE', 'cliques nao excedem impressoes na linha (linha de base)', 'ALERTA', 0.995, CAST(COUNT(*) AS INT64), CAST(COUNTIF(cliques > impressoes) AS INT64) FROM t_local
  UNION ALL
  SELECT 'trs_google_ads__palavra_chave_semanal.clique_nao_excede_impressao', 'Trusted', 'trs_google_ads__palavra_chave_semanal', 'VALIDADE', 'cliques nao excedem impressoes na linha (linha de base)', 'ALERTA', 0.995, CAST(COUNT(*) AS INT64), CAST(COUNTIF(cliques > impressoes) AS INT64) FROM t_kw
  UNION ALL
  SELECT 'trs_google_ads__grupo_anuncio_semanal.clique_nao_excede_impressao', 'Trusted', 'trs_google_ads__grupo_anuncio_semanal', 'VALIDADE', 'cliques nao excedem impressoes na linha (linha de base)', 'ALERTA', 0.995, CAST(COUNT(*) AS INT64), CAST(COUNTIF(cliques > impressoes) AS INT64) FROM t_grupo
  UNION ALL
  SELECT 'trs_google_ads__video_desempenho_semanal.visualizacao_nao_excede_impressao', 'Trusted', 'trs_google_ads__video_desempenho_semanal', 'VALIDADE', 'visualizacoes de video nao excedem impressoes (linha de base)', 'ALERTA', 0.99, CAST(COUNT(*) AS INT64), CAST(COUNTIF(visualizacoes_video > impressoes) AS INT64) FROM t_video
  UNION ALL
  SELECT 'trs_google_ads__segmento_localizacao_usuario_semanal.regiao_e_cidade_na_geo_alvo', 'Trusted', 'trs_google_ads__segmento_localizacao_usuario_semanal', 'INTEGRIDADE', 'id_regiao e id_cidade resolvem em trs_google_ads__geo_alvo (dimensao de copia viva: linha de base)', 'ALERTA', 0.995, CAST(COUNT(*) AS INT64), CAST(COUNTIF(gr.id_alvo_geo IS NULL OR gc.id_alvo_geo IS NULL) AS INT64) FROM t_local l LEFT JOIN geo gr ON gr.id_alvo_geo = l.id_regiao LEFT JOIN geo gc ON gc.id_alvo_geo = l.id_cidade
  UNION ALL
  SELECT 'trs_google_ads__segmento_geografico_semanal.pais_na_geo_alvo', 'Trusted', 'trs_google_ads__segmento_geografico_semanal', 'INTEGRIDADE', 'id_pais resolve em trs_google_ads__geo_alvo (linha de base)', 'ALERTA', 0.995, CAST(COUNT(*) AS INT64), CAST(COUNTIF(gp.id_alvo_geo IS NULL) AS INT64) FROM t_geo g LEFT JOIN geo gp ON gp.id_alvo_geo = g.id_pais
  UNION ALL
  SELECT 'trs_google_ads__palavra_chave_semanal.nivel_qualidade_entre_1_e_10', 'Trusted', 'trs_google_ads__palavra_chave_semanal', 'VALIDADE', 'nivel_qualidade, quando presente, esta entre 1 e 10 (NULL e ausencia de nota)', 'BLOQUEANTE', 1.00, CAST(COUNTIF(nivel_qualidade IS NOT NULL) AS INT64), CAST(COUNTIF(nivel_qualidade IS NOT NULL AND (nivel_qualidade < 1 OR nivel_qualidade > 10)) AS INT64) FROM t_kw
  UNION ALL
  SELECT 'trs_google_ads__alcance_frequencia_campanha_semanal.alcance_presente_quando_ha_impressao', 'Trusted', 'trs_google_ads__alcance_frequencia_campanha_semanal', 'COMPLETUDE', 'linha com impressao traz usuarios unicos (o Google as vezes nao reporta alcance: linha de base)', 'ALERTA', 0.95, CAST(COUNTIF(impressoes > 0) AS INT64), CAST(COUNTIF(impressoes > 0 AND usuarios_unicos_na_semana IS NULL) AS INT64) FROM t_alcance
  UNION ALL
  SELECT 'trs_google_ads__alcance_frequencia_campanha_semanal.usuarios_nao_excedem_impressoes', 'Trusted', 'trs_google_ads__alcance_frequencia_campanha_semanal', 'VALIDADE', 'usuarios unicos nao excedem impressoes (linha de base)', 'ALERTA', 0.99, CAST(COUNTIF(usuarios_unicos_na_semana IS NOT NULL) AS INT64), CAST(COUNTIF(usuarios_unicos_na_semana > impressoes) AS INT64) FROM t_alcance
  UNION ALL
  SELECT 'trs_google_ads__conversao_acao_campanha_prestex.categoria_preenchida', 'Trusted', 'trs_google_ads__conversao_acao_campanha_prestex', 'COMPLETUDE', 'categoria_conversao nunca e vazia', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(categoria_conversao IS NULL) AS INT64) FROM t_cc
  UNION ALL
  SELECT 'trs_google_ads__conversao_acao_anuncio_prestex.categoria_preenchida', 'Trusted', 'trs_google_ads__conversao_acao_anuncio_prestex', 'COMPLETUDE', 'categoria_conversao nunca e vazia', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(categoria_conversao IS NULL) AS INT64) FROM t_ca
  UNION ALL
  SELECT 'trs_google_ads__termo_busca_semanal.nunca_excede_o_total_da_semana', 'Trusted', 'trs_google_ads__termo_busca_semanal', 'INTEGRIDADE', 'por semana o breakdown nunca passa do total de insight_semanal (se passar, o grao duplicou)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(i.micros IS NULL OR b.micros > i.micros) AS INT64) FROM (SELECT semana_inicio, SUM(investimento_micros) AS micros FROM t_termo GROUP BY semana_inicio) b LEFT JOIN ins i USING (semana_inicio)
  UNION ALL
  SELECT 'trs_google_ads__segmento_localizacao_usuario_semanal.nunca_excede_o_total_da_semana', 'Trusted', 'trs_google_ads__segmento_localizacao_usuario_semanal', 'INTEGRIDADE', 'por semana o breakdown nunca passa do total de insight_semanal (se passar, o grao duplicou)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(i.micros IS NULL OR b.micros > i.micros) AS INT64) FROM (SELECT semana_inicio, SUM(investimento_micros) AS micros FROM t_local GROUP BY semana_inicio) b LEFT JOIN ins i USING (semana_inicio)
  UNION ALL
  SELECT 'trs_google_ads__segmento_faixa_etaria_semanal.nunca_excede_o_total_da_semana', 'Trusted', 'trs_google_ads__segmento_faixa_etaria_semanal', 'INTEGRIDADE', 'por semana o breakdown nunca passa do total de insight_semanal (se passar, o grao duplicou)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(i.micros IS NULL OR b.micros > i.micros) AS INT64) FROM (SELECT semana_inicio, SUM(investimento_micros) AS micros FROM t_idade GROUP BY semana_inicio) b LEFT JOIN ins i USING (semana_inicio)
  UNION ALL
  SELECT 'trs_google_ads__segmento_genero_semanal.nunca_excede_o_total_da_semana', 'Trusted', 'trs_google_ads__segmento_genero_semanal', 'INTEGRIDADE', 'por semana o breakdown nunca passa do total de insight_semanal (se passar, o grao duplicou)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(i.micros IS NULL OR b.micros > i.micros) AS INT64) FROM (SELECT semana_inicio, SUM(investimento_micros) AS micros FROM t_genero GROUP BY semana_inicio) b LEFT JOIN ins i USING (semana_inicio)
  UNION ALL
  SELECT 'trs_google_ads__palavra_chave_semanal.nunca_excede_o_total_da_semana', 'Trusted', 'trs_google_ads__palavra_chave_semanal', 'INTEGRIDADE', 'por semana o breakdown nunca passa do total de insight_semanal (se passar, o grao duplicou)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(i.micros IS NULL OR b.micros > i.micros) AS INT64) FROM (SELECT semana_inicio, SUM(investimento_micros) AS micros FROM t_kw GROUP BY semana_inicio) b LEFT JOIN ins i USING (semana_inicio)
  UNION ALL
  SELECT 'trs_google_ads__grupo_anuncio_semanal.nunca_excede_o_total_da_semana', 'Trusted', 'trs_google_ads__grupo_anuncio_semanal', 'INTEGRIDADE', 'por semana o breakdown nunca passa do total de insight_semanal (se passar, o grao duplicou)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(i.micros IS NULL OR b.micros > i.micros) AS INT64) FROM (SELECT semana_inicio, SUM(investimento_micros) AS micros FROM t_grupo GROUP BY semana_inicio) b LEFT JOIN ins i USING (semana_inicio)
  UNION ALL
  SELECT 'trs_google_ads__video_desempenho_semanal.nunca_excede_o_total_da_semana', 'Trusted', 'trs_google_ads__video_desempenho_semanal', 'INTEGRIDADE', 'por semana o breakdown nunca passa do total de insight_semanal (se passar, o grao duplicou)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(i.micros IS NULL OR b.micros > i.micros) AS INT64) FROM (SELECT semana_inicio, SUM(investimento_micros) AS micros FROM t_video GROUP BY semana_inicio) b LEFT JOIN ins i USING (semana_inicio)
  UNION ALL
  SELECT 'trs_google_ads__segmento_geografico_semanal.reconcilia_com_o_total_da_semana', 'Trusted', 'trs_google_ads__segmento_geografico_semanal', 'INTEGRIDADE', 'por semana o geografico reconcilia com o total de insight_semanal (unico breakdown que fecha a verba)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(i.micros IS NULL OR b.micros <> i.micros) AS INT64) FROM (SELECT semana_inicio, SUM(investimento_micros) AS micros FROM t_geo GROUP BY semana_inicio) b LEFT JOIN ins i USING (semana_inicio)
  UNION ALL
  SELECT 'trs_google_ads__segmento_faixa_etaria_semanal.mesmo_gasto_do_genero', 'Trusted', 'trs_google_ads__segmento_faixa_etaria_semanal', 'INTEGRIDADE', 'por semana faixa etaria e genero cobrem o mesmo gasto (dois recortes do mesmo dinheiro)', 'ALERTA', 0.99, CAST(COUNT(*) AS INT64), CAST(COUNTIF(g.micros IS NULL OR ABS(a.micros - g.micros) > 1000) AS INT64) FROM (SELECT semana_inicio, SUM(investimento_micros) AS micros FROM t_idade GROUP BY semana_inicio) a LEFT JOIN (SELECT semana_inicio, SUM(investimento_micros) AS micros FROM t_genero GROUP BY semana_inicio) g USING (semana_inicio)
  UNION ALL
  SELECT 'rfn_midia__termo_busca_semanal.id_termo_semanal_unico', 'Refined', 'rfn_midia__termo_busca_semanal', 'UNICIDADE', 'id_termo_semanal e unico e nunca nulo', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_termo_semanal) + COUNTIF(id_termo_semanal IS NULL) AS INT64) FROM r_termo
  UNION ALL
  SELECT 'rfn_midia__segmento_semanal.id_segmento_semanal_unico', 'Refined', 'rfn_midia__segmento_semanal', 'UNICIDADE', 'id_segmento_semanal e unico e nunca nulo', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_segmento_semanal) + COUNTIF(id_segmento_semanal IS NULL) AS INT64) FROM r_seg
  UNION ALL
  SELECT 'rfn_midia__localizacao_semanal.id_localizacao_semanal_unico', 'Refined', 'rfn_midia__localizacao_semanal', 'UNICIDADE', 'id_localizacao_semanal e unico e nunca nulo', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_localizacao_semanal) + COUNTIF(id_localizacao_semanal IS NULL) AS INT64) FROM r_local
  UNION ALL
  SELECT 'rfn_midia__palavra_chave_semanal.id_palavra_semanal_unico', 'Refined', 'rfn_midia__palavra_chave_semanal', 'UNICIDADE', 'id_palavra_semanal e unico e nunca nulo', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_palavra_semanal) + COUNTIF(id_palavra_semanal IS NULL) AS INT64) FROM r_kw
  UNION ALL
  SELECT 'rfn_midia__grupo_anuncio_semanal.id_grupo_semanal_unico', 'Refined', 'rfn_midia__grupo_anuncio_semanal', 'UNICIDADE', 'id_grupo_semanal e unico e nunca nulo', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_grupo_semanal) + COUNTIF(id_grupo_semanal IS NULL) AS INT64) FROM r_grupo
  UNION ALL
  SELECT 'rfn_midia__video_semanal.id_video_semanal_unico', 'Refined', 'rfn_midia__video_semanal', 'UNICIDADE', 'id_video_semanal e unico e nunca nulo', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_video_semanal) + COUNTIF(id_video_semanal IS NULL) AS INT64) FROM r_video
  UNION ALL
  SELECT 'rfn_midia__alcance_semanal.id_alcance_semanal_unico', 'Refined', 'rfn_midia__alcance_semanal', 'UNICIDADE', 'id_alcance_semanal e unico e nunca nulo', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_alcance_semanal) + COUNTIF(id_alcance_semanal IS NULL) AS INT64) FROM r_alcance
  UNION ALL
  SELECT 'rfn_midia__conversao_categoria_prestex_mensal.id_conversao_mensal_unico', 'Refined', 'rfn_midia__conversao_categoria_prestex_mensal', 'UNICIDADE', 'id_conversao_mensal e unico e nunca nulo', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNT(*) - COUNT(DISTINCT id_conversao_mensal) + COUNTIF(id_conversao_mensal IS NULL) AS INT64) FROM r_conv
  UNION ALL
  SELECT 'rfn_midia__termo_busca_semanal.reproduz_a_trusted', 'Refined', 'rfn_midia__termo_busca_semanal', 'INTEGRIDADE', 'linhas = (conta, termo, semana) distintos da Trusted e investimento_micros igual (a Refined agrega e nao filtra)', 'BLOQUEANTE', 1.00, 1, IF((SELECT COUNT(*) FROM r_termo) = (SELECT COUNT(*) FROM (SELECT DISTINCT id_conta, termo, semana_inicio FROM t_termo)) AND ((SELECT SUM(investimento_micros) FROM r_termo) = (SELECT SUM(investimento_micros) FROM t_termo)), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_midia__segmento_semanal.reproduz_a_trusted', 'Refined', 'rfn_midia__segmento_semanal', 'INTEGRIDADE', 'linhas = chaves distintas das tres Trusted e o investimento_micros fecha DENTRO de cada tipo (faixa etaria, genero, pais), nunca entre tipos', 'BLOQUEANTE', 1.00, 1, IF((SELECT COUNT(*) FROM r_seg) = ((SELECT COUNT(*) FROM (SELECT DISTINCT id_conta, faixa_etaria, semana_inicio FROM t_idade)) + (SELECT COUNT(*) FROM (SELECT DISTINCT id_conta, genero, semana_inicio FROM t_genero)) + (SELECT COUNT(*) FROM (SELECT DISTINCT id_conta, tipo_localizacao, id_pais, semana_inicio FROM t_geo))) AND ((SELECT SUM(IF(tipo_segmento = 'FAIXA_ETARIA', investimento_micros, 0)) FROM r_seg) = (SELECT SUM(investimento_micros) FROM t_idade) AND (SELECT SUM(IF(tipo_segmento = 'GENERO', investimento_micros, 0)) FROM r_seg) = (SELECT SUM(investimento_micros) FROM t_genero) AND (SELECT SUM(IF(STARTS_WITH(tipo_segmento, 'PAIS_'), investimento_micros, 0)) FROM r_seg) = (SELECT SUM(investimento_micros) FROM t_geo)), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_midia__localizacao_semanal.reproduz_a_trusted', 'Refined', 'rfn_midia__localizacao_semanal', 'INTEGRIDADE', 'linhas = (conta, pais, regiao, cidade, semana) distintos da Trusted e investimento_micros igual', 'BLOQUEANTE', 1.00, 1, IF((SELECT COUNT(*) FROM r_local) = (SELECT COUNT(*) FROM (SELECT DISTINCT id_conta, id_pais, id_regiao, id_cidade, semana_inicio FROM t_local)) AND ((SELECT SUM(investimento_micros) FROM r_local) = (SELECT SUM(investimento_micros) FROM t_local)), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_midia__palavra_chave_semanal.reproduz_a_trusted', 'Refined', 'rfn_midia__palavra_chave_semanal', 'INTEGRIDADE', 'mesmo grao da Trusted: linhas e investimento_micros iguais', 'BLOQUEANTE', 1.00, 1, IF((SELECT COUNT(*) FROM r_kw) = (SELECT COUNT(*) FROM t_kw) AND ((SELECT SUM(investimento_micros) FROM r_kw) = (SELECT SUM(investimento_micros) FROM t_kw)), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_midia__grupo_anuncio_semanal.reproduz_a_trusted', 'Refined', 'rfn_midia__grupo_anuncio_semanal', 'INTEGRIDADE', 'mesmo grao da Trusted: linhas e investimento_micros iguais', 'BLOQUEANTE', 1.00, 1, IF((SELECT COUNT(*) FROM r_grupo) = (SELECT COUNT(*) FROM t_grupo) AND ((SELECT SUM(investimento_micros) FROM r_grupo) = (SELECT SUM(investimento_micros) FROM t_grupo)), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_midia__video_semanal.reproduz_a_trusted', 'Refined', 'rfn_midia__video_semanal', 'INTEGRIDADE', 'linhas = (conta, campanha, video, semana) distintos da Trusted e investimento_micros igual', 'BLOQUEANTE', 1.00, 1, IF((SELECT COUNT(*) FROM r_video) = (SELECT COUNT(*) FROM (SELECT DISTINCT id_conta, id_campanha, id_video, semana_inicio FROM t_video)) AND ((SELECT SUM(investimento_micros) FROM r_video) = (SELECT SUM(investimento_micros) FROM t_video)), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_midia__alcance_semanal.reproduz_a_trusted', 'Refined', 'rfn_midia__alcance_semanal', 'INTEGRIDADE', 'mesmo grao da Trusted: linhas e impressoes iguais', 'BLOQUEANTE', 1.00, 1, IF((SELECT COUNT(*) FROM r_alcance) = (SELECT COUNT(*) FROM t_alcance) AND ((SELECT SUM(impressoes) FROM r_alcance) = (SELECT SUM(impressoes) FROM t_alcance)), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_midia__conversao_categoria_prestex_mensal.reproduz_a_trusted', 'Refined', 'rfn_midia__conversao_categoria_prestex_mensal', 'INTEGRIDADE', 'linhas = chaves (conta, campanha, mes, categoria) distintas das duas Trusted e as conversoes dos dois graos fecham, cada uma com a sua (os graos nao somam o mesmo)', 'BLOQUEANTE', 1.00, 1, IF((SELECT COUNT(*) FROM r_conv) = (SELECT COUNT(*) FROM (SELECT DISTINCT id_conta, id_campanha, mes_referencia, categoria_conversao FROM (SELECT id_conta, id_campanha, mes_referencia, categoria_conversao FROM t_cc UNION ALL SELECT id_conta, id_campanha, mes_referencia, categoria_conversao FROM t_ca))) AND (ROUND((SELECT SUM(conversoes_campanha) FROM r_conv) * 10000) = ROUND((SELECT SUM(conversoes) FROM t_cc) * 10000) AND ROUND((SELECT SUM(conversoes_anuncio) FROM r_conv) * 10000) = ROUND((SELECT SUM(conversoes) FROM t_ca) * 10000)), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_midia__termo_busca_semanal.custo_por_conversao_so_com_conversao', 'Refined', 'rfn_midia__termo_busca_semanal', 'VALIDADE', 'custo_por_conversao e NULL exatamente quando conversoes = 0 (nunca zero por falta de denominador)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF((IFNULL(conversoes, 0) = 0) <> (custo_por_conversao IS NULL)) AS INT64) FROM r_termo
  UNION ALL
  SELECT 'rfn_midia__segmento_semanal.custo_por_conversao_so_com_conversao', 'Refined', 'rfn_midia__segmento_semanal', 'VALIDADE', 'custo_por_conversao e NULL exatamente quando conversoes = 0 (nunca zero por falta de denominador)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF((IFNULL(conversoes, 0) = 0) <> (custo_por_conversao IS NULL)) AS INT64) FROM r_seg
  UNION ALL
  SELECT 'rfn_midia__localizacao_semanal.custo_por_conversao_so_com_conversao', 'Refined', 'rfn_midia__localizacao_semanal', 'VALIDADE', 'custo_por_conversao e NULL exatamente quando conversoes = 0 (nunca zero por falta de denominador)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF((IFNULL(conversoes, 0) = 0) <> (custo_por_conversao IS NULL)) AS INT64) FROM r_local
  UNION ALL
  SELECT 'rfn_midia__palavra_chave_semanal.custo_por_conversao_so_com_conversao', 'Refined', 'rfn_midia__palavra_chave_semanal', 'VALIDADE', 'custo_por_conversao e NULL exatamente quando conversoes = 0 (nunca zero por falta de denominador)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF((IFNULL(conversoes, 0) = 0) <> (custo_por_conversao IS NULL)) AS INT64) FROM r_kw
  UNION ALL
  SELECT 'rfn_midia__grupo_anuncio_semanal.custo_por_conversao_so_com_conversao', 'Refined', 'rfn_midia__grupo_anuncio_semanal', 'VALIDADE', 'custo_por_conversao e NULL exatamente quando conversoes = 0 (nunca zero por falta de denominador)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF((IFNULL(conversoes, 0) = 0) <> (custo_por_conversao IS NULL)) AS INT64) FROM r_grupo
  UNION ALL
  SELECT 'rfn_midia__segmento_semanal.participacao_soma_um_por_tipo', 'Refined', 'rfn_midia__segmento_semanal', 'INTEGRIDADE', 'dentro de (conta, tipo, semana) a participacao_investimento soma 1,0 (tolerancia 0,001); entre tipos nao', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(ABS(s - 1) > 0.001) AS INT64) FROM (SELECT id_conta, tipo_segmento, semana_inicio, SUM(participacao_investimento) AS s FROM r_seg GROUP BY 1, 2, 3 HAVING SUM(investimento_micros) > 0)
  UNION ALL
  SELECT 'rfn_midia__localizacao_semanal.participacao_soma_um_na_conta_semana', 'Refined', 'rfn_midia__localizacao_semanal', 'INTEGRIDADE', 'dentro de (conta, semana) a participacao_investimento_na_conta_semana soma 1,0 (tolerancia 0,001)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(ABS(s - 1) > 0.001) AS INT64) FROM (SELECT id_conta, semana_inicio, SUM(participacao_investimento_na_conta_semana) AS s FROM r_local GROUP BY 1, 2 HAVING SUM(investimento_micros) > 0)
  UNION ALL
  SELECT 'rfn_midia__segmento_semanal.rotulo_preenchido', 'Refined', 'rfn_midia__segmento_semanal', 'COMPLETUDE', 'rotulo_segmento nunca e nulo (faixa, genero e pais resolvem)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(rotulo_segmento IS NULL) AS INT64) FROM r_seg
  UNION ALL
  SELECT 'rfn_midia__termo_busca_semanal.campanha_principal_preenchida', 'Refined', 'rfn_midia__termo_busca_semanal', 'COMPLETUDE', 'toda linha tem campanha principal', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(id_campanha_principal IS NULL) AS INT64) FROM r_termo
  UNION ALL
  SELECT 'rfn_midia__localizacao_semanal.alvo_mais_fora_e_o_total', 'Refined', 'rfn_midia__localizacao_semanal', 'INTEGRIDADE', 'investimento_em_local_alvo + investimento_fora_do_alvo = investimento (local_e_alvo particiona; tolerancia de 1 centavo por arredondamento por linha)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(ABS(investimento_em_local_alvo + investimento_fora_do_alvo - investimento) > 0.011) AS INT64) FROM r_local
  UNION ALL
  SELECT 'rfn_midia__alcance_semanal.frequencia_so_com_alcance', 'Refined', 'rfn_midia__alcance_semanal', 'VALIDADE', 'frequencia_calculada e NULL exatamente quando nao ha usuarios unicos (nunca zero)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF((IFNULL(usuarios_unicos_na_semana, 0) = 0) <> (frequencia_calculada IS NULL)) AS INT64) FROM r_alcance
  UNION ALL
  SELECT 'rfn_midia__video_semanal.quartil_entre_zero_e_um', 'Refined', 'rfn_midia__video_semanal', 'VALIDADE', 'taxas de quartil, quando presentes, ficam entre 0 e 1', 'ALERTA', 0.99, CAST(COUNT(*) AS INT64), CAST(COUNTIF(taxa_quartil_25 < 0 OR taxa_quartil_25 > 1 OR taxa_quartil_50 < 0 OR taxa_quartil_50 > 1 OR taxa_quartil_75 < 0 OR taxa_quartil_75 > 1 OR taxa_quartil_100 < 0 OR taxa_quartil_100 > 1) AS INT64) FROM r_video
  UNION ALL
  SELECT 'rfn_midia__conversao_categoria_prestex_mensal.classe_indefinida_baixa', 'Refined', 'rfn_midia__conversao_categoria_prestex_mensal', 'VALIDADE', 'poucas linhas caem em INDEFINIDA (categoria fora do mapa; medido 4 de 498 chaves fora do mapa: UNKNOWN/DEFAULT da origem; linha de base)', 'ALERTA', 0.95, CAST(COUNT(*) AS INT64), CAST(COUNTIF(classe_conversao = 'INDEFINIDA') AS INT64) FROM r_conv
  UNION ALL
  SELECT 'rfn_midia__conversao_categoria_prestex_mensal.graos_divergem_marcado', 'Refined', 'rfn_midia__conversao_categoria_prestex_mensal', 'INTEGRIDADE', 'flag_graos_divergem concorda com a comparacao dos dois graos (os graos nao somam o mesmo: marca, nao corrige)', 'BLOQUEANTE', 1.00, CAST(COUNT(*) AS INT64), CAST(COUNTIF(flag_graos_divergem <> (ABS(IFNULL(conversoes_campanha, 0) - IFNULL(conversoes_anuncio, 0)) > 0.01 OR ABS(IFNULL(todas_conversoes_campanha, 0) - IFNULL(todas_conversoes_anuncio, 0)) > 0.01)) AS INT64) FROM r_conv
),
avaliado AS (
  SELECT r.*, 'GOOGLE_ADS' AS sistema, (r.linhas_avaliadas - r.linhas_falha) AS linhas_conformes,
    SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, NULLIF(r.linhas_avaliadas, 0)) AS taxa_conformidade,
    IF(r.linhas_avaliadas = 0, NULL, SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, r.linhas_avaliadas) >= r.limiar) AS is_conforme,
    (r.linhas_avaliadas = 0) AS flag_sem_linha_para_avaliar
  FROM r
)
SELECT a.*,
  CASE WHEN a.flag_sem_linha_para_avaliar THEN 'SEM_DADO' WHEN a.is_conforme THEN 'CONFORME'
       WHEN a.severidade = 'BLOQUEANTE' THEN 'FALHA_BLOQUEANTE' ELSE 'FALHA_ALERTA' END AS resultado,
  'PRESTEX_BREAKDOWNS' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'google-ads-OzfZ' AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a
