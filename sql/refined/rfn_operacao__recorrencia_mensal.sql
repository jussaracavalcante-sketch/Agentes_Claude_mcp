-- rfn_operacao__recorrencia_mensal  ·  Refined / operacao  ·  111 linhas  ·  L2 INTERNAL
-- Grao: uma REGRA de recorrencia em um MES de prazo planejado. Chave: id_recorrencia_mensal.
-- Origens: trs_vjob__recorrencia_ocorrencia (426) · trs_vjob__job_recorrencia (30) ·
--          trs_vjob__job_tarefa (so o job que originou a regra).
-- Gatilho: evento em query-r7ps, que ja dispara em query-UCso -- a cadeia garante a ordem.
-- As regras numeradas e os numeros da validacao estao na descricao da transformacao.
--
-- O ACHADO: **90 das 356 ocorrencias futuras (25,3%) JA ESTAO CANCELADAS.** A maquina
--   continua gerando e alguem cancela adiantado. Nao e agenda que vai acontecer nem
--   entrega que aconteceu -- e agenda ja desfeita, e some das duas leituras se ninguem
--   separar. Mais 2 futuras que ja constam CONCLUIDAS, com prazo em dezembro.
--
-- R1 o denominador da conclusao e a ocorrencia VENCIDA, nunca o total: 44,3% (31 de 70)
--   contra 7,3% (31 de 426) -- seis vezes · R2 taxa NULL, nunca zero, nas **84 de 111
--   linhas sem nenhuma ocorrencia vencida** · R3 a agenda e de tres meses e meio
--   (04/09 a 25/12/2026) e 83,6% dela ainda nao venceu · R4 `ocorrencias` da regra e
--   campo morto (zero nas 30) e sai NULL, nunca zero · R5 a ligacao e 1:1 e exata --
--   426 ocorrencias, 426 jobs distintos, ZERO orfaos nos dois lados.
--
-- LIMITACAO 1: **nao ha cliente aqui.** O job da recorrencia carrega `projeto`, que e
--   numerico e nao resolve contra nenhuma tabela-pai no catalogo -- medido: as 30 regras
--   apontam para UM UNICO projeto. Recorrencia por cliente nao se mede nesta base.
--
-- FUSO: relogio local da intranet. NAO CONVERTER.
WITH ocorrencia AS (
  SELECT
    id_ocorrencia, id_recorrencia, id_job_unico, prazo_planejado,
    flag_ocorrencia_futura, flag_job_cancelado, flag_job_concluido,
    flag_prazo_alterado, dias_deslocados
  FROM `vanguardamartech_trusted`.`trs_vjob__recorrencia_ocorrencia`
),
regra AS (
  SELECT
    id_recorrencia, id_job_unico, tipo, unidade, dias_semana, modo_mensal,
    termina_tipo, flag_sem_fim, resumo,
    -- R4 - campo morto na origem. NULL, nunca zero.
    ocorrencias                                         AS ocorrencias_previstas_na_regra
  FROM `vanguardamartech_trusted`.`trs_vjob__job_recorrencia`
),
job_origem AS (
  SELECT DISTINCT id_job_unico, atividade, status, projeto
  FROM `vanguardamartech_trusted`.`trs_vjob__job_tarefa`
),
agr AS (
  SELECT
    id_recorrencia,
    DATE_TRUNC(prazo_planejado, MONTH)                  AS mes_referencia,
    COUNT(*)                                            AS qtd_ocorrencias,
    -- R1 - vencida e futura nao se misturam em taxa nenhuma.
    COUNTIF(NOT flag_ocorrencia_futura)                 AS qtd_vencidas,
    COUNTIF(flag_ocorrencia_futura)                     AS qtd_futuras,
    COUNTIF(NOT flag_ocorrencia_futura AND flag_job_concluido)
                                                        AS qtd_vencidas_concluidas,
    COUNTIF(NOT flag_ocorrencia_futura AND flag_job_cancelado)
                                                        AS qtd_vencidas_canceladas,
    COUNTIF(NOT flag_ocorrencia_futura AND NOT flag_job_concluido AND NOT flag_job_cancelado)
                                                        AS qtd_vencidas_abertas,
    -- O ACHADO: agenda ja desfeita, e agenda ja dada por feita.
    COUNTIF(flag_ocorrencia_futura AND flag_job_cancelado)
                                                        AS qtd_futuras_ja_canceladas,
    COUNTIF(flag_ocorrencia_futura AND flag_job_concluido)
                                                        AS qtd_futuras_ja_concluidas,
    COUNTIF(flag_prazo_alterado)                        AS qtd_prazo_alterado,
    ROUND(AVG(IF(flag_prazo_alterado, dias_deslocados, NULL)), 2)
                                                        AS deslocamento_medio_dias,
    MIN(prazo_planejado)                                AS primeiro_prazo,
    MAX(prazo_planejado)                                AS ultimo_prazo
  FROM ocorrencia
  GROUP BY 1, 2
)
SELECT
  FORMAT('%d:%t', a.id_recorrencia, a.mes_referencia)   AS id_recorrencia_mensal,
  a.id_recorrencia,
  a.mes_referencia,
  EXTRACT(YEAR FROM a.mes_referencia)                   AS ano_referencia,

  r.id_job_unico                                        AS id_job_da_regra,
  j.atividade                                           AS atividade_da_regra,
  j.status                                              AS status_do_job_da_regra,
  r.tipo                                                AS tipo_recorrencia,
  r.unidade,
  r.dias_semana,
  r.modo_mensal,
  r.termina_tipo,
  r.flag_sem_fim,
  r.resumo                                              AS resumo_da_regra,
  -- R4 - NULL, nunca zero: a origem nunca preencheu.
  r.ocorrencias_previstas_na_regra,
  (r.id_recorrencia IS NULL)                            AS flag_regra_nao_catalogada,
  (r.id_job_unico IS NOT NULL AND j.id_job_unico IS NULL)
                                                        AS flag_job_da_regra_nao_catalogado,

  a.qtd_ocorrencias,
  a.qtd_vencidas,
  a.qtd_futuras,
  a.qtd_vencidas_concluidas,
  a.qtd_vencidas_canceladas,
  a.qtd_vencidas_abertas,
  a.qtd_futuras_ja_canceladas,
  a.qtd_futuras_ja_concluidas,

  -- R1 e R2 - o denominador e a ocorrencia VENCIDA, e sem vencida a taxa e NULL.
  IF(a.qtd_vencidas = 0, NULL,
     ROUND(SAFE_DIVIDE(a.qtd_vencidas_concluidas, a.qtd_vencidas), 4))
                                                        AS taxa_conclusao_do_vencido,
  IF(a.qtd_vencidas = 0, NULL,
     ROUND(SAFE_DIVIDE(a.qtd_vencidas_canceladas, a.qtd_vencidas), 4))
                                                        AS taxa_cancelamento_do_vencido,
  (a.qtd_vencidas = 0)                                  AS flag_sem_ocorrencia_vencida,

  a.qtd_prazo_alterado,
  a.deslocamento_medio_dias,
  a.primeiro_prazo,
  a.ultimo_prazo,

  CURRENT_TIMESTAMP()                                   AS _extraido_at,
  'mysql-yIOn'                                          AS _fonte,
  'America/Sao_Paulo'                                   AS _fuso
FROM agr a
LEFT JOIN regra      r ON r.id_recorrencia = a.id_recorrencia
LEFT JOIN job_origem j ON j.id_job_unico   = r.id_job_unico
