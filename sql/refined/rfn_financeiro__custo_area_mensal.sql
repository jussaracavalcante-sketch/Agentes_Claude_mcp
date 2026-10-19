-- rfn_financeiro__custo_area_mensal  ·  Refined / financeiro  ·  L3 CONFIDENTIAL
-- Grao: um MES de competencia - quanto do custo do Supabase tem centro de custo. Le: trs_financeiro__custo_area_mes (query-OMqx).
-- Gatilho: evento em query-OMqx. Cadencia herdada: semanal (segunda 07:20 America/Manaus).
-- VALIDACAO (2026-10-19): 56 meses, 56 chaves, 2019-12 a 2026-12; 344 linhas de origem, 28.056 lancamentos e R$ 46.795.780,19 (= Trusted); sem centro R$ 40.003.426,46 + com centro R$ 6.792.353,73; centro multiplo R$ 10.542,59; 1 mes posterior a carga.
-- REGRA 1 - AGREGA, NAO FILTRA: SUM(custo_total_abs) = R$ 46.795.780,19 e SUM(qtd_lancamentos) = 28.056 (344 linhas de origem, 19/10/2026).
-- REGRA 2 - COBERTURA DE CENTRO: `pct_custo_sem_centro` = custo do balde SEM centro / custo do mes; NULL quando o custo do mes e zero. 85,5% do custo total esta sem centro;
--   o centro de custo so existe de fato a partir de 2025-11 (era Conta Azul), antes e o custo do iClips.
-- REGRA 3 - LISTA DE CENTROS NAO E RATEIO: 4 linhas de origem trazem varios centros separados por virgula; ficam em `custo_centro_multiplo_abs` e NUNCA sao divididas.
-- REGRA 4 - `is_mes_posterior_a_carga` compara com o mes da CARGA da Trusted, nao com o relogio.
-- LIMITACOES - NAO CONTORNE: NAO e custo operacional da casa (trs_financeiro__movimento, classe OPERACIONAL, R$ 31,35 mi; saida total R$ 50,65 mi): a view do Supabase mistura iClips e
--   Conta Azul com recorte proprio; nao serve para rateio por area antes de 2025-11; competencia, nao caixa.
WITH t AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__custo_area_mes`
),
g AS (
  SELECT
    mes_referencia,
    COUNT(*)                                                          AS qtd_linhas_origem,
    COUNT(DISTINCT centro_custos)                                     AS qtd_centros_distintos,
    SUM(qtd_lancamentos)                                              AS qtd_lancamentos,
    ROUND(SUM(custo_total_abs), 2)                                    AS custo_total_abs,
    ROUND(SUM(IF(flag_sem_centro_de_custo, custo_total_abs, 0)), 2)   AS custo_sem_centro_abs,
    ROUND(SUM(IF(NOT flag_sem_centro_de_custo, custo_total_abs, 0)), 2) AS custo_com_centro_abs,
    ROUND(SUM(IF(flag_centro_multiplo, custo_total_abs, 0)), 2)       AS custo_centro_multiplo_abs,
    MAX(DATE(_extraido_at, 'America/Sao_Paulo'))                      AS data_carga_trusted
  FROM t
  GROUP BY mes_referencia
),
final AS (
  SELECT
    CAST(mes_referencia AS STRING)                                    AS id_custo_area_mensal,
    g.*,
    SAFE_DIVIDE(custo_sem_centro_abs, NULLIF(custo_total_abs, 0))     AS pct_custo_sem_centro,
    (mes_referencia > DATE_TRUNC(data_carga_trusted, MONTH))          AS is_mes_posterior_a_carga,
    'L3_CONFIDENTIAL'                                                 AS classificacao_dado
  FROM g
)
SELECT
  f.*,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
