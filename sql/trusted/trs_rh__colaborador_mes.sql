-- trs_rh__colaborador_mes
-- Trusted / RH. Grao: uma pessoa (pessoa_id) em um mes (mes_ref) com tres evidencias lado a lado: situacao no RH (Qulture), lancamento financeiro
-- (folha/freelancer no financeiro) e apontamento de atividade (iClips). 4.265 linhas, 4.265 chaves (pessoa_id, mes_ref), 293 pessoas, 2024-01 a 2026-10
-- (medido em 2026-10-18). Origem: vanguardamartech_raw.supabase_gold_vw_colaborador_conferencia_mes (fonte supabase-x0tz); vw_colaborador_evidencia_mes e a
-- mesma tabela sem a coluna `status` (4.265 linhas): nao foi tratada.
-- Nivel: L4 PERSONAL_DATA — nome, situacao contratual e REMUNERACAO INDIVIDUAL (fin_valor por pessoa e mes). NAO publicar em painel sem decisao de acesso.
-- `status` e a conferencia do Supabase (OK 2.550, RH_ATV_SEM_PGTO 624, SO_RH 605, ATV_SEM_RH 216, FIN_ANTES_ADMISSAO 138, FIN_POS_SAIDA_TOLERADO 121,
--   FIN_POS_SAIDA_DIVERGE 11) e sai CRU: a regra que o produz nao esta nesta casa.
-- Datas de admissao e desligamento sao constantes por pessoa (0 pessoas com valor diferente entre meses); admissao nula em 20 das 293 pessoas.
-- fin_valor e ASSINADO como no financeiro (pagamento = negativo). Zero de atividade ou de lancamento NAO e ausencia de trabalho: so ha linha-mes onde alguma evidencia existiu.
SELECT
  CONCAT(CAST(pessoa_id AS STRING), '|', CAST(mes_ref AS STRING))   AS id_pessoa_mes,
  CAST(pessoa_id AS STRING)                                         AS id_pessoa,
  NULLIF(TRIM(nome_canonico), '')                                   AS nome,
  mes_ref                                                           AS mes_referencia,
  rh_ativo                                                          AS is_rh_ativo,
  NULLIF(TRIM(rh_situacao_atual), '')                               AS rh_situacao_atual,
  NULLIF(TRIM(rh_tipo_contrato_atual), '')                          AS rh_tipo_contrato_atual,
  NULLIF(TRIM(rh_cargo_atual), '')                                  AS rh_cargo_atual,
  NULLIF(TRIM(rh_setor_atual), '')                                  AS rh_setor_atual,
  NULLIF(TRIM(rh_house_atual), '')                                  AS rh_house_atual,
  data_admissao,
  data_desligamento_efetiva                                         AS data_desligamento,
  fin_valor,
  fin_lancamentos,
  NULLIF(TRIM(fin_subcategoria_dominante), '')                      AS fin_subcategoria_dominante,
  NULLIF(TRIM(fin_cc_setor), '')                                    AS fin_cc_setor,
  atv_min,
  atv_apontamentos,
  NULLIF(TRIM(atv_departamento), '')                                AS atv_departamento,
  NULLIF(TRIM(status), '')                                          AS status_conferencia,
  (data_admissao IS NULL)                                           AS flag_sem_admissao,
  (data_desligamento_efetiva IS NOT NULL)                           AS is_desligado,
  'L4_PERSONAL_DATA'                                                AS classificacao_dado,
  CURRENT_TIMESTAMP()                                               AS _extraido_at,
  'supabase-x0tz'                                                   AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(c)))                                    AS _payload_hash
FROM vanguardamartech_raw.supabase_gold_vw_colaborador_conferencia_mes c
