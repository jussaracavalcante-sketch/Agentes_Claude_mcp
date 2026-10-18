-- trs_financeiro__mov_classif
-- Trusted / Financeiro. Grao: um lancamento financeiro CLASSIFICADO (DRE/DFC) em um REGIME (competencia ou caixa), de tres fontes:
-- iClips, Conta Azul e Conexa (coluna `fonte`), em duas operacoes (BRM, VD) mais a VBOT. 106.568 linhas, 100.719 conteudos distintos
-- (medido em 2026-10-18): NAO HA CHAVE NATURAL e 5.849 linhas tem conteudo identico a outra (recorrencias legitimas); id_linha =
-- hash do conteudo + ordinal da duplicata, estavel enquanto o conteudo nao muda.
-- Origem: vanguardamartech_raw.supabase_gold_vw_fin_mov_contraparte (fonte supabase-x0tz). Nivel: L4 PERSONAL_DATA (razao social,
-- descricao livre e documento; ha CPF e folha). vw_fato_mov_classif tem o mesmo conteudo e a mesma soma (R$ 472.781,37) e mvw_fin_mov_*
-- sao agregacoes: nao foram tratadas (duplicata provada).
-- REGRA 1: cada movimento aparece UMA vez por regime; somar sem filtrar regime conta o dinheiro em dobro (competencia 53.272 + caixa 53.296).
-- REGRA 2: valor e ASSINADO (receita +, despesa -); natureza e papel concordam (RECEITA/cliente, DESPESA/fornecedor).
-- REGRA 3: sentinela '(sem centro de custo)' e '(sem identificacao)' viram NULL com flag; centro_custo e contraparte_key NAO sao dimensoes resolvidas.
-- REGRA 4: documento so e documento com 14 ou 11 digitos (92.436 de 92.707 com documento tem forma valida); o cru fica em documento_origem.
-- REGRA 5: `fornecedor_origem` mistura o METODO de identificacao (cadastro 91.617, derivado 4.037, vazio 2.456) com nomes proprios; sai cru como
--          origem_contraparte e nao serve de dimensao.
-- Sem fuso a tratar: competencia, pagamento e data_ref sao DATE na origem.
-- RELACAO COM trs_financeiro__movimento (medida em 2026-10-18): o iClips desta tabela e o mesmo razao ate 2025 (contagem por ano identica de 2018 a 2025); a divergencia comeca em 2026
--   (5.937 linhas aqui contra 5.032 no movimento) e em 2027 em diante so ha projecao nesta (362 linhas). As 4 contas do iClips sem API (1.120 linhas, R$ 3.639.848,49) estao
--   nos DOIS lados: nao e correto dizer que esta gold as exclui. Nao somar as duas.
WITH base AS (
  SELECT
    m.regime, m.fonte, m.empresa, m.ano, m.mes, m.flag_projecao, m.pago, m.valor, m.natureza, m.pacote, m.categoria, m.subcategoria,
    NULLIF(m.centro_custo, '(sem centro de custo)')               AS centro_custo,
    m.competencia, m.pagamento, m.data_ref,
    NULLIF(TRIM(m.razao_social), '')                              AS razao_social,
    m.categoria_fonte, m.subcategoria_fonte, m.conta,
    NULLIF(TRIM(m.descricao), '')                                 AS descricao,
    NULLIF(TRIM(m.fornecedor_origem), '')                         AS origem_contraparte,
    NULLIF(REGEXP_REPLACE(IFNULL(m.documento, ''), r'[^0-9]', ''), '') AS documento_origem,
    NULLIF(m.contraparte_key, '(sem identificação)')              AS contraparte_key,
    NULLIF(m.grupo_key, '(sem identificação)')                    AS grupo_key,
    m.papel,
    TO_HEX(MD5(TO_JSON_STRING(m)))                                AS hash_conteudo
  FROM vanguardamartech_raw.supabase_gold_vw_fin_mov_contraparte m
)
SELECT
  CONCAT(hash_conteudo, '-', CAST(ROW_NUMBER() OVER (PARTITION BY hash_conteudo ORDER BY ano) AS STRING)) AS id_linha,
  regime,
  fonte,
  empresa,
  ano,
  mes,
  DATE(ano, mes, 1)                                  AS mes_referencia,
  flag_projecao                                      AS is_projecao,
  pago                                               AS is_pago,
  valor,
  ABS(valor)                                         AS valor_abs,
  natureza,
  papel,
  pacote,
  categoria,
  subcategoria,
  categoria_fonte,
  subcategoria_fonte,
  centro_custo,
  (centro_custo IS NULL)                             AS flag_sem_centro_custo,
  conta,
  competencia,
  pagamento,
  data_ref,
  razao_social,
  IF(LENGTH(IFNULL(documento_origem, '')) IN (11, 14), documento_origem, NULL) AS documento,
  documento_origem,
  (LENGTH(IFNULL(documento_origem, '')) = 14)        AS is_pj,
  (LENGTH(IFNULL(documento_origem, '')) = 11)        AS is_pf,
  (documento_origem IS NOT NULL AND LENGTH(documento_origem) NOT IN (11, 14)) AS flag_documento_invalido,
  contraparte_key,
  grupo_key,
  (contraparte_key IS NULL)                          AS flag_sem_contraparte,
  origem_contraparte,
  descricao,
  'L4_PERSONAL_DATA'                                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                                AS _extraido_at,
  'supabase-x0tz'                                    AS _fonte,
  hash_conteudo                                      AS _payload_hash
FROM base
