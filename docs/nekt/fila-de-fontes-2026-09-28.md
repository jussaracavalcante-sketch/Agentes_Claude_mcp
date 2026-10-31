# 28/09 — a fila das fontes sem tratamento, resolvida: 3 tratadas e 5 sem o que tratar

Medido em 2026-09-28 contra a tabela materializada, nunca contra o metadado do catálogo.
A fila herdada da sessão anterior tinha **9 fontes**. Depois de medir uma a uma, ela é:
**3 tratáveis (feitas hoje), 1 que já estava tratada, e 5 em que não há o que tratar.**

| fonte | veredito | prova |
|---|---|---|
| `gmail-cF2Q` | **tratada hoje** | `trs_gmail__mensagem` + `trs_gmail__rotulo` |
| `gmail-c3ku` | **tratada hoje** | idem |
| `rest-api-xk4P` | **tratada hoje** | `trs_iclips__peca_categoria` (a segunda tabela não, com medição) |
| `google-ads-wypN` | **já estava tratada** | 38 campanhas em `trs_google_ads__campanha` |
| `rd-station-1eaJ` | **não se trata** | 264 dos 265 contatos já estão em `pDLk` |
| `rd-station-bjQx` | **não se trata** | 263 de 263 já estão em `pDLk` |
| `rd-station-socq` | **nada a tratar** | 34 execuções com sucesso, **zero tabelas materializadas** |
| `supabase-fEvu` | **nada a tratar** | 84 streams, 1 de negócio, **zero linhas** |
| `supabase-3gKz` | **nada a tratar** | 113 streams, 1 de negócio, **zero linhas** |

---

## 1. Gmail — duas caixas, 32.870 mensagens, e três armadilhas

`trs_gmail__rotulo` (`query-tXrB`, 32, L2) → `trs_gmail__mensagem` (`query-TXoY`, 32.870, **L4**).
Cadeia linear: as duas fontes → rótulo → mensagem.

**A chave do rótulo é composta por OBRIGAÇÃO, não por prevenção.** Os rótulos de sistema do
Gmail têm id fixo e igual em toda conta — 15 dos 17 ids da vtech existem também na contato,
o que dá **30 das 32 linhas**. E o de usuário é pior:

| id | na vtech | na contato |
|---|---|---|
| `Label_1` | **Migrated All Mail** (162 msgs) | **YELLOW_STAR** (6 msgs) |
| `Label_2` | YELLOW_STAR | — |

Mesmo id, significado oposto; e o mesmo nome com dois ids. Juntar rótulo por id sem a caixa
atribui o nome errado **em silêncio**, nas duas direções. É o mecanismo do `id_gestor` do
VJOB (id 24 = `Layane` num catálogo, `Kethlen Nascimento` no outro).

**Cabeçalho se casa sem case, sempre — e ignorar isso custa até 4,7%.** O mesmo cabeçalho
chega em até **quatro grafias**: `Reply-To`, `Reply-to`, `REPLY-TO`, `reply-to`. Medido na
vtech:

| cabeçalho | casando exato | com `LOWER()` | perdidas |
|---|---:|---:|---:|
| `Reply-To` | 21.148 | **22.196** | 1.048 (4,7%) |
| `Message-ID` | 30.314 | **30.819** | 505 (1,6%) |
| `Date` | 30.808 | **30.819** | 11 |

`From` e `Subject` só fecham 100% com `LOWER()`. **Nada na contagem de linhas denuncia a perda.**

**São caixas de ENTRADA: 64 SENT em 32.870.** vtech 30.480 INBOX contra 12 SENT; contato
1.997 contra 52. Não há registro do que a casa respondeu — então não se mede tempo nem taxa
de resposta por aqui.

**Os 94,3% "não lidas" não dizem que ninguém lê.** O stream `email` é INCREMENTAL por
`internalDate`: a mensagem é buscada uma vez e **nunca mais é relida**, então o rótulo é a
fotografia do instante em que ela chegou. Por isso a coluna se chama
`flag_nao_lida_na_extracao`, e não `is_nao_lida`. Pelo mesmo mecanismo, mensagem apagada na
origem permanece indefinidamente — o caso que o documento de LGPD já declarou em aberto.

**Fuso medido, não herdado.** `internalDate` **é UTC** (época em milissegundos da API), então
`DATETIME(ts,'America/Sao_Paulo')` está certo aqui, ao contrário do VJOB e do iClips. Prova
pelo teste do almoço que esta casa já usa: lido em SP o volume tem pico às 10-12h e 15-18h e
**cai às 13h (1.227) e 14h (1.272)**; lido em UTC esse vale cairia às 16-17h.

**O corpo não é emitido.** `snippet` e `payload.parts[].body.data` continuam na Raw — 662 MB
de texto livre de terceiros, que em cliente de saúde ou jurídico carrega dado sensível do
Art. 11. Assunto e remetente já respondem quem falou sobre o quê.

**A tabela dedicada de anexo existe no catálogo e nunca materializou**, nas duas fontes, com
28 execuções de sucesso. `qtd_arquivos` sai do próprio `payload.parts` e é um **piso**: o
conector achata um nível de partes. 4.326 mensagens com arquivo.

**Defeito pego antes de publicar:** a primeira versão de `remetente_nome` apagava `<...>` do
texto inteiro, então remetente sem nome de exibição saía com o **próprio endereço** na coluna
de nome — 582 mensagens, e só 8 sairiam NULL. Corrigido para extrair só o que vem antes do
`<`. E **em 12.906 das 32.870 (39%) o nome de exibição É o endereço** — não foi "corrigido",
porque é o que o remetente escreveu; `flag_nome_exibicao_e_endereco` marca.

**Quinto caso de "a busca não devolveu, logo não existe":** `gmail_vtechlabel` não voltou na
busca semântica do catálogo e tem **17 linhas**. Prova de ausência é `COUNT(*)`.

---

## 2. iClips — o catálogo de categorias que explica o `Off` × `OFF`

`trs_iclips__peca_categoria` (`query-Lrtd`, 29, L2, evento em `rest-api-xk4P`).

**É a tabela de domínio que a `trs_iclips__peca_tipo` declarava não ter**: das 22 categorias
distintas usadas nos tipos de peça, **22 casam exatamente e zero ficam de fora**.

**E ela explica por id o que a casa só tinha visto como duplicata de caixa.** A
`rfn_operacao__custo_peca` já registrava que "`Off` e `OFF` são categorias distintas na
origem: a primeira tem 95% de precificação e a segunda zero". O catálogo mostra por quê:

| id | nome | tipos de peça | com valor |
|---:|---|---:|---:|
| 14 | `Off` | 71 | 42 |
| 28 | `OFF` | 52 | 0 |
| 42 | `OFF` | 52 | 0 |
| 43 | `OFF` | 52 | 0 |

**São quatro cadastros**, três deles com o mesmo nome. E `setup` (27) convive com `SETUP` (29).

**Juntar o catálogo às peças POR NOME multiplica, e o número está medido:** somar
`qtd_tipos_de_peca_com_este_nome` entre as 29 linhas dá **413 contra 309 reais** — os 104 a
mais são exatamente os 52 tipos de `OFF` contados três vezes.

**Cobertura: só 309 dos 1.049 tipos de peça (29,5%) têm categoria.** Como as 22 que aparecem
resolvem 22 de 22, o buraco é de **preenchimento na origem**, não de domínio faltando.

**`valor` não é emitido: é zero nas 29.** A coluna prometia ser a segunda fonte de preço que a
cadeia de custo procurou. Emiti-la convidaria a somar e obter zero.

**`raw_workflow_templates` não foi tratada, com medição:** `stepCount` zero nas 24,
`estimatedTotalHours` zero nas 24, `tipoWorkflow` com um único valor, `isActive` verdadeiro
nas 24 — quatro das sete colunas mortas ou constantes. E **não há consumidor**: o
`id_workflow` da `trs_iclips__etapa` é a INSTÂNCIA, com 514.843 valores na faixa 443.594 a
1.396.520, enquanto o template vai de 1 a 25 — **zero ids em comum, e as faixas nem se tocam**.

---

## 3. Google Ads Dr. Cabral — já tratada, e a exclusão foi reconferida

`google-ads-wypN` **não estava fora do tratamento**: contribui **38 campanhas** para
`trs_google_ads__campanha` (827 campanhas, 41 fontes). Ela está fora da
`trs_google_ads__insight_diario` (40 fontes) porque **não tem desempenho nenhum**, e isso foi
reconferido hoje: **zero linhas** em `campaign_performance` e em `ad_performance`, depois de
**12 execuções com sucesso** desde 26/08. A conta tem 38 campanhas e nenhuma entrega.

Das 43 fontes de Google Ads publicadas, 40 estão na união de insight. As três de fora têm
motivo medido: `wypN` (zero desempenho, hoje), `vE2C` (Don Watches 1, conta sem atividade
desde 2023) e `OzfZ` (Prestex, `USER_PERMISSION_DENIED`).

---

## 4. RD Station — a decisão de 01/09 foi reconferida e continua certa

A descrição da `query-9dz7` registrou em 01/09 que `1eaJ` e `bjQx` são **subconjuntos
estritos** de `pDLk`. Os números cresceram; a conclusão não mudou:

| | 01/09 | 28/09 | dentro de `pDLk` hoje |
|---|---:|---:|---:|
| `rd-station-1eaJ` | 168 | **265** | **264** |
| `rd-station-bjQx` | 167 | **263** | **263** |
| `rd-station-pDLk` | 4.666 | **4.757** | — |

**As duas são a mesma conta de RD extraída três vezes.** E `1eaJ` ⊃ `bjQx`: os 263 são os
mesmos uuids, com **zero divergência** em `updated_at` e em `email`, e o mesmo
`MAX(updated_at)` = 24/09/2026 17:57:20 nas três. Incluí-las triplicaria esses contatos.

**O único contato de `1eaJ` que não está em `pDLk` é `teste-diagnostico@example.com`**
("Teste Diagnostico", 04/09/2026). Nada real está invisível.

**`rd-station-socq` (AMZ IMPORTS) é o caso mais nítido desta base de "fonte publicada não é
fonte integrada": 34 execuções, todas com sucesso, diárias às 13:40, e NENHUMA tabela
materializada.** `rd_amz_importscontacts_details` responde `table_not_materialized`. Não há o
que tratar até a conta de RD produzir dado.

---

## 5. Os dois Supabase do VJOB extraem 197 streams e nenhum dado de negócio

| | `supabase-fEvu` | `supabase-3gKz` |
|---|---|---|
| descrição | "fonte de dados VJOB" | "fonte de dados_vanguarda_vjob II" |
| streams habilitados | **84** de 109 | **113** de 113 |
| de negócio | 1 (`public-app_meta`) | 1 (`public-app_meta`) |
| linhas nele | **0** | **0** |
| execuções | 34, todas success, diária 02:45 | 3, todas success, semanal domingo 02:00 |
| duração | ~21 min | ~25 min |

**`supabase-3gKz` tem 27 streams de `auth` e 2 de `vault` HABILITADOS.** É o padrão que a casa
já corrigiu em 31/08 nas outras duas fontes Supabase, e aqui ele voltou numa fonte criada em
**18/09** — depois da correção. Os streams incluem `refresh_tokens`, `sessions`,
`mfa_factors`, `webauthn_credentials`, `one_time_tokens`, `saml_providers` e `oauth_clients`.

**Hoje todas estão VAZIAS** — o projeto Supabase não tem usuário. Esse é o ponto: a janela
que este arquivo declarou fechada para o VJOB (`desabilitar stream não apaga tabela já
materializada`) **está aberta aqui**, e custa zero fechá-la agora. No `supabase-x0tz` ela não
foi fechada a tempo e 34 refresh tokens, 20 usuários e 9 sessões seguem no warehouse desde
agosto.

**Não foi alterado** — a R-002 é explícita: stream de fonte publicada não se mexe sem pedido.
É a única coisa desta varredura que depende de decisão dela.

---

## O que fica aberto, e cada um com causa medida

- **`github-s0VO` desativada** com `401 Bad credentials` — três falhas seguidas em 24, 25 e
  26/09, sem tentativa desde então. Três Trusted e uma Refined não rodam. Troca de credencial
  é na interface web.
- **`supabase-3gKz` com `auth` e `vault` habilitados** e vazios. Decisão dela.
- **Z-API**: rascunho `webhook-v2-nZdJ` pronto, falta digitar a `api_key_value` na tela.
- **Turnover / tempo de casa**: única das cinco perguntas órfãs da camada semântica ainda sem
  resposta, e o bloqueio é acesso à fonte de RH.
