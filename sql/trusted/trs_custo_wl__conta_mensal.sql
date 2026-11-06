-- trs_custo_wl__conta_mensal (query-kafQ)
-- Trusted / Custo white-label (VBOT). Grao: uma CONTA em um MES de fatura. Chave: (periodo, conta_key).
-- Nivel: L3 CONFIDENTIAL (custo por conta de cliente da VBOT).
--
-- O QUE E. Detalhe por conta da fatura mensal do parceiro white-label cobrada da VBOT
-- (arquivos faturamento_wl_*.xlsx, ingeridos na supabase-x0tz; 'parceiro' = VBOT SOLUCOES DE COMUNICACAO LTDA).
-- Que e CUSTO da VBOT (e nao receita) vem do nome da origem (custo_wl) e da coluna parceiro; nao foi
-- confirmado contra o contrato: tratar como leitura declarada.
--
-- ORIGEM. supabase_silver_custo_wl_conta (569) FULL OUTER JOIN supabase_silver_custo_wl_infra (564) por
-- (periodo, conta_key). Medido em 18/10/2026: 538 pares nos dois, 31 so em conta, 26 so em infra => 595 linhas,
-- 595 chaves, 8 periodos (2026-01 a 2026-08), 116 contas distintas (115 na parte de conta). bronze_custo_wl__contas
-- (660) e __custo_infraestrutura (651) sao versoes das mesmas chaves e nao foram usados.
--
-- IDENTIDADES (medidas; somas totais R$ 219.138,94 de contas e R$ 25.506,71 de infra; sao a prova de que o tratamento nao perdeu dinheiro):
--   SUM(total_contas) por periodo = consolidado.contas, EXATO nos 8 periodos (R$ 15.593,85 a R$ 39.006,47)
--   SUM(custo_infra)  por periodo = consolidado.infraestrutura, EXATO nos 8 periodos
--
-- ZERO. custo_infra e zero ou negativo em 475 das 564 linhas de infra (84%): so ~89 contas pagam infraestrutura
-- no mes. E zero real (o parceiro nao cobrou), nao ausencia; por isso passa como veio e flag_infra_zerada marca.
--
-- LIMITACAO -- NAO CONTORNE: conta_key e o apelido do cliente em minusculas (nao e CNPJ nem id do Conexa);
-- ligar com cliente da VBOT e casamento por nome (hipotese declarada, nao prova). Periodos sao mensais; o
-- arquivo de agosto tem carga de 17/08/2026 (periodo possivelmente parcial).
SELECT
  COALESCE(c.periodo, i.periodo)                                  AS periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(COALESCE(c.periodo, i.periodo), '-01')) AS mes_referencia,
  COALESCE(c.conta_key, i.conta_key)                              AS conta_key,
  COALESCE(NULLIF(TRIM(c.conta_fantasia), ''), NULLIF(TRIM(i.conta_fantasia), '')) AS conta_fantasia,
  NULLIF(TRIM(c.conta_razao), '')                                 AS conta_razao,
  NULLIF(TRIM(c.conta_raw), '')                                   AS conta_raw,
  c.qtde_usuarios,
  c.qtde_canais,
  c.app_transcricao,
  c.app_asaas,
  c.ia,
  c.usuarios_faixa1, c.usuarios_faixa2, c.usuarios_faixa3,
  c.canais_faixa1, c.canais_faixa2,
  c.usuarios_cortesia, c.canais_cortesia,
  SAFE_CAST(CAST(c.inicio_faturamento AS STRING) AS DATE)         AS inicio_faturamento,
  SAFE_CAST(CAST(c.fim_faturamento AS STRING) AS DATE)            AS fim_faturamento,
  c.total_contas                                                  AS valor_contas,
  i.atendimentos,
  i.mau,
  i.mau_exc_0045,
  i.mau_exc_0035,
  i.mau_exc_0025,
  i.custo_infra                                                   AS valor_infra,
  (c.conta_key IS NOT NULL AND i.conta_key IS NULL)               AS flag_so_conta,
  (c.conta_key IS NULL AND i.conta_key IS NOT NULL)               AS flag_so_infra,
  (i.conta_key IS NOT NULL AND i.custo_infra <= 0)                AS flag_infra_zerada,
  IFNULL(c.total_contas, 0) + IFNULL(i.custo_infra, 0)            AS valor_total_conta,
  DATE(GREATEST(IFNULL(c.fetched_at, i.fetched_at), IFNULL(i.fetched_at, c.fetched_at)), 'America/Sao_Paulo') AS arquivo_lido_em,
  CURRENT_TIMESTAMP()                                             AS _extraido_at,
  'supabase-x0tz'                                                 AS _fonte,
  'America/Sao_Paulo'                                             AS _fuso,
  TO_HEX(MD5(CONCAT(TO_JSON_STRING(c), TO_JSON_STRING(i))))       AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_silver_custo_wl_conta` c
FULL OUTER JOIN `vanguardamartech_raw`.`supabase_silver_custo_wl_infra` i
  ON c.periodo = i.periodo AND c.conta_key = i.conta_key
