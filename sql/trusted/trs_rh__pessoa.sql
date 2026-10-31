-- trs_rh__pessoa
-- Trusted / RH. Grao: uma pessoa cadastrada no Qulture (plataforma de gestao de pessoas), com estrutura organizacional e engajamento.
-- Chave: email (165 distintos em 165 linhas, 120 ativos, medido em 2026-10-18). Junta vw_people_base (estrutura) e qulture_engajamento_colaborador
-- (feedbacks, elogios, PDIs e reunioes 1:1, 165 linhas, 165 e-mails). gold_people_analytics e gold_headcount_organograma sao subconjuntos de colunas de
-- vw_people_base (mesmas 165 linhas): nao foram tratadas. Nivel: L4 PERSONAL_DATA (nome, e-mail, cargo, gestor).
-- O Qulture NAO e o RH formal: a admissao e o desligamento formais estao em trs_rh__colaborador_mes e trs_rh__desligamento. Aqui `is_ativo` e o do Qulture.
-- `equipes` (array) nao e emitido; so qtd_equipes. Engajamento zero NAO e engajamento nulo: a pessoa pode nao ter usado o modulo.
SELECT
  b.email,
  NULLIF(TRIM(b.nome), '')                    AS nome,
  b.ativo                                     AS is_ativo,
  NULLIF(TRIM(b.cargo), '')                   AS cargo,
  NULLIF(TRIM(b.nivel), '')                   AS nivel,
  NULLIF(TRIM(b.gestor), '')                  AS gestor,
  b.qtd_equipes,
  b.email_corporativo                         AS is_email_corporativo,
  b.qulture_created_at,
  NULLIF(TRIM(b.area), '')                    AS area,
  NULLIF(TRIM(b.diretoria), '')               AS diretoria,
  NULLIF(TRIM(b.departamento), '')            AS departamento,
  NULLIF(TRIM(b.setor), '')                   AS setor,
  NULLIF(TRIM(b.faixa_casa), '')              AS faixa_casa,
  e.contract_id                               AS qulture_contract_id,
  e.feedbacks_dados,
  e.feedbacks_recebidos,
  e.elogios_dados,
  e.elogios_recebidos,
  e.pdis,
  e.reunioes_1a1,
  (e.email IS NOT NULL)                       AS tem_engajamento,
  'L4_PERSONAL_DATA'                          AS classificacao_dado,
  CURRENT_TIMESTAMP()                         AS _extraido_at,
  'supabase-x0tz'                             AS _fonte,
  TO_HEX(MD5(CONCAT(IFNULL(TO_JSON_STRING(b), ''), '|', IFNULL(TO_JSON_STRING(e), '')))) AS _payload_hash
FROM vanguardamartech_raw.supabase_gold_vw_people_base b
LEFT JOIN vanguardamartech_raw.supabase_gold_qulture_engajamento_colaborador e ON e.email = b.email
