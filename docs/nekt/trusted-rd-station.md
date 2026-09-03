# Trusted RD Station — consolidação de 30 fontes

**Data:** 2026-09-01 · **Status:** publicado, aguardando primeira execução agendada

| Slug | Tabela | Escopo | Cron (Manaus) |
|---|---|---|---|
| `query-9dz7` | `trs_rd_station__contato` | 30 fontes · 9.999 contatos | 13:10 |
| `query-ehQc` | `trs_rd_station__conversao` | 30 fontes · 17.293 conversões | 13:20 |

Rodam depois da última fonte de RD (12:40) e fora da cadeia do Google Ads.
**Nenhuma fonte foi tocada** — só leitura, conforme a R-002.

## Por que consolidada

O padrão anterior era 2 queries por cliente. Quatro clientes tratados = 8 queries; escalar
para 33 daria **66 queries** para manter. Aqui são 2, com `_fonte` e `cliente` por linha —
mesmo desenho já validado nas Trusted de Google Ads. Ajuda que as 33 fontes gravam todas na
camada `RD_marketing`: um dataset só.

## As três fontes que ficaram de fora

| Fonte | Motivo |
|---|---|
| `rd-station-1eaJ` | Subconjunto estrito de `pDLk`: 168 contatos, todos os 168 estão lá |
| `rd-station-bjQx` | Subconjunto estrito de `pDLk`: 167 contatos, todos os 167 estão lá |
| `rd-station-socq` | Tabelas no catálogo, nunca materializadas — conta de RD vazia |

**Três fontes liam a mesma conta.** Medido por interseção de `uuid`: `pDLk` tem 4.666 contatos
e contém as duas outras por inteiro. Incluir as três triplicaria esses contatos. Como são
subconjuntos, excluí-las não perde uma linha.

`rd-station-oYKw` **não** é duplicata, apesar do nome genérico e de dividir pasta de saída com
`pDLk`: zero `uuid` em comum com qualquer uma. Pasta compartilhada não diz nada sobre conta —
essa hipótese eu levantei e ela não se sustentou.

> **Fica em aberto para a área:** `1eaJ` e `bjQx` seguem ativas, rodando todo dia e gastando
> crédito sem entregar nada que `pDLk` já não traga. Desligar é decisão de vocês (R-002).

## Grão misto por disponibilidade

`trs_rd_station__contato` mistura duas origens, marcadas em `origem_contato`:

| Origem | Fontes | Contatos | Campos |
|---|---|---|---|
| `contacts_details` | 8 | 7.080 | 21 — telefone, cidade, estado, cargo, tags, custom_fields |
| `segmentation_contacts` | 22 | 2.919 | 4 — uuid, nome, e-mail, última conversão |

**`NULL` aqui não significa "não tem".** Um contato sem telefone pode ser um contato sem
telefone, ou um contato de fonte que não extrai telefone. Filtre `tem_detalhe = true` antes de
calcular qualquer taxa de preenchimento — sem isso o número sai errado por construção.

Quando as 22 fontes forem corrigidas na interface web, o dado entra sozinho: a query já lê as
duas tabelas e `origem_contato` passa a dizer `contacts_details` para aquele cliente.

## Armadilhas que este trabalho expôs

- **Catálogo não é existência.** A Nekt cria a entrada no catálogo quando a fonte é
  configurada; a tabela só nasce na primeira execução que escreve dado. Uma tabela pode estar
  listada e não existir — e aí o BigQuery derruba a query inteira, não só aquele ramo. Foi o
  caso da `socq`. **Conferir materialização antes de somar fonte nova.**
- **UTM vem dentro de uma query string.** `traffic_source` não é a fonte: vem como
  `utm_source=Facebook%20Ads&utm_medium=social`. Os valores extraídos continuam
  **percent-encoded** — o BigQuery não tem url-decode nativo, e decodificar é regra de negócio,
  pertence à Refined. Agrupar por `utm_source` sem decodificar racha a mesma fonte em variantes.
- **`payload` é STRUCT na origem.** Unir 30 tabelas por STRUCT quebra se uma tiver formato
  diferente. O union carrega `TO_JSON_STRING(payload)` e extrai depois com `JSON_VALUE`.
- **52% das conversões não têm origem de tráfego.** É ausência na origem, não perda no
  tratamento. Não tratar `NULL` como "direto" ou "orgânico": é desconhecido.
- **Os conjuntos de contato e conversão não coincidem** — 9.360 contatos nos eventos contra
  9.999 na tabela de contato. `LEFT JOIN`, nunca `INNER`.

## O que ainda não foi feito

As 8 queries por cliente que já existiam (Best Car, PMZ, Braga, Colmeia) **continuam rodando**.
Só proponho aposentá-las depois de bater número contra número contra as consolidadas — o que
só dá para fazer após a primeira execução agendada.
