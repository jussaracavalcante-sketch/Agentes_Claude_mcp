# Breakdowns do Google Ads — a medição da perda, conta por conta

Medido em 2026-09-08 sobre as 39 fontes de Google Ads, comparando cada stream de
breakdown contra a `trs_google_ads__insight_diario` em produção. Janela dos dados:
2025-01-01 a 2026-09-03.

Fecha a pendência que ficou aberta em 04/09: *"medir a faixa real de perda de
`user_location` e `search_term` em mais contas, antes de escrever o número na
descrição das transformações."*

**Total de referência: R$ 1.361.954,19** — reproduz ao centavo o total da
`trs_google_ads__insight_diario`, o que valida o mapeamento fonte → `customer_id`
injetado por ramo nos cinco arquivos.

---

## 1. Idade e gênero: a perda é exatamente o PMax

| | valor | % do total |
|---|---:|---:|
| Total de mídia Google | R$ 1.361.954,19 | 100,0% |
| Investimento em PERFORMANCE_MAX | R$ 271.440,61 | 19,9% |
| Verba não-PMax (**cobertura esperada**) | R$ 1.090.513,58 | 80,1% |
| **Cobertura medida de idade/gênero** | **R$ 1.091.904,50** | **80,2%** |
| Delta | R$ 1.390,92 | 0,13% |

O delta de R$ 1.390,92 não é perda nem sobra: é o dia **03/09 parcial**, presente nos
breakdowns e ausente na Trusted, que materializou antes daquela extração. Isolado na
DEB Transportadora: R$ 237,81 num único dia, sobre um total de R$ 3.714,67 — os 6,4%
que fazem a conta aparecer com "106,4% de cobertura".

**Por conta, `fatia_pmax% + cobertura% = 100%`.** Nas 17 contas com PMax:

| Conta | PMax | Cobertura demográfica | Soma |
|---|---:|---:|---:|
| PMZ ESCOLA DE MECANICOS | 70,2% | 29,8% | 100,0 |
| BIGAZINE | 56,7% | 43,3% | 100,0 |
| COLMEIA | 53,0% | 47,0% | 100,0 |
| SANTO REMEDIO | 48,9% | 51,1% | 100,0 |
| PNEU FORTE DISTRIBUIDORA | 35,6% | 64,4% | 100,0 |
| ARENA TINTAS | 27,1% | 72,9% | 100,0 |
| PMZ GRUPO LOJA | 26,9% | 73,1% | 100,0 |
| BRAGA VAREJO | 25,2% | 74,8% | 100,0 |
| BRAGA MOTORS BMW | 23,1% | 76,9% | 100,0 |
| MILLENIUM | 16,7% | 83,4% | 100,1 |
| BRAGA YAMAHA CONSORCIOS | 16,2% | 84,3% | 100,5 |
| BRAGA YAMAHA | 13,2% | 87,4% | 100,6 |
| CONSTROI INCORPORADORA | 11,9% | 88,1% | 100,0 |
| BRAGA ACESSORIOS | 8,5% | 92,7% | 101,2 |
| MOVE RENTAL CARS | 6,9% | 93,1% | 100,0 |
| HOSPITAL SANTA JULIA | 3,9% | 96,3% | 100,2 |
| OLA CASA NOVA | 0,4% | 99,6% | 100,0 |

As sobras de 0,1 a 1,2 ponto são o mesmo 03/09 parcial, proporcionalmente maior em
conta pequena. **Nas 19 contas sem PMax a cobertura é 100%.**

**Idade e gênero têm cobertura idêntica em todas as 36 contas com dado** — mesmo
mecanismo de supressão, então uma checagem serve para os dois.

Isto encerra a correção de 04/09. A afirmação original — *"age_range, gender e
geographic fecham exato"* — vinha de duas contas de amostra que eram `SEARCH` pura.
A causa é o PERFORMANCE_MAX, que não publica breakdown demográfico, e agora a relação
está medida nas 36 contas, não em 2.

---

## 2. Localização do usuário: perde 6,5%, e não é PMax

| | valor | % do total |
|---|---:|---:|
| Cobertura medida de `user_location` | R$ 1.273.195,67 | **93,5%** |

**Não segue a fórmula do PMax.** A PMZ Grupo Loja tem 26,9% em PMax e ainda assim
90,1% de cobertura de localização — ou seja, o PMax *publica* localização. A perda
vem de outro lugar: impressão cuja localização física do usuário o Google não
resolve.

Piores casos:

| Conta | Cobertura |
|---|---:|
| BRAGA YAMAHA CONSORCIOS | 75,6% |
| BRAGA VAREJO | 77,7% |
| PNEU FORTE DISTRIBUIDORA | 84,1% |
| AMZ GERADORES | 87,5% |
| PMZ GRUPO LOJA | 90,1% |

**Por que o `geographic` fecha e o `user_location` não:** são coisas diferentes.
O `geographic_performance` reporta o alvo geográfico *configurado na campanha* — é
uma definição, sempre existe. O `user_location_performance` reporta onde o usuário
**estava**, e isso pode não ser determinável. Daí um reconciliar em 100% e o outro
em 93,5%.

---

## 3. Termo de busca: 61% da verba de busca, 43% do total

| | valor | % |
|---|---:|---:|
| Investimento em SEARCH + SHOPPING | R$ 959.249,54 | 70,4% do total |
| Cobertura medida de `search_term` | R$ 584.702,31 | **61,0% da busca** / 42,9% do total |

Faixa por conta, contra a verba de busca: **mínimo 15,7% (Millenium), p25 42,8%,
mediana 54,3%, p75 67,6%, máximo 86,8% (Santo Remédio)**.

É o limiar de privacidade do Google: termo com volume abaixo do corte não é
publicado. Não há conserto, e a variação de 15,7% a 86,8% mostra que o corte morde
muito mais em conta de cauda longa.

O denominador correto é a verba de busca, não o total — campanha DISPLAY, VIDEO ou
PMax não tem termo de busca para publicar. Medir contra o total daria 42,9% e faria
parecer defeito o que é definição.

---

## 4. Consequência de projeto

**Nenhum dos cinco breakdowns serve para total de investimento, exceto o geográfico.**

| Trusted | Serve para | Não serve para |
|---|---|---|
| `trs_google_ads__segmento_faixa_etaria` | composição relativa dentro da verba não-PMax | total de verba (falta 19,9%) |
| `trs_google_ads__segmento_genero` | idem, cobertura idêntica à de idade | idem |
| `trs_google_ads__segmento_geografico` | alvo geográfico configurado; **reconcilia em 100%** | confundir com localização real do usuário |
| `trs_google_ads__segmento_localizacao_usuario` | onde o usuário estava | total de verba (falta 6,5%) |
| `trs_google_ads__termo_busca` | análise de query e negativação | total de verba (cobre 43%) |

Isto tem de entrar na descrição das cinco transformações, no bloco de limitações com
"não contorne", e na camada semântica antes de qualquer uma virar consumo. A regra
de leitura é uma frase: **verba se soma na `rfn_midia__desempenho_diario`; breakdown
serve para dividir, nunca para totalizar.**

---

## Método

Lado da verdade: `trs_google_ads__insight_diario` somada por conta, com o canal
resolvido por join na `trs_google_ads__campanha` (`advertising_channel_type`). Zero
linhas do fato ficaram sem dimensão de campanha nas 36 contas — o join fecha.

Lado do breakdown: união dos 39 ramos por stream, `SUM(metrics_cost_micros)/1e6`,
com o `customer_id` injetado como literal por ramo, porque **as tabelas de breakdown
não têm identificador de conta** (nem `account_id`, nem `resource_name`).

Nada foi publicado. Medição de leitura, sem consumo de crédito de pipeline.

---

## Publicado em 2026-09-08

Com o saldo da Nekt restabelecido (a parada foi de 04/09 13:43 a 05/09 14:20), as cinco
Trusted foram publicadas na camada **Trusted**, folder `google_ads`:

| Tabela | Slug | Deploy |
|---|---|---|
| `trs_google_ads__segmento_faixa_etaria` | `query-HAB1` | idle |
| `trs_google_ads__segmento_genero` | `query-C8qO` | idle |
| `trs_google_ads__segmento_geografico` | `query-tmws` | idle |
| `trs_google_ads__segmento_localizacao_usuario` | `query-pYmL` | idle |
| `trs_google_ads__termo_busca` | `query-vdre` | idle |

**Gatilho das cinco:** evento na fonte `google-ads-cwt3`, regra `any`. Espelha o padrão
já usado pela `query-tL4g` e pela `query-zF8L` — a `cwt3` tem o cron mais tarde das 39
(12:43 America/Manaus), então serve de marcador de fim do ciclo e cada transformação roda
**uma vez por terça**, depois de todas as fontes. Com evento nas 39 rodaria 39 vezes.

Nenhuma foi executada à mão. A primeira materialização é hoje, 08/09, quando a `cwt3`
disparar às 12:43 Manaus.

Os números desta medição entraram na descrição de cada uma das cinco, no bloco de
limitação com "não contorne", conforme o padrão da Refined.

**Verificação do deploy:** a `query-tmws` voltou com `input_tables` contendo exatamente
39 entradas — a Nekt resolveu todas as 39 referências de tabela, o que prova que nenhuma
está mal escrita. As cinco ficaram `idle` com `deploy_failed: false`.

### Também publicado hoje

- **`query-QXqC`** — limiar de `conta_defasada` de `> 2` para `> 9` dias, junto com a
  descrição explicando que o limiar é derivado do intervalo entre extrações. Chegou na
  hora: as 7 fontes de Facebook rodaram hoje às 05:18 e a flag falsa começaria a
  disparar na quinta.
- **`query-skPU`** — a `rfn_midia__desempenho_diario` passou a cobrir **duas
  plataformas**. Ramo de Facebook validado no mesmo dia contra a Trusted materializada:
  38.942 linhas = 38.942 chaves, 7 contas, zero órfã de conta, 281 pares sem dimensão de
  campanha (R$ 94.646,41 — o valor esperado, das 18 campanhas excluídas no Meta),
  R$ 2.318.791,22 de investimento, janela 2024-01-01 a 2026-09-08. Alinhamento do UNION
  conferido: 65 colunas, mesmos nomes, mesma ordem nos dois ramos.
