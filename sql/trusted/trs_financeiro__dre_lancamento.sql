-- trs_financeiro__dre_lancamento
-- Trusted / Financeiro. Grao: um lancamento da DRE gerencial (regime de competencia) com a classificacao de DRE do Supabase:
-- dre_pacote, dre_bucket (COGS etc.), dre_incluir, grupo_fcx e hierarquia area > diretoria > departamento > setor. 51.566 linhas,
-- 40.048 conteudos distintos (medido em 2026-10-18): NAO HA CHAVE NATURAL; id_linha = hash do conteudo + ordinal da duplicata.
-- Origem: vanguardamartech_raw.supabase_gold_vw_fato_dre (fonte supabase-x0tz; mvw_dre_lanc e a mesma tabela, 51.566 linhas e mesma soma
-- R$ 2.156.333,65; vw_dre_pacote, vw_dre_cc e mvw_dre_* sao agregacoes e nao foram tratadas). Nivel: L4 PERSONAL_DATA (razao social, descricao).
-- NAO e igual a trs_financeiro__mov_classif regime competencia: a DRE exclui lancamentos (R$ 2.156.333,65 contra R$ 286.925,66 de soma assinada;
-- 51.566 contra 53.272 linhas): o criterio de exclusao e do Supabase e nao esta nesta tabela. valor e ASSINADO (receita +, despesa -).
-- dre_incluir = FALSE marca o que a DRE gerencial NAO soma (43.962 incluidos de 51.566): marcar, nunca apagar.
SELECT
  CONCAT(hash_conteudo, '-', CAST(ROW_NUMBER() OVER (PARTITION BY hash_conteudo ORDER BY ano) AS STRING)) AS id_linha,
  empresa,
  ano,
  mes,
  DATE(ano, mes, 1)                                  AS mes_referencia,
  flag_projecao                                      AS is_projecao,
  pago                                               AS is_pago,
  valor,
  natureza,
  secao,
  dre_pacote,
  dre_incluir                                        AS is_dre_incluir,
  grupo_fcx,
  dre_bucket,
  nivel1_area,
  nivel2_diretoria,
  nivel3_departamento,
  nivel4_setor,
  categoria,
  subcategoria,
  conta,
  razao_social,
  IF(LENGTH(IFNULL(doc_origem, '')) IN (11, 14), doc_origem, NULL) AS documento,
  doc_origem                                         AS documento_origem,
  (LENGTH(IFNULL(doc_origem, '')) = 14)              AS is_pj,
  (LENGTH(IFNULL(doc_origem, '')) = 11)              AS is_pf,
  data_ref,
  descricao,
  'L4_PERSONAL_DATA'                                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                                AS _extraido_at,
  'supabase-x0tz'                                    AS _fonte,
  hash_conteudo                                      AS _payload_hash
FROM (
  SELECT
    d.ano, d.mes, d.flag_projecao, d.valor, d.dre_pacote, d.dre_incluir, d.grupo_fcx, d.dre_bucket, d.nivel1_area, d.nivel2_diretoria,
    d.nivel3_departamento, d.nivel4_setor, d.categoria, d.subcategoria,
    NULLIF(TRIM(d.razao_social), '')                 AS razao_social,
    d.conta, d.empresa, d.secao, d.pago, d.natureza,
    NULLIF(REGEXP_REPLACE(IFNULL(d.documento, ''), r'[^0-9]', ''), '') AS doc_origem,
    d.data_ref,
    NULLIF(TRIM(d.descricao), '')                    AS descricao,
    TO_HEX(MD5(TO_JSON_STRING(d)))                   AS hash_conteudo
  FROM vanguardamartech_raw.supabase_gold_vw_fato_dre d
)
