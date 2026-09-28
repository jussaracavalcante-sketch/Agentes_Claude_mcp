-- trs_vjob__job_prazo_alteracao
-- Alteracao de prazo de job no VJOB (mysql-yIOn). Grao: uma alteracao.
-- Chave: id_alteracao_unico.
--
-- O QUE ELA RESPONDE, e nenhuma outra tabela desta base responde: **quando o prazo de um
-- job muda, para onde ele vai.** A resposta e quase sempre a mesma.
--
-- **DE 227 ALTERACOES, 217 FORAM ADIAMENTO (95,6%).** E no modulo APOSENTADO foram
--   **124 de 124 -- cem por cento, nenhuma antecipacao em toda a historia dele**.
--   Remedido em 2026-09-28 na tabela materializada, por origem:
--     tbjobs      (`tbjobs_prazo_hist`)          123 alteracoes · 101 jobs · 123 adiaram
--     TAREFAS     (`tarefas_tbjobs_prazo_hist`)   95 alteracoes ·  76 jobs ·  85 adiaram
--     ADVISORY    (`advisory_tbjobs_prazo_hist`)   8 alteracoes ·   5 jobs ·   8 adiaram
--     tbjobsgeral (`tbjobs_prazo_hist_geral`)      1 alteracao  ·   1 job  ·   1 adiou
--   As 10 antecipacoes da base inteira estao todas no modulo vivo.
--
-- A QUARTA ORIGEM ENTROU EM 2026-09-24, pelo inventario dos 199 streams, depois de esta
--   tabela ja estar publicada com 224. E uma linha so e ela e **orfa** -- aponta para o
--   job 2, que nao existe em `tbjobsgeral`. Vale pelo mecanismo, nao pelo volume: a
--   origem existia, estava fora, e nada na contagem denunciava. Achada por `COUNT(*)`,
--   nao por busca -- a mesma licao do `tbjobs_arquivos`, no mesmo dia.
--
-- O ORFAO E DA ORIGEM, E ISSO FOI PROVADO EM 2026-09-28: `tbjobsgeral` tem 160 linhas e
--   o **menor id dela e 4** -- o job 2 nao existe e nao existiu na extracao nenhuma. O
--   log de prazo e de 27/10/2025 e sobreviveu ao cadastro que o gerou. E o mesmo
--   mecanismo ja medido na `trs_vjob__gestor_cliente`: o pai sai do catalogo e o
--   registro filho continua. Nao ha nada a consertar na origem por aqui.
--
-- **`flag_job_nao_catalogado` ACRESCENTADA EM 2026-09-28.** Ate aqui o orfao estava
--   DECLARADO na descricao e NAO SAIA EM COLUNA NENHUMA -- quem lesse a tabela nao tinha
--   como filtra-lo. A suite de qualidade acusou o caso como FALHA BLOQUEANTE na primeira
--   execucao com a quarta origem ja materializada, e ela estava certa sobre o fato e
--   errada sobre a severidade. Toda tabela desta base que tem buraco de cadastro acende
--   flag; esta era a excecao. **Orfao e melhor que falso par -- mas orfao SEM SINAL nao e
--   nenhum dos dois.** O anti-join e contra as duas Trusted de job (nao contra a
--   `rfn_operacao__job`, que dispara em `query-tfHg` em PARALELO com esta e pode nao
--   existir na hora), e usa LEFT JOIN sobre CTE com DISTINCT, nunca `NOT EXISTS`
--   correlacionado, que esta base ja registrou que nao roda no BigQuery quando o lado
--   direito cresce.
--
-- **O deslocamento medio e de +10,19 dias e o maior adiamento foi de 365 -- um ano.**
--   24 pessoas distintas ja alteraram prazo.
--
-- **A COBERTURA E PEQUENA E TEM DE VIR JUNTO COM O NUMERO: 183 jobs de 3.188 (5,7%)**
--   tiveram prazo alterado. Isso NAO significa que os outros 3.005 cumpriram o prazo --
--   significa que o prazo deles nunca foi editado no sistema. **Alteracao registrada e
--   alteracao registrada; nao e a medida de atraso.** Para atraso, a
--   `rfn_operacao__conformidade_cliente` mede marcacao contra prazo, que e outra coisa.
--
-- A CHAVE E COMPOSTA pelo mesmo motivo das tabelas de job: as quatro origens tem sequencia
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
--   5. `flag_job_nao_catalogado` e relativa ao conteudo das duas Trusted de job NA HORA
--      DA CARGA. Se um job for apagado da origem amanha, a flag acende nas alteracoes
--      dele -- e isso e o comportamento desejado, nao um defeito.
--
-- VALIDACAO 2026-09-28 (medida na tabela materializada, nao em simulacao)
--   227 linhas · 227 `id_alteracao_unico` distintos · 183 jobs distintos ·
--   217 adiamentos e 10 antecipacoes · **ZERO alteracoes de zero dia e ZERO com data
--   nula** · media +10,19 dias · maior adiamento 365 dias · 24 pessoas distintas ·
--   **1 orfao, o `tbjobsgeral:2`**, contra um universo de 3.188 jobs.
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
  UNION ALL
  -- QUARTA ORIGEM, acrescentada em 2026-09-24 pelo inventario dos 199 streams: o log de
  -- prazo de `tbjobsgeral`. Uma linha so, e ela e ORFA (aponta para o job 2, que nao
  -- existe -- o menor id de `tbjobsgeral` e 4). Vale pelo mecanismo: a origem existia e
  -- estava fora sem ninguem notar.
  SELECT 'tbjobsgeral', h.id, h.job_id, h.data_antiga, h.data_nova, h.alterado_por, h.data_alteracao
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbjobs_prazo_hist_geral` h
),
-- Universo de jobs das DUAS Trusted, com DISTINCT obrigatorio: sem ele o join
-- multiplicaria a linha da esquerda. Anti-join, nunca `NOT EXISTS` correlacionado.
jobs AS (
  SELECT DISTINCT id_job_unico FROM `vanguardamartech_trusted`.`trs_vjob__job`
  UNION DISTINCT
  SELECT DISTINCT id_job_unico FROM `vanguardamartech_trusted`.`trs_vjob__job_tarefa`
)
SELECT
  CONCAT(u.origem, ':', CAST(u.id AS STRING))       AS id_alteracao_unico,
  u.origem,
  u.id                                              AS id_alteracao,
  -- Mesmo prefixo das tabelas de job, entao junta direto com as quatro.
  CONCAT(u.origem, ':', CAST(u.job_id AS STRING))   AS id_job_unico,
  u.job_id                                          AS id_job,
  -- ACRESCENTADA 2026-09-28. O buraco de cadastro e da ORIGEM e esta tabela era a unica
  -- do VJOB que o carregava sem emitir sinal. Marcar, nunca apagar.
  (j.id_job_unico IS NULL)                          AS flag_job_nao_catalogado,
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
LEFT JOIN jobs j ON j.id_job_unico = CONCAT(u.origem, ':', CAST(u.job_id AS STRING))
