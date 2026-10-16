-- rfn_financeiro__despesa_vbot_mensal
-- PUBLICADA em 2026-09-28 como query-schs, camada Refined, folder financeiro.
-- Grao: um MES, um CENTRO DE CUSTO, uma CATEGORIA, um TIPO de despesa.
-- L2 INTERNAL -- nao ha pessoa nem cliente aqui, so fornecedor agregado em contagem.
-- Responde: ONDE a VBOT gasta -- por centro de custo, por categoria, fixo contra
-- variavel, mes a mes.
-- Origem: trs_conexa__despesa (1.461 linhas, 1.221 vigentes) mais a dimensao de
-- centro de custo da Raw.
--
-- FECHA A ULTIMA TRUSTED DO CONEXA SEM GOLD. Com esta e a
-- rfn_financeiro__receita_vbot_mensal, as cinco Trusted do Conexa passam a ter camada
-- de consumo; antes de hoje so a de cobranca tinha.
--
-- O RATEIO POR CENTRO DE CUSTO EXISTE NA ESTRUTURA E NAO E USADO -- medido, e isso
-- muda o codigo. A Trusted declara que "uma despesa pode ratear em mais de um centro
-- de custo: somar por centro sem desaninhar atribui tudo a um so; desaninhar sem
-- ponderar multiplica". Medido em 2026-09-28: `flag_rateio_multiplo` e FALSE nas
-- 1.221 vigentes, `qtd_centros_custo` e 1 em todas, e o `percentage` e 100 em TODAS
-- as linhas do array. A expansao devolve 1.221 linhas para 1.221 despesas -- nada
-- multiplica. **A ponderacao continua no codigo assim mesmo**, porque a estrutura
-- permite o rateio e o dia em que a origem usar, a query ja esta certa. E a
-- identidade prova: o valor rateado soma R$ 3.065.689,75, exatamente o valor direto.
--
-- MAIS DA METADE DO DINHEIRO AQUI E FUTURO. 374 das 1.221 despesas vigentes (30,6%)
-- tem competencia posterior ao mes corrente, e elas somam R$ 1.704.896,82 dos
-- R$ 3.065.689,75 (55,6%) -- despesa recorrente ja lancada ate 2027-10. Quem somar a
-- tabela inteira soma compromisso com gasto. `flag_mes_futuro` e o filtro.
--
-- REGRAS DE NEGOCIO
-- 1. TODA LEITURA COMECA POR `is_vigente`: 240 das 1.461 despesas (16,4%) foram
--    apagadas no Conexa e ficam fora.
-- 2. O VALOR SAI PONDERADO PELO PERCENTUAL DO CENTRO DE CUSTO, sempre -- ver o bloco
--    acima. Hoje o peso e 100% em todas as linhas e o resultado e identico ao valor
--    cheio; a forma e que garante o futuro.
-- 3. NULL EM `valor_pago` E `valor_em_aberto` E ZERO MEDIDO, NAO AUSENCIA: a origem
--    escreve NULL onde nao houve pagamento (404 linhas) e onde nada esta em aberto
--    (817, as pagas). Por isso levam IFNULL dentro da soma. Mesmo tratamento da
--    cobranca, e pelo mesmo motivo: sem IFNULL uma linha faz o mes inteiro virar NULL.
-- 4. ZERO NAO E ZERO na razao: `taxa_pagamento` sai NULL quando nao houve despesa no
--    grupo, nunca zero. E ELA PASSA DE 1,0 EM 10 DOS 447 GRUPOS -- isso NAO e defeito
--    e NAO foi limitado: 11 despesas foram pagas acima do valor de face (juros e
--    multa, R$ 271,23 no total, maior caso R$ 73,61) e 6 abaixo (desconto,
--    R$ 19.083,10). E o mesmo mecanismo ja medido no Conta Azul, onde 772 de 5.250
--    parcelas rompem a face. Cortar a taxa em 1,0 esconderia o juro.
-- 5. `tipo_despesa` ENTRA NO GRAO, nao vira coluna de medida. `fixed` (779) e `loose`
--    (442) sao naturezas diferentes de compromisso e somar as duas num indicador de
--    "custo fixo" seria exatamente o erro que a casa ja registrou com
--    `tipo_receita` CLIENTE vs CONTA_ORDEM.
--
-- LIMITACOES MEDIDAS -- NAO CONTORNE
-- 1. A CATEGORIA SAI SEM NOME, DE PROPOSITO, E ISSO E UMA ARMADILHA DE NOME EVITADA.
--    Existe uma `dim_categoria_vbot` na Raw com 11 linhas, e ela e o catalogo de
--    RECEITA, nao de despesa: "Receita Recorrente", "Planos de Assinatura", "Setup",
--    "Midia On". A despesa usa 18 ids de um plano de contas DIFERENTE, e 13 deles nem
--    existem naquela tabela. Juntar as duas rotularia 5 categorias de despesa com
--    nomes de receita por coincidencia numerica. Mesmo mecanismo ja medido na
--    `trs_vjob__auditoria_servico`, onde `categoria` aponta para `tbservicosauditoria`
--    e nao para `tbcategoriasauditoria`. **Orfao e melhor que falso par.**
-- 2. O CENTRO DE CUSTO, ESSE SIM, RESOLVE INTEIRO: 10 dos 11 cadastrados sao usados e
--    ZERO ids ficam orfaos.
-- 3. NAO HA CLIENTE NA DESPESA. Ela tem fornecedor, categoria e centro de custo.
--    Margem por cliente da VBOT nao se calcula com o que existe nesta base -- a
--    rfn_financeiro__receita_vbot_mensal declara o mesmo do outro lado.
-- 4. NENHUMA DESPESA ESTA CONCILIADA: a Trusted mede `is_reconciled` FALSE nas 1.458 e
--    `digitable_line` NULL em todas. Conciliacao bancaria nao se mede por aqui.
-- 5. NAO SOMAR COM `rfn_operacao__custo_peca` NEM COM `trs_financeiro__movimento`:
--    aquelas sao o custo da Vanguarda Comunicacao no iClips. Esta e a VBOT no Conexa.
--
-- VALIDACAO (2026-09-28, sobre a tabela materializada): 447 linhas, 447 chaves
-- distintas, 28 meses (2025-05 a 2027-10), 10 centros de custo, 18 categorias.
-- ZERO centros orfaos, ZERO sem nome, ZERO grupos com despesa e sem taxa, ZERO linhas
-- com rateio parcial. A soma de `qtd_despesas` devolve 1.221, exatamente as vigentes
-- -- zero multiplicacao pela expansao do array. Valor rateado R$ 3.065.689,75,
-- reproduzindo o valor direto da Trusted AO CENTAVO; pago R$ 1.205.785,43; futuro
-- R$ 1.704.896,82.
--
-- Gatilho: evento em query-8uTi (rfn_financeiro__receita_vbot_mensal), mantendo a
-- cadeia do Conexa LINEAR ate o fim: supabase-x0tz -> mbpv -> 6qKc -> 54P5 -> T3ct ->
-- rbJW -> bZT5 -> 8uTi -> esta.
WITH d AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_conexa__despesa` WHERE is_vigente
),
centro AS (
  SELECT CAST(conexa_id AS STRING) AS id_centro_custo, nome AS centro_custo
  FROM `vanguardamartech_raw`.`supabase_public_dim_centro_custo_vbot`
),
-- REGRA 2 -- desaninha o rateio E pondera pelo percentual. Hoje 1.221 -> 1.221 e o
-- peso e 100 em todas; a forma e que sobrevive ao dia em que a origem ratear.
expandida AS (
  SELECT
    d.* EXCEPT (rateio_centro_custo),
    JSON_VALUE(c, '$.id')                             AS id_centro_custo,
    CAST(JSON_VALUE(c, '$.percentage') AS FLOAT64) / 100 AS peso_centro
  FROM d, UNNEST(d.rateio_centro_custo) c
),
agg AS (
  SELECT
    mes_competencia_data                              AS mes_referencia,
    id_centro_custo,
    CAST(id_categoria AS STRING)                      AS id_categoria,
    tipo_despesa,

    COUNT(*)                                          AS qtd_despesas,
    COUNT(DISTINCT id_fornecedor)                     AS qtd_fornecedores,
    COUNT(DISTINCT id_subcategoria)                   AS qtd_subcategorias,

    ROUND(SUM(valor * peso_centro), 2)                        AS valor,
    ROUND(SUM(IFNULL(valor_pago, 0) * peso_centro), 2)        AS valor_pago,
    ROUND(SUM(IFNULL(valor_em_aberto, 0) * peso_centro), 2)   AS valor_em_aberto,
    ROUND(SUM(IF(is_atraso_a_pagar,
             IFNULL(valor_em_aberto, 0) * peso_centro, 0)), 2) AS valor_vencido,

    COUNTIF(is_paga)                                  AS qtd_pagas,
    COUNTIF(is_cancelada)                             AS qtd_canceladas,
    COUNTIF(is_atraso_a_pagar)                        AS qtd_vencidas,
    COUNTIF(is_cac)                                   AS qtd_cac,
    COUNTIF(peso_centro <> 1)                         AS qtd_com_rateio_parcial
  FROM expandida
  WHERE mes_competencia_data IS NOT NULL
  GROUP BY 1, 2, 3, 4
)
SELECT
  CONCAT(FORMAT_DATE('%Y-%m', a.mes_referencia), ':', a.id_centro_custo, ':',
         a.id_categoria, ':', a.tipo_despesa)         AS id_despesa_vbot_mensal,
  a.mes_referencia,
  (a.mes_referencia > DATE_TRUNC(CURRENT_DATE(), MONTH)) AS flag_mes_futuro,

  a.id_centro_custo,
  c.centro_custo,
  (c.id_centro_custo IS NULL)                         AS flag_centro_nao_catalogado,

  -- LIMITACAO 1 -- o id sai cru. A dim_categoria_vbot e catalogo de RECEITA.
  a.id_categoria,
  a.tipo_despesa,
  (a.tipo_despesa = 'fixed')                          AS is_despesa_fixa,

  a.qtd_despesas,
  a.qtd_fornecedores,
  a.qtd_subcategorias,
  a.valor,
  a.valor_pago,
  a.valor_em_aberto,
  a.valor_vencido,
  a.qtd_pagas,
  a.qtd_canceladas,
  a.qtd_vencidas,
  a.qtd_cac,
  a.qtd_com_rateio_parcial,
  -- REGRA 4 -- sem despesa no grupo, NULL. Nunca zero.
  ROUND(SAFE_DIVIDE(a.valor_pago, NULLIF(a.valor, 0)), 6) AS taxa_pagamento,

  'L2_INTERNAL'                                       AS classificacao_dado,
  CURRENT_TIMESTAMP()                                 AS _extraido_at
FROM agg a
LEFT JOIN centro c ON c.id_centro_custo = a.id_centro_custo
