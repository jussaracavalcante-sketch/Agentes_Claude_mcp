-- rfn_financeiro__mov_classif_mensal
-- Refined / financeiro. Grao: regime (competencia ou caixa) x fonte x empresa x mes x natureza x pacote x categoria x pago x projecao.
-- Le trs_financeiro__mov_classif. Nivel: L3 CONFIDENTIAL (agregado; nenhuma contraparte, descricao ou subcategoria nominal atravessa).
-- REGRA 1: SEMPRE filtrar ou agrupar por regime: cada movimento esta uma vez em cada regime e somar os dois conta o dinheiro em dobro.
-- REGRA 2: valor e ASSINADO (receita +, despesa -). DFC mensal = regime caixa; resultado por competencia = regime competencia.
-- REGRA 3: `is_pago`: no regime caixa, pago = saiu/entrou no banco; nao pago = programado. Medido: caixa pago -R$ 141.350,19 e nao pago R$ 327.205,90.
-- REGRA 4: categoria entra no grao e subcategoria NAO (331 valores, alguns com nome de socio ou colaborador).
-- LIMITACOES - NAO CONTORNE: nao soma com trs_financeiro__movimento, trs_contazul__movimento nem com rfn_financeiro__fluxo_caixa (mesmo dinheiro);
--   iClips so diverge de trs_financeiro__movimento em 2026+; fonte Conexa nao tem centro de custo; a classificacao e do Supabase.
WITH m AS (
  SELECT * FROM vanguardamartech_trusted.trs_financeiro__mov_classif
)
SELECT
  CONCAT(regime, '|', fonte, '|', IFNULL(empresa, '-'), '|', CAST(mes_referencia AS STRING), '|', IFNULL(natureza, '-'), '|', IFNULL(pacote, '-'), '|',
         IFNULL(categoria, '-'), '|', CAST(is_pago AS STRING), '|', CAST(is_projecao AS STRING)) AS id_mov_mensal,
  regime,
  fonte,
  empresa,
  mes_referencia,
  natureza,
  pacote,
  categoria,
  is_pago,
  is_projecao,
  COUNT(*)                                          AS qtd_lancamentos,
  SUM(valor)                                        AS valor,
  SUM(valor_abs)                                    AS valor_abs,
  COUNTIF(flag_sem_centro_custo)                    AS qtd_sem_centro_custo,
  COUNTIF(flag_sem_contraparte)                     AS qtd_sem_contraparte,
  COUNTIF(is_pf)                                    AS qtd_contraparte_pf,
  'L3_CONFIDENTIAL'                                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                               AS _extraido_at,
  'supabase-x0tz'                                   AS _fonte
FROM m
GROUP BY regime, fonte, empresa, mes_referencia, natureza, pacote, categoria, is_pago, is_projecao
