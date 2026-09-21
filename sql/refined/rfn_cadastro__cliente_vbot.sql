-- rfn_cadastro__cliente_vbot
-- Refined / dominio Cadastro. Grao: um cadastro da VBOT como cliente, por sistema.
-- Chave: id_cadastro = sistema + id no sistema.
--
-- A VBOT (CNPJ 61.077.352/0001-30) e empresa do grupo Vanguarda e ao mesmo tempo
-- cliente da agencia. Esta tabela reune TODOS os cadastros dela, para que o trabalho
-- e o custo intragrupo possam ser separados na leitura sem serem apagados na ingestao.
-- Par: rfn_cadastro__cliente_vanguarda_comunicacao, mesmo formato.
--
-- REGRA 1 -- A CHAVE E O CNPJ OU O ID DO SISTEMA, NUNCA O ROTULO, e a coluna
-- chave_por diz qual valeu linha a linha. Medido em 2026-09-21 na base irma: no
-- financeiro a Vanguarda Comunicacao entra pela RAZAO SOCIAL, e um filtro por nome
-- perde R$ 47.544,32. O mesmo risco vale aqui.
--
-- REGRA 2 -- NAO CONFUNDIR COM AS OUTRAS EMPRESAS DO GRUPO NEM COM CLIENTE REAL.
-- Ficam FORA desta tabela, de proposito, cada um com CNPJ proprio:
--   VANGUARDA COMUNICACAO ... 07.865.616/0001-74 -> tabela propria (a tabela par).
--   VANGUARDA MIDIA DIGITAL / VPROMO ... 26.123.250/0001-02, ids iClips 1511 e 3893.
--     Sao a MESMA pessoa juridica com dois cadastros, e NAO sao Vanguarda Comunicacao.
--     Terceira empresa do grupo, sem tabela pedida. NAO fundir por conter 'VANGUARDA'.
--   VANGUARDA INTERNACIONAL ... 59.772.810/0001-09 -> CLIENTE REAL. Entrega de
--     agencia: projetos LAVENDER (onboarding, on/social, off), 21 atividades em 6
--     departamentos. Compartilha apenas a palavra 'VANGUARDA'.
--   CLIENTE TESTE ... 62.361.814/0001-09 -> artefato de teste, nao e a VBOT.
--   TESTE HUGO SENNA ... VJOB id_cliente 146 -> teste sobre nome de cliente real.
--
-- REGRA 3 -- O CADASTRO E DECLARADO PELA CHAVE, O VOLUME E MEDIDO NA ORIGEM a cada
-- execucao. Cadastro que sair da origem deixa de produzir linha; cadastro novo com o
-- mesmo CNPJ entra sozinho. Nenhum numero desta tabela e digitado.
--
-- CADASTROS CONFERIDOS EM 2026-09-21
--   ICLIPS 3552 ... 23 projetos, 160 pecas   ICLIPS 3894 ... 1 projeto, 1 peca
--   VJOB   130  ... 1.263 escopos, 1.099 concluidos, cliente_ativo = true
--   PI          ... 1 PI, R$ 5.720,00 (Outdoor, COMPUGRAF, 15/06/2026)
--   CONEXA      ... NAO TEM CADASTRO. Verificado: nenhum registro em
--                   dim_cliente_vbot com este CNPJ. Coerente -- a VBOT opera o
--                   Conexa, nao e cliente nele.
--   FINANCEIRO  ... NAO TEM LANCAMENTO em gold_mvw_fin_cliente com este documento.
--
-- LIMITACAO -- NAO CONTORNE
-- 1. A linha de PI e chaveada por ROTULO, nao por documento: os PIs intragrupo tem
--    cliente_cnpj VAZIO na origem (medido: o 1 da VBOT e os 7 de CLIENTE TESTE).
--    Nao existe id nem CNPJ para casar. Renomear o cliente no PI derruba esta linha
--    em silencio. E a unica chave fraca da tabela e esta declarada em chave_por.
-- 2. O PI 22557 tem numero_projeto 29677 e tem_projeto_no_iclips = false -- o numero
--    nao casa com projeto do iClips. A linha de PI nao se soma as do iClips.
-- 3. As colunas de volume NAO se somam entre sistemas: projeto, peca, escopo,
--    cobranca, PI e lancamento sao graos diferentes. Somar da numero sem significado.
-- 4. Ausencia de linha de um sistema significa "sem cadastro naquele sistema", nao
--    "volume zero". Os dois casos conferidos acima (Conexa e Financeiro) estao no
--    bloco de cadastros conferidos justamente para nao virarem duvida depois.

WITH
-- ICLIPS -- chave: CNPJ do cadastro. Nunca o rotulo.
ic_proj AS (
  SELECT cliente_id AS id_no_sistema,
         ANY_VALUE(cliente_nome)        AS rotulo,
         COUNT(DISTINCT id_projeto)     AS qtd_projetos,
         MAX(DATE(data_entrada))        AS ultima
  FROM `vanguardamartech_trusted.trs_iclips__projeto`
  WHERE REGEXP_REPLACE(IFNULL(cliente_cnpj,''), r'[^0-9]','') = '61077352000130'
  GROUP BY cliente_id
),
ic_pecas AS (
  SELECT id_cliente_iclips AS id_no_sistema,
         COUNT(DISTINCT id_job_peca)              AS qtd_pecas,
         MAX(DATE(etapa_amostrada_play_inicio))   AS ultima
  FROM `vanguardamartech_trusted.trs_iclips__peca_atributo`
  WHERE REGEXP_REPLACE(IFNULL(cliente_cnpj,''), r'[^0-9]','') = '61077352000130'
  GROUP BY id_cliente_iclips
),
iclips AS (
  SELECT
    'ICLIPS'                                   AS sistema,
    COALESCE(p.id_no_sistema, c.id_no_sistema) AS id_no_sistema,
    'CNPJ'                                     AS chave_por,
    p.rotulo                                   AS rotulo_na_origem,
    CAST(NULL AS BOOL)                         AS ativo_na_origem,
    IFNULL(p.qtd_projetos, 0)                  AS qtd_projetos_iclips,
    IFNULL(c.qtd_pecas, 0)                     AS qtd_pecas_iclips,
    0 AS qtd_escopos_vjob, 0 AS qtd_concluidos_vjob,
    0 AS qtd_cobrancas_conexa, 0.0 AS valor_conexa,
    0 AS qtd_pis, 0.0 AS valor_pi,
    0 AS qtd_lancamentos_fin, 0.0 AS valor_fin,
    GREATEST(IFNULL(p.ultima, DATE '1900-01-01'), IFNULL(c.ultima, DATE '1900-01-01')) AS ultima_atividade
  FROM ic_proj p FULL OUTER JOIN ic_pecas c USING (id_no_sistema)
),

-- VJOB -- chave: id_cliente. A tabela-pai de cliente do VJOB nao existe no catalogo,
-- entao nao ha CNPJ para conferir; o id e o que ha, e o silver ja resolveu o nome.
vjob AS (
  SELECT
    'VJOB'                          AS sistema,
    CAST(id_cliente AS STRING)      AS id_no_sistema,
    'ID_SISTEMA'                    AS chave_por,
    ANY_VALUE(cliente_nome)         AS rotulo_na_origem,
    LOGICAL_OR(cliente_ativo)       AS ativo_na_origem,
    0, 0,
    COUNT(*)                        AS qtd_escopos_vjob,
    COUNTIF(concluido)              AS qtd_concluidos_vjob,
    0, 0.0, 0, 0.0, 0, 0.0,
    MAX(datafinal)                  AS ultima_atividade
  FROM `vanguardamartech_raw.supabase_silver_vjob_escopo`
  WHERE id_cliente IN (130)
  GROUP BY id_cliente
),

-- CONEXA -- chave: CNPJ do cadastro na base de clientes da operacao VBOT.
conexa AS (
  SELECT
    'CONEXA'                                   AS sistema,
    CAST(d.conexa_id AS STRING)                AS id_no_sistema,
    'CNPJ'                                     AS chave_por,
    IFNULL(NULLIF(d.nome_fantasia,''), d.nome) AS rotulo_na_origem,
    d.is_ativo                                 AS ativo_na_origem,
    0, 0, 0, 0,
    COUNT(f.cobranca_id)                       AS qtd_cobrancas_conexa,
    ROUND(IFNULL(SUM(f.valor), 0), 2)          AS valor_conexa,
    0, 0.0, 0, 0.0,
    IFNULL(MAX(f.due_date), DATE '1900-01-01') AS ultima_atividade
  FROM `vanguardamartech_raw.supabase_public_dim_cliente_vbot` d
  LEFT JOIN `vanguardamartech_raw.supabase_public_vw_faturamento_vbot` f
         ON f.customer_id = d.conexa_id
  WHERE REGEXP_REPLACE(IFNULL(d.cnpj,''), r'[^0-9]','') = '61077352000130'
  GROUP BY d.conexa_id, 4, d.is_ativo
),

-- PI -- LIMITACAO 1: chave por ROTULO. Os PIs intragrupo tem cliente_cnpj VAZIO
-- (medido em 2026-09-21: os 7 de CLIENTE TESTE e o 1 de VBOT, todos sem CNPJ).
-- Nao ha id nem documento para casar. Renomear o cliente na origem derruba esta linha.
pi AS (
  SELECT
    'PI'                                       AS sistema,
    CONCAT('ROTULO:', 'VBOT')                  AS id_no_sistema,
    'ROTULO'                                   AS chave_por,
    ANY_VALUE(cliente)                         AS rotulo_na_origem,
    CAST(NULL AS BOOL)                         AS ativo_na_origem,
    0, 0, 0, 0, 0, 0.0,
    COUNT(*)                                   AS qtd_pis,
    ROUND(SUM(valor_negociado), 2)             AS valor_pi,
    0, 0.0,
    MAX(data_inicio)                           AS ultima_atividade
  FROM `vanguardamartech_trusted.trs_pi__insercao`
  WHERE UPPER(TRIM(cliente)) = 'VBOT'
  HAVING COUNT(*) > 0
),

-- FINANCEIRO -- chave: cliente_doc. Aqui a empresa entra pela RAZAO SOCIAL, nao pelo
-- fantasia -- por isso a chave e o documento. Filtro por nome perderia a linha.
-- MAX(DATE(ano,mes,1)) e NAO DATE(MAX(ano),MAX(mes),1): a segunda combina ano e mes
-- maximos independentemente e inventa mes inexistente -- medido, 9 meses de erro.
fin AS (
  SELECT
    'FINANCEIRO'                    AS sistema,
    CONCAT('DOC:', cliente_doc)     AS id_no_sistema,
    'CNPJ'                          AS chave_por,
    ANY_VALUE(cliente_nome)         AS rotulo_na_origem,
    CAST(NULL AS BOOL)              AS ativo_na_origem,
    0, 0, 0, 0, 0, 0.0, 0, 0.0,
    COUNT(*)                        AS qtd_lancamentos_fin,
    ROUND(SUM(valor), 2)            AS valor_fin,
    MAX(DATE(ano, mes, 1))          AS ultima_atividade
  FROM `vanguardamartech_raw.supabase_gold_mvw_fin_cliente`
  WHERE REGEXP_REPLACE(IFNULL(cliente_doc,''), r'[^0-9]','') = '61077352000130'
  GROUP BY cliente_doc
),

uniao AS (
  SELECT * FROM iclips
  UNION ALL SELECT * FROM vjob
  UNION ALL SELECT * FROM conexa
  UNION ALL SELECT * FROM pi
  UNION ALL SELECT * FROM fin
),
final AS (
  SELECT
    CONCAT(u.sistema, ':', u.id_no_sistema)   AS id_cadastro,
    'VBOT'                                    AS empresa,
    '61077352000130'                          AS cnpj,
    u.sistema,
    u.id_no_sistema,
    u.chave_por,
    u.rotulo_na_origem,
    -- Cadastro de TESTE que divide o CNPJ da empresa nao e a empresa. Fica visivel,
    -- nao e fundido: o conserto e no cadastro de origem.
    IF(REGEXP_CONTAINS(UPPER(IFNULL(u.rotulo_na_origem,'')), r'TESTE'),
       'TESTE_SOBRE_O_CNPJ', 'EMPRESA')       AS classe,
    u.ativo_na_origem,
    u.qtd_projetos_iclips, u.qtd_pecas_iclips,
    u.qtd_escopos_vjob,    u.qtd_concluidos_vjob,
    u.qtd_cobrancas_conexa, u.valor_conexa,
    u.qtd_pis,              u.valor_pi,
    u.qtd_lancamentos_fin,  u.valor_fin,
    NULLIF(u.ultima_atividade, DATE '1900-01-01') AS ultima_atividade
  FROM uniao u
)
SELECT
  f.*,
  CURRENT_TIMESTAMP()                                     AS _extraido_at,
  'America/Sao_Paulo'                                     AS _fuso,
  'trs_iclips__projeto + trs_iclips__peca_atributo + supabase_silver_vjob_escopo + supabase_public_dim_cliente_vbot + supabase_public_vw_faturamento_vbot + trs_pi__insercao + supabase_gold_mvw_fin_cliente' AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(f)))                          AS _payload_hash
FROM final f
ORDER BY f.sistema, f.id_no_sistema
