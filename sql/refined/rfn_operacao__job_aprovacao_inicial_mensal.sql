-- rfn_operacao__job_aprovacao_inicial_mensal  ·  Refined / operacao  ·  L2 INTERNAL (a Trusted e L4; regra/decisor/atividade NAO atravessam)
-- Grao: um mes de criacao da aprovacao inicial. Le: trs_vjob__job_aprovacao_inicial. Gatilho: evento em query-1vhx. Identidade (07/10/2026): 42 aprovacoes = 42 · 36 + 2 + 4.
-- R1 taxa_aprovacao = aprovadas / DECIDIDAS (aprovadas + recusadas); pendente fica fora do denominador; NULL sem decisao. R2 O fluxo tem semanas de vida e cobre ~2% do modulo vivo.
-- R3 A regra de roteamento e um NOME DE PESSOA (breno/jessica): nao e emitida. R4 4 aprovacoes apontam para job nao catalogado e 4 estao pendentes.
-- R5 tempo ate a decisao so existe para as decididas; media sobre 38, nao sobre 42.
WITH a AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__job_aprovacao_inicial`
),
agg AS (
  SELECT
    DATE_TRUNC(DATE(criada_em), MONTH) AS mes_criacao,
    COUNT(*) AS qtd_aprovacoes,
    COUNTIF(flag_aprovada) AS qtd_aprovadas,
    COUNTIF(flag_recusada) AS qtd_recusadas,
    COUNTIF(flag_pendente) AS qtd_pendentes,
    COUNTIF(flag_job_nao_catalogado) AS qtd_job_nao_catalogado,
    COUNTIF(flag_decidida_sem_data) AS qtd_decidida_sem_data,
    COUNTIF(flag_pendente_com_data) AS qtd_pendente_com_data,
    COUNT(DISTINCT id_decidida_por) AS qtd_decisores_distintos,
    ROUND(AVG(minutos_ate_a_decisao), 1) AS minutos_medios_ate_a_decisao,
    MAX(minutos_ate_a_decisao) AS minutos_maximos_ate_a_decisao
  FROM a
  GROUP BY 1
),
final AS (
  SELECT
    CAST(mes_criacao AS STRING) AS id_aprovacao_mensal,
    a.*,
    IF(qtd_aprovadas + qtd_recusadas = 0, NULL, ROUND(SAFE_DIVIDE(qtd_aprovadas, qtd_aprovadas + qtd_recusadas), 4)) AS taxa_aprovacao,
    'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
