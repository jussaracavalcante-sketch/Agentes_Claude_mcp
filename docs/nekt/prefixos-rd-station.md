# RD Station — varredura das 33 fontes

**Data:** 2026-09-01 · **Método:** `get_resource` fonte a fonte, 33 de 33. Nada inferido do nome.
**Dados brutos:** [`prefixos-rd-station.tsv`](prefixos-rd-station.tsv)

Todas as 33 gravam na mesma camada `RD_marketing` (desvio já registrado no CLAUDE.md), então é
um dataset só — mais simples que os 39 do Google Ads. Mas o conteúdo **não** é uniforme.

## Achado 1 — `contacts_details` só existe em 11 das 33

O corte é exato e é a data de criação da fonte:

| Lote | Fontes | `contacts_details` |
|---|---|---|
| 26/08 | **11** | sim |
| 28/08 · 30/08 · 31/08 | **22** | não |

Quem tem, traz 21 campos: telefone pessoal e móvel, cidade, estado, país, cargo, aniversário,
site, redes, tags, `legal_bases`, `custom_fields`. Quem não tem, só `segmentation_contacts`
com 4 campos úteis — uuid, nome, e-mail, data da última conversão.

**Isso é dado que não entra, não é cosmético.** 22 clientes estão com contato pobre. A causa é
o `contacts_extraction_mode` escolhido na criação; o valor vem redigido pela API, então só dá
para confirmar pela lista de streams. Corrigir é na interface web da Nekt, fonte a fonte.

## Achado 2 — quatro fontes possivelmente duplicadas

| Fonte | Descrição | Prefixo | Pasta de saída |
|---|---|---|---|
| `rd-station-1eaJ` | BD - RD STATION - VANGUARDA | `rd_vanguarda_` | 05d890b6 |
| `rd-station-bjQx` | BD - RD STATION - VANGUARDA | `rdvanguarda` | *(nenhuma)* |
| `rd-station-oYKw` | RD_station_marketing | `rd_station_` | **6c0f3234** |
| `rd-station-pDLk` | RD_clientes_vanguarda | `rd_station_marketing` | **6c0f3234** |

As duas primeiras têm descrição idêntica. As duas últimas dividem a mesma pasta. Se estiverem
lendo a mesma conta de RD, são créditos gastos à toa e contagem dobrada em qualquer tabela
consolidada. **Confirmar antes de unir na Trusted.**

## Achado 3 — o prefixo continua não sendo dedutível

33 prefixos, 33 valores distintos, nenhum padrão. Casos que quebram qualquer palpite:

| Cliente | Prefixo | O que muda |
|---|---|---|
| PNEU FORTE | `rd_pneuforte_` | sem separador entre as palavras |
| VANGUARDA | `rdvanguarda` | sem underscore nenhum |
| AMAZON OPEN **MALL** | `rd_openwall_` | grafado "openWALL" |
| INFO**R**CELL | `rd_infocell_` | sem o "r" |
| MILLENIUM SHOPPING | `rd_millennium_shopping` | fonte com um N, prefixo com dois |
| RD_clientes_vanguarda | `rd_station_marketing` | prefixo não tem relação com o nome |

Cerca de metade termina em `_` e metade não — `rd_pmz_` e `rd_colmeia_` têm, `rd_best_car` e
`rd_braga_veiculos` não. Concatenar errado gera nome de tabela inexistente.

## Achado 4 — o conjunto de streams varia

Não é só o `contacts_details`. O total vai de **9 a 14 streams** por fonte:

- `analytics_funnel` (funil de visitantes → contatos → oportunidades → vendas) existe em
  apenas 5: as duas VANGUARDA, `RD_clientes_vanguarda`, MARAVILHA MOTOS, HOPE BAY e VBOT.
- Sete fontes estão sem os três streams `analytics_*` — DMELLO, MILLENIUM, AMAZON OPEN MALL,
  REI DAS MANGUEIRAS, BA ELÉTRICA, STEEL PORT e AMZ IMPORTS ficam com o mínimo.
- `campaigns` está desabilitado em 7, e isso foi **decisão nossa** de 31/08 para destravar as
  fontes que falhavam nesse stream. Não é defeito.

Uma query consolidada precisa tratar cada bloco como opcional, não assumir o mesmo conjunto.

## Consequência para o tratamento

A consolidada de contatos vai ler `contacts_details` onde existe e `segmentation_contacts`
onde não existe, com uma coluna marcando a origem — decisão de 01/09, para destravar os 29
clientes sem tratamento agora em vez de esperar a correção das 22.

Quando as 22 forem corrigidas na interface web, o dado entra sozinho: a query já lê as duas
tabelas, e a coluna de origem passa a dizer `contacts_details` para aquele cliente.
