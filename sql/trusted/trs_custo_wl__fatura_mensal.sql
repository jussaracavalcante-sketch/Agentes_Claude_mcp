-- trs_custo_wl__fatura_mensal
-- Trusted / Custo white-label (VBOT). Grao: uma FATURA MENSAL do parceiro white-label. Chave: periodo.
-- Nivel: L3 CONFIDENTIAL (custo operacional da VBOT).
--
-- ORIGEM. supabase_silver_custo_wl_consolidado (8 periodos, 2026-01 a 2026-08), arquivos faturamento_wl___consolidado.
-- bronze_custo_wl__consolidado tem 9 linhas para 8 chaves (uma versao a mais) e nao foi usado.
-- Medido em 18/10/2026: total R$ 19.309,43 (jan) a R$ 50.511,48 (jul); agosto R$ 48.493,74 (periodo possivelmente parcial).
--
-- IDENTIDADE (prova de que o consolidado e coerente): total_fatura = contas + instancias_zapi + infraestrutura
-- + desconto_volume + dominio + aplicativo, dentro de R$ 0,01 nos 8 periodos (flag_total_nao_fecha = FALSE).
--
-- RECONCILIACAO COM O DETALHE (colunas *_detalhe e diff_*):
--   contas e infraestrutura: SUM do detalhe (trs_custo_wl__conta_mensal) = consolidado EXATO nos 8 periodos.
--   instancias_zapi: o detalhe por instancia (supabase_silver_custo_wl_instancia) NAO fecha em 6 de 8 periodos;
--   diferenca de R$ 2,25 a R$ 18,00 a mais no detalhe, e 18 das 1.218 linhas repetem a chave
--   (periodo, conta, instancia). Fecha exato em fevereiro e junho. A diferenca fica explicita, nao e corrigida.
--
-- E CUSTO da VBOT (nao receita): leitura pelo nome da origem (custo_wl) e pelo parceiro = VBOT; nao confirmada
-- contra contrato. desconto_volume e negativo (abate da fatura), nao erro de sinal.
--
-- LIMITACAO -- NAO CONTORNE: o arquivo mais novo e de 17/08/2026; periodos depois de 2026-08 nao existem aqui.
WITH conta AS (
  SELECT periodo, ROUND(SUM(total_contas), 2) AS s FROM `vanguardamartech_raw`.`supabase_silver_custo_wl_conta` GROUP BY periodo
),
infra AS (
  SELECT periodo, ROUND(SUM(custo_infra), 2) AS s FROM `vanguardamartech_raw`.`supabase_silver_custo_wl_infra` GROUP BY periodo
),
inst AS (
  SELECT periodo, ROUND(SUM(valor), 2) AS s FROM `vanguardamartech_raw`.`supabase_silver_custo_wl_instancia` GROUP BY periodo
)
SELECT
  f.periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(f.periodo, '-01'))                 AS mes_referencia,
  NULLIF(TRIM(f.parceiro), '')                                          AS parceiro,
  f.contas                                                              AS valor_contas,
  f.instancias_zapi                                                     AS valor_instancias_zapi,
  f.infraestrutura                                                      AS valor_infraestrutura,
  f.desconto_volume                                                     AS valor_desconto_volume,
  f.dominio                                                             AS valor_dominio,
  f.aplicativo                                                          AS valor_aplicativo,
  f.total_fatura                                                        AS valor_total_fatura,
  c.s                                                                   AS contas_detalhe,
  ROUND(c.s - f.contas, 2)                                              AS diff_contas,
  i.s                                                                   AS infra_detalhe,
  ROUND(i.s - f.infraestrutura, 2)                                      AS diff_infra,
  z.s                                                                   AS instancias_detalhe,
  ROUND(z.s - f.instancias_zapi, 2)                                     AS diff_instancias,
  (ABS(f.total_fatura - (f.contas + f.instancias_zapi + f.infraestrutura + f.desconto_volume + f.dominio + f.aplicativo)) > 0.01) AS flag_total_nao_fecha,
  DATE(f.fetched_at, 'America/Sao_Paulo')                               AS arquivo_lido_em,
  CURRENT_TIMESTAMP()                                                   AS _extraido_at,
  'supabase-x0tz'                                                       AS _fonte,
  'America/Sao_Paulo'                                                   AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                                        AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_silver_custo_wl_consolidado` f
LEFT JOIN conta c ON c.periodo = f.periodo
LEFT JOIN infra i ON i.periodo = f.periodo
LEFT JOIN inst  z ON z.periodo = f.periodo
