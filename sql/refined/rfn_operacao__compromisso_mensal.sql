-- rfn_operacao__compromisso_mensal  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: um mes de referencia x origem (AGENDA, ATIVIDADE, ATIVIDADE_2, CHECK_*, TAREFA_PADRAO) x base da data. Le: trs_vjob__compromisso. Gatilho: evento em query-QDMA.
-- Identidade (07/10/2026): 58 compromissos = 58. Titulo e descricao NAO atravessam.
-- R1 A data de referencia e a do INICIO quando existe (so AGENDA) e a do CADASTRO quando nao; sem nenhuma das duas vai para SEM_DATA. base_da_data diz qual valeu, porque
--    mes de inicio e mes de cadastro NAO sao a mesma grandeza. R2 CHECK_HORARIO e TAREFA_PADRAO sao definicoes de rotina, sem data: nao ha serie mensal para elas.
-- R3 duracao_media_min so de quem tem inicio e fim com fim >= inicio. R4 Agenda e de 2019: nao e agenda corrente.
WITH c AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__compromisso`
),
agg AS (
  SELECT
    DATE_TRUNC(DATE(COALESCE(inicio, cadastrado_em)), MONTH) AS mes_referencia,
    origem,
    CASE WHEN inicio IS NOT NULL THEN 'INICIO' WHEN cadastrado_em IS NOT NULL THEN 'CADASTRO' ELSE 'SEM_DATA' END AS base_da_data,
    COUNT(*) AS qtd_compromissos,
    COUNTIF(ativo IS TRUE) AS qtd_ativos,
    COUNTIF(flag_fim_antes_do_inicio) AS qtd_fim_antes_do_inicio,
    COUNTIF(flag_conta_nao_catalogada) AS qtd_conta_nao_catalogada,
    COUNTIF(flag_atividade_nao_catalogada) AS qtd_atividade_nao_catalogada,
    ROUND(AVG(IF(inicio IS NOT NULL AND fim IS NOT NULL AND fim >= inicio, TIMESTAMP_DIFF(fim, inicio, MINUTE), NULL)), 1) AS duracao_media_min
  FROM c
  GROUP BY 1, 2, 3
),
final AS (
  SELECT CONCAT(IFNULL(CAST(mes_referencia AS STRING), 'SEM_DATA'), '|', origem, '|', base_da_data) AS id_compromisso_mensal, a.*, 'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
