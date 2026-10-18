-- trs_financeiro__programacao_snapshot
-- Trusted / Financeiro. Grao: uma parcela em aberto (a pagar ou a receber) em um snapshot DIARIO da programacao financeira do Conta Azul.
-- Chave composta id_snapshot_parcela = snapshot_date|id_parcela (140.000 distintos em 140.000 linhas, 69 datas, 2026-08-10 a 2026-10-17, medido em 2026-10-18).
-- Origem: vanguardamartech_raw.supabase_meta_fin_prog_snapshot (fonte supabase-x0tz). Nivel: L4 PERSONAL_DATA (contraparte nominal; ha pessoa fisica).
-- E HISTORICO QUE NAO SE RECALCULA: o razao so conhece o estado de hoje; este e o unico registro do que estava em aberto em cada dia.
-- A contagem de linhas da origem e exatamente 140.000 e o ultimo dia (2026-10-17) traz so 880 parcelas: possivel corte da extracao no teto.
-- Sete dias vem com captura parcial (341 a 1.738 parcelas contra ~1.900-2.400): marcar e tarefa da Refined (flag_snapshot_parcial).
-- BRM e VD apenas (VBOT nao esta no razao Conta Azul). valor_nao_pago > valor em 22 linhas (juros/multa), preservado.
SELECT
  CONCAT(CAST(snapshot_date AS STRING), '|', id_parcela)    AS id_snapshot_parcela,
  SAFE_CAST(snapshot_date AS DATE)                          AS snapshot_date,
  id_parcela,
  NULLIF(TRIM(tipo), '')                                    AS tipo,
  NULLIF(TRIM(empresa), '')                                 AS empresa,
  NULLIF(TRIM(contraparte), '')                             AS contraparte,
  NULLIF(TRIM(categoria), '')                               AS categoria,
  SAFE_CAST(data_vencimento AS DATE)                        AS data_vencimento,
  valor,
  valor_nao_pago,
  criado_em,
  COUNT(*) OVER (PARTITION BY snapshot_date)                AS qtd_parcelas_no_snapshot,
  'L4_PERSONAL_DATA'                                        AS classificacao_dado,
  CURRENT_TIMESTAMP()                                       AS _extraido_at,
  'supabase-x0tz'                                           AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(s)))                            AS _payload_hash
FROM vanguardamartech_raw.supabase_meta_fin_prog_snapshot s
