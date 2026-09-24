-- trs_vjob__checklist_diario  ·  query-OFX4  ·  2.748 linhas  ·  L2 INTERNAL
-- Trusted / VJOB. Grao: um item de checklist diario de uma conta num dia. Chave: id_check.
-- Origem: checklist_diario (2.748) + tbchecklist (34). Gatilho: evento em query-8JWf.
--
-- AQUI A CONCLUSAO SEMPRE DATA A ACAO: 2.748 de 2.748 com carimbo, zero marcadas sem.
--   33 linhas tem carimbo e status zero (marcado e desmarcado).
-- MODULO PARADO: janela 30/04/2025 a 04/02/2026.
-- SO 8 DAS 34 ATIVIDADES DO CATALOGO FORAM USADAS. Zero orfaos.
-- O cliente e a CONTA DE ATENDIMENTO: 5 orfaos, contra 214 se fosse tbclientes.
WITH c AS (SELECT * FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_checklist_diario`),
dim AS (
  SELECT id, NULLIF(TRIM(atividade), '') AS atividade, fase
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbchecklist`
),
atd AS (SELECT DISTINCT id_atendimento FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`),
u AS (SELECT DISTINCT id_usuario FROM `vanguardamartech_trusted`.`trs_vjob__usuario`),
prep AS (
  SELECT
    c.id                    AS id_check,
    NULLIF(c.id_cliente, 0) AS id_atendimento,
    c.id_tarefa             AS id_atividade,
    c.data                  AS dt_previsto,
    (c.status = 1)          AS is_marcado,
    c.data_check            AS marcado_em,
    NULLIF(c.quem_check, 0) AS marcado_por
  FROM c
),
tratado AS (
  SELECT
    p.*,
    d.atividade                                              AS nome_atividade,
    d.fase                                                   AS fase,
    (p.is_marcado AND p.marcado_em IS NULL)                  AS flag_marcado_sem_carimbo,
    (NOT p.is_marcado AND p.marcado_em IS NOT NULL)          AS flag_carimbo_sem_status,
    (d.id IS NULL)                                           AS flag_atividade_nao_catalogada,
    (a.id_atendimento IS NULL)                               AS flag_conta_nao_catalogada,
    (p.marcado_por IS NOT NULL AND u.id_usuario IS NULL)     AS flag_usuario_nao_catalogado
  FROM prep p
  LEFT JOIN dim d ON d.id = p.id_atividade
  LEFT JOIN atd a ON a.id_atendimento = p.id_atendimento
  LEFT JOIN u   ON u.id_usuario = p.marcado_por
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
