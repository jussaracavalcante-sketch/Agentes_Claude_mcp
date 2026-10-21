-- rfn_rh__turnover_mensal
-- Refined / rh. Grao: mes x tipo de contrato ATUAL da pessoa. Le trs_rh__colaborador_mes (uma linha por pessoa e mes; admissao e desligamento sao constantes por pessoa).
-- Nivel: L3 CONFIDENTIAL (contagens por mes e tipo de contrato; nenhuma pessoa, nome ou remuneracao atravessa; celulas pequenas existem).
-- REGRA 1: a base de pessoas e o conjunto de pessoa distinta de trs_rh__colaborador_mes (so quem teve alguma evidencia desde o primeiro mes da tabela); admissao e desligamento
--          sao os formais. Pessoa SEM data de admissao fica fora do headcount e e contada em qtd_sem_admissao_na_base (o headcount e piso).
-- REGRA 2: headcount_inicio = admitidos ANTES do mes e ainda nao desligados no inicio do mes; entradas = admissoes no mes; saidas = desligamentos no mes de quem TEM
--          admissao (as saidas de quem nao tem ficam em saidas_sem_admissao e fora do headcount); headcount_fim = inicio + entradas - saidas. Os meses vao do primeiro mes da tabela ao mes da carga (DATE(_extraido_at)), nunca do relogio de quem le.
-- REGRA 3: turnover_pct = saidas / media(headcount_inicio, headcount_fim); NULL quando a media e zero, nunca zero. Tempo de casa so de quem tem admissao.
-- REGRA 4: o tipo de contrato e o ATUAL (hoje), nao o da epoca: quem mudou de regime aparece no regime de hoje em todos os meses.
-- LIMITACOES - NAO CONTORNE: nao e o headcount oficial (a base e quem teve evidencia desde 2024-01); celulas por tipo de contrato podem ter 1 a poucas pessoas;
--   nao soma com trs_rh__pessoa (Qulture, 165 pessoas) nem com trs_rh__desligamento (outro universo, 300 pessoas); desligamento aqui e a data efetiva do RH formal.
WITH p AS (
  SELECT
    id_pessoa,
    ANY_VALUE(data_admissao)                          AS data_admissao,
    ANY_VALUE(data_desligamento)                      AS data_desligamento,
    IFNULL(ANY_VALUE(rh_tipo_contrato_atual), '(sem tipo)') AS tipo_contrato
  FROM vanguardamartech_trusted.trs_rh__colaborador_mes
  GROUP BY id_pessoa
),
lim AS (
  SELECT MIN(mes_referencia) AS mes_ini, DATE_TRUNC(DATE(MAX(_extraido_at)), MONTH) AS mes_fim
  FROM vanguardamartech_trusted.trs_rh__colaborador_mes
),
meses AS (
  SELECT m AS mes_referencia
  FROM lim, UNNEST(GENERATE_DATE_ARRAY(lim.mes_ini, lim.mes_fim, INTERVAL 1 MONTH)) AS m
),
tipos AS (
  SELECT DISTINCT tipo_contrato FROM p
),
base AS (
  SELECT m.mes_referencia, t.tipo_contrato
  FROM meses m CROSS JOIN tipos t
),
agg AS (
  SELECT
    b.mes_referencia,
    b.tipo_contrato,
    COUNTIF(p.data_admissao IS NOT NULL AND p.data_admissao < b.mes_referencia
            AND (p.data_desligamento IS NULL OR p.data_desligamento >= b.mes_referencia)) AS headcount_inicio,
    COUNTIF(p.data_admissao IS NOT NULL AND DATE_TRUNC(p.data_admissao, MONTH) = b.mes_referencia) AS entradas,
    COUNTIF(p.data_admissao IS NOT NULL AND p.data_desligamento IS NOT NULL AND DATE_TRUNC(p.data_desligamento, MONTH) = b.mes_referencia) AS saidas,
    COUNTIF(p.data_admissao IS NULL AND p.data_desligamento IS NOT NULL AND DATE_TRUNC(p.data_desligamento, MONTH) = b.mes_referencia) AS saidas_sem_admissao,
    COUNTIF(p.data_admissao IS NOT NULL AND p.data_admissao < DATE_ADD(b.mes_referencia, INTERVAL 1 MONTH)
            AND (p.data_desligamento IS NULL OR p.data_desligamento >= DATE_ADD(b.mes_referencia, INTERVAL 1 MONTH))) AS headcount_fim_medido,
    AVG(IF(p.data_admissao IS NOT NULL AND p.data_admissao < DATE_ADD(b.mes_referencia, INTERVAL 1 MONTH)
           AND (p.data_desligamento IS NULL OR p.data_desligamento >= DATE_ADD(b.mes_referencia, INTERVAL 1 MONTH)),
           DATE_DIFF(DATE_ADD(b.mes_referencia, INTERVAL 1 MONTH), p.data_admissao, DAY) / 30.4375, NULL)) AS tempo_casa_medio_meses_fim,
    COUNTIF(p.data_admissao IS NULL) AS qtd_sem_admissao_na_base
  FROM base b
  JOIN p ON p.tipo_contrato = b.tipo_contrato
  GROUP BY b.mes_referencia, b.tipo_contrato
)
SELECT
  CONCAT(CAST(mes_referencia AS STRING), '|', tipo_contrato)  AS id_turnover_mensal,
  mes_referencia,
  tipo_contrato,
  headcount_inicio,
  entradas,
  saidas,
  saidas_sem_admissao,
  headcount_inicio + entradas - saidas                         AS headcount_fim,
  headcount_fim_medido,
  SAFE_DIVIDE(saidas, NULLIF((headcount_inicio + (headcount_inicio + entradas - saidas)) / 2, 0)) AS turnover_pct,
  tempo_casa_medio_meses_fim,
  qtd_sem_admissao_na_base,
  'L3_CONFIDENTIAL'                                            AS classificacao_dado,
  CURRENT_TIMESTAMP()                                          AS _extraido_at,
  'supabase-x0tz'                                              AS _fonte
FROM agg
