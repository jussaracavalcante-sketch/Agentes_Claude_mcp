-- rfn_financeiro__contazul_categoria_mensal  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (a Trusted e L4; aqui nenhum documento nem contraparte atravessa)
-- Grao: um mes de COMPETENCIA, uma operacao (BRM/VD), um sentido, uma classe financeira e uma categoria
-- (id + nome como o movimento os carrega). Le: trs_contazul__movimento + trs_contazul__categoria.
-- Gatilho: evento em query-FDpl (rfn_financeiro__fluxo_caixa), que ja fecha a cadeia semanal do Conta Azul.
--
-- AGREGA, NAO FILTRA. Toda parcela do movimento cai em exatamente um grupo, vigente ou removida; a
-- soma de qtd_parcelas_total reproduz a Trusted linha a linha (identidade medida em 07/10/2026:
-- 7.097 = 7.097; vigente R$ 33.074.360,79; pago R$ 23.218.428,00; nao pago R$ 9.816.491,57).
--
-- R1  Dinheiro so conta se is_vigente. 1.593 de 7.097 parcelas estao removidas na origem; elas ficam
--     visiveis em qtd_removidas / valor_removido e NUNCA entram em valor_vigente.
-- R2  COMPETENCIA, nao caixa. Para caixa usar rfn_financeiro__fluxo_caixa. As duas se sobrepoem e nao
--     sao versoes do mesmo numero. Nao somar com trs_financeiro__movimento (razao do iClips) nem com
--     rfn_financeiro__receita_cliente_mensal.
-- R3  classe_financeira e parte do grao: OPERACIONAL, REPASSE_CONTA_ORDEM, FINANCEIRO, TRANSFERENCIA,
--     SOCIOS, TRIBUTO_RETIDO, DEVOLUCAO, RECEITA e SEM_CATEGORIA nao se somam como "custo da casa".
--     TRANSFERENCIA entra e sai dos dois lados e nao fecha (artefato de pareamento).
-- R4  valor_vigente e sempre positivo; valor_vigente_com_sinal soma ENTRADA (+) e SAIDA (-).
-- R5  O NOME DA CATEGORIA VEM DO MOVIMENTO, nao do cadastro. Em 10 ids o movimento carrega mais de um
--     nome para o mesmo id_categoria, e 53 ids (1.337 parcelas) nao existem no cadastro de categoria.
--     Por isso nome e id convivem no grao, e flag_id_fora_do_cadastro / flag_nome_diverge_do_cadastro
--     tornam o caso visivel. Agrupar por id junta nomes diferentes; agrupar por nome parte o mesmo
--     "Custo com time" em dois ids (6 pares de categorias com grafia identica e dois UUIDs).
-- R6  Parcela sem categoria (485) vai para o balde explicito '(sem categoria)', nunca descartada.
-- R7  flag_competencia_futura e relativa a CARGA (DATE(_extraido_at)), nao ao relogio. Ha competencia
--     ate 2033: contar mes futuro como realizado infla qualquer total do ano corrente.
--
-- LIMITES: so operacoes BRM e VD (nao ha VBOT no razao do Conta Azul) · 21% das parcelas tem categoria
-- fora do cadastro · contraparte nao entra no grao (cobre 73%).
WITH m AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_contazul__movimento`
),
c AS (
  SELECT id_categoria, nome AS nome_cadastro, flag_nome_duplicado
  FROM `vanguardamartech_trusted`.`trs_contazul__categoria`
),
j AS (
  SELECT
    m.mes_competencia,
    m.operacao,
    m.sentido,
    m.classe_financeira,
    m.id_categoria,
    COALESCE(m.categoria, '(sem categoria)') AS categoria,
    m.is_vigente,
    m.is_removido,
    m.is_quitado,
    m.valor,
    m.valor_pago,
    m.valor_nao_pago,
    m.origem_da_categoria,
    m._extraido_at,
    c.id_categoria IS NULL AND m.id_categoria IS NOT NULL AS fora_cadastro,
    c.nome_cadastro IS NOT NULL AND m.categoria IS NOT NULL AND c.nome_cadastro != m.categoria AS nome_diverge,
    c.flag_nome_duplicado
  FROM m
  LEFT JOIN c ON c.id_categoria = m.id_categoria
),
agg AS (
  SELECT
    mes_competencia,
    operacao,
    sentido,
    classe_financeira,
    COALESCE(id_categoria, '(sem categoria)') AS id_categoria,
    categoria,
    COUNT(*) AS qtd_parcelas_total,
    COUNTIF(is_vigente) AS qtd_parcelas_vigentes,
    COUNTIF(is_removido) AS qtd_removidas,
    COUNTIF(is_vigente AND is_quitado) AS qtd_quitadas,
    ROUND(SUM(IF(is_vigente, valor, 0)), 2) AS valor_vigente,
    ROUND(SUM(IF(is_vigente, valor_pago, 0)), 2) AS valor_pago_vigente,
    ROUND(SUM(IF(is_vigente, valor_nao_pago, 0)), 2) AS valor_nao_pago_vigente,
    ROUND(SUM(IF(is_vigente, valor, 0)) * IF(sentido = 'ENTRADA', 1, -1), 2) AS valor_vigente_com_sinal,
    ROUND(SUM(IF(is_removido, valor, 0)), 2) AS valor_removido,
    COUNTIF(origem_da_categoria = 'ESPELHO_MYSQL') AS qtd_nome_do_espelho,
    LOGICAL_OR(fora_cadastro) AS flag_id_fora_do_cadastro,
    LOGICAL_OR(IFNULL(nome_diverge, FALSE)) AS flag_nome_diverge_do_cadastro,
    LOGICAL_OR(IFNULL(flag_nome_duplicado, FALSE)) AS flag_nome_duplicado,
    mes_competencia > DATE_TRUNC(DATE(MAX(_extraido_at)), MONTH) AS flag_competencia_futura
  FROM j
  GROUP BY mes_competencia, operacao, sentido, classe_financeira, 5, categoria
),
final AS (
  SELECT
    CONCAT(CAST(mes_competencia AS STRING), '|', operacao, '|', sentido, '|', classe_financeira, '|', id_categoria, '|', categoria) AS id_categoria_mensal,
    a.*,
    'L3_CONFIDENTIAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz | mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
