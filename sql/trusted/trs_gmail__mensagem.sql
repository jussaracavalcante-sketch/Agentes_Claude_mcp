-- trs_gmail__mensagem
-- Metadado de mensagem das DUAS caixas corporativas (gmail-cF2Q `vtech@` e
-- gmail-c3ku `contato@`). Grao: uma mensagem numa caixa. Chave: id_mensagem_unico.
--
-- O QUE ELA COMPRA: quem escreveu para a agencia, quando, sobre o que, e por qual
--   caixa. Nao existia nada disto tratado -- as duas fontes rodam desde 01/09 e
--   paravam na Raw.
--
-- **ESTAS SAO CAIXAS DE ENTRADA, E ISSO MUDA TODA LEITURA.** Medido em 2026-09-28:
--   vtech tem **30.480 INBOX contra 12 SENT**; contato **1.997 contra 52**. Nao ha
--   registro do que a casa RESPONDEU. Qualquer indicador de "volume de comunicacao"
--   aqui mede o que CHEGOU -- e dizer o contrario e afirmar o que a base nao afirma.
--
-- **O ROTULO E A FOTOGRAFIA DO INSTANTE EM QUE A MENSAGEM CHEGOU, NAO O ESTADO DE
--   HOJE.** O stream `email` e INCREMENTAL por `internalDate`: a mensagem e buscada
--   uma vez e **nunca mais e relida**. Entao os 29.413 de 30.819 marcados UNREAD na
--   vtech (95,4%) **nao querem dizer que ninguem le a caixa** -- querem dizer que a
--   extracao capturou o rotulo antes de alguem abrir. `flag_nao_lida_na_extracao`
--   tem esse nome por isso, e nao `is_nao_lida`. Pelo mesmo mecanismo, mensagem
--   apagada na origem permanece aqui indefinidamente -- o caso que o documento de
--   LGPD da camada semantica ja declarou em aberto para os contatos do RD.
--
-- **CABECALHO SE CASA SEM CASE, SEMPRE -- e ignorar isso custa ate 4,7%.** O mesmo
--   cabecalho chega em ate QUATRO grafias: `Reply-To`, `Reply-to`, `REPLY-TO`,
--   `reply-to`. Medido em 2026-09-28 na vtech: casando exatamente, `Reply-To` acha
--   21.148 e `Message-ID` 30.314; **com `LOWER()` sobem para 22.196 e 30.819** --
--   1.048 e 505 mensagens a mais. `From`, `Subject` e `Date` so fecham 100% com
--   `LOWER()`. **Nada na contagem de linhas denuncia a perda.**
--
-- FUSO: `internalDate` E UTC de verdade -- e a epoca em milissegundos que a API do
--   Gmail devolve -- entao **`DATETIME(ts, 'America/Sao_Paulo')` esta CERTO aqui**,
--   ao contrario do VJOB e do iClips, que gravam relogio local. Medido, nao herdado,
--   pelo mesmo teste do almoco que esta casa ja usou: lido em SP o volume tem pico as
--   10-12h e 15-18h e **cai as 13h (1.227) e 14h (1.272)**; lido em UTC esse vale
--   cairia as 16-17h, que nao e almoco de ninguem.
--
-- O CORPO DA MENSAGEM NAO E EMITIDO, DE PROPOSITO. `snippet` e
--   `payload.parts[].body.data` continuam na Raw -- marcar, nunca apagar -- e ficam
--   FORA da Trusted: sao 662 MB de texto livre de terceiros, que em cliente de saude
--   ou juridico carrega dado sensivel do Art. 11, exatamente a ressalva que o
--   documento de LGPD faz sobre o `custom_fields` do RD. Assunto e remetente ja
--   respondem quem falou sobre o que; o corpo e outra decisao, e nao foi tomada.
--
-- **A TABELA DEDICADA DE ANEXO EXISTE NO CATALOGO E NUNCA MATERIALIZOU.** O stream
--   `email_attachments` esta habilitado nas duas fontes, com 28 execucoes de sucesso
--   na vtech, e `gmail_vtechemail_attachments` responde `table_not_materialized` --
--   a de contato tambem. Entao `qtd_arquivos` sai do proprio `payload.parts`, e e um
--   **PISO**: o conector achata UM nivel de partes, e anexo dentro de
--   `multipart/mixed` aninhado nao aparece. 3.979 mensagens com arquivo e 4.044
--   partes com `attachmentId` -- contagem minima, declarada.
--
-- CLASSIFICACAO: **L4 PERSONAL_DATA.** Nome, e-mail e assunto de pessoa identificada,
--   em 32.870 linhas. Nao publicar em painel sem recorte aprovado.
--
-- REGRAS
--   1. CHAVE COMPOSTA `(caixa, id)`. Medido: **zero ids em comum entre as duas
--      caixas** hoje, e zero threads -- entao e prevencao, nao correcao. Mas o id do
--      Gmail e por conta, e o catalogo de rotulos ja prova que a colisao acontece de
--      verdade entre contas nesta mesma base.
--   2. O ROTULO DE USUARIO E RESOLVIDO PELA CHAVE COMPOSTA, nunca pelo id sozinho.
--      `Label_1` e "Migrated All Mail" na vtech e "YELLOW_STAR" na contato -- juntar
--      so pelo id atribui o nome errado em silencio. Ver `trs_gmail__rotulo`.
--   3. O REMETENTE SAI EM QUATRO COLUNAS: o cru, o e-mail, o dominio e o nome. **Zero
--      das 32.870 mensagens deixam de resolver o e-mail** pela expressao regular, e sao
--      **342 dominios distintos**. O nome de exibicao existe em 32.288 e **NAO e nome
--      de pessoa em 12.906 delas (39%)** -- o remetente repete o proprio endereco ali.
--      `flag_nome_exibicao_e_endereco` marca o caso; nao foi "corrigido" porque e o que
--      o remetente escreveu.
--   4. `destinatarios` sai como TEXTO CRU, nao como lista. 1.343 mensagens tem mais
--      de um endereco no `To`, e separar por virgula quebra endereco com nome entre
--      aspas contendo virgula. Quem precisar da lista desaninha declarando a regra.
--   5. SPAM E LIXEIRA ENTRAM, marcados. 155 mensagens de SPAM e 1 de TRASH na vtech.
--      Contar "e-mails recebidos" sem filtrar `is_spam` superconta -- a flag existe
--      para o filtro ser uma escolha visivel.
--   6. NENHUM CABECALHO VEM CODIFICADO. Conferido: **zero** assuntos e zero `From`
--      em RFC 2047 (`=?UTF-8?B?...`) -- o conector ja decodificou. Nao aplicar
--      decodificacao por cima.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **Nao ha o que a casa enviou** (64 SENT em 32.870). Nao medir tempo de
--      resposta nem taxa de resposta por aqui.
--   2. O cabecalho `Date` (o que o remetente declarou) sai CRU em texto e nao e
--      convertido: ele traz fuso arbitrario do remetente e formato livre. A data
--      confiavel e `recebido_em`, que e do servidor.
--   3. `is_conversa_respondida` NAO existe: ha `In-Reply-To` em 336 mensagens, o que
--      diz que ALGUEM respondeu algo, nunca que a casa respondeu.
--   4. Os contadores de `trs_gmail__rotulo` sao da API sobre a caixa inteira e **nao
--      se somam** com a contagem daqui.
--   5. As duas caixas andam em cadencia diferente -- `gmail-cF2Q` diaria 04:00 e
--      `gmail-c3ku` **semanal, domingo 01:00**. Esta tabela dispara na diaria, entao
--      a parte `contato` pode estar ate seis dias atrasada. Declarado, nao corrigido.
--
-- VALIDACAO 2026-09-28 (medida na Raw materializada, antes de publicar)
--   32.870 linhas · 32.870 chaves distintas · 30.819 VTECH + 2.051 CONTATO · 24.553
--   conversas · e-mail do remetente resolvido em 32.870 de 32.870 · 342 dominios ·
--   582 sem nome de exibicao e 12.906 em que o nome E o endereco · 16 assuntos vazios ·
--   1.343 com mais de um destinatario · **zero mensagens sem rotulo nenhum**, entao
--   nenhuma flag de rotulo sai NULL · 155 SPAM · 64 SENT · 30.999 nao lidas na
--   extracao · 4.326 com arquivo · 6.133 de lista · 20.955 vindas da migracao ·
--   184 com rotulo de usuario · janela 01/02/2024 a 28/09/2026.
WITH bruto AS (
  SELECT 'VTECH'   AS caixa, 'vtech@vanguardamartech.com.br'   AS conta_email,
         'gmail-cF2Q' AS fonte, e.*
  FROM `vanguardamartech_gmail_vtech`.`gmail_vtechemail` e
  UNION ALL
  SELECT 'CONTATO', 'contato@vanguardamartech.com.br', 'gmail-c3ku', e.*
  FROM `vanguardamartech_gmail_contato_vang`.`gmail_contato_vangemail` e
),
-- REGRA 6 / cabecalho sem case. `LOWER(h.name)` em toda leitura; casar exato perde
-- ate 4,7% e a contagem de linhas nao denuncia.
cab AS (
  SELECT
    b.caixa, b.id,
    (SELECT h.value FROM UNNEST(b.payload.headers) h WHERE LOWER(h.name)='from'        LIMIT 1) AS remetente_bruto,
    (SELECT h.value FROM UNNEST(b.payload.headers) h WHERE LOWER(h.name)='to'          LIMIT 1) AS destinatarios,
    (SELECT h.value FROM UNNEST(b.payload.headers) h WHERE LOWER(h.name)='cc'          LIMIT 1) AS copia,
    (SELECT h.value FROM UNNEST(b.payload.headers) h WHERE LOWER(h.name)='bcc'         LIMIT 1) AS copia_oculta,
    (SELECT h.value FROM UNNEST(b.payload.headers) h WHERE LOWER(h.name)='reply-to'    LIMIT 1) AS responder_para,
    (SELECT h.value FROM UNNEST(b.payload.headers) h WHERE LOWER(h.name)='subject'     LIMIT 1) AS assunto,
    (SELECT h.value FROM UNNEST(b.payload.headers) h WHERE LOWER(h.name)='date'        LIMIT 1) AS data_declarada_no_cabecalho,
    (SELECT h.value FROM UNNEST(b.payload.headers) h WHERE LOWER(h.name)='message-id'  LIMIT 1) AS message_id_rfc,
    (SELECT h.value FROM UNNEST(b.payload.headers) h WHERE LOWER(h.name)='in-reply-to' LIMIT 1) AS em_resposta_a,
    (SELECT COUNT(1) FROM UNNEST(b.payload.headers) h WHERE LOWER(h.name)='list-unsubscribe') AS tem_descadastro,
    (SELECT COUNT(1) FROM UNNEST(b.payload.headers) h WHERE LOWER(h.name)='x-migratedby') AS veio_de_migracao,
    -- `Delivered-To` e multivalorado (50.538 ocorrencias para 30.812 mensagens na
    -- vtech), entao agrega em vez de escolher uma.
    (SELECT STRING_AGG(DISTINCT LOWER(TRIM(h.value)), ' | ' ORDER BY LOWER(TRIM(h.value)))
       FROM UNNEST(b.payload.headers) h WHERE LOWER(h.name)='delivered-to') AS entregue_para
  FROM bruto b
),
-- REGRA 2 - o rotulo de usuario resolve pela chave COMPOSTA. Achatar e reagregar,
-- em vez de subconsulta correlacionada contra outra tabela, que esta base ja
-- registrou que nao roda no BigQuery quando o lado direito cresce.
rot AS (
  SELECT caixa, id_rotulo, nome, is_rotulo_de_usuario
  FROM `vanguardamartech_trusted`.`trs_gmail__rotulo`
),
rotulos AS (
  SELECT
    b.caixa, b.id,
    ARRAY_AGG(lab ORDER BY lab)                                            AS rotulos,
    ARRAY_AGG(r.nome IGNORE NULLS ORDER BY r.nome)                         AS rotulos_de_usuario,
    COUNTIF(lab = 'INBOX')  > 0                                            AS is_inbox,
    COUNTIF(lab = 'SENT')   > 0                                            AS is_enviada,
    COUNTIF(lab = 'SPAM')   > 0                                            AS is_spam,
    COUNTIF(lab = 'TRASH')  > 0                                            AS is_lixeira,
    COUNTIF(lab = 'DRAFT')  > 0                                            AS is_rascunho,
    COUNTIF(lab = 'UNREAD') > 0                                            AS flag_nao_lida_na_extracao,
    COUNTIF(lab = 'IMPORTANT') > 0                                         AS is_marcada_importante,
    COUNTIF(lab = 'STARRED')   > 0                                         AS is_com_estrela,
    MAX(IF(STARTS_WITH(lab, 'CATEGORY_'), lab, NULL))                      AS categoria_gmail
  FROM bruto b, UNNEST(b.labelIds) lab
  LEFT JOIN rot r ON r.caixa = b.caixa AND r.id_rotulo = lab AND r.is_rotulo_de_usuario
  GROUP BY 1, 2
),
-- Anexo pelo proprio payload: a tabela dedicada nunca materializou. PISO, nao total.
anexo AS (
  SELECT
    b.caixa, b.id,
    (SELECT COUNT(1) FROM UNNEST(b.payload.parts) p
      WHERE p.filename IS NOT NULL AND p.filename <> '')                   AS qtd_arquivos,
    (SELECT STRING_AGG(p.filename, ' | ' ORDER BY p.filename) FROM UNNEST(b.payload.parts) p
      WHERE p.filename IS NOT NULL AND p.filename <> '')                   AS nomes_dos_arquivos,
    ARRAY_LENGTH(b.payload.parts)                                          AS qtd_partes
  FROM bruto b
)
SELECT
  -- REGRA 1 - chave composta por prevencao; zero colisao medida hoje.
  CONCAT(b.caixa, ':', b.id)                                               AS id_mensagem_unico,
  b.caixa,
  b.conta_email,
  b.id                                                                     AS id_mensagem,
  b.threadId                                                               AS id_conversa,
  c.message_id_rfc,

  -- REGRA 3 - remetente em tres colunas. Zero mensagens sem e-mail resolvido.
  c.remetente_bruto,
  LOWER(REGEXP_EXTRACT(c.remetente_bruto, r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'))
                                                                           AS remetente_email,
  LOWER(REGEXP_EXTRACT(c.remetente_bruto, r'@([A-Za-z0-9.\-]+\.[A-Za-z]{2,})'))
                                                                           AS remetente_dominio,
  -- CORRIGIDO ANTES DE PUBLICAR. A primeira versao apagava `<...>` do texto inteiro,
  -- entao remetente SEM nome de exibicao (`foo@bar.com`, sem colchetes) saia com o
  -- PROPRIO ENDERECO na coluna de nome -- 582 mensagens, e so 8 sairiam NULL. Agora
  -- so e nome o que vem ANTES do `<`; sem `<`, nao ha nome e a coluna sai NULL.
  NULLIF(TRIM(REGEXP_REPLACE(REGEXP_EXTRACT(c.remetente_bruto, r'^([^<]*)<'), r'^\s*"|"\s*$', '')), '')
                                                                           AS remetente_nome,
  -- E NOME DE EXIBICAO NAO E NOME DE PESSOA em 39% dos casos: 12.906 das 32.870
  -- mensagens trazem o proprio endereco no lugar do nome. A flag existe para ninguem
  -- contar "remetentes com nome" e medir outra coisa.
  (REGEXP_EXTRACT(c.remetente_bruto, r'^([^<]*)<') LIKE '%@%')             AS flag_nome_exibicao_e_endereco,

  -- REGRA 4 - destinatario sai CRU; separar por virgula quebra nome entre aspas.
  c.destinatarios,
  (c.destinatarios LIKE '%,%')                                             AS flag_varios_destinatarios,
  c.copia,
  c.copia_oculta,
  c.responder_para,
  c.entregue_para,

  NULLIF(TRIM(c.assunto), '')                                              AS assunto,
  (NULLIF(TRIM(c.assunto), '') IS NULL)                                    AS flag_assunto_vazio,

  -- FUSO: internalDate E UTC. Aqui a conversao esta certa -- medida, nao herdada.
  b.internalDate                                                           AS recebido_em,
  DATETIME(b.internalDate, 'America/Sao_Paulo')                            AS recebido_em_local,
  DATE(b.internalDate, 'America/Sao_Paulo')                                AS data_local,
  DATE_TRUNC(DATE(b.internalDate, 'America/Sao_Paulo'), MONTH)             AS mes_referencia,
  -- LIMITACAO 2 - o que o remetente declarou, cru. Fuso arbitrario, formato livre.
  c.data_declarada_no_cabecalho,

  r.rotulos,
  r.rotulos_de_usuario,
  r.is_inbox,
  r.is_enviada,
  r.is_spam,
  r.is_lixeira,
  r.is_rascunho,
  r.is_marcada_importante,
  r.is_com_estrela,
  r.categoria_gmail,
  -- Nome escolhido de proposito: NAO e "nao lida", e "nao lida QUANDO foi extraida".
  r.flag_nao_lida_na_extracao,

  (c.tem_descadastro > 0)                                                  AS flag_lista_de_email,
  (c.veio_de_migracao > 0)                                                 AS flag_veio_da_migracao,
  (c.em_resposta_a IS NOT NULL)                                            AS flag_e_resposta_de_alguem,
  c.em_resposta_a,

  a.qtd_arquivos,
  (a.qtd_arquivos > 0)                                                     AS tem_arquivo,
  a.nomes_dos_arquivos,
  a.qtd_partes,
  (a.qtd_partes > 0)                                                       AS is_multipartes,
  b.sizeEstimate                                                           AS tamanho_bytes,

  CURRENT_TIMESTAMP()                                                      AS _extraido_at,
  b.fonte                                                                  AS _fonte,
  'America/Sao_Paulo'                                                      AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(c)))                                           AS _payload_hash
FROM bruto b
LEFT JOIN cab    c ON c.caixa = b.caixa AND c.id = b.id
LEFT JOIN rotulos r ON r.caixa = b.caixa AND r.id = b.id
LEFT JOIN anexo  a ON a.caixa = b.caixa AND a.id = b.id
