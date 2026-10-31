-- rfn_midia__meta_ativos_conta (Refined / midia) - 2026-10-18
-- Grao: uma conta de anuncios do Meta (id_conta) com ao menos um ativo (imagem, video, rotulo, publico personalizado ou conversao personalizada). Chave id_conta.
-- Le as 5 Trusted irmas (imagem, video, rotulo, publico_personalizado, conversao_personalizada) e a dimensao trs_facebook_ads__conta. Nivel L2: so contagem, soma e datas;
-- nome de publico, descricao, nome de arquivo, URL e hash de imagem NAO atravessam. Gatilho: evento com regra all nas 5 Trusted (cron terca 13:40 Manaus).
WITH img AS (
  SELECT id_conta, ANY_VALUE(_fonte) AS fonte, COUNT(*) AS qtd_imagens,
         COUNTIF(tem_criativo) AS qtd_imagens_com_criativo, COUNTIF(NOT tem_criativo) AS qtd_imagens_sem_criativo,
         COUNTIF(flag_dimensao_difere_do_original) AS qtd_imagens_redimensionadas,
         MIN(criada_em) AS primeira_imagem_criada_em, MAX(criada_em) AS ultima_imagem_criada_em
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__imagem` GROUP BY id_conta
),
vid AS (
  SELECT id_conta, ANY_VALUE(_fonte) AS fonte, COUNT(*) AS qtd_videos,
         SUM(duracao_seg) AS duracao_total_seg, SUM(visualizacoes) AS visualizacoes_acumuladas, SUM(visualizacoes_post) AS visualizacoes_post_acumuladas,
         COUNTIF(titulo IS NULL) AS qtd_videos_sem_titulo,
         MIN(criado_em) AS primeiro_video_criado_em, MAX(criado_em) AS ultimo_video_criado_em
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__video` GROUP BY id_conta
),
rot AS (
  SELECT id_conta, ANY_VALUE(_fonte) AS fonte, COUNT(*) AS qtd_rotulos,
         COUNTIF(flag_rotulo_automatico_de_posicionamento) AS qtd_rotulos_automaticos,
         COUNTIF(NOT flag_rotulo_automatico_de_posicionamento) AS qtd_rotulos_manuais
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__rotulo` GROUP BY id_conta
),
pub AS (
  SELECT id_conta_da_fonte AS id_conta, ANY_VALUE(_fonte) AS fonte, COUNT(*) AS qtd_publicos_visiveis,
         COUNTIF(NOT flag_publico_de_outra_conta) AS qtd_publicos_proprios, COUNTIF(flag_publico_de_outra_conta) AS qtd_publicos_compartilhados,
         COUNTIF(is_semelhante) AS qtd_publicos_semelhantes, COUNTIF(flag_contagem_indisponivel) AS qtd_publicos_sem_contagem,
         COUNTIF(entrega_codigo = 200) AS qtd_publicos_prontos, COUNTIF(entrega_codigo = 300) AS qtd_publicos_pequenos_demais,
         MAX(qtd_aprox_max) AS maior_publico_qtd_max
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__publico_personalizado` GROUP BY 1
),
cnv AS (
  SELECT id_conta, ANY_VALUE(_fonte) AS fonte, COUNT(*) AS qtd_conversoes,
         COUNTIF(is_arquivada) AS qtd_conversoes_arquivadas, COUNTIF(NOT is_arquivada) AS qtd_conversoes_ativas,
         COUNTIF(flag_nunca_disparou) AS qtd_conversoes_nunca_dispararam,
         COUNTIF(NOT is_arquivada AND flag_nunca_disparou) AS qtd_conversoes_ativas_nunca_dispararam
  FROM `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conversao_personalizada` GROUP BY id_conta
),
spine AS (
  SELECT id_conta, fonte FROM img UNION DISTINCT SELECT id_conta, fonte FROM vid UNION DISTINCT SELECT id_conta, fonte FROM rot
  UNION DISTINCT SELECT id_conta, fonte FROM pub UNION DISTINCT SELECT id_conta, fonte FROM cnv
),
res AS (
SELECT
  s.id_conta, s.fonte,
  d.conta, d.moeda, d.fuso_conta,
  (d.id_conta IS NULL) AS flag_conta_nao_catalogada,
  IFNULL(i.qtd_imagens, 0) AS qtd_imagens, IFNULL(i.qtd_imagens_com_criativo, 0) AS qtd_imagens_com_criativo,
  IFNULL(i.qtd_imagens_sem_criativo, 0) AS qtd_imagens_sem_criativo, IFNULL(i.qtd_imagens_redimensionadas, 0) AS qtd_imagens_redimensionadas,
  SAFE_DIVIDE(i.qtd_imagens_com_criativo, i.qtd_imagens) AS taxa_imagens_com_criativo,
  i.primeira_imagem_criada_em, i.ultima_imagem_criada_em,
  IFNULL(v.qtd_videos, 0) AS qtd_videos, IFNULL(v.duracao_total_seg, 0) AS duracao_total_seg,
  IFNULL(v.visualizacoes_acumuladas, 0) AS visualizacoes_acumuladas, IFNULL(v.visualizacoes_post_acumuladas, 0) AS visualizacoes_post_acumuladas,
  IFNULL(v.qtd_videos_sem_titulo, 0) AS qtd_videos_sem_titulo, v.primeiro_video_criado_em, v.ultimo_video_criado_em,
  IFNULL(r.qtd_rotulos, 0) AS qtd_rotulos, IFNULL(r.qtd_rotulos_automaticos, 0) AS qtd_rotulos_automaticos, IFNULL(r.qtd_rotulos_manuais, 0) AS qtd_rotulos_manuais,
  IFNULL(p.qtd_publicos_visiveis, 0) AS qtd_publicos_visiveis, IFNULL(p.qtd_publicos_proprios, 0) AS qtd_publicos_proprios,
  IFNULL(p.qtd_publicos_compartilhados, 0) AS qtd_publicos_compartilhados, IFNULL(p.qtd_publicos_semelhantes, 0) AS qtd_publicos_semelhantes,
  IFNULL(p.qtd_publicos_sem_contagem, 0) AS qtd_publicos_sem_contagem, IFNULL(p.qtd_publicos_prontos, 0) AS qtd_publicos_prontos,
  IFNULL(p.qtd_publicos_pequenos_demais, 0) AS qtd_publicos_pequenos_demais, p.maior_publico_qtd_max,
  IFNULL(c.qtd_conversoes, 0) AS qtd_conversoes, IFNULL(c.qtd_conversoes_arquivadas, 0) AS qtd_conversoes_arquivadas,
  IFNULL(c.qtd_conversoes_ativas, 0) AS qtd_conversoes_ativas, IFNULL(c.qtd_conversoes_nunca_dispararam, 0) AS qtd_conversoes_nunca_dispararam,
  IFNULL(c.qtd_conversoes_ativas_nunca_dispararam, 0) AS qtd_conversoes_ativas_nunca_dispararam,
  (IFNULL(i.qtd_imagens, 0) > 0) AS tem_imagens, (IFNULL(v.qtd_videos, 0) > 0) AS tem_videos,
  (IFNULL(p.qtd_publicos_visiveis, 0) > 0) AS tem_publicos, (IFNULL(c.qtd_conversoes, 0) > 0) AS tem_conversoes,
  CURRENT_TIMESTAMP() AS _extraido_at
FROM spine s
LEFT JOIN img i ON i.id_conta = s.id_conta
LEFT JOIN vid v ON v.id_conta = s.id_conta
LEFT JOIN rot r ON r.id_conta = s.id_conta
LEFT JOIN pub p ON p.id_conta = s.id_conta
LEFT JOIN cnv c ON c.id_conta = s.id_conta
LEFT JOIN `vanguardamartech_trusted_facebook_ads`.`trs_facebook_ads__conta` d ON d.id_conta = s.id_conta
)
SELECT * FROM res
