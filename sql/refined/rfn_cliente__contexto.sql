-- rfn_cliente__contexto
-- Refined / dominio Cadastro. Grao: um cliente. Chave: id_cliente.
--
-- PONTO DE ENTRADA de contexto de cliente para aplicacao conectada na Nekt.
-- Uma linha por cliente com identidade canonica, classe (terceiro / intragrupo / teste)
-- e o historico que HOJE se consegue amarrar ao cliente por chave, nao por rotulo.
--
-- POR QUE ESTA TABELA EXISTE
-- A aplicacao precisa de lookup DETERMINISTICO por chave. A camada semantica
-- (`get_semantic_context`) e busca vetorial: devolve o documento que parece relevante,
-- nao o registro certo. Pedir "o hex da paleta do cliente X" a ela nao funciona.
-- Divisao de trabalho, medida em 2026-09-21:
--   execute_sql (esta tabela) ... fato estruturado: id, CNPJ, contagem, data, hex
--   get_semantic_context ....... prosa: biblia da voz, posicionamento, personas
--   read_file (volumes) ........ binario: logo, manual de marca, fonte tipografica
--
-- REGRA 1 -- A PONTE COM MIDIA E O CNPJ, E ELA COBRE 34 DOS 407 CLIENTES.
-- Medido em 2026-09-21: a `rfn_cadastro__conta` tem 190 contas, das quais 43 com CNPJ,
-- 34 CNPJs distintos -- e os 34 casam com cliente do canonico, 100%. A ponte nao esta
-- errada, estava DESLIGADA: aquela tabela foi publicada em 2026-09-17 antes de a coluna
-- `cnpj` materializar, e so 2 das 190 linhas tem `cliente_canonico_resolvido`. Esta
-- query faz o join que faltava, por CNPJ.
-- **NAO use `cliente_canonico_resolvido` da rfn_cadastro__conta como cobertura** -- ele
-- diz 2; o real e 34. A coluna `qtd_contas_midia` aqui e a medida honesta.
--
-- REGRA 2 -- COBERTURA BAIXA E O NUMERO CERTO, NAO DEFEITO A CONTORNAR.
-- 373 dos 407 clientes NAO tem conta de midia amarrada, e a maioria porque a conta
-- simplesmente nao tem CNPJ na origem (147 das 190). Isso se conserta no cadastro do
-- Google Ads / Meta, nao aqui. NAO casar por nome para aumentar a cobertura: medido em
-- 2026-09-21, dos 38 clientes que existem nas duas bases da casa, o nome DIVERGE em pelo
-- menos 8 (`BRAGA MOTORS` = `BMW`, `CDLM` = `CAMARA DE DIRIGENTES LOJISTAS DE MANAUS`,
-- `MOVEIS MDF DE MARIA` = `Comodare`), e `YAMAHA MOTOS MANAUS` aparece como
-- `BRAGA MOTOS - YAMAHA`, o que faria uma regra por prefixo fundir contas Braga --
-- proibido pela R-003.
--
-- REGRA 3 -- CLASSE SEPARA TERCEIRO DE CASA PROPRIA, SEM APAGAR NENHUM DOS DOIS.
-- `classe` = TERCEIRO | INTRAGRUPO | TESTE. A aplicacao que fizer relatorio de cliente
-- deve filtrar `classe = 'TERCEIRO'`; a que fizer custo interno usa INTRAGRUPO. As 3
-- empresas do grupo tem CNPJ proprio e estao declaradas abaixo por DOCUMENTO, nunca por
-- nome -- ver as armadilhas de 2026-09-21 no CLAUDE.md.
--
-- LIMITACAO -- NAO CONTORNE
-- 1. NAO HA CONTEUDO DE MARCA NESTA TABELA, e nao e esquecimento: paleta, tipografia,
--    biblia da voz, logo e manual NAO EXISTEM em nenhuma fonte conectada. Verificado em
--    2026-09-21: `get_semantic_context` para marca/voz/paleta devolve zero documentos, e
--    o catalogo nao tem nenhuma coluna de cor, logo ou tom. As unicas colunas de cor da
--    base sao `main_color`/`accent_color` dentro do struct de anuncio responsivo do
--    Google Ads -- configuracao de criativo, NAO a paleta canonica do cliente.
--    Isso e dado AUTORADO, nao extraido. Enquanto nao houver a fonte de entrada, esta
--    tabela nao finge ter as colunas: schema que promete dado inexistente e pior que
--    schema incompleto. Contrato dos campos: `docs/nekt/contexto-cliente-arquitetura.md`.
-- 2. O historico de PI entra por ROTULO, declarado em `pi_vinculado_por`. Os PIs nao tem
--    `cliente_cnpj` preenchido, entao nao ha documento para casar. Renomear o cliente no
--    PI derruba o vinculo em silencio. Zero PI NAO significa cliente sem midia off --
--    significa que o rotulo nao casou.
-- 3. `qtd_projetos` e `qtd_pecas` contam o que a origem associou ao cliente e nao fecham
--    com o total da base -- a `rfn_cadastro__cliente` declara a diferenca (1.472 linhas
--    de origem sem chave).
-- 4. Nao ha grupo economico: o campo existe no iClips e esta vazio (1 valor distinto em
--    12.106 projetos).
-- 5. A classe INTRAGRUPO esta declarada por lista de CNPJ nesta query. Quando o par
--    `rfn_cadastro__cliente_vbot` (query-NxG1) e
--    `rfn_cadastro__cliente_vanguarda_comunicacao` (query-hH5g) materializar -- criados
--    em 2026-09-21, ainda sem execucao -- trocar a lista por join nessas duas.

WITH canonico AS (
  SELECT
    id_cliente, chave_por, cnpj, cliente_nome, nomes_conhecidos,
    qtd_nomes_conhecidos, nome_tem_variacao, ids_iclips, qtd_ids_iclips,
    multiplos_cadastros_no_iclips, identidade_juridica_resolvida,
    qtd_projetos, qtd_pecas, primeira_atividade_em, ultima_atividade_em,
    data_ultima_atividade
  FROM `vanguardamartech_refined.rfn_cadastro__cliente`
),

-- REGRA 1: o join que faltava. Por CNPJ, nunca por nome.
midia AS (
  SELECT
    REGEXP_REPLACE(cnpj, r'[^0-9]', '')                       AS cnpj,
    COUNT(*)                                                  AS qtd_contas_midia,
    COUNT(DISTINCT plataforma)                                AS qtd_plataformas,
    STRING_AGG(DISTINCT plataforma, ', ' ORDER BY plataforma) AS plataformas,
    STRING_AGG(id_conta, ', ' ORDER BY id_conta)              AS contas_midia,
    COUNTIF(integrada_na_nekt)                                AS contas_integradas_nekt,
    STRING_AGG(DISTINCT moeda, ', ' ORDER BY moeda)           AS moedas
  FROM `vanguardamartech_refined.rfn_cadastro__conta`
  WHERE LENGTH(REGEXP_REPLACE(IFNULL(cnpj, ''), r'[^0-9]', '')) = 14
  GROUP BY cnpj
),

-- LIMITACAO 2: por ROTULO. Declarado, nao escondido.
pi AS (
  SELECT
    UPPER(TRIM(cliente))                                      AS rotulo,
    COUNT(*)                                                  AS qtd_pis,
    COUNTIF(NOT is_cancelado)                                  AS qtd_pis_vigentes,
    ROUND(SUM(IF(is_cancelado, 0, valor_negociado)), 2)        AS valor_pi_vigente,
    MIN(data_inicio)                                          AS pi_primeiro_inicio,
    MAX(data_inicio)                                          AS pi_ultimo_inicio,
    COUNT(DISTINCT tipo_midia)                                AS qtd_tipos_midia_off
  FROM `vanguardamartech_trusted.trs_pi__insercao`
  GROUP BY rotulo
)

SELECT
  c.id_cliente,
  c.chave_por,
  c.cnpj,
  c.cliente_nome,
  c.nomes_conhecidos,
  c.qtd_nomes_conhecidos,
  c.nome_tem_variacao,
  c.ids_iclips,
  c.qtd_ids_iclips,
  c.multiplos_cadastros_no_iclips,
  c.identidade_juridica_resolvida,

  -- REGRA 3: classe por DOCUMENTO. A aplicacao de relatorio de cliente filtra TERCEIRO.
  CASE
    WHEN c.cnpj IN ('07865616000174', '61077352000130', '26123250000102') THEN 'INTRAGRUPO'
    WHEN c.cnpj = '62361814000109' THEN 'TESTE'
    ELSE 'TERCEIRO'
  END                                                         AS classe,

  -- Historico iClips -- cobre os 407
  c.qtd_projetos,
  c.qtd_pecas,
  DATE(c.primeira_atividade_em)                               AS primeira_atividade,
  c.data_ultima_atividade                                     AS ultima_atividade,
  DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), c.data_ultima_atividade, DAY)
                                                              AS dias_sem_atividade,

  -- Midia paga -- REGRA 1, cobre 34. FALSE aqui significa "conta sem CNPJ na origem",
  -- nao "cliente sem midia".
  m.cnpj IS NOT NULL                                          AS tem_conta_de_midia,
  IFNULL(m.qtd_contas_midia, 0)                               AS qtd_contas_midia,
  IFNULL(m.qtd_plataformas, 0)                                AS qtd_plataformas_midia,
  m.plataformas                                               AS plataformas_midia,
  m.contas_midia,
  IFNULL(m.contas_integradas_nekt, 0)                         AS contas_midia_na_nekt,
  m.moedas                                                    AS moedas_midia,

  -- Midia off / PI -- LIMITACAO 2, vinculo por rotulo
  p.rotulo IS NOT NULL                                        AS tem_pi,
  IF(p.rotulo IS NOT NULL, 'ROTULO', CAST(NULL AS STRING))    AS pi_vinculado_por,
  IFNULL(p.qtd_pis, 0)                                        AS qtd_pis,
  IFNULL(p.qtd_pis_vigentes, 0)                               AS qtd_pis_vigentes,
  IFNULL(p.valor_pi_vigente, 0)                               AS valor_pi_vigente,
  p.pi_primeiro_inicio,
  p.pi_ultimo_inicio,
  IFNULL(p.qtd_tipos_midia_off, 0)                            AS qtd_tipos_midia_off,

  -- Quantas das tres superficies de historico este cliente tem amarradas.
  -- Serve para a aplicacao saber o que NAO pedir.
  CAST(c.qtd_projetos > 0 AS INT64)
    + CAST(m.cnpj IS NOT NULL AS INT64)
    + CAST(p.rotulo IS NOT NULL AS INT64)                     AS fontes_de_historico,

  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  'America/Sao_Paulo'                                         AS _fuso,
  'rfn_cadastro__cliente + rfn_cadastro__conta + trs_pi__insercao'  AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(c)))                              AS _payload_hash
FROM canonico c
LEFT JOIN midia m ON m.cnpj = c.cnpj
LEFT JOIN pi    p ON p.rotulo = UPPER(TRIM(c.cliente_nome))
