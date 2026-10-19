-- trs_financeiro__custo_area_mes
-- Trusted / Financeiro. Grao: um CENTRO DE CUSTO (rotulo cru da origem) em um mes de competencia, com o custo total e a quantidade de lancamentos, na visao do Supabase.
-- Chave: id_custo_mes = <mes>|<centro_custos ou SEM_CENTRO_DE_CUSTO> (344 linhas, 344 chaves; medido em 2026-10-19).
-- Origem: vanguardamartech_raw.supabase_public_vw_custo_por_area (fonte supabase-x0tz, diaria). Cadencia desta Trusted: semanal (segunda 07:20 America/Manaus).
-- Nivel: L3 CONFIDENTIAL (custo por area).
-- MEDIDO (2026-10-19): `diretoria` e `area` sao NULL em 344 de 344 - CAMPOS MORTOS, NAO EMITIDOS (emitidos seriam coluna constante que convida a agrupar por nada) ·
--   56 linhas SEM centro de custo carregam R$ 40.003.426,46 dos R$ 46.795.780,19 (85,5%) e 2019-12 a 2026-06: e o custo do iClips, que nao tem centro de custo ·
--   as 288 linhas COM centro comecam de fato em 2025-11 (era Conta Azul; antes disso so 15 linhas residuais) · 56 centros distintos, 4 deles sao LISTA de centros separada por
--   virgula (rateio nao desaninhado na origem: flag_centro_multiplo) · custo sempre NEGATIVO (sinal de saida) · 3 linhas em 2026-12 (lancamento futuro) · 28.056 lancamentos.
-- O QUE NAO FECHA, E PORQUE: a soma (R$ 46,80 mi) NAO reproduz a saida de trs_financeiro__movimento (R$ 50,65 mi) nem a saida OPERACIONAL (R$ 31,35 mi): a view mistura
--   iClips (sem centro) e Conta Azul (com centro) com recorte proprio. Nao ha identidade a declarar; e um ponto de vista do Supabase, preservado.
-- LIMITACOES - NAO CONTORNE: nao serve para rateio por area antes de 2025-11 (85% do custo esta no balde sem centro); o rotulo de centro e texto cru (nao resolve para
--   trs_financeiro__dicionario por chave); custo em competencia, nao caixa.
WITH origem AS (
  SELECT * FROM `vanguardamartech_raw`.`supabase_public_vw_custo_por_area`
),
final AS (
  SELECT
    CONCAT(CAST(mes AS STRING), '|', IFNULL(centro_custos, 'SEM_CENTRO_DE_CUSTO')) AS id_custo_mes,
    mes                                                              AS mes_referencia,
    NULLIF(TRIM(centro_custos), '')                                  AS centro_custos,
    (centro_custos IS NULL)                                          AS flag_sem_centro_de_custo,
    (STRPOS(IFNULL(centro_custos, ''), ',') > 0)                     AS flag_centro_multiplo,
    custo_total,
    ABS(custo_total)                                                 AS custo_total_abs,
    qtd_lancamentos
  FROM origem
)
SELECT
  f.*,
  'L3_CONFIDENTIAL'                  AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
