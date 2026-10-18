-- trs_iclips__nfse
-- Trusted / iClips (financeiro). Grao: uma NFS-e emitida pelo iClips. Chave: id_nfse.
-- Nivel: L3 CONFIDENTIAL (valor faturado por documento de cliente; documento em digitos, inclui CPF de PF).
--
-- ORIGEM. supabase_silver_iclips_nfse (1.323), da supabase-x0tz, tipada. bronze_iclips__financeiro_nfse tem
-- 2.646 linhas para as mesmas 1.323 chaves (2 versoes por NFS-e) e nao foi usado.
-- Medido em 18/10/2026: 1.323 linhas, 1.323 chaves (id_nfse); status issued 1.231 e cancelled 92; emitidas de
-- 08/12/2025 a 27/05/2026; valor emitido (issued) R$ 5.603.000,47; documento de 11 ou 14 digitos em 1.323 de 1.323;
-- 532 ligadas a um PI (pi preenchido), 791 sem PI; numero distinto em 1.322 e 1 NFS-e sem numero (zero numero repetido: flag_numero_repetido = 0 em todas); 16 tomadores PF.
--
-- FUSO. emissao e instante UTC real (1.313 de 1.323 com hora diferente de 00:00): DATETIME(emissao,'America/Sao_Paulo').
-- competencia e DATE (sem fuso).
--
-- CANCELADA NAO E RECEITA: somar valor sem filtrar status inclui as 92 canceladas. valor_vigente = valor so quando
-- status = 'issued'; NULL (nunca zero) nas canceladas.
--
-- LIMITACAO -- NAO CONTORNE: a NFS-e nao e o recebimento: o caixa esta em trs_extrato__lancamento e o razao em
-- trs_financeiro__movimento. 90% dos numeros (1.193 de 1.323) tambem aparecem em trs_financeiro__movimento.num_documento:
-- somar as duas fontes duplica. O periodo cobre so dez/2025 a mai/2026 (o stream de emissao nao traz NFS-e anterior).
SELECT
  CAST(n.id_nfse AS STRING)                                        AS id_nfse,
  CAST(n.numero AS STRING)                                         AS numero_nfse,
  NULLIF(TRIM(n.status), '')                                       AS status,
  (n.status = 'issued')                                            AS is_emitida,
  DATETIME(n.emissao, 'America/Sao_Paulo')                         AS emitida_em,
  n.competencia,
  n.valor,
  IF(n.status = 'issued', n.valor, NULL)                           AS valor_vigente,
  CAST(n.pi AS STRING)                                             AS id_pi,
  (n.pi IS NOT NULL)                                               AS tem_pi,
  IF(LENGTH(REGEXP_REPLACE(IFNULL(n.documento, ''), r'\D', '')) IN (11, 14), REGEXP_REPLACE(n.documento, r'\D', ''), NULL) AS documento_tomador,
  (LENGTH(REGEXP_REPLACE(IFNULL(n.documento, ''), r'\D', '')) = 11) AS tomador_is_pf,
  (COUNT(*) OVER (PARTITION BY n.numero) > 1)                      AS flag_numero_repetido,
  CURRENT_TIMESTAMP()                                              AS _extraido_at,
  'supabase-x0tz'                                                  AS _fonte,
  'America/Sao_Paulo'                                              AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(n)))                                   AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_silver_iclips_nfse` n
