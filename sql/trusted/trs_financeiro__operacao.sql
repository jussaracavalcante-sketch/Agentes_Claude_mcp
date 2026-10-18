-- trs_financeiro__operacao
-- Trusted / Financeiro. Grao: uma OPERACAO (empresa do grupo que fatura). Chave: operacao (BRM, VD, VBOT).
-- Nivel: L2 INTERNAL (cadastro das empresas do grupo; CNPJ de pessoa juridica, sem dado pessoal).
--
-- ORIGEM. supabase_public_dim_operacao (3 linhas), da supabase-x0tz. Medido em 18/10/2026: 3 linhas, 3 chaves,
-- 3 ativas, CNPJ de 14 digitos nas 3.
-- E O CADASTRO QUE EXPLICA A COLUNA 'empresa'/'operacao' DAS TABELAS FINANCEIRAS: BRM = B. R. M. Costa de Lima e Cia
-- (CNPJ 07.865.616/0001-74, Lucro Real, ERP Conta Azul), VD = Vanguarda Comunicacao Digital (26.123.250/0001-02, Lucro
-- Presumido, Conta Azul), VBOT = VBOT Solucoes de Comunicacao (61.077.352/0001-30, ERP Conexa). Os CNPJ batem com os
-- registrados na casa para as quatro empresas do grupo.
--
-- inicio_erp = 2026-06-01 para BRM e VD: e a data em que o ERP passou a ser o Conta Azul, e e a mesma virada medida no
-- razao (o iClips para de registrar em 2026-06 e o Conta Azul assume). A VBOT nao tem inicio_erp (Conexa).
--
-- LIMITACAO -- NAO CONTORNE: e o cadastro, nao o movimento; nao tem VPromo nem Vanguarda Internacional (clientes e
-- outras PJ ficam nas tabelas de cadastro de cliente). regime_tributario e licenca do Conta Azul so existem para BRM e VD.
SELECT
  NULLIF(TRIM(o.operacao), '')                                     AS operacao,
  NULLIF(TRIM(o.nome), '')                                         AS nome,
  NULLIF(TRIM(o.razao_social), '')                                 AS razao_social,
  NULLIF(TRIM(o.apelido), '')                                      AS apelido,
  NULLIF(TRIM(o.grupo), '')                                        AS grupo,
  IF(LENGTH(REGEXP_REPLACE(IFNULL(o.cnpj, ''), r'\D', '')) = 14, REGEXP_REPLACE(o.cnpj, r'\D', ''), NULL) AS cnpj,
  NULLIF(TRIM(o.erp), '')                                          AS erp,
  NULLIF(TRIM(o.regime_tributario), '')                            AS regime_tributario,
  NULLIF(TRIM(o.conta_azul_licenca), '')                           AS conta_azul_licenca,
  SAFE_CAST(CAST(o.inicio_erp AS STRING) AS DATE)                  AS inicio_erp,
  o.ativo                                                          AS is_ativa,
  NULLIF(TRIM(CAST(o.faturamento_modo AS STRING)), '')             AS faturamento_modo,
  SAFE_CAST(CAST(o.faturamento_antecedencia_dias AS STRING) AS INT64) AS faturamento_antecedencia_dias,
  NULLIF(TRIM(CAST(o.tipo_novos_clientes AS STRING)), '')          AS tipo_novos_clientes,
  NULLIF(TRIM(CAST(o.observacao AS STRING)), '')                   AS observacao,
  CURRENT_TIMESTAMP()                                              AS _extraido_at,
  'supabase-x0tz'                                                  AS _fonte,
  'America/Sao_Paulo'                                              AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(o)))                                   AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_public_dim_operacao` o
