-- rfn_operacao__intranet_atividade_mensal  (query-bkJu)
-- Refined / operacao, L2, gatilho "all" em query-NlWT (conteudo) e query-ZT0h (leitura). Grao: mes x origem (tipo de conteudo).
-- Dois fluxos independentes na mesma linha (publicado e lido): nao se dividem. So 4 de 10 tipos tem tabela de leitura.
-- Medido em 06/10/2026: 58 linhas, 80 conteudos, 118 leituras, 6 linhas sem data (mes NULL), 2019-06 a 2026-08.
WITH c AS (
  SELECT
    origem,
    DATE_TRUNC(DATE(COALESCE(publicado_em, cadastrado_em)), MONTH) AS mes_referencia,
    COUNT(*) AS qtd_conteudos,
    COUNTIF(publicado_em IS NULL) AS qtd_sem_data_de_publicacao,
    COUNTIF(flag_conta_nao_catalogada) AS qtd_conta_nao_catalogada,
    SUM(texto_chars) AS soma_texto_chars,
    MAX(_extraido_at) AS _extraido_c
  FROM `vanguardamartech_trusted`.`trs_vjob__intranet_conteudo`
  GROUP BY 1, 2
),
l AS (
  SELECT
    origem,
    DATE_TRUNC(DATE(lido_em), MONTH) AS mes_referencia,
    COUNT(*) AS qtd_leituras,
    COUNT(DISTINCT id_usuario) AS qtd_leitores_distintos,
    COUNTIF(flag_usuario_nao_catalogado) AS qtd_leitura_usuario_nao_catalogado,
    MAX(_extraido_at) AS _extraido_l
  FROM `vanguardamartech_trusted`.`trs_vjob__intranet_leitura`
  GROUP BY 1, 2
)
SELECT
  COALESCE(c.mes_referencia, l.mes_referencia) AS mes_referencia,
  COALESCE(c.origem, l.origem) AS origem,
  IFNULL(c.qtd_conteudos, 0) AS qtd_conteudos,
  IFNULL(c.qtd_sem_data_de_publicacao, 0) AS qtd_sem_data_de_publicacao,
  IFNULL(c.qtd_conta_nao_catalogada, 0) AS qtd_conta_nao_catalogada,
  c.soma_texto_chars AS soma_texto_chars,
  IFNULL(l.qtd_leituras, 0) AS qtd_leituras,
  l.qtd_leitores_distintos AS qtd_leitores_distintos,
  IFNULL(l.qtd_leitura_usuario_nao_catalogado, 0) AS qtd_leitura_usuario_nao_catalogado,
  CURRENT_TIMESTAMP() AS _extraido_at,
  GREATEST(IFNULL(c._extraido_c, TIMESTAMP '1970-01-01'), IFNULL(l._extraido_l, TIMESTAMP '1970-01-01')) AS _extraido_trusted
FROM c
FULL OUTER JOIN l
  ON c.origem = l.origem
 AND (c.mes_referencia = l.mes_referencia OR (c.mes_referencia IS NULL AND l.mes_referencia IS NULL))
