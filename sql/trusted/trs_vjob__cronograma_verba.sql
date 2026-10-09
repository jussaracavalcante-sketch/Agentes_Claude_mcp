-- trs_vjob__cronograma_verba
-- A quebra do contrato de VEICULACAO DE MIDIA ON por veiculo.
--
-- ESTE DINHEIRO NAO E NOVO: em 35 dos 37 contratos catalogados a soma das verbas
-- e EXATAMENTE o valor do contrato (R$ 323.274,29 dos dois lados). Somar verba com
-- parcela duplica. O aditivo continua sendo a parcela.
--
-- FUSO: o VJOB grava relogio local. Nada se converte.
WITH origem AS (
  SELECT
    id                                                          AS id_verba,
    cronograma_id                                               AS id_contrato,
    NULLIF(fornecedor_id, 0)                                    AS id_fornecedor,
    valor                                                       AS valor_verba,
    ordem,
    criado_em,
    atualizado_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbcronograma_on_verbas`
),
fornecedor AS (
  SELECT DISTINCT id AS id_fornecedor, NULLIF(TRIM(nomefornecedor), '') AS nome
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbfornecedorescronograma`
),
contrato AS (
  SELECT
    id_cronograma, id_cliente, cliente, cliente_cnpj, servico,
    tipo_cronograma_codigo, id_fornecedor AS id_fornecedor_cabecalho,
    valor_contrato_calculado, competencia
  FROM `vanguardamartech_trusted`.`trs_vjob__cronograma`
),
-- REGRA 3 - o total por contrato sai denormalizado para a conferencia nao exigir join.
por_contrato AS (
  SELECT id_contrato, SUM(valor_verba) AS valor_verba_total, COUNT(*) AS qtd_verbas
  FROM origem GROUP BY id_contrato
),
prep AS (
  SELECT
    o.*,
    f.nome                                                      AS fornecedor_nome,
    (o.id_fornecedor IS NOT NULL AND f.id_fornecedor IS NULL)   AS fornecedor_ausente,
    c.id_cliente, c.cliente, c.cliente_cnpj, c.servico,
    c.tipo_cronograma_codigo, c.id_fornecedor_cabecalho,
    c.valor_contrato_calculado, c.competencia                   AS competencia_do_contrato,
    (c.id_cronograma IS NULL)                                   AS contrato_ausente,
    g.valor_verba_total, g.qtd_verbas
  FROM origem o
  -- ANTI-JOIN por CTE DISTINCT, nao `NOT EXISTS` correlacionado.
  LEFT JOIN fornecedor   f ON f.id_fornecedor = o.id_fornecedor
  LEFT JOIN contrato     c ON c.id_cronograma = o.id_contrato
  LEFT JOIN por_contrato g ON g.id_contrato   = o.id_contrato
),
tratado AS (
  SELECT
    p.id_verba,
    p.id_contrato,

    -- REGRA 1 - escopo medido: todos de tipo 1 e servico VEICULACAO DE MIDIA ON.
    p.tipo_cronograma_codigo,
    p.servico,
    p.id_cliente,
    p.cliente,
    p.cliente_cnpj,
    p.competencia_do_contrato,

    -- REGRA 4 - zero e sentinela de fornecedor, nao id.
    p.id_fornecedor,
    p.fornecedor_nome,
    p.ordem,

    p.valor_verba,

    -- REGRA 3 - o contrato inteiro ao lado, para nao precisar de join na conferencia.
    p.valor_verba_total                                         AS valor_verba_total_no_contrato,
    p.qtd_verbas                                                AS qtd_verbas_no_contrato,
    p.valor_contrato_calculado,
    (p.valor_contrato_calculado IS NOT NULL
      AND ABS(p.valor_verba_total - p.valor_contrato_calculado) < 0.01)
                                                                AS flag_verba_fecha_o_contrato,
    CASE
      WHEN p.valor_contrato_calculado IS NULL THEN NULL
      ELSE ROUND(p.valor_verba_total - p.valor_contrato_calculado, 2)
    END                                                         AS diferenca_para_o_contrato,

    -- REGRA 2 - INVARIANTE: o fornecedor do cabecalho esta sempre entre os da verba.
    -- ZERO contratos em que ele fica de fora, medido em 2026-09-25.
    (p.id_fornecedor_cabecalho IS NOT NULL
      AND p.id_fornecedor_cabecalho = p.id_fornecedor)          AS flag_e_fornecedor_do_cabecalho,
    p.id_fornecedor_cabecalho,

    -- FUSO: relogio local. Nao converter.
    p.criado_em,
    p.atualizado_em,
    (p.atualizado_em IS NOT NULL AND p.atualizado_em <> p.criado_em)
                                                                AS flag_ja_editada,

    p.contrato_ausente                                          AS flag_contrato_nao_catalogado,
    p.fornecedor_ausente                                        AS flag_fornecedor_nao_catalogado
  FROM prep p
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'mysql-yIOn'                                                  AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                                AS _payload_hash
FROM tratado t
