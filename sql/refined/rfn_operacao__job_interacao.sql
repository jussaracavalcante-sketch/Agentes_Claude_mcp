-- rfn_operacao__job_interacao
-- PUBLICADA em 2026-09-28 como query-c1x0, camada Refined, folder operacao.
-- Grao: um JOB (`id_job_unico`). 3.188 linhas, uma por job da rfn_operacao__job.
-- L4 PERSONAL_DATA por linhagem -- o comentario de job e texto livre de pessoa.
-- Responde: QUAIS jobs tiveram conversa, quantos anexos carregam, e quanto tempo
-- levou para alguem falar sobre eles.
-- Origem: rfn_operacao__job (3.188) + quatro satelites que nao tinham camada de
-- consumo -- trs_vjob__job_comentario (1.333), __job_comentario_cliente (22),
-- __job_arquivo (1.007) e __comentario_arquivo (771).
--
-- FECHA QUATRO TRUSTED DE UMA VEZ. Todas as quatro eram lidas apenas pela suite de
-- qualidade; nenhuma tinha Refined.
--
-- REGRAS DE NEGOCIO
-- 1. O UNIVERSO E O JOB, e ele vem da rfn_operacao__job -- nao da uniao dos
--    satelites. Job sem nenhuma interacao existe e aparece com zero. Partir dos
--    satelites daria 754 jobs com comentario e esconderia os 2.434 sem nenhum.
-- 2. COMENTARIO INTERNO E COMENTARIO DE CLIENTE SAO DUAS COLUNAS, e a soma delas sai
--    declarada em `qtd_comentarios_total`. Sao populacoes DISJUNTAS -- 1.333 internos
--    em quatro origens e 22 de cliente numa quinta -- entao somar e correto. O que
--    nao e correto e ler so uma: a casa ja registrou que "quem contar conversa por
--    job precisa das duas".
-- 3. ANEXO DE JOB E ANEXO DE COMENTARIO TAMBEM SAO DOIS, pelo mesmo motivo do
--    precedente: o pai e outro. O anexo de comentario sobe ate o job pelo comentario,
--    e a ponte e exata -- **685 dos 771 casam por (origem, id_comentario), zero
--    orfaos**. Os outros **86 nao tem comentario-pai** (sao os do fluxo de upload por
--    token, e a Trusted ja mediu que token e sem-pai sao o mesmo conjunto): eles NAO
--    chegam a job nenhum e ficam fora desta tabela.
--    A ARITMETICA DOS DOIS LADOS, medida: dos 1.007 anexos de job, **978 chegam** e
--    **29 nao** -- sao os `flag_anexo_sem_job`, upload por token que nunca foi amarrado
--    a job. Dos 685 anexos de comentario com pai, **684 chegam**: o que falta pende de
--    um dos 4 comentarios de job nao catalogado da REGRA 6. Total de anexo do VJOB
--    continua sendo 1.007 + 771 = 1.778; o que chega a um job e 978 + 684 = 1.662.
-- 4. COMENTARIO VAZIO NAO E CONVERSA. A Trusted mede 120 comentarios sem texto (15,7%
--    no modulo aposentado, 2,7% no de tarefas). `qtd_comentarios_internos_vazios` sai
--    ao lado para que a contagem possa ser descontada, e `flag_teve_conversa` exige
--    comentario COM texto.
-- 5. `dias_ate_o_primeiro_comentario` E NULL, NUNCA ZERO, quando nao houve comentario.
--    Zero significaria "comentaram no mesmo dia", que e outra coisa.
-- 6. O JOB NAO CATALOGADO DO SATELITE FICA FORA, e a conta esta declarada: 4
--    comentarios internos apontam para job que a Refined de job nao tem
--    (`flag_job_nao_catalogado` da Trusted). O join e a partir do JOB, entao eles
--    simplesmente nao aparecem -- e por isso a soma de `qtd_comentarios_internos`
--    devolve 1.329, nao 1.333.
--
-- LIMITACOES MEDIDAS -- NAO CONTORNE
-- 1. A COBERTURA E BAIXA E E O NUMERO CERTO: **754 dos 3.188 jobs (23,7%) tem algum
--    comentario interno**, 674 (21,1%) tem anexo de job e **apenas 16 (0,5%) tem
--    comentario de cliente**. **1.940 jobs (60,9%) nao tem interacao NENHUMA** --
--    nem comentario, nem anexo. Job sem conversa e a regra, nao a excecao, e
--    `flag_sem_interacao` existe para que isso seja filtravel em vez de deduzido.
-- 2. `qtd_anexos_de_comentario` DEPENDE DE O COMENTARIO EXISTIR. Se um dia a Trusted
--    de comentario perder uma origem, o anexo dela some daqui sem a contagem de jobs
--    mudar -- e por isso a ponte esta medida acima e virou regra da suite.
-- 3. TEMPO ATE O PRIMEIRO COMENTARIO NAO E TEMPO DE RESPOSTA. Nao ha destinatario,
--    nao ha pergunta, nao ha leitura. E so a distancia entre o cadastro do job e a
--    primeira vez que alguem escreveu nele.
-- 4. `editado_em` SO EXISTE NO MODULO DE TAREFAS -- a Trusted ja declara que nas
--    outras origens e ausencia de coluna, nao ausencia de edicao. Por isso aqui sai
--    `qtd_comentarios_com_edicao_rastreavel` ao lado de `qtd_comentarios_editados`:
--    a razao entre os dois e a unica leitura honesta de "quanto se edita".
-- 5. NAO SOMAR COM `rfn_operacao__job`: aquela e uma linha por job com o job; esta e
--    uma linha por job com a interacao. Sao a mesma populacao vista de dois lados, e
--    o join entre elas e 1:1 por `id_job_unico`.
--
-- VALIDACAO (2026-09-28, sobre as tabelas materializadas): 3.188 linhas, 3.188 chaves
-- distintas, uma por job -- nem uma a mais que a rfn_operacao__job. Somas conferidas
-- contra as Trusted, e cada diferenca tem causa declarada: comentario interno
-- **1.329** (1.333 menos os 4 de job nao catalogado), comentario de cliente **22**
-- (22 de 22), anexo de job **978** (1.007 menos os 29 sem job), anexo de comentario
-- **684** (685 com pai menos 1 cujo comentario e de job nao catalogado).
-- ZERO jobs com `dias_ate_o_primeiro_comentario` preenchido e sem comentario, ZERO
-- com comentario e sem a data, e ZERO valores negativos -- nenhum comentario nasce
-- antes do job. Faixa de 0 a 53 dias.
--
-- Gatilho: evento em query-ijFf (trs_vjob__job_comentario_cliente), ultimo elo da
-- cadeia de interacao. A cadeia foi LINEARIZADA em 2026-09-28: `query-8QxL` e
-- `query-D6HS` disparavam EM PARALELO em `query-tfHg` junto com a `rfn_operacao__job`,
-- e esta tabela le as cinco -- evento em paralelo nao garante ordem.
-- Agora: tfHg -> wpYP -> 8QxL -> D6HS -> uR7K -> ijFf -> esta.
WITH job AS (
  SELECT
    id_job_unico, modulo, is_modulo_vivo, origem, id_job, atividade,
    status_canonico, data_cadastro_local, mes_referencia,
    id_responsavel, responsavel_nome
  FROM `vanguardamartech_refined`.`rfn_operacao__job`
),
com_int AS (
  SELECT
    id_job_unico,
    COUNT(*)                                   AS qtd_comentarios_internos,
    COUNTIF(flag_comentario_vazio)             AS qtd_comentarios_internos_vazios,
    COUNTIF(NOT flag_comentario_vazio)         AS qtd_comentarios_internos_com_texto,
    COUNT(DISTINCT id_autor)                   AS qtd_autores_internos,
    SUM(comprimento_texto)                     AS soma_caracteres_comentario,
    MIN(criado_em)                             AS primeiro_comentario_interno_em,
    MAX(criado_em)                             AS ultimo_comentario_interno_em,
    COUNTIF(flag_editado)                      AS qtd_comentarios_editados,
    COUNTIF(flag_edicao_rastreavel)            AS qtd_comentarios_com_edicao_rastreavel
  FROM `vanguardamartech_trusted`.`trs_vjob__job_comentario`
  GROUP BY 1
),
com_cli AS (
  SELECT
    id_job_unico,
    COUNT(*)                                   AS qtd_comentarios_cliente,
    COUNT(DISTINCT autor_nome_na_origem)       AS qtd_autores_cliente,
    MIN(comentado_em)                          AS primeiro_comentario_cliente_em,
    MAX(comentado_em)                          AS ultimo_comentario_cliente_em
  FROM `vanguardamartech_trusted`.`trs_vjob__job_comentario_cliente`
  GROUP BY 1
),
arq_job AS (
  SELECT
    id_job_unico,
    COUNT(*)                                   AS qtd_anexos_de_job,
    COUNT(DISTINCT categoria_arquivo)          AS qtd_categorias_de_anexo,
    MIN(data_upload)                           AS primeiro_anexo_em,
    MAX(data_upload)                           AS ultimo_anexo_em
  FROM `vanguardamartech_trusted`.`trs_vjob__job_arquivo`
  GROUP BY 1
),
-- REGRA 3 -- o anexo de comentario sobe ate o job PELO comentario. 685 de 771 casam;
-- os 86 sem comentario-pai nao chegam a job nenhum e ficam fora.
arq_com AS (
  SELECT
    c.id_job_unico,
    COUNT(*)                                   AS qtd_anexos_de_comentario
  FROM `vanguardamartech_trusted`.`trs_vjob__comentario_arquivo` ca
  JOIN `vanguardamartech_trusted`.`trs_vjob__job_comentario` c
    ON c.origem = ca.origem
   AND CAST(c.id_comentario AS STRING) = CAST(ca.id_comentario AS STRING)
  GROUP BY 1
)
SELECT
  j.id_job_unico,
  j.modulo,
  j.is_modulo_vivo,
  j.origem,
  j.id_job,
  j.atividade,
  j.status_canonico,
  j.data_cadastro_local,
  j.mes_referencia,
  j.id_responsavel,
  j.responsavel_nome,

  -- REGRA 2 -- interno e cliente, separados e somados.
  IFNULL(ci.qtd_comentarios_internos, 0)               AS qtd_comentarios_internos,
  IFNULL(ci.qtd_comentarios_internos_vazios, 0)        AS qtd_comentarios_internos_vazios,
  IFNULL(ci.qtd_comentarios_internos_com_texto, 0)     AS qtd_comentarios_internos_com_texto,
  IFNULL(cc.qtd_comentarios_cliente, 0)                AS qtd_comentarios_cliente,
  IFNULL(ci.qtd_comentarios_internos, 0)
    + IFNULL(cc.qtd_comentarios_cliente, 0)            AS qtd_comentarios_total,

  IFNULL(ci.qtd_autores_internos, 0)                   AS qtd_autores_internos,
  IFNULL(cc.qtd_autores_cliente, 0)                    AS qtd_autores_cliente,
  ci.soma_caracteres_comentario,
  -- REGRA 4 -- a razao de edicao so e honesta sobre o que a origem rastreia.
  IFNULL(ci.qtd_comentarios_editados, 0)               AS qtd_comentarios_editados,
  IFNULL(ci.qtd_comentarios_com_edicao_rastreavel, 0)  AS qtd_comentarios_com_edicao_rastreavel,

  ci.primeiro_comentario_interno_em,
  ci.ultimo_comentario_interno_em,
  cc.primeiro_comentario_cliente_em,
  cc.ultimo_comentario_cliente_em,

  -- REGRA 3 -- os dois anexos, separados e somados.
  IFNULL(aj.qtd_anexos_de_job, 0)                      AS qtd_anexos_de_job,
  IFNULL(ac.qtd_anexos_de_comentario, 0)               AS qtd_anexos_de_comentario,
  IFNULL(aj.qtd_anexos_de_job, 0)
    + IFNULL(ac.qtd_anexos_de_comentario, 0)           AS qtd_anexos_total,
  IFNULL(aj.qtd_categorias_de_anexo, 0)                AS qtd_categorias_de_anexo,
  aj.primeiro_anexo_em,
  aj.ultimo_anexo_em,

  -- REGRA 5 -- sem comentario, NULL. Nunca zero.
  IF(ci.primeiro_comentario_interno_em IS NULL, NULL,
     DATE_DIFF(DATE(ci.primeiro_comentario_interno_em), j.data_cadastro_local, DAY))
                                                       AS dias_ate_o_primeiro_comentario,

  (IFNULL(ci.qtd_comentarios_internos_com_texto, 0) > 0) AS flag_teve_conversa,
  (IFNULL(cc.qtd_comentarios_cliente, 0) > 0)            AS flag_teve_voz_do_cliente,
  (IFNULL(ci.qtd_comentarios_internos, 0) = 0
   AND IFNULL(cc.qtd_comentarios_cliente, 0) = 0
   AND IFNULL(aj.qtd_anexos_de_job, 0) = 0
   AND IFNULL(ac.qtd_anexos_de_comentario, 0) = 0)       AS flag_sem_interacao,

  'L4_PERSONAL_DATA'                                     AS classificacao_dado,
  CURRENT_TIMESTAMP()                                    AS _extraido_at
FROM job j
LEFT JOIN com_int ci USING (id_job_unico)
LEFT JOIN com_cli cc USING (id_job_unico)
LEFT JOIN arq_job aj USING (id_job_unico)
LEFT JOIN arq_com ac USING (id_job_unico)
