-- rfn_operacao__conformidade_cliente
-- Refined / dominio Operacao. Grao: uma origem, um cliente, um mes de referencia.
-- Le trs_vjob__auditoria_cliente, trs_vjob__etapa_cliente e trs_vjob__cliente.
--
-- O QUE ESTA TABELA RESPONDE: **do que estava previsto para o cliente no mes X, quanto
-- foi marcado como feito -- e quanto foi marcado DENTRO do prazo.** Os dois instrumentos
-- de conformidade do VJOB (auditoria de servico e etapa de servico) tem a mesma forma --
-- item previsto para um cliente, com prazo, que alguem marca -- e por isso convivem numa
-- tabela so, separados por `origem`.
--
-- OS DOIS INSTRUMENTOS COBREM CLIENTES QUASE DISJUNTOS, e isso decidiu o formato.
--   Medido em 2026-09-24: AUDITORIA tem **46 clientes**, ETAPA tem **169**, e apenas
--   **17 estao nos dois** -- 29 so na auditoria, 152 so na etapa, 198 no total.
--   **Uma tabela larga com as duas lado a lado seria quase toda NULL.** Empilhar com
--   `origem` e o que representa o fato: sao dois instrumentos aplicados a populacoes
--   diferentes, nao duas medidas do mesmo cliente. **NAO somar as duas origens num
--   indicador unico de conformidade da casa** sem dizer que o denominador muda.
--
-- O ACHADO DE NEGOCIO: **a maioria das marcacoes acontece DEPOIS do prazo, nos dois.**
--   AUDITORIA: dos 1.544 itens marcados, **1.014 (65,7%) foram marcados apos o prazo**
--   e 526 ate o prazo (4 nao tem prazo para comparar).
--   ETAPA: dos 1.447 marcados, **879 (60,8%) apos** e 566 ate (2 sem data).
--   `taxa_pontualidade` mede isso por cliente e mes. Nao e atraso de ENTREGA -- e atraso
--   de REGISTRO ou de entrega, e a base nao distingue os dois. Dizer "entregou atrasado"
--   seria afirmar o que a base nao afirma.
--
-- REGRAS DE NEGOCIO
--   **R1. `mes_referencia` e o mes do PRAZO, nunca o da marcacao.** Auditoria usa
--        `prazo` (`datafinal`), etapa usa `data_etapa`. A pergunta e "do que era devido
--        no mes X, quanto saiu" -- contar pelo mes da marcacao responde outra coisa e
--        **inverte o sinal**, que e exatamente o erro que o derivado Supabase do escopo
--        produziu e esta casa ja registrou.
--        Item SEM prazo (9 na auditoria, 42 na etapa) **nao some**: entra numa linha com
--        `mes_referencia` NULL e `flag_sem_prazo` acesa. Marcar, nunca apagar.
--   **R2. O DENOMINADOR E O ITEM ATIVO, nas DUAS origens.** Item inativo nao e item
--        atrasado: ele saiu do checklist. Medido em 2026-09-24, e o padrao e identico
--        nos dois instrumentos:
--          AUDITORIA: `ativo = 1` sao **1.563 itens com 1.542 marcados (98,7%)**;
--                     `ativo = 0` sao **1.462 com apenas 2 marcados (0,1%)**.
--          ETAPA:     ativa sao **3.987 com 1.446 marcados**; inativa sao 3.795
--                     (3.790 nunca ativadas + 5 desativadas) com **1 marcacao**.
--        **Somar tudo cairia a taxa da auditoria de 98,7% para 51% sem que nada tivesse
--        deixado de ser feito.** `qtd_itens` (bruto) e `qtd_itens_ativos` convivem, e
--        `taxa_conclusao` usa o ATIVO **nos dois lados da razao**: 2 marcacoes da
--        auditoria e 1 da etapa caem sobre item inativo, contam em `qtd_marcados` e
--        ficam fora da taxa, que usa `qtd_marcados_ativos`.
--        **Eu errei isto na primeira versao desta query**, antes de publicar: tratei
--        `ativo` da auditoria como se nao significasse nada e deixei o denominador
--        bruto. A medicao acima desmentiu, e e por isso que ela existe.
--   **R3. Zero de conclusao nao e zero: e NULL.** Cliente que nao tem NENHUMA marcacao
--        em toda a janela recebe `taxa_conclusao` NULL e `is_cliente_sem_registro` acesa.
--        Zero e um numero e seria somado; NULL obriga quem le a decidir. Mesma regra da
--        `rfn_operacao__escopo_mensal`.
--        **Ao agregar, recalcule da razao de somas e exclua os clientes sem registro.**
--   **R4. `taxa_pontualidade` tem como denominador o MARCADO, nao o previsto.** Ela e
--        NULL quando nao houve marcacao no mes -- nao ha pontualidade de quem nao marcou.
--   **R5. Mes futuro entra, marcado.** Ha prazo ate 30/09/2026 na auditoria e
--        **03/11/2026 na etapa**. `is_mes_futuro` acende; nada e descartado.
--        **Toda serie precisa de recorte de janela explicito.**
--   **R6. Documento so com 14 digitos.** `cnpj_digitos` vem da `trs_vjob__cliente`, que
--        ja aplica a regra da casa. E a ponte para o `cliente_sk`.
--
-- A IDENTIDADE RESOLVE BEM NA ETAPA E MAL NA AUDITORIA -- medido, e a cobertura vai
--   junto com qualquer numero por cliente:
--     ETAPA     : 169 clientes, **132 com CNPJ de 14 digitos**; 5.989 dos 7.782 itens
--                 (77%) ligam a documento. 20 clientes e 882 itens sem cadastro.
--     AUDITORIA : 46 clientes, **apenas 17 com CNPJ**; 26 clientes e **1.372 dos 3.025
--                 itens (45,4%) sem cadastro** em `tbclientes`.
--   E o mesmo buraco de origem ja medido no escopo e no cronograma. Os joins sao LEFT e
--   as flags acendem -- **com INNER, quase metade da auditoria sumiria sem sinal**.
--
-- FUSO: NADA SE CONVERTE. As duas Trusted entregam o relogio local do MySQL intacto.
--   `DATE()` sem argumento -- passar 'America/Sao_Paulo' subtrairia 3 horas de dado que
--   ja e local, a armadilha que esta casa ja pagou sete vezes.
--
-- CLASSIFICACAO: **L2 INTERNAL.** So contagem, taxa, ids e o CNPJ do cliente (que e PJ,
--   nao pessoa). **Nenhum nome de pessoa e denormalizado aqui** -- `qtd_pessoas_marcaram`
--   e uma contagem distinta, nao uma lista. Por isso esta Refined NAO herda L4 de
--   ninguem: as duas Trusted que ela le sao L2.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **Atraso aqui e de REGISTRO ou de entrega, e a base nao separa os dois.** Um item
--      marcado depois do prazo pode ter sido feito no prazo e registrado tarde.
--   2. `id_servico` NAO e comparavel entre as origens: na auditoria sao 1.339 valores em
--      3.025 linhas (id de instancia, nao catalogo) e na etapa 67. **Nao agrupar por
--      servico atravessando `origem`.** Por isso ele nao entra no grao desta tabela.
--   3. **46 e 169 clientes nao sao a base da casa** (315 cadastros no VJOB). Estes
--      instrumentos cobrem um recorte; nao inferir cobertura de processo a partir daqui.
--   4. `qtd_pessoas_marcaram` conta `quem_marcou` distinto e **ignora as 24 linhas da
--      etapa marcadas sem marcador registrado** -- elas contam em `qtd_marcados`.
--
-- VALIDACAO 2026-09-24 -- a query inteira foi executada antes de publicar, com as duas
-- Trusted replicadas inline (nenhuma materializou ainda), e reproduziu:
--   **510 linhas e 510 chaves (origem, cliente, mes) distintas** -- 83 AUDITORIA + 427 ETAPA.
--   AUDITORIA: 46 clientes · 3.025 itens · **1.563 ativos / 1.462 inativos** ·
--     1.544 marcados dos quais **1.542 sobre item ativo** · **taxa_conclusao geral
--     98,66%** (seria 51,04% com o denominador bruto) · **pontualidade 34,07%** ·
--     3 celulas com taxa NULL · 42 celulas com cliente nao catalogado · 2 sem prazo.
--   ETAPA: 169 clientes · 7.782 itens · **3.987 ativos / 3.795 inativos** ·
--     1.447 marcados dos quais **1.446 sobre item ativo** · **taxa_conclusao geral
--     36,27%** (seria 18,59% bruta) · **pontualidade 39,12%** · 350 celulas com taxa
--     NULL · 50 com cliente nao catalogado · 22 sem prazo · 7 em mes futuro.
--   No maximo 9 pessoas distintas marcaram numa mesma celula, nas duas origens.
WITH item AS (
  -- AUDITORIA -- item de auditoria de servico. `is_feito` e `marcado_em` coincidem
  -- exatamente (1.544 e 1.544, zero excecoes), entao a marcacao sempre data a acao.
  SELECT
    'AUDITORIA'                     AS origem,
    a.id_cliente,
    a.prazo                         AS prazo,
    -- R2: o inativo sai do denominador aqui tambem. 1.462 itens inativos com 2 marcados.
    COALESCE(a.is_ativo, FALSE)     AS is_item_ativo,
    a.is_feito                      AS is_marcado,
    a.marcado_em,
    a.quem_marcou
  FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_cliente` a
  UNION ALL
  -- ETAPA -- etapa de servico. Tres estados: ativa (3.987), desativada (5) e NUNCA
  -- ATIVADA (3.790, metade da tabela). A R2 tira as duas ultimas do denominador.
  SELECT
    'ETAPA',
    e.id_cliente,
    e.data_etapa,
    -- COALESCE e obrigatorio: `is_ativa` e NULL (nao FALSE) nas 3.790 nunca ativadas,
    -- e NOT NULL continuaria NULL, deixando-as fora da contagem em vez de no inativo.
    COALESCE(e.is_ativa, FALSE),
    e.is_marcada,
    e.marcado_em,
    e.quem_marcou
  FROM `vanguardamartech_trusted`.`trs_vjob__etapa_cliente` e
),
classificado AS (
  SELECT
    i.*,
    -- R1: o mes e o do PRAZO. Item sem prazo fica com mes NULL e nao some.
    DATE_TRUNC(i.prazo, MONTH)                                   AS mes_referencia,
    (i.prazo IS NULL)                                            AS flag_sem_prazo,
    -- R4: pontualidade so existe para item marcado E com prazo.
    (i.is_marcado AND i.prazo IS NOT NULL
       AND DATE(i.marcado_em) <= i.prazo)                        AS is_marcado_ate_prazo,
    (i.is_marcado AND i.prazo IS NOT NULL
       AND DATE(i.marcado_em) >  i.prazo)                        AS is_marcado_apos_prazo
  FROM item i
),
-- R3: a janela inteira decide se o cliente tem registro, nao o mes.
registro_cliente AS (
  SELECT origem, id_cliente, LOGICAL_OR(is_marcado) AS tem_alguma_marcacao
  FROM classificado GROUP BY origem, id_cliente
),
agregado AS (
  SELECT
    c.origem,
    c.id_cliente,
    c.mes_referencia,
    LOGICAL_OR(c.flag_sem_prazo)                    AS flag_sem_prazo,
    COUNT(*)                                        AS qtd_itens,
    COUNTIF(c.is_item_ativo)                        AS qtd_itens_ativos,
    COUNTIF(NOT c.is_item_ativo)                    AS qtd_itens_inativos,
    COUNTIF(c.is_marcado)                           AS qtd_marcados,
    -- Numerador e denominador precisam falar do MESMO conjunto. 2 marcacoes da auditoria
    -- e 1 da etapa caem sobre item INATIVO; elas contam em qtd_marcados e ficam fora da
    -- taxa. Sem isto a taxa da auditoria sairia 98,78% em vez de 98,66%.
    COUNTIF(c.is_marcado AND c.is_item_ativo)       AS qtd_marcados_ativos,
    COUNTIF(c.is_marcado_ate_prazo)                 AS qtd_marcados_ate_prazo,
    COUNTIF(c.is_marcado_apos_prazo)                AS qtd_marcados_apos_prazo,
    MIN(c.marcado_em)                               AS primeira_marcacao,
    MAX(c.marcado_em)                               AS ultima_marcacao,
    COUNT(DISTINCT c.quem_marcou)                   AS qtd_pessoas_marcaram
  FROM classificado c
  GROUP BY c.origem, c.id_cliente, c.mes_referencia
)
SELECT
  a.origem,
  a.id_cliente,
  cl.cliente                                        AS cliente_nome,
  cl.cnpj_digitos,
  (cl.id_cliente IS NULL)                           AS flag_cliente_nao_catalogado,
  (cl.id_cliente IS NOT NULL
     AND cl.cnpj_digitos IS NULL)                   AS flag_cliente_sem_cnpj,
  a.mes_referencia,
  a.flag_sem_prazo,
  -- R5: mes futuro entra, marcado. Nada e descartado por data.
  COALESCE(a.mes_referencia > DATE_TRUNC(CURRENT_DATE(), MONTH), FALSE) AS is_mes_futuro,
  a.qtd_itens,
  a.qtd_itens_ativos,
  a.qtd_itens_inativos,
  a.qtd_marcados,
  a.qtd_marcados_ativos,
  a.qtd_marcados_ate_prazo,
  a.qtd_marcados_apos_prazo,
  -- R2 + R3: denominador ATIVO, e NULL (nunca zero) para cliente sem registro na janela.
  IF(NOT r.tem_alguma_marcacao OR a.qtd_itens_ativos = 0,
     NULL,
     ROUND(SAFE_DIVIDE(a.qtd_marcados_ativos, a.qtd_itens_ativos), 4))  AS taxa_conclusao,
  -- R4: denominador e o MARCADO. Sem marcacao no mes nao ha pontualidade.
  IF(a.qtd_marcados = 0,
     NULL,
     ROUND(SAFE_DIVIDE(a.qtd_marcados_ate_prazo, a.qtd_marcados), 4))  AS taxa_pontualidade,
  NOT r.tem_alguma_marcacao                         AS is_cliente_sem_registro,
  a.primeira_marcacao,
  a.ultima_marcacao,
  a.qtd_pessoas_marcaram,
  CURRENT_TIMESTAMP()                               AS _extraido_at,
  'mysql-yIOn'                                      AS _fonte
FROM agregado a
JOIN registro_cliente r
  ON r.origem = a.origem AND r.id_cliente = a.id_cliente
LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__cliente` cl
  ON cl.id_cliente = a.id_cliente
