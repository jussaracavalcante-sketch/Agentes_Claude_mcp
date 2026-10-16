-- trs_conexa__cobranca  ·  query-6qKc  ·  933 linhas  ·  L3 CONFIDENTIAL
-- Trusted / Conexa (VBOT). Grao: uma cobranca. Chave: id_cobranca (conexa_id).
-- Origem: supabase-x0tz, public-fato_cobranca_vbot. Gatilho: evento em query-mbpv.
-- O FATO CENTRAL da operacao da VBOT. Competencia 2025-12 a 2026-10.
--
-- REGRA 1 — 72 COBRANCAS JA FORAM APAGADAS NO CONEXA E VALEM QUASE O MESMO QUE O SALDO VIVO:
--     unpaid, presente na origem ... 121 ... R$ 158.263,10
--     unpaid, APAGADA na origem ..... 72 ... R$ 148.032,30
--   Somar o aberto sem filtrar QUASE DOBRA a inadimplencia. `is_vigente` e a porta de entrada
--   de qualquer leitura de valor. Isto resolve, para esta familia, o que o documento de LGPD
--   da casa declarou em aberto — "registro apagado na origem permanece no warehouse
--   indefinidamente": aqui a esteira MARCA em vez de deixar invisivel.
-- REGRA 2 — TRES VALORES QUE NAO SAO O MESMO NUMERO. 226 das 933 tem current_amount != amount
--   (juros, multa, desconto) e no agregado o pago SUPERA a face: R$ 1.227.756,08 contra
--   R$ 1.219.773,48 nas 706 quitadas. Usar `amount` como caixa erra na linha.
-- REGRA 3 — `valor_em_aberto` so existe em cobranca nao quitada e nao cancelada; NULL, nunca
--   zero — zero seria somado e apareceria como saldo.
-- REGRA 4 — QUATRO STATUS: paid 706 · unpaid 193 · negotiated 20 · cancelled 14.
--   `negotiated` NAO e quitada (R$ 37.920,45) e um filtro status<>'unpaid' a esconderia.
--   status_canonico cai em OUTRO se a origem inventar um quinto.
-- REGRA 5 — A INADIMPLENCIA VEM DA DATA: em aberto + vigente + vencimento anterior a hoje.
--   Colunas relativas a DATA DA CARGA; para corte historico estavel comparar a data, nao a flag.
-- REGRA 6 — TRES CAMPOS MORTOS FICAM DE FORA: cancel_date NULL nas 933 (embora existam 14
--   cancelled), iss_amount NULL nas 933 e has_iss_retention FALSE nas 933.
-- REGRA 7 — `sales_ids` chega como TEXTO com array dentro e sai como array em `ids_venda`
--   (806 das 933 tem pelo menos uma). UMA COBRANCA AGRUPA VARIAS VENDAS — juntar sem
--   desaninhar multiplica a linha da cobranca.
--
-- COBERTURA (2026-09-25): 639 com NFSe · 98 parcelas alem da 1a · 11 com pai · 11 com original
--   · 4 com desconto · 15 com competencia futura.
-- FUSO: as datas sao DATE na origem; conexa_updated_at e processed_at sao carimbo (UTC).
--
-- LIMITACOES — NAO CONTORNE
--   1. NAO SOMAR COM O FINANCEIRO DA CASA: isto e VBOT, o iClips e o Conta Azul sao BRM e VD.
--   2. O BRONZE NAO E ESTADO: bronze-conexa__charges tem 5.197 linhas para 933 cobrancas.
--   3. `valor_pago` e o acumulado da cobranca, nao baixa individual — nao ha conta bancaria
--      nem metodo efetivo aqui, so `forma_recebimento`, que e o previsto.
--   4. A competencia vai ate 2026-10; flag_competencia_futura marca as 15.

WITH base AS (
  SELECT * FROM `vanguardamartech_raw`.`supabase_public_fato_cobranca_vbot`
),
final AS (
  SELECT
    c.conexa_id                                     AS id_cobranca,
    c.customer_id                                   AS id_cliente,
    c.account_id                                    AS id_conta_financeira,
    c.company_id                                    AS id_empresa,

    c.presente_no_origem                            AS is_vigente,
    (NOT c.presente_no_origem)                      AS flag_apagado_na_origem,

    c.tipo                                          AS tipo_cobranca,
    c.status                                        AS status_origem,
    CASE c.status
      WHEN 'paid'       THEN 'QUITADA'
      WHEN 'unpaid'     THEN 'EM_ABERTO'
      WHEN 'negotiated' THEN 'NEGOCIADA'
      WHEN 'cancelled'  THEN 'CANCELADA'
      ELSE 'OUTRO'
    END                                             AS status_canonico,
    (c.status = 'paid')                             AS is_quitada,
    (c.status = 'cancelled')                        AS is_cancelada,
    c.origin                                        AS origem_cobranca,
    c.receiving_method                              AS forma_recebimento,

    c.amount                                        AS valor_original,
    c.current_amount                                AS valor_atual,
    c.paid_amount                                   AS valor_pago,
    c.raw_amount                                    AS valor_bruto,
    c.discount_amount                               AS valor_desconto,
    ROUND(c.current_amount - c.amount, 2)           AS diferenca_atual_menos_original,
    (ABS(COALESCE(c.current_amount, 0) - COALESCE(c.amount, 0)) > 0.005)
                                                    AS flag_valor_alterado,
    IF(c.status IN ('unpaid', 'negotiated'), COALESCE(c.current_amount, c.amount), NULL)
                                                    AS valor_em_aberto,

    c.due_date                                      AS data_vencimento,
    c.payment_date                                  AS data_pagamento,
    c.competence_date                               AS data_competencia,
    DATE_TRUNC(c.competence_date, MONTH)            AS mes_competencia_data,
    c.mes_referencia,
    c.ano_referencia,
    (c.payment_date IS NOT NULL)                    AS tem_pagamento,
    IF(c.payment_date IS NOT NULL,
       DATE_DIFF(c.payment_date, c.due_date, DAY), NULL)
                                                    AS dias_vencimento_ate_pagamento,
    IF(c.status IN ('unpaid', 'negotiated') AND c.presente_no_origem
         AND c.due_date < CURRENT_DATE('America/Sao_Paulo'),
       DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), c.due_date, DAY), NULL)
                                                    AS dias_vencido,
    (c.status IN ('unpaid', 'negotiated') AND c.presente_no_origem
      AND c.due_date < CURRENT_DATE('America/Sao_Paulo'))
                                                    AS is_inadimplencia,
    (c.competence_date > CURRENT_DATE('America/Sao_Paulo'))
                                                    AS flag_competencia_futura,

    c.installment_number                            AS numero_parcela,
    c.total_installments                            AS total_parcelas,
    (c.total_installments > 1)                      AS is_parcelada,
    c.father_charge_id                              AS id_cobranca_pai,
    c.original_charge_id                            AS id_cobranca_original,

    c.tax_invoice_number                            AS numero_nfse,
    (c.tax_invoice_number IS NOT NULL)              AS tem_nfse,
    c.notes                                         AS observacoes,
    c.customer_views                                AS visualizacoes_do_cliente,

    JSON_VALUE_ARRAY(c.sales_ids)                   AS ids_venda,
    ARRAY_LENGTH(JSON_VALUE_ARRAY(c.sales_ids))     AS qtd_vendas_na_cobranca,

    c.conditional_discount_type                     AS desconto_condicional_tipo,
    c.conditional_discount_amount                   AS desconto_condicional_valor,
    c.conditional_discount_pct                      AS desconto_condicional_pct,
    c.conditional_discount_date                     AS desconto_condicional_ate,

    c.conexa_updated_at                             AS atualizado_na_origem_em,
    c.processed_at
  FROM base c
)
SELECT
  f.*,
  'L3_CONFIDENTIAL'                             AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz'                               AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                AS _payload_hash
FROM final f
