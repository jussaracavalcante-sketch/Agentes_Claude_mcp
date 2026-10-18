-- trs_quickin__candidato
-- Trusted / Recrutamento (Quickin). Grao: um CANDIDATO. Chave: id_candidato. Nivel: L4 PERSONAL_DATA
-- (nome, e-mail, data de nascimento, indicio de telefone). NAO atravessa nominal para a Refined.
--
-- ORIGEM. supabase_silver_candidato (3.206), da supabase-x0tz. bronze_quickin__candidates tem 3.767 linhas
-- (log de versoes) para as mesmas chaves e nao foi usado. Medido em 18/10/2026: 3.206 linhas, 3.206 chaves.
--
-- LGPD -- O ACHADO QUE MANDA: gdpr_consent_status = 'needs' em 3.202 de 3.206 (99,9%); consented 1, expired 1,
-- declined 2. A base guarda dado pessoal de 3.206 candidatos e so 1 tem consentimento registrado. Nao e
-- defeito da Trusted, e o que a origem diz. consentimento_status passa como veio; nao filtrar por ele para
-- 'limpar' a base sem decisao do RH.
--
-- FUSO. created_at, quickin_updated_at e gdpr_consent_updated sao instantes UTC reais (medido: a criacao de
-- candidato tem vale as 7-9h UTC, 3-5h da manha em Manaus, e pico das 14-21h UTC): DATETIME(ts,'America/Sao_Paulo').
--
-- CAMPOS MORTOS NAO EMITIDOS (zero preenchimento em 3.206): cpf, gender, origin, source_id, country, zipcode,
-- salary, position_category, experience_level, experiences, educations, avg_rating_intervideo,
-- avg_rating_questionnaire. Emitidos como NULL convidariam a contar zero onde o certo e ausencia.
-- headline (3.180 preenchidos) e summary (2.433) sao texto livre do candidato e ficam FORA (minimizacao): so
-- as flags tem_resumo e tem_headline.
--
-- DEFEITOS MARCADOS, NAO CORRIGIDOS: flag_nascimento_implausivel (nascimento antes de 1930 ou idade < 14 anos:
-- 3 + 15 medidos), flag_email_repetido (123 e-mails repetidos, 245 candidatos marcados: a mesma pessoa
-- candidata-se de novo e a plataforma cria outro id; nome nao e chave, e-mail tambem nao junta quem nao tem).
--
-- LIMITACAO -- NAO CONTORNE: telefone nao e emitido (so qtd_telefones); a base nao carrega CPF, entao nao ha
-- ponte por documento com o cadastro de colaboradores.
SELECT
  c.quickin_candidato_id                                      AS id_candidato,
  NULLIF(TRIM(c.name), '')                                    AS nome,
  NULLIF(LOWER(TRIM(c.email)), '')                            AS email,
  c.birth_date                                                AS data_nascimento,
  (c.birth_date < DATE '1930-01-01'
     OR c.birth_date > DATE_SUB(CURRENT_DATE('America/Sao_Paulo'), INTERVAL 14 YEAR)) AS flag_nascimento_implausivel,
  NULLIF(TRIM(c.city), '')                                    AS cidade,
  NULLIF(TRIM(c.region), '')                                  AS uf,
  NULLIF(TRIM(c.neighborhood), '')                            AS bairro,
  IFNULL(ARRAY_LENGTH(JSON_QUERY_ARRAY(c.phones)), 0)         AS qtd_telefones,
  (NULLIF(TRIM(c.headline), '') IS NOT NULL)                  AS tem_headline,
  (NULLIF(TRIM(c.summary), '') IS NOT NULL)                   AS tem_resumo,
  c.avg_rating_evaluation                                     AS nota_media_avaliacao,
  NULLIF(TRIM(c.gdpr_consent_status), '')                     AS consentimento_status,
  DATETIME(c.gdpr_consent_updated, 'America/Sao_Paulo')       AS consentimento_atualizado_em,
  IFNULL(ARRAY_LENGTH(JSON_QUERY_ARRAY(c.tags)), 0)           AS qtd_tags,
  (COUNT(*) OVER (PARTITION BY LOWER(TRIM(c.email))) > 1 AND NULLIF(TRIM(c.email), '') IS NOT NULL) AS flag_email_repetido,
  DATETIME(c.created_at, 'America/Sao_Paulo')                 AS criado_em,
  DATETIME(c.quickin_updated_at, 'America/Sao_Paulo')         AS atualizado_na_origem_em,
  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  'supabase-x0tz'                                             AS _fonte,
  'America/Sao_Paulo'                                         AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(c)))                              AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_silver_candidato` c
