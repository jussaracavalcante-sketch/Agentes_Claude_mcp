-- rfn_financeiro__margem_vbot_mensal
-- Refined / financeiro. Grao: periodo (mes) da VBOT. Le trs_vbot__margem_cliente (receita Conexa x custo white-label por cliente) e trs_vbot__conta_mes (uso e custo por conta).
-- Nivel: L3 CONFIDENTIAL (agregado por mes; nenhum cliente atravessa).
-- REGRA 1: custo_apurado = o mes tem custo de white-label na origem (soma de custo_helena > 0). Medido: 2026-01 a 2026-08 SIM; 2025-12 e 2026-09 em diante NAO. Mes sem custo apurado tem
--          margem_apurada e margem_pct NULL, nunca a receita inteira: custo zero na origem e fatura ainda nao apurada, nao custo zero.
-- REGRA 2: margem_apurada = receita_conexa - custo_helena; margem_pct e recalculada da razao de somas (margem_apurada / receita_conexa), nao e media de percentuais de cliente.
-- REGRA 3: a ligacao conta -> cliente e por NOME (origem_match), nunca por documento: receita_sem_conta = receita de cliente sem conta de custo (SO RECEITA) e
--          custo_sem_cliente = custo que nao achou cliente (INTERNA e SEM MATCH). Os dois ficam visiveis: margem por mes e confiavel, por cliente e hipotese.
-- REGRA 4: uso (contas, usuarios, canais, atendimentos, MAU, instancias) vem do custo por conta; MAU e atendimentos nao somam entre meses.
-- LIMITACOES - NAO CONTORNE: nao soma com rfn_financeiro__receita_vbot_mensal nem com rfn_financeiro__despesa_vbot_mensal (outros recortes do Conexa: la a despesa nao tem cliente);
--   so a operacao VBOT; o custo e o da plataforma white-label, nao toda a despesa da VBOT.
WITH c AS (
  SELECT * FROM vanguardamartech_trusted.trs_vbot__margem_cliente
),
cm AS (
  SELECT * FROM vanguardamartech_trusted.trs_vbot__conta_mes
),
fin AS (
  SELECT
    mes_referencia,
    operacao,
    COUNT(*)                                              AS qtd_linhas_cliente,
    COUNTIF(receita_conexa > 0)                           AS qtd_clientes_com_receita,
    COUNTIF(custo_helena > 0)                             AS qtd_clientes_com_custo,
    SUM(receita_conexa)                                   AS receita_conexa,
    SUM(custo_helena)                                     AS custo_helena,
    SUM(desconto_rateado)                                 AS desconto_rateado,
    SUM(dominio_rateado)                                  AS dominio_rateado,
    SUM(custo_liquido)                                    AS custo_liquido,
    SUM(IF(origem_match = 'SO RECEITA', receita_conexa, 0)) AS receita_sem_conta,
    SUM(IF(is_sem_cliente, custo_helena, 0))              AS custo_sem_cliente
  FROM c
  GROUP BY mes_referencia, operacao
),
uso AS (
  SELECT
    mes_referencia,
    COUNT(*)                                              AS qtd_contas,
    SUM(qtd_usuarios)                                     AS qtd_usuarios,
    SUM(qtd_canais)                                       AS qtd_canais,
    SUM(qtd_atendimentos)                                 AS qtd_atendimentos,
    SUM(qtd_mau)                                          AS qtd_mau,
    SUM(qtd_instancias)                                   AS qtd_instancias,
    SUM(qtd_instancias_ociosas)                           AS qtd_instancias_ociosas,
    SUM(valor_instancias_ociosas)                         AS valor_instancias_ociosas
  FROM cm
  GROUP BY mes_referencia
)
SELECT
  CONCAT(CAST(f.mes_referencia AS STRING), '|', f.operacao)  AS id_margem_mensal,
  f.mes_referencia,
  f.operacao,
  f.qtd_linhas_cliente,
  f.qtd_clientes_com_receita,
  f.qtd_clientes_com_custo,
  f.receita_conexa,
  f.custo_helena,
  (IFNULL(f.custo_helena, 0) > 0)                            AS custo_apurado,
  IF(IFNULL(f.custo_helena, 0) > 0, f.receita_conexa - f.custo_helena, NULL) AS margem_apurada,
  IF(IFNULL(f.custo_helena, 0) > 0, SAFE_DIVIDE(f.receita_conexa - f.custo_helena, NULLIF(f.receita_conexa, 0)), NULL) AS margem_pct,
  f.desconto_rateado,
  f.dominio_rateado,
  f.custo_liquido,
  f.receita_sem_conta,
  f.custo_sem_cliente,
  u.qtd_contas,
  u.qtd_usuarios,
  u.qtd_canais,
  u.qtd_atendimentos,
  u.qtd_mau,
  u.qtd_instancias,
  u.qtd_instancias_ociosas,
  u.valor_instancias_ociosas,
  'L3_CONFIDENTIAL'                                          AS classificacao_dado,
  CURRENT_TIMESTAMP()                                        AS _extraido_at,
  'supabase-x0tz'                                            AS _fonte
FROM fin f
LEFT JOIN uso u ON u.mes_referencia = f.mes_referencia
