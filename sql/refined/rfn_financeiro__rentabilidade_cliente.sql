-- rfn_financeiro__rentabilidade_cliente
-- Refined / dominio Financeiro. Grao: um cliente (documento) em uma competencia.
-- Chave: documento + mes_competencia.
-- Le rfn_operacao__custo_peca (custo) e trs_financeiro__movimento (receita).
--
-- PARA QUE SERVE
--   E a margem por cliente. Ela so existe desde 2026-09-23, quando o custo por peca
--   substituiu o custo por hora -- que cobria 0,8% das pecas e nao somava por mes.
--   Os dois lados agora saem da MESMA base financeira (fato_movimento_financeiro),
--   com a mesma classificacao, a mesma janela e a mesma chave.
--
-- REGRAS DE NEGOCIO
--
-- R1 -- A CHAVE E O DOCUMENTO, NUNCA O ROTULO.
--   No financeiro a empresa entra pela RAZAO SOCIAL: a Vanguarda Comunicacao aparece
--   como "B. R. M. COSTA DE LIMA E CIA SOCIEDADE SIMPLES PURA" e o CNPJ
--   16.665.666/0001-07 entra como "EF LOCACAO DE IMOVEIS PROPRIOS LTDA.", que nao
--   contem nenhuma das suas tres marcas. Filtrar por nome erra pelos dois lados.
--   Os dois rotulos ficam na linha -- `cliente_nome_iclips` e
--   `cliente_razao_social_financeiro` -- e NUNCA sao fundidos nem usados como chave.
--   Nada de agrupar por grupo economico aqui (R-003): quem quiser o consolidado
--   agrupa na leitura.
--
-- R2 -- FULL OUTER E OBRIGATORIO, E O TAMANHO DO QUE ELE SALVA ESTA MEDIDO.
--   Dos 4.545 pares (cliente, mes) da janela, apenas 1.924 tem os dois lados.
--   1.125 tem SO custo e 1.496 tem SO receita. Um INNER JOIN descartaria 58% das
--   linhas, sem sinal nenhum. Boa parte do descasamento e so competencia -- a peca sai
--   num mes e a nota no seguinte -- e e exatamente por isso que existe a R5.
--
-- R3 -- EXISTEM DUAS MARGENS, E ISSO NAO E INDECISAO -- E O QUE A BASE PERMITE AFIRMAR.
--   A receita operacional da janela e R$ 35,60 mi, e ela se parte em duas naturezas:
--     servico proprio . Fee R$ 16,94 mi + OS R$ 1,09 mi + SAAS R$ 0,40 mi +
--                       Desenvolvimento Web R$ 0,24 mi + Consultoria + Vpromo +
--                       Custo Interno R$ 0,82 mi + Outras R$ 0,82 mi  = R$ 20,31 mi
--     midia ........... Midia Off + Midia On                          = R$ 15,51 mi
--   **A linha de midia nao tem saida correspondente nesta base.** O custo operacional
--   total da janela e R$ 29,85 mi e nele nao ha nenhuma categoria de veiculacao --
--   Pessoal sozinho e R$ 20,2 mi. O repasse de veiculacao vive no cronograma do VJOB,
--   onde os tipos com fornecedor somam R$ 91,46 mi.
--   Entao ou (a) a linha de midia aqui e COMISSAO/BV, ja liquida, e `margem_total` e a
--   certa; ou (b) ela e valor BRUTO do cliente, e `margem_total` esta inflada em ate
--   R$ 15,51 mi. **A base nao decide isso**, e por isso as duas margens saem lado a
--   lado. E a distancia entre elas NAO e um detalhe, esta medida:
--       margem_total ..... +R$ 5.833.203,89   (16,4% da receita)
--       margem_servico ... -R$ 9.674.317,82
--   O sinal se INVERTE entre as duas leituras. `margem_servico` e o piso conservador,
--   `margem_total` e o teto, e a verdade esta no quanto da linha de midia e BV.
--   Quem souber a resposta escolhe a coluna -- ninguem precisa recalcular nada.
--
-- R4 -- MARGEM DE UM LADO SO NAO E MARGEM.
--   Quando falta receita no mes, a margem NAO e o custo negativo; quando falta peca,
--   a margem NAO e a receita inteira. Nos dois casos `margem_mes_*` sai NULL e
--   `motivo_margem_mes_indisponivel` diz qual lado faltou. Zero seria somado.
--   Isso e a mesma regra do "zero de conclusao nao e zero, e NULL" da
--   rfn_operacao__escopo_mensal.
--
-- R5 -- A MARGEM ROBUSTA E A DA JANELA, E ELA VIAJA NA LINHA.
--   O descasamento mes a mes e enorme e em boa parte e so competencia: a peca sai num
--   mes e a nota no seguinte. Por isso cada linha carrega tambem `receita_janela`,
--   `custo_janela` e `margem_janela_*` do MESMO cliente somados sobre toda a janela --
--   ali o descasamento se resolve sozinho. **Para ranking de cliente, use as colunas
--   de janela**; as mensais servem para ver o comportamento dentro dela.
--
-- R6 -- O CUSTO E RATEIO, NAO MEDICAO (herdado da rfn_operacao__custo_peca).
--   Ele responde "quanto do custo da casa coube a este cliente", nao "quanto este
--   cliente consumiu". E cliente que fatura sem ter peca no iClips fica com custo
--   NULL -- nao com custo zero, que o faria parecer 100% de margem.
--
-- LIMITACOES -- NAO CONTORNE
--   1. JANELA 2022-12 a 2026-05, herdada do custo. Fora dela nao ha margem.
--   2. A receita aqui NAO e a mesma da `supabase_gold_mvw_fin_cliente`: aquela view
--      da R$ 33,88 mi de `tipo_receita = CLIENTE` na mesma janela, contra R$ 35,60 mi
--      aqui, porque ela separa `BV` (R$ 2,60 mi) como terceira natureza e esta Trusted
--      ainda nao tem como separar -- o BV esta dentro de `Midia Off` na origem. Os dois
--      numeros nao competem: um separa BV, o outro nao.
--   3. CONTA E ORDEM ESTA FORA DOS DOIS LADOS, de proposito. R$ 7,82 mi de saida e
--      R$ 8,15 mi de entrada de impulsionamento por conta e ordem sao dinheiro de
--      terceiro passando pela conta. Somar qualquer um dos dois quebra a margem.
--   4. Retirada de socios (R$ 9,16 mi) NAO e custo e nao entra. Ela sai DEPOIS da
--      margem, nao antes.
--   5. 42 pares (cliente, mes) tem custo e NENHUM CNPJ -- sao as 2.258 pecas cujo
--      cliente o iClips nao resolve, carregando R$ 798.941,16. Elas NAO sao
--      descartadas: caem numa linha por mes com `flag_sem_documento` acesa e
--      `documento` NULL. Somar a coluna de custo sem olhar a flag mistura um balde de
--      clientes desconhecidos com um cliente real.
WITH
-- A janela NAO e escrita a mao: sao exatamente as competencias em que o custo existe,
-- que a rfn_operacao__custo_peca ja decidiu pela sua regra R2 (mes fechado). A receita
-- e recortada por ela, senao entrariam meses de 2019 a 2022 com margem NULL por falta
-- de custo -- ruido que parece cliente sem margem.
janela AS (
  SELECT DISTINCT mes_referencia AS mes_competencia
  FROM `vanguardamartech_refined`.`rfn_operacao__custo_peca`
  WHERE custo_peca IS NOT NULL
),
custo AS (
  SELECT
    NULLIF(cliente_cnpj, '')                       AS documento,
    mes_referencia                                 AS mes_competencia,
    ANY_VALUE(cliente_nome)                        AS cliente_nome_iclips,
    COUNT(*)                                       AS qtd_pecas,
    SUM(custo_peca)                                AS custo_producao,
    COUNTIF(valor_tabela_peca IS NOT NULL)         AS qtd_pecas_com_valor,
    SUM(valor_tabela_peca)                         AS valor_tabela_pecas,
    LOGICAL_OR(teve_retrabalho)                    AS teve_retrabalho
  FROM `vanguardamartech_refined`.`rfn_operacao__custo_peca`
  -- so peca com custo atribuido: fora da janela o custo e NULL por construcao
  WHERE custo_peca IS NOT NULL
  GROUP BY 1, 2
),
receita AS (
  SELECT
    contraparte_documento                          AS documento,
    mes_competencia,
    ANY_VALUE(contraparte_razao_social)            AS cliente_razao_social_financeiro,
    ANY_VALUE(contraparte)                         AS cliente_rotulo_financeiro,
    SUM(valor_abs)                                 AS receita_total,
    SUM(IF(categoria = 'Fee',                     valor_abs, 0)) AS receita_fee,
    SUM(IF(categoria = 'Mídia Off',               valor_abs, 0)) AS receita_midia_off,
    SUM(IF(categoria = 'Mídia On',                valor_abs, 0)) AS receita_midia_on,
    SUM(IF(categoria = 'Ordem de Serviço (OS)',   valor_abs, 0)) AS receita_os,
    SUM(IF(categoria = 'SAAS',                    valor_abs, 0)) AS receita_saas,
    SUM(IF(categoria = 'Desenvolvimento Web',     valor_abs, 0)) AS receita_dev_web,
    SUM(IF(categoria NOT IN ('Fee','Mídia Off','Mídia On','Ordem de Serviço (OS)',
                             'SAAS','Desenvolvimento Web'), valor_abs, 0)) AS receita_outras,
    COUNT(*)                                       AS qtd_lancamentos_receita
  FROM `vanguardamartech_trusted`.`trs_financeiro__movimento` m
  -- INNER com a janela: so competencia que tem custo fechado do outro lado
  JOIN janela j ON j.mes_competencia = m.mes_competencia
  WHERE m.is_receita_operacional
    AND m.contraparte_documento IS NOT NULL
  GROUP BY 1, 2
),
-- R2: FULL OUTER. Um INNER descartaria 58% das linhas e 41% do dinheiro.
par AS (
  SELECT
    COALESCE(c.documento, r.documento)             AS documento,
    COALESCE(c.mes_competencia, r.mes_competencia) AS mes_competencia,
    c.cliente_nome_iclips,
    r.cliente_razao_social_financeiro,
    r.cliente_rotulo_financeiro,
    c.qtd_pecas,
    c.qtd_pecas_com_valor,
    c.valor_tabela_pecas,
    c.custo_producao,
    c.teve_retrabalho,
    r.receita_total,
    r.receita_fee, r.receita_midia_off, r.receita_midia_on,
    r.receita_os, r.receita_saas, r.receita_dev_web, r.receita_outras,
    r.qtd_lancamentos_receita
  FROM custo c
  FULL OUTER JOIN receita r
    ON r.documento = c.documento
   AND r.mes_competencia = c.mes_competencia
),
-- R5: a janela inteira por cliente, denormalizada em cada linha.
janela_cliente AS (
  SELECT
    documento,
    SUM(custo_producao)                            AS custo_janela,
    SUM(receita_total)                             AS receita_janela,
    SUM(COALESCE(receita_midia_off, 0) + COALESCE(receita_midia_on, 0)) AS receita_midia_janela,
    SUM(qtd_pecas)                                 AS qtd_pecas_janela,
    COUNTIF(custo_producao IS NOT NULL)            AS meses_com_peca,
    COUNTIF(receita_total IS NOT NULL)             AS meses_com_receita,
    MIN(mes_competencia)                           AS primeiro_mes,
    MAX(mes_competencia)                           AS ultimo_mes
  FROM par
  GROUP BY documento
),
final AS (
  SELECT
    CONCAT(COALESCE(p.documento, 'SEM_DOCUMENTO'), '|',
           FORMAT_DATE('%Y-%m', p.mes_competencia)) AS id_rentabilidade,
    p.documento,
    (p.documento IS NULL)                          AS flag_sem_documento,
    (LENGTH(p.documento) = 14)                     AS is_pj,
    -- R1: dois rotulos, nunca fundidos, nunca chave
    p.cliente_nome_iclips,
    p.cliente_razao_social_financeiro,
    p.cliente_rotulo_financeiro,

    p.mes_competencia,
    EXTRACT(YEAR  FROM p.mes_competencia)          AS ano,
    EXTRACT(MONTH FROM p.mes_competencia)          AS mes,

    -- producao
    p.qtd_pecas,
    p.qtd_pecas_com_valor,
    p.valor_tabela_pecas,
    p.custo_producao,
    p.teve_retrabalho,

    -- receita, aberta por natureza (R3)
    p.receita_total,
    p.receita_fee,
    p.receita_midia_off,
    p.receita_midia_on,
    p.receita_os,
    p.receita_saas,
    p.receita_dev_web,
    p.receita_outras,
    p.qtd_lancamentos_receita,
    (COALESCE(p.receita_midia_off, 0) + COALESCE(p.receita_midia_on, 0)) AS receita_midia,
    IF(p.receita_total IS NULL, NULL,
       p.receita_total - COALESCE(p.receita_midia_off, 0) - COALESCE(p.receita_midia_on, 0))
                                                   AS receita_servico,

    -- R3 + R4: as duas margens do mes, NULL quando falta um lado
    IF(p.custo_producao IS NULL OR p.receita_total IS NULL, NULL,
       p.receita_total - p.custo_producao)         AS margem_mes_total,
    IF(p.custo_producao IS NULL OR p.receita_total IS NULL, NULL,
       SAFE_DIVIDE(p.receita_total - p.custo_producao, p.receita_total))
                                                   AS margem_mes_total_pct,
    IF(p.custo_producao IS NULL OR p.receita_total IS NULL, NULL,
       (p.receita_total - COALESCE(p.receita_midia_off,0) - COALESCE(p.receita_midia_on,0))
         - p.custo_producao)                       AS margem_mes_servico,
    IF(p.custo_producao IS NULL OR p.receita_total IS NULL, NULL,
       SAFE_DIVIDE((p.receita_total - COALESCE(p.receita_midia_off,0) - COALESCE(p.receita_midia_on,0))
                     - p.custo_producao,
                   NULLIF(p.receita_total - COALESCE(p.receita_midia_off,0) - COALESCE(p.receita_midia_on,0), 0)))
                                                   AS margem_mes_servico_pct,
    CASE
      WHEN p.custo_producao IS NULL AND p.receita_total IS NULL THEN 'SEM_OS_DOIS_LADOS'
      WHEN p.custo_producao IS NULL                             THEN 'MES_SEM_PECA_NO_ICLIPS'
      WHEN p.receita_total  IS NULL                             THEN 'MES_SEM_RECEITA_NO_FINANCEIRO'
      ELSE NULL
    END                                            AS motivo_margem_mes_indisponivel,

    -- R5: a janela inteira, que e o numero robusto para ranking
    j.qtd_pecas_janela,
    j.custo_janela,
    j.receita_janela,
    j.receita_midia_janela,
    IF(j.receita_janela IS NULL, NULL, j.receita_janela - COALESCE(j.receita_midia_janela, 0))
                                                   AS receita_servico_janela,
    IF(j.custo_janela IS NULL OR j.receita_janela IS NULL, NULL,
       j.receita_janela - j.custo_janela)           AS margem_janela_total,
    IF(j.custo_janela IS NULL OR j.receita_janela IS NULL, NULL,
       SAFE_DIVIDE(j.receita_janela - j.custo_janela, j.receita_janela))
                                                   AS margem_janela_total_pct,
    IF(j.custo_janela IS NULL OR j.receita_janela IS NULL, NULL,
       (j.receita_janela - COALESCE(j.receita_midia_janela,0)) - j.custo_janela)
                                                   AS margem_janela_servico,
    IF(j.custo_janela IS NULL OR j.receita_janela IS NULL, NULL,
       SAFE_DIVIDE((j.receita_janela - COALESCE(j.receita_midia_janela,0)) - j.custo_janela,
                   NULLIF(j.receita_janela - COALESCE(j.receita_midia_janela,0), 0)))
                                                   AS margem_janela_servico_pct,
    j.meses_com_peca,
    j.meses_com_receita,
    j.primeiro_mes,
    j.ultimo_mes
  FROM par p
  -- COALESCE nos dois lados: o balde sem documento tambem tem janela propria
  LEFT JOIN janela_cliente j
    ON COALESCE(j.documento, 'SEM_DOCUMENTO') = COALESCE(p.documento, 'SEM_DOCUMENTO')
)
SELECT
  f.*,
  CURRENT_TIMESTAMP()                              AS _extraido_at,
  'supabase-x0tz'                                  AS _fonte,
  'America/Sao_Paulo'                              AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                   AS _payload_hash
FROM final f
