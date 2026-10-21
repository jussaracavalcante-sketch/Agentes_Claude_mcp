-- rfn_qualidade__regra_google_ads_streams (query-hAuo) · 31 regras · L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA em uma execucao. Gatilho: evento nos 14 Trusted de Google Ads de 06/10 com regra "all" (query-nA2i, ZYGu, FJGq, Q8IQ, VDql, mqgF, Gt0y, vsvg, LlFz, UAJ7, SeEg, YJaZ, 8oUR, DEyX). Alerta ligado. Cadencia SEMANAL (terca, google-ads-cwt3).
-- Medido em 06/10/2026 sobre as tabelas materializadas: 31 regras, 31 ids distintos, zero falhas bloqueantes.
-- Linhas de base (ALERTA): clique > impressao em palavra-chave (0,24%) e grupo (0,11%); usuario unico > impressao no alcance (0,24%).
WITH total_campanha_dia AS (
  SELECT CAST(id_campanha AS STRING) AS id_campanha, data, SUM(investimento_micros) AS micros
  FROM `vanguardamartech_trusted`.`trs_google_ads__insight_diario`
  GROUP BY 1, 2
),
cargas AS (
  SELECT 'palavra_chave' AS tab, MAX(DATE(_extraido_at)) AS d FROM `vanguardamartech_trusted`.`trs_google_ads__palavra_chave` UNION ALL
  SELECT 'palavra_chave_cadastro', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_google_ads__palavra_chave_cadastro` UNION ALL
  SELECT 'grupo_anuncio_diario', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio_diario` UNION ALL
  SELECT 'grupo_anuncio', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio` UNION ALL
  SELECT 'conversao_acao_campanha', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_campanha` UNION ALL
  SELECT 'conversao_acao_grupo', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_grupo` UNION ALL
  SELECT 'conversao_acao_anuncio', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_anuncio` UNION ALL
  SELECT 'acao_conversao', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_google_ads__acao_conversao` UNION ALL
  SELECT 'anuncio', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_google_ads__anuncio` UNION ALL
  SELECT 'alcance_frequencia_campanha', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_google_ads__alcance_frequencia_campanha` UNION ALL
  SELECT 'ativo', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_google_ads__ativo` UNION ALL
  SELECT 'video', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_google_ads__video` UNION ALL
  SELECT 'orcamento_conta', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_google_ads__orcamento_conta` UNION ALL
  SELECT 'video_desempenho_diario', MAX(DATE(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_google_ads__video_desempenho_diario`
),
r AS (
  SELECT 'trs_google_ads__palavra_chave.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_google_ads__palavra_chave' AS tabela, 'Google Ads' AS sistema, 'UNICIDADE' AS dimensao,
         'chave (id_conta, id_campanha, id_grupo_anuncio, id_criterio, data) e unica e nunca nula' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_campanha AS STRING), '|', CAST(id_grupo_anuncio AS STRING), '|', CAST(id_criterio AS STRING), '|', CAST(data AS STRING))) + COUNTIF(id_campanha IS NULL) AS linhas_falha FROM `vanguardamartech_trusted`.`trs_google_ads__palavra_chave`
  UNION ALL SELECT 'trs_google_ads__palavra_chave_cadastro.chave_unica', 'Trusted', 'trs_google_ads__palavra_chave_cadastro', 'Google Ads', 'UNICIDADE',
         'chave (id_conta, id_campanha, id_grupo_anuncio, id_criterio) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_campanha AS STRING), '|', CAST(id_grupo_anuncio AS STRING), '|', CAST(id_criterio AS STRING))) + COUNTIF(id_campanha IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__palavra_chave_cadastro`
  UNION ALL SELECT 'trs_google_ads__grupo_anuncio_diario.chave_unica', 'Trusted', 'trs_google_ads__grupo_anuncio_diario', 'Google Ads', 'UNICIDADE',
         'chave (id_conta, id_campanha, id_grupo_anuncio, data) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_campanha AS STRING), '|', CAST(id_grupo_anuncio AS STRING), '|', CAST(data AS STRING))) + COUNTIF(id_campanha IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio_diario`
  UNION ALL SELECT 'trs_google_ads__grupo_anuncio.chave_unica', 'Trusted', 'trs_google_ads__grupo_anuncio', 'Google Ads', 'UNICIDADE',
         'chave (id_conta, id_grupo_anuncio) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_grupo_anuncio AS STRING))) + COUNTIF(id_grupo_anuncio IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio`
  UNION ALL SELECT 'trs_google_ads__conversao_acao_campanha.chave_unica', 'Trusted', 'trs_google_ads__conversao_acao_campanha', 'Google Ads', 'UNICIDADE',
         'chave (id_conta, id_campanha, categoria_conversao, data) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_campanha AS STRING), '|', CAST(categoria_conversao AS STRING), '|', CAST(data AS STRING))) + COUNTIF(id_campanha IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_campanha`
  UNION ALL SELECT 'trs_google_ads__conversao_acao_grupo.chave_unica', 'Trusted', 'trs_google_ads__conversao_acao_grupo', 'Google Ads', 'UNICIDADE',
         'chave (id_conta, id_campanha, id_grupo_anuncio, categoria_conversao, data) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_campanha AS STRING), '|', CAST(id_grupo_anuncio AS STRING), '|', CAST(categoria_conversao AS STRING), '|', CAST(data AS STRING))) + COUNTIF(id_campanha IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_grupo`
  UNION ALL SELECT 'trs_google_ads__conversao_acao_anuncio.chave_unica', 'Trusted', 'trs_google_ads__conversao_acao_anuncio', 'Google Ads', 'UNICIDADE',
         'chave (id_conta, id_campanha, id_grupo_anuncio, id_anuncio, categoria_conversao, data) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_campanha AS STRING), '|', CAST(id_grupo_anuncio AS STRING), '|', CAST(id_anuncio AS STRING), '|', CAST(categoria_conversao AS STRING), '|', CAST(data AS STRING))) + COUNTIF(id_campanha IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__conversao_acao_anuncio`
  UNION ALL SELECT 'trs_google_ads__acao_conversao.chave_unica', 'Trusted', 'trs_google_ads__acao_conversao', 'Google Ads', 'UNICIDADE',
         'chave (id_conta, id_acao) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_acao AS STRING))) + COUNTIF(id_acao IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__acao_conversao`
  UNION ALL SELECT 'trs_google_ads__anuncio.chave_unica', 'Trusted', 'trs_google_ads__anuncio', 'Google Ads', 'UNICIDADE',
         'chave (id_conta, id_anuncio) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_anuncio AS STRING))) + COUNTIF(id_anuncio IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__anuncio`
  UNION ALL SELECT 'trs_google_ads__alcance_frequencia_campanha.chave_unica', 'Trusted', 'trs_google_ads__alcance_frequencia_campanha', 'Google Ads', 'UNICIDADE',
         'chave (id_conta, id_campanha, data) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_campanha AS STRING), '|', CAST(data AS STRING))) + COUNTIF(id_campanha IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__alcance_frequencia_campanha`
  UNION ALL SELECT 'trs_google_ads__ativo.chave_unica', 'Trusted', 'trs_google_ads__ativo', 'Google Ads', 'UNICIDADE',
         'chave (id_conta, id_ativo) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_ativo AS STRING))) + COUNTIF(id_ativo IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__ativo`
  UNION ALL SELECT 'trs_google_ads__video.chave_unica', 'Trusted', 'trs_google_ads__video', 'Google Ads', 'UNICIDADE',
         'chave (id_conta, id_video) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_video AS STRING))) + COUNTIF(id_video IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__video`
  UNION ALL SELECT 'trs_google_ads__orcamento_conta.chave_unica', 'Trusted', 'trs_google_ads__orcamento_conta', 'Google Ads', 'UNICIDADE',
         'chave (id_conta, id_orcamento) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_orcamento AS STRING))) + COUNTIF(id_orcamento IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__orcamento_conta`
  UNION ALL SELECT 'trs_google_ads__video_desempenho_diario.chave_unica', 'Trusted', 'trs_google_ads__video_desempenho_diario', 'Google Ads', 'UNICIDADE',
         'chave (id_conta, id_campanha, id_grupo_anuncio, id_video, data) e unica e nunca nula', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_conta AS STRING), '|', CAST(id_campanha AS STRING), '|', CAST(id_grupo_anuncio AS STRING), '|', CAST(id_video AS STRING), '|', CAST(data AS STRING))) + COUNTIF(id_campanha IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__video_desempenho_diario`
  -- VALIDADE
  UNION ALL SELECT 'trs_google_ads__palavra_chave.investimento_nao_negativo', 'Trusted', 'trs_google_ads__palavra_chave', 'Google Ads', 'VALIDADE',
         'investimento_micros nunca e negativo', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(investimento_micros < 0) FROM `vanguardamartech_trusted`.`trs_google_ads__palavra_chave`
  UNION ALL SELECT 'trs_google_ads__grupo_anuncio_diario.investimento_nao_negativo', 'Trusted', 'trs_google_ads__grupo_anuncio_diario', 'Google Ads', 'VALIDADE',
         'investimento_micros nunca e negativo', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(investimento_micros < 0) FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio_diario`
  UNION ALL SELECT 'trs_google_ads__video_desempenho_diario.investimento_nao_negativo', 'Trusted', 'trs_google_ads__video_desempenho_diario', 'Google Ads', 'VALIDADE',
         'investimento_micros nunca e negativo', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(investimento_micros < 0) FROM `vanguardamartech_trusted`.`trs_google_ads__video_desempenho_diario`
  UNION ALL SELECT 'trs_google_ads__video_desempenho_diario.visualizacao_nao_excede_impressao', 'Trusted', 'trs_google_ads__video_desempenho_diario', 'Google Ads', 'VALIDADE',
         'visualizacoes_video nunca passa das impressoes (zero quebras em 4.404 na medicao)', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(visualizacoes_video > impressoes) FROM `vanguardamartech_trusted`.`trs_google_ads__video_desempenho_diario`
  -- LINHAS DE BASE: o Google atribui clique e impressao por regras diferentes; a regra detecta PIORA, nao cobra o que a plataforma entrega.
  UNION ALL SELECT 'trs_google_ads__palavra_chave.clique_nao_excede_impressao', 'Trusted', 'trs_google_ads__palavra_chave', 'Google Ads', 'VALIDADE',
         'clique nunca passa da impressao (472 de 198.866 acima na medicao, 0,24%)', 'ALERTA', 0.995, COUNT(*), COUNTIF(cliques > impressoes) FROM `vanguardamartech_trusted`.`trs_google_ads__palavra_chave`
  UNION ALL SELECT 'trs_google_ads__grupo_anuncio_diario.clique_nao_excede_impressao', 'Trusted', 'trs_google_ads__grupo_anuncio_diario', 'Google Ads', 'VALIDADE',
         'clique nunca passa da impressao (66 de 59.160 acima na medicao, 0,11%)', 'ALERTA', 0.998, COUNT(*), COUNTIF(cliques > impressoes) FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio_diario`
  UNION ALL SELECT 'trs_google_ads__alcance_frequencia_campanha.usuario_nao_excede_impressao', 'Trusted', 'trs_google_ads__alcance_frequencia_campanha', 'Google Ads', 'VALIDADE',
         'usuarios unicos no dia nao passam das impressoes (106 de 43.403 acima na medicao, 0,24%)', 'ALERTA', 0.995, COUNT(*), COUNTIF(usuarios_unicos_no_dia > impressoes) FROM `vanguardamartech_trusted`.`trs_google_ads__alcance_frequencia_campanha`
  UNION ALL SELECT 'trs_google_ads__anuncio.titulos_concordam_com_a_contagem', 'Trusted', 'trs_google_ads__anuncio', 'Google Ads', 'VALIDADE',
         'titulos so existe quando qtd_titulos > 0 e existe sempre que qtd_titulos > 0', 'BLOQUEANTE', 1.00, COUNT(*),
         COUNTIF((qtd_titulos = 0 AND IFNULL(titulos, '') <> '') OR (qtd_titulos > 0 AND IFNULL(titulos, '') = '')) FROM `vanguardamartech_trusted`.`trs_google_ads__anuncio`
  UNION ALL SELECT 'trs_google_ads__ativo.texto_so_em_ativo_de_texto', 'Trusted', 'trs_google_ads__ativo', 'Google Ads', 'VALIDADE',
         'so ativo do tipo TEXT carrega texto; nos outros tipos a origem nao entrega o conteudo', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(texto IS NOT NULL AND tipo <> 'TEXT') FROM `vanguardamartech_trusted`.`trs_google_ads__ativo`
  UNION ALL SELECT 'trs_google_ads__orcamento_conta.limite_infinito_sem_valor', 'Trusted', 'trs_google_ads__orcamento_conta', 'Google Ads', 'VALIDADE',
         'limite INFINITE nao carrega valor (NULL, nunca zero)', 'BLOQUEANTE', 1.00, COUNTIF(tipo_limite_aprovado = 'INFINITE'), COUNTIF(tipo_limite_aprovado = 'INFINITE' AND limite_aprovado_micros IS NOT NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__orcamento_conta`
  UNION ALL SELECT 'trs_google_ads__palavra_chave_cadastro.negativa_nunca_nula', 'Trusted', 'trs_google_ads__palavra_chave_cadastro', 'Google Ads', 'VALIDADE',
         'is_negativa nunca e nula', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(is_negativa IS NULL) FROM `vanguardamartech_trusted`.`trs_google_ads__palavra_chave_cadastro`
  -- DESIGUALDADES: cada recorte e parte do investimento da campanha; se a soma por (campanha, dia) passar, o grao duplicou e a contagem de linhas nao denuncia.
  UNION ALL SELECT 'trs_google_ads__palavra_chave.nao_excede_o_total', 'Trusted', 'trs_google_ads__palavra_chave', 'Google Ads', 'VALIDADE',
         'a soma por (campanha, dia) nao excede o investimento da campanha', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(b.micros > t.micros)
  FROM (SELECT CAST(id_campanha AS STRING) AS id_campanha, data, SUM(investimento_micros) AS micros FROM `vanguardamartech_trusted`.`trs_google_ads__palavra_chave` GROUP BY 1,2) b
  JOIN total_campanha_dia t USING (id_campanha, data)
  UNION ALL SELECT 'trs_google_ads__grupo_anuncio_diario.nao_excede_o_total', 'Trusted', 'trs_google_ads__grupo_anuncio_diario', 'Google Ads', 'VALIDADE',
         'a soma por (campanha, dia) nao excede o investimento da campanha', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(b.micros > t.micros)
  FROM (SELECT CAST(id_campanha AS STRING) AS id_campanha, data, SUM(investimento_micros) AS micros FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio_diario` GROUP BY 1,2) b
  JOIN total_campanha_dia t USING (id_campanha, data)
  UNION ALL SELECT 'trs_google_ads__video_desempenho_diario.nao_excede_o_total', 'Trusted', 'trs_google_ads__video_desempenho_diario', 'Google Ads', 'VALIDADE',
         'a soma por (campanha, dia) nao excede o investimento da campanha', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(b.micros > t.micros)
  FROM (SELECT CAST(id_campanha AS STRING) AS id_campanha, data, SUM(investimento_micros) AS micros FROM `vanguardamartech_trusted`.`trs_google_ads__video_desempenho_diario` GROUP BY 1,2) b
  JOIN total_campanha_dia t USING (id_campanha, data)
  -- INTEGRIDADE: dimensao e fotografia, fato e historico; campanha que saiu da dimensao deixa fato orfao. Linhas de base.
  UNION ALL SELECT 'trs_google_ads__grupo_anuncio_diario.grupo_catalogado', 'Trusted', 'trs_google_ads__grupo_anuncio_diario', 'Google Ads', 'INTEGRIDADE',
         'grupo do desempenho diario existe no cadastro de grupos (100% na medicao; dimensao e fotografia, fato e historico)', 'ALERTA', 0.98, COUNT(*), COUNTIF(g.id_grupo_anuncio IS NULL)
  FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio_diario` d LEFT JOIN (SELECT DISTINCT id_conta, id_grupo_anuncio FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio`) g USING (id_conta, id_grupo_anuncio)
  UNION ALL SELECT 'trs_google_ads__grupo_anuncio.campanha_catalogada', 'Trusted', 'trs_google_ads__grupo_anuncio', 'Google Ads', 'INTEGRIDADE',
         'campanha do grupo existe em trs_google_ads__campanha (100% na medicao)', 'ALERTA', 0.98, COUNT(*), COUNTIF(c.id_campanha IS NULL)
  FROM `vanguardamartech_trusted`.`trs_google_ads__grupo_anuncio` g LEFT JOIN (SELECT DISTINCT CAST(id_campanha AS STRING) AS id_campanha FROM `vanguardamartech_trusted`.`trs_google_ads__campanha`) c ON c.id_campanha = CAST(g.id_campanha AS STRING)
  -- FRESCOR com escopo de fonte: as 14 tabelas saem da mesma passada da google-ads-cwt3; uma na carga anterior quer dizer que um ramo nao rodou.
  UNION ALL SELECT 'google_ads_streams.carga_do_mesmo_dia', 'Trusted', 'trs_google_ads__* (14 streams)', 'Google Ads', 'FRESCOR',
         'as 14 Trusted dos streams novos tem a mesma data de carga (todas 2026-10-06 na medicao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(d < (SELECT MAX(d) FROM cargas)) FROM cargas
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
  'GOOGLE_ADS_STREAMS' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'google-ads-cwt3' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a