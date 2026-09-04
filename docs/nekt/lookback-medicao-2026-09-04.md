# Janela de reprocessamento do Google Ads — medida, não presumida — 2026-09-04

## A pergunta

O documento da camada semântica afirma `lookback_window = 7`. Mas isso é texto escrito por
alguém, não leitura da configuração viva. O MCP **redige** o valor
(`"lookback_window": "***"`), e eu não tenho sessão autenticada na interface web da Nekt.

Em vez de confiar no texto ou pedir para alguém abrir a tela, medi a janela pelo
comportamento do dado.

## O método

Se a janela é de N dias, os dias dentro dela foram relidos na última execução e devem estar
próximos da plataforma; os dias fora nunca mais foram lidos e ficaram congelados no valor
da última releitura, enquanto o Google seguiu redistribuindo atribuição. A fronteira
aparece como um **degrau** na divergência.

Comparei dia a dia a conta PMZ GRUPO ECOMM (5210673200) contra a API do Google Ads,
20 dias, de 14/08 a 02/09. A última extração tinha sido 03/09 às 13:43.

Escolhi essa conta porque tem conversão **fracionária** — sinal de atribuição data-driven,
que é o mecanismo que redistribui crédito ao longo do tempo.

## O resultado

| Faixa | Nosso | API | Divergência |
|---|---:|---:|---:|
| 14 a 25/08 — **fora da janela** | 103,07 | 110,53 | **6,8% a menos** |
| 26 a 31/08 — dentro, já assentado | 53,47 | 53,81 | **0,6%** |
| 01 a 02/09 — dentro, ainda movendo | 18,41 | 21,68 | 15,1% |

A mudança de regime cai entre 25 e 26/08 — **7 a 8 dias antes da última extração**. Isso
confirma `lookback_window = 7` por medição.

Os três blocos contam a história completa:

- **Fora da janela:** congelado 6,8% abaixo da plataforma, permanentemente.
- **Dentro e assentado:** 0,6%. A janela funciona.
- **Dentro e recente:** 15,1%. Atribuição em curso, esperado, não é defeito.

**Investimento bateu ao centavo nos 20 dias.** Só conversão se move. Isso vira regra:
divergência de custo contra a plataforma é bug, não atribuição.

### Detalhe dia a dia

| Dia | Nossa | API | Δ |
|---|---:|---:|---:|
| 14/08 | 15,7804 | 16,0055 | 1,4% |
| 15/08 | 5,7846 | 5,7846 | **0** |
| 16/08 | 0,3783 | 2,0761 | 81,8% |
| 17/08 | 13,6363 | 13,6822 | 0,3% |
| 18/08 | 8,8600 | 9,0945 | 2,6% |
| 19/08 | 11,9752 | 13,4024 | 10,6% |
| 20/08 | 6,8269 | 7,1679 | 4,8% |
| 21/08 | 12,8344 | 12,8867 | 0,4% |
| 22/08 | 3,3844 | 4,6774 | 27,6% |
| 23/08 | 2,3983 | 2,6675 | 10,1% |
| 24/08 | 8,4613 | 9,5046 | 11,0% |
| 25/08 | 12,7510 | 13,5847 | 6,1% |
| 26/08 | 8,4497 | 8,4535 | 0,0% |
| 27/08 | 9,7879 | 9,7879 | **0** |
| 28/08 | 6,0776 | 6,0850 | 0,1% |
| 29/08 | 12,8201 | 12,8832 | 0,5% |
| 30/08 | 3,8677 | 3,9235 | 1,4% |
| 31/08 | 12,4711 | 12,6768 | 1,6% |
| 01/09 | 12,5712 | 14,6505 | 14,2% |
| 02/09 | 5,8341 | 7,0283 | 17,0% |

Os percentuais altos em dias de base pequena (16/08, com 0,38 conversão) são ruído de
divisão, não sinal. Por isso o agregado por faixa é a leitura correta.

## Quem está exposto

Só contas com atribuição **fracionária**. Contas com conversão inteira (last-click) batem
exato sempre — a PMZ GRUPO LOJA bateu nos três meses testados, e a BIGAZINE bateu em junho
e julho, divergindo só no mês corrente.

Medido sobre as contas com dado desde junho: **12 das 32 usam conversão fracionária, e
essas 12 carregam R$ 215.011,89 de R$ 270.156,20 — 79,6% do investimento.**

Foram medidas 2 das 12 contra a API. A extrapolação para as outras dez **não foi
verificada** e não deve ser afirmada como se fosse.

## O conserto

Aumentar o `lookback_window` para 30 **não resolve** — só empurra a fronteira. O mecanismo
que corrigiria o passado é `settings_full_sync_cron`, uma ressincronização completa
periódica, hoje **null** em todas as fontes inspecionadas (`google-ads-rSav`,
`facebook-ads-Si4U`).

Uma ressincronização mensal faria o histórico assentar. Isso é mexer em fonte publicada,
então depende de decisão explícita (R-002).

## Onde ficou registrado

Regra **R-113** no documento da camada semântica "Google Ads — Regras de leitura"
(`82777086-c031-4403-9ddc-96557cbf6c43`), com os números e a data. A R-112, que já existia,
avisava que os últimos 7 dias mudam; faltava a outra metade — que dia mais velho que 7
nunca é corrigido.
