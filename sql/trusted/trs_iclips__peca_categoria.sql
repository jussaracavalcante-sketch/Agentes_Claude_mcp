-- trs_iclips__peca_categoria
-- Catalogo de CATEGORIAS de peca do iClips (fonte `rest-api-xk4P`, stream
-- `raw_piece_categories`). Grao: uma categoria. Chave: id_categoria. 29 linhas.
--
-- O QUE ELA COMPRA, e nada mais fazia: **a `trs_iclips__peca_tipo` carrega uma
--   `categoria` em TEXTO e nunca teve tabela de dominio.** Esta e ela, e resolve
--   inteiro: das 22 categorias distintas usadas nos tipos de peca, **22 casam
--   exatamente com o catalogo e ZERO ficam de fora**. Medido em 2026-09-28.
--
-- **O ACHADO: `Off` E `OFF` NAO SAO ERRO DE DIGITACAO NA LEITURA -- SAO QUATRO
--   CADASTROS.** Esta casa ja tinha registrado, na `rfn_operacao__custo_peca`, que
--   "`Off` e `OFF` sao categorias distintas na origem: a primeira tem 95% de
--   precificacao e a segunda zero". Agora se sabe por que: o catalogo tem
--     id 14 = `Off`  -- 71 tipos de peca, 42 com valor
--     id 28 = `OFF`  ·  id 42 = `OFF`  ·  id 43 = `OFF`
--   Os tres `OFF` sao registros SEPARADOS com o mesmo nome. E `setup` (27) convive
--   com `SETUP` (29). Nao e grafia na leitura -- e duplicata de cadastro.
--
-- **JUNTAR ESTE CATALOGO AOS TIPOS DE PECA POR NOME MULTIPLICA, E O NUMERO ESTA
--   MEDIDO.** Como a peca guarda o nome da categoria e nao o id, um join por nome
--   entrega os 52 tipos de `OFF` **tres vezes**, uma por id. Por isso
--   `qtd_tipos_de_peca_com_este_nome` tem esse nome comprido: ela e por NOME, nao
--   por id, e **somar a coluna entre linhas conta a mesma peca mais de uma vez**.
--   `qtd_ids_com_este_nome` fica ao lado para o divisor ser visivel.
--
-- **O VALOR NAO E EMITIDO, PORQUE E ZERO NAS 29.** A coluna `valor` existe na origem
--   e prometia ser a segunda fonte de preco que a cadeia de custo procurou -- e vale
--   **0 em todas as 29 linhas**. Emiti-la convidaria a somar e obter zero, que e um
--   numero, quando o certo e ausencia. Mesma doutrina ja aplicada ao `stats` do
--   GitHub e ao `data_emissao` do Conta Azul. O preco por peca continua saindo de
--   `trs_iclips__peca_tipo.valor_tabela`.
--
-- **A OUTRA TABELA DA MESMA FONTE NAO FOI TRATADA, e a medicao sustenta.**
--   `raw_workflow_templates` (24 linhas) tem `stepCount` **zero nas 24**,
--   `estimatedTotalHours` **zero nas 24**, `tipoWorkflow` com **um unico valor** e
--   `isActive` verdadeiro nas 24 -- quatro das sete colunas mortas ou constantes.
--   Sobra id + nome, **e nao ha consumidor**: o `id_workflow` da
--   `trs_iclips__etapa` e a INSTANCIA, com 514.843 valores na faixa 443.594 a
--   1.396.520, enquanto o template vai de 1 a 25 -- **zero ids em comum, e as faixas
--   nem se tocam**. Mesmo precedente do `tbclientexservico` e do `vmkt_*`.
--
-- CLASSIFICACAO: **L2 INTERNAL.** So id e nome de categoria de producao.
--
-- FUSO: a tabela nao tem coluna de tempo. Nada a converter.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **Nao decidir qual `OFF` e o certo.** Os quatro cadastros existem e a origem
--      nao diz qual prevalece; fundi-los aqui apagaria a informacao de que sao
--      quatro. `nome_normalizado` existe para quem QUISER agrupar na leitura, e essa
--      escolha fica com quem le -- exatamente como a R-003 trata conta de cliente.
--   2. **Uma linha nao tem nome** (id 41, string vazia). `flag_sem_nome` marca; nao
--      foi descartada, porque descartar esconde que ela existe.
--   3. 7 das 29 categorias nao aparecem em tipo de peca nenhum (`Desenvolvedor`,
--      `KV, STORY BOARD E BRIFING`, `PATIO`, `setup`, a sem nome...). Catalogo nao e
--      uso; `qtd_tipos_de_peca_com_este_nome` = 0 nelas.
--   4. O stream e FULL_SYNC: e uma FOTOGRAFIA, sem historico. Categoria apagada na
--      origem some daqui sem rastro.
--
-- **A COBERTURA TEM DE VIAJAR JUNTO COM O NUMERO: so 309 dos 1.049 tipos de peca
--   (29,5%) TEM categoria.** 740 estao com o campo vazio. Entao qualquer leitura "por
--   categoria de peca" fala de menos de um terco do catalogo -- e as 22 categorias
--   que aparecem resolvem 22 de 22 contra este cadastro, entao **o buraco e de
--   preenchimento na origem, nao de dominio faltando**.
--
-- VALIDACAO 2026-09-28 (medida na Raw materializada, antes de publicar): 29 linhas,
--   29 chaves distintas, 26 nomes distintos nao nulos, 1 sem nome, **3 linhas com
--   nome exatamente duplicado** (os tres `OFF`) e **6 linhas quando a caixa e
--   ignorada** (mais `Off`, `setup` e `SETUP`), 5 categorias sem uso nenhum, 22 das
--   22 categorias usadas pelos tipos de peca resolvem contra o catalogo, e
--   309 de 1.049 tipos de peca tem categoria.
--   **Somar `qtd_tipos_de_peca_com_este_nome` entre as 29 linhas da 413 contra 309
--   reais** -- os 104 a mais sao exatamente os 52 tipos de `OFF` contados tres vezes.
--   E a prova numerica de que o join por nome multiplica.
WITH origem AS (
  SELECT
    id                                                  AS id_categoria,
    NULLIF(TRIM(nome), '')                              AS nome
  FROM `vanguardamartech_gestao_de_projetos_do_iclips`.`raw_piece_categories`
),
-- Duas contagens DIFERENTES, e a distincao e o ponto da tabela:
--   `ids_com_este_nome`      -- quantos CADASTROS carregam este nome (exato)
--   `ids_com_este_nome_norm` -- idem, ignorando caixa (junta `Off` com `OFF`)
por_nome AS (
  SELECT
    nome,
    COUNT(*)                                            AS ids_com_este_nome
  FROM origem GROUP BY nome
),
por_nome_norm AS (
  SELECT
    UPPER(nome)                                         AS nome_norm,
    COUNT(*)                                            AS ids_com_este_nome_norm
  FROM origem GROUP BY 1
),
-- Uso nos tipos de peca, POR NOME -- porque a peca guarda o nome, nao o id.
-- Contagem por NOME: somar entre linhas conta a mesma peca mais de uma vez.
uso AS (
  SELECT
    TRIM(categoria)                                     AS nome,
    COUNT(*)                                            AS tipos_de_peca,
    COUNTIF(valor_tabela > 0)                           AS tipos_com_valor
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_tipo`
  WHERE NULLIF(TRIM(categoria), '') IS NOT NULL
  GROUP BY 1
)
SELECT
  o.id_categoria,
  o.nome,
  UPPER(o.nome)                                         AS nome_normalizado,
  (o.nome IS NULL)                                      AS flag_sem_nome,

  -- LIMITACAO 1 / o achado: quantos cadastros dividem este nome.
  IFNULL(pn.ids_com_este_nome, 0)                       AS qtd_ids_com_este_nome,
  (IFNULL(pn.ids_com_este_nome, 0) > 1)                 AS flag_nome_duplicado,
  IFNULL(pnn.ids_com_este_nome_norm, 0)                 AS qtd_ids_com_este_nome_normalizado,
  (IFNULL(pnn.ids_com_este_nome_norm, 0) > 1)           AS flag_nome_duplicado_sem_caixa,

  -- POR NOME, nao por id. NAO somar entre linhas -- ver o bloco do join que multiplica.
  IFNULL(u.tipos_de_peca, 0)                            AS qtd_tipos_de_peca_com_este_nome,
  IFNULL(u.tipos_com_valor, 0)                          AS qtd_tipos_com_valor_com_este_nome,
  (IFNULL(u.tipos_de_peca, 0) = 0)                      AS flag_categoria_sem_uso,

  CURRENT_TIMESTAMP()                                   AS _extraido_at,
  'rest-api-xk4P'                                       AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(o)))                        AS _payload_hash
FROM origem o
-- ANTI-JOIN/LOOKUP por CTE agregada, nunca `NOT EXISTS` correlacionado.
LEFT JOIN por_nome      pn  ON pn.nome       = o.nome
LEFT JOIN por_nome_norm pnn ON pnn.nome_norm = UPPER(o.nome)
LEFT JOIN uso           u   ON u.nome        = o.nome
