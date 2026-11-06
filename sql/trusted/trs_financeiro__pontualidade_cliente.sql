-- trs_financeiro__pontualidade_cliente
-- Trusted / Financeiro. Grao: um CLIENTE em uma ORIGEM de medicao de pontualidade de pagamento (tres instrumentos do Supabase, lado a lado, com coluna `origem`).
-- Chave: id_pontualidade = <origem>|<operacao ou ~>|<cliente_key> (514 + 672 + 177 = 1.363 linhas, 1.363 chaves; medido em 2026-10-19).
-- Origens (fonte supabase-x0tz, diaria): ICLIPS_CRONICO = supabase_gold_mvw_receb_cronicos_iclips (514; so titulos pagos no iClips, chave operacao x cliente_canonico) ·
--   BASE_CA = supabase_gold_vw_receb_cronicos_base (672; iClips + Conta Azul + Conexa, chave operacao x cliente_key; e um SUPERCONJUNTO: as 514 do iClips casam 514 de 514) ·
--   SCORE = supabase_public_vw_score_pontualidade (177; por cnpj_digits, sem operacao, com tier PONTUAL/REGULAR/ATRASA/CRONICO). Cadencia desta Trusted: semanal (segunda 06:45 America/Manaus).
-- Nivel: L4 PERSONAL_DATA (nome; CPF em 42 + 43 + 6 linhas; e-mail e telefone em BASE_CA, 301 e 303 linhas).
-- AS TRES ORIGENS NAO SE SOMAM: medem universos diferentes (so iClips · iClips + era atual · recorte do score). Filtrar por `origem` SEMPRE. n_pagos: 15.391 · 17.613 · 2.231.
-- DOCUMENTO: so e documento o que tem 14 (CNPJ) ou 11 (CPF) digitos; o LPAD de 13 digitos so e aceito quando o valor corrigido JA EXISTE entre os de 14 digitos das tres
--   origens (medido: 10 linhas repadronizadas, 4 em ICLIPS_CRONICO - FOGAS, RADIO TARUMA, INTELICOM, MERCANTIL NOVA ERA -, os mesmos 4 em BASE_CA e 2 no SCORE, todos com par;
--   flag_documento_repadronizado). `CA:871768534` (9 digitos, mascara pela metade, MOVE) fica sem documento (flag_documento_invalido). `CA:N:<nome>` e chave POR NOME
--   (34 linhas, todas em BASE_CA, nenhuma em ICLIPS_CRONICO; as 36 que comecam com `CA:N:` incluem os 2 baldes sem pessoa) e `VBOT:<id>` e id do Conexa (130).
-- SENTINELAS: a BASE_CA tem DUAS linhas `CA:N:` com nome vazio (operacoes distintas na chave: 283 pagos e R$ 4.391.925,11; 51 pagos e R$ 399.481,78 = 334 pagos) - sao o balde
--   dos titulos SEM pessoa, nao clientes (flag_balde_sem_pessoa); a SCORE tem uma linha com cnpj_digits vazio (vira NULL). `pior_atraso` negativo (10 linhas) e pagamento adiantado.
-- LIMITACOES - NAO CONTORNE: as metricas t0/t3/t7 sao da origem (atraso maior que 0, 3 e 7 dias) e nao sao recalculadas; `em_aberto_atual`, `vencido_aberto` e `a_vencer_aberto`
--   sao relativos a DATA DA CARGA; a SCORE nao tem operacao (um CNPJ pode estar em BRM e VD); cadencia semanal.
WITH ic AS (
  SELECT
    'ICLIPS_CRONICO' AS origem, operacao, cliente_canonico AS cliente_key, NULLIF(TRIM(cliente_nome), '') AS cliente_nome,
    NULLIF(REGEXP_REPLACE(IFNULL(documento, ''), r'[^0-9]', ''), '') AS documento_origem,
    CAST(NULL AS STRING) AS uf, CAST(NULL AS STRING) AS email, CAST(NULL AS STRING) AS telefone,
    n_pagos, n_atraso_t0, soma_dias_t0, n_atraso_t3, soma_dias_t3, n_atraso_t7, soma_dias_t7, soma_dias_geral, pior_atraso, soma_valor,
    primeiro_vencimento, ultimo_pagamento, CAST(NULL AS DATE) AS ultimo_vencimento,
    CAST(NULL AS FLOAT64) AS em_aberto_atual, CAST(NULL AS INT64) AS titulos_vencidos_abertos, CAST(NULL AS INT64) AS pagos_iclips, CAST(NULL AS INT64) AS pagos_era_atual,
    CAST(NULL AS BOOL) AS is_risco_juridico, CAST(NULL AS BOOL) AS is_historico_curto, CAST(NULL AS FLOAT64) AS vencido_aberto, CAST(NULL AS FLOAT64) AS a_vencer_aberto,
    CAST(NULL AS INT64) AS titulos_sem_vencimento, CAST(NULL AS BOOL) AS is_cliente_ativo, CAST(NULL AS STRING) AS ativo_fonte,
    CAST(NULL AS FLOAT64) AS pct_atraso, CAST(NULL AS FLOAT64) AS media_dias_atraso, CAST(NULL AS FLOAT64) AS media_geral, CAST(NULL AS INT64) AS max_atraso,
    CAST(NULL AS BOOL) AS is_cronico, CAST(NULL AS STRING) AS tier_pontualidade
  FROM `vanguardamartech_raw`.`supabase_gold_mvw_receb_cronicos_iclips`
),
ba AS (
  SELECT
    'BASE_CA' AS origem, operacao, cliente_key, NULLIF(TRIM(cliente_nome), '') AS cliente_nome,
    IF(REGEXP_CONTAINS(cliente_key, r'^CA:[0-9]+$'), SUBSTR(cliente_key, 4), NULL) AS documento_origem,
    NULLIF(TRIM(uf), '') AS uf, NULLIF(TRIM(email), '') AS email, NULLIF(TRIM(telefone), '') AS telefone,
    n_pagos, n_atraso_t0, soma_dias_t0, n_atraso_t3, soma_dias_t3, n_atraso_t7, soma_dias_t7, soma_dias_geral, pior_atraso, soma_valor,
    historico_desde AS primeiro_vencimento, CAST(NULL AS DATE) AS ultimo_pagamento, ultimo_vencimento,
    em_aberto_atual, titulos_vencidos_abertos, pagos_iclips, pagos_era_atual,
    risco_juridico AS is_risco_juridico, historico_curto AS is_historico_curto, vencido_aberto, a_vencer_aberto,
    titulos_sem_vencimento, cliente_ativo AS is_cliente_ativo, NULLIF(TRIM(ativo_fonte), '') AS ativo_fonte,
    CAST(NULL AS FLOAT64) AS pct_atraso, CAST(NULL AS FLOAT64) AS media_dias_atraso, CAST(NULL AS FLOAT64) AS media_geral, CAST(NULL AS INT64) AS max_atraso,
    CAST(NULL AS BOOL) AS is_cronico, CAST(NULL AS STRING) AS tier_pontualidade
  FROM `vanguardamartech_raw`.`supabase_gold_vw_receb_cronicos_base`
),
sc AS (
  SELECT
    'SCORE' AS origem, CAST(NULL AS STRING) AS operacao, IFNULL(NULLIF(TRIM(cnpj_digits), ''), 'SEM_DOCUMENTO') AS cliente_key, NULLIF(TRIM(cliente), '') AS cliente_nome,
    NULLIF(REGEXP_REPLACE(IFNULL(cnpj_digits, ''), r'[^0-9]', ''), '') AS documento_origem,
    CAST(NULL AS STRING) AS uf, CAST(NULL AS STRING) AS email, CAST(NULL AS STRING) AS telefone,
    tit_pagos AS n_pagos, CAST(NULL AS INT64) AS n_atraso_t0, CAST(NULL AS INT64) AS soma_dias_t0, CAST(NULL AS INT64) AS n_atraso_t3, CAST(NULL AS INT64) AS soma_dias_t3,
    CAST(NULL AS INT64) AS n_atraso_t7, CAST(NULL AS INT64) AS soma_dias_t7, CAST(NULL AS INT64) AS soma_dias_geral, CAST(NULL AS INT64) AS pior_atraso, valor_total AS soma_valor,
    CAST(NULL AS DATE) AS primeiro_vencimento, CAST(NULL AS DATE) AS ultimo_pagamento, CAST(NULL AS DATE) AS ultimo_vencimento,
    CAST(NULL AS FLOAT64) AS em_aberto_atual, CAST(NULL AS INT64) AS titulos_vencidos_abertos, CAST(NULL AS INT64) AS pagos_iclips, CAST(NULL AS INT64) AS pagos_era_atual,
    CAST(NULL AS BOOL) AS is_risco_juridico, CAST(NULL AS BOOL) AS is_historico_curto, CAST(NULL AS FLOAT64) AS vencido_aberto, CAST(NULL AS FLOAT64) AS a_vencer_aberto,
    CAST(NULL AS INT64) AS titulos_sem_vencimento, CAST(NULL AS BOOL) AS is_cliente_ativo, CAST(NULL AS STRING) AS ativo_fonte,
    pct_atraso, media_dias_atraso, media_geral, max_atraso, is_cronico, NULLIF(TRIM(tier_pontualidade), '') AS tier_pontualidade
  FROM `vanguardamartech_raw`.`supabase_public_vw_score_pontualidade`
),
uniao AS (
  SELECT * FROM ic UNION ALL SELECT * FROM ba UNION ALL SELECT * FROM sc
),
docs14 AS (
  SELECT DISTINCT documento_origem AS d FROM uniao WHERE LENGTH(documento_origem) = 14
),
final AS (
  SELECT
    CONCAT(u.origem, '|', IFNULL(u.operacao, '~'), '|', u.cliente_key)                      AS id_pontualidade,
    u.origem,
    u.operacao,
    u.cliente_key,
    u.cliente_nome,
    CASE
      WHEN LENGTH(u.documento_origem) = 13 AND d.d IS NOT NULL THEN d.d
      WHEN LENGTH(u.documento_origem) IN (11, 14) THEN u.documento_origem
    END                                                                                      AS documento,
    u.documento_origem,
    (LENGTH(u.documento_origem) = 13 AND d.d IS NOT NULL)                                    AS flag_documento_repadronizado,
    (u.documento_origem IS NOT NULL AND NOT (LENGTH(u.documento_origem) IN (11, 14) OR (LENGTH(u.documento_origem) = 13 AND d.d IS NOT NULL)))
                                                                                             AS flag_documento_invalido,
    IF(STARTS_WITH(u.cliente_key, 'CA:N:'), NULLIF(SUBSTR(u.cliente_key, 6), ''), NULL)      AS chave_por_nome,
    IF(STARTS_WITH(u.cliente_key, 'VBOT:'), SAFE_CAST(SUBSTR(u.cliente_key, 6) AS INT64), NULL) AS id_cliente_conexa,
    (u.cliente_key = 'CA:N:')                                                                AS flag_balde_sem_pessoa,
    u.uf, u.email, u.telefone,
    u.n_pagos, u.n_atraso_t0, u.soma_dias_t0, u.n_atraso_t3, u.soma_dias_t3, u.n_atraso_t7, u.soma_dias_t7, u.soma_dias_geral, u.pior_atraso, u.soma_valor,
    u.primeiro_vencimento, u.ultimo_pagamento, u.ultimo_vencimento,
    u.em_aberto_atual, u.titulos_vencidos_abertos, u.pagos_iclips, u.pagos_era_atual,
    u.is_risco_juridico, u.is_historico_curto, u.vencido_aberto, u.a_vencer_aberto, u.titulos_sem_vencimento, u.is_cliente_ativo, u.ativo_fonte,
    u.pct_atraso, u.media_dias_atraso, u.media_geral, u.max_atraso, u.is_cronico, u.tier_pontualidade
  FROM uniao u
  LEFT JOIN docs14 d ON LENGTH(u.documento_origem) = 13 AND d.d = LPAD(u.documento_origem, 14, '0')
)
SELECT
  f.*,
  (LENGTH(f.documento) = 14)         AS is_pj,
  (LENGTH(f.documento) = 11)         AS is_pf,
  'L4_PERSONAL_DATA'                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
