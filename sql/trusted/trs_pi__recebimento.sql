-- trs_pi__recebimento (query-d8ZT)
-- Trusted / PI. Grao: um PI (insercao) com recebimento registrado no iClips. Chave: id_pi.
-- Nivel: L3 CONFIDENTIAL (valor recebido por PI/cliente).
--
-- ORIGEM. supabase_silver_iclips_fin_recebimento (1.696 linhas), da supabase-x0tz. Medido em 18/10/2026:
-- 1.696 linhas, 1.696 PIs distintos, 2.329 parcelas, R$ 5.956.386,00 recebidos, zero valor <= 0 ou NULL,
-- recebimento de 2024-12-31 a 2026-06-23. 1.548 dos 1.696 PIs existem em trs_pi__insercao (148 nao: PI fora do
-- silver de PI, flag_pi_nao_catalogado) e 44 dos catalogados estao cancelados (flag_pi_cancelado).
--
-- O QUE ESTA TABELA TRAZ E A trs_pi__insercao NAO TEM: o VALOR recebido e o numero de parcelas. A trs_pi__insercao so
-- carrega a data (recebimento_em), que concorda com recebido_em em 1.473 dos 1.548 casados. valor_recebido nunca e
-- igual a valor_faturado_cliente nem a valor_negociado (medido: zero) -- e o caixa do iClips, nao o faturado.
--
-- LIMITACAO -- NAO CONTORNE: recebido_em e a data do ULTIMO recebimento do PI (um PI parcelado tem uma linha so);
-- o valor e a soma das parcelas. NAO e razao financeiro: nao soma com trs_financeiro__movimento nem com o Conta Azul
-- (mesmo dinheiro visto duas vezes). Cobre so PI recebido ate 2026-06 (o iClips deixou de registrar na virada do ERP).
SELECT
  CAST(r.pi AS STRING)                                             AS id_pi,
  SAFE_CAST(CAST(r.recebido_em AS STRING) AS DATE)                 AS recebido_em,
  r.n_parcelas                                                     AS qtd_parcelas,
  CAST(r.valor_recebido AS NUMERIC)                                AS valor_recebido,
  (p.id_pi IS NOT NULL)                                            AS tem_pi_catalogado,
  (p.id_pi IS NULL)                                                AS flag_pi_nao_catalogado,
  IFNULL(p.is_cancelado, FALSE)                                    AS flag_pi_cancelado,
  p.recebimento_em                                                 AS recebimento_em_do_pi,
  (p.id_pi IS NOT NULL AND SAFE_CAST(CAST(r.recebido_em AS STRING) AS DATE) IS DISTINCT FROM p.recebimento_em) AS flag_data_diverge_do_pi,
  p.cliente_cnpj                                                   AS cliente_cnpj,
  CURRENT_TIMESTAMP()                                              AS _extraido_at,
  'supabase-x0tz'                                                  AS _fonte,
  'America/Sao_Paulo'                                              AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(r)))                                   AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_silver_iclips_fin_recebimento` r
LEFT JOIN `vanguardamartech_trusted`.`trs_pi__insercao` p ON p.id_pi = CAST(r.pi AS STRING)
