-- rfn_cadastro__cliente_sk
-- Refined / dominio Cadastro. **A CAMADA DE IDENTIDADE** da arquitetura (§6).
-- Grao: um CADASTRO por sistema. Chave da linha: id_cadastro = sistema + id.
-- Chave de consolidacao: `cliente_sk`.
--
-- CLASSIFICACAO: **L2 INTERNAL**. Carrega CNPJ (documento de pessoa juridica, nao
-- pessoal) e rotulo -- nao carrega valor, contrato nem dado pessoal.
--
-- O QUE ELA RESOLVE. A arquitetura pede uma chave tecnica central que consolide o
-- mesmo cliente entre ERP, CRM e plataformas (§6). Sem ela e que aparecem os
-- 96 clientes de escopo e 1.303 contratos sem cadastro, e o casamento por nome que
-- esta casa ja proibiu tratar como prova. **Esta tabela e a chave, e ela e formada
-- por DOCUMENTO -- nunca por rotulo.**
--
-- INVENTARIO -- medido em 2026-09-23
--   VJOB     315 cadastros, 166 com CNPJ, 139 documentos distintos
--   iClips   408 cadastros, 349 com CNPJ, 349 documentos distintos
--   Conexa   133 cadastros, 128 com CNPJ, 113 documentos distintos
--   Financeiro                            495 documentos distintos
--   Cruzamento por documento: VJOB x iClips **118**, VJOB x financeiro **123**,
--   iClips x financeiro **225**, iClips x Conexa **38**.
--
-- COMO O `cliente_sk` E FORMADO -- so ha dois caminhos, e a coluna `sk_metodo` diz
-- qual valeu linha a linha:
--   `DOCUMENTO`               -> sk = 'DOC:' + digitos do CNPJ. Dois cadastros com o
--                                mesmo documento sao a mesma pessoa juridica e
--                                recebem o mesmo sk, em qualquer sistema.
--   `ISOLADO_SEM_DOCUMENTO`   -> sk = sistema + ':' + id. **Cadastro sem documento
--                                fica sozinho no proprio sk.** Nao e fundido com
--                                ninguem, nem por nome parecido, nem por nome igual.
--
-- **NOME NAO FORMA sk. NUNCA.** O casamento por rotulo aparece como
-- `candidato_sk_por_nome`, que e SUGESTAO PARA REVISAO HUMANA e nao entra no sk.
-- A casa ja tem dois casos que provam por que: `PARA GUARDAR SELF STORAGE` (VJOB) e
-- `PARA GUARDAR` (iClips) so se ligam pelo nome; e no financeiro a Vanguarda
-- Comunicacao entra pela razao social `B. R. M. COSTA DE LIMA E CIA`, que nao
-- contem a palavra Vanguarda -- filtrar por nome la perde R$ 47.544,32 e traz
-- R$ 40.067,03 de outra empresa.
--
-- A R-003 CONTINUA VALENDO E NAO CONFLITA. Ela proibe fundir CONTAS cujo nome
-- comeca igual (as 10 `BRAGA *`, as 3 `PMZ *`, as 3 `UNIPAR *`). Aqui nada e fundido
-- por nome; o que se agrupa e cadastro com o MESMO DOCUMENTO, que e a mesma PJ.
-- E o cadastro nao desaparece dentro do sk: cada linha mantem `sistema`,
-- `id_no_sistema` e `rotulo_na_origem`. Quem quiser a conta individual le a linha;
-- quem quiser a PJ agrupa por `cliente_sk`.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **Metade do VJOB nao tem documento.** 149 dos 315 cadastros ficam isolados,
--      um sk cada. Isso nao e defeito desta tabela -- e o cadastro de origem.
--      Para eles, ligar a receita do VJOB ao custo do iClips continua impossivel
--      por prova.
--   2. **O sk agrupa pessoa juridica, nao marca nem operacao.** O CNPJ
--      `16.665.666/0001-07` carrega TRES marcas (`PARA GUARDAR`, `HAYA SOLAR`,
--      `PARA CHEGAR`) e vira UM sk. Quem precisa de marca le o rotulo da linha.
--      Igualmente, Vanguarda Midia Digital e VPromo dividem
--      `26.123.250/0001-02` e viram um sk so -- sao a mesma PJ com dois cadastros.
--   3. **Cadastro de teste com CNPJ de verdade entra no sk da empresa real.**
--      `CADASTRO TESTE MESMO CNPJ` divide o documento da Vanguarda Comunicacao.
--      `flag_rotulo_de_teste` marca pelo rotulo, para que apareca em vez de sumir --
--      **e nao remove a linha do sk**, porque o documento e o mesmo de fato.
--   4. `candidato_sk_por_nome` **nao e conclusao**. Ele so existe onde o nome
--      normalizado bate EXATAMENTE com o de um cadastro que tem documento, e mesmo
--      assim pode ser homonimia. Usar para revisar, nunca para somar.
--   5. Esta tabela **nao inclui conta de midia** (Google Ads, Facebook Ads). Aquelas
--      dimensoes nao carregam CNPJ, entao nao ha como ligar por documento. A ponte
--      honesta ali continua sendo `gad_campaignid`, ja documentada.
WITH
-- Normalizacao de rotulo usada SO para o candidato, nunca para o sk.
-- Remove acento, pontuacao e espaco repetido.
cadastros AS (
  SELECT 'VJOB' AS sistema, CAST(v.id_cliente AS STRING) AS id_no_sistema,
         v.cliente AS rotulo_na_origem, v.cnpj_digitos AS documento, v.is_ativo AS ativo_na_origem
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente` v
  UNION ALL
  SELECT 'ICLIPS', CAST(i.id_cliente AS STRING), i.cliente_nome,
         NULLIF(REGEXP_REPLACE(IFNULL(i.cnpj,''), r'[^0-9]',''), ''), NULL
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente` i
  UNION ALL
  SELECT 'CONEXA', CAST(c.conexa_id AS STRING), c.nome,
         NULLIF(REGEXP_REPLACE(IFNULL(c.cnpj,''), r'[^0-9]',''), ''), c.is_ativo
  FROM `vanguardamartech_raw`.`supabase_public_dim_cliente_vbot` c
  UNION ALL
  -- O financeiro nao tem cadastro proprio: cada documento distinto vira uma linha,
  -- com a razao social como rotulo. E o que permite o sk alcancar o dinheiro.
  SELECT 'FINANCEIRO', f.documento, f.razao_social, f.documento, NULL
  FROM (
    -- `gold_mvw_fin_cliente` NAO tem `razao_social` (a `gold_vw_fin_cliente` tem).
    -- Aqui o rotulo e `cliente_nome`, que NO FINANCEIRO E A RAZAO SOCIAL -- por isso
    -- a Vanguarda Comunicacao aparece como `B. R. M. COSTA DE LIMA E CIA`.
    SELECT NULLIF(REGEXP_REPLACE(IFNULL(cliente_doc,''), r'[^0-9]',''), '') AS documento,
           ANY_VALUE(cliente_nome)                                          AS razao_social
    FROM `vanguardamartech_raw`.`supabase_gold_mvw_fin_cliente`
    WHERE NULLIF(REGEXP_REPLACE(IFNULL(cliente_doc,''), r'[^0-9]',''), '') IS NOT NULL
    GROUP BY 1
  ) f
),
normalizado AS (
  SELECT
    *,
    -- SO para o candidato. O sk nao olha para isto.
    NULLIF(TRIM(REGEXP_REPLACE(
      REGEXP_REPLACE(UPPER(NORMALIZE_AND_CASEFOLD(IFNULL(rotulo_na_origem,''), NFD)),
                     r'\pM', ''),
      r'[^A-Z0-9 ]', ' ')), '') AS rotulo_normalizado
  FROM cadastros
),
com_sk AS (
  SELECT
    *,
    -- OS DOIS UNICOS CAMINHOS. Ver o cabecalho.
    IF(documento IS NOT NULL,
       CONCAT('DOC:', documento),
       CONCAT(sistema, ':', id_no_sistema))       AS cliente_sk,
    IF(documento IS NOT NULL,
       'DOCUMENTO',
       'ISOLADO_SEM_DOCUMENTO')                   AS sk_metodo
  FROM normalizado
),
-- Candidato por nome: so para quem NAO tem documento, e so quando o rotulo
-- normalizado bate exatamente com o de um cadastro que TEM. Sugestao, nao conclusao.
rotulos_com_doc AS (
  SELECT rotulo_normalizado,
         ANY_VALUE(cliente_sk)              AS sk_candidato,
         COUNT(DISTINCT cliente_sk)         AS qtd_sk_no_rotulo
  FROM com_sk
  WHERE documento IS NOT NULL AND rotulo_normalizado IS NOT NULL
  GROUP BY rotulo_normalizado
),
-- Alcance do sk: em quantos sistemas o mesmo documento aparece.
alcance AS (
  SELECT cliente_sk,
         COUNT(DISTINCT sistema)            AS qtd_sistemas,
         COUNT(*)                           AS qtd_cadastros,
         STRING_AGG(DISTINCT sistema, ' | ' ORDER BY sistema) AS sistemas
  FROM com_sk
  GROUP BY cliente_sk
)
SELECT
  CONCAT(s.sistema, ':', s.id_no_sistema)           AS id_cadastro,
  s.cliente_sk,
  s.sk_metodo,
  s.sistema,
  s.id_no_sistema,
  s.rotulo_na_origem,
  s.documento                                       AS cnpj_digitos,
  (s.documento IS NOT NULL)                         AS tem_documento,
  s.ativo_na_origem,

  a.qtd_sistemas,
  a.qtd_cadastros                                   AS qtd_cadastros_no_sk,
  a.sistemas                                        AS sistemas_no_sk,
  (a.qtd_sistemas > 1)                              AS is_multissistema,

  -- Ver limitacao 4: sugestao para revisao humana, NAO entra no sk.
  IF(s.documento IS NULL, r.sk_candidato, NULL)     AS candidato_sk_por_nome,
  IF(s.documento IS NULL AND r.qtd_sk_no_rotulo > 1, TRUE, FALSE) AS candidato_ambiguo,

  -- Ver limitacao 3: marca, nao remove.
  REGEXP_CONTAINS(UPPER(IFNULL(s.rotulo_na_origem,'')), r'TESTE|CADASTRO TESTE') AS flag_rotulo_de_teste,

  'L2_INTERNAL'                                     AS classificacao_dado,
  CURRENT_TIMESTAMP()                               AS _extraido_at,
  'mysql-yIOn | rest-api-73hk | supabase-x0tz'      AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(s)))                    AS _payload_hash
FROM com_sk s
LEFT JOIN alcance a          ON a.cliente_sk = s.cliente_sk
LEFT JOIN rotulos_com_doc r  ON r.rotulo_normalizado = s.rotulo_normalizado
