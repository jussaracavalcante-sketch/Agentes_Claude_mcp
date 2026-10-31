-- trs_financeiro__faturamento
-- Trusted / Financeiro. Grao: um TITULO FATURADO (iClips ou Conta Azul) das operacoes BRM e VD, com as tres datas: competencia, emissao e pagamento.
-- 14.867 linhas, 14.200 conteudos distintos (medido em 2026-10-18): NAO HA CHAVE NATURAL e 667 linhas tem conteudo identico a outra (recorrencias legitimas);
-- id_linha = hash do conteudo + ordinal da duplicata, estavel enquanto o conteudo nao muda.
-- Origem: vanguardamartech_raw.supabase_gold_vw_fato_faturamento (fonte supabase-x0tz); supabase_gold_mvw_fin_faturamento e a MESMA tabela
--   (14.867 linhas, R$ 48.773.812,02 e EXCEPT DISTINCT = 0 nos dois sentidos medido): nao foi tratada.
-- Nivel: L4 PERSONAL_DATA (nome do cliente; ha pessoa fisica).
-- REGRA 1: a data de EMISSAO cobre so 8.481 das 14.867 linhas (57%; 6.386 sem emissao, medido em 2026-10-18): NULL e ausencia, nunca data antiga.
-- REGRA 2: data_pagamento NULL = titulo sem baixa registrada (1.363 linhas); is_pago acende quando a data existe.
-- REGRA 3: so iClips (12.977; R$ 39.433.991,62) e Conta Azul (1.890; R$ 9.339.820,40); a VBOT/Conexa NAO esta nesta tabela.
-- LIMITACOES - NAO CONTORNE: nao soma com trs_financeiro__movimento nem com trs_financeiro__mov_classif (mesmo dinheiro, outro recorte: a receita caixa do iClips no
--   razao e R$ 47,88 mi em 15.553 linhas contra R$ 39,43 mi em 12.977 aqui); competencia vai ate 2028-09 (projecao); o fuso nao se aplica (datas).
SELECT
  CONCAT(hash_conteudo, '-', CAST(ROW_NUMBER() OVER (PARTITION BY hash_conteudo ORDER BY data_competencia) AS STRING)) AS id_linha,
  empresa,
  fonte,
  NULLIF(TRIM(cliente), '')                          AS cliente,
  (NULLIF(TRIM(cliente), '') IS NULL)                AS flag_sem_cliente,
  valor,
  data_competencia,
  DATE_TRUNC(data_competencia, MONTH)                AS mes_competencia,
  data_emissao,
  (data_emissao IS NULL)                             AS flag_sem_emissao,
  data_pagamento,
  (data_pagamento IS NOT NULL)                       AS is_pago,
  'L4_PERSONAL_DATA'                                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                                AS _extraido_at,
  'supabase-x0tz'                                    AS _fonte,
  hash_conteudo                                      AS _payload_hash
FROM (
  SELECT f.*, TO_HEX(MD5(TO_JSON_STRING(f))) AS hash_conteudo
  FROM vanguardamartech_raw.supabase_gold_vw_fato_faturamento f
)
