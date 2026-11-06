-- rfn_operacao__issue_mensal
-- Trabalho INTERNO da agencia por projeto e mes, do Linear.
--
-- A FONTE ESTA PARADA EM DOIS MOMENTOS: ultima issue criada 28/07/2026, ultima
-- CONCLUSAO 25/06/2026. Julho tem 12 criadas e zero concluidas. Historico, nao
-- acompanhamento de trabalho corrente.
WITH issue AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_linear__issue`
),
-- REGRA 5 - o balde "(sem projeto)" e uma unidade de verdade: 26 das 230.
unidade AS (
  SELECT DISTINCT
    IFNULL(id_projeto, '(sem projeto)')                         AS id_unidade,
    IFNULL(projeto_nome, '(sem projeto)')                       AS projeto,
    flag_sem_projeto
  FROM issue
),
meses AS (
  SELECT DISTINCT m FROM (
    SELECT DATE_TRUNC(dt_criacao, MONTH)               AS m FROM issue
    UNION ALL
    SELECT DATE_TRUNC(DATE(concluida_em), MONTH)       AS m FROM issue WHERE concluida_em IS NOT NULL
  )
  WHERE m IS NOT NULL
),
grade AS (
  SELECT u.id_unidade, u.projeto, u.flag_sem_projeto, m.m AS mes_referencia
  FROM unidade u CROSS JOIN meses m
),
-- REGRA 1 - populacao A: issue que NASCEU no mes. Daqui sai a coorte.
criacao AS (
  SELECT
    IFNULL(id_projeto, '(sem projeto)')                         AS id_unidade,
    DATE_TRUNC(dt_criacao, MONTH)                               AS mes_referencia,
    COUNT(*)                                                    AS qtd_criadas,
    COUNTIF(is_concluida)                                       AS qtd_criadas_ja_concluidas,
    COUNTIF(is_cancelada)                                       AS qtd_canceladas,
    COUNTIF(is_subtarefa)                                       AS qtd_subtarefas,
    COUNTIF(NOT flag_sem_responsavel)                           AS qtd_com_responsavel,
    COUNTIF(dt_prazo IS NOT NULL)                               AS qtd_com_prazo
  FROM issue
  GROUP BY id_unidade, mes_referencia
),
-- REGRA 1 - populacao B: issue CONCLUIDA no mes, tenha nascido quando tiver.
conclusao AS (
  SELECT
    IFNULL(id_projeto, '(sem projeto)')                         AS id_unidade,
    DATE_TRUNC(DATE(concluida_em), MONTH)                       AS mes_referencia,
    COUNT(*)                                                    AS qtd_concluidas,
    -- REGRA 2 - a invariante: hoje ZERO atravessam o mes.
    COUNTIF(DATE_TRUNC(dt_criacao, MONTH) <> DATE_TRUNC(DATE(concluida_em), MONTH))
                                                                AS qtd_atravessam_mes,
    ROUND(AVG(dias_ate_conclusao), 2)                           AS dias_ate_conclusao_medio,
    MAX(dias_ate_conclusao)                                     AS dias_ate_conclusao_maximo,
    COUNTIF(dias_ate_conclusao = 0)                             AS qtd_concluidas_no_mesmo_dia
  FROM issue
  WHERE concluida_em IS NOT NULL
  GROUP BY id_unidade, mes_referencia
),
tratado AS (
  SELECT
    CONCAT(g.id_unidade, ':', FORMAT_DATE('%Y-%m', g.mes_referencia)) AS id_issue_mensal,
    g.mes_referencia,
    g.id_unidade,
    g.projeto,
    g.flag_sem_projeto,

    -- REGRA 1 - populacao A
    IFNULL(c.qtd_criadas, 0)                                    AS qtd_criadas_no_mes,
    IFNULL(c.qtd_criadas_ja_concluidas, 0)                      AS qtd_criadas_no_mes_ja_concluidas,
    IFNULL(c.qtd_canceladas, 0)                                 AS qtd_canceladas_no_mes,
    IFNULL(c.qtd_subtarefas, 0)                                 AS qtd_subtarefas_no_mes,
    IFNULL(c.qtd_com_responsavel, 0)                            AS qtd_com_responsavel,
    IFNULL(c.qtd_com_prazo, 0)                                  AS qtd_com_prazo,

    -- REGRA 1 - populacao B. NAO dividir a de baixo pela de cima.
    IFNULL(o.qtd_concluidas, 0)                                 AS qtd_concluidas_no_mes,

    -- REGRA 3 - zero de conclusao e NULL, nunca zero.
    CASE
      WHEN IFNULL(c.qtd_criadas, 0) = 0 THEN NULL
      ELSE ROUND(SAFE_DIVIDE(c.qtd_criadas_ja_concluidas, c.qtd_criadas), 4)
    END                                                         AS taxa_conclusao_coorte,

    o.dias_ate_conclusao_medio,
    o.dias_ate_conclusao_maximo,
    IFNULL(o.qtd_concluidas_no_mesmo_dia, 0)                    AS qtd_concluidas_no_mesmo_dia,

    -- REGRA 2 - a guarda. Se acender, fluxo e coorte deixam de coincidir.
    (IFNULL(o.qtd_atravessam_mes, 0) > 0)                       AS flag_conclusao_atravessa_mes,
    IFNULL(o.qtd_atravessam_mes, 0)                             AS qtd_conclusoes_de_outro_mes,

    (IFNULL(c.qtd_criadas, 0) > 0 AND IFNULL(o.qtd_concluidas, 0) = 0)
                                                                AS flag_mes_sem_conclusao
  FROM grade g
  LEFT JOIN criacao   c ON c.id_unidade = g.id_unidade AND c.mes_referencia = g.mes_referencia
  LEFT JOIN conclusao o ON o.id_unidade = g.id_unidade AND o.mes_referencia = g.mes_referencia
  -- REGRA 4 - mes sem criacao e sem conclusao nao produz linha (23 das 36 da grade).
  WHERE IFNULL(c.qtd_criadas, 0) > 0 OR IFNULL(o.qtd_concluidas, 0) > 0
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'linear-byrt'                                                 AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                                AS _payload_hash
FROM tratado t
