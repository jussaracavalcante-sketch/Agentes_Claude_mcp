# Varredura geral das fontes — 05/10/2026

Escopo: as 99 fontes publicadas na Nekt (94 ativas, 5 inativas). Histórico das 6 últimas execuções de cada uma (`list_pipeline_runs`), logs das que falharam, estado de rascunho/ativação, e cruzamento das contas Google Ads do MCC (1704439246) contra as fontes. Somente leitura, exceto 4 alertas ligados (não comportamental). Nenhum cron, stream, camada ou credencial foi alterado (R-002); nenhum pipeline foi rodado à mão.

## Resultado em uma linha
**88 das 99 fontes estão sãs. 11 têm problema, e nenhum deles se corrige pelo MCP** — todos exigem credencial/OAuth na interface da Nekt, decisão de negócio ou ação em sistema externo.

## Fontes com problema

| fonte | estado | causa medida | o que resolve |
|---|---|---|---|
| `google-ads-AMd2` | ativa, **2 falhas seguidas** (22/09 foi o último sucesso) | `403 CUSTOMER_NOT_ENABLED` na conta **2819044460**. Essa conta **não existe mais no MCC**; os dados dela terminam em **16/07/2025**. O Santo Remédio vivo é a conta **5138016841** (R$ 4.398,65 em 30 dias) | trocar o `customer_id` da fonte na interface (config de fonte viva não passa pelo MCP). A 3ª falha, terça 06/10, desativa a fonte |
| `google-ads-OzfZ` (Prestex) | ativa, último sucesso 08/09, sem execução desde então | `403 USER_PERMISSION_DENIED` na conta 7120717819. **A conta está no MCC da Vanguarda e gasta R$ 11.328,08 em 30 dias**; a credencial da Nekt é que não alcança | reautenticar com a credencial do MCC / `login_customer_id` 1704439246 |
| `google-ads-4YJU` (Dr. Cabral NOVA) | **rascunho**, nunca executou | validação devolve `success` com `streams: []` = a credencial não funciona. Conta 2516918741 gasta **R$ 1.936,79/30d** | OAuth na interface, depois `complete_pipeline` |
| `google-ads-H3hJ` (Pneu Forte Varejo) | **rascunho**, nunca executou | idem. Conta 3998287431, **R$ 779,40/30d** | idem |
| `rest-api-73hk` (iClips projetos) | **inativa**; 4 falhas em 6 runs | `429 Too Many Requests` do iClips na etapa de schema. Falha às 02:30 e também às 11:51, então o horário não é a causa | aumentar a cota no iClips. Consumidor único: `trs_projetos__projeto` (o PI já lê `trs_iclips__projeto`), impacto baixo |
| `semrush-OnLY` | inativa, 7 falhas, última 09/09 | `403 ERROR 120 :: WRONG KEY - ID PAIR` | corrigir API key e Account ID na interface |
| `rd-station-YLIU` (CDL) | inativa, 2 runs, ambas falhas | `403` em `/platform/campaigns` ("You cannot consume this service") — o plano não inclui Campaigns. Foi desativada à mão logo após a falha | desmarcar o stream `campaigns` e reativar, se alguém ainda quiser essa fonte |
| `github-2Upt` | ativa, 2 sucessos, **0 linhas** | log sem erro; a causa (`repositories` ou `start_date`) só se vê na interface | conferir config na interface |
| `webhook-v2-nZdJ` (Z-API) | ativa, sucesso diário, **0 linhas desde 28/09** | a tabela `vanguardamartech_whatsapp_vanguarda_grupos.webhook_v2_vanguarda_gruposwebhook` está vazia: **nada está chegando** | configurar a URL do webhook e o `x-api-key` na instância da Z-API; do lado da Nekt está pronto |
| `facebook-pages-ftS8` | ativa, gatilho manual, **nunca executou** | nunca foi acionada | decisão: dar um cron (R-002) |
| `rd-station-socq` | ativa, 34+ sucessos, **nenhuma tabela** | já registrado | — |

Falhas pontuais já recuperadas, sem ação: 14 fontes Google Ads com 1 falha em 04/09 e sucesso desde 08/09; `rd-station-7K57` (01/10), `rd-station-VYbu` (30/09), `rd-station-9mbj` (15/09).

## O achado que pesa mais: R$ 62.859,28 por mês de Google Ads sem fonte

Cruzando as 88 contas do MCC contra as 45 fontes de Google Ads, **16 contas com gasto nos últimos 30 dias não têm fonte alguma**, mais as duas em rascunho acima. Total sem entrar na Nekt: **R$ 65.575,47 em 30 dias** (Prestex, Santo Remédio e as duas em rascunho incluídos). **Atualização do mesmo dia: as 5 contas Nova Era (R$ 25.856,04) saíram da lista — a Nova Era deixou de ser cliente da agência (ver a seção final). Restam 11 contas sem fonte (R$ 37.003,24) mais as duas em rascunho (R$ 2.716,19).**

| conta | id | gasto 30d (R$) |
|---|---|---:|
| UIARA AMAZON RESORT | 1938326229 | 13.725,52 |
| Prestex (fonte existe, sem permissão) | 7120717819 | 11.328,08 |
| SANTO REMEDIO (conta viva) | 5138016841 | 4.398,65 |
| ECOMM \| PÁTIO GOURMET | 6819144625 | 2.943,02 |
| Dr. Cabral [NOVA] (rascunho) | 2516918741 | 1.936,79 |
| Aço Manaus | 5141358700 | 1.517,71 |
| Hope Bay Park | 4071499349 | 1.509,19 |
| Pneu Forte \| Varejo (rascunho) | 3998287431 | 779,40 |
| JULIA HERRERA | 3820531237 | 736,27 |
| Pátio Gourmet — Loja Física | 9657724454 | 379,79 |
| Tuboaços da Amazônia (2) | 7522971952 | 289,78 |
| CDL Manaus | 6618557333 | 87,82 |
| BRAGA MOTORS — CARRO | 4326096939 | 87,41 |

Origem: medição direta no MCC (`resumo_conta`, `LAST_30_DAYS`) contra a descrição de cada fonte (`customer_id`). O mapa está em `/tmp` e não foi versionado; reproduz-se com `listar_clientes` + `list_resources(kind="source")`.

**Ressalvas de método.** O gasto do MCC cobre 30 dias até 05/10; o da Nekt para o mesmo intervalo vai até 28/09 (última passada de terça), então comparações de valor entre os dois lados têm até uma semana de diferença — o cruzamento acima é de **existência de fonte**, não de valor. Não foi verificado se as Facebook Ads têm o mesmo buraco (não há acesso à Meta por aqui).

**Duas contas com fonte e dado possivelmente atrasado, sem confirmação:** `BRAGA MINI` (8766638384; Nekt termina em 05/06, MCC mostra R$ 68,32 em 30 dias) e `CAA TINTAS` (8837950560; Nekt R$ 0,06 desde 05/09, MCC R$ 261,48). A diferença de janela explica parte, não necessariamente tudo — conferir na passada de terça.

## O que foi feito
- Alertas de falha ligados em `google-ads-AMd2`, `webhook-v2-nZdJ`, `google-ads-OzfZ` e `rest-api-73hk` (estavam desligados).
- Nada mais: as 11 correções acima exigem a interface da Nekt, o Google Ads/Meta ou o iClips.

## O que depende de decisão
1. Quais das 16 contas sem fonte devem entrar. Cada uma pede **nome de camada** (irreversível, R-001: cliente + conta + plataforma, ex.: `nova_era_manaus_ecomm_g_ads`). Posso preparar os rascunhos e o link de OAuth assim que as grafias forem confirmadas.
2. Reautenticar `OzfZ` (Prestex) e trocar o `customer_id` de `AMd2` para a conta 5138016841 — a maior parte do buraco em dinheiro está nessas duas e na UIARA.
3. Ao entrar fonte nova, **a união da Trusted não se atualiza sozinha** (`trs_google_ads__insight_diario`, `__campanha`, dimensão de contas): somar à lista e rodar `LIMIT 0` antes.

## Atualização — Nova Era saiu da agência (05/10, a pedido)

Pedido: desativar as camadas da Nova Era. Medido antes de agir:
- **São três camadas**, todas de Facebook Ads: `Nova_era_` (MAO, 9.239 linhas de insights), `Nova_era_pvh` (Porto Velho, 6.285) e `Nova_era_boa_vista` (13.578). Dado até **31/08/2026**; gasto histórico R$ 236.319,57 + R$ 333.847,97 + R$ 632.672,66.
- **Já estavam sem fonte:** nenhuma das 99 fontes publicadas grava nelas, e a `trs_facebook_ads__insight_diario` consolidada (7 fontes) não as inclui. Não há nada a desligar e nenhuma Trusted/Refined depende delas.
- **Feito:** descrição das três camadas reescrita marcando-as como **DESATIVADAS em 05/10/2026**, com o estado medido, a proibição de uso e o motivo de não terem sido excluídas.
- **Não feito, e por quê:** camada só se exclui vazia, o nome é irreversível e a exclusão de tabela é backoffice na interface da Nekt — decisão de quem manda. O Facebook só re-extrai 37 meses, então apagar perde histórico de 2024.
- **Corrige o que este documento dizia acima:** as cinco contas Google Ads da Nova Era (R$ 25.856,04 em 30 dias) **não** devem entrar como fonte nova.
- **Ponto aberto:** as cinco contas **continuam no MCC da Vanguarda gastando R$ 25.856,04 em 30 dias**. Se a Nova Era saiu, o vínculo no MCC (1704439246) precisa ser desfeito no Google Ads — é ação de quem administra o MCC, não da Nekt.
