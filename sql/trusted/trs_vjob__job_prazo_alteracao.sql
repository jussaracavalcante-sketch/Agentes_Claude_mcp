-- trs_vjob__job_prazo_alteracao
-- Alteracao de prazo de job no VJOB (mysql-yIOn). Grao: uma alteracao.
-- Chave: id_alteracao_unico.
--
-- O QUE ELA RESPONDE, e nenhuma outra tabela desta base responde: **quando o prazo de um
-- job muda, para onde ele vai.** A resposta e quase sempre a mesma.
--
-- **DE 224 ALTERACOES, 214 FORAM ADIAMENTO (95,5%).** E no modulo APOSENTADO foram
--   **123 de 123 -- cem por cento, nenhuma antecipacao em toda a historia dele**.
--   Medido em 2026-09-24, por modulo:
--     APOSENTADO (`tbjobs_prazo_hist`)          123 alteracoes · 101 jobs · 123 adiaram
--     TAREFAS    (`tarefas_tbjobs_prazo_hist`)   93 alteracoes ·  74 jobs ·  83 adiaram
--     ADVISORY   (`advisory_tbjobs_prazo_hist`)   8 alteracoes ·   5 jobs ·   8 adiaram
--   As 10 antecipacoes da base inteira estao todas no modulo vivo.
--   **O deslocamento medio e de +10,2 dias e o maior adiamento foi de 365 -- um ano.**
--   24 pessoas distintas ja alteraram prazo.
--
-- **A COBERTURA E PEQUENA E TEM DE VIR JUNTO COM O NUMERO: 180 jobs de 3.099 (5,8%)**
--   tiveram prazo alterado. Isso NAO significa que os outros 2.919 cumpriram o prazo --
--   significa que o prazo deles nunca foi editado no sistema. **Alteracao registrada e
--   alteracao registrada; nao e a medida de atraso.** Para atraso, a
--   `rfn_operacao__conformidade_cliente` mede marcacao contra prazo, que e outra coisa.
--
-- A CHAVE E COMPOSTA pelo mesmo motivo das tabelas de job: as tres origens tem sequencia
--   propria de `id` e elas colidem. `id_alteracao_unico` = `<origem>:<id>`, e o
--   `id_job_unico` acompanha o mesmo prefixo das tabelas de job, entao junta direto com
--   `trs_vjob__job`, `trs_vjob__job_tarefa` e `rfn_operacao__job`.
--
-- FUSO: NADA SE CONVERTE. `data_alteracao` vem TIMESTAMP direto do MySQL e ja e hora
--   local (America/Sao_Paulo), provado no nivel do conector em 2026-09-23.
--
-- CLASSIFICACAO: **L2 INTERNAL.** So ids, duas datas e um timestamp. Nenhum texto livre,
--   nenhum nome -- `alterado_por` e id. Quem quiser o nome junta com `trs_vjob__usuario`
--   (L4) e herda o nivel de la.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **Isto e um LOG, nao um estado.** A tabela nao diz qual e o prazo vigente do job;
--      diz que ele mudou de X para Y naquele instante. O prazo atual esta em
--      `data_entrega` nas tabelas de job.
--   2. **Nao ha motivo.** Nenhuma coluna diz POR QUE o prazo mudou. Nao inferir causa.
--   3. `dias_deslocados` e a diferenca entre as duas datas, **sem sinal invertido**:
--      positivo e adiamento, negativo e antecipacao. Nao existe alteracao de zero dia.
--   4. Job com duas alteracoes aparece duas vezes, de proposito -- o grao e a ALTERACAO.
--      Para contar jobs afetados, use `COUNT(DISTINCT id_job_unico)`.
--
-- VALIDACAO 2026-09-24 (a query validada reproduziu todos estes numeros)
--   224 linhas · 224 `id_alteracao_unico` distintos · 224 `_payload_hash` distintos ·
--   180 jobs distintos · 214 adiamentos e 10 antecipacoes · **ZERO alteracoes de zero
--   dia e ZERO com data nula** · media +10,2 dias · maior adiamento 365 dias ·
--   24 pessoas distintas.
WITH uniao AS (
  SELECT 'tbjobs'   AS origem, h.id, h.job_id, h.data_antiga, h.data_nova,
         h.alterado_por, h.data_alteracao
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbjobs_prazo_hist` h
  UNION ALL
  SELECT 'TAREFAS', h.id, h.job_id, h.data_antiga, h.data_nova, h.alterado_por, h.data_alteracao
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tarefas_tbjobs_prazo_hist` h
  UNION ALL
  SELECT 'ADVISORY', h.id, h.job_id, h.data_antiga, h.data_nova, h.alterado_por, h.data_alteracao
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_advisory_tbjobs_prazo_hist` h
)
SELECT
  CONCAT(u.origem, ':', CAST(u.id AS STRING))       AS id_alteracao_unico,
  u.origem,
  u.id                                              AS id_alteracao,
  -- Mesmo prefixo das tabelas de job, entao junta direto com as tres.
  CONCAT(u.origem, ':', CAST(u.job_id AS STRING))   AS id_job_unico,
  u.job_id                                          AS id_job,
  u.data_antiga                                     AS prazo_anterior,
  u.data_nova                                       AS prazo_novo,
  DATE_DIFF(u.data_nova, u.data_antiga, DAY)        AS dias_deslocados,
  (u.data_nova > u.data_antiga)                     AS is_adiamento,
  (u.data_nova < u.data_antiga)                     AS is_antecipacao,
  NULLIF(u.alterado_por, 0)                         AS id_alterado_por,
  u.data_alteracao                                  AS alterado_em,
  CURRENT_TIMESTAMP()                               AS _extraido_at,
  'mysql-yIOn'                                      AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(u)))                    AS _payload_hash
FROM uniao u
