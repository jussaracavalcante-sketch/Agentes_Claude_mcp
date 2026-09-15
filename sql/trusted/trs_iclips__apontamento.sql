-- trs_iclips__apontamento  (query-9nws)
-- Trusted do iClips: um apontamento por linha. Chave id_apontamento.
-- Le gestao-de-projetos-do-iclips.apontamentos, saida do notebook-Rbpo.
--
-- SENTINELA 1800-01-01 -> NULL, e por que isso e seguro.
-- 2.206 de 6.884 registros (32%) trazem a data sentinela. MEDIDO em 2026-09-15:
-- todos eles tem tempo_gasto_min = 0, entao anular a data nao perde nenhuma hora.
-- O ganho e que o intervalo real aparece: o minimo era 1800-01-01 e passa a ser
-- 2026-07-17. Antes, qualquer MIN(data) mentia.
--
-- VINCULO EXCLUSIVO. Todo apontamento esta OU numa peca OU numa tarefa -- 6.810
-- via peca, 74 via tarefa, ZERO em ambos, ZERO em nenhum. A coluna vinculo
-- declara qual, para nao obrigar quem le a testar dois NULLs para descobrir.
--
-- LIMITACAO MEDIDA -- NAO CONTORNE
-- METADE DAS HORAS NAO TEM CUSTO. 3.090 apontamentos tem valor_hora = 0 e somam
-- 1.073,4 das 2.156,1 horas: 49,8%. O custo_estimado total de R$ 364.976,69 cobre
-- cerca de metade do esforco. Somar essa coluna e chamar de "custo da operacao"
-- subestima pela metade. A flag sem_custo_hora marca linha a linha. O conserto e
-- na origem (valor_hora no iClips), nao aqui -- Trusted nao inventa numero.
--
-- NAO RECALCULO METRICA DERIVADA (ADR-0009): custo_estimado passa como a
-- plataforma entrega. tempo_gasto_horas e conversao de unidade, nao regra.
--
-- ESCOPO: janelas moveis do notebook, hoje 2026-07-17 a 2026-09-14. NAO e o
-- historico completo. Existe caminho paralelo via Supabase muito mais profundo
-- (supabase_silver_iclips_etapa, 512.659 linhas), congelado desde 03/09. As duas
-- fontes NAO foram conciliadas -- nao somar uma com a outra.
WITH base AS (
  SELECT
    id_apontamento,
    id_projeto,
    id_job_peca,
    id_workflow,
    id_tarefa_job,
    IF(id_job_peca IS NOT NULL, 'PECA', 'TAREFA')                       AS vinculo,
    origem,
    id_pai,
    atividade_pos,
    CASE WHEN DATE(inicio_play, 'UTC') = DATE '1800-01-01' THEN NULL
         ELSE TIMESTAMP(DATETIME(inicio_play, 'UTC'), 'America/Sao_Paulo') END AS inicio_play,
    CASE WHEN DATE(fim_play, 'UTC') = DATE '1800-01-01' THEN NULL
         ELSE TIMESTAMP(DATETIME(fim_play, 'UTC'), 'America/Sao_Paulo') END    AS fim_play,
    status_conclusao,
    tempo_gasto_min,
    ROUND(tempo_gasto_min / 60, 4)                                      AS tempo_gasto_horas,
    executor_id,
    executor_nome,
    executor_departamento,
    valor_hora,
    custo_estimado,
    DATE(inicio_play, 'UTC') = DATE '1800-01-01'                        AS sem_data_de_execucao,
    valor_hora = 0                                                      AS sem_custo_hora,
    conteudo_hash,
    TIMESTAMP(DATETIME(extraido_em, 'UTC'), 'America/Sao_Paulo')        AS _extraido_at,
    'notebook-Rbpo'                                                     AS _fonte
  FROM `vanguardamartech_gestao_de_projetos_do_iclips`.`apontamentos`
),
unico AS (
  SELECT * FROM base
  QUALIFY ROW_NUMBER() OVER (PARTITION BY id_apontamento ORDER BY _extraido_at DESC) = 1
)
SELECT
  u.*,
  DATE(u.inicio_play)                                                   AS data_apontamento,
  DATE_TRUNC(DATE(u.inicio_play), MONTH)                                AS mes_referencia,
  TO_HEX(MD5(TO_JSON_STRING(u)))                                        AS _payload_hash
FROM unico u
