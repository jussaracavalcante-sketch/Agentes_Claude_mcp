-- trs_gmail__rotulo
-- Catalogo de rotulos das DUAS caixas de e-mail (gmail-cF2Q vtech@ e gmail-c3ku contato@).
-- Grao: um rotulo em uma caixa. Chave: id_rotulo_unico.
--
-- **A CHAVE E COMPOSTA POR OBRIGACAO, NAO POR PREVENCAO -- e este e o achado que
--   justifica a tabela existir.** Os rotulos de SISTEMA do Gmail (`INBOX`, `SENT`,
--   `UNREAD`, `CATEGORY_*`...) tem id FIXO e IGUAL em toda conta: **15 dos 17 ids da
--   vtech existem tambem na contato**. E o rotulo de USUARIO e pior, porque o id e
--   sequencial POR CONTA e o mesmo id significa coisas diferentes:
--     `Label_1` = **"Migrated All Mail"** na vtech (162 mensagens)
--     `Label_1` = **"YELLOW_STAR"**        na contato (6 mensagens)
--     `Label_2` = "YELLOW_STAR" na vtech -- entao o mesmo NOME tambem troca de id.
--   Medido em 2026-09-28. **Juntar rotulo por id sem a caixa atribui o nome errado em
--   silencio**, nas duas direcoes. E o mesmo mecanismo do `id_gestor` do VJOB, onde o
--   id 24 e `Layane` num catalogo e `Kethlen Nascimento` no outro.
--
-- `flag_nome_diverge_entre_caixas` marca exatamente esse caso -- hoje so o `Label_1`.
--
-- OS CONTADORES SAO DO GMAIL, NAO DA EXTRACAO. `messagesTotal`, `messagesUnread`,
--   `threadsTotal` e `threadsUnread` vem da API e descrevem a CAIXA INTEIRA naquele
--   instante, nao o que esta no warehouse. Sao uteis para saber o que ficou de fora e
--   NUNCA devem ser somados com a contagem de `trs_gmail__mensagem`.
--
-- CLASSIFICACAO: **L2 INTERNAL.** Nome de rotulo e contagem. Nenhum dado de pessoa.
--
-- FUSO: a tabela nao tem coluna de tempo. Nada a converter.
--
-- LIMITACOES -- NAO CONTORNE
--   1. O stream e FULL_SYNC: e uma FOTOGRAFIA do catalogo na ultima carga, sem
--      historico. Rotulo apagado na origem desaparece daqui sem deixar rastro.
--   2. Sao 3 rotulos de usuario em 32 linhas -- o resto e sistema do Gmail. Nao ha
--      taxonomia de negocio nesta caixa.
--   3. `color` sai desaninhada em duas colunas; e preferencia de interface, nao dado.
--
-- VALIDACAO 2026-09-28 (medida na Raw materializada, antes de publicar): 32 linhas,
--   32 chaves distintas, 17 ids distintos, **30 linhas com id compartilhado** (15 ids
--   nas duas caixas), **2 linhas com nome divergente** (o `Label_1` de cada caixa),
--   4 rotulos de usuario, zero sem nome.
WITH uniao AS (
  SELECT 'VTECH'   AS caixa, 'vtech@vanguardamartech.com.br'   AS conta_email, l.*
  FROM `vanguardamartech_gmail_vtech`.`gmail_vtechlabel` l
  UNION ALL
  SELECT 'CONTATO', 'contato@vanguardamartech.com.br', l.*
  FROM `vanguardamartech_gmail_contato_vang`.`gmail_contato_vanglabel` l
),
-- Quantas caixas usam cada id, e quantos NOMES distintos aquele id carrega.
por_id AS (
  SELECT id,
         COUNT(DISTINCT caixa)                       AS caixas_com_o_id,
         COUNT(DISTINCT NULLIF(TRIM(name), ''))      AS nomes_distintos
  FROM uniao GROUP BY id
)
SELECT
  CONCAT(u.caixa, ':', u.id)                         AS id_rotulo_unico,
  u.caixa,
  u.conta_email,
  u.id                                               AS id_rotulo,
  NULLIF(TRIM(u.name), '')                           AS nome,
  u.type                                             AS tipo,
  (u.type = 'user')                                  AS is_rotulo_de_usuario,

  -- O ACHADO, em duas colunas: o id se repete entre caixas, e as vezes com outro nome.
  (p.caixas_com_o_id > 1)                            AS flag_id_compartilhado_entre_caixas,
  (p.caixas_com_o_id > 1 AND p.nomes_distintos > 1)  AS flag_nome_diverge_entre_caixas,

  -- Contadores DA API, sobre a caixa inteira. Nao somar com trs_gmail__mensagem.
  u.messagesTotal                                    AS gmail_mensagens_total,
  u.messagesUnread                                   AS gmail_mensagens_nao_lidas,
  u.threadsTotal                                     AS gmail_conversas_total,
  u.threadsUnread                                    AS gmail_conversas_nao_lidas,

  u.messageListVisibility                            AS visibilidade_na_lista_de_mensagens,
  u.labelListVisibility                              AS visibilidade_na_lista_de_rotulos,
  u.color.textColor                                  AS cor_do_texto,
  u.color.backgroundColor                            AS cor_de_fundo,

  CURRENT_TIMESTAMP()                                AS _extraido_at,
  IF(u.caixa = 'VTECH', 'gmail-cF2Q', 'gmail-c3ku')  AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(u)))                     AS _payload_hash
FROM uniao u
LEFT JOIN por_id p ON p.id = u.id
