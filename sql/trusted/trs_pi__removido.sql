-- trs_pi__removido
-- Trusted / PI. Grao: um PI (pedido de insercao) que SUMIU do arquivo de PI numa carga do Supabase, com a fotografia JSON do PI no momento da remocao desaninhada em colunas.
-- Chave: id_pi (74 linhas, 74 chaves; medido em 2026-10-19).
-- Origem: vanguardamartech_raw.supabase_meta_pi_removida (fonte supabase-x0tz, diaria). Cadencia desta Trusted: semanal (segunda 07:15 America/Manaus).
-- Nivel: L4 PERSONAL_DATA (nome do responsavel interno pelo PI; cliente e veiculo sao PJ).
-- MEDIDO (2026-10-19): os 74 foram removidos na MESMA carga (run pi-excel-20260706T115356, 2026-07-06 15:54 UTC) e 73 REAPARECERAM em 2026-07-07 22:23 UTC - so 1 continua
--   fora. 73 de 74 existem hoje em trs_pi__insercao (id_pi): foi uma falha de UMA carga do arquivo, nao exclusao de PI. 10 clientes · faturamento: Aguardando Faturamento,
--   Cancelado, Sem Faturamento · valor_negociado R$ 500.322,50 · tipos de midia: TV*, Radio*, Outdoor*, TV Indoor, OOH.
-- JSON MISTO: `valor_negociado`, `valor_liquido`, `valor_comissao_veiculo` e `valor_faturado_cliente` chegam ora numero ora texto (SAFE_CAST) · `cnpj_veiculo` chega como NUMERO
--   em 25 linhas (13 digitos: perdeu o zero a esquerda) e como texto com mascara nas outras · `data_aprovacao_proposta` chega como SERIAL DO EXCEL (46057 = 2026-02-03) em 37 linhas.
-- DOCUMENTO: so 14 digitos e CNPJ. O LPAD dos 13 digitos (04642799000170 Radio Taruma, 04382099000194 TV A Critica) so e aceito porque o valor corrigido JA EXISTE entre os
--   cnpj_veiculo de 14 digitos de trs_pi__insercao (autoridade: o conjunto de documentos validos do mesmo sistema; dentro desta tabela eles nao existiam em 14). flag_cnpj_veiculo_repadronizado.
-- LIMITACOES - NAO CONTORNE: e historico de UMA carga; a fotografia e a do dia 06/07/2026 e pode divergir do PI vigente em trs_pi__insercao; `data_veiculacao` e texto livre
--   ("24/08/2026 a 06/09/2026") e NAO foi parseada; `vencimento` e texto de instrucao de nota, nao data.
WITH origem AS (
  SELECT
    p.pi,
    p.removido_em,
    p.reaparecido_em,
    p.run_ref,
    p.atualizado_em,
    SAFE.PARSE_JSON(p.snapshot)                                      AS s
  FROM `vanguardamartech_raw`.`supabase_meta_pi_removida` p
),
campos AS (
  SELECT
    o.*,
    NULLIF(REGEXP_REPLACE(IFNULL(JSON_VALUE(s, '$.cnpj_veiculo'), ''), r'[^0-9]', ''), '') AS cnpj_veiculo_digitos
  FROM origem o
),
docs14 AS (
  SELECT DISTINCT cnpj_veiculo AS d FROM `vanguardamartech_trusted`.`trs_pi__insercao` WHERE LENGTH(cnpj_veiculo) = 14
),
pi_atual AS (
  SELECT DISTINCT id_pi FROM `vanguardamartech_trusted`.`trs_pi__insercao`
),
final AS (
  SELECT
    c.pi                                                             AS id_pi,
    c.run_ref,
    c.removido_em,
    DATETIME(c.removido_em, 'America/Sao_Paulo')                     AS removido_em_local,
    c.reaparecido_em,
    DATETIME(c.reaparecido_em, 'America/Sao_Paulo')                  AS reaparecido_em_local,
    (c.reaparecido_em IS NOT NULL)                                   AS flag_reapareceu,
    (a.id_pi IS NOT NULL)                                            AS flag_existe_no_pi_atual,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.cliente')), '')                   AS cliente,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.veiculo')), '')                   AS veiculo,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.razao_social_veiculo')), '')      AS razao_social_veiculo,
    CASE
      WHEN LENGTH(c.cnpj_veiculo_digitos) = 14 THEN c.cnpj_veiculo_digitos
      WHEN LENGTH(c.cnpj_veiculo_digitos) = 13 AND d.d IS NOT NULL THEN d.d
    END                                                              AS cnpj_veiculo,
    JSON_VALUE(c.s, '$.cnpj_veiculo')                                AS cnpj_veiculo_origem,
    (LENGTH(c.cnpj_veiculo_digitos) = 13 AND d.d IS NOT NULL)        AS flag_cnpj_veiculo_repadronizado,
    (c.cnpj_veiculo_digitos IS NOT NULL AND LENGTH(c.cnpj_veiculo_digitos) <> 14 AND NOT (LENGTH(c.cnpj_veiculo_digitos) = 13 AND d.d IS NOT NULL))
                                                                     AS flag_cnpj_veiculo_invalido,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.tipo_midia')), '')                AS tipo_midia,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.praca')), '')                     AS praca,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.prazo')), '')                     AS prazo,
    SAFE_CAST(JSON_VALUE(c.s, '$.insercoes') AS INT64)               AS insercoes,
    SAFE_CAST(JSON_VALUE(c.s, '$.valor_negociado') AS FLOAT64)       AS valor_negociado,
    SAFE_CAST(JSON_VALUE(c.s, '$.valor_liquido') AS FLOAT64)         AS valor_liquido,
    SAFE_CAST(JSON_VALUE(c.s, '$.valor_comissao_veiculo') AS FLOAT64) AS valor_comissao_veiculo,
    SAFE_CAST(JSON_VALUE(c.s, '$.valor_faturado_cliente') AS FLOAT64) AS valor_faturado_cliente,
    SAFE_CAST(JSON_VALUE(c.s, '$.desc_padrao_pct') AS FLOAT64)       AS desc_padrao_pct,
    SAFE_CAST(JSON_VALUE(c.s, '$.numero_projeto') AS INT64)          AS numero_projeto,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.nome_projeto')), '')              AS nome_projeto,
    SAFE_CAST(JSON_VALUE(c.s, '$.numero_proposta') AS INT64)         AS numero_proposta,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.status_proposta')), '')           AS status_proposta,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.status_midia')), '')              AS status_midia,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.faturamento')), '')               AS status_faturamento,
    (JSON_VALUE(c.s, '$.faturamento') = 'Cancelado' OR JSON_VALUE(c.s, '$.status_midia') = 'Cancelado') AS is_cancelado_na_fotografia,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.responsavel')), '')               AS responsavel,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.data_veiculacao')), '')           AS data_veiculacao_texto,
    IF(SAFE_CAST(JSON_VALUE(c.s, '$.data_aprovacao_proposta') AS INT64) BETWEEN 40000 AND 60000,
       DATE_ADD(DATE '1899-12-30', INTERVAL SAFE_CAST(JSON_VALUE(c.s, '$.data_aprovacao_proposta') AS INT64) DAY), NULL)
                                                                     AS data_aprovacao_proposta,
    JSON_VALUE(c.s, '$.data_aprovacao_proposta')                     AS data_aprovacao_proposta_origem,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.nf_agencia')), '')                AS nf_agencia,
    NULLIF(TRIM(JSON_VALUE(c.s, '$.nf_fornecedor')), '')             AS nf_fornecedor,
    c.atualizado_em
  FROM campos c
  LEFT JOIN docs14 d ON LENGTH(c.cnpj_veiculo_digitos) = 13 AND d.d = LPAD(c.cnpj_veiculo_digitos, 14, '0')
  LEFT JOIN pi_atual a ON a.id_pi = c.pi
)
SELECT
  f.*,
  'L4_PERSONAL_DATA'                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
