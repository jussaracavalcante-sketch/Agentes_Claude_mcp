-- rfn_financeiro__faturamento_mensal
-- Refined / financeiro. Grao: mes de competencia x empresa x fonte. Le trs_financeiro__faturamento.
-- Nivel: L3 CONFIDENTIAL (agregado; nenhum cliente atravessa).
-- REGRA 1: o mes e o de COMPETENCIA do titulo; valor_pago soma so titulos com data de pagamento; valor_sem_baixa soma os demais. As duas colunas somam `valor`.
-- REGRA 2: emissao e opcional (cobre ~57% das linhas): valor_com_emissao e qtd_com_emissao mostram o quanto do mes tem data de emissao; NAO e taxa de nota emitida.
-- REGRA 3: flag_mes_futuro compara o mes com o mes DA CARGA (DATE(_extraido_at)), nunca com o relogio de quem le; competencia futura e projecao (vai ate 2028-09).
-- REGRA 4: tabela de soma, nao de taxa: razoes (ex.: valor_pago / valor) sao recalculadas da razao de somas por quem le.
-- LIMITACOES - NAO CONTORNE: so iClips e Conta Azul (BRM e VD); a VBOT/Conexa nao entra; nao soma com rfn_financeiro__receita_cliente_mensal, com
--   trs_financeiro__movimento nem com rfn_financeiro__mov_classif_mensal (mesmo dinheiro, outro recorte); nao ha cliente nesta tabela.
WITH f AS (
  SELECT *, DATE_TRUNC(DATE(_extraido_at), MONTH) AS mes_carga
  FROM vanguardamartech_trusted.trs_financeiro__faturamento
)
SELECT
  CONCAT(CAST(mes_competencia AS STRING), '|', empresa, '|', fonte)  AS id_faturamento_mensal,
  mes_competencia,
  empresa,
  fonte,
  COUNT(*)                                           AS qtd_titulos,
  SUM(valor)                                         AS valor,
  COUNTIF(is_pago)                                   AS qtd_pagos,
  SUM(IF(is_pago, valor, 0))                         AS valor_pago,
  SUM(IF(is_pago, 0, valor))                         AS valor_sem_baixa,
  COUNTIF(NOT flag_sem_emissao)                      AS qtd_com_emissao,
  SUM(IF(flag_sem_emissao, 0, valor))                AS valor_com_emissao,
  COUNTIF(flag_sem_cliente)                          AS qtd_sem_cliente,
  (ANY_VALUE(mes_competencia) > ANY_VALUE(mes_carga)) AS flag_mes_futuro,
  'L3_CONFIDENTIAL'                                  AS classificacao_dado,
  CURRENT_TIMESTAMP()                                AS _extraido_at,
  'supabase-x0tz'                                    AS _fonte
FROM f
GROUP BY mes_competencia, empresa, fonte
