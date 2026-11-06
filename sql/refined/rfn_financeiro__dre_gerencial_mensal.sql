-- rfn_financeiro__dre_gerencial_mensal
-- Refined / financeiro. Grao: mes de competencia x empresa x secao x pacote de DRE x bucket x area x diretoria x incluido na DRE x projecao.
-- Le trs_financeiro__dre_lancamento. Nivel: L3 CONFIDENTIAL (agregado; nenhuma razao social, descricao ou documento atravessa).
-- REGRA 1: valor e ASSINADO (receita +, despesa -); o resultado e a soma assinada. valor_incluido_na_dre soma so is_dre_incluir = TRUE
--          (e o criterio de inclusao do Supabase, nao desta casa); valor soma tudo. Os dois ficam lado a lado, nunca um no lugar do outro.
-- REGRA 2: is_projecao separa o que ainda nao aconteceu (competencia futura ou titulo previsto): realizado = is_projecao = FALSE.
-- REGRA 3: valor_pago x valor_em_aberto repartem o valor pelo status de pagamento do lancamento; a soma dos dois e valor.
-- REGRA 4: dre_bucket NAO_ALOCADO nao e erro: e tudo o que nao tem centro de custo de area (receita inclusive).
-- LIMITACOES - NAO CONTORNE: o criterio de exclusao da DRE e do Supabase (a DRE tem 51.566 lancamentos, a competencia de
--   trs_financeiro__mov_classif tem 53.272); nao soma com rfn_financeiro__receita_cliente_mensal nem com rfn_financeiro__rentabilidade_cliente
--   (outra metodologia: la a comissao de midia e a receita; aqui vale a classificacao do Supabase); empresa tem BRM, VD e VBOT.
WITH d AS (
  SELECT * FROM vanguardamartech_trusted.trs_financeiro__dre_lancamento
)
SELECT
  CONCAT(CAST(mes_referencia AS STRING), '|', IFNULL(empresa, '-'), '|', IFNULL(secao, '-'), '|', IFNULL(dre_pacote, '-'), '|', IFNULL(dre_bucket, '-'), '|',
         IFNULL(nivel1_area, '-'), '|', IFNULL(nivel2_diretoria, '-'), '|', CAST(is_dre_incluir AS STRING), '|', CAST(is_projecao AS STRING)) AS id_dre_mensal,
  mes_referencia,
  empresa,
  secao,
  dre_pacote,
  dre_bucket,
  nivel1_area,
  nivel2_diretoria,
  is_dre_incluir,
  is_projecao,
  COUNT(*)                                          AS qtd_lancamentos,
  SUM(valor)                                        AS valor,
  SUM(IF(is_dre_incluir, valor, 0))                 AS valor_incluido_na_dre,
  SUM(IF(is_pago, valor, 0))                        AS valor_pago,
  SUM(IF(NOT is_pago, valor, 0))                    AS valor_em_aberto,
  SUM(IF(valor > 0, valor, 0))                      AS valor_entradas,
  SUM(IF(valor < 0, valor, 0))                      AS valor_saidas,
  'L3_CONFIDENTIAL'                                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                               AS _extraido_at,
  'supabase-x0tz'                                   AS _fonte
FROM d
GROUP BY mes_referencia, empresa, secao, dre_pacote, dre_bucket, nivel1_area, nivel2_diretoria, is_dre_incluir, is_projecao
