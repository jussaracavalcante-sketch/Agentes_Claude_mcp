-- rfn_financeiro__mrr_projetado_mensal  ·  Refined / financeiro  ·  L3 CONFIDENTIAL
-- Grao: operacao x mes - o MRR PROJETADO do Supabase com a variacao contra o mes anterior da mesma operacao. Le: trs_financeiro__mrr_projetado (query-wIZn).
-- Gatilho: evento em query-wIZn. Cadencia herdada: semanal (segunda 06:40 America/Manaus).
-- VALIDACAO (2026-10-19): 41 linhas, 41 chaves, MRR R$ 10.624.390,80 e 1.001 contratos-mes (= Trusted); 2 primeiros meses sem anterior (variacao NULL), zero meses nao adjacentes, 31 meses posteriores a carga.
-- REGRA 1 - UMA LINHA POR LINHA DA TRUSTED: 41 linhas, MRR R$ 10.624.390,80, 1.001 contratos-mes (19/10/2026); nada e filtrado nem somado entre operacoes.
-- REGRA 2 - VARIACAO: `variacao_mrr` = mrr - mrr do mes anterior da MESMA operacao; o primeiro mes de cada operacao nao tem anterior e sai NULL, nunca zero (zero seria "nao mudou").
-- REGRA 3 - SE O MES ANTERIOR NAO E O DE CALENDARIO ANTERIOR (buraco na serie), `flag_mes_anterior_nao_adjacente` acende e a variacao e calculada mesmo assim, declarada.
-- REGRA 4 - `is_mes_posterior_a_carga` compara com o mes da CARGA da Trusted, nao com o relogio: 31 das 41 linhas sao projecao.
-- LIMITACOES - NAO CONTORNE: e PROJECAO do Supabase sobre parcela recorrente - NAO e o MRR do snapshot (rfn_financeiro__contazul_mrr_mensal, R$ 4,29 mi) nem o das vendas
--   (BRM 2027-04: 293.393,49 aqui contra 311.714,00 e 290.119,21); sao TRES definicoes e nao se somam nem se comparam como versoes do mesmo numero; comeca em 2026-06.
WITH t AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__mrr_projetado`
),
l AS (
  SELECT
    t.*,
    LAG(mrr)            OVER (PARTITION BY operacao ORDER BY mes_referencia) AS mrr_mes_anterior,
    LAG(mes_referencia) OVER (PARTITION BY operacao ORDER BY mes_referencia) AS mes_anterior
  FROM t
),
final AS (
  SELECT
    id_mrr_mes                                                  AS id_mrr_projetado_mensal,
    operacao,
    mes_referencia,
    mrr,
    contratos_ativos,
    arpa,
    mrr_mes_anterior,
    ROUND(mrr - mrr_mes_anterior, 2)                            AS variacao_mrr,
    SAFE_DIVIDE(mrr - mrr_mes_anterior, mrr_mes_anterior)       AS variacao_pct,
    (mes_anterior IS NOT NULL AND DATE_DIFF(mes_referencia, mes_anterior, MONTH) <> 1) AS flag_mes_anterior_nao_adjacente,
    (mes_referencia > DATE_TRUNC(DATE(_extraido_at, 'America/Sao_Paulo'), MONTH))       AS is_mes_posterior_a_carga,
    'L3_CONFIDENTIAL'                                           AS classificacao_dado
  FROM l
)
SELECT
  f.*,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
