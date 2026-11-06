-- trs_vjob__parcela_analista_alteracao
-- Troca de analista numa PARCELA do cronograma do VJOB.
-- Origem: mysql_vjobvjob_2024_tbcronogramadatas_analista_historico (282).
-- Familia do trs_vjob__squad_alteracao e do trs_vjob__cronograma_alteracao.
--
-- FUSO: o VJOB grava relogio local (medido na fonte em 2026-09-23, por dois caminhos).
-- `alterado_em` vem TIMESTAMP do MySQL e NADA SE CONVERTE.
WITH origem AS (
  SELECT
    id                                                          AS id_alteracao,
    id_cronogramadata                                           AS id_parcela,
    id_cronograma                                               AS id_contrato_no_log,
    mesanoreferencia                                            AS mes_referencia,
    NULLIF(analista_anterior_id, 0)                             AS id_analista_anterior,
    NULLIF(analista_novo_id, 0)                                 AS id_analista_novo,
    NULLIF(alterado_por, 0)                                     AS id_alterado_por,
    alterado_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbcronogramadatas_analista_historico`
),
parcela AS (
  SELECT DISTINCT id_parcela, id_cronograma AS id_contrato_na_parcela
  FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_parcela`
),
contrato AS (
  SELECT DISTINCT id_cronograma FROM `vanguardamartech_trusted`.`trs_vjob__cronograma`
),
usuarios AS (
  SELECT DISTINCT id_usuario, NULLIF(TRIM(nome), '') AS nome
  FROM `vanguardamartech_trusted`.`trs_vjob__usuario`
),
prep AS (
  SELECT
    o.*,
    p.id_contrato_na_parcela,
    (p.id_parcela IS NULL)                                      AS parcela_ausente,
    (c.id_cronograma IS NULL)                                   AS contrato_ausente,
    ua.nome                                                     AS analista_anterior_nome,
    un.nome                                                     AS analista_novo_nome,
    uz.nome                                                     AS alterado_por_nome,
    ROW_NUMBER() OVER (PARTITION BY o.id_parcela ORDER BY o.alterado_em, o.id_alteracao)
                                                                AS ordem_na_parcela,
    COUNT(*)     OVER (PARTITION BY o.id_parcela)               AS qtd_trocas_na_parcela
  FROM origem o
  -- ANTI-JOIN por CTE DISTINCT, nao `NOT EXISTS` correlacionado: esta base ja
  -- registrou que o correlacionado nao roda no BigQuery quando o lado direito cresce.
  LEFT JOIN parcela  p  ON p.id_parcela    = o.id_parcela
  LEFT JOIN contrato c  ON c.id_cronograma = o.id_contrato_no_log
  LEFT JOIN usuarios ua ON ua.id_usuario   = o.id_analista_anterior
  LEFT JOIN usuarios un ON un.id_usuario   = o.id_analista_novo
  LEFT JOIN usuarios uz ON uz.id_usuario   = o.id_alterado_por
),
tratado AS (
  SELECT
    p.id_alteracao,
    p.id_parcela,
    p.id_contrato_no_log,
    p.id_contrato_na_parcela,

    -- REGRA 1 - INVARIANTE MEDIDA: o contrato que o log declara e o contrato da
    -- propria parcela sao o mesmo em 248 de 248 avaliaveis, ZERO divergem.
    -- A coluna existe para que uma quebra futura apareca sem ninguem conferir.
    (p.id_contrato_na_parcela IS NOT NULL
      AND p.id_contrato_na_parcela <> p.id_contrato_no_log)     AS flag_contrato_diverge_da_parcela,

    -- REGRA 2 - mes_referencia e a competencia DA PARCELA, nao a data da troca.
    -- NAO e competencia limpa: 182 das 282 (64,5%) nao caem no dia 1, mesmo
    -- comportamento ja medido em tbcronograma.mesanoreferencia.
    p.mes_referencia,
    (EXTRACT(DAY FROM p.mes_referencia) <> 1)                   AS flag_mes_fora_do_dia_1,

    p.id_analista_anterior,
    p.analista_anterior_nome,
    p.id_analista_novo,
    p.analista_novo_nome,
    p.id_alterado_por,
    p.alterado_por_nome,

    -- FUSO: relogio local. Nao converter.
    p.alterado_em,

    -- REGRA 3 - a mesma parcela troca mais de uma vez: 41 parcelas, ate 4 trocas.
    -- Para "o analista atual da parcela", filtrar flag_ultima_troca, nunca somar linhas.
    p.ordem_na_parcela,
    p.qtd_trocas_na_parcela,
    (p.ordem_na_parcela = p.qtd_trocas_na_parcela)              AS flag_ultima_troca,

    -- REGRA 4 - troca sem efeito nao existe hoje (0 de 282), mas a coluna guarda
    -- a premissa: em tb_logs_squad o caso SEM_EFEITO tem 52 linhas.
    (p.id_analista_anterior IS NOT NULL
      AND p.id_analista_anterior = p.id_analista_novo)          AS flag_sem_efeito,
    (p.id_analista_anterior IS NULL)                            AS flag_entrada_sem_anterior,

    p.parcela_ausente                                           AS flag_parcela_nao_catalogada,
    p.contrato_ausente                                          AS flag_contrato_nao_catalogado
  FROM prep p
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'mysql-yIOn'                                                  AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                                AS _payload_hash
FROM tratado t
