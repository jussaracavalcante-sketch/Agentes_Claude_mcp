-- trs_vjob__ia_documento
-- Documento de contexto anexado a um cliente no modulo `ia_*` do VJOB real (mysql-yIOn).
-- Grao: um documento. Chave: id_documento.
--
-- MEDIDO EM 2026-09-24
--   21 documentos, 21 ids distintos, **2 clientes** -- MOVE RENTAL CARS (336) com 18 e
--   THEREZINHA RUIZ (339) com 3. O terceiro cliente configurado (PRESTEX, 136) nao tem
--   nenhum. Janela: 16/07 a 15/09/2026. Por familia de arquivo: 14 IMAGEM (34.193
--   caracteres extraidos, **4 delas sem conteudo nenhum**), 5 COMPACTADO (505 -- ou seja,
--   praticamente nada) e 2 PDF (13.324). Total **48.022 caracteres**.
--   O texto util esta em 17 dos 21 documentos, e a maior parte dele veio de IMAGEM --
--   extracao de imagem, nao de documento estruturado. Tratar como transcricao, nao fonte.
--
-- `conteudo_extraido` E EMITIDO DE PROPOSITO, e essa e a razao de a tabela existir. A §18
--   da arquitetura diz que a IA consome Gold e Semantic Layer, nunca a Bronze. Deixar o
--   texto so na Raw obrigaria quem consome a violar a norma para ler contexto de marca.
--
-- `flag_sem_conteudo` NAO E COSMETICA. Documento anexado sem texto extraido **conta como
--   documento e nao entrega contexto nenhum**. Um COUNT diria 21; o que serve para
--   alimentar IA sao 17. Mesmo mecanismo do `flag_config_vazia` da tabela de configuracao.
--
-- FUSO: NADA SE CONVERTE. `criado_em` vem TIMESTAMP direto do MySQL e ja e hora local
--   (America/Sao_Paulo) -- provado no nivel do conector em 2026-09-23. Aplicar
--   'America/Sao_Paulo' subtrairia 3 horas de dado ja local.
--
-- CLASSIFICACAO: **L3 CONFIDENTIAL**. E material de marca de cliente de terceiro.
--   Medido em 2026-09-24: ZERO ocorrencia de CPF, CNPJ, telefone ou e-mail nos 21
--   `conteudo_extraido`. Por isso nao e L4 -- mas e TEXTO EXTRAIDO DE ARQUIVO ENVIADO POR
--   PESSOA, entao a medicao e um retrato. Se o modulo crescer, **remedir antes de tratar
--   como L3**; um unico PDF com ficha de cliente dentro muda o nivel da tabela inteira.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **21 linhas nao sustentam indicador.** Serve para LER o contexto, nao para medir.
--   2. `caminho` e o caminho no servidor de arquivos do VJOB. O ARQUIVO NAO ESTA NESTA
--      BASE -- so o texto que o extrator tirou dele. Nao ha como reprocessar daqui.
--   3. `id_usuario_envio` resolve em `trs_vjob__usuario` (conferido: os 2 ids existem nas
--      272 linhas), e o nome NAO e denormalizado aqui de proposito -- aquela tabela e L4
--      e trazer o nome para ca subiria o nivel desta sem necessidade.
--   4. `tipo_arquivo` e derivado do `mime_type`, que e o que o upload declarou. Nao ha
--      verificacao de conteudo: arquivo com mime errado sai classificado errado.
WITH doc AS (
  SELECT
    d.id                                                  AS id_documento,
    d.cliente_id                                          AS id_cliente,
    NULLIF(TRIM(d.nome_original), '')                     AS nome_original,
    NULLIF(TRIM(d.caminho), '')                           AS caminho,
    NULLIF(TRIM(d.mime_type), '')                         AS mime_type,
    NULLIF(d.conteudo_extraido, '')                       AS conteudo_extraido,
    d.enviado_por                                         AS id_usuario_envio,
    d.criado_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_ia_cliente_documentos` d
)
SELECT
  doc.id_documento,
  doc.id_cliente,
  cl.nome                                                 AS cliente_nome,
  (cl.id IS NULL)                                         AS flag_cliente_nao_catalogado,
  doc.nome_original,
  doc.caminho,
  doc.mime_type,
  -- Familia de arquivo, derivada do mime declarado no upload. Categoria fechada: o que
  -- nao casa vira 'OUTRO' e continua visivel, nunca NULL silencioso.
  CASE
    WHEN doc.mime_type LIKE 'application/pdf%'   THEN 'PDF'
    WHEN doc.mime_type LIKE 'image/%'            THEN 'IMAGEM'
    WHEN doc.mime_type LIKE '%zip%'              THEN 'COMPACTADO'
    WHEN doc.mime_type IS NULL                   THEN 'NAO_DECLARADO'
    ELSE 'OUTRO'
  END                                                     AS tipo_arquivo,
  doc.conteudo_extraido,
  LENGTH(COALESCE(doc.conteudo_extraido, ''))             AS chars_conteudo,
  (doc.conteudo_extraido IS NULL)                         AS flag_sem_conteudo,
  doc.id_usuario_envio,
  doc.criado_em,
  CURRENT_TIMESTAMP()                                     AS _extraido_at,
  'mysql-yIOn'                                            AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(doc)))                        AS _payload_hash
FROM doc
LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbclientes` cl
  ON cl.id = doc.id_cliente
