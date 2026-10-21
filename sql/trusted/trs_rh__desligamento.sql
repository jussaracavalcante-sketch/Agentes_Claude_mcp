-- trs_rh__desligamento
-- Trusted / RH. Grao: uma pessoa no relatorio de desligamento (RH formal) ou detectada como inativa no Qulture. Chave: email (300 distintos em 300 linhas,
-- 183 com data de desligamento, medido em 2026-10-18). Origem: vanguardamartech_raw.supabase_gold_vw_people_desligamento (fonte supabase-x0tz).
-- Nivel: L4 PERSONAL_DATA (nome, e-mail, motivo, custo por pessoa). vw_people_cross_desligamento (198) e a conferencia entre a data formal e a deteccao no
-- Qulture: nao foi tratada (derivada).
-- origem = RELATORIO (relatorio do RH) ou DETECCAO (inativacao detectada no Qulture, sem relatorio): a deteccao nao prova data formal.
-- situacao da origem preservada (DESLIGADO, ATIVO, ATIVO_INCONSISTENTE, AVISO_PREVIO). data_desligamento NULL em 117 linhas (quem ainda esta ativo ou em aviso).
-- tempo_casa_meses e faixa_casa vem da origem; custo_tt e preservado cru (a origem nao documenta a unidade: nao somar sem descobrir).
SELECT
  email,
  NULLIF(TRIM(nome), '')                         AS nome,
  NULLIF(TRIM(cargo), '')                        AS cargo,
  NULLIF(TRIM(nivel), '')                        AS nivel,
  NULLIF(TRIM(departamento), '')                 AS departamento,
  NULLIF(TRIM(area), '')                         AS area,
  NULLIF(TRIM(gestor), '')                       AS gestor,
  data_admissao,
  data_desligamento,
  tempo_casa_meses,
  ativo_rel                                      AS is_ativo_rel,
  NULLIF(TRIM(situacao), '')                     AS situacao,
  NULLIF(TRIM(tipo_desligamento), '')            AS tipo_desligamento,
  NULLIF(TRIM(motivo_codigo), '')                AS motivo_codigo,
  NULLIF(TRIM(motivo), '')                       AS motivo,
  motivo_ordem,
  custo_tt,
  NULLIF(TRIM(origem), '')                       AS origem,
  NULLIF(TRIM(faixa_casa), '')                   AS faixa_casa,
  (data_desligamento IS NOT NULL)                AS is_desligado_com_data,
  (data_admissao IS NULL)                        AS flag_sem_admissao,
  'L4_PERSONAL_DATA'                             AS classificacao_dado,
  CURRENT_TIMESTAMP()                            AS _extraido_at,
  'supabase-x0tz'                                AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(d)))                 AS _payload_hash
FROM vanguardamartech_raw.supabase_gold_vw_people_desligamento d
