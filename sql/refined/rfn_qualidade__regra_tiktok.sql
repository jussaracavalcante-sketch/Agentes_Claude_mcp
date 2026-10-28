WITH c AS (SELECT * FROM `vanguardamartech_trusted`.`trs_tiktok__conta`),
v AS (SELECT * FROM `vanguardamartech_trusted`.`trs_tiktok__video`),
m AS (SELECT * FROM `vanguardamartech_refined`.`rfn_social__tiktok_video_mensal`),
vc AS (
  SELECT c.id_conta, c.qtd_videos_no_perfil, COUNT(v.id_video) AS qtd_extraida
  FROM c LEFT JOIN v ON v.id_conta = c.id_conta
  GROUP BY c.id_conta, c.qtd_videos_no_perfil
),
r AS (
  SELECT 'trs_tiktok__conta.id_unico' AS id_regra, 'Trusted' AS camada, 'trs_tiktok__conta' AS tabela, 'TikTok' AS sistema, 'UNICIDADE' AS dimensao,
         'id_conta (open_id) e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_conta) + COUNTIF(id_conta IS NULL) AS linhas_falha FROM c
  UNION ALL
  SELECT 'trs_tiktok__conta.uma_fonte_por_conta', 'Trusted', 'trs_tiktok__conta', 'TikTok', 'UNICIDADE',
         'cada fonte tiktok-* le uma conta so (R-001: uma camada por fonte)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT _fonte) FROM c
  UNION ALL
  SELECT 'trs_tiktok__conta.usuario_preenchido', 'Trusted', 'trs_tiktok__conta', 'TikTok', 'COMPLETUDE',
         'usuario (@) preenchido e sem espacos nas pontas', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(usuario IS NULL OR usuario <> TRIM(usuario)) FROM c
  UNION ALL
  SELECT 'trs_tiktok__conta.contagens_nao_negativas', 'Trusted', 'trs_tiktok__conta', 'TikTok', 'VALIDADE',
         'seguidores, seguindo, curtidas_total e qtd_videos_no_perfil nunca negativos', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(seguidores < 0 OR seguindo < 0 OR curtidas_total < 0 OR qtd_videos_no_perfil < 0) FROM c
  UNION ALL
  SELECT 'trs_tiktok__video.id_unico', 'Trusted', 'trs_tiktok__video', 'TikTok', 'UNICIDADE',
         'id_video e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_video) + COUNTIF(id_video IS NULL) FROM v
  UNION ALL
  -- Anti-join: NOT EXISTS correlacionado sobre CTE grande nao roda no BigQuery.
  SELECT 'trs_tiktok__video.conta_catalogada', 'Trusted', 'trs_tiktok__video', 'TikTok', 'INTEGRIDADE',
         'todo video aponta para uma conta existente em trs_tiktok__conta', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(k.id_conta IS NULL)
  FROM v LEFT JOIN (SELECT DISTINCT id_conta FROM c) k ON k.id_conta = v.id_conta
  UNION ALL
  SELECT 'trs_tiktok__video.metricas_nao_negativas', 'Trusted', 'trs_tiktok__video', 'TikTok', 'VALIDADE',
         'visualizacoes, curtidas, comentarios, compartilhamentos e duracao_s nunca negativos', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(visualizacoes < 0 OR curtidas < 0 OR comentarios < 0 OR compartilhamentos < 0 OR duracao_s < 0) FROM v
  UNION ALL
  SELECT 'trs_tiktok__video.publicado_em_nao_futuro', 'Trusted', 'trs_tiktok__video', 'TikTok', 'VALIDADE',
         'publicado_em nunca posterior a carga (create_time e epoch UTC)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(publicado_em > _extraido_at) FROM v
  UNION ALL
  -- Guarda o fuso: o create_time e UTC e data_local/hora_local sao America/Sao_Paulo (DATETIME(ts,'America/Sao_Paulo')).
  SELECT 'trs_tiktok__video.data_local_concorda_com_o_fuso', 'Trusted', 'trs_tiktok__video', 'TikTok', 'VALIDADE',
         'data_local, hora_local e mes_referencia reproduzem publicado_em em America/Sao_Paulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(data_local <> DATE(DATETIME(publicado_em, 'America/Sao_Paulo'))
                           OR hora_local <> EXTRACT(HOUR FROM DATETIME(publicado_em, 'America/Sao_Paulo'))
                           OR mes_referencia <> DATE_TRUNC(data_local, MONTH)) FROM v
  UNION ALL
  -- Linha de base: o perfil declara um total e a extracao traz outro em algumas contas (diferenca pequena, causa nao verificada).
  SELECT 'trs_tiktok__video.extracao_cobre_o_perfil', 'Trusted', 'trs_tiktok__video', 'TikTok', 'INTEGRIDADE',
         'contas em que os videos extraidos nao passam do video_count do perfil', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(qtd_extraida > qtd_videos_no_perfil) FROM vc
  UNION ALL
  -- Linha de base medida em 28/10: 7 de 14 contas extraem de 1 a 7 videos a menos que o perfil declara (96,8% a 99,7% de cobertura); piso de 95% detecta piora.
  SELECT 'trs_tiktok__video.extracao_cobre_95pct_do_perfil', 'Trusted', 'trs_tiktok__video', 'TikTok', 'INTEGRIDADE',
         'contas em que os videos extraidos cobrem ao menos 95% do video_count do perfil', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(qtd_videos_no_perfil > 0 AND qtd_extraida < 0.95 * qtd_videos_no_perfil) FROM vc
  UNION ALL
  SELECT 'rfn_social__tiktok_video_mensal.id_unico', 'Refined', 'rfn_social__tiktok_video_mensal', 'TikTok', 'UNICIDADE',
         'id_conta_mes e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_conta_mes) + COUNTIF(id_conta_mes IS NULL) FROM m
  UNION ALL
  -- Identidades entre camadas (grao de 1 linha: total contra total). A Refined agrega e nao filtra.
  SELECT 'rfn_social__tiktok_video_mensal.videos_reproduzem_a_trusted', 'Refined', 'rfn_social__tiktok_video_mensal', 'TikTok', 'INTEGRIDADE',
         'soma de qtd_videos nos meses = numero de videos da Trusted', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_videos) FROM m) = (SELECT COUNT(*) FROM v), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_social__tiktok_video_mensal.metricas_reproduzem_a_trusted', 'Refined', 'rfn_social__tiktok_video_mensal', 'TikTok', 'INTEGRIDADE',
         'soma de visualizacoes, curtidas, comentarios e compartilhamentos nos meses = soma da Trusted', 'BLOQUEANTE', 1.00,
         1, IF(IFNULL((SELECT SUM(visualizacoes) FROM m), 0) = IFNULL((SELECT SUM(visualizacoes) FROM v), 0)
               AND IFNULL((SELECT SUM(curtidas) FROM m), 0) = IFNULL((SELECT SUM(curtidas) FROM v), 0)
               AND IFNULL((SELECT SUM(comentarios) FROM m), 0) = IFNULL((SELECT SUM(comentarios) FROM v), 0)
               AND IFNULL((SELECT SUM(compartilhamentos) FROM m), 0) = IFNULL((SELECT SUM(compartilhamentos) FROM v), 0), 0, 1) FROM UNNEST([1])
  UNION ALL
  -- Conta sem video nao gera linha neste grao: as contas da Refined sao as da Trusted de video, nunca mais.
  SELECT 'rfn_social__tiktok_video_mensal.contas_reproduzem_os_videos', 'Refined', 'rfn_social__tiktok_video_mensal', 'TikTok', 'INTEGRIDADE',
         'contas distintas na Refined = contas distintas com video na Trusted', 'BLOQUEANTE', 1.00,
         1, IF((SELECT COUNT(DISTINCT id_conta) FROM m) = (SELECT COUNT(DISTINCT id_conta) FROM v), 0, 1) FROM UNNEST([1])
  UNION ALL
  -- R3: sem visualizacao a taxa e NULL, nunca zero; com visualizacao ela e a razao declarada.
  SELECT 'rfn_social__tiktok_video_mensal.taxa_null_sem_visualizacao', 'Refined', 'rfn_social__tiktok_video_mensal', 'TikTok', 'VALIDADE',
         'taxa_engajamento e NULL quando visualizacoes = 0 e reproduz a razao quando > 0', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(IF(visualizacoes = 0, taxa_engajamento IS NOT NULL,
                              taxa_engajamento IS NULL OR ABS(taxa_engajamento - (curtidas + comentarios + compartilhamentos) / visualizacoes) > 1e-9)) FROM m
  UNION ALL
  SELECT 'rfn_social__tiktok_video_mensal.conta_catalogada', 'Refined', 'rfn_social__tiktok_video_mensal', 'TikTok', 'INTEGRIDADE',
         'toda linha aponta para uma conta de trs_tiktok__conta (usuario preenchido pelo join)', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(k.id_conta IS NULL)
  FROM m LEFT JOIN (SELECT DISTINCT id_conta FROM c) k ON k.id_conta = m.id_conta
  UNION ALL
  SELECT 'rfn_social__tiktok_video_mensal.janela_dentro_do_mes', 'Refined', 'rfn_social__tiktok_video_mensal', 'TikTok', 'VALIDADE',
         'primeira e ultima publicacao caem dentro do mes_referencia e na ordem certa', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(primeira_publicacao > ultima_publicacao
                           OR DATE_TRUNC(primeira_publicacao, MONTH) <> mes_referencia
                           OR DATE_TRUNC(ultima_publicacao, MONTH) <> mes_referencia) FROM m
  UNION ALL
  -- Frescor: as tres tabelas sao escritas na mesma passada (Refined dispara nas duas Trusted com regra all).
  SELECT 'tiktok.carga_do_mesmo_dia', 'Trusted', 'trs_tiktok__conta+video+rfn_social__tiktok_video_mensal', 'TikTok', 'INTEGRIDADE',
         'as duas Trusted e a Refined foram escritas no mesmo dia', 'BLOQUEANTE', 1.00,
         1, IF((SELECT MAX(DATE(_extraido_at)) FROM c) = (SELECT MAX(DATE(_extraido_at)) FROM v)
               AND (SELECT MAX(DATE(_extraido_at)) FROM v) = (SELECT MAX(DATE(_extraido_at)) FROM m), 0, 1) FROM UNNEST([1])
  -- Sem LIMIT: no ultimo ramo de um UNION ALL ele vale para a uniao inteira.
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
  'TikTok' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'tiktok-*' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a
