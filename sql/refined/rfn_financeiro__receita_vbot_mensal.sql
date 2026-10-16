-- rfn_financeiro__receita_vbot_mensal
-- PUBLICADA em 2026-09-28 como query-8uTi, camada Refined, folder financeiro.
-- Grao: um CLIENTE da VBOT, um MES. 2.090 linhas, 2.090 chaves, 128 clientes,
-- 29 meses (2025-05 a 2027-09). L4 por linhagem (documento de cliente PF).
-- Responde: QUANTO a VBOT tem contratado, quanto faturou, quanto recebeu e o que
-- ainda nao virou cobranca -- por cliente e por mes.
-- Origem: trs_conexa__contrato, __cobranca, __venda e __cliente.
--
-- ATE HOJE A VBOT SO TINHA GOLD DE INADIMPLENCIA. Das cinco Trusted do Conexa, so a
-- de cobranca era lida por uma Refined (rfn_financeiro__inadimplencia_vbot); contrato,
-- venda e despesa eram lidas apenas pela suite de qualidade. O MRR da operacao -- o
-- numero que diz se ela cresce -- nao existia na camada oficial de consumo.
--
-- O MRR TRIPLICOU EM DEZ MESES, e este e o achado: R$ 30.188,55 em 2025-12 com 41
-- contratos, R$ 102.470,04 em 2026-09 com 103. Curva sem um unico mes de queda.
--
-- REGRAS DE NEGOCIO
-- 1. TODA LEITURA COMECA POR `is_vigente` NA ORIGEM. Registro apagado no Conexa fica
--    fora das tres origens aqui -- a Trusted ja mede quanto isso vale (16,5% das
--    despesas, R$ 144.312,88 de titulos vencidos apagados).
-- 2. CONTRATO VIGENTE NO MES VEM DA DATA, e a flag foi MEDIDA antes de ser
--    descartada: `is_ativo` e a vigencia por data concordam em 102 de 102 contratos,
--    ZERO divergencia nos dois sentidos, e o MRR bate ao centavo (R$ 102.470,04 dos
--    dois lados). Aqui a flag NAO mente -- ao contrario do status do Conta Azul, que
--    deixa 285 de 395 parcelas vencidas sem o rotulo ATRASADO. A data manda porque e
--    ela que permite olhar um MES PASSADO; a flag so sabe de hoje.
-- 3. NAO SOMAR `valor_faturado` COM VENDA. As 2.401 vendas que ja estao dentro de uma
--    cobranca somam R$ 1.419.457,71 e seriam contadas duas vezes. Esta tabela emite
--    apenas `valor_vendas_sem_cobranca` -- a parte que AINDA NAO virou cobranca, e que
--    por isso e aditiva com o faturado. A conta fecha: 3.473 vendas vigentes = 2.401
--    com cobranca + 122 canceladas + 950 em aberto (R$ 430.069,84).
-- 4. `is_faturada` DA VENDA E ESTAGIO, NAO ACUMULADO -- e essa e a armadilha mais cara
--    desta familia. Ela e TRUE em 194 vendas; as 2.207 que ja foram PAGAS saem com
--    FALSE, embora tenham cobranca. Medir faturamento por ela devolve 194 de 2.401
--    (8%) e R$ 154.833,48 de R$ 1.419.457,71 (11%). A invariante correta e
--    `tem_cobranca = is_faturada OR is_paga`, verdadeira em 2.401 de 2.401.
-- 5. ZERO NAO E ZERO: `taxa_recebimento` sai NULL quando nao houve faturamento no
--    mes, nunca zero. Zero seria somado; NULL obriga quem le a decidir.
-- 6. MES FUTURO NAO SE CORTA, SE MARCA -- E ELE E MAIORIA. 1.228 das 2.090 linhas
--    (58,8%) sao de mes futuro, porque ha contrato com fim contratado ate 2027-09 e
--    venda recorrente ja gerada ate la. Quem somar a tabela inteira soma agenda com
--    entrega. `flag_mes_futuro` e o filtro; mesma doutrina da recorrencia do VJOB,
--    onde 349 de 410 ocorrencias sao agenda, e do escopo, com cadastro ate 2027.
--
-- A JANELA E DERIVADA, NUNCA ESCRITA A MAO: menor e maior mes entre inicio de
-- contrato, competencia de cobranca e data de referencia de venda. Quando a base
-- andar, a janela anda sozinha.
--
-- LIMITACOES MEDIDAS -- NAO CONTORNE
-- 1. NAO HA CUSTO AQUI, e isso nao e esquecimento: `trs_conexa__despesa` NAO TEM
--    CLIENTE. Ela tem fornecedor, categoria e centro de custo. Margem por cliente da
--    VBOT nao se calcula com o que existe nesta base.
-- 2. 29 DOS 131 CONTRATOS VIGENTES (22%) NAO TEM `valor_mensal_recorrente`.
--    `qtd_contratos_sem_valor` sai na linha para que ninguem leia o MRR como completo.
-- 3. TRES COBRANCAS NAO TEM MES DE COMPETENCIA e ficam fora (R$ 2.284,97 de
--    R$ 1.460.892,29, 0,16%). Por isso `valor_faturado` desta tabela soma
--    R$ 1.458.607,32 e nao o total da Trusted -- a diferenca esta declarada, nao e
--    perda silenciosa. Uma delas e um titulo vencido de R$ 1.376,20, e por isso o
--    `valor_vencido` daqui e R$ 63.704,74 contra R$ 65.080,94 na Trusted.
--    NAO E DIVERGENCIA COM A rfn_financeiro__inadimplencia_vbot: aquela nao tem grao
--    de mes, entao nao precisa descartar o titulo sem competencia. O numero dela
--    registrado em 25/09 (R$ 54.198,56, 30 titulos) e de ANTES da carga de 28/09 --
--    hoje a Trusted tem 46 titulos vencidos vigentes. A base andou, nao o tratamento.
-- 4. O valor do contrato tem DUAS leituras que a Trusted ja declarou nao reconciliar:
--    `valor_mensal_recorrente` do cabecalho e os `servicos_complementares` (101 dos
--    139 contratos tem). Aqui vale o cabecalho. Qual dos dois e "o valor do contrato"
--    e regra de negocio que ninguem desta casa decidiu.
-- 5. Churn por `data_fim` SUBCONTA: so 30 dos 131 contratos vigentes tem data de fim.
--    `qtd_contratos_encerrados` conta o que a origem datou, e so.
-- 6. NAO SOMAR COM `rfn_financeiro__rentabilidade_cliente` NEM COM
--    `rfn_financeiro__fluxo_caixa`. Esta e a operacao VBOT no Conexa; aquelas sao a
--    Vanguarda Comunicacao no iClips e no Conta Azul. A casa ja mediu que a cobranca
--    de R$ 5,00 da Vanguarda Comunicacao aparece nos DOIS lugares -- somar duplica.
--
-- L4 PERSONAL_DATA por linhagem: 4 dos 128 clientes sao pessoa fisica e o `documento`
-- deles e CPF. Ele fica porque e a unica chave para fora do Conexa, e `is_pf` existe
-- para que se filtre sem contar digito.
--
-- VALIDACAO (2026-09-28, sobre a tabela materializada): 2.090 linhas, 2.090 chaves,
-- ZERO clientes orfaos, ZERO id_cliente nulo nas tres origens, MRR mensal reproduzindo
-- a Trusted (R$ 102.470,04 em 2026-09), faturado R$ 1.458.607,32, recebido
-- R$ 1.248.927,44 e pipeline R$ 430.069,84 -- este ultimo exatamente as 950 vendas
-- NAO_FATURADA da Trusted, ao centavo.
--
-- Gatilho: evento em query-bZT5 (rfn_financeiro__inadimplencia_vbot), ultimo elo da
-- cadeia do Conexa, que e DIARIA (supabase-x0tz 01:00 -> 03:32). Pendurar nas Trusted
-- do meio nao garantiria que contrato, venda e cobranca ja tivessem materializado.
WITH cli AS (
  SELECT id_cliente, nome AS cliente, nome_fantasia, documento, is_pj, is_pf,
         segmento, uf, cidade, is_ativo AS cliente_is_ativo
  FROM `vanguardamartech_trusted`.`trs_conexa__cliente`
),
ctr AS (SELECT * FROM `vanguardamartech_trusted`.`trs_conexa__contrato` WHERE is_vigente_na_origem),
cob AS (SELECT * FROM `vanguardamartech_trusted`.`trs_conexa__cobranca`  WHERE is_vigente),
ven AS (SELECT * FROM `vanguardamartech_trusted`.`trs_conexa__venda`     WHERE is_vigente),

-- REGRA 3 -- quais vendas ja estao dentro de uma cobranca. `ids_venda` e array na
-- Trusted; 2.401 citadas e 2.401 casam, zero orfas.
venda_em_cobranca AS (
  SELECT DISTINCT CAST(v AS STRING) AS id_venda FROM cob, UNNEST(ids_venda) v
),
ven_m AS (
  SELECT v.*, (e.id_venda IS NOT NULL) AS tem_cobranca
  FROM ven v
  LEFT JOIN venda_em_cobranca e ON e.id_venda = CAST(v.id_venda AS STRING)
),

-- Janela DERIVADA das tres origens. Nenhuma data escrita a mao.
janela AS (
  SELECT m FROM UNNEST(GENERATE_DATE_ARRAY(
    (SELECT LEAST(MIN(DATE_TRUNC(data_inicio, MONTH)),
       (SELECT MIN(mes_competencia_data) FROM cob),
       (SELECT MIN(DATE_TRUNC(data_referencia_dia, MONTH)) FROM ven)) FROM ctr),
    (SELECT GREATEST(MAX(DATE_TRUNC(COALESCE(data_fim, CURRENT_DATE()), MONTH)),
       (SELECT MAX(mes_competencia_data) FROM cob),
       (SELECT MAX(DATE_TRUNC(data_referencia_dia, MONTH)) FROM ven)) FROM ctr),
    INTERVAL 1 MONTH)) m
),

-- REGRA 2 -- contrato vigente no mes pela DATA.
b_ctr AS (
  SELECT j.m AS mes_referencia, c.id_cliente,
    COUNT(*)                                                     AS qtd_contratos_vigentes,
    COUNTIF(c.valor_mensal_recorrente IS NULL)                   AS qtd_contratos_sem_valor,
    ROUND(SUM(c.valor_mensal_recorrente), 2)                     AS mrr_contratado,
    COUNTIF(DATE_TRUNC(c.data_inicio, MONTH) = j.m)              AS qtd_contratos_iniciados,
    COUNTIF(c.data_fim IS NOT NULL
            AND DATE_TRUNC(c.data_fim, MONTH) = j.m)             AS qtd_contratos_encerrados,
    TRUE                                                         AS _tem_contrato
  FROM janela j
  JOIN ctr c
    ON DATE_TRUNC(c.data_inicio, MONTH) <= j.m
   AND (c.data_fim IS NULL OR DATE_TRUNC(c.data_fim, MONTH) >= j.m)
  GROUP BY 1, 2
),
b_cob AS (
  SELECT mes_competencia_data AS mes_referencia, id_cliente,
    COUNT(*)                                        AS qtd_cobrancas,
    -- NULL AQUI E ZERO MEDIDO, NAO AUSENCIA -- e por isso leva IFNULL, ao contrario
    -- da taxa. `valor_pago` e NULL em 152 das 874 cobrancas vigentes e 151 delas tem
    -- `tem_pagamento = FALSE`: a origem escreve NULL onde nao houve pagamento, e nao
    -- houve pagamento e um fato. Mesmo caso de `valor_em_aberto`, NULL em 737 (as
    -- quitadas). Somar sem IFNULL faria o mes inteiro virar NULL por causa de uma linha.
    ROUND(SUM(IFNULL(valor_atual, 0)), 2)           AS valor_faturado,
    ROUND(SUM(IFNULL(valor_pago, 0)), 2)            AS valor_recebido,
    ROUND(SUM(IFNULL(valor_em_aberto, 0)), 2)       AS valor_em_aberto,
    ROUND(SUM(IF(is_inadimplencia, IFNULL(valor_em_aberto, 0), 0)), 2) AS valor_vencido,
    COUNTIF(is_quitada AND valor_pago IS NULL)      AS qtd_quitadas_sem_valor_pago,
    COUNTIF(is_inadimplencia)                       AS qtd_titulos_vencidos,
    COUNTIF(is_cancelada)                           AS qtd_cobrancas_canceladas,
    COUNTIF(tem_nfse)                               AS qtd_cobrancas_com_nfse,
    TRUE                                            AS _tem_cobranca
  FROM cob
  WHERE mes_competencia_data IS NOT NULL
  GROUP BY 1, 2
),
-- REGRA 3 -- so a venda SEM cobranca e aditiva com o faturado.
b_ven AS (
  SELECT DATE_TRUNC(data_referencia_dia, MONTH) AS mes_referencia, id_cliente,
    COUNT(*)                                                             AS qtd_vendas,
    COUNTIF(NOT tem_cobranca AND NOT is_cancelada)                       AS qtd_vendas_sem_cobranca,
    ROUND(SUM(IF(NOT tem_cobranca AND NOT is_cancelada, valor, 0)), 2)   AS valor_vendas_sem_cobranca,
    COUNTIF(is_cancelada)                                                AS qtd_vendas_canceladas,
    COUNTIF(is_recorrente)                                               AS qtd_vendas_recorrentes,
    TRUE                                                                 AS _tem_venda
  FROM ven_m
  WHERE data_referencia_dia IS NOT NULL
  GROUP BY 1, 2
),
chaves AS (
  SELECT mes_referencia, id_cliente FROM b_ctr
  UNION DISTINCT SELECT mes_referencia, id_cliente FROM b_cob
  UNION DISTINCT SELECT mes_referencia, id_cliente FROM b_ven
)
SELECT
  CONCAT(CAST(k.id_cliente AS STRING), ':',
         FORMAT_DATE('%Y-%m', k.mes_referencia))         AS id_receita_vbot_mensal,
  k.id_cliente,
  c.cliente,
  c.nome_fantasia,
  c.documento,
  c.is_pj,
  c.is_pf,
  c.segmento,
  c.uf,
  c.cidade,
  c.cliente_is_ativo,
  k.mes_referencia,
  -- REGRA 6 -- futuro e agenda, e se marca.
  (k.mes_referencia > DATE_TRUNC(CURRENT_DATE(), MONTH)) AS flag_mes_futuro,

  -- Bloco CONTRATO
  IFNULL(t.qtd_contratos_vigentes, 0)                    AS qtd_contratos_vigentes,
  IFNULL(t.qtd_contratos_sem_valor, 0)                   AS qtd_contratos_sem_valor,
  t.mrr_contratado,
  IFNULL(t.qtd_contratos_iniciados, 0)                   AS qtd_contratos_iniciados,
  IFNULL(t.qtd_contratos_encerrados, 0)                  AS qtd_contratos_encerrados,

  -- Bloco COBRANCA (faturamento por competencia)
  IFNULL(o.qtd_cobrancas, 0)                             AS qtd_cobrancas,
  o.valor_faturado,
  o.valor_recebido,
  o.valor_em_aberto,
  o.valor_vencido,
  IFNULL(o.qtd_titulos_vencidos, 0)                      AS qtd_titulos_vencidos,
  IFNULL(o.qtd_cobrancas_canceladas, 0)                  AS qtd_cobrancas_canceladas,
  IFNULL(o.qtd_cobrancas_com_nfse, 0)                    AS qtd_cobrancas_com_nfse,
  IFNULL(o.qtd_quitadas_sem_valor_pago, 0)               AS qtd_quitadas_sem_valor_pago,
  -- REGRA 5 -- sem faturamento, NULL. Nunca zero.
  ROUND(SAFE_DIVIDE(o.valor_recebido, NULLIF(o.valor_faturado, 0)), 6) AS taxa_recebimento,

  -- Bloco VENDA -- so o que ainda NAO virou cobranca (REGRA 3)
  IFNULL(v.qtd_vendas, 0)                                AS qtd_vendas,
  IFNULL(v.qtd_vendas_sem_cobranca, 0)                   AS qtd_vendas_sem_cobranca,
  v.valor_vendas_sem_cobranca,
  IFNULL(v.qtd_vendas_canceladas, 0)                     AS qtd_vendas_canceladas,
  IFNULL(v.qtd_vendas_recorrentes, 0)                    AS qtd_vendas_recorrentes,

  (t._tem_contrato IS NULL)                              AS flag_sem_contrato_no_mes,
  (o._tem_cobranca IS NULL)                              AS flag_sem_cobranca_no_mes,
  (o._tem_cobranca IS NULL AND t._tem_contrato IS NOT NULL) AS flag_contratado_sem_faturar,
  (IFNULL(t.qtd_contratos_iniciados, 0) > 0)             AS flag_entrou_no_mes,
  (IFNULL(t.qtd_contratos_encerrados, 0) > 0)            AS flag_saiu_no_mes,

  'L4_PERSONAL_DATA'                                     AS classificacao_dado,
  CURRENT_TIMESTAMP()                                    AS _extraido_at
FROM chaves k
LEFT JOIN b_ctr t USING (mes_referencia, id_cliente)
LEFT JOIN b_cob o USING (mes_referencia, id_cliente)
LEFT JOIN b_ven v USING (mes_referencia, id_cliente)
LEFT JOIN cli   c ON c.id_cliente = k.id_cliente
