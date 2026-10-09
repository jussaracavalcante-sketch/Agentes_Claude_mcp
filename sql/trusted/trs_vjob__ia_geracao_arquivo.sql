-- trs_vjob__ia_geracao_arquivo
-- Arquivo produzido por uma geracao da IA, no modulo `ia_*` do VJOB real (mysql-yIOn).
-- Grao: um arquivo. Chave: id_arquivo.
--
-- MEDIDO EM 2026-09-24
--   78 arquivos, 78 ids, **73 geracoes e 73 solicitacoes** -- entao ha geracao com mais
--   de um arquivo. Janela 07/07 a 17/09/2026.
--   **`tipo` tem um unico valor: `imagem`.** Nenhum outro tipo de saida foi produzido.
--   2 mime types: **59 `image/png` e 19 `image/svg+xml`**. Nenhum arquivo sem caminho.
--
-- A COBERTURA CONFIRMA A CADEIA, e esse e o achado desta tabela: das 86 solicitacoes,
--   **73 das 75 concluidas tem arquivo e NENHUMA das 11 nao concluidas tem**. Duas
--   concluidas sem arquivo sao a unica excecao. O estado do pedido e o estado da entrega
--   batem -- o que nao e obvio em modulo novo e e por isso que vale estar medido.
--
-- FUSO: NADA SE CONVERTE. `criado_em` vem TIMESTAMP direto do MySQL e ja e hora local.
--
-- CLASSIFICACAO: **L2 INTERNAL.** Esta tabela e so metadado de arquivo -- nome, caminho,
--   mime e data. **O conteudo da peca NAO esta aqui**; ele esta em
--   `trs_vjob__ia_geracao.resultado`, que e L3. O arquivo em si nao esta nesta base.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **O ARQUIVO NAO ESTA AQUI.** `caminho` aponta para o servidor de arquivos do VJOB.
--      Nao ha bytes nesta base, nem tamanho, nem dimensao da imagem.
--   2. `id_geracao` junta com `trs_vjob__ia_geracao`; `id_solicitacao` esta denormalizado
--      na propria linha para o filtro por pedido nao exigir join -- mesmo padrao do
--      `flag_repo_fork` da `trs_github__commit`.
--   3. 78 linhas nao sustentam indicador de nada.
SELECT
  a.id                                                    AS id_arquivo,
  a.geracao_id                                            AS id_geracao,
  a.solicitacao_id                                        AS id_solicitacao,
  NULLIF(TRIM(a.tipo), '')                                AS tipo,
  NULLIF(TRIM(a.titulo), '')                              AS titulo,
  NULLIF(TRIM(a.nome_arquivo), '')                        AS nome_arquivo,
  NULLIF(TRIM(a.caminho), '')                             AS caminho,
  NULLIF(TRIM(a.mime_type), '')                           AS mime_type,
  -- Categoria fechada sobre o mime declarado. O que nao casa continua visivel como
  -- 'OUTRO', nunca some num NULL silencioso.
  CASE
    WHEN a.mime_type LIKE 'image/svg%' THEN 'SVG'
    WHEN a.mime_type LIKE 'image/%'    THEN 'IMAGEM_RASTER'
    WHEN a.mime_type IS NULL           THEN 'NAO_DECLARADO'
    ELSE 'OUTRO'
  END                                                     AS familia_arquivo,
  a.criado_em,
  CURRENT_TIMESTAMP()                                     AS _extraido_at,
  'mysql-yIOn'                                            AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(a)))                          AS _payload_hash
FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_ia_geracao_arquivos` a
