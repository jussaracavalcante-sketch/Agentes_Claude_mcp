-- trs_contazul__movimento  ·  query-rtu2  ·  6.768 linhas  ·  L4 PERSONAL_DATA
-- Trusted / Conta Azul. Grao: uma PARCELA financeira do ERP. Chave: id_movimento (id_parcela).
-- Origem: raw.supabase_conta_azul_ca_fato_evento_financeiro (supabase-x0tz) + espelho de
--   entidade e de categoria (mysql-yIOn). Gatilho: evento em query-PdzT.
--
-- ATENCAO AO SUJEITO — EXISTEM DOIS "CONTA AZUL" NESTA BASE:
--   (a) O ESPELHO no MySQL do VJOB (mysql_vjobvjob_2024_contazul_*): catalogo de entidades e
--       fila de envio. NAO tem valor nenhum.
--   (b) O RAZAO FINANCEIRO, que e esta tabela: 6.768 parcelas a pagar e a receber, com
--       valor, baixa, conta bancaria e conciliacao.
--   Esta Trusted usa (a) como DIMENSAO de (b) — o fato so guarda `id_pessoa` como UUID.
--
-- O ACHADO: O RAZAO MUDOU DE SISTEMA EM JUNHO/2026. Lancamentos por competencia,
--   medido em 2026-09-25:
--     2026-03  iClips   966 | Conta Azul    28
--     2026-04  iClips 1.048 | Conta Azul    58
--     2026-05  iClips   708 | Conta Azul   397
--     2026-06  iClips    13 | Conta Azul 1.120
--     2026-07  iClips     0 | Conta Azul 1.089
--     2026-08  iClips     0 | Conta Azul 1.129
--   A trs_financeiro__movimento declara a despesa "completa ate 2026-05" e trata 2026-06 em
--   diante como mes nao fechado. NAO e mes nao fechado: e HANDOFF. A janela em que a margem
--   existe (2022-12 a 2026-05) e o fim do razao do iClips, nao o fim do dado.
--   ESTA TABELA NAO ESTENDE A MARGEM SOZINHA — estender exige decidir a sobreposicao de
--   2025-12 a 2026-05, em que os dois razoes tem lancamento. Declarado, nao feito.
--
-- REGRA 1 — 37,7% DO DINHEIRO ESTA REMOVIDO NA ORIGEM. 1.518 das 6.768 parcelas tem
--   `removido_em`, somando R$ 18.769.466,63 de R$ 49.824.862,25. Somar sem filtrar infla o
--   total em 60%. Marcar, nunca apagar: a linha fica com `is_removido`/`is_vigente`. TODA
--   leitura de valor comeca por `is_vigente = TRUE`. Vivo: saida R$ 14.506.034,16, entrada
--   R$ 16.549.361,46.
-- REGRA 2 — `status_traduzido` MENTE SOBRE A DIRECAO: a origem escreve `RECEBIDO` tambem em
--   parcela A PAGAR (1.461 linhas BRM). Ali quer dizer QUITADO. `status_canonico` traduz
--   (QUITADO / QUITADO_PARCIAL / EM_ABERTO / ATRASADO / PERDIDO); string vazia e sentinela e
--   vira NULL (505 linhas); `status_traduzido_origem` preserva o cru.
-- REGRA 3 — `data_pagamento` DA ORIGEM E 100% NULL, E A DATA DA BAIXA EXISTE: zero das 6.768
--   linhas na coluna, 3.329 dentro do JSON `baixas[0].data_pagamento`. Serie de caixa sobre
--   a coluna devolve VAZIO, e vazio parece um resultado. `data_emissao` tambem e 100% NULL e
--   por isso NAO e emitida.
-- REGRA 4 — CATEGORIA POR DUAS ROTAS, declaradas em `origem_da_categoria`: o evento traz o
--   nome em `categorias[0].nome` (6.213 de 6.768), o espelho recupera mais 101, sobram 454
--   sem nome (6,7%). O espelho sozinho resolveria 5.525 e o evento sozinho 6.213 — as duas
--   juntas sao melhores que qualquer uma.
-- REGRA 5 — `classe_financeira` SEGUE O VOCABULARIO DA trs_financeiro__movimento, com DUAS
--   ADICOES declaradas:
--   - TRANSFERENCIA (115) — o Conta Azul lanca transferencia entre contas dos DOIS lados;
--     sem separar, o mesmo dinheiro entra e sai. A categoria vem em TRES grafias:
--     `transferencia entre contas`, `transferencia entre  contas` (espaco duplo) e
--     `tranferencia entre contas` (erro de digitacao). O padrao `tra%sferencia entre%contas`
--     pega as tres; `categoria` preserva a grafia crua.
--   - TRIBUTO_RETIDO (132, R$ 473.679,26) — "Impostos retidos em vendas" chega no lado A
--     RECEBER; e imposto retido, nao receita. ALTERNATIVA NAO TOMADA: deixar em RECEITA.
--   SOCIOS 133, FINANCEIRO 122, REPASSE_CONTA_ORDEM 243. NAO HA CAPEX: o plano de contas do
--   Conta Azul nao tem essa categoria; compra de equipamento fica em OPERACIONAL.
-- REGRA 6 — `valor` NUNCA E NEGATIVO. A direcao esta em `tipo`/`sentido`, nunca no sinal.
-- REGRA 7 — CONTRAPARTE POR ID, COBERTURA MEDIDA: 551 parcelas sem `id_pessoa`; das 6.217
--   com, 5.395 resolvem entidade (79,7% do total) e 4.950 resolvem DOCUMENTO (73,1%). As 822
--   que nao resolvem apontam para pessoa criada depois de 17/08/2026, quando o espelho parou
--   — `flag_contraparte_nao_catalogada` separa isso de `flag_sem_contraparte`. Join LEFT:
--   com INNER, 20% da tabela sumiria sem sinal.
-- REGRA 8 — COMPETENCIA FUTURA vai ate 2033-07-01 (serie comeca em 2025-02).
--   `flag_competencia_futura` e RELATIVA A DATA DA CARGA — para corte historico estavel,
--   comparar `data_competencia` contra a data escolhida, nunca a flag.
-- REGRA 9 — DUAS OPERACOES, NAO TRES: BRM e VD. NAO ha VBOT aqui, ao contrario da
--   supabase_gold_mvw_fin_cliente, que tem as tres.
--
-- FUSO: `data_competencia`, `data_vencimento` e a data da baixa sao DATE na origem — nao ha
--   fuso a tratar. Os timestamps de controle vem do Supabase em UTC e saem como vieram, sem
--   conversao, porque sao metadado de carga e nao evento de negocio.
--
-- LIMITACOES — NAO CONTORNE
--   1. NAO SOMAR COM supabase_gold_mvw_fin_cliente: a view e um RECORTE (so receita de
--      cliente, tres operacoes) e esta tabela e o razao inteiro (duas). Medido em 2026-06:
--      a view da R$ 1.205.190,93 de BRM contra R$ 2.370.689,64 de `receber` BRM aqui.
--   2. NAO SOMAR COM trs_financeiro__movimento sem recortar janela: os dois razoes se
--      sobrepoem de 2025-12 a 2026-05.
--   3. O espelho de entidade e de categoria esta CONGELADO em 17/08/2026 e o fato recebe
--      dado ate 15/09: a cobertura so piora enquanto a sincronizacao nao voltar.
--   4. CONTA BANCARIA E METODO SO EXISTEM ONDE HOUVE BAIXA — 3.329 de 6.768 (49,2%), 20
--      contas distintas. Nao ha conta prevista para parcela em aberto.
--   5. `id_centro_custo` sai como UUID cru: NAO HA dimensao de centro de custo nesta base
--      (2.863 linhas preenchidas, nenhuma tabela resolve).
--   6. `id_venda` (3.395) NAO foi ligado ao `contaazul_venda_id` do cronograma do VJOB
--      (143 parcelas, 105 vendas distintas) — a ponte nao foi testada aqui.
--   7. Um `id_evento` pode ter varias parcelas: 6.768 parcelas para 6.248 eventos. A
--      grandeza aditiva e a PARCELA.
--
-- L4: a contraparte traz CPF de pessoa fisica (140 entidades) e o proprio ROTULO DA
--   CATEGORIA nomeia socios — "Antecipacao de Lucros Breno Maciel" (89, R$ 822.666,68) e
--   "Antecipacao de Lucros Juarez Costa" (8, R$ 173.000). Mais folha (salarios, FGTS, vale,
--   plano de saude) com contraparte identificada. NAO publicar em painel sem filtrar
--   `is_folha_pessoal = FALSE`, e lembrar que SOCIOS carrega nome proprio mesmo com
--   contraparte PJ.

WITH entidade AS (
  SELECT
    contaazul_id,
    MAX(nome)                          AS nome,
    MAX(documento)                     AS documento,
    LOGICAL_OR(papel = 'CLIENTE')      AS is_cliente,
    LOGICAL_OR(papel = 'FORNECEDOR')   AS is_fornecedor,
    LOGICAL_OR(papel = 'VENDEDOR')     AS is_vendedor
  FROM (
    SELECT contaazul_id, nome, documento, 'CLIENTE' AS papel
      FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_clientes`
    UNION ALL
    SELECT contaazul_id, nome, documento, 'FORNECEDOR'
      FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_fornecedores`
    UNION ALL
    SELECT contaazul_id, nome, documento, 'VENDEDOR'
      FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_vendedores`
  )
  GROUP BY contaazul_id
),
base AS (
  SELECT
    e.*,
    NULLIF(JSON_VALUE(e.categorias, '$[0].nome'), '')                AS cat_evento,
    c.nome                                                           AS cat_espelho,
    JSON_VALUE(e.baixas, '$[0].conta_financeira.nome')               AS conta_bancaria,
    JSON_VALUE(e.baixas, '$[0].conta_financeira.banco')              AS banco,
    JSON_VALUE(e.baixas, '$[0].metodo_pagamento')                    AS metodo_pagamento_baixa,
    SAFE.PARSE_DATE('%F', JSON_VALUE(e.baixas, '$[0].data_pagamento')) AS data_baixa
  FROM `vanguardamartech_raw`.`supabase_conta_azul_ca_fato_evento_financeiro` e
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_categorias` c
    ON c.contaazul_id = e.id_categoria
),
nomeado AS (
  SELECT
    b.*,
    COALESCE(b.cat_evento, b.cat_espelho)                            AS categoria,
    CASE
      WHEN b.cat_evento  IS NOT NULL THEN 'EVENTO'
      WHEN b.cat_espelho IS NOT NULL THEN 'ESPELHO_MYSQL'
      ELSE 'SEM_NOME'
    END                                                              AS origem_da_categoria,
    TRIM(REGEXP_REPLACE(
      LOWER(REGEXP_REPLACE(NORMALIZE(COALESCE(b.cat_evento, b.cat_espelho), NFD), r'\pM', '')),
      r'\s+', ' '))                                                  AS categoria_normalizada
  FROM base b
),
classificado AS (
  SELECT
    n.*,
    IF(n.tipo = 'pagar', 'SAIDA', 'ENTRADA')                         AS sentido,
    CASE
      WHEN n.categoria_normalizada IS NULL                             THEN 'SEM_CATEGORIA'
      WHEN n.categoria_normalizada LIKE 'tra%sferencia entre%contas'   THEN 'TRANSFERENCIA'
      WHEN n.categoria_normalizada LIKE 'antecipacao de lucros%'
        OR n.categoria_normalizada LIKE 'participacao de socios%'
        OR n.categoria_normalizada LIKE 'retirada%'                    THEN 'SOCIOS'
      WHEN n.categoria_normalizada LIKE 'mutuo%'
        OR n.categoria_normalizada IN ('emprestimo', 'rendimentos de aplicacoes',
                                       'juros pagos', 'juros passivos', 'iof')
                                                                       THEN 'FINANCEIRO'
      WHEN n.categoria_normalizada LIKE 'repasse%'                     THEN 'REPASSE_CONTA_ORDEM'
      WHEN n.categoria_normalizada = 'impostos retidos em vendas'      THEN 'TRIBUTO_RETIDO'
      WHEN n.categoria_normalizada LIKE 'devolucao para%'              THEN 'DEVOLUCAO'
      WHEN n.categoria_normalizada = 'outras despesas nao operacionais'
                                                                       THEN 'NAO_OPERACIONAL'
      WHEN n.tipo = 'pagar'                                            THEN 'OPERACIONAL'
      ELSE                                                                  'RECEITA'
    END                                                              AS classe_financeira,
    CASE NULLIF(n.status_traduzido, '')
      WHEN 'RECEBIDO'          THEN 'QUITADO'
      WHEN 'RECEBIDO_PARCIAL'  THEN 'QUITADO_PARCIAL'
      WHEN 'EM_ABERTO'         THEN 'EM_ABERTO'
      WHEN 'ATRASADO'          THEN 'ATRASADO'
      WHEN 'PERDIDO'           THEN 'PERDIDO'
      WHEN NULL                THEN NULL
      ELSE 'OUTRO'
    END                                                              AS status_canonico,
    (n.categoria_normalizada IN (
       'salarios', 'fgts', 'fgts rescisorio', 'aviso previo/ indenizacoes',
       'provisao de ferias', 'vale alimentacao', 'vale refeicao', 'auxilio transporte',
       'auxilio educacao', 'ajuda de custo', 'plano de saude', 'comissao p/ equipe',
       'aprendiz/estagiario', 'exames ocupacionais'))                AS is_categoria_pessoal
  FROM nomeado n
),
final AS (
  SELECT
    c.id_parcela                                        AS id_movimento,
    c.id_evento,
    c.operacao,
    c.tipo                                              AS tipo_origem,
    c.sentido,
    c.descricao,

    c.classe_financeira,
    c.categoria,
    c.categoria_normalizada,
    c.origem_da_categoria,
    c.id_categoria,
    (c.categoria IS NULL)                               AS flag_sem_categoria,
    c.is_categoria_pessoal,
    -- a porta que impede expor remuneracao individual por engano
    (c.sentido = 'SAIDA' AND c.is_categoria_pessoal
      AND LENGTH(REGEXP_REPLACE(COALESCE(e.documento, ''), r'[^0-9]', '')) = 11)
                                                        AS is_folha_pessoal,

    -- as portas de entrada de qualquer leitura financeira desta tabela
    (c.removido_em IS NULL)                             AS is_vigente,
    (c.removido_em IS NOT NULL)                         AS is_removido,
    (c.removido_em IS NULL AND c.sentido = 'SAIDA'  AND c.classe_financeira = 'OPERACIONAL')
                                                        AS is_custo_operacional,
    (c.removido_em IS NULL AND c.sentido = 'ENTRADA' AND c.classe_financeira = 'RECEITA')
                                                        AS is_receita_operacional,

    c.status                                            AS status_origem,
    NULLIF(c.status_traduzido, '')                      AS status_traduzido_origem,
    c.status_canonico,
    (c.status_canonico IN ('QUITADO', 'QUITADO_PARCIAL'))
                                                        AS is_quitado,

    c.id_pessoa                                         AS id_entidade_contaazul,
    e.nome                                              AS contraparte,
    NULLIF(REGEXP_REPLACE(COALESCE(e.documento, ''), r'[^0-9]', ''), '')
                                                        AS contraparte_documento_origem,
    IF(LENGTH(REGEXP_REPLACE(COALESCE(e.documento, ''), r'[^0-9]', '')) IN (11, 14),
       REGEXP_REPLACE(e.documento, r'[^0-9]', ''), NULL)
                                                        AS contraparte_documento,
    (LENGTH(REGEXP_REPLACE(COALESCE(e.documento, ''), r'[^0-9]', '')) = 14)
                                                        AS contraparte_is_pj,
    (LENGTH(REGEXP_REPLACE(COALESCE(e.documento, ''), r'[^0-9]', '')) = 11)
                                                        AS contraparte_is_pf,
    e.is_cliente                                        AS contraparte_is_cliente,
    e.is_fornecedor                                     AS contraparte_is_fornecedor,
    (c.id_pessoa IS NULL)                               AS flag_sem_contraparte,
    (c.id_pessoa IS NOT NULL AND e.contaazul_id IS NULL)
                                                        AS flag_contraparte_nao_catalogada,

    c.data_competencia,
    DATE_TRUNC(c.data_competencia, MONTH)               AS mes_competencia,
    c.data_vencimento,
    -- ATENCAO: a coluna data_pagamento da origem e 100% NULL. A data real da baixa
    -- so existe dentro do JSON `baixas`.
    c.data_baixa                                        AS data_pagamento,
    (c.data_baixa IS NOT NULL)                          AS tem_baixa,
    (c.data_competencia > CURRENT_DATE('America/Sao_Paulo'))
                                                        AS flag_competencia_futura,

    c.valor,
    c.valor_pago,
    c.valor_nao_pago,
    c.conta_bancaria,
    c.banco,
    COALESCE(c.metodo_pagamento_baixa, c.metodo_pagamento) AS metodo_pagamento,
    c.id_centro_custo,
    c.id_venda,
    (c.id_venda IS NOT NULL)                            AS tem_venda,
    c.conciliado                                        AS is_conciliado,
    c.flag_migrado                                      AS is_migrado,
    c.fonte_erp,
    c.removido_em,
    c.data_criacao,
    c.ca_updated_at,
    c.processed_at
  FROM classificado c
  LEFT JOIN entidade e
    ON e.contaazul_id = c.id_pessoa
)
SELECT
  f.*,
  'L4_PERSONAL_DATA'                            AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz | mysql-yIOn'                  AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                AS _payload_hash
FROM final f
