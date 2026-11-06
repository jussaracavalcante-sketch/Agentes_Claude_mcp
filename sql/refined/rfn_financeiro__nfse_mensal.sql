-- rfn_financeiro__nfse_mensal (query-cUo0)
-- Refined / financeiro. Grao: um mes de EMISSAO x status da NFS-e. Chave: (mes_referencia, status).
-- Nivel: L3 CONFIDENTIAL (valor faturado por nota; tomador e numero da nota NAO atravessam, so contagem).
--
-- LE: trs_iclips__nfse (1.323 notas, query-ney7).
-- VALIDACAO (18/10/2026, reproduzindo a Trusted sobre a Raw, que ainda nao materializou): 12 linhas (6 meses x 2 status),
-- soma de qtd_notas 1.323 = total da Trusted; valor_vigente R$ 5.603.000,47 = soma de valor das emitidas; valor total
-- R$ 6.267.952,08 (inclui canceladas); 532 notas com PI, 16 de tomador pessoa fisica, zero numero repetido; meses 2025-12 a 2026-05.
--
-- REGRAS: (R1) mes pela data de emissao em America/Sao_Paulo (DATETIME, sem segunda conversao). (R2) valor_vigente so
-- soma nota emitida (status 'issued'); nota cancelada fica em valor_total, nunca em valor_vigente. (R3) status e o da
-- origem, em ingles.
-- LIMITACAO -- NAO CONTORNE: e a nota fiscal de SERVICO da agencia no iClips, nao receita reconhecida nem caixa; nao soma
-- com trs_financeiro__movimento nem com o Conta Azul. A serie cobre so 2025-12 a 2026-05 (o iClips para de emitir na
-- virada do ERP). So 532 de 1.323 notas ligam a um PI.
-- Correcao 18/10/2026: a agregacao foi para a CTE g e o _payload_hash passou a ler mes_referencia e status ja agrupados.
-- A versao anterior referenciava t.emitida_em dentro do hash com GROUP BY por ordinal e o BigQuery recusava
-- ("neither grouped nor aggregated"); falhou nas duas primeiras execucoes. Validado antes do deploy: 12 linhas,
-- 12 chaves, 1.323 notas, vigente 5.603.000,47, total 6.267.952,08 (os mesmos numeros da descricao).
WITH g AS (
SELECT
  DATE_TRUNC(CAST(t.emitida_em AS DATE), MONTH)               AS mes_referencia,
  IFNULL(t.status, '(sem status)')                            AS status,
  COUNT(*)                                                    AS qtd_notas,
  SUM(t.valor)                                                AS valor_total,
  SUM(t.valor_vigente)                                        AS valor_vigente,
  COUNTIF(t.tem_pi)                                           AS qtd_com_pi,
  COUNTIF(t.tomador_is_pf)                                    AS qtd_tomador_pf,
  COUNTIF(t.flag_numero_repetido)                             AS qtd_numero_repetido
FROM `vanguardamartech_trusted`.`trs_iclips__nfse` t
GROUP BY 1, 2
)
SELECT
  g.*,
  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  'supabase-x0tz'                                             AS _fonte,
  'America/Sao_Paulo'                                         AS _fuso,
  TO_HEX(MD5(CONCAT(CAST(g.mes_referencia AS STRING), g.status))) AS _payload_hash
FROM g
