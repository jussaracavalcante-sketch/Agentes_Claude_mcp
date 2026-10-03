-- trs_iclips__etapa
-- Trusted do iClips: uma etapa de workflow por linha. Chave id_workflow.
-- Historico profundo do bronze + ponta viva do notebook, deduplicados.
--
-- MESMO METODO da trs_iclips__projeto: o historico JA ESTAVA na base, aninhado
-- dentro do payload de projeto em supabase_bronze_iclips__projetos. Nao foi
-- preciso extrair nada -- foi preciso desaninhar.
--
-- VOLUME -- medido em 2026-09-15
--   bronze  : 728.245 ocorrencias brutas, 512.900 chaves distintas
--   notebook: 5.399 linhas
-- O bronze traz 95x mais etapas que o notebook, porque o notebook so
-- materializa as janelas moveis correntes.
--
-- DEDUPLICACAO. A mesma etapa aparece em varias capturas do projeto (o payload
-- e refeito a cada janela). Fica a leitura mais recente por fetched_at.
--
-- DESEMPATE ENTRE FONTES. Quando a chave existe nos dois lados vence o NOTEBOOK,
-- que e a leitura mais nova. origem_do_registro declara a procedencia linha a
-- linha -- ninguem precisa adivinhar de onde veio o numero.
--
-- SENTINELA 1800-01-01 vira NULL em todas as datas.
--
-- FUSO: o iClips JA entrega America/Sao_Paulo -- nao converter.
-- Ate 15/09/2026 estas tabelas usavam TIMESTAMP(dt,'America/Sao_Paulo'), que nao
-- converte de UTC: ela interpreta um relogio de parede COMO SE fosse SP e devolve
-- o instante, SOMANDO 3 horas a um dado que ja era local. Corrigido em 16/09/2026.
--
-- O NOTEBOOK PERDE O TIPO DE REFACAO, E ESTA TABELA NAO PERDE.
-- No payload, refacao e TEXTO com tres valores: vazio, "Alteracao Cliente" e
-- "Alteracao Interna". A tabela do notebook converte para BOOL e joga fora a
-- distincao entre refacao pedida pelo cliente e erro interno -- que e
-- exatamente a informacao que interessa para gestao. Aqui ficam as duas:
-- refacao_tipo (texto, so no bronze) e refacao (bool, comparavel entre fontes).
--
-- TEMPO ESTIMADO vem como duracao "H:MM:SS" e e convertido para minutos. E
-- conversao de unidade, nao regra de negocio (ADR-0009).

-- LIMITACAO -- NAO CONTORNE
-- O historico NAO avanca sozinho: o bronze depende da supabase-x0tz, congelada
-- desde 03/09. Enquanto ela estiver parada, so a ponta do notebook se move.
WITH bronze_bruto AS (
  SELECT
    JSON_VALUE(b.payload,'$.idProjeto')                               AS id_projeto,
    JSON_VALUE(p,'$.idJobPeca')                                       AS id_job_peca,
    JSON_VALUE(w,'$.idWorkflow')                                      AS id_workflow,
    JSON_VALUE(w,'$.nome')                                            AS nome_etapa,
    NULLIF(JSON_VALUE(w,'$.refacao'),'')                              AS refacao_tipo,
    NULLIF(JSON_VALUE(w,'$.refacao'),'') IS NOT NULL                  AS refacao,
    SAFE_CAST(SPLIT(JSON_VALUE(w,'$.tempoEstimado'),':')[SAFE_OFFSET(0)] AS INT64)*60 + SAFE_CAST(SPLIT(JSON_VALUE(w,'$.tempoEstimado'),':')[SAFE_OFFSET(1)] AS INT64) + SAFE_CAST(SPLIT(JSON_VALUE(w,'$.tempoEstimado'),':')[SAFE_OFFSET(2)] AS INT64)/60      AS tempo_estimado_min,
    SAFE_CAST(JSON_VALUE(w,'$.inicio') AS DATETIME)                   AS dt_inicio,
    SAFE_CAST(JSON_VALUE(w,'$.fim')    AS DATETIME)                   AS dt_fim,
    wpos                                                              AS etapa_pos,
    ARRAY_LENGTH(JSON_QUERY_ARRAY(w,'$.atividades'))                  AS qtd_apontamentos,
    b.fetched_at                                                      AS extraido_em
  FROM `vanguardamartech_raw.supabase_bronze_iclips__projetos` b,
       UNNEST(JSON_QUERY_ARRAY(b.payload,'$.pecas')) p,
       UNNEST(JSON_QUERY_ARRAY(p,'$.workflows')) w WITH OFFSET AS wpos
),
bronze AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT x.*, ROW_NUMBER() OVER (PARTITION BY id_workflow ORDER BY extraido_em DESC) AS rn
    FROM bronze_bruto x) WHERE rn = 1
),
nb AS (
  SELECT
    id_projeto, id_job_peca, id_workflow, nome_etapa,
    CAST(NULL AS STRING) AS refacao_tipo, refacao,
    tempo_estimado_min,
    DATETIME(inicio,'UTC') AS dt_inicio,
    DATETIME(fim,'UTC')    AS dt_fim,
    etapa_pos, qtd_apontamentos, extraido_em
  FROM `vanguardamartech_gestao_de_projetos_do_iclips`.`projeto_etapas`
),
uniao AS (
  SELECT 'BRONZE_HISTORICO' AS origem_do_registro, * FROM bronze
  UNION ALL SELECT 'NOTEBOOK_VIVO', * FROM nb
),
escolhida AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT u.*, ROW_NUMBER() OVER (PARTITION BY id_workflow
      ORDER BY IF(origem_do_registro='NOTEBOOK_VIVO',0,1), extraido_em DESC) AS rn
    FROM uniao u) WHERE rn = 1
),
tratada AS (
  SELECT
    e.id_workflow, e.id_job_peca, e.id_projeto, e.nome_etapa,
    e.refacao_tipo, e.refacao, e.tempo_estimado_min,
    IF(DATE(e.dt_inicio)=DATE '1800-01-01', NULL, TIMESTAMP(e.dt_inicio)) AS inicio,
    IF(DATE(e.dt_fim)   =DATE '1800-01-01', NULL, TIMESTAMP(e.dt_fim)) AS fim,
    e.etapa_pos, e.qtd_apontamentos,
    e.origem_do_registro,
    e.origem_do_registro = 'BRONZE_HISTORICO'                        AS registro_historico,
    DATE(e.dt_inicio) = DATE '1800-01-01'                            AS sem_data_inicio,
    e.extraido_em                                                    AS _extraido_at,
    IF(e.origem_do_registro='NOTEBOOK_VIVO','notebook-Rbpo',
       'supabase_bronze_iclips__projetos')                           AS _fonte
  FROM escolhida e
)
SELECT t.*, TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash FROM tratada t
