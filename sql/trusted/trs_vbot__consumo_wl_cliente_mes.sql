-- trs_vbot__consumo_wl_cliente_mes  ·  query-fz02  ·  Trusted  ·  gatilho: cron segunda 06:00 America/Manaus  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Trusted / VBOT (white-label). Grao: um CLIENTE (cliente_key) em um periodo (mes): custo do white-label com a quebra por componente
-- (licencas, transcricao, Asaas, IA, instancias, infra), desconto e dominio rateados, uso (usuarios, canais, atendimentos, MAU, instancias)
-- e os custos unitarios que a origem calcula. Chave (periodo, cliente_key): 550 distintos em 550 linhas, medido em 2026-10-19.
-- Nivel: L3 CONFIDENTIAL (custo por cliente).
-- ORIGEM: supabase_gold_vw_consumo_vbot_cliente (550) JOIN supabase_gold_vw_consumo_vbot_unitarios (550) por (periodo, cliente_key):
--   mesmas 550 chaves e as 13 colunas em comum IDENTICAS nas 550 (zero divergencias): viram UMA tabela. 8 periodos (2026-01 a 2026-08),
--   103 clientes, 47 linhas INTERNA. As 550 existem em trs_vbot__margem_cliente (766).
-- DECOMPOSICOES MEDIDAS (zero quebras em 550): custo_bruto = licencas + transcricao + asaas + ia + instancias + infra;
--   custo_apps = transcricao + asaas + ia; custo_liquido = custo_bruto + desconto_rateado + dominio_rateado.
--   SUM(custo_bruto) por periodo = SUM(custo_helena) de trs_vbot__conta_mes nos 8 periodos (R$ 298.702,92); licencas + apps = custo_contas.
--   SUM(custo_liquido) R$ 280.919,62 = fatura (R$ 280.881,21) + R$ 38,41 de diff_instancias (o detalhe por instancia cobra a mais que o
--   consolidado em 6 dos 8 periodos; ver trs_custo_wl__fatura_mensal).
-- UNITARIOS NAO SAO RECALCULADOS: licenca_por_usuario, licenca_por_canal, infra_por_atendimento, infra_por_mau, instancia_por_dia e
--   custo_total_por_atendimento passam como a origem entrega (reproduzem custo/quantidade em 100% das linhas nao nulas, medido).
--   NULL = denominador zero ou ausente (licenca_por_usuario 24, licenca_por_canal 46, infra_por_atendimento 23, custo_total_por_atendimento 23).
-- NULL DE USO: atendimentos e mau sao NULL em 23 linhas (nao ha medicao, nao e zero): flag_sem_medicao_uso.
-- LIGACAO COM CLIENTE E POR NOME (origem_match), nunca por documento; cliente_key com prefixo '#conta:' e conta sem cliente resolvido.
-- LIMITACAO - NAO CONTORNE: n_contas > 1 em 16 linhas (cliente com mais de uma conta: contas lista os nomes); cliente_desde NULL em 24;
--   o custo so existe ate 2026-08. Nao somar custo_liquido entre clientes e depois com trs_custo_wl__fatura_mensal: e o mesmo dinheiro.
SELECT
  CONCAT(c.periodo, '|', c.cliente_key)                          AS id_cliente_mes,
  c.periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(c.periodo, '-01'))          AS mes_referencia,
  c.cliente_key,
  NULLIF(TRIM(c.cliente), '')                                    AS cliente,
  NULLIF(TRIM(c.origem_match), '')                               AS origem_match,
  (c.origem_match = 'INTERNA')                                   AS is_cliente_interno,
  (c.origem_match = 'SEM MATCH')                                 AS is_sem_match,
  c.n_contas                                                     AS qtd_contas,
  NULLIF(TRIM(c.contas), '')                                     AS contas,
  c.cliente_desde,
  c.custo_licencas,
  c.custo_transcricao,
  c.custo_asaas,
  c.custo_ia,
  c.custo_apps,
  c.custo_instancias,
  c.custo_infra,
  c.custo_bruto,
  c.desconto_rateado,
  c.dominio_rateado,
  c.custo_liquido,
  c.usuarios                                                     AS qtd_usuarios,
  c.canais                                                       AS qtd_canais,
  c.atendimentos                                                 AS qtd_atendimentos,
  c.mau                                                          AS qtd_mau,
  c.instancias                                                   AS qtd_instancias,
  c.instancias_ociosas                                           AS qtd_instancias_ociosas,
  c.dias_conta_ativa,
  c.instancia_dias,
  c.usuarios_cortesia,
  c.usuarios_faixa1,
  c.usuarios_faixa2,
  c.usuarios_faixa3,
  c.canais_cortesia,
  un.licenca_por_usuario,
  un.licenca_por_canal,
  un.infra_por_atendimento,
  un.infra_por_mau,
  un.instancia_por_dia,
  un.custo_total_por_atendimento,
  (c.atendimentos IS NULL OR c.mau IS NULL)                      AS flag_sem_medicao_uso,
  (c.n_contas > 1)                                               AS flag_multi_conta,
  'L3_CONFIDENTIAL'                                              AS classificacao_dado,
  CURRENT_TIMESTAMP()                                            AS _extraido_at,
  'supabase-x0tz'                                                AS _fonte,
  'America/Sao_Paulo'                                            AS _fuso,
  TO_HEX(MD5(CONCAT(TO_JSON_STRING(c), '|', TO_JSON_STRING(un)))) AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_gold_vw_consumo_vbot_cliente` c
JOIN `vanguardamartech_raw`.`supabase_gold_vw_consumo_vbot_unitarios` un
  ON un.periodo = c.periodo AND un.cliente_key = c.cliente_key
