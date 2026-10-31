-- rfn_operacao__blog_mensal  ·  Refined / operacao  ·  573 linhas  ·  L2 INTERNAL
-- Grao: uma CONTA DE ATENDIMENTO em um MES DE COMPETENCIA. Chave: id_blog_mensal.
-- Origens: trs_vjob__blog_pauta (1.323) · trs_vjob__escopo (195.163, so as linhas
--          citadas) · trs_vjob__cliente_atendimento (310).
-- Gatilho: evento em query-8JWf.
-- As regras numeradas e os numeros da validacao estao na descricao da transformacao.
--
-- O ACHADO: **conclusao de escopo NAO prova entrega, e a assimetria e total.**
--   1.182 pautas resolvem escopo. Publicada COM escopo concluido: 954. Publicada SEM
--   escopo concluido: **ZERO**. Escopo concluido SEM pauta publicada: **176** -- e
--   **101 dessas (57%) estao canceladas ou em churn**. A conclusao do escopo e um
--   SUPERCONJUNTO da publicacao: quem contar entrega de blog pela marcacao do escopo
--   conta 176 entregas que nao sairam, 66 delas canceladas pela propria pauta.
--
-- R1 o denominador exclui cancelada e churn: 91,96% sobre as vivas contra 80,42% sobre
--   todas, 11,5 pontos · R2 taxa e NULL, nunca zero, nos **61 pares sem nenhuma pauta
--   viva** · R3 tres contagens de entrega convivem (status 1.064, link 832, data 715) ·
--   R4 a relacao escopo:pauta e N:1 -- **40 escopos recebem mais de uma pauta**, ate 11 ·
--   R5 modulo PARADO: ultimo cadastro 18/12/2025.
--
-- GUARDA DE DATA: `publicado_em < 1900` era sentinela ou ano digitado errado em 4 linhas.
--   A Trusted passou a anular isso em 29/09/2026; enquanto ela nao materializa, a guarda
--   abaixo e que faz a contagem fechar em 715. Depois disso ela e redundante e inofensiva.
--
-- FUSO: relogio local da intranet. NAO CONVERTER.
WITH pauta AS (
  SELECT
    id_pauta, id_atendimento, mes_referencia, id_analista, id_escopo,
    status, is_publicado, is_cancelado, tem_link_publicacao,
    (status = 'churn')                                  AS is_churn,
    link_iclips,
    -- GUARDA DE DATA -- ver o cabecalho.
    IF(publicado_em < DATE '1900-01-01', NULL, publicado_em) AS dt_publicacao
  FROM `vanguardamartech_trusted`.`trs_vjob__blog_pauta`
),
escopo AS (
  SELECT id_escopo, is_concluido
  FROM `vanguardamartech_trusted`.`trs_vjob__escopo`
),
conta AS (
  SELECT DISTINCT id_atendimento, nome_conta, cnpj_digitos, nome_no_cadastro_juridico,
         is_ativo, classe
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`
),
-- O ACHADO: a conclusao do escopo e superconjunto da publicacao. Nada se decide aqui,
-- os dois lados saem contados.
j AS (
  SELECT
    p.*,
    (e.id_escopo IS NOT NULL)                           AS escopo_resolve,
    COALESCE(e.is_concluido, FALSE)                     AS escopo_concluido
  FROM pauta p
  LEFT JOIN escopo e ON e.id_escopo = p.id_escopo
),
agr AS (
  SELECT
    id_atendimento,
    mes_referencia,
    COUNT(*)                                            AS qtd_pautas,
    -- R1 - cancelada e churn saem do denominador. Pauta retirada nao e entrega falhada.
    COUNTIF(NOT is_cancelado AND NOT is_churn)          AS qtd_pautas_vivas,
    COUNTIF(is_cancelado)                               AS qtd_canceladas,
    COUNTIF(is_churn)                                   AS qtd_churn,
    -- R3 - tres contagens de entrega, da mais fraca para a mais forte.
    COUNTIF(is_publicado)                               AS qtd_publicadas_declaradas,
    COUNTIF(is_publicado AND tem_link_publicacao)       AS qtd_publicadas_com_prova,
    COUNTIF(dt_publicacao IS NOT NULL)                  AS qtd_com_data_publicacao,
    COUNTIF(tem_link_publicacao)                        AS qtd_com_link,
    COUNTIF(NOT is_publicado AND NOT is_cancelado AND NOT is_churn)
                                                        AS qtd_em_fluxo,
    -- R4 - N:1. Pauta e escopo nao se contam um pelo outro.
    COUNTIF(id_escopo IS NOT NULL)                      AS qtd_pautas_com_escopo,
    COUNT(DISTINCT id_escopo)                           AS qtd_escopos_citados,
    COUNTIF(escopo_concluido)                           AS qtd_escopo_concluido,
    -- O ACHADO, nas duas direcoes.
    COUNTIF(escopo_concluido AND NOT is_publicado)      AS qtd_escopo_concluido_sem_publicacao,
    COUNTIF(is_publicado AND escopo_resolve AND NOT escopo_concluido)
                                                        AS qtd_publicada_sem_escopo_concluido,
    COUNTIF(escopo_concluido AND (is_cancelado OR is_churn))
                                                        AS qtd_escopo_concluido_com_pauta_morta,
    COUNT(DISTINCT id_analista)                         AS qtd_analistas,
    COUNTIF(link_iclips IS NOT NULL)                    AS qtd_com_link_iclips,
    MIN(dt_publicacao)                                  AS primeira_publicacao,
    MAX(dt_publicacao)                                  AS ultima_publicacao
  FROM j
  GROUP BY 1, 2
)
SELECT
  FORMAT('%d:%t', a.id_atendimento, a.mes_referencia)   AS id_blog_mensal,
  a.id_atendimento,
  c.nome_conta,
  c.cnpj_digitos                                        AS cliente_cnpj,
  c.nome_no_cadastro_juridico,
  c.classe                                              AS classe_da_conta,
  c.is_ativo                                            AS conta_ativa_hoje,
  (c.id_atendimento IS NULL)                            AS flag_conta_nao_catalogada,
  (c.cnpj_digitos IS NULL)                              AS flag_sem_cnpj,

  a.mes_referencia,
  EXTRACT(YEAR FROM a.mes_referencia)                   AS ano_referencia,

  a.qtd_pautas,
  a.qtd_pautas_vivas,
  a.qtd_canceladas,
  a.qtd_churn,
  a.qtd_em_fluxo,

  a.qtd_publicadas_declaradas,
  a.qtd_publicadas_com_prova,
  a.qtd_com_data_publicacao,
  a.qtd_com_link,

  -- R2 - sem pauta viva a taxa e NULL, nunca zero. Sao 61 pares.
  IF(a.qtd_pautas_vivas = 0, NULL,
     ROUND(SAFE_DIVIDE(a.qtd_publicadas_declaradas, a.qtd_pautas_vivas), 4))
                                                        AS taxa_publicacao_declarada,
  IF(a.qtd_pautas_vivas = 0, NULL,
     ROUND(SAFE_DIVIDE(a.qtd_publicadas_com_prova, a.qtd_pautas_vivas), 4))
                                                        AS taxa_publicacao_com_prova,
  (a.qtd_pautas_vivas = 0)                              AS flag_sem_pauta_viva,

  a.qtd_pautas_com_escopo,
  a.qtd_escopos_citados,
  a.qtd_escopo_concluido,
  a.qtd_escopo_concluido_sem_publicacao,
  a.qtd_publicada_sem_escopo_concluido,
  a.qtd_escopo_concluido_com_pauta_morta,
  -- R4 - N:1. Quando difere, mais de uma pauta cita o mesmo escopo.
  (a.qtd_pautas_com_escopo > a.qtd_escopos_citados)     AS flag_escopo_compartilhado,

  a.qtd_analistas,
  a.qtd_com_link_iclips,
  a.primeira_publicacao,
  a.ultima_publicacao,

  CURRENT_TIMESTAMP()                                   AS _extraido_at,
  'mysql-yIOn'                                          AS _fonte,
  'America/Sao_Paulo'                                   AS _fuso
FROM agr a
LEFT JOIN conta c ON c.id_atendimento = a.id_atendimento
