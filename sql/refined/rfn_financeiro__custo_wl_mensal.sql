-- rfn_financeiro__custo_wl_mensal  ·  query-VAZA  ·  Refined  ·  gatilho: evento all em query-uSUb + query-fz02  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Refined / financeiro. Grao: um PERIODO (mes) da fatura do white-label (plataforma de atendimento da VBOT): a fatura do parceiro, o detalhe por conta
-- e por instancia que a compoe, o USO que a gerou e o custo rateado por cliente, lado a lado com as identidades que ligam as cinco Trusted.
-- Le: trs_custo_wl__fatura_mensal (8), trs_custo_wl__conta_mensal (595), trs_custo_wl__instancia_mensal (1.218), trs_vbot__uso_wl_conta_mes (572),
-- trs_vbot__consumo_wl_cliente_mes (550). Nivel: L3 CONFIDENTIAL (custo operacional da VBOT; nenhum cliente nem conta atravessa, so contagem e soma).
-- Gatilho: evento "all" em query-uSUb e query-fz02 (as duas Trusted semanais desta frente); as tres Trusted custo_wl rodam todo dia na supabase-x0tz
-- e sao lidas como estiverem (mesma fonte, dado parado em 2026-08).
-- REGRA 1 A FATURA E O TOTAL; o resto e decomposicao. valor_total_fatura e a soma de contas + instancias_zapi + infraestrutura + desconto_volume
--   + dominio + aplicativo (flag_total_nao_fecha = FALSE nos 8). Nao somar a fatura com o detalhe nem com o custo por cliente: e o mesmo dinheiro.
-- REGRA 2 IDENTIDADES MEDIDAS EM 2026-10-19 (8 periodos): valor_contas_detalhe = valor_contas e valor_infra_detalhe = valor_infraestrutura, EXATOS nos 8;
--   valor_instancias_detalhe > valor_instancias_zapi em 6 dos 8 (dif_instancias_detalhe de R$ 2,25 a R$ 18,00; total R$ 38,41); e
--   custo_liquido_clientes - valor_total_fatura = dif_instancias_detalhe nos 8 (o rateio por cliente parte do detalhe por instancia, nao do consolidado).
--   flag_identidade_fecha acende quando essa igualdade vale dentro de R$ 0,02.
-- REGRA 3 valor_aplicativo e ZERO nos 8 periodos: os apps (transcricao, Asaas, IA) estao DENTRO de valor_contas (custo_licencas + custo_apps = custo_contas,
--   medido 8 de 8). custo_apps e a parte deles.
-- REGRA 4 USO: qtd_usuarios_total e qtd_canais_total somam as faixas das contas; instancia_dias_total soma dias de instancia; qtd_mau e qtd_atendimentos
--   somam clientes dentro do mes e NAO somam entre meses. qtd_contas_com_uso (572 no total) < qtd_contas_faturadas (595): 23 linhas de conta so em infra ou
--   sem uso.
-- REGRA 5 custo_liquido_interno (origem_match INTERNA) e custo_liquido_sem_match sao custo que nao achou cliente externo: ficam visiveis e fora de
--   custo_liquido_clientes_externos. A ligacao conta -> cliente e por NOME.
-- LIMITACAO - NAO CONTORNE: a serie vai de 2026-01 a 2026-08 (ultima fatura apurada, arquivo de 17/08/2026: agosto pode ser parcial); nao ha fatura
--   depois disso e zero nao e custo zero. Nao soma com rfn_financeiro__margem_vbot_mensal (que ja le este custo pelo custo_helena) nem com
--   rfn_financeiro__despesa_vbot_mensal (toda a despesa da VBOT no Conexa, que tambem contem esta fatura).
WITH f AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_custo_wl__fatura_mensal`
),
cm AS (
  SELECT periodo,
         COUNT(*)                                   AS qtd_contas_faturadas,
         COUNTIF(flag_so_conta)                     AS qtd_contas_so_conta,
         COUNTIF(flag_so_infra)                     AS qtd_contas_so_infra,
         COUNTIF(flag_infra_zerada)                 AS qtd_contas_infra_zerada,
         ROUND(SUM(valor_contas), 2)                AS valor_contas_detalhe,
         ROUND(SUM(valor_infra), 2)                 AS valor_infra_detalhe
  FROM `vanguardamartech_trusted`.`trs_custo_wl__conta_mensal`
  GROUP BY periodo
),
inst AS (
  SELECT periodo,
         COUNT(*)                                   AS qtd_instancias_cobradas,
         COUNT(DISTINCT conta_key)                  AS qtd_contas_com_instancia,
         COUNTIF(flag_chave_repetida)               AS qtd_instancias_chave_repetida,
         COUNTIF(flag_valor_zerado)                 AS qtd_instancias_valor_zerado,
         ROUND(SUM(valor), 2)                       AS valor_instancias_detalhe
  FROM `vanguardamartech_trusted`.`trs_custo_wl__instancia_mensal`
  GROUP BY periodo
),
uso AS (
  SELECT periodo,
         COUNT(*)                                   AS qtd_contas_com_uso,
         COUNTIF(is_ativa)                          AS qtd_contas_ativas,
         COUNTIF(is_conta_interna)                  AS qtd_contas_internas,
         COUNTIF(flag_sem_instancia)                AS qtd_contas_sem_instancia,
         COUNTIF(NOT flag_sem_app)                  AS qtd_contas_com_app,
         SUM(qtd_usuarios)                          AS qtd_usuarios_total,
         SUM(usuarios_cortesia)                     AS qtd_usuarios_cortesia,
         SUM(usuarios_faixa1)                       AS qtd_usuarios_faixa1,
         SUM(usuarios_faixa2)                       AS qtd_usuarios_faixa2,
         SUM(usuarios_faixa3)                       AS qtd_usuarios_faixa3,
         SUM(qtd_canais)                            AS qtd_canais_total,
         SUM(canais_cortesia)                       AS qtd_canais_cortesia,
         SUM(canais_faixa1)                         AS qtd_canais_faixa1,
         SUM(canais_faixa2)                         AS qtd_canais_faixa2,
         SUM(instancia_dias)                        AS instancia_dias_total,
         SUM(qtd_app_transcricao)                   AS qtd_app_transcricao,
         SUM(qtd_app_asaas)                         AS qtd_app_asaas,
         SUM(qtd_app_ia)                            AS qtd_app_ia,
         ROUND(SUM(custo_helena), 2)                AS custo_helena_contas_com_uso
  FROM `vanguardamartech_trusted`.`trs_vbot__uso_wl_conta_mes`
  GROUP BY periodo
),
cons AS (
  SELECT periodo,
         COUNT(*)                                   AS qtd_clientes,
         COUNTIF(is_cliente_interno)                AS qtd_clientes_internos,
         COUNTIF(is_sem_match)                      AS qtd_clientes_sem_match,
         COUNTIF(flag_sem_medicao_uso)              AS qtd_clientes_sem_medicao_uso,
         ROUND(SUM(custo_licencas), 2)              AS custo_licencas,
         ROUND(SUM(custo_apps), 2)                  AS custo_apps,
         ROUND(SUM(custo_instancias), 2)            AS custo_instancias,
         ROUND(SUM(custo_infra), 2)                 AS custo_infra,
         ROUND(SUM(custo_bruto), 2)                 AS custo_bruto,
         ROUND(SUM(desconto_rateado), 2)            AS desconto_rateado,
         ROUND(SUM(dominio_rateado), 2)             AS dominio_rateado,
         ROUND(SUM(custo_liquido), 2)               AS custo_liquido_clientes,
         ROUND(SUM(IF(is_cliente_interno, custo_liquido, 0)), 2) AS custo_liquido_interno,
         ROUND(SUM(IF(is_sem_match, custo_liquido, 0)), 2)       AS custo_liquido_sem_match,
         SUM(qtd_atendimentos)                      AS qtd_atendimentos,
         SUM(qtd_mau)                               AS qtd_mau
  FROM `vanguardamartech_trusted`.`trs_vbot__consumo_wl_cliente_mes`
  GROUP BY periodo
),
final AS (
  SELECT
    f.periodo                                                     AS id_periodo,
    f.periodo,
    f.mes_referencia,
    f.parceiro,
    f.valor_total_fatura,
    f.valor_contas,
    f.valor_instancias_zapi,
    f.valor_infraestrutura,
    f.valor_desconto_volume,
    f.valor_dominio,
    f.valor_aplicativo,
    f.flag_total_nao_fecha,
    f.arquivo_lido_em,
    cm.qtd_contas_faturadas,
    cm.qtd_contas_so_conta,
    cm.qtd_contas_so_infra,
    cm.qtd_contas_infra_zerada,
    cm.valor_contas_detalhe,
    ROUND(cm.valor_contas_detalhe - f.valor_contas, 2)            AS dif_contas_detalhe,
    cm.valor_infra_detalhe,
    ROUND(cm.valor_infra_detalhe - f.valor_infraestrutura, 2)     AS dif_infra_detalhe,
    inst.qtd_instancias_cobradas,
    inst.qtd_contas_com_instancia,
    inst.qtd_instancias_chave_repetida,
    inst.qtd_instancias_valor_zerado,
    inst.valor_instancias_detalhe,
    ROUND(inst.valor_instancias_detalhe - f.valor_instancias_zapi, 2) AS dif_instancias_detalhe,
    uso.qtd_contas_com_uso,
    uso.qtd_contas_ativas,
    uso.qtd_contas_internas,
    uso.qtd_contas_sem_instancia,
    uso.qtd_contas_com_app,
    uso.qtd_usuarios_total,
    uso.qtd_usuarios_cortesia,
    uso.qtd_usuarios_faixa1,
    uso.qtd_usuarios_faixa2,
    uso.qtd_usuarios_faixa3,
    uso.qtd_canais_total,
    uso.qtd_canais_cortesia,
    uso.qtd_canais_faixa1,
    uso.qtd_canais_faixa2,
    uso.instancia_dias_total,
    uso.qtd_app_transcricao,
    uso.qtd_app_asaas,
    uso.qtd_app_ia,
    uso.custo_helena_contas_com_uso,
    cons.qtd_clientes,
    cons.qtd_clientes_internos,
    cons.qtd_clientes_sem_match,
    cons.qtd_clientes_sem_medicao_uso,
    cons.custo_licencas,
    cons.custo_apps,
    cons.custo_instancias,
    cons.custo_infra,
    cons.custo_bruto,
    cons.desconto_rateado,
    cons.dominio_rateado,
    cons.custo_liquido_clientes,
    cons.custo_liquido_interno,
    cons.custo_liquido_sem_match,
    ROUND(cons.custo_liquido_clientes - cons.custo_liquido_interno - cons.custo_liquido_sem_match, 2) AS custo_liquido_clientes_externos,
    cons.qtd_atendimentos,
    cons.qtd_mau,
    ROUND(cons.custo_liquido_clientes - f.valor_total_fatura, 2)  AS dif_liquido_clientes_vs_fatura,
    (ABS((cons.custo_liquido_clientes - f.valor_total_fatura) - (inst.valor_instancias_detalhe - f.valor_instancias_zapi)) <= 0.02) AS flag_identidade_fecha,
    'L3_CONFIDENTIAL'                                             AS classificacao_dado
  FROM f
  LEFT JOIN cm   ON cm.periodo = f.periodo
  LEFT JOIN inst ON inst.periodo = f.periodo
  LEFT JOIN uso  ON uso.periodo = f.periodo
  LEFT JOIN cons ON cons.periodo = f.periodo
)
SELECT x.*,
  CURRENT_TIMESTAMP()                                             AS _extraido_at,
  'supabase-x0tz'                                                 AS _fonte,
  'America/Sao_Paulo'                                             AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(x)))                                  AS _payload_hash
FROM final x
