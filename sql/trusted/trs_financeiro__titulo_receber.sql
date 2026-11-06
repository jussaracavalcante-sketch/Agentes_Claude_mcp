-- trs_financeiro__titulo_receber
-- Trusted / Financeiro. Grao: um TITULO A RECEBER (parcela de entrada do Conta Azul ou cobranca do Conexa) com cliente, vencimento, pagamento e saldo, na visao do Supabase.
-- Chave: titulo_id da origem (`CA:<uuid da parcela>` ou `VBOT:<id da cobranca>`): 3.490 linhas, 3.490 chaves (medido em 2026-10-19).
-- Origem: vanguardamartech_raw.supabase_gold_vw_receb_titulos (fonte supabase-x0tz, diaria). Cadencia desta Trusted: semanal (segunda 06:50 America/Manaus).
-- Nivel: L4 PERSONAL_DATA (nome, e-mail em 2.956, telefone em 3.083, vendedor; CPF em 45). E-mail e telefone FICAM aqui e NAO atravessam para a Refined.
-- MEDIDO (2026-10-19): Conta Azul 2.522 (BRM 2.326 + VD 196) = EXATAMENTE as parcelas vigentes de ENTRADA de trs_contazul__movimento (2.522 = 2.522, 2.522 casam por id) ·
--   Conexa 968 = EXATAMENTE as cobrancas de trs_conexa__cobranca que a view le (968 casam por id) · face R$ 18.818.306,58 · pago R$ 12.581.547,19 · saldo R$ 6.141.271,75 ·
--   2.222 pagos · vencimento 2025-04-10 a 2028-09-30.
-- valor - valor_pago - saldo_aberto NAO fecha em 1.008 titulos (R$ 95.487,64 liquido, com sinal; R$ 117.983,66 em modulo): juros, multa e desconto na baixa, mesmo mecanismo medido em rfn_financeiro__fluxo_caixa.
--   `diferenca_face` mostra o quanto, com sinal; nada e recalculado.
-- DOCUMENTO: `cliente_canonico` traz 14 digitos em 2.164, 11 em 45, `N:` em 300 (sentinela de titulo SEM pessoa: 252 BRM + 48 VD -> documento NULL, flag_sem_pessoa),
--   `871768534` em 13 (fragmento de mascara, MOVE -> NULL, flag_documento_invalido) e `VBOT:<id>` em 968 (id do cliente no Conexa, nao documento).
-- SENTINELA: telefone `9999999999` em 51 linhas vira NULL (flag_telefone_sentinela). `dias` e `atraso_pagamento` passam como a origem entrega: `dias` = hoje - vencimento
--   NA DATA DA CARGA (medido: 0 divergencias contra CURRENT_DATE em 19/10); `atraso_pagamento` = pagamento - vencimento (0 divergencias). 1 titulo pago sem data de pagamento
--   (R$ 27.500, o mesmo da fluxo_caixa); 5 nao pagos com data; 2 pagos com saldo (PARTIAL).
-- LIMITACOES - NAO CONTORNE: status_origem mistura vocabularios do Conta Azul (PENDING/OVERDUE/ACQUITTED/LOST, PENDENTE/QUITADO/PERDIDO) e do Conexa (unpaid/paid/
--   cancelled/negotiated) e NAO e normalizado - `is_pago` da origem e o unico separador; NAO SOMAR com rfn_financeiro__fluxo_caixa (mesmas parcelas do Conta Azul, outra visao);
--   `dias` envelhece ate 6 dias com a cadencia semanal: para corte estavel, use data_vencimento contra a data escolhida.
WITH origem AS (
  SELECT
    t.*,
    CASE
      WHEN REGEXP_CONTAINS(t.cliente_canonico, r'^[0-9]+$') THEN t.cliente_canonico
      ELSE NULL
    END                                                              AS documento_origem
  FROM `vanguardamartech_raw`.`supabase_gold_vw_receb_titulos` t
),
final AS (
  SELECT
    titulo_id                                                        AS id_titulo,
    fonte                                                            AS sistema_origem,
    operacao,
    cliente_key,
    NULLIF(TRIM(cliente_nome), '')                                   AS cliente_nome,
    cliente_canonico,
    IF(LENGTH(documento_origem) IN (11, 14), documento_origem, NULL) AS documento,
    documento_origem,
    (documento_origem IS NOT NULL AND LENGTH(documento_origem) NOT IN (11, 14)) AS flag_documento_invalido,
    (cliente_canonico = 'N:')                                        AS flag_sem_pessoa,
    IF(STARTS_WITH(cliente_canonico, 'VBOT:'), SAFE_CAST(SUBSTR(cliente_canonico, 6) AS INT64), NULL) AS id_cliente_conexa,
    NULLIF(TRIM(uf), '')                                             AS uf,
    NULLIF(TRIM(email), '')                                          AS email,
    IF(telefone = '9999999999', NULL, NULLIF(TRIM(telefone), ''))    AS telefone,
    (telefone = '9999999999')                                        AS flag_telefone_sentinela,
    NULLIF(TRIM(vendedor), '')                                       AS vendedor,
    valor                                                            AS valor_face,
    valor_pago,
    saldo_aberto,
    ROUND(valor - valor_pago - saldo_aberto, 2)                      AS diferenca_face,
    pago                                                             AS is_pago,
    data_vencimento,
    data_pagamento,
    dias                                                             AS dias_desde_vencimento_na_carga,
    atraso_pagamento                                                 AS dias_atraso_pagamento,
    NULLIF(TRIM(status_origem), '')                                  AS status_origem,
    (pago AND data_pagamento IS NULL)                                AS flag_pago_sem_data,
    (NOT pago AND data_pagamento IS NOT NULL)                        AS flag_nao_pago_com_data,
    (pago AND saldo_aberto <> 0)                                     AS flag_pago_com_saldo
  FROM origem
)
SELECT
  f.*,
  (LENGTH(f.documento) = 14)         AS is_pj,
  (LENGTH(f.documento) = 11)         AS is_pf,
  'L4_PERSONAL_DATA'                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
