-- trs_conexa__despesa  ·  query-rbJW  ·  1.458 linhas  ·  L3 CONFIDENTIAL
-- Trusted / Conexa (VBOT). Grao: uma despesa (conta a pagar). Chave: id_despesa (conexa_id).
-- Origem: supabase-x0tz, public-fato_despesa_vbot. Gatilho: evento em query-T3ct.
-- O lado do custo da VBOT. O vivo soma R$ 3.065.689,75.
--
-- REGRA 1 — 240 DAS 1.458 (16,5%) JA FORAM APAGADAS NO CONEXA — a maior taxa da familia
--   (cobranca 7,7%, venda 5,2%). `is_vigente` e a porta de entrada de qualquer leitura.
-- REGRA 2 — `valor_em_aberto` so existe em despesa nao paga e nao cancelada; NULL, nunca zero.
--   `valor_pago` cobre 818 das 1.458 — nas demais e ausencia de baixa, nao pagamento zero.
-- REGRA 3 — DOIS CAMPOS MORTOS FICAM DE FORA: digitable_line NULL nas 1.458 e is_reconciled
--   FALSE nas 1.458 — NAO HA UMA UNICA DESPESA CONCILIADA nesta base, entao nao da para medir
--   conciliacao bancaria por aqui.
-- REGRA 4 — `centros_custo` chega como TEXTO com array de rateio dentro
--   ([{"id": 1, "percentage": 100}]) e sai desaninhado. UMA DESPESA PODE RATEAR EM MAIS DE UM
--   CENTRO: somar por centro sem desaninhar atribui o valor inteiro a um so, e desaninhar sem
--   ponderar pelo percentage multiplica. A Trusted entrega o array e NAO decide o rateio.
-- REGRA 5 — O CAC E MARCADO E QUASE NAO EXISTE: cac_incluido TRUE em 3 das 1.458.
-- REGRA 6 — A LIGACAO COM A COBRANCA COBRE 4 LINHAS (charge_id). Nao da para reconciliar
--   despesa contra cobranca por id; o que existe e a competencia.
--
-- COBERTURA (2026-09-25): 818 pagas · 710 com forma de pagamento · 3 status · 2 tipos.
-- FUSO: as datas sao DATE na origem; conexa_updated_at e processed_at sao carimbo (UTC).
--
-- LIMITACOES — NAO CONTORNE
--   1. O BRONZE NAO E ESTADO: bronze-conexa__bills tem 3.025 linhas para 1.458 despesas.
--   2. id_categoria, id_subcategoria, id_fornecedor e id_conta_financeira saem crus — as
--      dimensoes existem no Supabase e nao foram tratadas nesta passada.
--   3. NAO SOMAR COM O CUSTO DA CASA: isto e VBOT, o iClips e o Conta Azul sao BRM e VD.

WITH final AS (
  SELECT
    d.conexa_id                                     AS id_despesa,
    d.company_id                                    AS id_empresa,
    d.supplier_id                                   AS id_fornecedor,
    d.account_id                                    AS id_conta_financeira,
    d.category_id                                   AS id_categoria,
    d.subcategory_id                                AS id_subcategoria,
    d.charge_id                                     AS id_cobranca_ligada,
    d.parent_bill_id                                AS id_despesa_pai,
    d.original_bill_id                              AS id_despesa_original,
    d.recurrent_bill_id                             AS id_despesa_recorrente,

    d.presente_no_origem                            AS is_vigente,
    (NOT d.presente_no_origem)                      AS flag_apagado_na_origem,

    d.descricao,
    d.tipo                                          AS tipo_despesa,
    d.status                                        AS status_origem,
    CASE d.status
      WHEN 'paid'      THEN 'PAGA'
      WHEN 'unpaid'    THEN 'EM_ABERTO'
      WHEN 'cancelled' THEN 'CANCELADA'
      ELSE 'OUTRO'
    END                                             AS status_canonico,
    (d.status = 'paid')                             AS is_paga,
    (d.status = 'cancelled')                        AS is_cancelada,

    d.amount                                        AS valor,
    d.paid_amount                                   AS valor_pago,
    IF(d.status = 'unpaid', d.amount, NULL)         AS valor_em_aberto,
    IF(d.paid_amount IS NOT NULL,
       ROUND(d.paid_amount - d.amount, 2), NULL)    AS diferenca_pago_menos_valor,

    d.due_date                                      AS data_vencimento,
    d.payment_date                                  AS data_pagamento,
    d.competence_date                               AS data_competencia,
    d.document_date                                 AS data_documento,
    DATE_TRUNC(d.competence_date, MONTH)            AS mes_competencia_data,
    d.mes_referencia,
    d.ano_referencia,
    (d.payment_date IS NOT NULL)                    AS tem_pagamento,
    IF(d.status = 'unpaid' AND d.presente_no_origem
         AND d.due_date < CURRENT_DATE('America/Sao_Paulo'),
       DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), d.due_date, DAY), NULL)
                                                    AS dias_vencido,
    (d.status = 'unpaid' AND d.presente_no_origem
      AND d.due_date < CURRENT_DATE('America/Sao_Paulo'))
                                                    AS is_atraso_a_pagar,

    d.document_number                               AS numero_documento,
    d.installment_number                            AS numero_parcela,
    d.payment_method_id                             AS id_forma_pagamento,
    d.cac_incluido                                  AS is_cac,
    d.cac_percentual                                AS cac_percentual,

    JSON_QUERY_ARRAY(d.centros_custo)               AS rateio_centro_custo,
    ARRAY_LENGTH(JSON_QUERY_ARRAY(d.centros_custo)) AS qtd_centros_custo,
    (ARRAY_LENGTH(JSON_QUERY_ARRAY(d.centros_custo)) > 1) AS flag_rateio_multiplo,

    d.conexa_updated_at                             AS atualizado_na_origem_em,
    d.processed_at
  FROM `vanguardamartech_raw`.`supabase_public_fato_despesa_vbot` d
)
SELECT
  f.*,
  'L3_CONFIDENTIAL'                             AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz'                               AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                AS _payload_hash
FROM final f
