-- rfn_financeiro__receita_cliente_mensal
-- Refined / dominio Financeiro. Grao: um cliente, uma competencia.
-- Chave: id_cliente + competencia.
-- Le trs_vjob__cronograma_parcela, trs_vjob__cronograma e trs_vjob__escopo.
--
-- CLASSIFICACAO: **L3 CONFIDENTIAL** (arquitetura §31) -- carrega valor de contrato.
-- Nao expor a perfil de Marketing ou Midia sem decisao (§40).
--
-- PARA QUE SERVE: poe RECEITA e ENTREGA lado a lado por cliente e mes. E o insumo
-- direto da margem -- e **nao e a margem**, ver R1.
--
-- Na arquitetura de referencia isto e `gold/comercial/receita_cliente` somado a
-- `gold/financeiro/faturamento` (§7). O padrao de tabela larga foi mantido a pedido,
-- em vez do modelo dimensional da §8.
--
-- REGRAS DE NEGOCIO
--
-- R1 -- **ESTA TABELA NAO CALCULA MARGEM, PORQUE NAO EXISTE CUSTO.**
--   A arquitetura espera um `fact_custos` (§8) que esta base nao tem. Medido em
--   2026-09-23: o escopo do VJOB conta PECAS, nao horas, e o unico `custo_hora` da
--   base esta em `supabase_public_dim_colaborador` -- **128 de 850 pessoas (15%)**,
--   do iClips, ligavel ao VJOB **so por nome** (122 dos 166 marcadores casam, 55 com
--   custo). Sem hora gasta, custo/hora nao multiplica nada.
--   Quem precisar de margem tem de trazer custo de fora. Nao derivar daqui.
--
-- R2 -- HONORARIO E REPASSE NAO SE SOMAM COMO RECEITA DA CASA.
--   Parcela de contrato **sem fornecedor** e entrega da casa (Fee Mensal, manutencao);
--   **com fornecedor** ha um terceiro que recebe (veiculacao, producao, comissao).
--   Medido: os tipos 1-4 tem fornecedor em 100% das linhas e os tipos 5-6 em 0%.
--   `valor_honorario` R$ 19,75 mi e `valor_repasse` R$ 91,46 mi saem em colunas
--   separadas. `valor_total` existe para reconciliar com a Trusted, **nao para ser
--   lido como faturamento da agencia**. Mesmo mecanismo do `tipo_receita`
--   CLIENTE vs CONTA_ORDEM ja declarado no financeiro do Supabase.
--
-- R3 -- A GRANDEZA ADITIVA E A DA PARCELA, NUNCA O `valor` DO CONTRATO.
--   `tbcronograma.valor` e o valor de UMA parcela. Somar entre contratos da
--   R$ 84,9 mi contra os R$ 111,2 mi reais -- R$ 26,3 milhoes de diferenca.
--   Esta tabela soma `valor_parcela` da `trs_vjob__cronograma_parcela`.
--
-- R4 -- "FATURADO" NAO EXISTE NA ORIGEM; A NFSe E O PROXY, E ESTA DECLARADO.
--   `faturado = 1` em zero das 10.036 parcelas e `status` vazio em 10.007.
--   `valor_com_nfse` e `cobertura_nfse` usam a NFSe, que cobre 91% -- **e nao e a
--   mesma coisa que faturado**. A NFSe tambem nao e chave (7.977 numeros distintos
--   para 9.146 parcelas), entao nao contar notas aqui.
--
-- R5 -- COMPETENCIA FUTURA FICA MARCADA, NAO REMOVIDA.
--   Ha parcela ate 12/2027 e escopo ate 09/2027. `is_competencia_futura` acende;
--   somar sem o filtro conta mes que nao aconteceu.
--
-- R6 -- CLIENTE SEM REGISTRO DE CONCLUSAO NAO RECEBE TAXA.
--   Herda a regra da `rfn_operacao__escopo_mensal`: 86 clientes nao tem uma conclusao
--   sequer de 2025 em diante. Para eles `taxa_conclusao` e NULL, nunca zero, e
--   `receita_por_escopo_concluido` tambem -- dividir por zero registro inventa numero.
--
-- R7 -- CLIENTE E O CADASTRO, NUNCA O GRUPO (R-003).
--
-- R8 -- FULL OUTER: OS DOIS LADOS SOBREVIVEM SOZINHOS.
--   Medido em 2026-09-23: das 7.455 linhas do grao, so **1.771 tem receita E escopo**;
--   1.272 tem so receita e 4.412 so escopo. **R$ 60,36 milhoes -- mais da metade da
--   receita -- estao em cliente-mes SEM nenhum escopo.** Um INNER JOIN aqui destruiria
--   metade do dinheiro em silencio. `tem_receita` e `tem_escopo` dizem qual lado
--   sustenta cada linha.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **Isto nao e faturamento realizado.** E valor contratado por competencia. O que
--      de fato entrou esta no financeiro do Supabase (`gold_mvw_fin_cliente`), que tem
--      outra chave (razao social / `cliente_doc`) e ainda nao foi reconciliado com esta
--      tabela. **Nao somar as duas fontes** -- a casa ja tem caso registrado de dinheiro
--      contado duas vezes entre Conexa e financeiro.
--   2. **Nao existe `cliente_sk`** (arquitetura §6). O `id_cliente` aqui e o id do VJOB
--      e nao consolida iClips, Conexa nem Google Ads. 1.303 contratos e 96 clientes de
--      escopo nem cadastro tem. `flag_cliente_nao_catalogado` marca.
--   3. `receita_por_escopo_concluido` usa **so o honorario** no numerador. Dividir
--      repasse de midia por peca entregue nao significa nada.
--   4. A cobertura do carimbo de conclusao e de 84% (10.926 de 68.016 conclusoes nao
--      datam). `qtd_escopo_com_carimbo` esta na linha para a serie declarar sobre
--      quanto fala.
WITH janela AS (
  SELECT DATE_TRUNC(CURRENT_DATE('America/Sao_Paulo'), MONTH) AS mes_corrente
),
-- RECEITA: parcela e o grao do dinheiro (R3). O contrato entra so para dizer se ha
-- fornecedor, que e o que separa honorario de repasse (R2).
receita AS (
  SELECT
    c.id_cliente,
    p.competencia,
    SUM(p.valor_parcela)                                            AS valor_total,
    SUM(IF(NOT c.tem_fornecedor, p.valor_parcela, 0))               AS valor_honorario,
    SUM(IF(c.tem_fornecedor,     p.valor_parcela, 0))               AS valor_repasse,
    SUM(IF(p.tem_nfse, p.valor_parcela, 0))                         AS valor_com_nfse,
    COUNT(*)                                                        AS qtd_parcelas,
    COUNT(DISTINCT p.id_cronograma)                                 AS qtd_contratos,
    COUNTIF(p.tem_nfse)                                             AS qtd_parcelas_com_nfse,
    COUNT(DISTINCT IF(NOT c.tem_fornecedor, p.id_cronograma, NULL)) AS qtd_contratos_honorario,
    COUNT(DISTINCT c.id_fornecedor)                                 AS qtd_fornecedores,
    ANY_VALUE(c.cliente)                                            AS cliente_do_cronograma,
    ANY_VALUE(c.cliente_cnpj)                                       AS cnpj_do_cronograma,
    LOGICAL_OR(c.flag_cliente_nao_catalogado)                       AS cronograma_cliente_orfao
  FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_parcela` p
  JOIN `vanguardamartech_trusted`.`trs_vjob__cronograma` c
    ON c.id_cronograma = p.id_cronograma
  GROUP BY c.id_cliente, p.competencia
),
-- ENTREGA: o escopo mensal, no mesmo grao.
entrega AS (
  SELECT
    e.id_cliente,
    e.competencia,
    COUNT(*)                                        AS qtd_escopo_planejado,
    COUNTIF(e.is_concluido)                         AS qtd_escopo_concluido,
    COUNTIF(e.is_concluido AND e.marcado_em IS NOT NULL) AS qtd_escopo_com_carimbo,
    COUNT(DISTINCT e.id_servico)                    AS qtd_servicos,
    COUNT(DISTINCT e.id_marcado_por)                AS qtd_pessoas_marcaram,
    ANY_VALUE(e.cliente)                            AS cliente_do_escopo,
    ANY_VALUE(e.cliente_cnpj)                       AS cnpj_do_escopo,
    LOGICAL_OR(e.cliente_ativo)                     AS cliente_ativo,
    LOGICAL_OR(e.flag_cliente_nao_catalogado)       AS escopo_cliente_orfao
  FROM `vanguardamartech_trusted`.`trs_vjob__escopo` e
  GROUP BY e.id_cliente, e.competencia
),
-- R6: o cliente que nao registra conclusao nenhuma nao recebe taxa.
perfil_cliente AS (
  SELECT
    id_cliente,
    SUM(IF(competencia >= '2025-01-01' AND is_concluido, 1, 0)) AS concl_2025_em_diante,
    SUM(IF(competencia >= '2025-01-01', 1, 0))                  AS plan_2025_em_diante
  FROM `vanguardamartech_trusted`.`trs_vjob__escopo`
  GROUP BY id_cliente
)
SELECT
  CONCAT(CAST(COALESCE(r.id_cliente, e.id_cliente) AS STRING), '|',
         FORMAT_DATE('%Y-%m', COALESCE(r.competencia, e.competencia))) AS id_receita_mensal,
  COALESCE(r.id_cliente, e.id_cliente)              AS id_cliente,
  COALESCE(e.cliente_do_escopo, r.cliente_do_cronograma)   AS cliente,
  COALESCE(e.cnpj_do_escopo,    r.cnpj_do_cronograma)      AS cliente_cnpj,
  e.cliente_ativo,
  COALESCE(e.escopo_cliente_orfao, r.cronograma_cliente_orfao) AS flag_cliente_nao_catalogado,

  COALESCE(r.competencia, e.competencia)            AS competencia,
  EXTRACT(YEAR  FROM COALESCE(r.competencia, e.competencia)) AS ano,
  EXTRACT(MONTH FROM COALESCE(r.competencia, e.competencia)) AS mes,
  -- R5
  (COALESCE(r.competencia, e.competencia) > j.mes_corrente) AS is_competencia_futura,

  -- R8: qual lado sustenta a linha.
  (r.id_cliente IS NOT NULL)                        AS tem_receita,
  (e.id_cliente IS NOT NULL)                        AS tem_escopo,

  -- RECEITA. Ver R2 e R3.
  IFNULL(r.valor_total,     0)                      AS valor_total,
  IFNULL(r.valor_honorario, 0)                      AS valor_honorario,
  IFNULL(r.valor_repasse,   0)                      AS valor_repasse,
  IFNULL(r.qtd_parcelas,    0)                      AS qtd_parcelas,
  IFNULL(r.qtd_contratos,   0)                      AS qtd_contratos,
  IFNULL(r.qtd_contratos_honorario, 0)              AS qtd_contratos_honorario,
  IFNULL(r.qtd_fornecedores, 0)                     AS qtd_fornecedores,

  -- R4: proxy de faturado, declarado como proxy.
  IFNULL(r.valor_com_nfse, 0)                       AS valor_com_nfse,
  IFNULL(r.qtd_parcelas_com_nfse, 0)                AS qtd_parcelas_com_nfse,
  SAFE_DIVIDE(r.valor_com_nfse, NULLIF(r.valor_total, 0)) AS cobertura_nfse,

  -- ENTREGA.
  IFNULL(e.qtd_escopo_planejado,   0)               AS qtd_escopo_planejado,
  IFNULL(e.qtd_escopo_concluido,   0)               AS qtd_escopo_concluido,
  IFNULL(e.qtd_escopo_com_carimbo, 0)               AS qtd_escopo_com_carimbo,
  IFNULL(e.qtd_servicos,           0)               AS qtd_servicos,
  IFNULL(e.qtd_pessoas_marcaram,   0)               AS qtd_pessoas_marcaram,

  -- R6: NULL, nunca zero, para cliente que nao registra.
  IF(p.concl_2025_em_diante = 0 AND p.plan_2025_em_diante > 0,
     NULL,
     SAFE_DIVIDE(e.qtd_escopo_concluido, e.qtd_escopo_planejado)) AS taxa_conclusao,
  (p.concl_2025_em_diante = 0 AND p.plan_2025_em_diante > 0)      AS is_cliente_sem_registro,

  -- CRUZAMENTO. So o honorario no numerador -- ver limitacao 3.
  IF(p.concl_2025_em_diante = 0 AND p.plan_2025_em_diante > 0,
     NULL,
     SAFE_DIVIDE(r.valor_honorario, NULLIF(e.qtd_escopo_concluido, 0))) AS honorario_por_escopo_concluido,
  SAFE_DIVIDE(r.valor_honorario, NULLIF(e.qtd_escopo_planejado, 0))     AS honorario_por_escopo_planejado,

  'L3_CONFIDENTIAL'                                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                               AS _extraido_at,
  'mysql-yIOn'                                      AS _fonte,
  'America/Sao_Paulo'                               AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(r, e))))         AS _payload_hash
FROM receita r
-- R8: FULL OUTER de proposito. R$ 60,36 mi estao em cliente-mes sem escopo nenhum.
FULL OUTER JOIN entrega e
  ON e.id_cliente = r.id_cliente AND e.competencia = r.competencia
CROSS JOIN janela j
LEFT JOIN perfil_cliente p
  ON p.id_cliente = COALESCE(r.id_cliente, e.id_cliente)
