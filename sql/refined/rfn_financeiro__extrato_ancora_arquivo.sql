-- rfn_financeiro__extrato_ancora_arquivo  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (saldo bancario; agencia e numero da conta NAO atravessam)
-- Grao: um ARQUIVO de extrato importado de uma conta (conta_ref x arquivo), com o saldo anterior, o saldo final e a PONTE com o arquivo seguinte da mesma conta.
-- Le: trs_financeiro__extrato_ancora (query-MM2y). Gatilho: evento em query-MM2y. Cadencia herdada: semanal (segunda 06:55 America/Manaus).
-- VALIDACAO (2026-10-19): 24 arquivos, 24 chaves, 6 contas, 48 ancoras, saldo R$ 569.622,12 (= Trusted); 6 ultimos arquivos sem ponte (NULL), ZERO pontes quebradas em 18, 17 ancoras de saldo zero, 3 de virada.
-- REGRA 1 - AGREGA, NAO FILTRA: cada arquivo tem uma ancora anterior e uma final; as 48 ancoras da Trusted viram 24 arquivos (medido em 19/10/2026); SUM(saldo_anterior)+SUM(saldo_final)
--   = R$ 569.622,12 = soma de `saldo` da Trusted.
-- REGRA 2 - A PONTE: `saldo_final` do arquivo N tem de ser igual ao `saldo_anterior` do arquivo N+1 da mesma conta (ordem por data da ancora anterior); `diferenca_ponte` e a
--   diferenca, NULL no ultimo arquivo de cada conta (nao ha seguinte, nunca zero) e `flag_ponte_quebrada` acende quando passa de um centavo.
-- REGRA 3 - SALDO ZERO E SALDO, NAO AUSENCIA: 17 das 48 ancoras valem zero (conta sem saldo) e ficam como zero.
-- LIMITACOES - NAO CONTORNE: saldo DECLARADO pelo arquivo, nao calculado; so as 6 contas com extrato importado; 2025-12 a 2026-08; nao e o saldo bancario de hoje.
WITH t AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__extrato_ancora`
),
arq AS (
  SELECT
    conta_ref,
    arquivo,
    ANY_VALUE(operacao)                                         AS operacao,
    ANY_VALUE(nome_conta_ca)                                    AS nome_conta_ca,
    MAX(IF(is_saldo_anterior, data_ref, NULL))                  AS data_saldo_anterior,
    MAX(IF(is_saldo_anterior, saldo, NULL))                     AS saldo_anterior,
    MAX(IF(is_saldo_final, data_ref, NULL))                     AS data_saldo_final,
    MAX(IF(is_saldo_final, saldo, NULL))                        AS saldo_final,
    COUNT(*)                                                    AS qtd_ancoras,
    COUNTIF(is_ancora_virada)                                   AS qtd_ancoras_de_virada,
    COUNTIF(flag_saldo_zero)                                    AS qtd_ancoras_saldo_zero,
    MAX(DATE(_extraido_at, 'America/Sao_Paulo'))                AS data_carga_trusted
  FROM t
  GROUP BY conta_ref, arquivo
),
l AS (
  SELECT
    a.*,
    LEAD(saldo_anterior) OVER (PARTITION BY conta_ref ORDER BY data_saldo_anterior, arquivo) AS saldo_anterior_do_proximo_arquivo
  FROM arq a
),
final AS (
  SELECT
    CONCAT(conta_ref, '|', arquivo)                             AS id_ancora_arquivo,
    l.* EXCEPT (saldo_anterior_do_proximo_arquivo),
    saldo_anterior_do_proximo_arquivo,
    ROUND(saldo_final - saldo_anterior_do_proximo_arquivo, 2)   AS diferenca_ponte,
    (saldo_anterior_do_proximo_arquivo IS NOT NULL AND ABS(saldo_final - saldo_anterior_do_proximo_arquivo) > 0.01) AS flag_ponte_quebrada,
    'L3_CONFIDENTIAL'                                           AS classificacao_dado
  FROM l
)
SELECT
  f.*,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
