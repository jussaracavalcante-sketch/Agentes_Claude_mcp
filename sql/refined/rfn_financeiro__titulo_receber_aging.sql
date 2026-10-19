-- rfn_financeiro__titulo_receber_aging  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (a Trusted e L4; nome, documento, e-mail, telefone e vendedor NAO atravessam)
-- Grao: sistema de origem x operacao x identificacao do cliente x SITUACAO do titulo x faixa de aging. Le: trs_financeiro__titulo_receber (query-jeJR).
-- Gatilho: evento em query-jeJR. Cadencia herdada: semanal (segunda 06:50 America/Manaus).
-- VALIDACAO (2026-10-19): 37 linhas, 37 chaves; 3.490 titulos, face R$ 18.818.306,58, pago R$ 12.581.547,19, saldo R$ 6.141.271,75 e diferenca_face R$ 95.487,64 em 1.008 titulos (= Trusted); PAGO 2.222, EM_ABERTO 1.204, NEGOCIADO 31, CANCELADO 15, PERDIDO 13, QUITADO_SEM_MARCA_DE_PAGO 5; todo EM_ABERTO tem faixa e nenhum outro tem; saldo em aberto ja vencido R$ 1.440.612.
-- REGRA 1 - AGREGA, NAO FILTRA: soma das linhas = Trusted (3.490 titulos, face R$ 18.818.306,58, pago R$ 12.581.547,19, saldo R$ 6.141.271,75 em 19/10/2026).
-- REGRA 2 - SITUACAO VEM DE `is_pago` E DO STATUS TERMINAL, NA ORDEM: PAGO (is_pago) > QUITADO_SEM_MARCA_DE_PAGO (status quitado/paid com is_pago FALSE: 5 titulos que a origem se contradiz)
--   > PERDIDO (LOST, PERDIDO) > CANCELADO (cancelled) > NEGOCIADO (negotiated) > EM_ABERTO. So EM_ABERTO tem faixa de aging.
-- REGRA 3 - AGING VEM DA DATA, NUNCA DO ROTULO: faixa = dias entre data_vencimento e a DATA DA CARGA da Trusted (A_VENCER, 01_30, 31_60, 61_90, 91_180, 181_MAIS); os rotulos PENDING/OVERDUE
--   da origem nao mandam. Fora de EM_ABERTO a faixa e NULL, nunca zero.
-- REGRA 4 - `valor_face - valor_pago - saldo_aberto` NAO fecha em 1.008 titulos (juros, multa, desconto): `diferenca_face` soma a diferenca, e nada e recalculado.
-- LIMITACOES - NAO CONTORNE: e a visao do Supabase sobre titulos a receber, NAO e a inadimplencia oficial (rfn_financeiro__fluxo_caixa para BRM e VD, rfn_financeiro__inadimplencia_vbot para a VBOT) e NAO soma com
--   elas; o aging e relativo a DATA DA CARGA (semanal): para corte estavel use data_vencimento da Trusted contra a data escolhida; o balde SEM_PESSOA (300 titulos) fica no grao e nao e cliente;
--   vencimento ate 2028-09 (titulos futuros contam em A_VENCER).
WITH t AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__titulo_receber`
),
k AS (
  SELECT
    t.*,
    DATE(_extraido_at, 'America/Sao_Paulo') AS data_carga,
    CASE
      WHEN flag_sem_pessoa THEN 'SEM_PESSOA'
      WHEN is_pj THEN 'PJ'
      WHEN is_pf THEN 'PF'
      WHEN flag_documento_invalido THEN 'DOCUMENTO_INVALIDO'
      WHEN id_cliente_conexa IS NOT NULL THEN 'ID_CONEXA'
      ELSE 'SEM_DOCUMENTO'
    END AS tipo_identificacao,
    CASE
      WHEN is_pago THEN 'PAGO'
      WHEN status_origem IN ('ACQUITTED', 'QUITADO', 'paid') THEN 'QUITADO_SEM_MARCA_DE_PAGO'
      WHEN status_origem IN ('LOST', 'PERDIDO') THEN 'PERDIDO'
      WHEN status_origem = 'cancelled' THEN 'CANCELADO'
      WHEN status_origem = 'negotiated' THEN 'NEGOCIADO'
      ELSE 'EM_ABERTO'
    END AS situacao
  FROM t
),
f AS (
  SELECT
    k.*,
    CASE
      WHEN situacao <> 'EM_ABERTO' THEN NULL
      WHEN DATE_DIFF(data_carga, data_vencimento, DAY) <= 0   THEN 'A_VENCER'
      WHEN DATE_DIFF(data_carga, data_vencimento, DAY) <= 30  THEN '01_30'
      WHEN DATE_DIFF(data_carga, data_vencimento, DAY) <= 60  THEN '31_60'
      WHEN DATE_DIFF(data_carga, data_vencimento, DAY) <= 90  THEN '61_90'
      WHEN DATE_DIFF(data_carga, data_vencimento, DAY) <= 180 THEN '91_180'
      ELSE '181_MAIS'
    END AS faixa_aging
  FROM k
),
g AS (
  SELECT
    sistema_origem,
    operacao,
    tipo_identificacao,
    situacao,
    faixa_aging,
    COUNT(*)                                       AS qtd_titulos,
    ROUND(SUM(valor_face), 2)                      AS valor_face,
    ROUND(SUM(valor_pago), 2)                      AS valor_pago,
    ROUND(SUM(saldo_aberto), 2)                    AS saldo_aberto,
    ROUND(SUM(diferenca_face), 2)                  AS diferenca_face,
    COUNTIF(diferenca_face <> 0)                   AS qtd_com_diferenca_face,
    COUNTIF(flag_pago_sem_data)                    AS qtd_pago_sem_data,
    COUNTIF(flag_pago_com_saldo)                   AS qtd_pago_com_saldo,
    MIN(data_vencimento)                           AS primeiro_vencimento,
    MAX(data_vencimento)                           AS ultimo_vencimento,
    MAX(data_carga)                                AS data_carga_trusted
  FROM f
  GROUP BY sistema_origem, operacao, tipo_identificacao, situacao, faixa_aging
),
final AS (
  SELECT
    CONCAT(sistema_origem, '|', operacao, '|', tipo_identificacao, '|', situacao, '|', IFNULL(faixa_aging, '~')) AS id_titulo_aging,
    g.*,
    'L3_CONFIDENTIAL' AS classificacao_dado
  FROM g
)
SELECT
  x.*,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(x)))     AS _payload_hash
FROM final x
