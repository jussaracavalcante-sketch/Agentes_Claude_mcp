-- trs_financeiro__movimento
-- Trusted / Financeiro. Grao: um movimento financeiro do iClips. Chave: id_movimento.
-- Origem: vanguardamartech_raw.supabase_public_fato_movimento_financeiro (fonte supabase-x0tz).
--
-- POR QUE ESTA TABELA EXISTE
--   E o fact_custos que faltava (ADR-0010, divergencia 5). Sem ela nao existe base de
--   custo nenhuma nesta casa: o custo por hora cobre 1,2% das pecas e nao soma por mes.
--   Aqui esta a despesa REAL da agencia, por competencia, de 2019 em diante.
--
-- CHAVE PROVADA: `codigo` e unico -- 45.154 valores distintos em 45.154 linhas
--   (medido em 2026-09-23). Nao precisa de chave composta.
--
-- CLASSIFICACAO -- A REGRA QUE IMPEDE SOMAR COISAS DIFERENTES
--   `classe_financeira` separa o que a casa GASTA do que ela apenas REPASSA, do que
--   ela DISTRIBUI e do que e INVESTIMENTO. A separacao e por categoria e esta abaixo,
--   nome a nome. E o mesmo mecanismo que `tipo_receita` CLIENTE vs CONTA_ORDEM ja faz
--   no financeiro e que `tem_fornecedor` faz no cronograma do VJOB: sem ela, o custo
--   operacional da casa (R$ 29,8 mi) e lido como R$ 46,8 mi, 57% a mais.
--     REPASSE_CONTA_ORDEM . Impulsionamento Por Conta E Ordem, nas duas pontas.
--                           R$ 7,79 mi de saida e R$ 8,12 mi de entrada. Dinheiro de
--                           terceiro passando pela conta -- nao e custo nem receita.
--     SOCIOS .............. Retiradas Socios, R$ 7,21 mi. E distribuicao de resultado,
--                           nao custo de producao. Entra depois da margem, nao antes.
--     FINANCEIRO .......... Emprestimos e Financiamentos, Resultado Financeiro.
--     CAPEX ............... Capex, R$ 0,80 mi. Investimento, nao despesa do periodo.
--     DEVOLUCAO ........... Devolucoes para Clientes. Reduz receita, nao aumenta custo.
--     NAO_OPERACIONAL ..... RECEITAS NAO OPERACIONAIS.
--     INATIVO ............. qualquer categoria que comeca com "INATIVO".
--     OPERACIONAL ......... todo o resto na SAIDA. Pessoal (R$ 20,2 mi), Tributos,
--                           Despesas Gerais, TI, Servicos contratados, Custos gerais,
--                           Ocupacao, Manutencao, Utilidades, Viagens, Marketing.
--     RECEITA ............. todo o resto na ENTRADA. Fee, Midia Off, Midia On, OS,
--                           SAAS, Desenvolvimento Web, Consultoria, Vpromo.
--   ESCOLHA DECLARADA: `Tributos` (R$ 4,34 mi) entra em OPERACIONAL. A alternativa
--   NAO tomada era trata-lo como deducao de receita. Como o tributo da casa e custo
--   de operar e nao repasse de terceiro, ele fica no custo -- quem preferir a outra
--   leitura filtra por `categoria = 'Tributos'`, que continua visivel na linha.
--
-- SENTIDO E PROJECAO SAO COISAS SEPARADAS. `tipo` da origem mistura as duas:
--   "Saida"/"Entrada" sao realizados e "A Pagar"/"A Receber" sao projecao. Aqui
--   `sentido` diz a direcao (SAIDA/ENTRADA) e `is_projecao` diz se ja aconteceu.
--   Somar sem filtrar `is_projecao` conta futuro como passado: 836 lancamentos a
--   pagar chegam ate 2030-03 e 833 a receber ate 2027-04.
--
-- SINAL: a origem ja traz saida NEGATIVA e entrada POSITIVA. O sinal e PRESERVADO em
--   `valor` e `valor_abs` traz o modulo. Nao inverter -- somar `valor` de tudo da o
--   resultado liquido, que e o comportamento esperado.
--
-- FUSO: competencia, vencimento, pagamento e emissao sao DATE na origem -- nao ha
--   armadilha de fuso nelas. `created_at` e `processed_at` sao instantes.
--
-- CLASSIFICACAO: **L4 -- PERSONAL_DATA** (ADR-0010 sec. 31). Esta tabela NAO e so
--   financeira: ela carrega **FOLHA DE PAGAMENTO NOMINAL**. Medido em 2026-09-23 na
--   origem: 6.429 linhas tem CPF no lugar do CNPJ, 304 CPFs distintos, e a maior parte
--   e a categoria `Pessoal` -- **4.944 linhas, 277 CPFs, R$ 15.707.213,45**, ou seja
--   quanto cada pessoa recebeu, mes a mes, identificada. Mais `Retiradas Socios`, com
--   **595 linhas e 7 CPFs somando R$ 5.614.132,45**.
--   O documento NAO e removido porque e a chave: 35 CPFs sao CLIENTE PESSOA FISICA com
--   R$ 451.991,17 de receita, e sem ele a rentabilidade deles desaparece. O que a
--   tabela faz e tornar o caso VISIVEL e filtravel -- `contraparte_is_pf` e
--   `is_folha_pessoal` existem para que ninguem exponha folha por engano.
--   **Nao publicar esta tabela em painel sem filtrar `is_folha_pessoal = FALSE`.**
--   Sec. 30.3 da arquitetura: "acessar dado pessoal -> restrito".
--
-- CENTRO DE CUSTO NAO SUSTENTA RATEIO: preenchido em 3.626 de 45.154 (8%), com 56
--   valores. A coluna fica, mas nao ha como ratear despesa por area com 8%.
WITH origem AS (
  SELECT
    codigo,
    NULLIF(TRIM(titulo), '')                    AS titulo,
    NULLIF(TRIM(descricao), '')                 AS descricao,
    NULLIF(TRIM(origem_destino), '')            AS contraparte,
    NULLIF(TRIM(razao_social), '')              AS contraparte_razao_social,
    -- identidade por documento, nunca por rotulo
    NULLIF(REGEXP_REPLACE(COALESCE(cpf_cnpj, ''), r'[^0-9]', ''), '') AS contraparte_documento,
    TRIM(tipo)                                  AS tipo_origem,
    NULLIF(TRIM(condicao), '')                  AS condicao,
    competencia,
    vencimento                                  AS dt_vencimento,
    pagamento                                   AS dt_pagamento,
    data_emissao_nf                             AS dt_emissao_nf,
    NULLIF(TRIM(num_documento), '')             AS num_documento,
    valor_bruto_nf,
    NULLIF(TRIM(discriminacao_nota), '')        AS discriminacao_nota,
    NULLIF(TRIM(categoria), '')                 AS categoria,
    NULLIF(TRIM(subcategoria), '')              AS subcategoria,
    NULLIF(TRIM(relacao), '')                   AS relacao,
    NULLIF(TRIM(conta), '')                     AS conta,
    NULLIF(TRIM(centro_custos), '')             AS centro_custos,
    multa, desconto, outras_retencoes, irrf, issrf, porcentagem_imposto,
    valor,
    flag_projecao                               AS is_projecao,
    created_at, processed_at
  FROM `vanguardamartech_raw`.`supabase_public_fato_movimento_financeiro`
),
classificado AS (
  SELECT
    o.*,
    IF(o.tipo_origem IN ('Saída', 'A Pagar'), 'SAIDA', 'ENTRADA')  AS sentido,
    CASE
      WHEN STARTS_WITH(UPPER(COALESCE(o.categoria, '')), 'INATIVO')          THEN 'INATIVO'
      WHEN UPPER(COALESCE(o.categoria, '')) LIKE 'IMPULSIONAMENTO POR CONTA E ORDEM%'
                                                                            THEN 'REPASSE_CONTA_ORDEM'
      WHEN o.categoria = 'Retiradas Sócios'                                 THEN 'SOCIOS'
      WHEN o.categoria IN ('Empréstimos e Financiamentos', 'Resultado Financeiro')
                                                                            THEN 'FINANCEIRO'
      WHEN o.categoria = 'Capex'                                            THEN 'CAPEX'
      WHEN o.categoria = 'Devoluções para Clientes'                         THEN 'DEVOLUCAO'
      WHEN o.categoria = 'RECEITAS NÃO OPERACIONAIS'                        THEN 'NAO_OPERACIONAL'
      WHEN o.categoria IS NULL                                              THEN 'SEM_CATEGORIA'
      WHEN o.tipo_origem IN ('Saída', 'A Pagar')                            THEN 'OPERACIONAL'
      ELSE                                                                       'RECEITA'
    END                                                                     AS classe_financeira
  FROM origem o
),
final AS (
  SELECT
    CAST(c.codigo AS STRING)                      AS id_movimento,
    c.titulo,
    c.descricao,
    c.contraparte,
    c.contraparte_razao_social,
    c.contraparte_documento,
    (LENGTH(COALESCE(c.contraparte_documento, '')) = 14) AS contraparte_is_pj,
    (LENGTH(COALESCE(c.contraparte_documento, '')) = 11) AS contraparte_is_pf,
    -- L4: a porta que impede expor folha de pagamento por engano
    (c.sentido = 'SAIDA' AND c.categoria = 'Pessoal'
      AND LENGTH(COALESCE(c.contraparte_documento, '')) = 11) AS is_folha_pessoal,

    c.tipo_origem,
    c.sentido,
    c.is_projecao,
    (NOT c.is_projecao)                           AS is_realizado,
    c.classe_financeira,
    -- a porta de entrada de qualquer base de custo desta casa
    (c.sentido = 'SAIDA' AND c.classe_financeira = 'OPERACIONAL' AND NOT c.is_projecao)
                                                  AS is_custo_operacional,
    (c.sentido = 'ENTRADA' AND c.classe_financeira = 'RECEITA' AND NOT c.is_projecao)
                                                  AS is_receita_operacional,

    c.categoria,
    c.subcategoria,
    c.relacao,
    c.conta,
    c.centro_custos,
    (c.centro_custos IS NULL)                     AS flag_sem_centro_custo,

    c.competencia,
    DATE_TRUNC(c.competencia, MONTH)              AS mes_competencia,
    c.dt_vencimento,
    c.dt_pagamento,
    c.dt_emissao_nf,
    c.num_documento,
    c.discriminacao_nota,

    c.valor,
    ABS(c.valor)                                  AS valor_abs,
    c.valor_bruto_nf,
    c.multa, c.desconto, c.outras_retencoes, c.irrf, c.issrf, c.porcentagem_imposto,

    c.created_at,
    c.processed_at
  FROM classificado c
)
SELECT
  f.*,
  CURRENT_TIMESTAMP()                             AS _extraido_at,
  'supabase-x0tz'                                 AS _fonte,
  'America/Sao_Paulo'                             AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                  AS _payload_hash
FROM final f
