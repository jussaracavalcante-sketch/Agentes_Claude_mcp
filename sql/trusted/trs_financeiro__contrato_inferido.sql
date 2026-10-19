-- trs_financeiro__contrato_inferido
-- Trusted / Financeiro. Grao: um CONTRATO INFERIDO pelo Supabase a partir das parcelas de receita do Conta Azul, por operacao e pessoa.
-- Chave: id_contrato_inferido = <operacao>|<id_pessoa ou SEM_PESSOA> (181 linhas, 181 chaves; medido em 2026-10-19).
-- Origem: vanguardamartech_raw.supabase_conta_azul_vw_contrato (fonte supabase-x0tz, diaria). Cadencia desta Trusted: semanal (segunda 06:30 America/Manaus), por custo de credito.
-- Nivel: L4 PERSONAL_DATA (nome do cliente, e-mail e telefone; ha pessoa fisica entre os clientes).
-- O QUE E: regra de negocio do Supabase que agrupa parcelas por pessoa e chama o agrupamento de "contrato" (inicio, fim, n_meses, n_parcelas, valor,
--   recorrente, encerrado/ativo). NAO e contrato juridico nem o contrato nativo do Conta Azul (esse esta em trs_contazul__contrato, 390 linhas).
--   Tratado como DERIVADO DECLARADO: nada e recalculado aqui; a definicao de "recorrente" e do Supabase e nao foi confirmada.
-- MEDIDO (2026-10-19): 2 operacoes (BRM, VD) · `cnpj` e o CNPJ da OPERACAO (07.865.616/0001-74 e 26.123.250/0001-02), NAO do cliente · 179 pessoas distintas,
--   todas catalogadas em trs_contazul__pessoa · 2 linhas SEM pessoa (uma por operacao: 252 parcelas / R$ 4.481.580,43 em BRM e 48 / R$ 389.563,10 em VD) sao o
--   balde das parcelas sem id_pessoa e NAO sao um cliente · recorrente TRUE 112, FALSE 64, NULL 5 (fica NULL) · encerrado 110, ativo 71 · fee_mes_corrente em 70 ·
--   competencia 2026-06-01 a 2028-09-02 · 2.234 parcelas · R$ 16.427.356,29 · n_meses diverge do intervalo de meses em 12 linhas (n_meses conta meses COM parcela).
-- LIMITACOES - NAO CONTORNE: comeca em 2026-06 (handoff do razao para o Conta Azul); nao soma com trs_contazul__contrato nem com trs_financeiro__receita_cliente;
--   o balde SEM_PESSOA nao e cliente e deve ficar fora de qualquer ranking.
WITH origem AS (
  SELECT
    c.*,
    NULLIF(REGEXP_REPLACE(IFNULL(c.cnpj, ''), r'[^0-9]', ''), '')   AS cnpj_operacao_digitos
  FROM `vanguardamartech_raw`.`supabase_conta_azul_vw_contrato` c
),
final AS (
  SELECT
    CONCAT(operacao, '|', IFNULL(id_pessoa, 'SEM_PESSOA'))          AS id_contrato_inferido,
    operacao,
    cnpj_operacao_digitos                                           AS cnpj_operacao,
    id_pessoa,
    (id_pessoa IS NULL)                                             AS flag_sem_pessoa,
    NULLIF(TRIM(cliente), '')                                       AS cliente,
    NULLIF(TRIM(email), '')                                         AS email,
    NULLIF(TRIM(telefone), '')                                      AS telefone,
    competencia_inicio,
    competencia_fim,
    n_meses,
    DATE_DIFF(competencia_fim, competencia_inicio, MONTH) + 1       AS meses_do_intervalo,
    (n_meses <> DATE_DIFF(competencia_fim, competencia_inicio, MONTH) + 1) AS flag_n_meses_diverge_do_intervalo,
    n_parcelas,
    valor_total_contratado,
    recorrente                                                      AS is_recorrente,
    (recorrente IS NULL)                                            AS flag_recorrencia_nao_informada,
    fee_mes_corrente,
    status                                                          AS status_origem,
    (status = 'ativo')                                              AS is_ativo,
    (status = 'encerrado')                                          AS is_encerrado
  FROM origem
)
SELECT
  f.*,
  'L4_PERSONAL_DATA'                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
