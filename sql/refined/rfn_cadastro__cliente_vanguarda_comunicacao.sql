-- rfn_cadastro__cliente_vanguarda_comunicacao
-- Refined / dominio Cadastro. Grao: um cadastro da Vanguarda Comunicacao como
-- cliente, por sistema. Chave: id_cadastro = sistema + id no sistema.
--
-- A Vanguarda Comunicacao (CNPJ 07.865.616/0001-74, razao social
-- 'B. R. M. COSTA DE LIMA E CIA SOCIEDADE SIMPLES PURA') e a controladora do grupo e
-- ao mesmo tempo cliente da propria agencia. Esta tabela reune TODOS os cadastros
-- dela. Par: rfn_cadastro__cliente_vbot (query-NxG1), mesmo formato.
--
-- REGRA 1 -- A CHAVE E O CNPJ OU O ID DO SISTEMA, NUNCA O ROTULO. Aqui isso nao e
-- preferencia, e o unico jeito de a tabela fechar: MEDIDO EM 2026-09-21, no
-- financeiro (gold_mvw_fin_cliente) esta empresa aparece como
-- 'B. R. M. COSTA DE LIMA E CIA SOCIEDADE SIMPLES PURA' -- a RAZAO SOCIAL. Um filtro
-- cliente_nome LIKE '%VANGUARDA%' pega R$ 40.067,03 (que e da Vanguarda Midia
-- Digital, outra empresa) e PERDE os R$ 47.544,32 desta. O documento e a chave.
--
-- REGRA 2 -- O CADASTRO DE TESTE QUE DIVIDE O CNPJ NAO E A EMPRESA.
-- O Conexa tem DOIS cadastros com este CNPJ: o 74 ('VANGUARDA COMUNICACAO') e o 96
-- ('CADASTRO TESTE MESMO CNPJ'), ambos is_ativo = true, ambos contando na base de 122
-- clientes da operacao VBOT. Os dois entram aqui, separados pela coluna classe
-- (EMPRESA / TESTE_SOBRE_O_CNPJ). Nao sao fundidos nem descartados: fundir esconderia
-- que existe um cadastro de teste ativo; descartar esconderia que ele conta na base.
-- O conserto e no cadastro de origem.
--
-- REGRA 3 -- NAO CONFUNDIR COM AS OUTRAS EMPRESAS DO GRUPO NEM COM CLIENTE REAL.
-- Ficam FORA desta tabela, de proposito, cada um com CNPJ proprio:
--   VBOT ... 61.077.352/0001-30 -> tabela propria (a tabela par).
--   VANGUARDA MIDIA DIGITAL / VPROMO ... 26.123.250/0001-02, ids iClips 1511 e 3893,
--     R$ 40.067,03 no financeiro. Sao a MESMA pessoa juridica com dois cadastros e
--     uma TERCEIRA empresa do grupo -- nao sao esta. Nenhuma tabela foi pedida para
--     ela. NAO fundir por conter 'VANGUARDA' no nome: e o erro que esta regra impede.
--   VANGUARDA INTERNACIONAL ... 59.772.810/0001-09 -> CLIENTE REAL, entrega LAVENDER.
--   CLIENTE TESTE ... 62.361.814/0001-09, e TESTE HUGO SENNA (VJOB 146) -> artefatos
--     de teste, nao sao esta empresa.
--
-- REGRA 4 -- O VOLUME E MEDIDO NA ORIGEM a cada execucao. Nenhum numero e digitado.
--
-- CADASTROS CONFERIDOS EM 2026-09-21
--   ICLIPS 263 ... 227 projetos, 953 pecas
--   VJOB   160 ... 1 escopo, 1 concluido, cliente_ativo = FALSE
--   CONEXA 74  ... 1 cobranca, R$ 5,00, is_ativo = true      -> classe EMPRESA
--   CONEXA 96  ... 0 cobrancas, R$ 0,00, is_ativo = true     -> classe TESTE_SOBRE_O_CNPJ
--   FINANCEIRO ... 4 lancamentos, R$ 47.544,32, tipo_receita = 'CLIENTE'
--   PI         ... NAO TEM PI com este rotulo nem com este documento. Verificado.
--
-- LIMITACAO -- NAO CONTORNE
-- 1. FICOU DE FORA, E E DECISAO PENDENTE: o cadastro ICLIPS 1562 e uma PESSOA FISICA
--    cujo nome reproduz a raiz da razao social desta empresa ('B. R. M. COSTA DE
--    LIMA'), com 2 projetos e 0 pecas, ultima atividade em 19/04/2021. Ele NAO TEM
--    CNPJ. Incluir seria resolver identidade por semelhanca de NOME, que e exatamente
--    o que a regra 1 proibe -- entao ficou fora. ALTERNATIVA NAO TOMADA: incluir como
--    cadastro da empresa. Nao contorne por conta propria: precisa de confirmacao de
--    quem conhece o cadastro.
-- 2. O grao das colunas de volume difere por sistema (projeto, peca, escopo, cobranca,
--    lancamento). NAO somar entre sistemas.
-- 3. Ausencia de linha de um sistema significa "sem cadastro naquele sistema", nao
--    "volume zero". O caso conferido (PI) esta no bloco acima.
-- 4. R$ 5,00 de cobranca no Conexa e valor de teste, nao receita. Esta aqui porque e o
--    que a origem tem; nao usar como receita intragrupo -- para isso vale o
--    financeiro (R$ 47.544,32).

WITH
-- ICLIPS -- chave: CNPJ do cadastro. Nunca o rotulo.
ic_proj AS (
  SELECT cliente_id AS id_no_sistema,
         ANY_VALUE(cliente_nome)        AS rotulo,
         COUNT(DISTINCT id_projeto)     AS qtd_projetos,
         MAX(DATE(data_entrada))        AS ultima
  FROM `vanguardamartech_trusted.trs_iclips__projeto`
  WHERE REGEXP_REPLACE(IFNULL(cliente_cnpj,''), r'[^0-9]','') = '07865616000174'
  GROUP BY cliente_id
),
ic_pecas AS (
  SELECT id_cliente_iclips AS id_no_sistema,
         COUNT(DISTINCT id_job_peca)              AS qtd_pecas,
         MAX(DATE(etapa_amostrada_play_inicio))   AS ultima
  FROM `vanguardamartech_trusted.trs_iclips__peca_atributo`
  WHERE REGEXP_REPLACE(IFNULL(cliente_cnpj,''), r'[^0-9]','') = '07865616000174'
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
  WHERE id_cliente IN (160)
  GROUP BY id_cliente
),

-- CONEXA -- chave: CNPJ. REGRA 2: os DOIS cadastros entram, o 74 e o 96 de teste.
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
  WHERE REGEXP_REPLACE(IFNULL(d.cnpj,''), r'[^0-9]','') = '07865616000174'
  GROUP BY d.conexa_id, 4, d.is_ativo
),

-- PI -- chave por ROTULO (os PIs intragrupo tem cliente_cnpj VAZIO na origem).
-- Nesta empresa nao ha PI; o HAVING mantem a CTE vazia em vez de emitir linha falsa.
pi AS (
  SELECT
    'PI'                                       AS sistema,
    CONCAT('ROTULO:', 'VANGUARDA COMUNICACAO') AS id_no_sistema,
    'ROTULO'                                   AS chave_por,
    ANY_VALUE(cliente)                         AS rotulo_na_origem,
    CAST(NULL AS BOOL)                         AS ativo_na_origem,
    0, 0, 0, 0, 0, 0.0,
    COUNT(*)                                   AS qtd_pis,
    ROUND(SUM(valor_negociado), 2)             AS valor_pi,
    0, 0.0,
    MAX(data_inicio)                           AS ultima_atividade
  FROM `vanguardamartech_trusted.trs_pi__insercao`
  WHERE UPPER(TRIM(cliente)) = 'VANGUARDA COMUNICACAO'
  HAVING COUNT(*) > 0
),

-- FINANCEIRO -- chave: cliente_doc. REGRA 1 em acao: aqui a empresa entra pela RAZAO
-- SOCIAL, nao pelo fantasia. Filtro por nome perderia os R$ 47.544,32.
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
  WHERE REGEXP_REPLACE(IFNULL(cliente_doc,''), r'[^0-9]','') = '07865616000174'
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
    'VANGUARDA COMUNICACAO'                   AS empresa,
    '07865616000174'                          AS cnpj,
    u.sistema,
    u.id_no_sistema,
    u.chave_por,
    u.rotulo_na_origem,
    -- REGRA 2: cadastro de TESTE que divide o CNPJ da empresa nao e a empresa. Fica
    -- visivel, nao e fundido: o conserto e no cadastro de origem.
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
