-- trs_quickin__aplicacao
-- Trusted / Recrutamento (Quickin). Grao: uma APLICACAO (candidato x vaga). Chave: id_aplicacao.
-- Nivel: L3 CONFIDENTIAL (resultado de selecao ligado a candidato identificavel por id; sem nome nem contato aqui).
--
-- ORIGEM. supabase_silver_aplicacao (4.013) + supabase_silver_decisao (4.013, 1:1) + supabase_silver_avaliacao
-- (64, agregada) + supabase_silver_etapa_funil (nomes de etapa). Medido em 18/10/2026: 4.013 aplicacoes,
-- 4.013 chaves, 4.013 candidatos e 4.013 vagas resolvem (zero orfao), decisao casa 4.013 de 4.013.
--
-- DECISAO. resultado: contratado 150, reprovado 1.282, em_andamento 2.581. is_contratado concorda com
-- decisao.hired em 150 de 150; flag_hired_diverge marca qualquer divergencia futura entre as duas leituras.
-- reprovado 1.282 contra 1.284 com motivo de desqualificacao: 2 aplicacoes tem motivo e nao estao reprovadas
-- (marcado em flag_motivo_sem_reprovacao, nao corrigido).
--
-- FUSO. stage_date, hired_date, decided_at e quickin_updated_at sao instantes UTC reais (API Quickin):
-- DATETIME(ts,'America/Sao_Paulo'). Medido na criacao de candidatos: vale as 7-9h UTC.
--
-- team_users e array de ids de usuarios (com repeticao): so a contagem de distintos e emitida.
--
-- LIMITACAO -- NAO CONTORNE: em_andamento (2.581, 64%) NAO e funil vivo: 212 das 217 vagas estao arquivadas,
-- entao a maior parte dessas aplicacoes ficou parada numa etapa quando a vaga foi encerrada. Taxa de
-- contratacao honesta divide por aplicacoes DECIDIDAS (contratado + reprovado = 1.432), nao pelo total.
-- Nao existe nome do motivo de desqualificacao nesta base, so o id.
WITH av AS (
  SELECT aplicacao_id, COUNT(*) qtd, AVG(nota_media) nota
  FROM `vanguardamartech_raw`.`supabase_silver_avaliacao` GROUP BY aplicacao_id
),
et AS (
  SELECT quickin_etapa_id, name, type FROM `vanguardamartech_raw`.`supabase_silver_etapa_funil`
)
SELECT
  a.quickin_aplicacao_id                                      AS id_aplicacao,
  a.candidato_id                                              AS id_candidato,
  a.job_id                                                    AS id_vaga,
  a.stage_id                                                  AS id_etapa,
  COALESCE(NULLIF(TRIM(a.stage_nome), ''), e.name)            AS etapa,
  e.type                                                      AS tipo_etapa,
  DATETIME(a.stage_date, 'America/Sao_Paulo')                 AS etapa_desde,
  NULLIF(TRIM(a.status), '')                                  AS status,
  a.is_new                                                    AS is_nova,
  a.hired                                                     AS is_contratado,
  DATETIME(a.hired_date, 'America/Sao_Paulo')                 AS contratado_em,
  NULLIF(TRIM(d.resultado), '')                               AS resultado,
  DATETIME(d.decided_at, 'America/Sao_Paulo')                 AS decidido_em,
  d.disqualify_reason_id                                      AS id_motivo_desqualificacao,
  a.confidential                                              AS is_confidencial,
  (SELECT COUNT(DISTINCT u) FROM UNNEST(JSON_VALUE_ARRAY(a.team_users)) u) AS qtd_membros_time,
  IFNULL(v.qtd, 0)                                            AS qtd_avaliacoes,
  v.nota                                                      AS nota_media_avaliacoes,
  (a.hired IS DISTINCT FROM d.hired)                          AS flag_hired_diverge,
  (d.disqualify_reason_id IS NOT NULL AND d.resultado <> 'reprovado') AS flag_motivo_sem_reprovacao,
  DATETIME(a.quickin_updated_at, 'America/Sao_Paulo')         AS atualizado_na_origem_em,
  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  'supabase-x0tz'                                             AS _fonte,
  'America/Sao_Paulo'                                         AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                              AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_silver_aplicacao` a
LEFT JOIN `vanguardamartech_raw`.`supabase_silver_decisao` d ON d.aplicacao_id = a.quickin_aplicacao_id
LEFT JOIN av v ON v.aplicacao_id = a.quickin_aplicacao_id
LEFT JOIN et e ON e.quickin_etapa_id = a.stage_id
