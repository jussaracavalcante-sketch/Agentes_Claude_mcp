-- trs_financeiro__receita_cliente
-- Trusted / Financeiro. Grao: um lancamento de RECEITA LIGADA A CLIENTE (iClips ou Conta Azul; BRM, VD e VBOT) com a natureza da receita: CLIENTE, BV ou CONTA_ORDEM.
-- 19.409 linhas, 17.563 conteudos distintos (medido em 2026-10-18): NAO HA CHAVE NATURAL e 1.846 linhas tem conteudo identico a outra (recorrencias legitimas);
-- id_linha = hash do conteudo + ordinal da duplicata, estavel enquanto o conteudo nao muda.
-- Origem: vanguardamartech_raw.supabase_gold_vw_fin_cliente (fonte supabase-x0tz; a mvw_fin_cliente tem a MESMA soma, R$ 58.696.772,34, em 11.584 linhas agregadas).
-- Nivel: L4 PERSONAL_DATA (razao social e nome do cliente; ha CPF: 408 linhas com 11 digitos).
-- POR QUE EXISTE: e a unica tabela que SEPARA O BV. Medido em 2026-10-18: CLIENTE R$ 46.363.277,40 (15.959 linhas) · BV R$ 3.273.626,36 (1.643; iClips 2.937.781,75 +
--   Conta Azul 335.844,61) · CONTA_ORDEM R$ 9.059.868,58 (1.807). A Trusted de financeiro nao consegue separar BV: ele esta dentro de Midia Off na origem.
-- DOCUMENTO: so e documento o que tem 14 (CNPJ) ou 11 (CPF) digitos. 123 linhas (R$ 157.945,50) chegam com 13 digitos (zero a esquerda perdido); o LPAD so e aceito quando o
--   valor corrigido JA EXISTE entre os documentos de 14 digitos desta propria tabela (flag_documento_repadronizado). 13 linhas (R$ 143.500,00) trazem 9 digitos (mascara pela
--   metade) e ficam sem documento (flag_documento_invalido). O documento cru fica em documento_origem.
-- LIMITACOES - NAO CONTORNE: NAO soma com trs_financeiro__movimento nem com trs_financeiro__mov_classif (a receita de competencia ali e R$ 66,54 mi; aqui R$ 58,70 mi, so o que
--   se liga a cliente); grupo_key e o agrupamento do Supabase (raiz de CNPJ ou nome), nunca chave de conta (R-003); 496 linhas (R$ 772.786,49) nao tem documento e a chave
--   delas e o nome (prefixo N:); ate 2028 ha projecao (351 linhas).
WITH base AS (
  SELECT
    c.*,
    TO_HEX(MD5(TO_JSON_STRING(c)))                                         AS hash_conteudo,
    NULLIF(REGEXP_REPLACE(IFNULL(c.cliente_doc, ''), r'[^0-9]', ''), '')   AS doc_origem
  FROM vanguardamartech_raw.supabase_gold_vw_fin_cliente c
),
docs14 AS (
  SELECT DISTINCT doc_origem AS d FROM base WHERE LENGTH(doc_origem) = 14
),
fin AS (
  SELECT
    b.*,
    (LENGTH(b.doc_origem) = 13 AND d.d IS NOT NULL)                        AS flag_documento_repadronizado,
    CASE
      WHEN LENGTH(b.doc_origem) = 13 AND d.d IS NOT NULL THEN d.d
      WHEN LENGTH(b.doc_origem) IN (11, 14) THEN b.doc_origem
    END                                                                    AS documento
  FROM base b
  LEFT JOIN docs14 d ON LENGTH(b.doc_origem) = 13 AND d.d = LPAD(b.doc_origem, 14, '0')
)
SELECT
  CONCAT(hash_conteudo, '-', CAST(ROW_NUMBER() OVER (PARTITION BY hash_conteudo ORDER BY ano, mes) AS STRING)) AS id_linha,
  ano,
  mes,
  DATE(ano, mes, 1)                                  AS mes_referencia,
  empresa,
  flag_projecao                                      AS is_projecao,
  pago                                               AS is_pago,
  valor,
  NULLIF(TRIM(linha_servico), '')                    AS linha_servico,
  NULLIF(TRIM(categoria), '')                        AS categoria,
  NULLIF(TRIM(subcategoria), '')                     AS subcategoria,
  tipo_receita,
  fonte,
  cliente_key,
  NULLIF(TRIM(cliente_nome), '')                     AS cliente_nome,
  documento,
  doc_origem                                         AS documento_origem,
  (LENGTH(documento) = 14)                           AS is_pj,
  (LENGTH(documento) = 11)                           AS is_pf,
  (doc_origem IS NOT NULL AND documento IS NULL)     AS flag_documento_invalido,
  flag_documento_repadronizado,
  tem_documento                                      AS tem_documento_origem,
  grupo_key,
  NULLIF(TRIM(grupo_nome), '')                       AS grupo_nome,
  NULLIF(TRIM(razao_social), '')                     AS razao_social,
  conta,
  data_ref,
  NULLIF(TRIM(descricao), '')                        AS descricao,
  'L4_PERSONAL_DATA'                                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                                AS _extraido_at,
  'supabase-x0tz'                                    AS _fonte,
  hash_conteudo                                      AS _payload_hash
FROM fin
