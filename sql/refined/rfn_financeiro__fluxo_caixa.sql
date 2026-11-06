-- rfn_financeiro__fluxo_caixa  ·  query-FDpl  ·  5.237 linhas  ·  L4 PERSONAL_DATA
-- Refined / financeiro. Grao: uma PARCELA do razao Conta Azul em um REGIME de caixa.
-- Chave: id_fluxo = `<id_movimento>:<regime>`. Origem: trs_contazul__movimento (query-rtu2).
-- Gatilho: evento em query-rtu2. Cadencia herdada: semanal.
--
-- O QUE RESPONDE: fluxo de caixa por dia, caixa REALIZADO x PROJETADO, aging de contas a
--   receber e a pagar, e inadimplencia de BRM e VD — tres das cinco perguntas que os
--   documentos de camada semantica do Financeiro (a034ca75) e do Account (64dc365b)
--   declaravam so existirem na camada RAW, que a §18 proibe a IA de consultar.
-- O QUE NAO RESPONDE: inadimplencia da VBOT (a operacao nao existe no razao Conta Azul) e
--   "o que esta por faturar" antes de virar parcela (vive no funil, ainda na Raw).
--
-- REGRA 1 — DOIS REGIMES, E ELES NAO SE SOBREPOEM EM DINHEIRO.
--   REALIZADO: data_caixa = data da BAIXA, valor_caixa = valor_pago. 3.205 linhas,
--     R$ 21.227.444,68 — bate ao centavo com SUM(valor_pago) do razao.
--   PREVISTO: data_caixa = VENCIMENTO, valor_caixa = valor_nao_pago. 2.032 linhas,
--     R$ 9.793.507,73 — bate ao centavo com SUM(valor_nao_pago).
--   Parcela PARCIALMENTE paga aparece nos DOIS regimes com o valor repartido (3 casos), e
--   por isso somar a tabela inteira nao duplica.
-- REGRA 2 — AS 16 PARCELAS ZERADAS FICAM DE FORA. valor_pago = 0 E valor_nao_pago = 0, com
--   R$ 30.252,20 de FACE. Nao sao caixa nem saldo. 5.250 vigentes -> 5.237 linhas
--   (5.234 parcelas, 3 em dois regimes, 16 ausentes).
-- REGRA 3 — O QUE ENTROU NO BANCO NAO E A FACE, em 760 parcelas (juros, multa, desconto na
--   baixa). valor_pago + valor_nao_pago rompe a face em 772 de 5.250 — 694 para mais, 78
--   para menos, maior diferenca R$ 10.167,16. Caixa = `valor_caixa`; `valor_face` fica ao
--   lado e `diferenca_para_a_face` mostra o quanto, com sinal.
-- REGRA 4 — A SITUACAO VEM DA DATA, NUNCA DO STATUS DA ORIGEM. 395 parcelas estao vencidas
--   pela data e **285 delas NAO carregam `ATRASADO`** — filtrar pelo status perde 72%.
-- REGRA 5 — AS COLUNAS RELATIVAS A HOJE sao relativas a DATA DA CARGA (`situacao`,
--   `dias_vencido`, `faixa_aging`, `is_inadimplencia`). Para corte historico estavel,
--   comparar `data_caixa` contra a data escolhida — nunca guardar a flag.
-- REGRA 6 — `valor_caixa` e sempre positivo; `valor_caixa_liquido` tem sinal (ENTRADA +,
--   SAIDA -), para que a soma direta por dia de o caixa liquido.
-- REGRA 7 — `is_inadimplencia` = ENTRADA + PREVISTO + vencido, fora de TRANSFERENCIA,
--   FINANCEIRO e SOCIOS. Medido: 233 parcelas e R$ 1.046.743,14 a receber vencidos, contra
--   162 e R$ 481.933,17 a pagar em atraso; 171 parcelas e R$ 829.218,24 na faixa 01-30.
-- REGRA 8 — TRANSFERENCIA ENTRE CONTAS NAO E CAIXA DA OPERACAO (`is_caixa_operacional`):
--   o Conta Azul lanca dos dois lados e sem o filtro o mesmo dinheiro entra e sai.
-- REGRA 9 — 1 PARCELA PAGA SEM DATA DE BAIXA (R$ 27.500) entra com o VENCIMENTO e
--   `flag_data_caixa_estimada` acesa. Descarta-la faria o caixa divergir do razao; a
--   alternativa nao tomada era deixar a linha sem data.
--
-- LINHA DE BASE (2026-09-25) — caixa realizado por mes: 2026-05 R$ 15.501,23 (5 parcelas,
--   cauda da migracao) · 06 R$ 5,40 mi · 07 R$ 7,12 mi · 08 R$ 6,91 mi · 09 (ate o dia 15)
--   R$ 1,75 mi. Saldo previsto: R$ 8.264.831,42 a vencer, R$ 1.528.676,31 vencido.
--
-- LIMITACOES — NAO CONTORNE
--   1. O CAIXA REALIZADO COMECA EM 25/05/2026 — nenhuma baixa anterior, embora a
--      competencia va ate 2025-02: o Conta Azul recebeu os saldos em aberto na migracao.
--      Serie de caixa antes de junho/2026 NAO EXISTE nesta base, e o iClips, que cobre o
--      periodo anterior, nao registra data de pagamento por parcela.
--   2. NAO SOMAR com trs_financeiro__movimento nem com rfn_financeiro__receita_cliente_mensal:
--      aquelas medem COMPETENCIA e esta mede CAIXA, sobre periodos que se sobrepoem de
--      2025-12 a 2026-05.
--   3. DUAS OPERACOES, NAO TRES: BRM e VD. Nao ha VBOT.
--   4. 1.407 de 5.237 linhas (26,9%) sem contraparte identificada — aging POR CLIENTE
--      cobre 73%, e a cobertura vai junto com o numero.
--   5. CONTA BANCARIA E METODO so existem no REALIZADO (so a baixa os carrega). No PREVISTO
--      saem NULL, e isso e ausencia de informacao, nao "sem conta".
--   6. `data_caixa` do PREVISTO e o vencimento CONTRATADO, nao previsao de recebimento.
--   7. CADENCIA SEMANAL, herdada: o razao e extraido todo dia, mas a dimensao de entidade
--      vem do MySQL do VJOB, que roda domingo. Latencia de ate 6 dias.
--
-- L4 por LINHAGEM: o nivel sobe e nunca desce sem prova escrita, e aqui nao ha prova — a
--   tabela mantem o grao da parcela e propaga `contraparte_documento` (com CPF de PF) e as
--   categorias de socio, que carregam nome proprio no rotulo. NAO publicar em painel sem
--   filtrar `is_folha_pessoal = FALSE`.

WITH vigente AS (
  SELECT *
  FROM `vanguardamartech_trusted`.`trs_contazul__movimento`
  WHERE is_vigente
),
realizado AS (
  SELECT
    'REALIZADO'                                   AS regime,
    COALESCE(v.data_pagamento, v.data_vencimento) AS data_caixa,
    (v.data_pagamento IS NULL)                    AS flag_data_caixa_estimada,
    v.valor_pago                                  AS valor_caixa,
    v.conta_bancaria,
    v.banco,
    v.metodo_pagamento,
    v.is_conciliado,
    v.* EXCEPT (conta_bancaria, banco, metodo_pagamento, is_conciliado)
  FROM vigente v
  WHERE v.valor_pago > 0
),
previsto AS (
  SELECT
    'PREVISTO'                                    AS regime,
    v.data_vencimento                             AS data_caixa,
    FALSE                                         AS flag_data_caixa_estimada,
    v.valor_nao_pago                              AS valor_caixa,
    CAST(NULL AS STRING)                          AS conta_bancaria,
    CAST(NULL AS STRING)                          AS banco,
    CAST(NULL AS STRING)                          AS metodo_pagamento,
    CAST(NULL AS BOOL)                            AS is_conciliado,
    v.* EXCEPT (conta_bancaria, banco, metodo_pagamento, is_conciliado)
  FROM vigente v
  WHERE v.valor_nao_pago > 0
),
uniao AS (
  SELECT * FROM realizado
  UNION ALL
  SELECT * FROM previsto
),
final AS (
  SELECT
    CONCAT(u.id_movimento, ':', u.regime)         AS id_fluxo,
    u.id_movimento,
    u.regime,
    (u.regime = 'REALIZADO')                      AS is_realizado,

    u.data_caixa,
    DATE_TRUNC(u.data_caixa, MONTH)               AS mes_caixa,
    u.flag_data_caixa_estimada,

    -- REGRA 4: a situacao vem da DATA, nunca do rotulo de status da origem
    CASE
      WHEN u.regime = 'REALIZADO'                                        THEN 'PAGO'
      WHEN u.data_caixa < CURRENT_DATE('America/Sao_Paulo')              THEN 'VENCIDO'
      ELSE                                                                    'A_VENCER'
    END                                                                  AS situacao,
    IF(u.regime = 'PREVISTO' AND u.data_caixa < CURRENT_DATE('America/Sao_Paulo'),
       DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), u.data_caixa, DAY), NULL)
                                                                         AS dias_vencido,
    CASE
      WHEN u.regime = 'REALIZADO' THEN NULL
      WHEN DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), u.data_caixa, DAY) <=   0 THEN 'A_VENCER'
      WHEN DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), u.data_caixa, DAY) <=  30 THEN '01_30'
      WHEN DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), u.data_caixa, DAY) <=  60 THEN '31_60'
      WHEN DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), u.data_caixa, DAY) <=  90 THEN '61_90'
      WHEN DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), u.data_caixa, DAY) <= 180 THEN '91_180'
      ELSE '181_MAIS'
    END                                                                  AS faixa_aging,

    u.operacao,
    u.sentido,
    u.valor_caixa,
    -- entrada positiva, saida negativa: soma direta da o caixa liquido
    IF(u.sentido = 'ENTRADA', u.valor_caixa, -u.valor_caixa)             AS valor_caixa_liquido,
    u.valor                                                              AS valor_face,
    -- REGRA 3: o pago difere do valor de face (juros, multa, desconto)
    IF(u.regime = 'REALIZADO', ROUND(u.valor_caixa - u.valor, 2), NULL)  AS diferenca_para_a_face,

    u.classe_financeira,
    (u.classe_financeira NOT IN ('TRANSFERENCIA'))                       AS is_caixa_operacional,
    (u.sentido = 'ENTRADA' AND u.classe_financeira = 'RECEITA')          AS is_receita_operacional,
    (u.sentido = 'SAIDA'   AND u.classe_financeira = 'OPERACIONAL')      AS is_custo_operacional,
    u.categoria,
    u.categoria_normalizada,
    u.origem_da_categoria,
    u.flag_sem_categoria,

    u.id_entidade_contaazul,
    u.contraparte,
    u.contraparte_documento,
    u.contraparte_is_pj,
    u.contraparte_is_pf,
    u.contraparte_is_cliente,
    u.contraparte_is_fornecedor,
    u.flag_sem_contraparte,
    u.flag_contraparte_nao_catalogada,
    -- REGRA 7: inadimplencia e saldo VENCIDO a receber de terceiro
    (u.regime = 'PREVISTO' AND u.sentido = 'ENTRADA'
      AND u.data_caixa < CURRENT_DATE('America/Sao_Paulo')
      AND u.classe_financeira NOT IN ('TRANSFERENCIA', 'FINANCEIRO', 'SOCIOS'))
                                                                         AS is_inadimplencia,

    u.conta_bancaria,
    u.banco,
    u.metodo_pagamento,
    u.is_conciliado,

    u.data_competencia,
    u.mes_competencia,
    u.data_vencimento,
    u.data_pagamento,
    DATE_DIFF(u.data_vencimento, u.data_competencia, DAY)                AS dias_competencia_ate_vencimento,
    IF(u.regime = 'REALIZADO' AND u.data_pagamento IS NOT NULL,
       DATE_DIFF(u.data_pagamento, u.data_vencimento, DAY), NULL)        AS dias_vencimento_ate_pagamento,

    u.status_canonico,
    u.is_categoria_pessoal,
    u.is_folha_pessoal
  FROM uniao u
)
SELECT
  f.*,
  'L4_PERSONAL_DATA'                            AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz | mysql-yIOn'                  AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                AS _payload_hash
FROM final f
