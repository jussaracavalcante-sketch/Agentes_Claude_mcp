# Pendências — Nekt

Estado em 2026-08-31. Agrupado por quem consegue executar.

## Só no backoffice / UI da Nekt

Sem endpoint na API e sem ferramenta no MCP.

| # | Item | Detalhe |
|---|---|---|
| 1 | Criar 9 camadas Facebook da Braga | Nomes propostos em `#braga`. Bloqueia a integração de R$ 1,89 mi de verba |
| 2 | Publicar 2 drafts do Google Ads | `google-ads-H3hJ` (Pneu Forte Varejo), `google-ads-4YJU` (Dr. Cabral 2). Config completa e validada; o MCP não publica por conflito de streams |
| 3 | Excluir 11 tabelas `*adaccounts` | Cada uma tem 98 contas de anúncio de todos os clientes. Stream já desabilitado; auditoria de dependência feita — nenhuma transformação lê |
| 4 | Excluir tabelas `auth_*` do Raw | 34 refresh tokens, 20 usuários, 9 sessões. Stream já desabilitado |
| 5 | Renomear camadas fora do padrão | Plano em `camadas-google-ads.md`. Prioridade: as 3 com nome contradizendo o conteúdo |
| 6 | Agendar Full Sync semanal no RD | Campo `settings_full_sync_cron`, hoje `null` em todas. Destrava exclusão de titular. Testar primeiro em `rd-station-pG4G` (127 contatos) |

## Depende de credencial no navegador

O segredo não passa pelo chat.

| # | Item | O que falta |
|---|---|---|
| 7 | `rd-station-YLIU` (CDL) | OAuth. Camada `cdl` já criada (`2732d2c6-def9-4156-8f3b-3a57d2745e97`) |
| 8 | 9 fontes Facebook da Braga | 9 OAuths, depois de criadas as camadas do item 1 |
| 9 | `facebook_ads_adsets` | 968 linhas, tabela nunca materializou. Precisa `account_id` + token |

## Decisão de negócio ou jurídico

| # | Item | Quem decide |
|---|---|---|
| 10 | Enquadramento operadora/controladora | Jurídico. Dado de cliente vs dado de RH são regimes diferentes |
| 11 | Art. 11 para clientes de saúde | Jurídico. 6 clientes: Hospital Santa Júlia, Acesso Saúde, Doctor Mais, Santo Remédio, Dr. Cabral, Dr. José Cabral Jr |
| 12 | 75 contatos sem autorização | 20 recusaram, 55 sem registro. Marcado como pendência no documento LGPD |
| 13 | RD Station: 33 catálogos ou exceção declarada? | 33 fontes numa camada só. Contraria a R-001 |
| 14 | Reverter o que foi feito sem pedido? | Streams `auth`/`vault` nas 2 fontes Supabase; `vE2C` semanal; 5 descrições de camada. Todos reversíveis |
| 15 | Rotacionar tokens do Supabase | Os 34 refresh tokens estiveram no warehouse por tempo indeterminado |
| 16 | Revisar `supabase-fEvu` | 84 streams habilitados, 1 é dado de negócio. Praticamente redundante — o VJOB real vem pelo schema `bronze` da `x0tz` |

## Posso fazer, aguardando ok

| # | Item | Impacto |
|---|---|---|
| 17 | Desabilitar 82 streams de ruído | `information_schema`, `storage`, `realtime`, `extensions`, `cron` nas 2 Supabase. Ganho: tempo de extração e catálogo limpo. Sem risco |
| 18 | Trusted do Google Ads | Ver `#pilotos`. 3 de 4 pilotos no ar; falta Don Watches |
| 19 | Levantamento completo de autorização no RD | Hoje medido em 4 de 34 clientes. Preciso descobrir o prefixo de tabela de cada um |
| 20 | Subir a R-100 para o `CLAUDE.md` | Citada na descrição de `query-KVas` ("conta não equivale a cliente"), não está registrada em lugar nenhum |

## Sem dono

| # | Item |
|---|---|
| 21 | 9 contas de Facebook da Braga fora do warehouse — R$ 1,89 mi, 82% da verba do grupo |
| 22 | Descrição errada em `facebook-ads-kQ2S` e `facebook-ads-GWZ2`: ambas dizem "BRAGA (Grupo Completo)", cada uma traz uma conta |
| 23 | `rd-station-1eaJ` e `rd-station-bjQx`: mesma descrição "VANGUARDA", `bjQx` com `output_folder` nulo. Possível duplicata, não verificado |
| 24 | Destino `gmail-gaO0` criado em 26/08, nunca rodou |
| 25 | Retenção de 5 anos definida sem mecanismo que a aplique |

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

### Estado em 2026-08-31 — três dos quatro pilotos estão no ar

Recomendação aceita. As duas Trusted vivem na camada `Trusted`, folder `google_ads`,
e cobrem **3 das 42 contas** de Google Ads. Deploy sem erro nas duas
(`status: idle`, `deploy_failed: false`).

| Transformação | Tabela de saída | Grão | Linhas validadas |
|---|---|---|---|
| `query-zF8L` | `trs_google_ads__campanha` | 1 linha por campanha | 77 |
| `query-tL4g` | `trs_google_ads__insight_diario` | anúncio-dia + resíduo campanha-dia | 7.836 |

| Cliente | Fonte | Conta | Moeda | Campanhas | Insights | Investimento |
|---|---|---|---|---|---|---|
| Acesso Saúde | `google-ads-cwt3` | 175-244-3056 | BRL | 36 | 5.550 | R$ 58.807,58 |
| Olá Casa Nova | `google-ads-DzVL` | 615-504-3001 | BRL | 19 | 1.048 | R$ 32.446,95 |
| Move Rental Cars | `google-ads-vfUV` | 568-598-9711 | USD | 22 | 1.238 | US$ 19.372,45 |

Cada `customer_id` foi resolvido pelo `resource_name`, não pelo nome da camada, e
os três conferem com a descrição da fonte. Zero linhas sem conta resolvida.

**Nenhuma das duas foi executada manualmente.** As duas têm gatilho de evento em
`google-ads-cwt3`, que roda 09:40 `America/Manaus` — depois da Move (09:25) e da
Olá Casa Nova (09:35). Uma execução por dia pega as três já atualizadas e gasta 1
crédito em vez de 3. **Se o cron da `cwt3` sair de último, o gatilho tem que mudar
junto**, senão a Trusted roda com dado velho das outras duas.

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

Na Move eram 2 campanhas PMax e 18.072 cliques fora da conta.

**Correção:** a tabela passou a ter grão misto, marcado na coluna `grao`. Linhas
`ANUNCIO` vêm de `ad_performance`; linhas `CAMPANHA` vêm de `campaign_performance`,
**só** para os pares (campanha, dia) que não existem em `ad_performance`.

A união é exata, não aproximada — verificado nas 3 contas: a ausência é sempre por
(campanha, dia) inteiro, **zero** casos de dia com anúncio cuja soma seja menor que
o total da campanha. Não há dupla contagem nem resíduo parcial. Somar
`investimento_micros` reproduz `campaign_performance` ao centavo.

Para análise por anúncio ou grupo, filtrar `grao = 'ANUNCIO'` — nas linhas
`CAMPANHA` os campos de grupo e anúncio são nulos.

**Vale para as outras 39 contas.** Qualquer Trusted de Google Ads construída só
sobre `ad_performance` perde o investimento de PMax. Conferir antes de replicar.

### Outros tratamentos, todos verificados contra a base

- `id_conta` extraído do `resource_name` (`customers/<id>/...`) — não existe coluna
  `customer_id` em `campaigns`, `ad_performance` nem `campaign_performance`.
- **Prefixo de tabela mente de novo:** a camada é `move_rental_cars_g_ads` mas o
  prefixo das tabelas é `google_ads_move_rental`, sem o `_cars`. Mais um caso para
  a lista de armadilhas do `CLAUDE.md`.
- Coluna `moeda`, fixada por fonte no SQL. Não existe campo de moeda em nenhum
  stream habilitado — o stream `customer`, que traz `currency_code`, está desligado
  nas 42 fontes. A tabela hoje já mistura BRL e USD: **não somar sem filtrar**.
- Valores em micros divididos por 1e6. Taxas (`metrics_ctr` e afins) **não** são
  divididas — já vêm como fração 0–1.
- **Investimento e orçamento não são arredondados.** Arredondar por linha faz a
  soma derivar: medido, R$ 0,50 de erro em R$ 58 mil só na Acesso Saúde. Arredondar
  na leitura.
- Sentinela `2037-12-30` de `end_date` vira `NULL`, com flag `sem_fim_definido`.
  São 48 das 77 campanhas.
- Orçamento nulo não é falha: 13 das 77 campanhas são `CUSTOM_PERIOD` e carregam o
  valor em `total_amount_micros`. Ler `periodo_orcamento` para saber qual coluna usar.
- Cada ramo da união lista coluna a coluna com `SAFE_CAST`, de propósito. `SELECT *`
  ou struct quebraria: as 42 tabelas `campaigns` não têm schema garantidamente
  idêntico, e a falha apareceria na união, não na origem.
- Chave do insight: `id_insight = _fonte|grao|id_origem`. Composta porque a tabela
  agora une 3 contas e 2 grãos; `id_origem` fica exposto para rastrear até a Raw.

### O que falta nos pilotos

| Piloto | Situação |
|---|---|
| `google-ads-cwt3` — Acesso Saúde | no ar |
| `google-ads-DzVL` — Olá Casa Nova | no ar |
| `google-ads-vfUV` — Move Rental Cars | no ar |
| `google-ads-vE2C` — Don Watches | **bloqueado por decisão**: unir as duas contas numa linha de cliente, como a `query-KVas` fez no Facebook. A conta 1 contribui com zero até voltar a ter atividade |

Depois dos 4 pilotos, faltam 38 contas para a Trusted de Google Ads ficar completa.
O molde está pronto: por conta são 2 SELECT na `query-zF8L` e 2 na `query-tL4g`.
