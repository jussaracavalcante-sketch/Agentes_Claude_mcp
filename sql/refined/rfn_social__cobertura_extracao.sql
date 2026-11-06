-- rfn_social__cobertura_extracao  ·  Refined / social  ·  L2
-- Grao: uma CONTA Instagram. Chave: id_conta. Responde: o que a extracao trouxe, comparado
-- com o que a conta tem. A Refined de social NAO pode apresentar a contagem de posts
-- extraidos como se fosse o total da conta: esta tabela existe para dizer quanto falta.
-- Origem: trs_instagram__conta, __midia (so flags e datas), __insight_conta e
-- __audiencia_seguidor. Gatilho: evento (regra all) nas quatro. L2.
-- Regras numeradas, validacao e limitacoes: na descricao da transformacao.
--
-- R1 media_count da API e o total historico da conta (denominador de cobertura, nao
-- metrica) · R2 a razao compara FEED+REELS extraidos com media_count; STORY fica fora
-- porque nao se sabe se media_count conta story · R3 zero extraido e fato medido (a tabela
-- existe e veio vazia), nao ausencia · R4 janela de midia e de insight declaradas.
WITH m AS (
  SELECT
    id_conta,
    COUNT(*)                                               AS qtd_midias_extraidas,
    COUNTIF(NOT is_story)                                  AS qtd_feed_reels_extraidos,
    COUNTIF(is_story)                                      AS qtd_stories_extraidos,
    COUNTIF(NOT tem_insight)                               AS qtd_midias_sem_insight,
    MIN(data_local)                                        AS primeira_publicacao_extraida,
    MAX(data_local)                                        AS ultima_publicacao_extraida
  FROM `vanguardamartech_trusted`.`trs_instagram__midia`
  GROUP BY id_conta
),
i AS (
  SELECT
    id_conta,
    COUNT(DISTINCT data_fim_janela)                        AS qtd_dias_com_insight_de_conta,
    MIN(data_fim_janela)                                   AS primeira_data_insight_de_conta,
    MAX(data_fim_janela)                                   AS ultima_data_insight_de_conta
  FROM `vanguardamartech_trusted`.`trs_instagram__insight_conta`
  WHERE janela = 'DIA'
  GROUP BY id_conta
),
a AS (
  SELECT
    id_conta,
    SUM(IF(dimensao = 'IDADE', qtd_seguidores, 0))         AS seguidores_com_idade
  FROM `vanguardamartech_trusted`.`trs_instagram__audiencia_seguidor`
  GROUP BY id_conta
)
SELECT
  c.id_conta,
  c.usuario,
  c._fonte                                                 AS fonte_nekt,
  c.seguidores,
  c.data_snapshot_seguidores,

  -- R1 - o total historico da conta, segundo a API.
  c.qtd_midias_na_conta,

  -- R3 - zero extraido e medido: a tabela de midia existe e pode ter vindo vazia.
  IFNULL(m.qtd_midias_extraidas, 0)                        AS qtd_midias_extraidas,
  IFNULL(m.qtd_feed_reels_extraidos, 0)                    AS qtd_feed_reels_extraidos,
  IFNULL(m.qtd_stories_extraidos, 0)                       AS qtd_stories_extraidos,
  IFNULL(m.qtd_midias_sem_insight, 0)                      AS qtd_midias_sem_insight,
  m.primeira_publicacao_extraida,
  m.ultima_publicacao_extraida,

  -- R2 - cobertura da extracao: FEED+REELS extraidos sobre o historico da conta.
  ROUND(SAFE_DIVIDE(IFNULL(m.qtd_feed_reels_extraidos, 0), NULLIF(c.qtd_midias_na_conta, 0)), 4)
                                                           AS razao_feed_reels_extraidos_sobre_historico,

  -- R4 - a janela que o insight de conta cobre.
  IFNULL(i.qtd_dias_com_insight_de_conta, 0)               AS qtd_dias_com_insight_de_conta,
  i.primeira_data_insight_de_conta,
  i.ultima_data_insight_de_conta,

  -- Quanto da base de seguidores a demografia consegue descrever.
  a.seguidores_com_idade,
  ROUND(SAFE_DIVIDE(a.seguidores_com_idade, NULLIF(c.seguidores, 0)), 4) AS cobertura_demografica_sobre_seguidores,

  (IFNULL(m.qtd_midias_extraidas, 0) = 0)                  AS flag_sem_midia_extraida,
  (IFNULL(m.qtd_feed_reels_extraidos, 0) < c.qtd_midias_na_conta) AS flag_extracao_parcial_do_historico,

  CURRENT_TIMESTAMP()                                      AS _extraido_at,
  'instagram'                                              AS _fonte
FROM `vanguardamartech_trusted`.`trs_instagram__conta` c
LEFT JOIN m ON m.id_conta = c.id_conta
LEFT JOIN i ON i.id_conta = c.id_conta
LEFT JOIN a ON a.id_conta = c.id_conta
