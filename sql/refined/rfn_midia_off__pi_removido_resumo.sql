-- rfn_midia_off__pi_removido_resumo  ·  Refined / midia_off  ·  L3 CONFIDENTIAL (a Trusted e L4; responsavel, cliente e veiculo NAO atravessam)
-- Grao: carga do arquivo (run_ref) x reapareceu x status de faturamento x tipo de midia. Le: trs_pi__removido (query-wgg9). Gatilho: evento em query-wgg9. Cadencia herdada: semanal (segunda 07:15 America/Manaus).
-- VALIDACAO (2026-10-19): 9 linhas, 9 chaves; 74 PIs (73 reapareceram e 73 existem no PI atual), 10 cancelados na fotografia, 25 CNPJ de veiculo repadronizados, valor negociado R$ 500.322,50, liquido R$ 400.258,00 e comissao R$ 100.064,50 (= Trusted).
-- REGRA 1 - AGREGA, NAO FILTRA: soma = Trusted (74 PIs, valor negociado R$ 500.322,50, liquido R$ 400.258,00, comissao do veiculo R$ 100.064,50 em 19/10/2026).
-- REGRA 2 - REMOVIDO NAO E EXCLUIDO: os 74 sumiram na MESMA carga (06/07/2026) e 73 reapareceram em 07/07; so 1 continua fora. `qtd_existe_no_pi_atual` mostra quantos estao hoje em trs_pi__insercao.
--   Foi falha de UMA carga do arquivo: somar estes valores como "PIs perdidos" ou "PIs cancelados" e erro.
-- REGRA 3 - A FOTOGRAFIA E A DE 06/07/2026 e pode divergir do PI vigente; para valor oficial de PI use rfn_midia_off__pi.
-- REGRA 4 - CNPJ DE VEICULO: 25 chegam como numero com 13 digitos; o LPAD so e aceito quando o corrigido ja existe em trs_pi__insercao (`qtd_cnpj_veiculo_repadronizado`); documento nunca e emitido.
-- LIMITACOES - NAO CONTORNE: historico de UMA carga; nao e o PI vigente; `is_cancelado_na_fotografia` e o rotulo do PI naquele dia.
WITH t AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_pi__removido`
),
g AS (
  SELECT
    run_ref,
    flag_reapareceu,
    status_faturamento,
    tipo_midia,
    COUNT(*)                                       AS qtd_pis,
    COUNTIF(flag_existe_no_pi_atual)               AS qtd_existe_no_pi_atual,
    COUNTIF(is_cancelado_na_fotografia)            AS qtd_cancelado_na_fotografia,
    COUNTIF(flag_cnpj_veiculo_repadronizado)       AS qtd_cnpj_veiculo_repadronizado,
    COUNTIF(flag_cnpj_veiculo_invalido)            AS qtd_cnpj_veiculo_invalido,
    ROUND(SUM(valor_negociado), 2)                 AS valor_negociado,
    ROUND(SUM(valor_liquido), 2)                   AS valor_liquido,
    ROUND(SUM(valor_comissao_veiculo), 2)          AS valor_comissao_veiculo,
    MIN(removido_em_local)                         AS primeira_remocao_local,
    MAX(DATE(_extraido_at, 'America/Sao_Paulo'))   AS data_carga_trusted
  FROM t
  GROUP BY run_ref, flag_reapareceu, status_faturamento, tipo_midia
),
final AS (
  SELECT
    CONCAT(run_ref, '|', IF(flag_reapareceu, 'REAPARECEU', 'AUSENTE'), '|', IFNULL(status_faturamento, '~'), '|', IFNULL(tipo_midia, '~')) AS id_pi_removido_resumo,
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
