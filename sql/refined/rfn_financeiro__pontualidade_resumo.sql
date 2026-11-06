-- rfn_financeiro__pontualidade_resumo  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (a Trusted e L4; nome, documento, e-mail e telefone NAO atravessam)
-- Grao: origem do instrumento x operacao x tipo de identificacao do cliente x tier de pontualidade. Le: trs_financeiro__pontualidade_cliente (query-7Q3r).
-- Gatilho: evento em query-7Q3r. Cadencia herdada: semanal (segunda 06:45 America/Manaus).
-- VALIDACAO (2026-10-19): 22 linhas, 22 chaves; 1.363 linhas de origem, 35.235 pagamentos, R$ 116.573.256,87, 12 cronicos e 10 documentos repadronizados (= Trusted); ICLIPS_CRONICO 514, BASE_CA 672, SCORE 177; balde sem pessoa 2; nenhuma linha do SCORE tem taxa t0.
-- REGRA 1 - AGREGA, NAO FILTRA, E AS TRES ORIGENS NAO SE SOMAM: ICLIPS_CRONICO (514 clientes), BASE_CA (672, superconjunto da primeira) e SCORE (177) medem universos diferentes.
--   Dentro de cada origem as linhas reproduzem a Trusted (1.363 linhas, 35.235 pagamentos, R$ 116.573.256,87 somando as tres - numero que NAO tem leitura de negocio, so serve de identidade).
-- REGRA 2 - TAXA DE ATRASO E RAZAO DE SOMAS, nunca media de taxas: `taxa_atraso_t0` = SUM(n_atraso_t0) / SUM(n_pagos) do grupo (idem t3 e t7); NULL quando o instrumento
--   nao traz a metrica (SCORE nao tem t0/t3/t7) ou nao ha pagamento, nunca zero.
-- REGRA 3 - O BALDE SEM PESSOA FICA NO GRAO (tipo_identificacao = BALDE_SEM_PESSOA): titulos sem pessoa NAO sao cliente (2 linhas de BASE_CA); quem le por cliente o exclui.
-- REGRA 4 - A IDENTIFICACAO NAO E SO DOCUMENTO: PJ (14), PF (11), DOCUMENTO_INVALIDO (fragmento), CHAVE_POR_NOME, ID_CONEXA (cliente da VBOT) ou SEM_DOCUMENTO; documento nunca e emitido.
-- LIMITACOES - NAO CONTORNE: as metricas t0/t3/t7 sao da origem (atraso maior que 0, 3 e 7 dias) e nao sao recalculadas; `valor_em_aberto` e `valor_vencido_aberto` sao relativos a DATA DA CARGA
--   do Supabase; o SCORE nao tem operacao; comeca em 2021 no iClips e em 2025 no Conta Azul; nao e inadimplencia (isso e rfn_financeiro__fluxo_caixa e rfn_financeiro__inadimplencia_vbot).
WITH t AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__pontualidade_cliente`
),
k AS (
  SELECT
    t.*,
    CASE
      WHEN flag_balde_sem_pessoa THEN 'BALDE_SEM_PESSOA'
      WHEN is_pj THEN 'PJ'
      WHEN is_pf THEN 'PF'
      WHEN flag_documento_invalido THEN 'DOCUMENTO_INVALIDO'
      WHEN chave_por_nome IS NOT NULL THEN 'CHAVE_POR_NOME'
      WHEN id_cliente_conexa IS NOT NULL THEN 'ID_CONEXA'
      ELSE 'SEM_DOCUMENTO'
    END AS tipo_identificacao
  FROM t
),
g AS (
  SELECT
    origem,
    operacao,
    tipo_identificacao,
    tier_pontualidade,
    COUNT(*)                                       AS qtd_linhas,
    SUM(n_pagos)                                   AS n_pagos,
    SUM(n_atraso_t0)                               AS n_atraso_t0,
    SUM(n_atraso_t3)                               AS n_atraso_t3,
    SUM(n_atraso_t7)                               AS n_atraso_t7,
    ROUND(SUM(soma_valor), 2)                      AS soma_valor,
    SUM(soma_dias_t0)                              AS soma_dias_t0,
    MAX(pior_atraso)                               AS pior_atraso,
    COUNTIF(is_cronico)                            AS qtd_cronicos,
    COUNTIF(is_risco_juridico)                     AS qtd_risco_juridico,
    COUNTIF(flag_documento_repadronizado)          AS qtd_documento_repadronizado,
    ROUND(SUM(em_aberto_atual), 2)                 AS valor_em_aberto,
    ROUND(SUM(vencido_aberto), 2)                  AS valor_vencido_aberto,
    MAX(DATE(_extraido_at, 'America/Sao_Paulo'))   AS data_carga_trusted
  FROM k
  GROUP BY origem, operacao, tipo_identificacao, tier_pontualidade
),
final AS (
  SELECT
    CONCAT(origem, '|', IFNULL(operacao, '~'), '|', tipo_identificacao, '|', IFNULL(tier_pontualidade, '~')) AS id_pontualidade_resumo,
    g.*,
    SAFE_DIVIDE(n_atraso_t0, NULLIF(n_pagos, 0))   AS taxa_atraso_t0,
    SAFE_DIVIDE(n_atraso_t3, NULLIF(n_pagos, 0))   AS taxa_atraso_t3,
    SAFE_DIVIDE(n_atraso_t7, NULLIF(n_pagos, 0))   AS taxa_atraso_t7,
    'L3_CONFIDENTIAL'                              AS classificacao_dado
  FROM g
)
SELECT
  f.*,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
