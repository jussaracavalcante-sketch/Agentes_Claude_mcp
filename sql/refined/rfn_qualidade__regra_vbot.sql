-- rfn_qualidade__regra_vbot  ·  query-SxaY  ·  23 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra
-- (a execucao se le em _extraido_at).
-- Gatilho: evento em query-schs, ultimo elo da cadeia DIARIA do Conexa. Alerta ligado.
--
-- O QUE FICAVA DE FORA. As duas Gold da VBOT -- `rfn_financeiro__receita_vbot_mensal`
--   (query-8uTi, 2.103) e `rfn_financeiro__despesa_vbot_mensal` (query-schs, 447) --
--   foram publicadas em 28/09 e nunca rodaram, porque a `supabase-x0tz` caiu com senha
--   rejeitada em 29/09. Materializaram em 30/09 06:36, e ate aqui as duas tabelas que
--   respondem MRR, faturamento, recebimento e custo da VBOT nao tinham UMA regra.
--
-- POR QUE UMA DECIMA SUITE. O mesmo motivo das outras: a `rfn_qualidade__regra` esta com
--   57 KB e 84 regras e `update_transformation` substitui o CODIGO INTEIRO. As 10 regras
--   das TRUSTED do Conexa ja moram la; estas 23 sao das GOLD. O CONTRATO DE COLUNAS E
--   IDENTICO ao das outras nove -- um UNION ALL da o painel unico e `familia` diz de onde
--   veio cada linha.
--
-- A SUITE E O PROPRIO TESTE DE FRESCOR, e por isso NAO ha regra de carga aqui. As outras
--   suites de lote comparam `MAX(DATE(_extraido_at))` entre tabelas irmas. Aqui seria
--   redundante: QUATRO das 23 regras comparam a Gold contra a Trusted por TOTAL, e uma
--   Gold defasada divergiria da Trusted na hora. A cadeia e estritamente linear a partir
--   de uma fonte so (supabase-x0tz → mbpv → 6qKc → 54P5 → T3ct → rbJW → bZT5 → 8uTi →
--   schs), entao a suite dispara no ULTIMO elo e mede tudo recem-escrito.
--
-- A OITAVA IDENTIDADE DESTA CASA: `despesa.rateio_reproduz_o_valor_direto`. Ver o bloco
--   no proprio codigo, mais abaixo.
--
-- O ACHADO QUE MOLDOU A REGRA DA RECEITA: `valor_faturado` INCLUI cobranca cancelada e
--   `valor_recebido`/`valor_em_aberto` NAO. Ver o bloco em `faturado_decompoe_sem_cancelada`.
--
-- O QUE NAO ENTROU, E A AUSENCIA E A DECISAO:
--   Nome de CATEGORIA na despesa -- a Gold emite a categoria SEM nome de proposito: os
--     ids da despesa apontam para outro plano de contas e 13 deles nem existem no
--     catalogo de RECEITA (`dim_categoria_vbot`), entao juntar rotularia despesa com nome
--     de receita por coincidencia numerica. Regra de completude ali exigiria o que a
--     tabela decidiu NAO fazer.
--   `flag_mes_futuro`, nas duas -- e relativa a DATA DA CARGA e as tabelas sao
--     reconstruidas inteiras a cada execucao: a regra mediria o relogio, nao o dado.
--     Mesmo criterio ja aplicado ao `flag_inicio_futuro` e ao `flag_ocorrencia_futura`.
--   Margem -- `trs_conexa__despesa` NAO TEM CLIENTE, entao receita e despesa so se
--     comparam no total do mes. Nao ha identidade a testar entre as duas tabelas.
--
-- VALIDACAO: a query inteira foi rodada sobre as tabelas materializadas antes do deploy e
--   devolveu 23 regras, 23 ids distintos, CONFORME 23, ZERO falhas.
--
-- CLASSIFICACAO: L2 INTERNAL. So contagem, taxa e nome de regra. A
--   `rfn_financeiro__receita_vbot_mensal` e L4 (documento e nome de cliente, 4 deles
--   pessoa fisica) e NADA disso atravessa -- o mesmo caminho da `rfn_operacao__custo_peca`.

WITH
-- --------------------------------------------------------------------- RECEITA (10)
r_rec AS (
  SELECT 'rfn_financeiro__receita_vbot_mensal.id_receita_vbot_mensal_unico' AS id_regra,
         'Refined' AS camada, 'rfn_financeiro__receita_vbot_mensal' AS tabela,
         'Conexa' AS sistema, 'UNICIDADE' AS dimensao,
         'id_receita_vbot_mensal e unico e nunca nulo' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_receita_vbot_mensal)
           + COUNTIF(id_receita_vbot_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_vbot_mensal`

  UNION ALL
  -- A chave declara o grao. Chave incoerente parte o mesmo cliente-mes em duas linhas
  -- SEM mudar nenhum total -- o defeito ja registrado na `rfn_cadastro__cliente`.
  SELECT 'rfn_financeiro__receita_vbot_mensal.chave_concorda_com_o_grao', 'Refined',
         'rfn_financeiro__receita_vbot_mensal', 'Conexa', 'VALIDADE',
         'a chave e <id_cliente>:<AAAA-MM> do proprio grao', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(id_receita_vbot_mensal
                 <> CONCAT(CAST(id_cliente AS STRING), ':', FORMAT_DATE('%Y-%m', mes_referencia)))
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_vbot_mensal`

  UNION ALL
  -- IDENTIDADE CONDICIONAL, E A CONDICAO FOI MEDIDA, NAO SUPOSTA. `valor_faturado`
  -- INCLUI cobranca cancelada; `valor_recebido` e `valor_em_aberto` NAO. Medido em
  -- 30/09: dos 659 pares com faturamento, os 648 SEM cancelada fecham em ZERO e os 11
  -- COM cancelada falham TODOS -- nenhuma excecao em nenhuma das duas direcoes, o que e
  -- a prova de que o mecanismo e o cancelamento e nao ruido. A lacuna e R$ 18.067,93 em
  -- 8 clientes. Escrever a identidade SEM a condicao criaria falha permanente que
  -- ninguem pode resolver, que e o que ensina a ignorar a suite.
  SELECT 'rfn_financeiro__receita_vbot_mensal.faturado_decompoe_sem_cancelada', 'Refined',
         'rfn_financeiro__receita_vbot_mensal', 'Conexa', 'VALIDADE',
         'sem cobranca cancelada, recebido mais em aberto reproduz o faturado',
         'BLOQUEANTE', 1.00,
         COUNTIF(valor_faturado IS NOT NULL AND qtd_cobrancas_canceladas = 0),
         COUNTIF(valor_faturado IS NOT NULL AND qtd_cobrancas_canceladas = 0
                 AND ABS(IFNULL(valor_recebido, 0) + IFNULL(valor_em_aberto, 0)
                         - valor_faturado) > 0.005)
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_vbot_mensal`

  UNION ALL
  -- Acoplamento NULL/zero: faturado NULO e exatamente "nao houve cobranca no mes", nunca
  -- "faturou zero". 1.444 dos dois lados. Se soltar, zero vira numero e entra em media.
  SELECT 'rfn_financeiro__receita_vbot_mensal.faturado_nulo_exatamente_sem_cobranca', 'Refined',
         'rfn_financeiro__receita_vbot_mensal', 'Conexa', 'VALIDADE',
         'valor_faturado e nulo exatamente onde nao ha cobranca no mes', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF((valor_faturado IS NULL) <> (qtd_cobrancas = 0))
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_vbot_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__receita_vbot_mensal.documento_tem_forma', 'Refined',
         'rfn_financeiro__receita_vbot_mensal', 'Conexa', 'VALIDADE',
         'o documento tem 14 digitos (CNPJ) ou 11 (CPF), sem pontuacao', 'BLOQUEANTE', 1.00,
         COUNTIF(documento IS NOT NULL),
         COUNTIF(documento IS NOT NULL
                 AND (LENGTH(documento) NOT IN (14, 11)
                      OR REGEXP_CONTAINS(documento, r'[^0-9]')))
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_vbot_mensal`

  UNION ALL
  -- PJ e PF particionam e nunca se sobrepoem. CPF de 11 digitos e documento VALIDO, e
  -- foi o falso positivo dos 2.555 CPFs da `rfn_operacao__peca` que ensinou isso aqui.
  SELECT 'rfn_financeiro__receita_vbot_mensal.pj_e_pf_particionam', 'Refined',
         'rfn_financeiro__receita_vbot_mensal', 'Conexa', 'VALIDADE',
         'is_pj e is_pf concordam com o comprimento e nunca acendem juntas',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(is_pj <> (documento IS NOT NULL AND LENGTH(documento) = 14)
              OR is_pf <> (documento IS NOT NULL AND LENGTH(documento) = 11)
              OR (is_pj AND is_pf))
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_vbot_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__receita_vbot_mensal.taxa_recebimento_reproduz_a_razao', 'Refined',
         'rfn_financeiro__receita_vbot_mensal', 'Conexa', 'VALIDADE',
         'taxa_recebimento reproduz recebido sobre faturado, e nao existe sem denominador',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(taxa_recebimento IS NOT NULL
                 AND (IFNULL(valor_faturado, 0) = 0
                      OR ABS(taxa_recebimento - SAFE_DIVIDE(valor_recebido, valor_faturado)) > 0.0001))
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_vbot_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__receita_vbot_mensal.parte_nunca_excede_o_todo', 'Refined',
         'rfn_financeiro__receita_vbot_mensal', 'Conexa', 'VALIDADE',
         'titulo vencido, cobranca cancelada e venda sem cobranca nunca passam do total',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(qtd_titulos_vencidos > qtd_cobrancas
              OR qtd_cobrancas_canceladas > qtd_cobrancas
              OR qtd_quitadas_sem_valor_pago > qtd_cobrancas
              OR qtd_vendas_sem_cobranca > qtd_vendas
              OR qtd_vendas_canceladas > qtd_vendas)
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_vbot_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__receita_vbot_mensal.metrica_nao_negativa', 'Refined',
         'rfn_financeiro__receita_vbot_mensal', 'Conexa', 'VALIDADE',
         'MRR, valores e contagens nunca sao negativos', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(mrr_contratado < 0 OR valor_faturado < 0 OR valor_recebido < 0
              OR valor_em_aberto < 0 OR valor_vencido < 0 OR valor_vendas_sem_cobranca < 0
              OR qtd_cobrancas < 0 OR qtd_contratos_vigentes < 0 OR qtd_vendas < 0)
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_vbot_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__receita_vbot_mensal.mes_referencia_e_o_primeiro_dia', 'Refined',
         'rfn_financeiro__receita_vbot_mensal', 'Conexa', 'VALIDADE',
         'mes_referencia e sempre o primeiro dia do mes', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(mes_referencia IS NULL OR mes_referencia <> DATE_TRUNC(mes_referencia, MONTH))
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_vbot_mensal`
),

-- ------------------------------------------ RECEITA x TRUSTED: duas identidades (2)
-- GRAO DA REGRA: UMA LINHA, nao a linha da tabela. Mesmo desenho do
-- `caixa_reproduz_o_razao` do Conta Azul: testa-se um TOTAL contra o total do outro
-- lado, e uma unica divergencia condena a leitura inteira.
r_rec_id AS (
  -- A diferenca esta MEDIDA e nao arredondada: 873 na Gold contra 876 vigentes na
  -- Trusted sao exatamente as 3 cobrancas SEM mes de referencia, que uma tabela de grao
  -- mensal descarta por construcao. A Gold ja declarava esse descarte em palavras ("um
  -- titulo de R$ 1.376,20 sem competencia"); aqui vira teste, comparando contra
  -- "vigente E com mes".
  SELECT 'rfn_financeiro__receita_vbot_mensal.cobrancas_reproduzem_a_trusted' AS id_regra,
         'Refined' AS camada, 'rfn_financeiro__receita_vbot_mensal' AS tabela,
         'Conexa' AS sistema, 'INTEGRIDADE' AS dimensao,
         'a soma de qtd_cobrancas reproduz as cobrancas vigentes COM mes de referencia' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         1 AS linhas_avaliadas,
         IF((SELECT IFNULL(SUM(qtd_cobrancas), 0)
             FROM `vanguardamartech_refined`.`rfn_financeiro__receita_vbot_mensal`)
            = (SELECT COUNTIF(is_vigente AND mes_referencia IS NOT NULL)
               FROM `vanguardamartech_trusted`.`trs_conexa__cobranca`), 0, 1) AS linhas_falha

  UNION ALL
  SELECT 'rfn_financeiro__receita_vbot_mensal.vendas_reproduzem_a_trusted', 'Refined',
         'rfn_financeiro__receita_vbot_mensal', 'Conexa', 'INTEGRIDADE',
         'a soma de qtd_vendas reproduz as vendas vigentes da Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF((SELECT IFNULL(SUM(qtd_vendas), 0)
             FROM `vanguardamartech_refined`.`rfn_financeiro__receita_vbot_mensal`)
            = (SELECT COUNTIF(is_vigente) FROM `vanguardamartech_trusted`.`trs_conexa__venda`), 0, 1)
),

-- --------------------------------------------------------------------- DESPESA (9)
r_des AS (
  SELECT 'rfn_financeiro__despesa_vbot_mensal.id_despesa_vbot_mensal_unico' AS id_regra,
         'Refined' AS camada, 'rfn_financeiro__despesa_vbot_mensal' AS tabela,
         'Conexa' AS sistema, 'UNICIDADE' AS dimensao,
         'id_despesa_vbot_mensal e unico e nunca nulo' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_despesa_vbot_mensal)
           + COUNTIF(id_despesa_vbot_mensal IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__despesa_vbot_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__despesa_vbot_mensal.chave_concorda_com_o_grao', 'Refined',
         'rfn_financeiro__despesa_vbot_mensal', 'Conexa', 'VALIDADE',
         'a chave e <AAAA-MM>:<centro>:<categoria>:<tipo> do proprio grao',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(id_despesa_vbot_mensal
                 <> CONCAT(FORMAT_DATE('%Y-%m', mes_referencia), ':',
                           CAST(id_centro_custo AS STRING), ':',
                           CAST(id_categoria AS STRING), ':', tipo_despesa))
  FROM `vanguardamartech_refined`.`rfn_financeiro__despesa_vbot_mensal`

  UNION ALL
  -- O ACOPLAMENTO QUE SUBSTITUI A DECOMPOSICAO, E A RAZAO ESTA MEDIDA. A identidade
  -- obvia -- pago mais em aberto reproduz o valor -- NAO VALE: falha em 15 de 447, e a
  -- causa NAO e cancelamento (ha ZERO despesa cancelada nas 447). Sao dois mecanismos:
  -- 12 grupos com juros, multa ou desconto (de -R$ 73,61 a +R$ 72,99), o mesmo que a
  -- `rfn_financeiro__fluxo_caixa` ja mediu em 772 parcelas do Conta Azul; e 3 grupos da
  -- DIRETORIA EXECUTIVA com pagamento PARCIAL registrado como pago (R$ 9.000, R$ 5.000
  -- e R$ 5.000, redondos). Liquido de R$ 18.811,87. O que VALE, e vale nas duas pontas,
  -- e o acoplamento: grupo inteiramente pago tem em aberto ZERO (254 de 254) e grupo sem
  -- nenhuma paga tem em aberto igual ao valor (188 de 188). Os 5 grupos PARCIAIS ficam
  -- de fora do denominador, declarados.
  SELECT 'rfn_financeiro__despesa_vbot_mensal.aberto_concorda_com_o_pagamento', 'Refined',
         'rfn_financeiro__despesa_vbot_mensal', 'Conexa', 'VALIDADE',
         'grupo todo pago tem em aberto zero, e grupo sem pagamento tem em aberto igual ao valor',
         'BLOQUEANTE', 1.00,
         COUNTIF(qtd_pagas = qtd_despesas OR qtd_pagas = 0),
         COUNTIF((qtd_pagas = qtd_despesas AND IFNULL(valor_em_aberto, 0) <> 0)
              OR (qtd_pagas = 0 AND ABS(IFNULL(valor_em_aberto, 0) - IFNULL(valor, 0)) > 0.005))
  FROM `vanguardamartech_refined`.`rfn_financeiro__despesa_vbot_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__despesa_vbot_mensal.tipo_conhecido_e_a_flag_concorda', 'Refined',
         'rfn_financeiro__despesa_vbot_mensal', 'Conexa', 'VALIDADE',
         'tipo_despesa e fixed ou loose, e is_despesa_fixa concorda', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(tipo_despesa IS NULL OR tipo_despesa NOT IN ('fixed', 'loose')
              OR is_despesa_fixa <> (tipo_despesa = 'fixed'))
  FROM `vanguardamartech_refined`.`rfn_financeiro__despesa_vbot_mensal`

  UNION ALL
  -- O centro de custo resolve INTEIRO, zero orfaos -- ao contrario da categoria, que de
  -- proposito sai sem nome. A flag existe porque uma DIMENSAO PODE ESVAZIAR: a
  -- `github_repositories` foi de 10 linhas para ZERO quando a fonte caiu, enquanto os
  -- fatos continuaram la.
  SELECT 'rfn_financeiro__despesa_vbot_mensal.centro_catalogado', 'Refined',
         'rfn_financeiro__despesa_vbot_mensal', 'Conexa', 'INTEGRIDADE',
         'todo grupo resolve o centro de custo, e a flag concorda', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(centro_custo IS NULL
              OR flag_centro_nao_catalogado <> (centro_custo IS NULL))
  FROM `vanguardamartech_refined`.`rfn_financeiro__despesa_vbot_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__despesa_vbot_mensal.taxa_pagamento_reproduz_a_razao', 'Refined',
         'rfn_financeiro__despesa_vbot_mensal', 'Conexa', 'VALIDADE',
         'taxa_pagamento reproduz pago sobre valor, e nao existe sem denominador',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(taxa_pagamento IS NOT NULL
                 AND (IFNULL(valor, 0) = 0
                      OR ABS(taxa_pagamento - SAFE_DIVIDE(valor_pago, valor)) > 0.0001))
  FROM `vanguardamartech_refined`.`rfn_financeiro__despesa_vbot_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__despesa_vbot_mensal.parte_nunca_excede_o_todo', 'Refined',
         'rfn_financeiro__despesa_vbot_mensal', 'Conexa', 'VALIDADE',
         'paga, cancelada, vencida, CAC, rateio e fornecedor nunca passam do total do grupo',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(qtd_pagas > qtd_despesas OR qtd_canceladas > qtd_despesas
              OR qtd_vencidas > qtd_despesas OR qtd_cac > qtd_despesas
              OR qtd_com_rateio_parcial > qtd_despesas
              OR qtd_fornecedores > qtd_despesas OR qtd_subcategorias > qtd_despesas)
  FROM `vanguardamartech_refined`.`rfn_financeiro__despesa_vbot_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__despesa_vbot_mensal.metrica_nao_negativa', 'Refined',
         'rfn_financeiro__despesa_vbot_mensal', 'Conexa', 'VALIDADE',
         'valores e contagens nunca sao negativos, e o grupo nunca e vazio',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(valor < 0 OR valor_pago < 0 OR valor_em_aberto < 0 OR valor_vencido < 0
              OR qtd_despesas < 1)
  FROM `vanguardamartech_refined`.`rfn_financeiro__despesa_vbot_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__despesa_vbot_mensal.mes_referencia_e_o_primeiro_dia', 'Refined',
         'rfn_financeiro__despesa_vbot_mensal', 'Conexa', 'VALIDADE',
         'mes_referencia e sempre o primeiro dia do mes', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(mes_referencia IS NULL OR mes_referencia <> DATE_TRUNC(mes_referencia, MONTH))
  FROM `vanguardamartech_refined`.`rfn_financeiro__despesa_vbot_mensal`
),

-- ----------------------------------- DESPESA x TRUSTED: A IDENTIDADE DO RATEIO (2)
r_des_id AS (
  -- A OITAVA IDENTIDADE DESTA CASA, e a que a `trs_conexa__despesa` pedia com nome.
  -- Uma despesa pode ratear em mais de um centro de custo (`centros_custo` com
  -- `percentage`), entao a Gold EXPANDE a despesa por centro e PONDERA o valor. A
  -- estrutura permite o rateio, mas hoje `percentage` e 100 em todas as 1.222 -- e e
  -- justamente por isso que a identidade e verificavel: a expansao ponderada tem de
  -- reproduzir a soma direta da Trusted, AO CENTAVO. Medido: R$ 3.071.330,75 dos dois
  -- lados. Se um dia houver rateio real ela CONTINUA valendo, porque os pesos somam 1
  -- por despesa; o que ela pega e a expansao SEM ponderacao (multiplicaria o valor pelo
  -- numero de centros) e a ponderacao SEM expansao (atribuiria tudo a um centro so).
  -- Nenhuma das duas muda a contagem de linhas.
  SELECT 'rfn_financeiro__despesa_vbot_mensal.rateio_reproduz_o_valor_direto' AS id_regra,
         'Refined' AS camada, 'rfn_financeiro__despesa_vbot_mensal' AS tabela,
         'Conexa' AS sistema, 'VALIDADE' AS dimensao,
         'a soma do valor rateado reproduz a soma direta da Trusted, ao centavo' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         1 AS linhas_avaliadas,
         IF(ABS((SELECT IFNULL(SUM(valor), 0)
                 FROM `vanguardamartech_refined`.`rfn_financeiro__despesa_vbot_mensal`)
              - (SELECT IFNULL(SUM(IF(is_vigente, valor, 0)), 0)
                 FROM `vanguardamartech_trusted`.`trs_conexa__despesa`)) > 0.005, 1, 0) AS linhas_falha

  UNION ALL
  -- O outro lado da mesma expansao: nenhuma despesa vigente se perde e nenhuma entra
  -- duas vezes. CARDINALIDADE, nao valor -- irma da
  -- `rfn_marketing__conversao.reproduz_a_trusted_linha_a_linha`. 1.222 dos dois lados.
  SELECT 'rfn_financeiro__despesa_vbot_mensal.despesas_reproduzem_a_trusted', 'Refined',
         'rfn_financeiro__despesa_vbot_mensal', 'Conexa', 'INTEGRIDADE',
         'a soma de qtd_despesas reproduz as despesas vigentes da Trusted', 'BLOQUEANTE', 1.00,
         1,
         IF((SELECT IFNULL(SUM(qtd_despesas), 0)
             FROM `vanguardamartech_refined`.`rfn_financeiro__despesa_vbot_mensal`)
            = (SELECT COUNTIF(is_vigente) FROM `vanguardamartech_trusted`.`trs_conexa__despesa`), 0, 1)
),

todas AS (
  SELECT * FROM r_rec
  UNION ALL SELECT * FROM r_rec_id
  UNION ALL SELECT * FROM r_des
  UNION ALL SELECT * FROM r_des_id
),
avaliado AS (
  SELECT
    t.*,
    (t.linhas_avaliadas - t.linhas_falha)                       AS linhas_conformes,
    SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, NULLIF(t.linhas_avaliadas, 0))
                                                                AS taxa_conformidade,
    -- Regra sem linha para avaliar NAO passa: sai NULL, nunca TRUE.
    IF(t.linhas_avaliadas = 0, NULL,
       SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, t.linhas_avaliadas) >= t.limiar)
                                                                AS is_conforme,
    (t.linhas_avaliadas = 0)                                    AS flag_sem_linha_para_avaliar
  FROM todas t
)
SELECT
  a.*,
  CASE
    WHEN a.flag_sem_linha_para_avaliar          THEN 'SEM_DADO'
    WHEN a.is_conforme                          THEN 'CONFORME'
    WHEN a.severidade = 'BLOQUEANTE'            THEN 'FALHA_BLOQUEANTE'
    ELSE                                             'FALHA_ALERTA'
  END                                           AS resultado,
  'VBOT'                                        AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a