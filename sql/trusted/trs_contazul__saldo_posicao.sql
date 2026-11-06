-- trs_contazul__saldo_posicao
-- Trusted / Conta Azul. Grao: um saldo inicial de conta financeira (origem SALDO_INICIAL) ou uma posicao mensal a receber/pagar
-- (origem POSICAO_SNAPSHOT). 16 + 18 = 34 linhas, 34 chaves (2026-10-18). Chave composta id_linha.
-- Origem: ca_fato_saldo_inicial e ca_snapshot_posicao (fonte supabase-x0tz). Nivel: L3 CONFIDENTIAL.
-- POSICAO_SNAPSHOT e historico que nao se recalcula; vw_evolucao_posicao (9 linhas) e derivada da posicao viva.
-- Campos: ref_data = data_competencia (SALDO_INICIAL) | ref_mes (POSICAO_SNAPSHOT); saldo = saldo_inicial | saldo_aberto.
SELECT
  a.*,
  'L3_CONFIDENTIAL'                  AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(a)))     AS _payload_hash
FROM (
  SELECT
    CONCAT('SALDO_INICIAL|', id_conta_financeira, '|', CAST(data_competencia AS STRING), '|', IFNULL(tipo, '')) AS id_linha,
    'SALDO_INICIAL' AS origem, operacao, id_conta_financeira, tipo, data_competencia AS ref_data,
    saldo_inicial AS saldo, CAST(NULL AS INT64) AS qtd_titulos, CAST(NULL AS FLOAT64) AS vencido, CAST(NULL AS FLOAT64) AS a_vencer,
    data_inicio_consulta, data_fim_consulta, fetched_at AS capturado_em
  FROM vanguardamartech_raw.supabase_conta_azul_ca_fato_saldo_inicial
  UNION ALL
  SELECT
    CONCAT('POSICAO_SNAPSHOT|', CAST(ref_mes AS STRING), '|', operacao, '|', IFNULL(tipo, '')),
    'POSICAO_SNAPSHOT', operacao, CAST(NULL AS STRING), tipo, ref_mes,
    saldo_aberto, qtd_titulos, vencido, a_vencer,
    CAST(NULL AS DATE), CAST(NULL AS DATE), data_snapshot
  FROM vanguardamartech_raw.supabase_conta_azul_ca_snapshot_posicao
) a
