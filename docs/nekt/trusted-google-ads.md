# Trusted Google Ads — expansão para 39 contas

**Data:** 2026-09-01 · **Status:** publicado, aguardando a primeira execução agendada

Duas transformações na camada `Trusted`, folder `google_ads`, que leem as tabelas que as
39 fontes de Google Ads **já gravaram** e produzem duas tabelas tratadas.

**Nenhuma fonte foi tocada.** Nem cron, nem stream, nem camada de destino — conforme a R-002.
A expansão é só SQL de leitura.

| Slug | Tabela de saída | Escopo | Grão |
|---|---|---|---|
| `query-zF8L` | `trs_google_ads__campanha` | 39 fontes / 815 campanhas | 1 linha por campanha |
| `query-tL4g` | `trs_google_ads__insight_diario` | 39 fontes / 36 com dado | misto (ver abaixo) |

As duas foram de 5 para 39 fontes em 01/09. Casam por `id_campanha` + `_fonte`.

## O grão misto, e por que ele existe

`trs_google_ads__insight_diario` mistura dois grãos de propósito, marcados na coluna `grao`:

- **`ANUNCIO`** — uma linha por anúncio por dia, de `ad_performance`. É o grão normal.
- **`CAMPANHA`** — uma linha por campanha por dia, de `campaign_performance`, **somente**
  para os pares (campanha, dia) que não existem em `ad_performance`.

O Google não expõe desempenho no nível de anúncio para campanhas `PERFORMANCE_MAX`. Uma
Trusted lida só sobre `ad_performance` perde esse investimento **em silêncio**. Medido em
31/08: Move Rental Cars perdia US$ 1.347,11 de US$ 19.372,45 (7% da conta, 18.072 cliques).

## A premissa, verificada nas 39 contas

O desenho só é exato se a ausência for sempre por **campanha-dia inteiro**. Se houvesse
atribuição parcial — um dia com alguns anúncios mas soma menor que o total da campanha —
a união por presença contaria a menos, e a query precisaria de resíduo por diferença.

Medido em 01/09 sobre `campaign_performance` das 39 fontes:

| Medida | Resultado |
|---|---|
| Pares (campanha, dia) | 42.758 |
| Pares sem nenhuma linha de anúncio | 9.607 (22,5%) |
| **Pares com cobertura parcial** | **0** |
| **Anúncios órfãos** (sem par em `campaign_performance`) | **0** |
| Total de referência | 1.354.538.045.829 micros |
| Total reproduzido pela Trusted | 1.354.538.045.829 micros |

Bate ao micro. **Se um dia aparecer par parcial, a premissa cai** — é esse teste que deve
ser refeito antes de confiar em qualquer soma.

## Três contas sem linha de desempenho

36 das 39 têm dado. As três sem, verificadas uma a uma — nenhuma é problema da query:

| Fonte | Conta | O que tem | Diagnóstico |
|---|---|---|---|
| `google-ads-vE2C` | DON WATCHES CONTA 1 · 855-373-3895 | zero em tudo, inclusive `campaigns` | Sem atividade desde 2023, confirmado na API do Google: R$ 0, 0 impressões. |
| `google-ads-wypN` | DR. CABRAL CONTA 1 · 738-192-0209 | **38 campanhas**, zero desempenho | **Não é falha.** As 6 execuções desde 26/08 deram sucesso e os streams de performance estão habilitados. A conta não teve entrega na janela extraída. |
| `google-ads-rYKp` | RODRIX MOTOS · 973-940-7801 | 1 campanha, zero desempenho | Mesmo caso, em escala menor. |

Os ramos ficam nas queries: custam zero e o dado entra sozinho quando a conta produzir.

> **Para o time de mídia:** 38 campanhas e nenhum investimento na Dr. Cabral conta 1 é
> sinal de conta parada **ou** de janela de extração curta demais. Vale confirmar qual dos dois.

## Armadilhas que este trabalho expôs

- **Nome de camada e prefixo de tabela não identificam a conta.** `don_watches_conta_1_g_ads`
  guarda a conta 2 e vice-versa; `braga_yamaha_consorcios` guarda a Braga Yamaha/Motos;
  `caa` guarda só a CAA Tintas. A conta se resolve pelo `customer_id` extraído do
  `resource_name` (`customers/<id>/...`), nunca pelo nome. Mapa completo dos 39 prefixos
  em [`prefixos-google-ads.md`](prefixos-google-ads.md), cada um sondado contra a base.
- **Duas famílias de unidade.** Dinheiro vem em micros (÷ 1.000.000); taxas vêm como fração
  de 0 a 1, não percentual. Tratar as duas igual erra por um fator de um milhão ou de cem.
- **Não arredondar por linha.** `ROUND` antes do `SUM` derivou R$ 0,50 em R$ 58 mil.
  `investimento_micros` é a fonte exata; arredonde na leitura.
- **`date` chega como TIMESTAMP**, não DATE. Convertido com `DATE()`, sem deslocar fuso —
  o Google já entrega o dia na timezone da conta.
- **Moeda não existe em nenhum stream.** Fixada por fonte no SQL. BRL em tudo menos a Move
  Rental Cars, que é USD. **Não somar investimento entre clientes sem filtrar `moeda`.**

## O que ainda não foi conferido

O rótulo `cliente` é escrito à mão no SQL — não vem do dado. É o único ponto onde um erro de
digitação passaria despercebido. **Depois da primeira execução agendada**, comparar os pares
distintos `(id_conta, cliente)` das duas tabelas contra o mapa de `prefixos-google-ads.md`.

As queries **não foram executadas manualmente**, por decisão registrada: só rodam no horário
agendado (evento na `google-ads-cwt3`, 12:43 Manaus).
