-- rfn_financeiro__contazul_entidade_resumo  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (a Trusted e L4; nome e documento NAO atravessam)
-- Grao: um papel (CLIENTE/FORNECEDOR/CLIENTE+FORNECEDOR/VENDEDOR) x tipo de documento (PJ/PF/DOCUMENTO_INVALIDO/SEM_DOCUMENTO) x is_ativo.
-- Le: trs_contazul__entidade + trs_contazul__movimento. Gatilho: evento em query-rtu2 (movimento).
-- Identidade (07/10/2026): 1.828 entidades = 1.828 · 1.980 cadastros = 1.980 · 17 linhas.
-- R1 Agrega, nao filtra. R2 So parcela VIGENTE entra em movimento. R3 Das 4.950 parcelas vigentes com id de entidade, 4.327 casam
--    com o cadastro (623 apontam para pessoa criada depois de 17/08/2026, quando o espelho parou de sincronizar) — a cobertura vai junto.
-- R4 qtd_documentos_distintos NAO e emitida: o mesmo documento aparece em mais de um papel e a soma entre linhas daria 1.033 contra 1.008.
-- R5 Competencia, nao caixa; nao soma com o razao do iClips.
WITH e AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_contazul__entidade`
),
mv AS (
  SELECT id_entidade_contaazul AS id, COUNT(*) AS qtd_parcelas, SUM(valor) AS valor
  FROM `vanguardamartech_trusted`.`trs_contazul__movimento`
  WHERE is_vigente AND id_entidade_contaazul IS NOT NULL
  GROUP BY 1
),
j AS (
  SELECT e.*, mv.id IS NOT NULL AS tem_mov, IFNULL(mv.qtd_parcelas, 0) AS qp, IFNULL(mv.valor, 0) AS vv
  FROM e LEFT JOIN mv ON mv.id = e.id_entidade
),
agg AS (
  SELECT
    papeis,
    CASE WHEN is_pj THEN 'PJ' WHEN is_pf THEN 'PF' WHEN flag_documento_invalido THEN 'DOCUMENTO_INVALIDO' ELSE 'SEM_DOCUMENTO' END AS tipo_documento,
    IFNULL(is_ativo, FALSE) AS is_ativo,
    COUNT(*) AS qtd_entidades,
    SUM(qtd_cadastros) AS qtd_cadastros,
    COUNTIF(is_cliente_e_fornecedor) AS qtd_cliente_e_fornecedor,
    COUNTIF(flag_cadastros_divergem) AS qtd_cadastros_divergem,
    COUNTIF(flag_nome_e_o_documento) AS qtd_nome_e_o_documento,
    COUNTIF(is_pj OR is_pf) AS qtd_com_documento_valido,
    COUNTIF(tem_mov) AS qtd_com_movimento_vigente,
    SUM(qp) AS qtd_parcelas_vigentes,
    ROUND(SUM(vv), 2) AS valor_vigente
  FROM j
  GROUP BY 1, 2, 3
),
final AS (
  SELECT CONCAT(papeis, '|', tipo_documento, '|', CAST(is_ativo AS STRING)) AS id_entidade_resumo, a.*, 'L3_CONFIDENTIAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn | supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
