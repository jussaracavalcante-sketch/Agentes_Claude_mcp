-- rfn_financeiro__recebimento_pi_mensal (query-nCYr)
-- Refined / financeiro. Grao: um mes de RECEBIMENTO (data do ultimo recebimento do PI). Chave: mes_referencia.
-- Nivel: L3 CONFIDENTIAL (valor recebido por mes; nenhum PI nem cliente atravessa).
--
-- LE: trs_pi__recebimento (1.696 PIs, query-d8ZT).
-- VALIDACAO (18/10/2026, reproduzindo a Trusted sobre a Raw e a trs_pi__insercao, ja materializada): 19 linhas,
-- soma de qtd_pis 1.696 = total da Trusted; qtd_parcelas 2.329; valor_recebido R$ 5.956.386,00; 44 PIs cancelados
-- (R$ 72.435,00); 148 PIs nao catalogados (R$ 601.591,00); 75 com data diferente da do PI; meses 2024-12 a 2026-06.
--
-- REGRAS: (R1) o mes e o da data do ULTIMO recebimento do PI: um PI parcelado cai inteiro no mes do ultimo
-- recebimento, nao e fluxo por parcela. (R2) PI cancelado e PI nao catalogado ficam em colunas proprias e CONTAM em
-- valor_recebido; para o recebido de PI vivo e catalogado, subtrair as duas (podem se sobrepor: nao ha PI cancelado
-- nao catalogado, pois o cancelamento vem do cadastro).
-- LIMITACAO -- NAO CONTORNE: NAO e fluxo de caixa mensal (PI parcelado concentra no ultimo mes) e nao soma com
-- rfn_financeiro__fluxo_caixa nem com o razao do iClips. Cobre so ate 2026-06.
SELECT
  DATE_TRUNC(t.recebido_em, MONTH)                            AS mes_referencia,
  COUNT(*)                                                    AS qtd_pis,
  SUM(t.qtd_parcelas)                                         AS qtd_parcelas,
  SUM(t.valor_recebido)                                       AS valor_recebido,
  COUNTIF(t.flag_pi_cancelado)                                AS qtd_pis_cancelados,
  SUM(IF(t.flag_pi_cancelado, t.valor_recebido, 0))           AS valor_pis_cancelados,
  COUNTIF(t.flag_pi_nao_catalogado)                           AS qtd_pis_nao_catalogados,
  SUM(IF(t.flag_pi_nao_catalogado, t.valor_recebido, 0))      AS valor_pis_nao_catalogados,
  COUNTIF(t.flag_data_diverge_do_pi)                          AS qtd_data_diverge,
  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  'supabase-x0tz'                                             AS _fonte,
  'America/Sao_Paulo'                                         AS _fuso,
  TO_HEX(MD5(CAST(DATE_TRUNC(t.recebido_em, MONTH) AS STRING))) AS _payload_hash
FROM `vanguardamartech_trusted`.`trs_pi__recebimento` t
GROUP BY 1
