-- trs_vjob__ia_solicitacao
-- Pedido de peca gerada por IA no modulo `ia_*` do VJOB real (mysql-yIOn).
-- Grao: uma solicitacao. Chave: id_solicitacao.
--
-- ESTE E O MODULO MAIS RECENTE DO VJOB EM ATIVIDADE. Medido em 2026-09-24: a ultima
--   solicitacao e de **17/09/2026 14:08:39** -- mais recente que o ultimo escopo
--   (11/09) e muito mais que o ultimo job (24/08). Quem quiser saber o que a casa esta
--   fazendo AGORA no VJOB olha aqui, nao no modulo de job, que esta parado desde agosto.
--
-- MEDIDO EM 2026-09-24
--   86 solicitacoes, 86 ids distintos, **3 clientes** e **4 usuarios**, de 23/06 a
--   17/09/2026 -- tres meses de operacao.
--   Por cliente: 336 MOVE RENTAL CARS 60 · 339 THEREZINHA RUIZ 25 · 136 PRESTEX 1.
--   Por status: concluido 75 · erro 6 · aguardando_configuracao 3 · erro_imagem 1 ·
--   aguardando_montagem_imagem 1 -- ou seja **75 concluidos e 7 em erro**.
--   Taxa de conclusao **87,2%**. `prompt_final` esta preenchido nas 86.
--   Os 6 `erro` tem prompt de 31.123 caracteres em media, contra 19.759 dos concluidos --
--   **o pedido que falha e o pedido grande**. E observacao de 6 linhas, nao indicador.
--
-- FUSO: NADA SE CONVERTE. `criado_em` e `atualizado_em` vem TIMESTAMP direto do MySQL e
--   ja sao hora local -- provado no nivel do conector em 2026-09-23.
--
-- NORMALIZACAO DECLARADA (R-004: achado cosmetico documenta e segue)
--   `canal` chega em 5 valores na origem -- "Instagram", "Instragram" (erro de
--   digitacao), "instagram", "email" e vazio. Medido: **4 grafias nao vazias viram 2
--   canais** depois da normalizacao (minuscula, erro de digitacao corrigido, vazio ->
--   NULL), e **`canal_origem` preserva o que veio**. Alternativa nao tomada: deixar cru e
--   obrigar quem le a normalizar -- descartada porque 4 valores para 2 canais quebra
--   qualquer GROUP BY.
--   `formato` chega em **12 valores na origem, 11 nao vazios** ("1080x1920",
--   "Post 1080x1080", "carossel", "carrosel com duas imagens"...). Aqui a normalizacao
--   para so na DIMENSAO: `formato_dimensao` extrai o LxA quando existe -- **80 das 86
--   solicitacoes, resolvendo os 11 rotulos em 4 dimensoes distintas** -- e o resto fica
--   em `formato_origem`, cru. **Classificar "post" contra "carrossel" seria adivinhar**:
--   as grafias livres nao formam categoria confiavel, e inventar uma esconderia isso.
--
-- CLASSIFICACAO: **L3 CONFIDENTIAL**. `briefing`, `publico`, `objetivo` e `prompt_final`
--   sao estrategia de campanha de cliente de terceiro. Medido em 2026-09-24 sobre as 86:
--   ZERO ocorrencia de CPF, CNPJ, telefone ou e-mail. Por isso nao e L4 -- mas e CAMPO
--   LIVRE DIGITADO POR PESSOA, entao vale a mesma ressalva que a casa ja declarou para o
--   `custom_fields` do RD Station: nao presumir o conteudo, remedir se o modulo crescer.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **86 linhas e 3 clientes nao sustentam indicador.** Nao derivar produtividade,
--      nao comparar cliente com cliente, nao projetar adocao. A taxa de 87,2% e de UM
--      cliente com 60 pedidos e outro com 25.
--   2. **A peca gerada nao esta NESTA tabela, mas EXISTE.** `prompt_final` e o que foi
--      PEDIDO a IA; o que ela devolveu esta em `trs_vjob__ia_geracao.resultado` (86
--      linhas, 1:1 com esta) e os arquivos em `trs_vjob__ia_geracao_arquivo` (78).
--      **CORRECAO de 2026-09-24:** a primeira versao deste bloco dizia que a peca gerada
--      "nao esta aqui, nao ha coluna com o que ela devolveu" -- eu tinha visto
--      `ia_geracao_arquivos` e presumido que a tabela-pai nao estava no catalogo, sem
--      contar as linhas dela. Estava.
--      O que continua verdadeiro: **nao ha ligacao com `trs_iclips__peca` nem com o
--      escopo do VJOB**, entao a cadeia do modulo nao diz se a peca virou entrega.
--   3. `status` NAO tem tabela de dominio. Os 5 valores sao os que aparecem; `is_concluido`
--      e `is_erro` sao leitura declarada do rotulo, e `status` segue visivel ao lado.
--      Valor novo na origem cai fora das duas flags e permanece visivel em `status`.
--   4. `id_usuario` resolve em `trs_vjob__usuario` (conferido: os 4 ids existem nas 272
--      linhas). O nome NAO e denormalizado -- aquela tabela e L4.
--   5. `atualizado_em` esta preenchido nas 86, mas NAO e carimbo de conclusao: ele se move
--      a cada alteracao. Nao usar para datar quando o pedido ficou pronto.
WITH sol AS (
  SELECT
    s.id                                                  AS id_solicitacao,
    s.cliente_id                                          AS id_cliente,
    s.usuario_id                                          AS id_usuario,
    NULLIF(TRIM(s.tipo_peca), '')                         AS tipo_peca,
    NULLIF(TRIM(s.titulo), '')                            AS titulo,
    NULLIF(s.briefing, '')                                AS briefing,
    NULLIF(TRIM(s.canal), '')                             AS canal_origem,
    NULLIF(s.objetivo, '')                                AS objetivo,
    NULLIF(s.publico, '')                                 AS publico,
    NULLIF(TRIM(s.formato), '')                           AS formato_origem,
    NULLIF(TRIM(s.status), '')                            AS status,
    NULLIF(s.prompt_final, '')                            AS prompt_final,
    s.criado_em,
    s.atualizado_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_ia_solicitacoes` s
)
SELECT
  sol.id_solicitacao,
  sol.id_cliente,
  cl.nome                                                 AS cliente_nome,
  (cl.id IS NULL)                                         AS flag_cliente_nao_catalogado,
  sol.id_usuario,
  sol.tipo_peca,
  sol.titulo,
  sol.briefing,
  sol.objetivo,
  sol.publico,
  sol.canal_origem,
  -- "Instragram" e erro de digitacao de UMA pessoa, nao um canal. Corrigido aqui e
  -- preservado em canal_origem, para a correcao ser auditavel.
  CASE
    WHEN LOWER(sol.canal_origem) IN ('instagram', 'instragram') THEN 'instagram'
    ELSE LOWER(sol.canal_origem)
  END                                                     AS canal,
  sol.formato_origem,
  -- So a DIMENSAO se normaliza. O resto do rotulo e texto livre e fica cru.
  LOWER(REGEXP_REPLACE(
    REGEXP_EXTRACT(sol.formato_origem, r'([0-9]{3,4}\s*[xX]\s*[0-9]{3,4})'),
    r'\s+', ''))                                          AS formato_dimensao,
  sol.status,
  (sol.status = 'concluido')                              AS is_concluido,
  (sol.status IN ('erro', 'erro_imagem'))                 AS is_erro,
  sol.prompt_final,
  LENGTH(COALESCE(sol.prompt_final, ''))                  AS chars_prompt,
  LENGTH(COALESCE(sol.briefing, ''))                      AS chars_briefing,
  sol.criado_em,
  sol.atualizado_em,
  CURRENT_TIMESTAMP()                                     AS _extraido_at,
  'mysql-yIOn'                                            AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(sol)))                        AS _payload_hash
FROM sol
LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbclientes` cl
  ON cl.id = sol.id_cliente
