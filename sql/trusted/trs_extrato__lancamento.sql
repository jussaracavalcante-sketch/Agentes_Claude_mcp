-- trs_extrato__lancamento
-- Trusted / Financeiro (extrato bancario). Grao: um LANCAMENTO de extrato de conta bancaria.
-- Chave: id_linha (natural_key do extrato; row_hash do extrato VBOT). Nivel: L4 PERSONAL_DATA
-- (contraparte nominal e documento: ha CPF de pessoa fisica). Nao publicar em painel sem agregar.
--
-- ORIGEM. Dois extratos, os dois ingeridos pela supabase-x0tz a partir de ARQUIVOS (xlsx, pdf, xls):
--   supabase_silver_eb_lancamento      4.431 lancamentos, 6 contas (BB BRM, Itau BRM, Itau VD, Nubank BRM,
--                                      Conta Azul IP BRM e VD), 23 arquivos, 02/01/2026 a 06/08/2026
--   supabase_public_vw_extrato_conta_vbot  217 lancamentos da conta Inter da VBOT (= supabase_public_raw_extrato_conta_vbot
--                                      = supabase_bronze_vbot__extrato_conta, 217 nas tres)
-- bronze_extrato_bancario__lancamento (4.431 linhas, 4.431 chaves) e a mesma extracao da silver e nao foi usado.
-- Medido em 18/10/2026: 4.648 linhas, 4.648 chaves.
--
-- BANCO REAL, NAO RAZAO. E o dinheiro que passou pela conta, nao a competencia: serve de prova independente do
-- caixa realizado. Cobre de janeiro/2026 em diante, enquanto o razao do Conta Azul so registra baixa a partir de 25/05/2026.
-- Entradas R$ 18.777.246,22 e saidas R$ 18.916.830,52 no extrato de arquivo (soma bruta, INCLUI transferencia entre as
-- contas da propria casa e aplicacao/resgate: NAO e receita nem despesa; filtrar por historico/categoria antes de ler como tal).
--
-- FUSO: as datas sao DATE (dia do extrato), sem hora: nao ha fuso a tratar.
--
-- DOCUMENTO: doc_contraparte chega com mascara (18 caracteres) ou so digitos (14); sai em DIGITOS e so e documento se
-- tiver 14 (CNPJ) ou 11 (CPF). Em lancamentos do BB, o CNPJ vem DENTRO do texto da contraparte
-- ('09/01 14:09 04240370000157 MERCANTIL N'): sai separado em documento_no_texto, fora da chave, sem substituir o campo.
--
-- CONCILIACAO: conciliacao = NULL em 3.879 de 4.431 (nunca conciliado ou nao verificado), 'conciliado' 546, 'nao_conciliado' 6.
-- NULL nao e 'nao conciliado': e ausencia de marcacao.
--
-- LIMITACAO -- NAO CONTORNE: e arquivo mensal ingerido a mao; mes sem arquivo nao aparece (ex.: bb_brm 2026-05 tem saldo e
-- zero lancamentos). Transferencia entre contas proprias entra dos dois lados e se anula na soma: nao somar entrada ou
-- saida como receita ou despesa.
WITH eb AS (
  SELECT
    'EXTRATO_ARQUIVO'                                   AS origem,
    natural_key                                         AS id_linha,
    conta_ref,
    empresa,
    data                                                AS data_movimento,
    periodo,
    NULLIF(TRIM(historico), '')                         AS historico,
    NULLIF(TRIM(contraparte), '')                       AS contraparte,
    NULLIF(REGEXP_REPLACE(IFNULL(doc_contraparte, ''), r'\D', ''), '') AS doc_digitos,
    valor,
    seq_dia,
    layout,
    arquivo,
    NULLIF(TRIM(conciliacao), '')                       AS conciliacao_origem,
    CAST(NULL AS STRING)                                AS categoria,
    CAST(NULL AS STRING)                                AS subcategoria,
    CAST(NULL AS STRING)                                AS num_nfse,
    fetched_at                                          AS lido_em
  FROM `vanguardamartech_raw`.`supabase_silver_eb_lancamento`
  UNION ALL
  SELECT
    'EXTRATO_VBOT_INTER',
    row_hash,
    'inter_vbot',
    'VBOT',
    data_movimento,
    competencia,
    NULLIF(TRIM(demonstrativo), ''),
    NULLIF(TRIM(cliente_fornecedor), ''),
    CAST(NULL AS STRING),
    valor,
    CAST(NULL AS INT64),
    'inter_xls',
    arquivo,
    IF(conciliado IS NULL, NULL, IF(conciliado, 'conciliado', 'nao_conciliado')),
    NULLIF(TRIM(categoria), ''),
    NULLIF(TRIM(subcategoria), ''),
    NULLIF(CAST(num_nfse AS STRING), ''),
    importado_em
  FROM `vanguardamartech_raw`.`supabase_public_vw_extrato_conta_vbot`
)
SELECT
  e.id_linha,
  e.origem,
  e.conta_ref,
  e.empresa,
  e.data_movimento,
  e.periodo,
  e.historico,
  e.contraparte,
  IF(LENGTH(e.doc_digitos) IN (11, 14), e.doc_digitos, NULL)               AS contraparte_documento,
  e.doc_digitos                                                            AS contraparte_documento_origem,
  (e.doc_digitos IS NOT NULL AND LENGTH(e.doc_digitos) NOT IN (11, 14))    AS flag_documento_invalido,
  REGEXP_EXTRACT(e.contraparte, r'(?:^|\D)(\d{14})(?:\D|$)')               AS documento_no_texto,
  IF(e.valor > 0, 'ENTRADA', IF(e.valor < 0, 'SAIDA', 'ZERO'))             AS sentido,
  e.valor,
  ABS(e.valor)                                                             AS valor_abs,
  e.categoria,
  e.subcategoria,
  UPPER(e.conciliacao_origem)                                              AS conciliacao,
  e.num_nfse,
  e.seq_dia,
  e.layout,
  e.arquivo,
  DATE(e.lido_em, 'America/Sao_Paulo')                                     AS arquivo_lido_em,
  CURRENT_TIMESTAMP()                                                      AS _extraido_at,
  'supabase-x0tz'                                                          AS _fonte,
  'America/Sao_Paulo'                                                      AS _fuso,
  TO_HEX(MD5(CONCAT(e.id_linha, CAST(e.valor AS STRING), CAST(e.data_movimento AS STRING)))) AS _payload_hash
FROM eb e
