-- trs_vjob__blog_pauta
-- Trusted / VJOB. Grao: uma pauta de blog. Chave: id_pauta.
-- Origem: mysql-yIOn, `tbblogs` (1.323). L2 INTERNAL.
--
-- A unica tabela desta base que liga entrega a linha de escopo: `id_escopo`
-- resolve 1.183 de 1.323 com 1 orfao. Ver a descricao.
--
-- CORRIGIDO EM 29/09/2026: `publicado_em` trazia 4 datas fora de qualquer periodo
-- real -- 2 sentinelas `0001-01-01` e 2 com o ano digitado como `0205` em vez de
-- `2025`. `tem_data_publicacao` acendia nas quatro. Agora a coluna so carrega data
-- valida (715, era 719), o cru fica em `publicado_em_origem` e o candidato corrigido
-- fica FORA da medida. Marcar, nunca apagar.
WITH b AS (SELECT * FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbblogs`),
atd AS (SELECT DISTINCT id_atendimento FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`),
esc AS (SELECT DISTINCT id_escopo FROM `vanguardamartech_trusted`.`trs_vjob__escopo`),
prep AS (
  SELECT
    b.id                                    AS id_pauta,
    -- O cliente aqui e a CONTA DE ATENDIMENTO: 2 orfaos contra 252 se fosse tbclientes.
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
    -- 4 datas invalidas: 2 sentinelas `0001-01-01` e 2 com ano `0205`.
    -- O cru fica; a medida so recebe data que existe.
    b.datapublicacao                        AS publicado_em_origem,
    IF(b.datapublicacao < DATE '1900-01-01', NULL, b.datapublicacao) AS publicado_em,
    -- FUSO: relogio local. Nao converter.
    b.datacadastro                          AS cadastrado_em,
    NULLIF(b.quemcadastrou, 0)              AS cadastrado_por,
    NULLIF(b.id_escopo, 0)                  AS id_escopo
  FROM b
),
tratado AS (
  SELECT
    p.*,
    -- Status e declaracao; link e evidencia. 1.064 x 849 x 715.
    (p.status = 'publicado')                              AS is_publicado,
    (p.status = 'cancelado')                              AS is_cancelado,
    (p.link_publicacao IS NOT NULL)                       AS tem_link_publicacao,
    (p.publicado_em IS NOT NULL)                          AS tem_data_publicacao,
    (p.publicado_em_origem IS NOT NULL AND p.publicado_em IS NULL)
                                                          AS flag_data_publicacao_invalida,
    -- CANDIDATO, FORA DA MEDIDA. Duas rotas independentes dao a MESMA data:
    -- ler `0205` como `2025`, e completar o ano pela competencia da propria linha.
    -- Nao entra em `publicado_em` -- a casa ja recusou correcao aritmetica sozinha
    -- no telefone do SMS; aqui ela e corroborada, e mesmo assim fica declarada ao lado.
    IF(p.publicado_em IS NULL AND p.publicado_em_origem IS NOT NULL
         AND p.publicado_em_origem <> DATE '0001-01-01' AND p.mes_referencia IS NOT NULL,
       DATE(EXTRACT(YEAR  FROM p.mes_referencia),
            EXTRACT(MONTH FROM p.publicado_em_origem),
            EXTRACT(DAY   FROM p.publicado_em_origem)),
       NULL)                                              AS candidato_data_publicacao_corrigida,
    (p.id_escopo IS NULL)                                 AS flag_escopo_ausente,
    (p.id_escopo IS NOT NULL AND e.id_escopo IS NULL)     AS flag_escopo_nao_catalogado,
    (a.id_atendimento IS NULL)                            AS flag_conta_nao_catalogada
  FROM prep p
  LEFT JOIN esc e ON e.id_escopo = p.id_escopo
  LEFT JOIN atd a ON a.id_atendimento = p.id_atendimento
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()             AS _extraido_at,
  'mysql-yIOn'                    AS _fonte,
  'America/Sao_Paulo'             AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))  AS _payload_hash
FROM tratado t
