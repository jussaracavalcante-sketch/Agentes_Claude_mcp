-- rfn_financeiro__contrato_inferido_resumo  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (a Trusted e L4; nome, e-mail e telefone NAO atravessam)
-- Grao: operacao x status de origem x recorrencia (RECORRENTE / NAO_RECORRENTE / NAO_INFORMADO) x balde sem pessoa. Le: trs_financeiro__contrato_inferido (query-ER7C).
-- Gatilho: evento em query-ER7C. Cadencia herdada: semanal (segunda 06:30 America/Manaus).
-- VALIDACAO (2026-10-19): 10 linhas, 10 chaves; 181 contratos inferidos, 2.234 parcelas, R$ 16.427.356,29, 70 com fee (R$ 483.618,02), 12 com n_meses divergente e 2 do balde sem pessoa - tudo igual a Trusted.
-- REGRA 1 - AGREGA, NAO FILTRA: as linhas somam a Trusted (181 contratos inferidos, 2.234 parcelas, R$ 16.427.356,29 em 19/10/2026).
-- REGRA 2 - O BALDE SEM PESSOA FICA NO GRAO (flag_sem_pessoa): 2 linhas de origem (BRM 252 parcelas, VD 48) que NAO sao cliente; tirar o balde apagaria R$ 4,87 mi
--   do total e a identidade com a Trusted deixaria de fechar. Quem ranqueia cliente filtra flag_sem_pessoa = FALSE.
-- REGRA 3 - RECORRENCIA NULA NAO VIRA FALSE: 5 contratos chegam com `recorrente` NULL e saem como NAO_INFORMADO, nunca como NAO_RECORRENTE.
-- REGRA 4 - `valor_total_contratado` E SOMA DE PARCELAS DO SUPABASE, nao valor de contrato juridico; fee_mes_corrente so soma onde existe (NULL e ausencia, nao zero).
-- LIMITACOES - NAO CONTORNE: derivado do Supabase, definicao de "recorrente" nao confirmada; comeca em 2026-06 (handoff do razao); nao soma com trs_contazul__contrato
--   nem com rfn_financeiro__contazul_mrr_mensal; contagem de contratos por pessoa nao e contagem de clientes (um cliente pode ter contratos nas duas operacoes).
WITH t AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__contrato_inferido`
),
g AS (
  SELECT
    operacao,
    status_origem,
    CASE WHEN is_recorrente IS NULL THEN 'NAO_INFORMADO' WHEN is_recorrente THEN 'RECORRENTE' ELSE 'NAO_RECORRENTE' END AS recorrencia,
    flag_sem_pessoa,
    COUNT(*)                                       AS qtd_contratos_inferidos,
    SUM(n_parcelas)                                AS qtd_parcelas,
    ROUND(SUM(valor_total_contratado), 2)          AS valor_total_contratado,
    ROUND(SUM(fee_mes_corrente), 2)                AS fee_mes_corrente,
    COUNTIF(fee_mes_corrente IS NOT NULL)          AS qtd_com_fee,
    MIN(competencia_inicio)                        AS primeira_competencia,
    MAX(competencia_fim)                           AS ultima_competencia,
    COUNTIF(flag_n_meses_diverge_do_intervalo)     AS qtd_n_meses_diverge_do_intervalo,
    MAX(DATE(_extraido_at, 'America/Sao_Paulo'))   AS data_carga_trusted
  FROM t
  GROUP BY operacao, status_origem, recorrencia, flag_sem_pessoa
),
final AS (
  SELECT
    CONCAT(operacao, '|', status_origem, '|', recorrencia, '|', IF(flag_sem_pessoa, 'SEM_PESSOA', 'COM_PESSOA')) AS id_contrato_resumo,
    g.*,
    'L3_CONFIDENTIAL' AS classificacao_dado
  FROM g
)
SELECT
  f.*,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
