-- rfn_rh__desligamento_mensal (query-I2PH)
-- Refined / rh. Grao: um mes de DESLIGAMENTO x tipo de desligamento. Chave: (mes_referencia, tipo_desligamento).
-- Nivel: L3 CONFIDENTIAL (so contagem por mes e tipo; nome, e-mail, cargo, area, salario e motivo NAO atravessam).
--
-- LE: trs_qulture__colaborador (317 cadastros, query-GiqT).
-- VALIDACAO (18/10/2026, reproduzindo a Trusted sobre a Raw, que ainda nao materializou): 30 linhas; soma de
-- qtd_desligados 191; 192 cadastros da planilha tem data de inativacao e 1 deles e linha que nao e pessoa (flag_nao_pessoa),
-- excluida; meses 2024-10 a 2026-08; maior celula 29.
--
-- REGRAS: (R1) desligamento = cadastro com data de inativacao (inativado_em, DATE, sem conversao de fuso) e que seja pessoa.
-- (R2) tipo sem valor vira '(sem tipo)'. (R3) so a planilha de RH do Qulture tem data de inativacao: cadastro que existe
-- so na API nao entra.
-- LIMITACAO -- NAO CONTORNE: NAO e taxa de turnover. Nao ha data de admissao na base (qulture_criado_em e criacao do
-- registro, nao admissao), logo nao ha quadro de pessoas no inicio ou fim de cada mes para dividir. Isto responde
-- QUANTOS sairam e de que tipo, nao QUAL percentual. Sem agrupar por area ou cargo de proposito: grupos de uma ou duas
-- pessoas reidentificam o colaborador (a Trusted e L4).
SELECT
  DATE_TRUNC(t.inativado_em, MONTH)                           AS mes_referencia,
  IFNULL(t.tipo_desligamento, '(sem tipo)')                   AS tipo_desligamento,
  COUNT(*)                                                    AS qtd_desligados,
  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  'supabase-x0tz'                                             AS _fonte,
  'America/Sao_Paulo'                                         AS _fuso,
  TO_HEX(MD5(CONCAT(CAST(DATE_TRUNC(t.inativado_em, MONTH) AS STRING), IFNULL(t.tipo_desligamento, '')))) AS _payload_hash
FROM `vanguardamartech_trusted`.`trs_qulture__colaborador` t
WHERE t.inativado_em IS NOT NULL
  AND NOT IFNULL(t.flag_nao_pessoa, FALSE)
GROUP BY 1, 2
