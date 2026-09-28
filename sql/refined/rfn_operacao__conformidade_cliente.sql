-- rfn_operacao__conformidade_cliente
-- Refined / dominio Operacao. Grao: uma origem, um cliente, um mes de referencia.
--
-- CORRECAO 2026-09-24: AS DUAS ORIGENS ERAM RESOLVIDAS CONTRA A MESMA DIMENSAO, e uma
--   delas era a errada. O `id_cliente` da AUDITORIA e da conta de atendimento; o da
--   ETAPA e do cadastro juridico. O join unico no fim casava os dois contra
--   `trs_vjob__cliente` e, dos 46 ids da auditoria, 20 encontravam par -- com o nome
--   DIVERGENTE nos vinte. Nao era falta de dado, era IDENTIDADE TROCADA.
--   Agora cada origem resolve contra a sua dimensao, dentro da propria CTE.
--   Ver a descricao da transformacao.
--
-- `id_cliente` NAO ATRAVESSA ORIGEM: atendimento na AUDITORIA, juridico na ETAPA.
--   A coluna comparavel entre instrumentos e `cnpj_digitos`.
--
-- R1 mes do PRAZO · R2 denominador ATIVO · R3 zero e NULL · R4 pontualidade sobre o
-- marcado · R5 mes futuro entra marcado · R6 documento de 14 digitos ·
-- R7 identidade POR ORIGEM.
--
-- FUSO: NADA SE CONVERTE. `DATE()` sem argumento.
WITH item AS (
  -- AUDITORIA -- a identidade ja vem resolvida da Trusted, que le
  -- `trs_vjob__cliente_atendimento`. ZERO orfaos em 3.025.
  SELECT
    'AUDITORIA'                     AS origem,
    a.id_cliente                    AS id_cliente,
    a.id_cliente_juridico           AS id_cliente_juridico,
    a.cliente_nome                  AS cliente_nome,
    a.cnpj_digitos                  AS cnpj_digitos,
    a.flag_cliente_nao_catalogado   AS flag_cliente_nao_catalogado,
    a.prazo                         AS prazo,
    -- R2: o inativo sai do denominador. 1.462 itens inativos com 2 marcados.
    COALESCE(a.is_ativo, FALSE)     AS is_item_ativo,
    a.is_feito                      AS is_marcado,
    a.marcado_em,
    a.quem_marcou
  FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_cliente` a
  UNION ALL
  -- ETAPA -- esta sim pende do cadastro juridico. Medido: 882 orfaos contra
  -- `trs_vjob__cliente` e 1.856 contra o atendimento, entao o pai e este mesmo.
  SELECT
    'ETAPA',
    e.id_cliente,
    cl.id_cliente,
    cl.cliente,
    cl.cnpj_digitos,
    (cl.id_cliente IS NULL),
    e.data_etapa,
    -- COALESCE e obrigatorio: `is_ativa` e NULL (nao FALSE) nas 3.790 nunca ativadas,
    -- e NOT NULL continuaria NULL, deixando-as fora da contagem em vez de no inativo.
    COALESCE(e.is_ativa, FALSE),
    e.is_marcada,
    e.marcado_em,
    e.quem_marcou
  FROM `vanguardamartech_trusted`.`trs_vjob__etapa_cliente` e
  LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__cliente` cl
    ON cl.id_cliente = e.id_cliente
),
classificado AS (
  SELECT
    i.*,
    -- R1: o mes e o do PRAZO. Item sem prazo fica com mes NULL e nao some.
    DATE_TRUNC(i.prazo, MONTH)                                   AS mes_referencia,
    (i.prazo IS NULL)                                            AS flag_sem_prazo,
    -- R4: pontualidade so existe para item marcado E com prazo.
    (i.is_marcado AND i.prazo IS NOT NULL
       AND DATE(i.marcado_em) <= i.prazo)                        AS is_marcado_ate_prazo,
    (i.is_marcado AND i.prazo IS NOT NULL
       AND DATE(i.marcado_em) >  i.prazo)                        AS is_marcado_apos_prazo
  FROM item i
),
-- R3: a janela inteira decide se o cliente tem registro, nao o mes.
registro_cliente AS (
  SELECT origem, id_cliente, LOGICAL_OR(is_marcado) AS tem_alguma_marcacao
  FROM classificado GROUP BY origem, id_cliente
),
agregado AS (
  SELECT
    c.origem,
    c.id_cliente,
    -- R7: identidade resolvida por origem, carregada ate aqui. MAX sobre valor constante
    -- dentro do grupo -- o cliente nao muda dentro de (origem, id_cliente, mes).
    MAX(c.id_cliente_juridico)                      AS id_cliente_juridico,
    MAX(c.cliente_nome)                             AS cliente_nome,
    MAX(c.cnpj_digitos)                             AS cnpj_digitos,
    LOGICAL_OR(c.flag_cliente_nao_catalogado)       AS flag_cliente_nao_catalogado,
    c.mes_referencia,
    LOGICAL_OR(c.flag_sem_prazo)                    AS flag_sem_prazo,
    COUNT(*)                                        AS qtd_itens,
    COUNTIF(c.is_item_ativo)                        AS qtd_itens_ativos,
    COUNTIF(NOT c.is_item_ativo)                    AS qtd_itens_inativos,
    COUNTIF(c.is_marcado)                           AS qtd_marcados,
    -- Numerador e denominador precisam falar do MESMO conjunto. 2 marcacoes da auditoria
    -- e 1 da etapa caem sobre item INATIVO; elas contam em qtd_marcados e ficam fora da
    -- taxa. Sem isto a taxa da auditoria sairia 98,78% em vez de 98,66%.
    COUNTIF(c.is_marcado AND c.is_item_ativo)       AS qtd_marcados_ativos,
    COUNTIF(c.is_marcado_ate_prazo)                 AS qtd_marcados_ate_prazo,
    COUNTIF(c.is_marcado_apos_prazo)                AS qtd_marcados_apos_prazo,
    MIN(c.marcado_em)                               AS primeira_marcacao,
    MAX(c.marcado_em)                               AS ultima_marcacao,
    COUNT(DISTINCT c.quem_marcou)                   AS qtd_pessoas_marcaram
  FROM classificado c
  GROUP BY c.origem, c.id_cliente, c.mes_referencia
)
SELECT
  a.origem,
  -- ATENCAO: id nativo da origem. Nao comparar atravessando `origem`.
  a.id_cliente,
  a.id_cliente_juridico,
  a.cliente_nome,
  a.cnpj_digitos,
  a.flag_cliente_nao_catalogado,
  (NOT a.flag_cliente_nao_catalogado
     AND a.cnpj_digitos IS NULL)                    AS flag_cliente_sem_cnpj,
  a.mes_referencia,
  a.flag_sem_prazo,
  -- R5: mes futuro entra, marcado. Nada e descartado por data.
  COALESCE(a.mes_referencia > DATE_TRUNC(CURRENT_DATE(), MONTH), FALSE) AS is_mes_futuro,
  a.qtd_itens,
  a.qtd_itens_ativos,
  a.qtd_itens_inativos,
  a.qtd_marcados,
  a.qtd_marcados_ativos,
  a.qtd_marcados_ate_prazo,
  a.qtd_marcados_apos_prazo,
  -- R2 + R3: denominador ATIVO, e NULL (nunca zero) para cliente sem registro na janela.
  IF(NOT r.tem_alguma_marcacao OR a.qtd_itens_ativos = 0,
     NULL,
     ROUND(SAFE_DIVIDE(a.qtd_marcados_ativos, a.qtd_itens_ativos), 4))  AS taxa_conclusao,
  -- R4: denominador e o MARCADO. Sem marcacao no mes nao ha pontualidade.
  IF(a.qtd_marcados = 0,
     NULL,
     ROUND(SAFE_DIVIDE(a.qtd_marcados_ate_prazo, a.qtd_marcados), 4))  AS taxa_pontualidade,
  NOT r.tem_alguma_marcacao                         AS is_cliente_sem_registro,
  a.primeira_marcacao,
  a.ultima_marcacao,
  a.qtd_pessoas_marcaram,
  CURRENT_TIMESTAMP()                               AS _extraido_at,
  'mysql-yIOn'                                      AS _fonte
FROM agregado a
JOIN registro_cliente r
  ON r.origem = a.origem AND r.id_cliente = a.id_cliente
