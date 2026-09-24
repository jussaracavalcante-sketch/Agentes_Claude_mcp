-- rfn_operacao__job
-- Refined / dominio Operacao. Grao: um job. Chave: id_job_unico = (origem, id_job).
-- Le trs_vjob__job, trs_vjob__job_tarefa e trs_vjob__usuario.
--
-- ESTENDIDA EM 2026-09-24 PARA O MODULO VIVO -- ate hoje esta tabela media um MODULO
-- APOSENTADO e ninguem via. Ela lia so `trs_vjob__job` (`tbjobs` + `tbjobsgeral`), que
-- parou de receber cadastro em **24/08/2026**. O trabalho continuou em `tarefas_tbjobs`
-- e `advisory_tbjobs` -- 1.585 jobs, o mais recente de **23/09/2026** -- e a camada
-- oficial de consumo nao enxergava nenhum deles. Quem consultasse "os jobs da casa"
-- via uma operacao parada havia um mes.
--   **A Gold estava entregando numero errado, nao apenas incompleto.** Trusted nao e
--   consumo: publicar a `trs_vjob__job_tarefa` nao consertava isto.
--
-- 1.514 + 1.585 = **3.099 jobs**, e somar NAO duplica: entre `tbjobs` e `tarefas_tbjobs`
--   ha ZERO linhas que casem por (projeto, atividade, data_cadastro) e ZERO por
--   (id, data_cadastro) -- medido em 2026-09-24. Os 1.229 ids em comum sao coincidencia
--   de sequencia numerica. E os prefixos de `origem` nao colidem (`tbjobs`,
--   `tbjobsgeral`, `TAREFAS`, `ADVISORY`), entao `id_job_unico` continua unico.
--
-- A COLUNA `modulo` E O EIXO QUE IMPORTA, e existe para que ninguem repita o erro ao
--   contrario. **Serie historica de job precisa dos dois modulos e o corte esta em
--   24/08/2026**; qualquer leitura de "produtividade atual" filtra `modulo = 'VIVO'`.
--   `origem` continua visivel com os quatro valores crus -- a grafia mista
--   (minuscula no aposentado, maiuscula no vivo) e cosmetica e NAO foi normalizada:
--   mexer nela quebraria filtro de quem ja consome. Alternativa nao tomada, declarada.
--
-- OS DOIS MODULOS TEM VOCABULARIO DE STATUS DIFERENTE -- por isso `status_origem` sai
--   cru e `status_canonico` traduz os SETE valores:
--     APOSENTADO : Feito 1.469 · A fazer 29 · Em andamento 13 · Cancelado 3
--     VIVO       : Aprovado 676 · A fazer 449 · Cancelado 192 · Feito 213 ·
--                  Em andamento 23 · Aguardando analista 6 · Aprovacao cliente 3
--   `Aprovado` (TAREFAS) e `Feito` (ADVISORY e aposentado) sao o MESMO estado final:
--   os dois viram `concluido` -- **2.358 jobs**. `Aguardando analista` e
--   `Aprovacao cliente` (9 jobs) viram `aguardando`, um canonico NOVO: nao sao
--   `pendente` (o trabalho comecou) nem `em_andamento` (esta parado esperando alguem).
--   Valor novo na origem cai em `desconhecido` e permanece legivel em `status_origem`.
--
-- `foi_checado` COBRE 4% DO MODULO VIVO, e a cobertura vai junto com o numero.
--   Medido: **ZERO das 1.329 linhas de TAREFAS tem `checado_em`**, contra 66 das 256 de
--   ADVISORY e 1.051 das 1.354 do aposentado. A etapa de checagem sumiu do fluxo novo.
--   `dias_ate_checagem` e NULL nessas linhas -- **NULL, nunca zero**: zero seria somado
--   como se a checagem tivesse sido instantanea.
--
-- **132 jobs do modulo vivo estao concluidos SEM `aprovado = 1`** (`Aprovado` ou `Feito`
--   no status, flag de aprovacao apagada). `flag_concluido_sem_aprovacao` acende neles.
--   Nao e defeito desta query -- e o estado da origem, e e exatamente o que a flag
--   existe para mostrar.
--
-- FUSO: CORRIGIDO EM 2026-09-23 -- DOIS ERROS QUE SE CANCELAVAM.
--   Esta query fazia `DATE(data_cadastro, 'America/Sao_Paulo')`, que SUBTRAI 3 horas
--   de um relogio que ja e local. Ate entao o resultado saia certo POR ACIDENTE: a
--   `trs_vjob__job` SOMAVA 3 horas e esta aqui subtraia as mesmas 3. Dois defeitos se
--   anulando. Ao consertar a Trusted contra o VJOB real, o valor passou a chegar
--   certo -- e a conversao daqui, sozinha, passaria a ERRAR: 13 dos 1.514 jobs foram
--   cadastrados entre 00:00 e 03:00 e mudariam de dia, arrastando junto
--   `mes_referencia` e `flag_entrega_antes_cadastro`.
--   **Erro compensado e o pior tipo, porque consertar metade quebra o todo.**
--   `DATE()` SEM argumento nos dois modulos -- o MySQL entrega o relogio local intacto.
--
-- CLASSIFICACAO: **L4 PERSONAL_DATA, por linhagem.** Ela denormaliza NOME de pessoa de
--   `trs_vjob__usuario` (que e L4) em quatro papeis, e `observacao` e campo livre
--   preenchido por pessoa. O nivel sobe pela linhagem e nunca desce.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **`projeto` NAO E CLIENTE.** Nos dois modulos ele e um id numerico
--      (1.585 de 1.585 no vivo, e o aposentado ja trazia `id_projeto`), e **a tabela-pai
--      de projetos nao foi localizada no catalogo**. NAO ligar a `trs_vjob__cliente` nem
--      ao `cliente_sk` por este campo.
--   2. **Colunas que so existem num modulo saem NULL no outro, e isso e ausencia
--      declarada, nao zero.** So no VIVO: `data_publicacao`, `responsavel_tipo`,
--      `id_responsavel`, `id_servico_interno`. So no APOSENTADO: `id_setor` (que a casa
--      ja registra como campo morto, constante 1 em `tbjobsgeral`).
--      **Sempre filtre `modulo` antes de agregar qualquer uma delas.**
--   3. **O responsavel aqui e o do CABECALHO, e ha um so.** O modulo vivo tem
--      `tarefas_tbjobs_responsaveis` (1.329 linhas) permitindo mais de um por job, e
--      essa tabela NAO esta tratada. Contagem por responsavel cobre o principal.
--   4. `id_servico_interno` (13 linhas) **nao tem tabela de dominio localizada**.
--   5. O token de acesso publico NAO chega aqui -- a Trusted ja o retem (§31, L5).
--
-- VALIDACAO 2026-09-24 -- a uniao inteira foi executada antes de publicar, com a
-- `trs_vjob__job_tarefa` replicada inline (ela ainda nao materializou), e reproduziu:
--   **3.099 linhas e 3.099 `id_job_unico` distintos** -- nenhuma colisao entre os
--   quatro valores de `origem`. 1.585 vivo + 1.514 aposentado.
--   **2.358 concluidos** (1.469 Feito do aposentado + 676 Aprovado + 213 Feito do vivo,
--   e a soma fecha), 9 aguardando e **ZERO em `desconhecido`** -- o CASE cobre os sete
--   valores de status que existem hoje.
--   1.246 checados (1.180 do aposentado + 66 de ADVISORY; TAREFAS contribui zero).
--   **135 concluidos sem aprovacao** (132 no vivo, 3 no aposentado).
--   27 com prazo invalido · 28 com entrega antes do cadastro.
--   **ZERO usuarios nao resolvidos** em quem cadastrou, aprovador e responsavel, contra
--   as 272 linhas de `trs_vjob__usuario`.
--   `MAX(data_cadastro_local)` passa a ser **2026-09-23** -- era 2026-08-24.
WITH base AS (
  -- MODULO APOSENTADO -- tbjobs + tbjobsgeral, parado em 24/08/2026.
  SELECT
    'APOSENTADO'                            AS modulo,
    j.origem,
    j.id_job,
    j.id_job_unico,
    j.projeto,
    j.id_projeto,
    j.tipo_codigo,
    j.status_job                            AS status_origem,
    j.atividade,
    j.observacao,
    j.data_entrada,
    j.data_entrega,
    CAST(NULL AS DATE)                      AS data_publicacao,
    j.data_cadastro,
    j.checado_em,
    j.aprovado_em,
    j.aprovado,
    j.id_quem_cadastrou,
    j.id_checado_por,
    j.id_aprovado_por,
    CAST(NULL AS STRING)                    AS responsavel_tipo,
    CAST(NULL AS INT64)                     AS id_responsavel,
    CAST(NULL AS INT64)                     AS id_servico_interno,
    j.id_setor,
    j._extraido_at,
    j._fonte
  FROM `vanguardamartech_trusted`.`trs_vjob__job` j
  UNION ALL
  -- MODULO VIVO -- tarefas_tbjobs + advisory_tbjobs, cadastro ate 23/09/2026.
  SELECT
    'VIVO',
    t.origem,
    t.id_job,
    t.id_job_unico,
    t.projeto,
    -- Mesmo tratamento do aposentado: o campo e id numerico guardado como texto.
    SAFE_CAST(t.projeto AS INT64),
    t.tipo,
    t.status,
    t.atividade,
    t.observacao,
    t.data_entrada,
    t.data_entrega,
    t.data_publicacao,
    t.data_cadastro,
    t.checado_em,
    t.aprovado_em,
    t.is_aprovado,
    t.quem_cadastrou,
    t.checado_por,
    t.aprovado_por,
    t.responsavel_tipo,
    t.id_responsavel,
    t.id_servico_interno,
    -- `id_setor` nao existe no modulo novo. NULL declarado, nunca emprestado.
    CAST(NULL AS INT64),
    t._extraido_at,
    t._fonte
  FROM `vanguardamartech_trusted`.`trs_vjob__job_tarefa` t
),
canonico AS (
  SELECT
    b.*,
    -- OS DOIS VOCABULARIOS NUM SO CANONICO. "Aprovado" (TAREFAS) e "Feito" (ADVISORY e
    -- aposentado) sao o mesmo estado final. "Aguardando" e canonico proprio: o trabalho
    -- comecou e esta parado esperando terceiro -- nao e pendente nem em andamento.
    CASE b.status_origem
      WHEN 'Feito'               THEN 'concluido'
      WHEN 'Aprovado'            THEN 'concluido'
      WHEN 'Em andamento'        THEN 'em_andamento'
      WHEN 'A fazer'             THEN 'pendente'
      WHEN 'Cancelado'           THEN 'cancelado'
      WHEN 'Aguardando analista' THEN 'aguardando'
      WHEN 'Aprovação cliente'   THEN 'aguardando'
      ELSE 'desconhecido'
    END                                                     AS status_canonico,
    -- FUSO: o VJOB grava hora local e as duas Trusted a entregam intacta. DATE() SEM
    -- argumento. Passar 'America/Sao_Paulo' aqui subtrai 3 horas -- ver o bloco acima.
    DATE(b.data_cadastro)                                   AS data_cadastro_local,
    DATE_TRUNC(DATE(b.data_cadastro), MONTH)                AS mes_referencia
  FROM base b
),
calc AS (
  SELECT
    c.*,
    DATE_DIFF(c.data_entrega, c.data_entrada, DAY)          AS prazo_bruto_dias,
    COALESCE(c.data_entrega < c.data_entrada, FALSE)        AS flag_prazo_invalido,
    COALESCE(c.data_entrega < c.data_cadastro_local, FALSE) AS flag_entrega_antes_cadastro
  FROM canonico c
)
SELECT
  c.id_job_unico,
  c.modulo,
  -- TRUE so no modulo que ainda recebe cadastro. Atalho para a leitura mais comum,
  -- sem obrigar ninguem a decorar quais origens sao quais.
  (c.modulo = 'VIVO')                                                 AS is_modulo_vivo,
  c.origem,
  c.id_job,
  c.projeto,
  c.id_projeto,
  c.tipo_codigo,
  c.status_origem,
  c.status_canonico,
  c.atividade,
  c.data_cadastro_local,
  c.mes_referencia,
  c.data_entrada,
  c.data_entrega,
  c.data_publicacao,
  IF(c.flag_prazo_invalido, NULL, c.prazo_bruto_dias)                 AS prazo_planejado_dias,
  ROUND(TIMESTAMP_DIFF(c.checado_em,  c.data_cadastro, HOUR) / 24, 2) AS dias_ate_checagem,
  ROUND(TIMESTAMP_DIFF(c.aprovado_em, c.data_cadastro, HOUR) / 24, 2) AS dias_ate_aprovacao,
  c.checado_em IS NOT NULL                                            AS foi_checado,
  c.aprovado IS TRUE                                                  AS foi_aprovado,
  c.responsavel_tipo,
  (c.responsavel_tipo = 'externo')                                    AS is_responsavel_externo,
  c.id_responsavel,   ur.nome AS responsavel_nome,
  c.id_quem_cadastrou, uc.nome AS quem_cadastrou_nome,
  c.id_checado_por,    uk.nome AS checado_por_nome,
  c.id_aprovado_por,   ua.nome AS aprovado_por_nome,
  c.id_servico_interno,
  c.id_setor,
  c.observacao,
  c.flag_prazo_invalido,
  c.flag_entrega_antes_cadastro,
  (c.status_canonico = 'concluido' AND c.aprovado IS NOT TRUE)        AS flag_concluido_sem_aprovacao,
  NOT (c.flag_prazo_invalido OR c.flag_entrega_antes_cadastro)        AS registro_confiavel,
  c._extraido_at, c._fonte
FROM calc c
LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__usuario` uc ON uc.id_usuario = c.id_quem_cadastrou
LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__usuario` uk ON uk.id_usuario = c.id_checado_por
LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__usuario` ua ON ua.id_usuario = c.id_aprovado_por
LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__usuario` ur ON ur.id_usuario = c.id_responsavel
