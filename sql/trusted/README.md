# SQL da Trusted de Google Ads

Estes dois arquivos são a versão que lê `cliente` e `moeda` da dimensão
`trs_google_ads__conta` em vez dos literais escritos à mão, gerados em 2026-09-03.

| Arquivo | Transformação | Linhas | Ramos |
|---|---|---|---|
| `trs_google_ads__campanha.sql` | `query-zF8L` | 214 | 39 campaigns + 39 campaign_budget |
| `trs_google_ads__insight_diario.sql` | `query-tL4g` | 365 | 39 campaigns + 39 ad_performance + 39 campaign_performance |

## O que mudou

- Removidos os literais por fonte: 78 pares `cliente`/`moeda` no insight, 39 no campanha.
- `cliente` e `moeda` passam a vir de `trs_google_ads__conta`, resolvidos por `id_conta`
  (extraído de `resource_name`, nunca deduzido de nome de camada ou prefixo de tabela).
- Join `LEFT` de propósito: `INNER` descartaria investimento em silêncio se a dimensão
  estivesse desatualizada. Nova coluna `flag_conta_nao_catalogada` acende nesse caso.
- O anti-join do insight (correção de 02/09) está preservado — conferido.

## Verificação feita antes de publicar

- `sqlglot` no dialeto BigQuery: os dois parseiam, e a lista de colunas de saída é
  idêntica à da versão anterior na mesma ordem, mais a flag nova.
- Contagem de ramos e de tabelas distintas bate com 39 fontes.
- Zero literais de moeda restantes.
- **Divergência medida contra as tabelas em produção: nenhuma.** 74 pares
  (36 do insight + 38 do campanha), zero conta ausente na dimensão, zero divergência
  de `cliente`, zero de `moeda`. A refatoração é neutra em valor — o que ela compra é
  estrutural: acaba o ponto onde um erro de digitação passaria despercebido.

## Publicado em 2026-09-03

As duas transformações foram atualizadas na Nekt e o código aqui é **cópia exata do que
está no ar** (baixado com `get_code` depois de publicar, não o rascunho).

Conferência pós-publicação, byte a byte contra a referência local:

| | `query-zF8L` | `query-tL4g` |
|---|---|---|
| Fontes distintas | 39 | 39 |
| Tabelas distintas | 79 | 118 |
| Literais de moeda restantes | 0 | 0 |
| Anti-join preservado | — | sim |
| Diferença para a referência | só a quebra de linha final | só aliases redundantes |

Os 77 pontos de diferença no insight são aliases de coluna nos ramos 2 a 39 da união, que o
BigQuery ignora (o nome da coluna vem do primeiro ramo). Normalizando os aliases, os dois
arquivos são idênticos.

Nada foi executado à mão: as duas rodam no gatilho de sempre, evento na `google-ads-cwt3`,
~12:43 Manaus.

## Por que o arquivo existe

A Nekt não aceita arquivo: `update_transformation` recebe o código como texto. Manter o
SQL aqui dá uma fonte de verdade revisável, e foi o que permitiu conferir a publicação
comparando o que subiu com o que foi verificado.
