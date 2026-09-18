-- trs_iclips__peca
-- Trusted do iClips: uma peca de projeto por linha. Chave id_job_peca.
-- Historico profundo do bronze + ponta viva do notebook, deduplicados.
--
-- MESMO METODO da trs_iclips__projeto: o historico JA ESTAVA na base, aninhado
-- dentro do payload de projeto em supabase_bronze_iclips__projetos. Nao foi
-- preciso extrair nada -- foi preciso desaninhar.
--
-- VOLUME -- medido em 2026-09-15
--   bronze  : 195.822 ocorrencias brutas, 134.118 chaves distintas
--   notebook: 1.628 linhas
-- O bronze traz 82x mais pecas que o notebook, porque o notebook so
-- materializa as janelas moveis correntes.
--
-- DEDUPLICACAO. A mesma peca aparece em varias capturas do projeto (o payload
-- e refeito a cada janela). Fica a leitura mais recente por fetched_at.
--
-- DESEMPATE ENTRE FONTES. Quando a chave existe nos dois lados vence o NOTEBOOK,
-- que e a leitura mais nova. origem_do_registro declara a procedencia linha a
-- linha -- ninguem precisa adivinhar de onde veio o numero.
--
-- SENTINELA 1800-01-01 vira NULL em todas as datas. Medido: 195.020 de 195.822 ocorrencias
-- (99,6%) trazem inicioPlanejado sentinela. Na pratica o iClips nao planeja data
-- de peca -- NAO ler a ausencia como atraso.
--
-- FUSO: o iClips JA entrega America/Sao_Paulo -- nao converter.
-- Ate 15/09/2026 estas tabelas usavam TIMESTAMP(dt,'America/Sao_Paulo'), que nao
-- converte de UTC: ela interpreta um relogio de parede COMO SE fosse SP e devolve
-- o instante, SOMANDO 3 horas a um dado que ja era local. Corrigido em 16/09/2026.
--
-- STATUS VEM EM DUAS LINGUAS. O bronze traz codigo inteiro (5, 12, -1, 6, 13); o
-- notebook traz rotulo de texto. Sao expostos em colunas SEPARADAS --
-- status_peca_codigo e status_peca_rotulo -- em vez de espremidos numa so, que
-- obrigaria quem le a adivinhar o tipo. Cada linha preenche o da sua origem.

-- LIMITACAO -- NAO CONTORNE
-- O historico NAO avanca sozinho: o bronze depende da supabase-x0tz, congelada
-- desde 03/09. Enquanto ela estiver parada, so a ponta do notebook se move.
WITH bronze_bruto AS (
  SELECT
    JSON_VALUE(b.payload,'$.idProjeto')                               AS id_projeto,
    JSON_VALUE(p,'$.idJobPeca')                                       AS id_job_peca,
    JSON_VALUE(p,'$.idPeca')                                          AS id_peca,
    JSON_VALUE(p,'$.nomePeca')                                        AS nome_peca,
    JSON_VALUE(p,'$.tituloAtividade')                                 AS titulo_atividade,
    SAFE_CAST(JSON_VALUE(p,'$.status') AS INT64)                      AS status_peca_codigo,
    CAST(NULL AS STRING)                                              AS status_peca_rotulo,
    SAFE_CAST(JSON_VALUE(p,'$.isFlexible') AS BOOL)                   AS is_flexible,
    SAFE_CAST(JSON_VALUE(p,'$.inicioPlanejado') AS DATETIME)          AS dt_inicio,
    SAFE_CAST(JSON_VALUE(p,'$.fimPlanejado')    AS DATETIME)          AS dt_fim,
    pos                                                               AS peca_pos,
    ARRAY_LENGTH(JSON_QUERY_ARRAY(p,'$.workflows'))                   AS qtd_etapas,
    b.fetched_at                                                      AS extraido_em
  FROM `vanguardamartech_raw.supabase_bronze_iclips__projetos` b,
       UNNEST(JSON_QUERY_ARRAY(b.payload,'$.pecas')) p WITH OFFSET AS pos
),
bronze AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT x.*, ROW_NUMBER() OVER (PARTITION BY id_job_peca ORDER BY extraido_em DESC) AS rn
    FROM bronze_bruto x) WHERE rn = 1
),
nb AS (
  SELECT
    id_projeto, id_job_peca, id_peca, nome_peca, titulo_atividade,
    CAST(NULL AS INT64) AS status_peca_codigo, status_peca AS status_peca_rotulo,
    is_flexible,
    DATETIME(inicio_planejado,'UTC') AS dt_inicio,
    DATETIME(fim_planejado,'UTC')    AS dt_fim,
    peca_pos, qtd_etapas, extraido_em
  FROM `vanguardamartech_gestao_de_projetos_do_iclips`.`projeto_pecas`
),
uniao AS (
  SELECT 'BRONZE_HISTORICO' AS origem_do_registro, * FROM bronze
  UNION ALL SELECT 'NOTEBOOK_VIVO', * FROM nb
),
escolhida AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT u.*, ROW_NUMBER() OVER (PARTITION BY id_job_peca
      ORDER BY IF(origem_do_registro='NOTEBOOK_VIVO',0,1), extraido_em DESC) AS rn
    FROM uniao u) WHERE rn = 1
),
tratada AS (
  SELECT
    e.id_job_peca, e.id_projeto, e.id_peca, e.nome_peca, e.titulo_atividade,
    e.status_peca_codigo, e.status_peca_rotulo, e.is_flexible,
    IF(DATE(e.dt_inicio)=DATE '1800-01-01', NULL, TIMESTAMP(e.dt_inicio)) AS inicio_planejado,
    IF(DATE(e.dt_fim)   =DATE '1800-01-01', NULL, TIMESTAMP(e.dt_fim)) AS fim_planejado,
    e.peca_pos, e.qtd_etapas,
    e.origem_do_registro,
    e.origem_do_registro = 'BRONZE_HISTORICO'                        AS registro_historico,
    DATE(e.dt_inicio) = DATE '1800-01-01'                            AS sem_data_planejada,
    e.extraido_em                                                    AS _extraido_at,
    IF(e.origem_do_registro='NOTEBOOK_VIVO','notebook-Rbpo',
       'supabase_bronze_iclips__projetos')                           AS _fonte
  FROM escolhida e
)
SELECT t.*, TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash FROM tratada t
