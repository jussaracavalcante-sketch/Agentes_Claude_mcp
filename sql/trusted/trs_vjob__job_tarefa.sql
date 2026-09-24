-- trs_vjob__job_tarefa
-- O MODULO DE JOB VIVO do VJOB real (mysql-yIOn). Grao: um job. Chave: id_job_unico.
--
-- LEIA ISTO ANTES DE USAR A `trs_vjob__job`. Ate 2026-09-24 esta casa registrava que
-- "o modulo de JOB do VJOB esta parado desde 24/08/2026". **Nao esta parado: mudou de
-- tabela.** A `trs_vjob__job` le `tbjobs` + `tbjobsgeral`, e essas duas de fato pararam.
-- O trabalho continuou em `tarefas_tbjobs` e `advisory_tbjobs`, que NENHUMA tabela desta
-- base lia. Medido em 2026-09-24:
--   `tbjobs`          04/08/2025 -> **24/08/2026** (1.354)  -- modulo aposentado
--   `tarefas_tbjobs`  04/03/2026 -> **23/09/2026** (1.329)  -- ontem
--   `advisory_tbjobs` 26/01/2026 -> **18/09/2026** (256)
--
-- E NAO E COPIA, ISSO FOI TESTADO. A hipotese obvia -- migracao que duplicou as linhas --
-- foi medida e descartada: entre `tbjobs` e `tarefas_tbjobs` ha **ZERO** linhas que casem
-- por (projeto, atividade, data_cadastro) e **ZERO** que casem por (id, data_cadastro).
-- Os 1.229 ids em comum sao **coincidencia de sequencia numerica**, nao a mesma linha.
-- Portanto as duas tabelas contam trabalho DIFERENTE e **somar as duas nao duplica nada**.
--
-- A CHAVE E COMPOSTA, e isso tambem foi medido: 1.585 linhas, **1.585 chaves
-- (origem, id_job) e apenas 1.330 ids crus** -- 255 ids aparecem nas duas origens. Usar
-- `id_job` sozinho funde jobs distintos. Mesma armadilha ja registrada na `trs_vjob__job`.
--
-- AS DUAS ORIGENS TEM VOCABULARIO DE STATUS DIFERENTE, e por isso `status` sai CRU.
--   TAREFAS  : Aprovado 676 · A fazer 449 · Cancelado 185 · Em andamento 10 ·
--              Aguardando analista 6 · Aprovacao cliente 3
--   ADVISORY : **Feito** 213 · A fazer 23 · Em andamento 13 · Cancelado 7
--   Nao existe tabela de dominio de status. `is_concluido` le os dois vocabularios
--   ("Aprovado" ou "Feito") e **`status` continua visivel ao lado** -- valor novo na
--   origem cai fora da flag e permanece legivel. Normalizar os dois num rotulo so
--   apagaria a informacao de que sao dois modulos.
--
-- `checado_em` E CAMPO MORTO NO MODULO NOVO -- quase. Medido: **ZERO das 1.329 linhas de
--   TAREFAS tem `checado_em`**, contra 66 das 256 de ADVISORY. No modulo aposentado ele
--   estava preenchido em 1.051 de 1.354. A etapa de checagem deixou de existir no fluxo
--   novo. Indicador de checagem sobre esta tabela cobre 4% dela -- e a cobertura vai
--   junto com o numero, nunca sozinha.
--
-- `responsavel_tipo` SEPARA QUEM EXECUTA, e as origens se comportam ao contrario:
--   TAREFAS  e **100% interno** (1.329 de 1.329, nenhum externo).
--   ADVISORY e **70% externo** (179 de 256). O `advisory` e trabalho tocado por
--   terceiro; o `tarefas` e a operacao da casa. Somar os dois num indicador de
--   produtividade interna infla o denominador.
--
-- FUSO: NADA SE CONVERTE. Os TIMESTAMP vem direto do MySQL e ja sao hora local
--   (America/Sao_Paulo), provado no nivel do conector em 2026-09-23. Aplicar
--   'America/Sao_Paulo' somaria ou subtrairia 3 horas -- e a armadilha que deixou a
--   `trs_vjob__job` 3 horas adiantada em 100% das linhas ate 23/09/2026.
--
-- SEGREDO NAO SAI DAQUI. 153 das 1.585 linhas tem `public_token` -- token de acesso
--   publico ao job. NAO e emitido (§31: secret e L5 e nao deve estar no Data Lake),
--   junto com `public_generated_at` e `public_expires_at`. Sai apenas
--   `flag_tem_token_publico`, que responde "existe acesso publico?" sem entregar a chave.
--
-- CLASSIFICACAO: **L4 PERSONAL_DATA, por linhagem.** A tabela em si carrega ids de
--   pessoa (responsavel, checado_por, aprovado_por, quemcadastrou), nao nomes -- mas
--   `observacao` e campo livre preenchido por pessoa em 1.389 das 1.585 linhas, e o
--   nivel sobe pela linhagem, nunca desce. Quem agregar e provar que nada pessoal passou
--   pode declarar L3 na descricao da Refined, como fez a `rfn_operacao__custo_peca`.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **`projeto` NAO E CLIENTE.** E texto livre, igual ao da `tbjobs`, e esta base ja
--      registra que `tbjobs.projeto` nao e FK de cliente. 72 valores distintos em
--      TAREFAS. NAO ligar a `trs_vjob__cliente` nem ao `cliente_sk` por este campo --
--      seria casamento por rotulo, que a casa proibe tratar como prova.
--   2. **Esta tabela NAO substitui a `trs_vjob__job`**; ela cobre o periodo que a outra
--      nao cobre. Serie historica de job precisa das duas, e o corte esta em 24/08/2026.
--   3. `id_servico_interno` so existe em ADVISORY (13 linhas preenchidas) e **nao tem
--      tabela de dominio localizada**. Sai como id, sem rotulo.
--   4. **19 jobs tem entrega prevista ANTES da entrada** (`dias_entrada_ate_entrega`
--      negativo). Esta na origem e nao se corrige aqui -- marcar, nunca apagar. Nenhuma
--      das 1.585 linhas esta sem as duas datas, entao o indicador de prazo cobre 100%.
--   5. As tabelas satelite do modulo NAO estao aqui e nao foram tratadas:
--      `tarefas_tbjobs_responsaveis` (1.329), `_comentarios` (589), `_arquivos` (282),
--      `_prazo_hist` (75), `_recorrencias` (30), `_aprovacao_inicial` (25). O job pode
--      ter mais de um responsavel; esta tabela emite o do cabecalho, que e um so.
--
-- VALIDACAO 2026-09-24 (a query validada reproduziu todos estes numeros)
--   1.585 linhas · 1.585 chaves `id_job_unico` · 1.585 `_payload_hash` distintos ·
--   889 concluidos · 192 cancelados · 179 responsavel externo · 66 checados ·
--   757 com `aprovado = 1` · 153 com token publico · 143 com acesso publico ativo ·
--   13 com servico interno · 19 com prazo negativo · ZERO sem as duas datas de prazo.
WITH uniao AS (
  SELECT
    'TAREFAS'                             AS origem,
    t.id                                  AS id_job,
    NULLIF(TRIM(t.projeto), '')           AS projeto,
    NULLIF(TRIM(t.tipo), '')              AS tipo,
    NULLIF(TRIM(t.atividade), '')         AS atividade,
    t.data_entrada,
    t.data_entrega,
    t.data_publicacao,
    NULLIF(TRIM(t.status), '')            AS status,
    NULLIF(TRIM(t.responsavel_tipo), '')  AS responsavel_tipo,
    NULLIF(t.responsavel, 0)              AS id_responsavel,
    NULLIF(t.responsavel_externo_id, 0)   AS id_responsavel_externo,
    CAST(NULL AS INT64)                   AS id_servico_interno,
    NULLIF(t.checado_por, 0)              AS checado_por,
    t.checado_em,
    t.aprovado,
    NULLIF(t.aprovado_por, 0)             AS aprovado_por,
    t.aprovado_em,
    NULLIF(t.observacao, '')              AS observacao,
    NULLIF(t.quemcadastrou, 0)            AS quem_cadastrou,
    t.data_cadastro,
    t.public_enabled,
    t.public_token
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tarefas_tbjobs` t
  UNION ALL
  SELECT
    'ADVISORY',
    a.id,
    NULLIF(TRIM(a.projeto), ''),
    NULLIF(TRIM(a.tipo), ''),
    NULLIF(TRIM(a.atividade), ''),
    a.data_entrada,
    a.data_entrega,
    -- ADVISORY nao tem data de publicacao no esquema. NULL declarado, nunca uma data
    -- emprestada da outra origem.
    CAST(NULL AS DATE),
    NULLIF(TRIM(a.status), ''),
    NULLIF(TRIM(a.responsavel_tipo), ''),
    NULLIF(a.responsavel, 0),
    NULLIF(a.responsavel_externo_id, 0),
    NULLIF(a.servico_interno, 0),
    NULLIF(a.checado_por, 0),
    a.checado_em,
    a.aprovado,
    NULLIF(a.aprovado_por, 0),
    a.aprovado_em,
    NULLIF(a.observacao, ''),
    NULLIF(a.quemcadastrou, 0),
    a.data_cadastro,
    a.public_enabled,
    a.public_token
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_advisory_tbjobs` a
)
SELECT
  CONCAT(u.origem, ':', CAST(u.id_job AS STRING))       AS id_job_unico,
  u.origem,
  u.id_job,
  u.projeto,
  u.tipo,
  u.atividade,
  u.data_entrada,
  u.data_entrega,
  u.data_publicacao,
  u.status,
  -- Le os DOIS vocabularios. "Feito" e o "Aprovado" do modulo advisory.
  (u.status IN ('Aprovado', 'Feito'))                   AS is_concluido,
  (u.status = 'Cancelado')                              AS is_cancelado,
  u.responsavel_tipo,
  (u.responsavel_tipo = 'externo')                      AS is_responsavel_externo,
  u.id_responsavel,
  u.id_responsavel_externo,
  u.id_servico_interno,
  u.checado_por,
  u.checado_em,
  (u.checado_em IS NOT NULL)                            AS flag_checado,
  (u.aprovado = 1)                                      AS is_aprovado,
  u.aprovado_por,
  u.aprovado_em,
  u.observacao,
  u.quem_cadastrou,
  u.data_cadastro,
  -- Prazo medido, nao suposto: negativo significa entrega prevista ANTES da entrada
  -- (19 casos), que existe na origem e nao se corrige aqui.
  DATE_DIFF(u.data_entrega, u.data_entrada, DAY)        AS dias_entrada_ate_entrega,
  -- O TOKEN NAO SAI. So a existencia dele.
  (u.public_enabled = 1)                                AS flag_acesso_publico_ativo,
  (u.public_token IS NOT NULL AND u.public_token <> '') AS flag_tem_token_publico,
  CURRENT_TIMESTAMP()                                   AS _extraido_at,
  'mysql-yIOn'                                          AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(u)))                        AS _payload_hash
FROM uniao u
