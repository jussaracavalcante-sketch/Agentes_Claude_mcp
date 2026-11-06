-- trs_conexa__contrato  ·  query-54P5  ·  139 linhas  ·  L3 CONFIDENTIAL
-- Trusted / Conexa (VBOT). Grao: um contrato. Chave: id_contrato (conexa_id).
-- Origem: supabase-x0tz, public-fato_contrato_vbot. Gatilho: evento em query-6qKc.
-- Onde mora a RECEITA RECORRENTE da VBOT. Inicio de 2025-05-16 a 2026-10-01.
--
-- REGRA 1 — A RECEITA RECORRENTE EXIGE DUAS CONDICOES: ativo E vigente na origem. 112 ativos,
--   10 apagados no Conexa; o que sobrevive aos dois soma R$ 103.229,94/mes. Nos demais
--   `valor_mensal_recorrente` sai NULL, nunca zero.
-- REGRA 2 — DOIS ESTADOS QUE NAO CONVERSAM. So 27 dos 139 tem end_date e 26 tem motivo.
--   flag_inativo_sem_fim e flag_fim_sem_motivo marcam os dois lados. CONTAR CHURN POR
--   `end_date` SUBCONTA — a data de fim cobre 19% da base.
-- REGRA 3 — `complementary_services` chega como TEXTO com array de objetos dentro, e e onde
--   esta a maior parte do dinheiro: um contrato medido tem amount 570,05 no cabecalho e CINCO
--   servicos somando R$ 2.888,25 dentro. 101 dos 139 tem pelo menos um. O valor de dentro NAO
--   foi reconciliado com o do cabecalho — sao dois numeros que a origem mantem separados, e
--   dizer qual e "o valor do contrato" e regra de negocio. Somar os dois duplica.
-- REGRA 4 — QUATRO CAMPOS MORTOS FICAM DE FORA: fidelity_date NULL nas 139,
--   last_contractual_readjustment NULL nas 139, had_prorata FALSE nas 139, refund_amount zero
--   nas 139. NAO HA REAJUSTE CONTRATUAL REGISTRADO nesta base.
-- REGRA 5 — `payment_frequency` tem um unico valor (`Monthly`) nas 139.
--
-- FUSO: as datas sao DATE na origem; conexa_updated_at e processed_at sao carimbo (UTC).
--
-- LIMITACOES — NAO CONTORNE
--   1. O BRONZE NAO E ESTADO: bronze-conexa__contracts tem 529 linhas para 139 contratos.
--   2. id_motivo_encerramento resolve contra dim_motivo_churn_vbot (4 linhas), nao tratada.
--   3. id_plano, id_vendedor e id_centro_custo saem crus — as dimensoes existem no Supabase
--      (dim_plano_vbot 7, dim_usuario_vbot 91, dim_centro_custo_vbot 11) e nao foram tratadas.
--   4. NAO SOMAR COM O FINANCEIRO DA CASA: isto e VBOT, o iClips e o Conta Azul sao BRM e VD.

WITH final AS (
  SELECT
    c.conexa_id                                     AS id_contrato,
    c.customer_id                                   AS id_cliente,
    c.plan_id                                       AS id_plano,
    c.seller_id                                     AS id_vendedor,
    c.cost_center_id                                AS id_centro_custo,

    c.presente_no_origem                            AS is_vigente_na_origem,
    (NOT c.presente_no_origem)                      AS flag_apagado_na_origem,

    c.contract_summary                              AS resumo_contrato,
    c.amount                                        AS valor_mensal,
    c.payment_frequency                             AS frequencia_pagamento,

    c.is_active                                     AS is_ativo,
    IF(c.is_active AND c.presente_no_origem, c.amount, NULL)
                                                    AS valor_mensal_recorrente,

    c.start_date                                    AS data_inicio,
    c.end_date                                      AS data_fim,
    c.first_due_date                                AS primeiro_vencimento,
    c.due_day                                       AS dia_vencimento,
    c.date_sales_generation                         AS ultima_geracao_de_venda,
    (c.end_date IS NOT NULL)                        AS tem_data_de_fim,
    c.end_reason_id                                 AS id_motivo_encerramento,
    (c.end_date IS NOT NULL AND c.end_reason_id IS NULL) AS flag_fim_sem_motivo,
    (c.end_date IS NULL AND NOT c.is_active)             AS flag_inativo_sem_fim,
    IF(c.end_date IS NOT NULL,
       DATE_DIFF(c.end_date, c.start_date, DAY), NULL)   AS dias_de_vigencia,

    c.sales_quantity                                AS qtd_vendas_geradas,

    JSON_QUERY_ARRAY(c.complementary_services)      AS servicos_complementares,
    ARRAY_LENGTH(JSON_QUERY_ARRAY(c.complementary_services))
                                                    AS qtd_servicos_complementares,
    (SELECT ROUND(SUM(SAFE_CAST(JSON_VALUE(s, '$.amount') AS FLOAT64)), 2)
       FROM UNNEST(JSON_QUERY_ARRAY(c.complementary_services)) s)
                                                    AS valor_servicos_complementares,

    c.notes                                         AS observacoes,
    c.mes_referencia,
    c.ano_referencia,
    c.conexa_updated_at                             AS atualizado_na_origem_em,
    c.processed_at
  FROM `vanguardamartech_raw`.`supabase_public_fato_contrato_vbot` c
)
SELECT
  f.*,
  'L3_CONFIDENTIAL'                             AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz'                               AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                AS _payload_hash
FROM final f
