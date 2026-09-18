-- trs_iclips__tarefa
-- Trusted do iClips: uma tarefa de projeto por linha. Chave id_tarefa_job.
-- Historico profundo do bronze + ponta viva do notebook, deduplicados.
--
-- MESMO METODO da trs_iclips__projeto: o historico JA ESTAVA na base, aninhado
-- dentro do payload de projeto em supabase_bronze_iclips__projetos. Nao foi
-- preciso extrair nada -- foi preciso desaninhar.
--
-- VOLUME -- medido em 2026-09-15
--   bronze  : 11.448 ocorrencias brutas, 8.781 chaves distintas
--   notebook: 86 linhas
-- O bronze traz 102x mais tarefas que o notebook, porque o notebook so
-- materializa as janelas moveis correntes.
--
-- DEDUPLICACAO. A mesma tarefa aparece em varias capturas do projeto (o payload
-- e refeito a cada janela). Fica a leitura mais recente por fetched_at.
--
-- DESEMPATE ENTRE FONTES. Quando a chave existe nos dois lados vence o NOTEBOOK,
-- que e a leitura mais nova. origem_do_registro declara a procedencia linha a
-- linha -- ninguem precisa adivinhar de onde veio o numero.
--
-- SENTINELA 1800-01-01 vira NULL em todas as datas. Medido: 1.765 de 11.448 ocorrencias trazem
-- inicioPlanejado sentinela.
--
-- FUSO: o iClips JA entrega America/Sao_Paulo -- nao converter.
-- Ate 15/09/2026 estas tabelas usavam TIMESTAMP(dt,'America/Sao_Paulo'), que nao
-- converte de UTC: ela interpreta um relogio de parede COMO SE fosse SP e devolve
-- o instante, SOMANDO 3 horas a um dado que ja era local. Corrigido em 16/09/2026.
--
-- TAREFA E O CAMINHO ALTERNATIVO DA PECA. O apontamento se liga OU a uma etapa
-- de peca OU a uma tarefa, nunca aos dois (medido na trs_iclips__apontamento:
-- 6.810 via peca, 74 via tarefa, zero em ambos). Tarefa e o volume menor.
--
-- TEMPO ESTIMADO vem como duracao "H:MM:SS" e vira minutos -- conversao de
-- unidade, nao regra de negocio.

-- LIMITACAO -- NAO CONTORNE
-- O historico NAO avanca sozinho: o bronze depende da supabase-x0tz, congelada
-- desde 03/09. Enquanto ela estiver parada, so a ponta do notebook se move.
WITH bronze_bruto AS (
  SELECT
    JSON_VALUE(b.payload,'$.idProjeto')                               AS id_projeto,
    JSON_VALUE(t,'$.idTarefaJob')                                     AS id_tarefa_job,
    JSON_VALUE(t,'$.tituloAtividade')                                 AS titulo_atividade,
    SAFE_CAST(SPLIT(JSON_VALUE(t,'$.tempoEstimado'),':')[SAFE_OFFSET(0)] AS INT64)*60 + SAFE_CAST(SPLIT(JSON_VALUE(t,'$.tempoEstimado'),':')[SAFE_OFFSET(1)] AS INT64) + SAFE_CAST(SPLIT(JSON_VALUE(t,'$.tempoEstimado'),':')[SAFE_OFFSET(2)] AS INT64)/60      AS tempo_estimado_min,
    SAFE_CAST(JSON_VALUE(t,'$.inicioPlanejado') AS DATETIME)          AS dt_inicio,
    SAFE_CAST(JSON_VALUE(t,'$.fimPlanejado')    AS DATETIME)          AS dt_fim,
    tpos                                                              AS tarefa_pos,
    ARRAY_LENGTH(JSON_QUERY_ARRAY(t,'$.atividades'))                  AS qtd_apontamentos,
    b.fetched_at                                                      AS extraido_em
  FROM `vanguardamartech_raw.supabase_bronze_iclips__projetos` b,
       UNNEST(JSON_QUERY_ARRAY(b.payload,'$.tarefas')) t WITH OFFSET AS tpos
),
bronze AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT x.*, ROW_NUMBER() OVER (PARTITION BY id_tarefa_job ORDER BY extraido_em DESC) AS rn
    FROM bronze_bruto x) WHERE rn = 1
),
nb AS (
  SELECT
    id_projeto, id_tarefa_job, titulo_atividade, tempo_estimado_min,
    DATETIME(inicio_planejado,'UTC') AS dt_inicio,
    DATETIME(fim_planejado,'UTC')    AS dt_fim,
    tarefa_pos, qtd_apontamentos, extraido_em
  FROM `vanguardamartech_gestao_de_projetos_do_iclips`.`projeto_tarefas`
),
uniao AS (
  SELECT 'BRONZE_HISTORICO' AS origem_do_registro, * FROM bronze
  UNION ALL SELECT 'NOTEBOOK_VIVO', * FROM nb
),
escolhida AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT u.*, ROW_NUMBER() OVER (PARTITION BY id_tarefa_job
      ORDER BY IF(origem_do_registro='NOTEBOOK_VIVO',0,1), extraido_em DESC) AS rn
    FROM uniao u) WHERE rn = 1
),
tratada AS (
  SELECT
    e.id_tarefa_job, e.id_projeto, e.titulo_atividade, e.tempo_estimado_min,
    IF(DATE(e.dt_inicio)=DATE '1800-01-01', NULL, TIMESTAMP(e.dt_inicio)) AS inicio_planejado,
    IF(DATE(e.dt_fim)   =DATE '1800-01-01', NULL, TIMESTAMP(e.dt_fim)) AS fim_planejado,
    e.tarefa_pos, e.qtd_apontamentos,
    e.origem_do_registro,
    e.origem_do_registro = 'BRONZE_HISTORICO'                        AS registro_historico,
    DATE(e.dt_inicio) = DATE '1800-01-01'                            AS sem_data_planejada,
    e.extraido_em                                                    AS _extraido_at,
    IF(e.origem_do_registro='NOTEBOOK_VIVO','notebook-Rbpo',
       'supabase_bronze_iclips__projetos')                           AS _fonte
  FROM escolhida e
)
SELECT t.*, TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash FROM tratada t
