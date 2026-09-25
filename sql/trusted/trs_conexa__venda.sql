-- trs_conexa__venda  ·  query-T3ct  ·  3.638 linhas  ·  L3 CONFIDENTIAL
-- Trusted / Conexa (VBOT). Grao: uma venda (item cobravel). Chave: id_venda (conexa_id).
-- Origem: supabase-x0tz, public-fato_venda_vbot. Gatilho: evento em query-54P5.
-- E o item que compoe a cobranca: uma cobranca agrupa varias vendas.
--
-- REGRA 1 — SETE STATUS, E ELES NAO SAO UMA ESCADA: paid, partiallyPaid, billed,
--   billedNegociated, notBilled, cancelled, billedCancelled. TRES EIXOS convivem na mesma
--   coluna (faturada, paga, cancelada), e por isso saem tres flags independentes alem do
--   canonico — `billedCancelled` e faturada E cancelada ao mesmo tempo.
-- REGRA 2 — 927 VENDAS TIVERAM O VALOR ALTERADO, E SAO EXATAMENTE AS 927 COM DESCONTO.
--   amount difere de original_amount em 927 de 3.638 (25,5%) e o conjunto e o mesmo das que
--   tem discount_value > 0 — nao e coincidencia, e o mecanismo.
-- REGRA 3 — `is_vigente` E A PORTA DE ENTRADA: 189 das 3.638 ja foram apagadas no Conexa.
--   O vivo soma R$ 1.919.496,58.
-- REGRA 4 — A LIGACAO COM CONTRATO COBRE 27%: 965 de 3.638 tem contract_id, 2.476 tem
--   recurring_sale_id e apenas 148 tem product_id. O que cobre 100% e `nome_produto`, que vem
--   como TEXTO na linha — a leitura por produto se faz pelo rotulo, nao pelo id, e isso e uma
--   limitacao, nao uma escolha.
--
-- FUSO: reference_date e TIMESTAMP e sai como veio, com o dia ao lado em DATE;
--   conexa_updated_at e processed_at sao carimbo de sistema (UTC).
--
-- LIMITACOES — NAO CONTORNE
--   1. O BRONZE NAO E ESTADO: bronze-conexa__sales tem 9.417 linhas para 3.638 vendas.
--   2. NAO SOMAR VENDA COM COBRANCA — dois graos do mesmo dinheiro.
--   3. id_produto cobre 4%; dim_produto_vbot (30) existe e nao foi tratada.
--   4. NAO SOMAR COM O FINANCEIRO DA CASA: isto e VBOT, o iClips e o Conta Azul sao BRM e VD.

WITH final AS (
  SELECT
    v.conexa_id                                     AS id_venda,
    v.customer_id                                   AS id_cliente,
    v.contract_id                                   AS id_contrato,
    v.product_id                                    AS id_produto,
    v.recurring_sale_id                             AS id_venda_recorrente,
    v.seller_id                                     AS id_vendedor,
    v.requester_id                                  AS id_solicitante,

    v.presente_no_origem                            AS is_vigente,
    (NOT v.presente_no_origem)                      AS flag_apagado_na_origem,

    v.status                                        AS status_origem,
    CASE v.status
      WHEN 'paid'              THEN 'PAGA'
      WHEN 'partiallyPaid'     THEN 'PAGA_PARCIAL'
      WHEN 'billed'            THEN 'FATURADA'
      WHEN 'billedNegociated'  THEN 'FATURADA_NEGOCIADA'
      WHEN 'notBilled'         THEN 'NAO_FATURADA'
      WHEN 'cancelled'         THEN 'CANCELADA'
      WHEN 'billedCancelled'   THEN 'FATURADA_CANCELADA'
      ELSE 'OUTRO'
    END                                             AS status_canonico,
    (v.status IN ('cancelled', 'billedCancelled'))  AS is_cancelada,
    (v.status IN ('billed', 'billedNegociated', 'billedCancelled')) AS is_faturada,
    (v.status IN ('paid', 'partiallyPaid'))         AS is_paga,

    v.product_name                                  AS nome_produto,
    v.quantity                                      AS quantidade,
    v.amount                                        AS valor,
    v.original_amount                               AS valor_original,
    v.discount_value                                AS valor_desconto,
    ROUND(v.original_amount - v.amount, 2)          AS diferenca_para_o_original,
    (ABS(COALESCE(v.original_amount, 0) - COALESCE(v.amount, 0)) > 0.005)
                                                    AS flag_valor_alterado,
    (v.recurring_sale_id IS NOT NULL)               AS is_recorrente,
    (v.contract_id IS NOT NULL)                     AS tem_contrato,

    v.reference_date                                AS data_referencia,
    DATE(v.reference_date)                          AS data_referencia_dia,
    v.mes_referencia,
    v.ano_referencia,

    v.notes                                         AS observacoes,
    v.conexa_updated_at                             AS atualizado_na_origem_em,
    v.processed_at
  FROM `vanguardamartech_raw`.`supabase_public_fato_venda_vbot` v
)
SELECT
  f.*,
  'L3_CONFIDENTIAL'                             AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz'                               AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                AS _payload_hash
FROM final f
