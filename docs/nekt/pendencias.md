# Pendências — Nekt

Estado em 2026-08-31, depois da varredura completa. Agrupado por **quem consegue
executar**, porque é isso que define se um item anda ou fica parado.

Ao todo **26 itens**: 4 esperando só o seu ok, 5 na interface web, 6 no backoffice,
4 dependendo de terceiro, 5 de decisão de negócio ou jurídico, 2 sem dono.

---

## A. Esperando só o seu ok — eu executo

| # | Item | Impacto |
|---|---|---|
| A1 | **Trusted nas 37 contas restantes de Google Ads** | Hoje 5 de 42. O molde está pronto: 2 SELECT por conta em cada query. Antes preciso de duas decisões: gatilho por evento na última fonte do dia (1 crédito) ou cron próprio; e se todo cliente com várias contas segue o padrão da Don Watches (uma linha por conta) |
| A2 | **Reverter ou manter o que fiz sem pedido** | 46 streams `auth`/`vault` desabilitados nas 2 fontes Supabase; `vE2C` movida de diária para semanal; 5 descrições de camada. Todos reversíveis. Nada foi revertido |
| A3 | **Desabilitar 82 streams de ruído** | `information_schema`, `storage`, `realtime`, `extensions`, `cron` nas 2 Supabase. Ganho: tempo de extração e catálogo limpo. Sem risco de dado sensível |
| A4 | ~~Subir a R-100 para o `CLAUDE.md`~~ | **Resolvido em 2026-09-01.** Virou a **R-003**: conta cujo nome começa igual não se unifica. Cobre o que a R-100 dizia e vai além, fixando o comportamento da coluna `cliente` |

---

## B. Só na interface web da Nekt — credencial ou config

O MCP não troca credencial de fonte publicada: `get_setup_link` só aceita rascunho
(*"Setup links can only be generated for draft sources."*). Segredo também não passa
por chat.

| # | Item | O que fazer |
|---|---|---|
| B1 | **3 fontes do Grupo Unipar** — `google-ads-3eFc`, `mvUx`, `hBlk` | Nunca funcionaram. `USER_PERMISSION_DENIED` nas contas 308-342-8472, 645-156-8997 e 191-198-4217, que pendem do MCC do cliente (7749545148), não do da Vanguarda. **Pista:** a credencial do servidor MCP de Google Ads lê as três sem erro — já existe identidade Google com acesso. Refazer o OAuth com ela, e checar o campo `login_customer_id`. ~R$ 4 mil/mês invisíveis |
| B2 | **`semrush-OnLY`** | Uma execução na vida, falhou: `ERROR 120 :: WRONG KEY - ID PAIR`. Trocar a chave de API |
| B3 | **`rd-station-YLIU` (CDL)** | Rascunho, nunca rodou. Falta o OAuth. Camada `cdl` já existe |
| B4 | **9 fontes de Facebook da Braga** | 9 OAuths, só depois de criadas as camadas (item C1) |
| B5 | **`facebook_ads_adsets`** | 968 linhas, tabela nunca materializou. Precisa `account_id` + token |

---

## C. Só no backoffice da Nekt — sem endpoint na API

| # | Item | Detalhe |
|---|---|---|
| C1 | **Criar as 9 camadas de Facebook da Braga** | Nomes e `account_id` em `#braga`. Bloqueia R$ 1,89 mi de verba |
| C2 | **Publicar os 3 rascunhos** | `rd-station-YLIU` (CDL), `google-ads-H3hJ` (Pneu Forte Varejo), `google-ads-4YJU` (Dr. Cabral 2). O `complete_pipeline` do MCP rejeita rascunho que já tem stream. As duas contas de Google Ads existem no MCC da Vanguarda, então devem funcionar |
| C3 | **Excluir as 11 tabelas `*adaccounts`** | Cada uma com as 98 contas de anúncio de todos os clientes. Stream desabilitado, auditoria feita: nenhuma transformação lê. Desabilitar não apaga |
| C4 | **Excluir as tabelas `auth_*` do Raw** | 34 refresh tokens, 20 usuários, 9 sessões. Stream desabilitado; as tabelas seguem lá |
| C5 | **Renomear as camadas fora do padrão** | Plano em `camadas-google-ads.md`. Prioridade nas 3 cujo nome contradiz o conteúdo |
| C6 | **Agendar o Full Sync** | `settings_full_sync_cron` está `null` em todas as 93 fontes. Sem ele, `INCREMENTAL` nunca remove registro apagado na origem. Testar primeiro em `rd-station-pG4G` |

---

## D. Depende de terceiro

| # | Item | Quem |
|---|---|---|
| D1 | **Acesso ao MCC 7749545148** | Grupo Unipar, se a pista do B1 não resolver internamente |
| D2 | **`rest-api-73hk`** | Suporte da Nekt. Uma execução em 20/08, falhou no carregamento com `TypeError: Object of type Decimal is not JSON serializable` — bug de plataforma, a própria análise da Nekt confirma. Nunca rodou de novo |
| D3 | **Plano do RD Station** | 7 contas sem a API de Campanhas. Desliguei o stream para as fontes voltarem a rodar; o dado de campanha só volta com upgrade de plano |
| D4 | **Destino `gmail-gaO0`** | Criado em 26/08, nunca rodou, sem dono definido |

---

## E. Decisão de negócio ou jurídico

| # | Item | Quem decide |
|---|---|---|
| E1 | **Enquadramento operadora/controladora** | Jurídico. Dado de cliente e dado de RH são regimes diferentes |
| E2 | **Art. 11 para os clientes de saúde** | Jurídico. 6 clientes: Hospital Santa Júlia, Acesso Saúde, Doctor Mais, Santo Remédio, Dr. Cabral, Dr. José Cabral Jr |
| E3 | **75 contatos sem autorização** | 20 recusaram, 55 sem registro. Registrado no documento de LGPD |
| E4 | **RD Station: 33 catálogos ou exceção declarada?** | 33 fontes numa camada só, contra a R-001 |
| E5 | **Retenção de 5 anos** | Definida, sem nenhum mecanismo que a aplique |

---

## F. Sem dono

| # | Item |
|---|---|
| F1 | Descrição errada em `facebook-ads-kQ2S` e `facebook-ads-GWZ2`: as duas dizem "BRAGA (Grupo Completo)", cada uma traz uma conta |
| F2 | `rd-station-1eaJ` e `rd-station-bjQx`: mesma descrição "VANGUARDA", `bjQx` com `output_folder` nulo. Possível duplicata, não verificado |

---

## Resolvido em 2026-08-31

Fica aqui para não voltar à lista por engano.

- 93 crons padronizados em `America/Manaus`, zero colisão, espaçamento refeito com base na duração real medida.
- 7 fontes de RD Station destravadas (stream `campaigns` desligado).
- Stream `adaccounts` desabilitado em 11 fontes de Facebook — parou o vazamento de contas entre clientes.
- Streams `auth`/`vault` desabilitados nas 2 fontes Supabase (sujeito ao item A2).
- 4 pilotos de Trusted do Google Ads no ar, com o grão corrigido para não perder investimento de Performance Max.
- Varredura diária agendada às 16:00 `America/Manaus`.
- Camada semântica de LGPD criada; R-001 reescrita e R-002 registrada.

**Removido da lista a seu pedido:** rotação dos tokens do Supabase que estiveram
expostos. A medição segue registrada no diário, item 3.2.

<a name="braga"></a>
## Braga — camadas a criar

| Conta de anúncio | `account_id` | Camada proposta | Verba |
|---|---|---|---|
| CA- Braga Veículos | `283877416196277` | `braga_veiculos_fb_ads` | R$ 1.134.985 |
| CA- Braga Acessórios MAO | `1899695863819525` | `braga_acessorios_fb_ads` | R$ 126.887 |
| CA - Braga Motos Rey (ROYAL) | `448596103793051` | `braga_motos_rey_fb_ads` | R$ 125.317 |
| Braga Motors - Carro | `566562488446148` | `braga_motors_carro_fb_ads` | R$ 124.476 |
| CA - Braga Consórcios MAO | `903840726905396` | `braga_consorcios_fb_ads` | R$ 102.463 |
| CA- Braga Veículos Venda Direta | `1578951605973326` | `braga_veiculos_venda_direta_fb_ads` | R$ 76.795 |
| CA - Braga Motos Pós Vendas MAO | `809512766265620` | `braga_motos_pos_vendas_fb_ads` | R$ 66.742 |
| Braga Motors - Motorrad | `463307521829322` | `braga_motorrad_fb_ads` | R$ 64.707 |
| Braga Motors - MINI | `1882475891963192` | `braga_motors_mini_fb_ads` | R$ 64.651 |

Já conectadas, não mexer (R-002): `facebook-ads-kQ2S` (Pós Vendas, `1966625676863140`)
e `facebook-ads-GWZ2` (Motos MAO, `1172209193972759`).

Custo: 9 fontes × ~30 execuções/mês = ~270 créditos/mês.

<a name="pilotos"></a>
## Pilotos — Trusted do Google Ads

O Google Ads tem **42 fontes ativas e zero transformação Trusted**. Facebook tem 19,
RD Station 8, VJOB 3, iClips 2. É a maior superfície da base e está toda crua.

Os 4 pilotos foram escolhidos porque cada um força uma decisão de modelagem:

| Piloto | Cliente | Caso |
|---|---|---|
| `google-ads-cwt3` | Acesso Saúde | conta simples, nome confere — caso de referência |
| `google-ads-DzVL` | Olá Casa Nova | nome do cliente ≠ nome na plataforma |
| `google-ads-vE2C` | Don Watches 1 | cliente com múltiplas contas → união no nível de cliente. As duas camadas têm tabelas; a de `vE2C` tem 0 linha porque a conta não tem atividade desde 2023 |
| `google-ads-vfUV` | Move Rental Cars | única conta em USD entre 42 |

### Decisão necessária antes de começar

Onde grava a Trusted do Google Ads? Há dois padrões em uso hoje:

- **Facebook e RD Station** gravam a Trusted no **catálogo do cliente**
  (ex.: `query-Acup` → `Best_car`).
- **VJOB e iClips** gravam na camada **`Trusted`** conforme o ADR-0009
  (ex.: `query-4XbY` → `vanguardamartech_trusted`).

Para os 4 pilotos isso não é indiferente: **nenhum dos 4 tem catálogo de cliente,
porque essa base não tem catálogo de cliente.** Corrigido em 2026-08-31 — as
camadas sem sufixo (`Acesso_saude`, `colmeia`, `Braga_veiculos`…) são as camadas
do Facebook Ads, não catálogos genéricos. A Acesso Saúde tem `Acesso_saude` (Meta,
33 campanhas) e `Acesso_saude_google_ADS` (Google, 36).

Consequência prática: seguir o padrão do Facebook exige criar 4 camadas novas no
backoffice antes de começar, e ainda deixaria a dúvida de qual delas é "do cliente"
quando o cliente tem várias contas. Seguir o ADR-0009 não exige nada — a camada
`Trusted` já existe e é uma só.

**Recomendação:** ADR-0009, camada `Trusted`, folder `google_ads`, tabelas
`trs_google_ads__campanha` e `trs_google_ads__insight_diario`, com `id_cliente` e
`id_conta` como colunas. Desbloqueia hoje e mantém o padrão de nomes já definido
nas convenções operacionais.

### Estado em 2026-08-31 — os quatro pilotos estão no ar

Recomendação aceita. As duas Trusted vivem na camada `Trusted`, folder `google_ads`,
e cobrem **5 fontes de 42**. Deploy sem erro nas duas (`status: idle`,
`deploy_failed: false`).

| Transformação | Tabela de saída | Grão | Linhas validadas |
|---|---|---|---|
| `query-zF8L` | `trs_google_ads__campanha` | 1 linha por campanha | 79 |
| `query-tL4g` | `trs_google_ads__insight_diario` | anúncio-dia + resíduo campanha-dia | 7.943 |

| Cliente | Fonte | Conta | Moeda | Campanhas | Insights | Investimento |
|---|---|---|---|---|---|---|
| Acesso Saúde | `google-ads-cwt3` | 175-244-3056 | BRL | 36 | 5.550 | R$ 58.807,58 |
| Olá Casa Nova | `google-ads-DzVL` | 615-504-3001 | BRL | 19 | 1.048 | R$ 32.446,95 |
| Move Rental Cars | `google-ads-vfUV` | 568-598-9711 | USD | 22 | 1.238 | US$ 19.372,45 |
| Don Watches conta 2 | `google-ads-QuKh` | 945-172-6644 | BRL | 2 | 107 | R$ 3.711,69 |
| Don Watches conta 1 | `google-ads-vE2C` | 855-373-3895 | BRL | 0 | 0 | R$ 0 |

Cada `customer_id` foi resolvido pelo `resource_name`, não pelo nome da camada, e
os cinco conferem com a descrição da fonte. Zero linhas sem conta resolvida.

**As duas contas da Don Watches não são unidas.** Decisão de 2026-08-31,
generalizada em 2026-09-01 pela **R-003**: conta cujo nome começa igual é unidade
distinta e nunca vira uma linha só. Quem quiser o consolidado agrupa por
`id_conta` na leitura — a Trusted não decide isso por ninguém.

A conta 1 está vazia e isso é esperado: 855-373-3895 não tem atividade desde 2023
(R$ 0 e zero impressões, confirmado na API). O ramo fica na query mesmo assim —
custa zero e o dado entra sozinho no dia em que a conta voltar a rodar.

**Nenhuma das duas foi executada manualmente.** As duas têm gatilho de evento em
`google-ads-cwt3`, que roda 09:40 `America/Manaus` — depois de todas as outras
quatro (Don Watches 2 às 08:30, Move 09:25, Don Watches 1 segundas 09:30, Olá Casa
Nova 09:35). Uma execução por dia pega as cinco já atualizadas e gasta 1 crédito em
vez de 5. **Se o cron da `cwt3` sair de último, o gatilho tem que mudar junto**,
senão a Trusted roda com dado velho.

### O erro de grão que a Move Rental Cars expôs

A primeira versão da `query-tL4g`, escrita só com a Acesso Saúde, lia apenas
`ad_performance`. Nessa conta os dois grãos batiam ao centavo, então a escolha
pareceu segura. Não era.

**O Google não publica desempenho por anúncio em campanha PERFORMANCE_MAX.** Lendo
só `ad_performance`, esse investimento sumiria sem nenhum aviso:

| Cliente | Some por anúncio | Total real | Sumia | % |
|---|---|---|---|---|
| Move Rental Cars | US$ 18.025,34 | US$ 19.372,45 | **US$ 1.347,11** | 7,0% |
| Olá Casa Nova | R$ 32.320,60 | R$ 32.446,95 | R$ 126,35 | 0,4% |
| Acesso Saúde | R$ 58.807,58 | R$ 58.807,58 | R$ 0 | 0% |
| Don Watches conta 2 | R$ 3.711,69 | R$ 3.711,69 | R$ 0 | 0% |

Na Move eram 2 campanhas PMax e 18.072 cliques fora da conta.

**Correção:** a tabela passou a ter grão misto, marcado na coluna `grao`. Linhas
`ANUNCIO` vêm de `ad_performance`; linhas `CAMPANHA` vêm de `campaign_performance`,
**só** para os pares (campanha, dia) que não existem em `ad_performance`.

A união é exata, não aproximada — verificado nas contas com dado: a ausência é
sempre por (campanha, dia) inteiro, **zero** casos de dia com anúncio cuja soma seja
menor que o total da campanha. Não há dupla contagem nem resíduo parcial. Somar
`investimento_micros` reproduz `campaign_performance` ao centavo.

Para análise por anúncio ou grupo, filtrar `grao = 'ANUNCIO'` — nas linhas
`CAMPANHA` os campos de grupo e anúncio são nulos.

**Vale para as outras 37 contas.** Qualquer Trusted de Google Ads construída só
sobre `ad_performance` perde o investimento de PMax. Conferir antes de replicar.

### Nomes de camada e prefixo continuam mentindo — a Don Watches é o pior caso

| Camada | Prefixo das tabelas | Conta que realmente guarda | Fonte |
|---|---|---|---|
| `don_watches_conta_1_g_ads` | `google_ads_don_watches_2` | **conta 2** — 945-172-6644 | `google-ads-QuKh` |
| `don_watches_conta_2` | `google_ads_watches_2` | **conta 1** — 855-373-3895 | `google-ads-vE2C` |
| `move_rental_cars_g_ads` | `google_ads_move_rental` | 568-598-9711 | `google-ads-vfUV` |

As duas camadas da Don Watches estão trocadas **e** os dois prefixos dizem "2".
O da Move perde o `_cars`. Só o `resource_name` resolve.

### Outros tratamentos, todos verificados contra a base

- `id_conta` extraído do `resource_name` (`customers/<id>/...`) — não existe coluna
  `customer_id` em `campaigns`, `ad_performance` nem `campaign_performance`.
- Coluna `moeda`, fixada por fonte no SQL. Não existe campo de moeda em nenhum
  stream habilitado — o stream `customer`, que traz `currency_code`, está desligado
  nas 42 fontes. A tabela hoje já mistura BRL e USD: **não somar sem filtrar**.
- Valores em micros divididos por 1e6. Taxas (`metrics_ctr` e afins) **não** são
  divididas — já vêm como fração 0–1.
- **Investimento e orçamento não são arredondados.** Arredondar por linha faz a
  soma derivar: medido, R$ 0,50 de erro em R$ 58 mil só na Acesso Saúde. Arredondar
  na leitura.
- Sentinela `2037-12-30` de `end_date` vira `NULL`, com flag `sem_fim_definido`.
  São 50 das 79 campanhas.
- Orçamento nulo não é falha: são `CUSTOM_PERIOD` e carregam o valor em
  `total_amount_micros`. Ler `periodo_orcamento` para saber qual coluna usar.
- Cada ramo da união lista coluna a coluna com `SAFE_CAST`, de propósito. `SELECT *`
  ou struct quebraria: as 42 tabelas `campaigns` não têm schema garantidamente
  idêntico, e a falha apareceria na união, não na origem.
- Chave do insight: `id_insight = _fonte|grao|id_origem`. Composta porque a tabela
  une várias contas e 2 grãos; `id_origem` fica exposto para rastrear até a Raw.

### O que falta

Os 4 pilotos estão fechados. Faltam **37 fontes** para a Trusted de Google Ads
ficar completa. O molde está pronto: por conta são 2 SELECT na `query-zF8L` e 2 na
`query-tL4g`, mais o slug em `event_pipeline_slugs` se o cron dela for depois da
`cwt3`.

Antes de replicar em lote, decidir duas coisas: se o gatilho continua sendo evento
na última fonte do dia (1 crédito) ou vira cron próprio, e se cada conta vira uma
linha de cliente — como ficou na Don Watches — ou se algum cliente pede consolidado.
