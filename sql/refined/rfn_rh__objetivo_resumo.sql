-- rfn_rh__objetivo_resumo  ·  Refined / rh (Qulture)  ·  L2 INTERNAL
-- Grao: mes de criacao x nivel hierarquico (TOPO = sem pai; FILHO = com pai) do objetivo (OKR).
-- Le: trs_qulture__objetivo (query-Moqr, L2). Gatilho: evento em query-Moqr. Cadencia diaria (supabase-x0tz).
-- Identidade (19/10/2026, contra a Trusted materializada): 28 objetivos = 28 · 8 linhas, 8 chaves · 17 de topo · soma de score
--   1.174,58 = 1.174,58 · 82 key results · 11 filhos · 75 versoes · zero pai orfao · 2025-03 a 2025-07.
-- R1 score_pct passa como a plataforma entrega (0 a 100... e ha 1 objetivo com 190): qtd_score_acima_de_100 marca, nao corrige.
--    media_score_pct e media simples dos objetivos do grupo, nao ponderada por key result.
-- R2 qtd_com_time e ZERO nas 8 linhas e e fato medido: team.id e nulo nos 28 objetivos na origem. Nao ha recorte por time.
-- R3 qtd_pai_nao_catalogado conta objetivo cujo pai nao existe na propria tabela (hoje zero). Nome do objetivo nao atravessa.
-- LIMITACAO -- NAO CONTORNE: nao ha progresso por key result nem data de conclusao/prazo no payload; o ultimo objetivo foi criado em
--   22/07/2025 e nada novo entrou desde entao (fonte parada no conteudo, nao na extracao).
WITH o AS (SELECT * FROM `vanguardamartech_trusted`.`trs_qulture__objetivo`),
ids AS (SELECT DISTINCT id_objetivo FROM o),
base AS (
  SELECT o.*, (o.id_objetivo_pai IS NOT NULL AND p.id_objetivo IS NULL) AS flag_pai_nao_catalogado
  FROM o LEFT JOIN ids p ON p.id_objetivo = o.id_objetivo_pai
),
agg AS (
  SELECT
    DATE_TRUNC(DATE(criado_em), MONTH) AS mes_criacao,
    IF(is_objetivo_de_topo, 'TOPO', 'FILHO') AS nivel_hierarquico,
    COUNT(*) AS qtd_objetivos,
    COUNT(DISTINCT tipo) AS qtd_tipos,
    COUNTIF(score_pct IS NOT NULL) AS qtd_com_score,
    SUM(score_pct) AS soma_score_pct,
    AVG(score_pct) AS media_score_pct,
    MIN(score_pct) AS menor_score_pct,
    MAX(score_pct) AS maior_score_pct,
    COUNTIF(score_pct = 0) AS qtd_score_zero,
    COUNTIF(score_pct > 100) AS qtd_score_acima_de_100,
    SUM(qtd_key_results) AS soma_key_results,
    COUNTIF(qtd_key_results = 0) AS qtd_sem_key_result,
    SUM(qtd_filhos) AS soma_filhos,
    COUNTIF(id_time IS NOT NULL) AS qtd_com_time,
    COUNTIF(flag_pai_nao_catalogado) AS qtd_pai_nao_catalogado,
    SUM(qtd_versoes) AS soma_versoes,
    MAX(versao_lida_em) AS versao_lida_em
  FROM base
  GROUP BY 1, 2
),
final AS (
  SELECT CONCAT(FORMAT_DATE('%Y-%m', mes_criacao), '|', nivel_hierarquico) AS id_objetivo_resumo, a.*, 'L2_INTERNAL' AS classificacao_dado FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
