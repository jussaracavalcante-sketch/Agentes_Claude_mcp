-- rfn_qualidade__regra_facebook_pages  ·  Refined / qualidade  ·  L2 INTERNAL
-- Suite de qualidade da familia Paginas do Facebook (4 Trusted + 4 Refined). Contrato de colunas identico as demais suites.
-- Gatilho: evento `all` nas 4 Refined (query-bekk, query-RviE, query-7osl, query-BI5i): so roda depois de tudo materializado.
-- Cadencia semanal (terca 14:00 America/Manaus, cadeia das fontes manuais). Descricao da transformacao = regras, limiares medidos, limites.
WITH r_pagina AS (
  SELECT 'trs_facebook_pages__pagina.id_pagina_fonte_unico' AS id_regra, 'Trusted' AS camada, 'trs_facebook_pages__pagina' AS tabela, 'Facebook Pages' AS sistema, 'UNICIDADE' AS dimensao,
         'id_pagina_fonte (fonte + id) e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_pagina_fonte) AS linhas_falha
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__pagina`
  UNION ALL
  SELECT 'trs_facebook_pages__pagina.uma_pagina_por_fonte', 'Trusted', 'trs_facebook_pages__pagina', 'Facebook Pages', 'UNICIDADE',
         'cada fonte le exatamente uma pagina (a avaliacao se liga a pagina pela fonte)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT _fonte)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__pagina`
  UNION ALL
  SELECT 'trs_facebook_pages__pagina.nenhuma_pagina_em_duas_fontes', 'Trusted', 'trs_facebook_pages__pagina', 'Facebook Pages', 'UNICIDADE',
         'nenhuma pagina aparece em mais de uma fonte', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(flag_pagina_em_mais_de_uma_fonte)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__pagina`
  UNION ALL
  SELECT 'trs_facebook_pages__pagina.nome_preenchido', 'Trusted', 'trs_facebook_pages__pagina', 'Facebook Pages', 'COMPLETUDE',
         'toda pagina tem nome', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(nome IS NULL)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__pagina`
  UNION ALL
  SELECT 'trs_facebook_pages__pagina.seguidores_validos', 'Trusted', 'trs_facebook_pages__pagina', 'Facebook Pages', 'VALIDADE',
         'seguidores existe e nao e negativo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(seguidores IS NULL OR seguidores < 0)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__pagina`
),
r_insight AS (
  SELECT 'trs_facebook_pages__insight_diario.id_insight_diario_unico' AS id_regra, 'Trusted' AS camada, 'trs_facebook_pages__insight_diario' AS tabela, 'Facebook Pages' AS sistema, 'UNICIDADE' AS dimensao,
         'id_insight_diario (fonte + pagina + dia) e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_insight_diario) AS linhas_falha
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario`
  UNION ALL
  SELECT 'trs_facebook_pages__insight_diario.data_metrica_nao_futura', 'Trusted', 'trs_facebook_pages__insight_diario', 'Facebook Pages', 'VALIDADE',
         'data_metrica nao e posterior ao dia da carga (referencial: _extraido_at, nunca o relogio)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(data_metrica > DATE(_extraido_at))
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario`
  UNION ALL
  SELECT 'trs_facebook_pages__insight_diario.fim_do_periodo_a_meia_noite_pacifico', 'Trusted', 'trs_facebook_pages__insight_diario', 'Facebook Pages', 'VALIDADE',
         'end_time cai sempre a 00:00 no Pacifico (convencao que fixa data_metrica = dia anterior)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(EXTRACT(HOUR FROM DATETIME(fim_periodo_utc, 'America/Los_Angeles')) <> 0 OR EXTRACT(MINUTE FROM DATETIME(fim_periodo_utc, 'America/Los_Angeles')) <> 0)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario`
  UNION ALL
  SELECT 'trs_facebook_pages__insight_diario.metricas_nao_negativas', 'Trusted', 'trs_facebook_pages__insight_diario', 'Facebook Pages', 'VALIDADE',
         'visualizacoes, engajamentos, reacoes, video e media views nao sao negativos', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(visualizacoes_pagina < 0 OR engajamentos_posts < 0 OR media_views < 0 OR video_views < 0 OR reacoes_curtir < 0 OR media_views_unicas < 0)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario`
  UNION ALL
  SELECT 'trs_facebook_pages__insight_diario.video_views_decompoe_em_paga_e_organica', 'Trusted', 'trs_facebook_pages__insight_diario', 'Facebook Pages', 'VALIDADE',
         'video_views = video_views_pagas + video_views_organicas (identidade medida em 173 de 173)', 'BLOQUEANTE', 1.00,
         COUNTIF(video_views IS NOT NULL AND video_views_pagas IS NOT NULL AND video_views_organicas IS NOT NULL), COUNTIF(video_views IS NOT NULL AND video_views_pagas IS NOT NULL AND video_views_organicas IS NOT NULL AND video_views <> video_views_pagas + video_views_organicas)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario`
  UNION ALL
  SELECT 'trs_facebook_pages__insight_diario.unicos_nao_excedem_o_total', 'Trusted', 'trs_facebook_pages__insight_diario', 'Facebook Pages', 'VALIDADE',
         'media_views_unicas nao excede media_views (pessoas distintas nao passam de visualizacoes)', 'ALERTA', 1.00,
         COUNTIF(media_views IS NOT NULL AND media_views_unicas IS NOT NULL), COUNTIF(media_views_unicas > media_views)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario`
  UNION ALL
  SELECT 'trs_facebook_pages__insight_diario.quebra_anuncio_organica_reconcilia', 'Trusted', 'trs_facebook_pages__insight_diario', 'Facebook Pages', 'VALIDADE',
         'media_views_de_anuncio + media_views_organicas = media_views (linha de base: sao chamadas separadas da API; 155 de 173 em 2026-10-16)', 'ALERTA', 0.85,
         COUNTIF(media_views_de_anuncio IS NOT NULL AND media_views_organicas IS NOT NULL), COUNTIF(media_views_de_anuncio IS NOT NULL AND media_views_organicas IS NOT NULL AND media_views_de_anuncio + media_views_organicas <> media_views)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario`
  UNION ALL
  SELECT 'trs_facebook_pages__insight_diario.quebra_seguidor_reconcilia', 'Trusted', 'trs_facebook_pages__insight_diario', 'Facebook Pages', 'VALIDADE',
         'media_views_de_seguidores + media_views_de_nao_seguidores = media_views (linha de base: 155 de 173 em 2026-10-16)', 'ALERTA', 0.85,
         COUNTIF(media_views_de_seguidores IS NOT NULL AND media_views_de_nao_seguidores IS NOT NULL), COUNTIF(media_views_de_seguidores IS NOT NULL AND media_views_de_nao_seguidores IS NOT NULL AND media_views_de_seguidores + media_views_de_nao_seguidores <> media_views)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario`
  UNION ALL
  SELECT 'trs_facebook_pages__insight_diario.quebra_presente', 'Trusted', 'trs_facebook_pages__insight_diario', 'Facebook Pages', 'COMPLETUDE',
         'todo dia de metrica tem a quebra de media views', 'ALERTA', 0.95,
         COUNT(*), COUNTIF(NOT flag_breakdown_presente)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario`
  UNION ALL
  SELECT 'trs_facebook_pages__insight_diario.pagina_catalogada', 'Trusted', 'trs_facebook_pages__insight_diario', 'Facebook Pages', 'INTEGRIDADE',
         'toda linha de insight aponta para pagina de trs_facebook_pages__pagina (anti-join)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(p.k IS NULL)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario` i LEFT JOIN (SELECT DISTINCT _fonte, id_pagina, 1 AS k FROM `vanguardamartech_trusted`.`trs_facebook_pages__pagina`) p ON p._fonte = i._fonte AND p.id_pagina = i.id_pagina
  UNION ALL
  SELECT 'trs_facebook_pages__insight_diario.um_ultimo_periodo_por_pagina', 'Trusted', 'trs_facebook_pages__insight_diario', 'Facebook Pages', 'UNICIDADE',
         'cada pagina tem exatamente um flag_ultimo_periodo_da_fonte (grao: pagina)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(q <> 1)
         FROM (SELECT _fonte, id_pagina, COUNTIF(flag_ultimo_periodo_da_fonte) AS q FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario` GROUP BY 1, 2)
),
r_post AS (
  SELECT 'trs_facebook_pages__post.id_post_fonte_unico' AS id_regra, 'Trusted' AS camada, 'trs_facebook_pages__post' AS tabela, 'Facebook Pages' AS sistema, 'UNICIDADE' AS dimensao,
         'id_post_fonte (fonte + id do post) e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_post_fonte) AS linhas_falha
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__post`
  UNION ALL
  SELECT 'trs_facebook_pages__post.id_com_prefixo_da_pagina', 'Trusted', 'trs_facebook_pages__post', 'Facebook Pages', 'VALIDADE',
         'id_post comeca com o id da propria pagina (<pagina>_<post>; 94 de 94 em 2026-10-16)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(NOT STARTS_WITH(id_post, CONCAT(id_pagina, '_')))
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__post`
  UNION ALL
  SELECT 'trs_facebook_pages__post.criado_nao_futuro', 'Trusted', 'trs_facebook_pages__post', 'Facebook Pages', 'VALIDADE',
         'criado_em nao e posterior ao instante da carga (referencial: _extraido_at)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(criado_em > _extraido_at)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__post`
  UNION ALL
  SELECT 'trs_facebook_pages__post.atualizado_depois_de_criado', 'Trusted', 'trs_facebook_pages__post', 'Facebook Pages', 'VALIDADE',
         'atualizado_em nao e anterior a criado_em', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(atualizado_em < criado_em)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__post`
  UNION ALL
  SELECT 'trs_facebook_pages__post.video_concorda_com_duracao', 'Trusted', 'trs_facebook_pages__post', 'Facebook Pages', 'VALIDADE',
         'is_video (status added_video) coincide com duracao_video_ms preenchida (zero e sentinela de nao-video)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(is_video <> (duracao_video_ms IS NOT NULL))
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__post`
  UNION ALL
  SELECT 'trs_facebook_pages__post.tem_insight', 'Trusted', 'trs_facebook_pages__post', 'Facebook Pages', 'COMPLETUDE',
         'todo post tem a linha de post_insights (join 1:1; 94 de 94 em 2026-10-16)', 'ALERTA', 0.95,
         COUNT(*), COUNTIF(flag_sem_insight)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__post`
  UNION ALL
  SELECT 'trs_facebook_pages__post.tem_quebra', 'Trusted', 'trs_facebook_pages__post', 'Facebook Pages', 'COMPLETUDE',
         'todo post tem a quebra de media views', 'ALERTA', 0.95,
         COUNT(*), COUNTIF(flag_sem_breakdown)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__post`
  UNION ALL
  SELECT 'trs_facebook_pages__post.quebra_anuncio_organica_reconcilia', 'Trusted', 'trs_facebook_pages__post', 'Facebook Pages', 'VALIDADE',
         'media_views_de_anuncio + media_views_organicas = media_views (linha de base: 78 de 94 em 2026-10-16)', 'ALERTA', 0.75,
         COUNTIF(media_views_de_anuncio IS NOT NULL AND media_views_organicas IS NOT NULL), COUNTIF(media_views_de_anuncio IS NOT NULL AND media_views_organicas IS NOT NULL AND media_views_de_anuncio + media_views_organicas <> media_views)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__post`
  UNION ALL
  SELECT 'trs_facebook_pages__post.pagina_catalogada', 'Trusted', 'trs_facebook_pages__post', 'Facebook Pages', 'INTEGRIDADE',
         'todo post aponta para pagina de trs_facebook_pages__pagina (anti-join)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(p.k IS NULL)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__post` i LEFT JOIN (SELECT DISTINCT _fonte, id_pagina, 1 AS k FROM `vanguardamartech_trusted`.`trs_facebook_pages__pagina`) p ON p._fonte = i._fonte AND p.id_pagina = i.id_pagina
),
r_avaliacao AS (
  SELECT 'trs_facebook_pages__avaliacao.id_avaliacao_fonte_unico' AS id_regra, 'Trusted' AS camada, 'trs_facebook_pages__avaliacao' AS tabela, 'Facebook Pages' AS sistema, 'UNICIDADE' AS dimensao,
         'id_avaliacao_fonte (fonte + instante + seq) e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_avaliacao_fonte) AS linhas_falha
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__avaliacao`
  UNION ALL
  SELECT 'trs_facebook_pages__avaliacao.tipo_de_recomendacao_conhecido', 'Trusted', 'trs_facebook_pages__avaliacao', 'Facebook Pages', 'VALIDADE',
         'tipo_recomendacao so assume positive ou negative', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(tipo_recomendacao IS NULL OR tipo_recomendacao NOT IN ('positive', 'negative'))
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__avaliacao`
  UNION ALL
  SELECT 'trs_facebook_pages__avaliacao.criada_nao_futura', 'Trusted', 'trs_facebook_pages__avaliacao', 'Facebook Pages', 'VALIDADE',
         'criada_em nao e posterior ao instante da carga (referencial: _extraido_at)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(criada_em > _extraido_at)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__avaliacao`
  UNION ALL
  SELECT 'trs_facebook_pages__avaliacao.fonte_catalogada', 'Trusted', 'trs_facebook_pages__avaliacao', 'Facebook Pages', 'INTEGRIDADE',
         'toda avaliacao tem uma pagina na mesma fonte (page_id e NULL na origem; o elo e a fonte)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(p.k IS NULL)
         FROM `vanguardamartech_trusted`.`trs_facebook_pages__avaliacao` i LEFT JOIN (SELECT DISTINCT _fonte, 1 AS k FROM `vanguardamartech_trusted`.`trs_facebook_pages__pagina`) p ON p._fonte = i._fonte
),
r_desempenho AS (
  SELECT 'rfn_social__pagina_desempenho_mensal.id_pagina_mes_unico' AS id_regra, 'Refined' AS camada, 'rfn_social__pagina_desempenho_mensal' AS tabela, 'Facebook Pages' AS sistema, 'UNICIDADE' AS dimensao,
         'id_pagina_mes e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_pagina_mes) AS linhas_falha
         FROM `vanguardamartech_refined`.`rfn_social__pagina_desempenho_mensal`
  UNION ALL
  SELECT 'rfn_social__pagina_desempenho_mensal.dias_reproduzem_a_trusted', 'Refined', 'rfn_social__pagina_desempenho_mensal', 'Facebook Pages', 'VALIDADE',
         'soma de qtd_dias_com_dado reproduz as linhas de trs_facebook_pages__insight_diario (identidade entre camadas)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_dias_com_dado) FROM `vanguardamartech_refined`.`rfn_social__pagina_desempenho_mensal`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario`), 0, 1)
         FROM (SELECT 1)
  UNION ALL
  SELECT 'rfn_social__pagina_desempenho_mensal.media_views_reproduz_a_trusted', 'Refined', 'rfn_social__pagina_desempenho_mensal', 'Facebook Pages', 'VALIDADE',
         'soma de media_views reproduz a Trusted (a Refined agrega e nao filtra)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(media_views) FROM `vanguardamartech_refined`.`rfn_social__pagina_desempenho_mensal`) = (SELECT SUM(media_views) FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario`), 0, 1)
         FROM (SELECT 1)
  UNION ALL
  SELECT 'rfn_social__pagina_desempenho_mensal.dias_cabem_no_mes', 'Refined', 'rfn_social__pagina_desempenho_mensal', 'Facebook Pages', 'VALIDADE',
         'qtd_dias_com_dado nunca excede dias_no_mes', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_dias_com_dado > dias_no_mes)
         FROM `vanguardamartech_refined`.`rfn_social__pagina_desempenho_mensal`
  UNION ALL
  SELECT 'rfn_social__pagina_desempenho_mensal.participacao_entre_zero_e_um', 'Refined', 'rfn_social__pagina_desempenho_mensal', 'Facebook Pages', 'VALIDADE',
         'participacao_anuncio_nas_partes fica entre 0 e 1', 'BLOQUEANTE', 1.00,
         COUNTIF(participacao_anuncio_nas_partes IS NOT NULL), COUNTIF(participacao_anuncio_nas_partes < 0 OR participacao_anuncio_nas_partes > 1)
         FROM `vanguardamartech_refined`.`rfn_social__pagina_desempenho_mensal`
  UNION ALL
  SELECT 'rfn_social__pagina_desempenho_mensal.um_mes_mais_recente_por_pagina', 'Refined', 'rfn_social__pagina_desempenho_mensal', 'Facebook Pages', 'UNICIDADE',
         'cada pagina tem exatamente um mes mais recente (so ele carrega seguidores; grao: pagina)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(q <> 1)
         FROM (SELECT fonte, id_pagina, COUNTIF(is_mes_mais_recente) AS q FROM `vanguardamartech_refined`.`rfn_social__pagina_desempenho_mensal` GROUP BY 1, 2)
),
r_post_mensal AS (
  SELECT 'rfn_social__pagina_post_mensal.id_pagina_mes_unico' AS id_regra, 'Refined' AS camada, 'rfn_social__pagina_post_mensal' AS tabela, 'Facebook Pages' AS sistema, 'UNICIDADE' AS dimensao,
         'id_pagina_mes e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_pagina_mes) AS linhas_falha
         FROM `vanguardamartech_refined`.`rfn_social__pagina_post_mensal`
  UNION ALL
  SELECT 'rfn_social__pagina_post_mensal.posts_reproduzem_a_trusted', 'Refined', 'rfn_social__pagina_post_mensal', 'Facebook Pages', 'VALIDADE',
         'soma de qtd_posts reproduz as linhas de trs_facebook_pages__post (identidade entre camadas)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_posts) FROM `vanguardamartech_refined`.`rfn_social__pagina_post_mensal`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_facebook_pages__post`), 0, 1)
         FROM (SELECT 1)
  UNION ALL
  SELECT 'rfn_social__pagina_post_mensal.media_views_reproduz_a_trusted', 'Refined', 'rfn_social__pagina_post_mensal', 'Facebook Pages', 'VALIDADE',
         'soma de media_views reproduz a Trusted de post', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(media_views) FROM `vanguardamartech_refined`.`rfn_social__pagina_post_mensal`) = (SELECT SUM(media_views) FROM `vanguardamartech_trusted`.`trs_facebook_pages__post`), 0, 1)
         FROM (SELECT 1)
  UNION ALL
  SELECT 'rfn_social__pagina_post_mensal.tipos_decompoem_os_posts', 'Refined', 'rfn_social__pagina_post_mensal', 'Facebook Pages', 'VALIDADE',
         'qtd_fotos + qtd_videos + qtd_outros_tipos = qtd_posts', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_fotos + qtd_videos + qtd_outros_tipos <> qtd_posts)
         FROM `vanguardamartech_refined`.`rfn_social__pagina_post_mensal`
),
r_aval_mensal AS (
  SELECT 'rfn_social__pagina_avaliacao_mensal.id_pagina_mes_unico' AS id_regra, 'Refined' AS camada, 'rfn_social__pagina_avaliacao_mensal' AS tabela, 'Facebook Pages' AS sistema, 'UNICIDADE' AS dimensao,
         'id_pagina_mes e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_pagina_mes) AS linhas_falha
         FROM `vanguardamartech_refined`.`rfn_social__pagina_avaliacao_mensal`
  UNION ALL
  SELECT 'rfn_social__pagina_avaliacao_mensal.avaliacoes_reproduzem_a_trusted', 'Refined', 'rfn_social__pagina_avaliacao_mensal', 'Facebook Pages', 'VALIDADE',
         'soma de qtd_avaliacoes reproduz as linhas de trs_facebook_pages__avaliacao (identidade entre camadas)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_avaliacoes) FROM `vanguardamartech_refined`.`rfn_social__pagina_avaliacao_mensal`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_facebook_pages__avaliacao`), 0, 1)
         FROM (SELECT 1)
  UNION ALL
  SELECT 'rfn_social__pagina_avaliacao_mensal.positivas_e_negativas_decompoem', 'Refined', 'rfn_social__pagina_avaliacao_mensal', 'Facebook Pages', 'VALIDADE',
         'qtd_positivas + qtd_negativas = qtd_avaliacoes', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_positivas + qtd_negativas <> qtd_avaliacoes)
         FROM `vanguardamartech_refined`.`rfn_social__pagina_avaliacao_mensal`
  UNION ALL
  SELECT 'rfn_social__pagina_avaliacao_mensal.taxa_entre_zero_e_um', 'Refined', 'rfn_social__pagina_avaliacao_mensal', 'Facebook Pages', 'VALIDADE',
         'taxas de recomendacao ficam entre 0 e 1', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(taxa_recomendacao_no_mes NOT BETWEEN 0 AND 1 OR taxa_recomendacao_acumulada NOT BETWEEN 0 AND 1)
         FROM `vanguardamartech_refined`.`rfn_social__pagina_avaliacao_mensal`
),
r_cobertura AS (
  SELECT 'rfn_social__pagina_cobertura_extracao.id_pagina_fonte_unico' AS id_regra, 'Refined' AS camada, 'rfn_social__pagina_cobertura_extracao' AS tabela, 'Facebook Pages' AS sistema, 'UNICIDADE' AS dimensao,
         'id_pagina_fonte e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_pagina_fonte) AS linhas_falha
         FROM `vanguardamartech_refined`.`rfn_social__pagina_cobertura_extracao`
  UNION ALL
  SELECT 'rfn_social__pagina_cobertura_extracao.uma_linha_por_pagina', 'Refined', 'rfn_social__pagina_cobertura_extracao', 'Facebook Pages', 'VALIDADE',
         'a cobertura tem uma linha por pagina de trs_facebook_pages__pagina (nenhuma pagina some)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT COUNT(*) FROM `vanguardamartech_refined`.`rfn_social__pagina_cobertura_extracao`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_facebook_pages__pagina`), 0, 1)
         FROM (SELECT 1)
  UNION ALL
  SELECT 'rfn_social__pagina_cobertura_extracao.dias_reproduzem_a_trusted', 'Refined', 'rfn_social__pagina_cobertura_extracao', 'Facebook Pages', 'VALIDADE',
         'soma de qtd_dias_insight reproduz as linhas de trs_facebook_pages__insight_diario', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_dias_insight) FROM `vanguardamartech_refined`.`rfn_social__pagina_cobertura_extracao`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario`), 0, 1)
         FROM (SELECT 1)
  UNION ALL
  SELECT 'rfn_social__pagina_cobertura_extracao.posts_reproduzem_a_trusted', 'Refined', 'rfn_social__pagina_cobertura_extracao', 'Facebook Pages', 'VALIDADE',
         'soma de qtd_posts reproduz as linhas de trs_facebook_pages__post', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_posts) FROM `vanguardamartech_refined`.`rfn_social__pagina_cobertura_extracao`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_facebook_pages__post`), 0, 1)
         FROM (SELECT 1)
  UNION ALL
  SELECT 'rfn_social__pagina_cobertura_extracao.avaliacoes_reproduzem_a_trusted', 'Refined', 'rfn_social__pagina_cobertura_extracao', 'Facebook Pages', 'VALIDADE',
         'soma de qtd_avaliacoes reproduz as linhas de trs_facebook_pages__avaliacao', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_avaliacoes) FROM `vanguardamartech_refined`.`rfn_social__pagina_cobertura_extracao`) = (SELECT COUNT(*) FROM `vanguardamartech_trusted`.`trs_facebook_pages__avaliacao`), 0, 1)
         FROM (SELECT 1)
),
r_frescor AS (
  SELECT 'trs_facebook_pages__*.carga_do_mesmo_dia' AS id_regra, 'Trusted' AS camada, 'trs_facebook_pages__*' AS tabela, 'Facebook Pages' AS sistema, 'VALIDADE' AS dimensao,
         'as quatro Trusted da familia foram escritas na mesma passada (mesma data de _extraido_at)' AS regra, 'ALERTA' AS severidade, 1.00 AS limiar,
         1 AS linhas_avaliadas, IF((SELECT COUNT(DISTINCT d) FROM (SELECT DATE(MAX(_extraido_at)) AS d FROM `vanguardamartech_trusted`.`trs_facebook_pages__pagina` UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_facebook_pages__insight_diario` UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_facebook_pages__post` UNION ALL SELECT DATE(MAX(_extraido_at)) FROM `vanguardamartech_trusted`.`trs_facebook_pages__avaliacao`)) = 1, 0, 1) AS linhas_falha
         FROM (SELECT 1)
),
todas AS (
SELECT * FROM r_pagina
  UNION ALL SELECT * FROM r_insight
  UNION ALL SELECT * FROM r_post
  UNION ALL SELECT * FROM r_avaliacao
  UNION ALL SELECT * FROM r_desempenho
  UNION ALL SELECT * FROM r_post_mensal
  UNION ALL SELECT * FROM r_aval_mensal
  UNION ALL SELECT * FROM r_cobertura
  UNION ALL SELECT * FROM r_frescor
),
avaliado AS (
  SELECT
    t.*,
    (t.linhas_avaliadas - t.linhas_falha)                       AS linhas_conformes,
    SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, NULLIF(t.linhas_avaliadas, 0))
                                                                AS taxa_conformidade,
    -- Regra sem linha para avaliar NAO passa: sai NULL, nunca TRUE.
    IF(t.linhas_avaliadas = 0, NULL,
       SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, t.linhas_avaliadas) >= t.limiar)
                                                                AS is_conforme,
    (t.linhas_avaliadas = 0)                                    AS flag_sem_linha_para_avaliar
  FROM todas t
)
SELECT
  a.*,
  CASE
    WHEN a.flag_sem_linha_para_avaliar          THEN 'SEM_DADO'
    WHEN a.is_conforme                          THEN 'CONFORME'
    WHEN a.severidade = 'BLOQUEANTE'            THEN 'FALHA_BLOQUEANTE'
    ELSE                                             'FALHA_ALERTA'
  END                                           AS resultado,
  'Facebook Pages'                              AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
