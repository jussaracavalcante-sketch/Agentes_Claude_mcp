-- trs_vbot__conta_mes
-- Trusted / VBOT. Grao: uma CONTA do white-label (conta_key) em um periodo (mes): custo da plataforma, uso e a ligacao com o cliente do Conexa.
-- Chave (periodo, conta_key): 595 distintos em 595 linhas, medido em 2026-10-18. Junta vw_margem_vbot_conta (ligacao com cliente, desconto e dominio rateados)
-- com mvw_custo_wl_conta_mes (usuarios, canais, MAU por faixa, instancias ociosas): as duas tem as mesmas 595 chaves e custo_helena = custo_bruto em 595 de 595.
-- vw_custo_wl_conta_mes tem as mesmas 595 linhas de mvw_custo_wl_conta_mes e nao foi tratada. Origem: fonte supabase-x0tz. Nivel: L3 CONFIDENTIAL.
-- `mau` existe nas DUAS origens e e IDENTICO (zero divergencias; 31 linhas sao NULL nas duas): sai uma coluna so, qtd_mau. LIGACAO POR NOME (origem_match), nao por documento.
-- Percentuais e derivados vem da origem, nao se recalculam aqui. O custo so existe ate 2026-08.
SELECT
  CONCAT(m.periodo, '|', m.conta_key)               AS id_conta_mes,
  m.periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(m.periodo, '-01')) AS mes_referencia,
  m.conta_key,
  NULLIF(TRIM(m.conta), '')                         AS conta,
  NULLIF(TRIM(w.conta_razao), '')                   AS conta_razao,
  m.cliente_key,
  NULLIF(TRIM(m.cliente_nome), '')                  AS cliente_nome,
  NULLIF(TRIM(m.origem_match), '')                  AS origem_match,
  m.sem_cliente                                     AS is_sem_cliente,
  m.custo_helena,
  w.custo_contas,
  w.custo_infra,
  w.custo_instancias,
  w.custo_bruto,
  m.desconto_rateado,
  m.dominio_rateado,
  w.qtde_usuarios                                   AS qtd_usuarios,
  w.qtde_canais                                     AS qtd_canais,
  m.atendimentos                                    AS qtd_atendimentos,
  m.mau                                             AS qtd_mau,
  w.mau_exc_0045,
  w.mau_exc_0035,
  w.mau_exc_0025,
  w.n_instancias                                    AS qtd_instancias,
  w.n_ociosas                                       AS qtd_instancias_ociosas,
  w.valor_ociosas                                   AS valor_instancias_ociosas,
  (w.conta_key IS NULL)                             AS flag_sem_custo_wl,
  'L3_CONFIDENTIAL'                                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                               AS _extraido_at,
  'supabase-x0tz'                                   AS _fonte,
  TO_HEX(MD5(CONCAT(IFNULL(TO_JSON_STRING(m), ''), '|', IFNULL(TO_JSON_STRING(w), '')))) AS _payload_hash
FROM vanguardamartech_raw.supabase_gold_vw_margem_vbot_conta m
LEFT JOIN vanguardamartech_raw.supabase_gold_mvw_custo_wl_conta_mes w
  ON w.periodo = m.periodo AND w.conta_key = m.conta_key
