# `rfn_operacao__email_remetente_mensal` — dois terços do e-mail da casa é máquina

**Publicada em 2026-09-29** · `query-n0hh` · Refined / `operacao` · **1.596 linhas** ·
**L2 INTERNAL** · gatilho de evento em `query-TXoY` · alerta ligado · deploy limpo ·
**cadência diária**.

Grão: um **mês**, uma **caixa**, um **domínio de remetente**. Origem:
`trs_gmail__mensagem` (32.911) — que **materializou na madrugada de hoje** e estava sem
nenhuma Refined lendo.

## O achado

**258 dos 342 domínios têm UM único remetente**, e eles carregam **21.512 das 32.911
mensagens (65,4%)**.

| domínio | mensagens | remetentes | meses | de lista |
|---|---:|---:|---:|---:|
| **iclips-mail.com.br** | **12.657 (38,5%)** | **1** | **3** | **0** |
| rdstation.com.br | 4.418 | 1 | 22 | 0 |
| vanguardamartech.com.br | 3.251 | 92 | 22 | 47 |
| google.com | 2.426 | 38 | 32 | 715 |
| transkriptor.com | 1.003 | 3 | 24 | **1.003** |
| semrush.com | 950 | 21 | 21 | 866 |
| business-updates.facebook.com | 808 | 1 | 12 | 808 |
| otter.ai | 602 | 1 | 12 | 591 |
| mlabs.com.br | 555 | 18 | 22 | 19 |
| gmail.com | 487 | **99** | 26 | 0 |

**E a flag de lista não pega o maior deles.** `flag_lista_de_email` (o cabeçalho
`List-Unsubscribe`) cobre **6.151 mensagens (18,7%)** e **nenhuma delas é do iClips** — em
10/2024 foram **9.801 mensagens em 23 dias, 426 por dia**, o máximo de
`mensagens_por_dia_ativo` da tabela inteira (426,13).

**Quem separar "automático" só por essa flag deixa o maior robô do lado humano.** Por isso a
tabela emite `qtd_remetentes_distintos`, `qtd_de_lista`, `qtd_dias_com_mensagem` e
`mensagens_por_dia_ativo` — e **não decide por ninguém**.

## A série tem dois regimes, e o corte é 10/2025

**20.955 das 32.911 (63,7%) carregam o cabeçalho `X-MigratedBy`** — vieram de migração de
caixa, não chegaram aqui.

**A migração preserva a data original, e isso foi medido:**

| período | migradas | nativas |
|---|---:|---:|
| 02/2024 → 07/2025 | tudo | **0** |
| 08/2025 | 715 | 2 |
| **09/2025** | **1.363** | **32** ← mês de transição |
| 10/2025 → 09/2026 | **0** | tudo |

Então a série é história de verdade, mas **antes de 10/2025 ela mede o que a migração trouxe**
(que pode ter tido recorte) e **depois mede o que chegou**. `qtd_migradas`, `qtd_nativas`,
`flag_mes_de_transicao` (15 linhas) e `flag_so_migrada` carregam isso em cada linha.

**Comparar volume de 2024 com o de 2026 sem esse recorte compara coisas diferentes.**

## As outras regras

**R2 — `mensagens_por_dia_ativo` usa o dia com mensagem, não o mês inteiro.** Um domínio que
mandou 400 e-mails em 2 dias e um que mandou 400 em 30 são coisas opostas, e dividir por 30
nos dois casos apaga a diferença.

**R3 — `flag_dominio_interno` é REGRA, não lista fixa.** Casa `%vanguarda%`: hoje pega 4
domínios (`vanguardamartech.com.br`, `vanguardacomunicacao.com.br`,
`gws.vanguardamartech.com.br`, `vanguardateste1.com.br`), 82 linhas e 3.728 mensagens. Lista
fixa é o erro do `tipo_midia` do PI, que tirou R$ 363 mil do acompanhamento — um domínio novo
da casa entraria sozinho aqui e não entraria numa lista. **O que ela não faz é provar que o
domínio é da casa:** `vanguardateste1.com.br` casa e é teste.

**R4 — isto é caixa de entrada.** 64 SENT em 32.911. **Não medir tempo nem taxa de resposta
por aqui**; `qtd_enviadas` existe só para o número ficar visível, nunca como denominador.

**R5 — `qtd_nao_lida_na_extracao` não diz que ninguém leu.** O stream é INCREMENTAL por
`internalDate`: a mensagem é buscada uma vez e nunca relida, então o rótulo `UNREAD` é a
**fotografia da chegada**. São 31.040 de 32.911 (94,3%).

## Classificação L2, com a prova do que não passou

A Trusted é **L4** porque carrega endereço, nome de exibição e assunto. **Nenhum dos três
atravessa** — o grão agrega por **domínio**, `qtd_remetentes_distintos` é contagem e não
lista, e assunto, corpo e nome de arquivo ficam de fora. O que sobra é domínio e número.
Mesmo caminho da `rfn_operacao__custo_peca`, que desceu de nível lendo uma L4.

## Limitações — não contorne

1. **Nem assunto nem endereço individual saem daqui.**
2. **Domínio não é empresa.** `gmail.com` tem 99 remetentes e não é uma organização;
   `vanguardamartech.com.br` tem 92 e é a própria casa.
3. **`qtd_arquivos` é PISO**, herdado da Trusted: o conector achata um nível de partes.
4. **Duas caixas, não a casa inteira** — `VTECH` e `CONTATO`.

**FUSO:** `internalDate` é UTC e a Trusted **já converte**. Não converter de novo.

## Validação

32.911 mensagens · 1.596 linhas · 1.596 chaves · 2 caixas · 342 domínios · 871 remetentes ·
32 meses (02/2024 a 28/09/2026) · **20.955 migradas + 11.956 nativas = 32.911** · 6.151 de
lista · 829 linhas de remetente único com 21.512 mensagens · 82 linhas internas com 3.728
mensagens · 15 linhas de transição · 4.333 com arquivo · 338 respostas · 64 enviadas ·
1,47 GB · zero linhas sem taxa.
