-- trs_qulture__colaborador
-- Trusted / RH (Qulture). Grao: um colaborador. Chave: email_chave (e-mail minusculo, sem espaco).
-- Nivel: L4 PERSONAL_DATA (salario, comissao, custo total, beneficios, motivo e tipo de desligamento,
-- sexo, formacao). NAO atravessa para a Refined: ela agrega e nunca emite nome nem valor individual.
--
-- ORIGEM. Duas leituras do mesmo sistema, ambas ja tipadas na supabase-x0tz:
--   supabase_silver_colaborador_rel  (307) planilha de colaboradores exportada do Qulture
--   supabase_silver_colaborador      (165) API do Qulture (contrato, papel, supervisor)
-- FULL OUTER JOIN por e-mail minusculo. Medido em 18/10/2026: 307 na planilha, 165 na API,
-- 155 nos dois, 10 so na API => 317 linhas, 317 chaves. origem_cadastro diz de onde veio cada linha.
-- A API e o que traz id_contrato_qulture e papel; a planilha traz o resto (datas, cargo, custo).
--
-- FUSO. As tres colunas TIMESTAMP da planilha (inativado_em, atualizado_em_origem, criado_em_origem)
-- sao DATA disfarcada de instante: hora diferente de 00:00 em ZERO das linhas (192, 307 e 307
-- preenchidas). Saem como DATE, sem conversao de fuso (DATE(ts,'America/Sao_Paulo') jogaria cada
-- uma para o dia anterior). qulture_criado_em, da API, e instante UTC de verdade (carrega 'Z') e
-- converte com DATETIME(ts,'America/Sao_Paulo').
--
-- tempo_casa_meses E RELATIVO A DATA DO ARQUIVO, NAO A HOJE. Medido: reproduz
-- DATEDIFF(COALESCE(desligamento_efetivo, 2026-08-07), admissao)/30,4375 com diferenca zero em 277 de 277,
-- e 2026-08-07 e o dia do arquivo. Passa como a origem entrega e ganha data_referencia_arquivo ao lado.
-- Para tempo de casa de hoje, recalcular na Refined a partir de data_admissao.
--
-- DEFEITOS DA ORIGEM, MARCADOS E NAO CORRIGIDOS (marcar, nunca apagar):
--   flag_deslig_antes_admissao   5 (desligamento anterior a admissao)
--   flag_ativo_com_desligamento 12 (ativo na planilha e com data de desligamento)
--   flag_desligado_sem_data      1
--   flag_salario_difere_custo   27 (custo_tt difere do salario: custo total inclui encargos, nao e erro)
--   flag_ativo_diverge          planilha e API discordam sobre estar ativo
--   flag_nao_pessoa             9 (conta administrativa/sistema: eh_pessoa = FALSE)
--
-- BENEFICIOS vem como texto "R$ 480,00": convertido para FLOAT64 (formato brasileiro). Ferias e
-- zero de 307: nao emitida. Comissao tem 3 valores.
--
-- LIMITACAO -- NAO CONTORNE
-- E um arquivo (xlsx) exportado em 07/08/2026 e a API de 29/09/2026: nao e historico. Quem saiu
-- depois dessas datas nao aparece como saido. Turnover mede ate a data do arquivo.
WITH rel AS (
  SELECT * FROM `vanguardamartech_raw`.`supabase_silver_colaborador_rel`
),
api AS (
  SELECT * FROM `vanguardamartech_raw`.`supabase_silver_colaborador`
),
junto AS (
  SELECT
    COALESCE(LOWER(TRIM(r.email)), LOWER(TRIM(a.email)))                        AS email_chave,
    CASE WHEN r.email IS NOT NULL AND a.email IS NOT NULL THEN 'AMBOS'
         WHEN r.email IS NOT NULL THEN 'SO_PLANILHA' ELSE 'SO_API' END           AS origem_cadastro,
    a.qulture_contract_id                                                        AS id_contrato_qulture,
    COALESCE(NULLIF(TRIM(r.nome), ''), NULLIF(TRIM(a.nome), ''))                 AS nome,
    NULLIF(TRIM(r.apelido), '')                                                  AS apelido,
    COALESCE(NULLIF(TRIM(r.supervisor_nome), ''), NULLIF(TRIM(a.qulture_supervisor_nome), '')) AS supervisor_nome,
    NULLIF(LOWER(TRIM(r.supervisor_email)), '')                                  AS supervisor_email,
    NULLIF(CAST(a.qulture_supervisor_id AS STRING), '')                          AS id_supervisor_qulture,
    r.ativo_rel                                                                  AS is_ativo_planilha,
    a.ativo                                                                      AS is_ativo_api,
    NULLIF(TRIM(r.situacao), '')                                                 AS situacao,
    NULLIF(TRIM(r.cargo), '')                                                    AS cargo_planilha,
    NULLIF(TRIM(a.cargo), '')                                                    AS cargo_api,
    NULLIF(TRIM(a.papel), '')                                                    AS papel_qulture,
    NULLIF(TRIM(COALESCE(r.nivel, a.nivel)), '')                                 AS nivel,
    NULLIF(TRIM(r.departamento), '')                                             AS departamento,
    NULLIF(TRIM(r.area), '')                                                     AS area,
    NULLIF(TRIM(r.setor), '')                                                    AS setor,
    NULLIF(TRIM(r.tags), '')                                                     AS tags,
    NULLIF(TRIM(r.equipes), '')                                                  AS equipes_planilha,
    (SELECT STRING_AGG(JSON_VALUE(e, '$.name'), ' | ' ORDER BY JSON_VALUE(e, '$.name'))
       FROM UNNEST(JSON_QUERY_ARRAY(a.qulture_equipes)) e)                       AS equipes_api,
    NULLIF(TRIM(r.formacao), '')                                                 AS formacao,
    NULLIF(TRIM(r.sexo), '')                                                     AS sexo,
    NULLIF(TRIM(r.genero), '')                                                   AS genero,
    NULLIF(TRIM(r.pais), '')                                                     AS pais,
    NULLIF(TRIM(r.cidade), '')                                                   AS cidade,
    NULLIF(TRIM(r.estado), '')                                                   AS estado,
    NULLIF(TRIM(r.modalidade), '')                                               AS modalidade,
    NULLIF(TRIM(r.tipo_contrato), '')                                            AS tipo_contrato,
    CASE LOWER(TRIM(r.house)) WHEN 'sim' THEN TRUE WHEN 'nao' THEN FALSE END     AS is_house,
    NULLIF(TRIM(r.local_fisico), '')                                             AS local_fisico,
    r.data_admissao,
    r.data_desligamento,
    r.data_desligamento_efetiva,
    r.data_ultima_mudanca_cargo,
    SAFE_CAST(NULLIF(TRIM(r.data_renovacao_contrato), '') AS DATE)               AS data_renovacao_contrato,
    SAFE_CAST(NULLIF(TRIM(r.data_pagamento), '') AS INT64)                       AS dia_pagamento,
    DATE(r.inativado_em)                                                         AS inativado_em,
    DATE(r.criado_em_origem)                                                     AS criado_em_origem,
    DATE(r.atualizado_em_origem)                                                 AS atualizado_em_origem,
    DATETIME(a.qulture_created_at, 'America/Sao_Paulo')                          AS qulture_criado_em,
    NULLIF(TRIM(r.tipo_desligamento), '')                                        AS tipo_desligamento,
    NULLIF(TRIM(r.motivo_desligamento), '')                                      AS motivo_desligamento,
    NULLIF(TRIM(r.faixa_salarial), '')                                           AS faixa_salarial,
    r.salario,
    r.comissao,
    r.custo_tt                                                                   AS custo_total,
    SAFE_CAST(REPLACE(REPLACE(REPLACE(NULLIF(TRIM(r.mobilidade), ''), 'R$', ''), '.', ''), ',', '.') AS FLOAT64)    AS beneficio_mobilidade,
    SAFE_CAST(REPLACE(REPLACE(REPLACE(NULLIF(TRIM(r.refeicao), ''), 'R$', ''), '.', ''), ',', '.') AS FLOAT64)      AS beneficio_refeicao,
    SAFE_CAST(REPLACE(REPLACE(REPLACE(NULLIF(TRIM(r.plano_saude), ''), 'R$', ''), '.', ''), ',', '.') AS FLOAT64)   AS beneficio_plano_saude,
    SAFE_CAST(REPLACE(REPLACE(REPLACE(NULLIF(TRIM(r.gympass), ''), 'R$', ''), '.', ''), ',', '.') AS FLOAT64)       AS beneficio_gympass,
    SAFE_CAST(REPLACE(REPLACE(REPLACE(NULLIF(TRIM(r.saldo_livre), ''), 'R$', ''), '.', ''), ',', '.') AS FLOAT64)   AS beneficio_saldo_livre,
    r.tempo_casa_meses,
    DATE(r.fetched_at)                                                           AS data_referencia_arquivo,
    r.eh_pessoa,
    (r.data_desligamento < r.data_admissao)                                      AS flag_deslig_antes_admissao,
    (COALESCE(r.ativo_rel, FALSE) AND r.data_desligamento IS NOT NULL)           AS flag_ativo_com_desligamento,
    (r.situacao = 'DESLIGADO' AND r.data_desligamento IS NULL)                   AS flag_desligado_sem_data,
    (r.salario IS NOT NULL AND r.custo_tt IS NOT NULL AND ABS(r.salario - r.custo_tt) > 0.01) AS flag_salario_difere_custo,
    (r.ativo_rel IS NOT NULL AND a.ativo IS NOT NULL AND r.ativo_rel <> a.ativo) AS flag_ativo_diverge,
    (r.eh_pessoa IS NOT NULL AND NOT r.eh_pessoa)                                AS flag_nao_pessoa
  FROM rel r
  FULL OUTER JOIN api a ON LOWER(TRIM(r.email)) = LOWER(TRIM(a.email))
)
SELECT
  j.*,
  CURRENT_TIMESTAMP()                                                            AS _extraido_at,
  'supabase-x0tz'                                                                AS _fonte,
  'America/Sao_Paulo'                                                            AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(j)))                                                 AS _payload_hash
FROM junto j
