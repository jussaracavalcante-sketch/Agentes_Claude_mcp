-- trs_vjob__job_responsavel
-- Responsavel por job no modulo VIVO do VJOB (mysql-yIOn). Grao: um par (job, pessoa).
-- Chave: id_job_responsavel.
--
-- POR QUE ELA EXISTE: a `trs_vjob__job_tarefa` e a `rfn_operacao__job` carregam, as duas,
-- a limitacao "o responsavel aqui e o do CABECALHO, e ha um so". **A limitacao e real e
-- agora esta medida:** 101 dos 1.267 jobs cobertos tem MAIS DE UM responsavel, ate
-- **seis**. Quem contar trabalho pelo cabecalho subconta trabalho colaborativo em 8% dos
-- jobs. Esta tabela e o lado N que faltava.
--
-- MEDIDO EM 2026-09-24
--   **1.381 linhas, 1.381 ids, 1.267 jobs** -- o DDL do catalogo dizia 1.329, que e
--   metadado antigo (a armadilha ja registrada nesta casa). Janela 30/06 a 23/09/2026.
--   60 usuarios distintos, **todos `interno`**: `responsavel_externo_id` esta vazio em
--   TODAS as linhas, entao o modulo permite externo e ninguem usou.
--
-- DUAS INVARIANTES MEDIDAS, e as duas saem como coluna para quebra futura aparecer:
--   1. **Exatamente UM principal por job.** 1.267 jobs, 1.267 principais, **zero sem
--      principal e zero com mais de um**. Sem isso, "o responsavel do job" seria ambiguo.
--   2. **O principal NUNCA contradiz o cabecalho.** Comparado com
--      `tarefas_tbjobs.responsavel`: **1.267 batem, ZERO divergem**. Entao esta tabela
--      ACRESCENTA responsavel, nunca corrige o que a `trs_vjob__job_tarefa` ja diz --
--      as duas podem ser lidas juntas sem conflito.
--
-- **62 DOS 1.329 JOBS (4,7%) NAO TEM LINHA AQUI**, e nao e defeito: o satelite comeca em
--   30/06/2026 e o modulo de job comeca em 04/03/2026. Os 62 sao anteriores ao satelite e
--   so tem o responsavel do cabecalho. **Join a partir do job tem de ser LEFT**; com
--   INNER esses 62 sumiriam de qualquer contagem por responsavel, sem sinal.
--
-- FUSO: NADA SE CONVERTE. `criado_em` vem TIMESTAMP direto do MySQL e ja e hora local
--   (America/Sao_Paulo), provado no nivel do conector em 2026-09-23.
--
-- CLASSIFICACAO: **L2 INTERNAL.** So ids, um booleano e uma data. **Nenhum nome de
--   pessoa** -- quem quiser o nome junta com `trs_vjob__usuario`, que e L4, e a tabela
--   resultante herda o nivel de la.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **Esta tabela e SO do ramo TAREFAS.** O `advisory_tbjobs` nao tem satelite de
--      responsaveis: la o responsavel existe apenas no cabecalho. Por isso `id_job_unico`
--      sai sempre com o prefixo `TAREFAS:` -- **nao junta com as 256 linhas ADVISORY**.
--   2. `id_responsavel_externo` e emitido e esta **vazio nas 1.381 linhas**. Fica como
--      ausencia declarada, nao como zero: o modulo prevê responsavel externo e ele nunca
--      foi usado. Nao somar por ele esperando encontrar alguem.
--   3. **Nao ha papel nem carga.** A tabela diz QUEM, nao o que a pessoa fez nem quanto.
--      Nao existe percentual, hora ou etapa por responsavel nesta base.
--
-- VALIDACAO 2026-09-24 (a query validada reproduziu todos estes numeros)
--   1.381 linhas · 1.381 `id_job_responsavel` · 1.381 `_payload_hash` distintos ·
--   1.267 jobs · 1.267 principais (um por job, zero sem e zero em duplicidade) ·
--   101 jobs com mais de um responsavel, maximo 6 · 60 usuarios · ZERO externos.
SELECT
  r.id                                              AS id_job_responsavel,
  -- A chave que junta com trs_vjob__job_tarefa e rfn_operacao__job. O prefixo e sempre
  -- TAREFAS porque o satelite nao existe para ADVISORY -- ver limitacao 1.
  CONCAT('TAREFAS:', CAST(r.job_id AS STRING))      AS id_job_unico,
  r.job_id                                          AS id_job,
  NULLIF(r.usuario_id, 0)                           AS id_usuario,
  NULLIF(TRIM(r.responsavel_tipo), '')              AS responsavel_tipo,
  -- Invariante 1: exatamente um TRUE por job. Se aparecer job com zero ou com dois,
  -- "o responsavel do job" vira ambiguo e toda leitura por principal fica errada.
  (r.principal = 1)                                 AS is_principal,
  -- Emitido vazio de proposito: o modulo prevê externo e ninguem usou. Ausencia
  -- declarada, nunca zero.
  NULLIF(r.responsavel_externo_id, 0)               AS id_responsavel_externo,
  r.criado_em,
  CURRENT_TIMESTAMP()                               AS _extraido_at,
  'mysql-yIOn'                                      AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(r)))                    AS _payload_hash
FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tarefas_tbjobs_responsaveis` r
