-- trs_financeiro__cliente_risco (query-ZNA3)
-- Trusted / Financeiro. Grao: um CLIENTE sinalizado como risco de recebimento. Chave: documento (14 ou 11 digitos).
-- Nivel: L3 CONFIDENTIAL (classificacao de inadimplencia por cliente; documento pode ser CPF).
--
-- ORIGEM. supabase_public_dim_cliente_risco (14 linhas), da supabase-x0tz, cadastro mantido a mao (observacao livre).
-- Medido em 18/10/2026: 14 linhas, 14 chaves, documento de 11 ou 14 digitos em 14 de 14; classificacao
-- recuperacao_especial 5 (contrato encerrado por inadimplencia, devedor conhecido; grupos WD/CIESA e GRUPO KING) e
-- pagador_cronico 9 (com score de atraso: 9 de 9 tem score_atualizado_em). As 14 existem como contraparte em
-- trs_financeiro__movimento (14 de 14).
--
-- ESTA E UMA CLASSIFICACAO HUMANA, nao medida: o score de pagador cronico (media de dias de atraso e % de atraso em
-- 6 meses, titulos pagos em 6 meses) e do derivado e vale como foi calculado na data score_atualizado_em; nao e
-- recalculado aqui.
--
-- LIMITACAO -- NAO CONTORNE: lista curta e curada, nao e a carteira inadimplente: inadimplencia mede-se por titulo em
-- rfn_financeiro__fluxo_caixa (BRM e VD) e rfn_financeiro__inadimplencia_vbot (VBOT). Ausencia aqui nao e bom pagador.
SELECT
  IF(LENGTH(r.cnpj_digits) IN (11, 14), r.cnpj_digits, NULL)       AS documento,
  r.cnpj_digits                                                    AS documento_origem,
  (LENGTH(r.cnpj_digits) = 11)                                     AS is_pf,
  NULLIF(TRIM(r.razao_social), '')                                 AS razao_social,
  NULLIF(TRIM(r.grupo), '')                                        AS grupo,
  NULLIF(TRIM(r.classificacao), '')                                AS classificacao,
  r.contrato_encerrado                                             AS is_contrato_encerrado,
  r.expectativa_recuperacao                                        AS tem_expectativa_recuperacao,
  r.pagador_cronico                                                AS is_pagador_cronico,
  r.media_dias_atraso_6m,
  r.pct_atraso_6m,
  r.tit_pagos_6m                                                   AS titulos_pagos_6m,
  r.score_atualizado_em                                            AS score_atualizado_em,
  NULLIF(TRIM(r.observacao), '')                                   AS observacao,
  DATE(r.created_at, 'America/Sao_Paulo')                          AS cadastrado_em,
  (r.pagador_cronico AND r.score_atualizado_em IS NULL)            AS flag_cronico_sem_score,
  CURRENT_TIMESTAMP()                                              AS _extraido_at,
  'supabase-x0tz'                                                  AS _fonte,
  'America/Sao_Paulo'                                              AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(r)))                                   AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_public_dim_cliente_risco` r
