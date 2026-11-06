-- trs_vjob__ia_cliente_config
-- Contexto de marca por cliente, do modulo `ia_*` do VJOB real (mysql-yIOn).
-- Grao: uma configuracao por cliente. Chave: id_cliente.
--
-- POR QUE ESTA TABELA EXISTE. A arquitetura de `docs/nekt/contexto-cliente-arquitetura.md`
-- foi escrita presumindo que NAO havia lugar onde a casa autora conteudo de marca.
-- Havia: este modulo, em uso. A §18 da arquitetura manda a IA consumir Gold e Semantic
-- Layer, nunca a Bronze -- entao o contexto precisa existir tratado, nao so na Raw.
--
-- ADOCAO MEDIDA EM 2026-09-24 -- E ELA E PEQUENA, DIGA ISSO JUNTO COM QUALQUER NUMERO
--   3 clientes configurados de 315 cadastrados no VJOB (0,95%), os tres com `ativo = 1`:
--     136 PRESTEX ENCOMENDAS  -- so a URL de referencia. ZERO caractere nos 7 campos
--                                de conteudo. Configuracao aberta e nunca preenchida.
--     336 MOVE RENTAL CARS    -- 8.588 caracteres em 5 dos 7 campos.
--     339 THEREZINHA RUIZ     -- 3.402 caracteres em 6 dos 7 campos.
--   Portanto **2 clientes tem contexto de marca utilizavel**, nao 3. E o que
--   `qtd_campos_preenchidos` e `flag_config_vazia` existem para nao deixar esconder.
--   `fatos_verificados` esta VAZIO NOS TRES -- o campo existe no esquema e ninguem usou.
--
-- FUSO: NADA SE CONVERTE. `criado_em` e `atualizado_em` vem TIMESTAMP direto do MySQL e
--   o relogio ja e local (America/Sao_Paulo). Provado no nivel do conector em 2026-09-23:
--   o mesmo registro carrega o relogio identico no MySQL e no payload bronze do Supabase,
--   e a distribuicao das 57.163 marcacoes de escopo mostra o almoco da casa as 13-14h.
--   Aplicar 'America/Sao_Paulo' aqui SUBTRAIRIA 3 horas de dado ja local -- e a armadilha
--   que custou seis tabelas do iClips e a sétima, a `trs_vjob__job`.
--
-- CLASSIFICACAO: **L3 CONFIDENTIAL**. Biblia de marca, regras inegociaveis e tom de voz
--   sao estrategia de cliente de terceiro. Medido em 2026-09-24 sobre os 3 registros:
--   ZERO ocorrencia de CPF, CNPJ, telefone ou e-mail nos campos livres -- por isso NAO e
--   L4. Mas e **texto livre digitado por pessoa**, entao a medicao e um retrato, nao uma
--   garantia: se o modulo crescer, remedir antes de tratar como L3.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **3 linhas nao sustentam indicador.** Nao derivar taxa de adocao, nao ranquear,
--      nao comparar cliente com cliente. Serve para LER o contexto de quem tem.
--   2. `cliente_nome` vem de `tbclientes` e e ROTULO. Identidade se resolve por
--      `id_cliente`. `flag_cliente_nao_catalogado` acende se o cadastro sumir.
--   3. `provedor_texto_id`, `provedor_imagem_id` e `provedor_video_id` NAO sao emitidos:
--      nao ha tabela de dominio de provedor nesta base, entao o id nao diz nada.
--   4. `ia_usuario_cliente` -- o mapa de quem pode ver qual cliente no modulo -- existe e
--      tem **ZERO linhas**. Nao ha controle de acesso registrado no modulo.
WITH cfg AS (
  SELECT
    c.id                                                    AS id_config,
    c.cliente_id                                            AS id_cliente,
    NULLIF(TRIM(c.nome_exibicao), '')                       AS nome_exibicao,
    NULLIF(TRIM(c.gpt_referencia_url), '')                  AS gpt_referencia_url,
    NULLIF(c.instrucoes, '')                                AS instrucoes,
    NULLIF(c.biblia_resumo, '')                             AS biblia_resumo,
    NULLIF(c.tom_voz, '')                                   AS tom_voz,
    NULLIF(c.palavras_evitar, '')                           AS palavras_evitar,
    NULLIF(c.regras_inegociaveis, '')                       AS regras_inegociaveis,
    NULLIF(c.fatos_verificados, '')                         AS fatos_verificados,
    NULLIF(c.elementos_visuais, '')                         AS elementos_visuais,
    NULLIF(c.observacoes, '')                               AS observacoes,
    (c.ativo = 1)                                           AS is_ativo,
    (c.exigir_midia_imagem = 1)                             AS exige_midia_imagem,
    c.criado_em,
    c.atualizado_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_ia_cliente_config` c
)
SELECT
  cfg.id_config,
  cfg.id_cliente,
  cl.nome                                                   AS cliente_nome,
  (cl.id IS NULL)                                           AS flag_cliente_nao_catalogado,
  cfg.nome_exibicao,
  cfg.gpt_referencia_url,
  cfg.instrucoes,
  cfg.biblia_resumo,
  cfg.tom_voz,
  cfg.palavras_evitar,
  cfg.regras_inegociaveis,
  cfg.fatos_verificados,
  cfg.elementos_visuais,
  cfg.observacoes,
  cfg.is_ativo,
  cfg.exige_midia_imagem,
  -- COMPLETUDE MEDIDA, NAO DIGITADA. Sao os 7 campos de conteudo de marca; a URL de
  -- referencia NAO conta, porque ela aponta para fora e nao e contexto nesta base.
  ( IF(cfg.instrucoes          IS NOT NULL, 1, 0)
  + IF(cfg.biblia_resumo       IS NOT NULL, 1, 0)
  + IF(cfg.tom_voz             IS NOT NULL, 1, 0)
  + IF(cfg.palavras_evitar     IS NOT NULL, 1, 0)
  + IF(cfg.regras_inegociaveis IS NOT NULL, 1, 0)
  + IF(cfg.fatos_verificados   IS NOT NULL, 1, 0)
  + IF(cfg.elementos_visuais   IS NOT NULL, 1, 0)
  )                                                         AS qtd_campos_preenchidos,
  7                                                         AS qtd_campos_possiveis,
  ( LENGTH(COALESCE(cfg.instrucoes,''))
  + LENGTH(COALESCE(cfg.biblia_resumo,''))
  + LENGTH(COALESCE(cfg.tom_voz,''))
  + LENGTH(COALESCE(cfg.palavras_evitar,''))
  + LENGTH(COALESCE(cfg.regras_inegociaveis,''))
  + LENGTH(COALESCE(cfg.fatos_verificados,''))
  + LENGTH(COALESCE(cfg.elementos_visuais,''))
  )                                                         AS chars_contexto,
  -- Configuracao ABERTA e VAZIA nao e configuracao. E o caso do PRESTEX: a linha existe,
  -- `ativo = 1`, e nao ha uma palavra de contexto. Sem esta flag, um COUNT diria 3.
  ( cfg.instrucoes          IS NULL
    AND cfg.biblia_resumo       IS NULL
    AND cfg.tom_voz             IS NULL
    AND cfg.palavras_evitar     IS NULL
    AND cfg.regras_inegociaveis IS NULL
    AND cfg.fatos_verificados   IS NULL
    AND cfg.elementos_visuais   IS NULL )                   AS flag_config_vazia,
  cfg.criado_em,
  cfg.atualizado_em,
  CURRENT_TIMESTAMP()                                       AS _extraido_at,
  'mysql-yIOn'                                              AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(cfg)))                          AS _payload_hash
FROM cfg
LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbclientes` cl
  ON cl.id = cfg.id_cliente
