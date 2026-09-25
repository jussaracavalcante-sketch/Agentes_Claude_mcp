-- trs_vjob__blog_pauta  ·  query-8JWf  ·  1.323 linhas  ·  L2 INTERNAL
-- Trusted / VJOB. Grao: uma pauta de blog. Chave: id_pauta.
-- Origem: mysql-yIOn, `tbblogs`. Gatilho: evento em query-TkGA.
--
-- E A UNICA TABELA DESTA BASE QUE LIGA UMA ENTREGA A LINHA DE ESCOPO QUE A PEDIU:
--   id_escopo resolve 1.183 de 1.323 (89,4%) com 1 orfao. Carrega tambem link_iclips,
--   uma segunda ponte para fora do VJOB.
-- MODULO PARADO: ultimo cadastro 18/12/2025, ultima publicacao 02/10/2025.
-- "PUBLICADO" E DECLARACAO, NAO PROVA: 1.064 com status publicado, 849 com link,
--   719 com data. A evidencia e o link.
-- O cliente e a CONTA DE ATENDIMENTO: 2 orfaos, contra 252 se fosse tbclientes.
WITH b AS (SELECT * FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbblogs`),
atd AS (SELECT DISTINCT id_atendimento FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`),
esc AS (SELECT DISTINCT id_escopo FROM `vanguardamartech_trusted`.`trs_vjob__escopo`),
prep AS (
  SELECT
    b.id                                    AS id_pauta,
    NULLIF(b.cliente, 0)                    AS id_atendimento,
    NULLIF(b.analista, 0)                   AS id_analista,
    b.mesano                                AS mes_referencia,
    NULLIF(TRIM(b.pauta), '')               AS pauta,
    NULLIF(TRIM(b.palavrachave), '')        AS palavra_chave,
    NULLIF(TRIM(b.status), '')              AS status,
    NULLIF(TRIM(b.linkblog), '')            AS link_publicacao,
    NULLIF(TRIM(b.linkiclips), '')          AS link_iclips,
    NULLIF(TRIM(b.linkdrive), '')           AS link_drive,
    NULLIF(TRIM(b.observacoes), '')         AS observacoes,
    NULLIF(TRIM(b.motivo_cancelamento), '') AS motivo_cancelamento,
    b.datapublicacao                        AS publicado_em,
    b.datacadastro                          AS cadastrado_em,
    NULLIF(b.quemcadastrou, 0)              AS cadastrado_por,
    NULLIF(b.id_escopo, 0)                  AS id_escopo
  FROM b
),
tratado AS (
  SELECT
    p.*,
    (p.status = 'publicado')                              AS is_publicado,
    (p.status = 'cancelado')                              AS is_cancelado,
    (p.link_publicacao IS NOT NULL)                       AS tem_link_publicacao,
    (p.publicado_em IS NOT NULL)                          AS tem_data_publicacao,
    (p.id_escopo IS NULL)                                 AS flag_escopo_ausente,
    (p.id_escopo IS NOT NULL AND e.id_escopo IS NULL)     AS flag_escopo_nao_catalogado,
    (a.id_atendimento IS NULL)                            AS flag_conta_nao_catalogada
  FROM prep p
  LEFT JOIN esc e ON e.id_escopo = p.id_escopo
  LEFT JOIN atd a ON a.id_atendimento = p.id_atendimento
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
