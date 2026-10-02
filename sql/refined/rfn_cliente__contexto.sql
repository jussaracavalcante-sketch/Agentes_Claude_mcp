-- rfn_cliente__contexto
-- Refined / dominio Cadastro. Grao: um cliente. Chave: id_cliente.
--
-- PONTO DE ENTRADA de contexto de cliente para aplicacao conectada na Nekt.
-- Identidade canonica + classe + o historico que se amarra POR CHAVE, nao por rotulo.
--
-- As tres superficies que uma aplicacao conectada le, e que NAO sao intercambiaveis:
--   execute_sql (esta tabela) ... fato estruturado: id, CNPJ, contagem, data, hex
--   get_semantic_context ....... prosa: biblia da voz, posicionamento, personas
--   read_file (volumes) ........ binario: logo, manual de marca, fonte tipografica
-- Busca vetorial devolve o documento que PARECE relevante, nao o registro certo --
-- por isso o fato estruturado mora aqui e nao num documento semantico.
--
-- REGRA 1 -- A PONTE COM MIDIA E O CNPJ, E COBRE 34 DOS 407. Medido em 2026-09-21: a
-- rfn_cadastro__conta tem 190 contas, 43 com CNPJ, 34 CNPJs distintos, e os 34 casam
-- 100% com cliente do canonico. A ponte estava DESLIGADA, nao errada: so 2 das 190
-- linhas tem cliente_canonico_resolvido, porque aquela tabela foi publicada antes de a
-- coluna cnpj materializar. NAO usar cliente_canonico_resolvido como cobertura.
--
-- REGRA 2 -- COBERTURA BAIXA E O NUMERO CERTO. 147 das 190 contas nao tem CNPJ na
-- origem; conserta-se no cadastro da plataforma, nao aqui. NAO casar por nome: o nome
-- diverge entre as bases em pelo menos 8 dos 38 casos conhecidos, e YAMAHA MOTOS MANAUS
-- aparece como BRAGA MOTOS - YAMAHA -- regra por prefixo fundiria Braga, proibido R-003.
--
-- REGRA 3 -- CLASSE POR DOCUMENTO, NUNCA POR NOME. VANGUARDA INTERNACIONAL e PARA
-- GUARDAR sao CLIENTE REAL apesar do nome; VBOT e VANGUARDA MIDIA DIGITAL/VPROMO sao
-- do grupo. Ver as armadilhas de 2026-09-21 no CLAUDE.md.
--
-- LIMITACAO 1 -- NAO HA CONTEUDO DE MARCA AQUI e nao e esquecimento: paleta, tipografia,
-- voz, logo e manual nao existem em nenhuma fonte conectada (get_semantic_context para
-- marca devolve zero; o catalogo nao tem coluna de cor). E dado AUTORADO. Esta tabela
-- nao finge ter as colunas -- contrato em docs/nekt/contexto-cliente-arquitetura.md.
-- LIMITACAO 2 -- PI entra por DOCUMENTO; so o PI SEM documento entra por ROTULO UNICO.
-- Reescrito em 2026-10-02 (antes: so rotulo, 3.132 PIs, e 25 PIs casavam com MAIS DE UM
-- cliente, contados duas vezes em valor_pi_vigente). Cada PI cai em NO MAXIMO um cliente:
-- documento do projeto do iClips, ou o do monitoramento, contra rfn_cadastro__cliente.cnpj
-- (2.932 PIs); sem documento, rotulo que case com um unico cliente (201 PIs). 215 PIs
-- ficam sem vinculo e nao sao forcados; rotulo ambiguo NUNCA desempata. pi_vinculado_por
-- diz o caminho (DOCUMENTO | ROTULO | DOCUMENTO+ROTULO). Zero PI significa "nao casou",
-- NAO "cliente sem midia off".

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

-- LIMITACAO 2: documento primeiro, rotulo unico so sem documento. Cada PI cai em no maximo um cliente.
pi_base AS (
  SELECT
    id_pi, is_cancelado, valor_negociado, data_inicio, tipo_midia,
    UPPER(TRIM(cliente)) AS rotulo,
    COALESCE(
      projeto_cliente_cnpj,
      IF(LENGTH(REGEXP_REPLACE(IFNULL(cliente_cnpj, ''), r'[^0-9]', '')) IN (11, 14),
         REGEXP_REPLACE(cliente_cnpj, r'[^0-9]', ''), NULL)) AS doc
  FROM `vanguardamartech_trusted.trs_pi__insercao`
),
-- CUIDADO: o alias NAO pode repetir o nome da coluna do HAVING, senao o BigQuery le o HAVING
-- sobre o agregado e recusa com "aggregations of aggregations".
rot_unico AS (
  SELECT UPPER(TRIM(cliente_nome)) AS rotulo, ANY_VALUE(id_cliente) AS id_r
  FROM canonico GROUP BY 1 HAVING COUNT(DISTINCT id_cliente) = 1
),
doc_cliente AS (SELECT cnpj, id_cliente AS id_d FROM canonico WHERE cnpj IS NOT NULL),
pi_vinculo AS (
  SELECT b.*, COALESCE(d.id_d, r.id_r) AS id_cliente_pi, d.id_d IS NOT NULL AS via_documento, r.id_r IS NOT NULL AS via_rotulo
  FROM pi_base b
  LEFT JOIN doc_cliente d ON d.cnpj = b.doc
  LEFT JOIN rot_unico r ON r.rotulo = b.rotulo AND b.doc IS NULL
),
pi AS (
  SELECT
    id_cliente_pi                                             AS id_cliente,
    COUNT(*)                                                  AS qtd_pis,
    COUNTIF(NOT is_cancelado)                                 AS qtd_pis_vigentes,
    ROUND(SUM(IF(is_cancelado, 0, valor_negociado)), 2)       AS valor_pi_vigente,
    MIN(data_inicio)                                          AS pi_primeiro_inicio,
    MAX(data_inicio)                                          AS pi_ultimo_inicio,
    COUNT(DISTINCT tipo_midia)                                AS qtd_tipos_midia_off,
    COUNTIF(via_documento)                                    AS qtd_pis_por_documento,
    COUNTIF(via_rotulo)                                       AS qtd_pis_por_rotulo
  FROM pi_vinculo
  WHERE id_cliente_pi IS NOT NULL
  GROUP BY id_cliente_pi
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

  -- REGRA 3: aplicacao de relatorio de cliente filtra TERCEIRO.
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

  -- Midia paga -- REGRA 1, cobre 34. FALSE significa "conta sem CNPJ na origem",
  -- NAO "cliente sem midia".
  m.cnpj IS NOT NULL                                          AS tem_conta_de_midia,
  IFNULL(m.qtd_contas_midia, 0)                               AS qtd_contas_midia,
  IFNULL(m.qtd_plataformas, 0)                                AS qtd_plataformas_midia,
  m.plataformas                                               AS plataformas_midia,
  m.contas_midia,
  IFNULL(m.contas_integradas_nekt, 0)                         AS contas_midia_na_nekt,
  m.moedas                                                    AS moedas_midia,

  -- Midia off / PI -- LIMITACAO 2, vinculo por documento (rotulo unico so sem documento)
  p.id_cliente IS NOT NULL                                    AS tem_pi,
  CASE WHEN p.qtd_pis_por_documento > 0 AND p.qtd_pis_por_rotulo > 0 THEN 'DOCUMENTO+ROTULO'
       WHEN p.qtd_pis_por_documento > 0 THEN 'DOCUMENTO'
       WHEN p.qtd_pis_por_rotulo > 0 THEN 'ROTULO' END        AS pi_vinculado_por,
  IFNULL(p.qtd_pis_por_documento, 0)                          AS qtd_pis_por_documento,
  IFNULL(p.qtd_pis_por_rotulo, 0)                             AS qtd_pis_por_rotulo,
  IFNULL(p.qtd_pis, 0)                                        AS qtd_pis,
  IFNULL(p.qtd_pis_vigentes, 0)                               AS qtd_pis_vigentes,
  IFNULL(p.valor_pi_vigente, 0)                               AS valor_pi_vigente,
  p.pi_primeiro_inicio,
  p.pi_ultimo_inicio,
  IFNULL(p.qtd_tipos_midia_off, 0)                            AS qtd_tipos_midia_off,

  -- Quantas das tres superficies de historico este cliente tem amarradas. Serve para a
  -- aplicacao saber o que NAO pedir.
  CAST(c.qtd_projetos > 0 AS INT64)
    + CAST(m.cnpj IS NOT NULL AS INT64)
    + CAST(p.id_cliente IS NOT NULL AS INT64)                 AS fontes_de_historico,

  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  'America/Sao_Paulo'                                         AS _fuso,
  'rfn_cadastro__cliente + rfn_cadastro__conta + trs_pi__insercao'  AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(c)))                              AS _payload_hash
FROM canonico c
LEFT JOIN midia m ON m.cnpj = c.cnpj
LEFT JOIN pi    p ON p.id_cliente = c.id_cliente
