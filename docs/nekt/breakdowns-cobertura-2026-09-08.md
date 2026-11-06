# Breakdowns do Google Ads — a medição da perda, conta por conta

Medido em 2026-09-08 sobre as 39 fontes de Google Ads, comparando cada stream de
breakdown contra a `trs_google_ads__insight_diario` em produção. Janela dos dados:
2025-01-01 a 2026-09-03.

Fecha a pendência que ficou aberta em 04/09: *"medir a faixa real de perda de
`user_location` e `search_term` em mais contas, antes de escrever o número na
descrição das transformações."*

> **LEIA A CORREÇÃO NO FIM DESTE DOCUMENTO ANTES DE USAR OS VALORES ABAIXO.**
> O total de R$ 1.361.954,19 usado nesta seção soma BRL e USD, o que a regra da base
> proíbe. Os percentuais seguem válidos; os valores absolutos foram refeitos por moeda
> na seção "CORREÇÃO de 2026-09-08".

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


---

## CORREÇÃO de 2026-09-08 — eu misturei moedas

**O total de R$ 1.361.954,19 usado acima está errado no rótulo.** Ele é
`R$ 1.342.354,13 + US$ 19.600,06` somados como se fossem a mesma moeda — exatamente o
que a regra da base proíbe, e a mesma regra que a `rfn_midia__desempenho_diario`
declara na própria descrição. A Move Rental Cars é a única das 42 contas em USD.

Refeito por moeda:

| | BRL (35 contas) | USD (1 conta) |
|---|---:|---:|
| Total | R$ 1.342.354,13 | US$ 19.600,06 |
| PERFORMANCE_MAX | R$ 270.088,20 (20,1%) | US$ 1.352,40 (6,9%) |
| Verba não-PMax (cobertura esperada) | R$ 1.072.265,93 (79,9%) | US$ 18.247,66 (93,1%) |
| **Cobertura medida de idade/gênero** | **R$ 1.073.656,85 (80,0%)** | **US$ 18.247,66 (93,1%)** |
| Delta | R$ 1.390,92 | **US$ 0,00** |
| Cobertura de localização | R$ 1.254.634,41 (93,5%) | US$ 18.561,26 (94,7%) |
| Verba SEARCH + SHOPPING | R$ 941.001,89 (70,1%) | US$ 18.247,66 (93,1%) |
| Cobertura de termo | R$ 575.998,18 (**61,2%** da busca) | US$ 8.704,13 (47,7% da busca) |

**A conclusão do PMax não mudou — ficou mais forte.** O delta de R$ 1.390,92 entre a
cobertura demográfica e a verba não-PMax é **todo BRL**; no USD o delta é **zero**. Isso
confirma que a diferença é o dia 03/09 parcial e nada mais, porque a única conta em USD
não tinha esse dia pendente.

Os percentuais praticamente não se moveram: 80,2% → 80,0%, localização 93,5% → 93,5%,
termo 61,0% → 61,2%. O que estava errado era o **rótulo do valor absoluto**, não a
proporção.

**Lição, e ela não é cosmética:** eu apliquei a regra "não some moedas" ao escrever a
descrição da Refined e violei a mesma regra ao medir a cobertura, na mesma sessão.
Regra que se aplica ao produto e não ao próprio trabalho de medição não está aprendida.
Toda soma de investimento nesta base precisa de `GROUP BY moeda` — inclusive as minhas.

### Achado paralelo: a coluna `investimento` da Refined não é somável

Medido no mesmo dia sobre a `rfn_midia__desempenho_diario` inteira:

| plataforma / moeda | linhas | somando `investimento_micros` | somando `investimento` | deriva |
|---|---:|---:|---:|---:|
| GOOGLE_ADS / BRL | 42.045 | R$ 1.342.354,14 | R$ 1.342.355,04 | **+R$ 0,90** |
| GOOGLE_ADS / USD | 843 | US$ 19.600,06 | US$ 19.600,10 | +US$ 0,04 |

A coluna `investimento` é `ROUND(micros / 1e6, 2)` **por linha campanha-dia**. Somar
42.045 linhas arredondadas acumula R$ 0,90. A regra 3 da Refined já manda somar micros e
dividir uma vez só; isto é a medição de quanto custa não seguir. Na Trusted o mesmo teste
deu erro **zero** — os arredondamentos por linha se cancelaram lá, o que é sorte e não
garantia.

Regra de leitura: **verba se soma por `investimento_micros`, dividido por 1e6 uma única
vez no fim, com `GROUP BY moeda`.** A coluna `investimento` serve para ler uma linha, não
para totalizar.

---

## Conferência da materialização — 2026-09-08, 14:23

As cinco rodaram no ciclo das 13:48, **uma execução cada**, todas com sucesso e em 12 a 16
segundos. O gatilho na fonte única (`google-ads-cwt3`, a de cron mais tarde) funcionou como
projetado — com evento nas 39 fontes teriam rodado 39 vezes.

| Tabela | Linhas | Chaves | Hashes | Grão | Fontes | Contas |
|---|---:|---:|---:|:---:|---:|---:|
| `trs_google_ads__termo_busca` | 2.956.599 | 2.956.599 | 2.956.599 | ok | 36 | 36 |
| `trs_google_ads__segmento_localizacao_usuario` | 785.459 | 785.459 | 785.459 | ok | 36 | 36 |
| `trs_google_ads__segmento_faixa_etaria` | 277.959 | 277.959 | 277.959 | ok | 36 | 36 |
| `trs_google_ads__segmento_genero` | 133.648 | 133.648 | 133.648 | ok | 36 | 36 |
| `trs_google_ads__segmento_geografico` | 68.631 | 68.631 | 68.631 | ok | 36 | 36 |

**`fontes = contas = 36` nas cinco é a prova do mapeamento.** Como o SQL injeta um literal de
`id_conta` por ramo, uma conta só poderia aparecer sob duas fontes se eu tivesse repetido um
literal — e aí `contas` viria **menor** que `fontes`. Vindo iguais, o pareamento é bijetivo.
São 36 e não 39 porque três contas integradas não têm desempenho nenhum e portanto não
contribuem linha; a nota de conferência que eu havia escrito esperando 39 estava errada.

### As duas reconciliações agora fecham em ZERO

| | BRL | USD |
|---|---:|---:|
| Total na `trs_google_ads__insight_diario` | R$ 1.355.603,00 | US$ 19.925,49 |
| Total no geográfico | R$ 1.355.603,00 | US$ 19.925,49 |
| **Diferença** | **0** | **0** |
| Verba não-PMax | R$ 1.084.334,23 | US$ 18.578,38 |
| Cobertura demográfica medida | R$ 1.084.334,23 | US$ 18.578,38 |
| **Diferença** | **0** | **0** |

Em micros, identidade exata em inteiro: **1.355.603.001.705** dos dois lados em BRL e
**19.925.490.736** em USD.

**Isto encerra a questão do dia 03/09 parcial.** Na medição da manhã eu tinha delta de
R$ 1.390,92 na cobertura demográfica e R$ 830,62 no geográfico, e atribuí os dois ao
desalinhamento de janela entre a Trusted e os breakdowns. Agora que os dois lados
materializaram no **mesmo ciclo**, o delta é zero nas duas moedas. A explicação estava certa,
e a prova é melhor do que a que eu tinha: **a fórmula `cobertura demográfica = verba não-PMax`
é exata ao centavo**, não aproximada.

Coberturas medidas, contra o que está publicado nas descrições:

| | Publicado | Medido agora |
|---|---:|---:|
| Demográfico BRL | 80,0% | **80,0%** |
| Demográfico USD | 93,1% | 93,2% |
| Localização BRL | 93,5% | 93,4% |
| Termo / verba de busca BRL | 61,2% | **61,2%** |
| Termo / verba de busca USD | 47,7% | 47,1% |

As variações de 0,1 a 0,6 ponto são o dia de dado novo que entrou. As descrições publicadas
seguem corretas.

### A Refined falhou, foi corrigida e reprocessada

A primeira execução da versão de duas plataformas, às 13:49, **falhou**:

> `Invalid SQL query: Column 11 in UNION ALL has incompatible types: INT64, STRING`

A coluna 11 é `id_campanha`: **INT64** na `trs_google_ads__insight_diario` e **STRING** na
`trs_facebook_ads__insight_diario`.

**A falha é de validação minha, e vale nomear o mecanismo.** Eu havia conferido o alinhamento
do union com sqlglot, que compara **nome e ordem das colunas, não tipo**, e havia validado o
ramo de Facebook isolado — nunca executei a união. O deploy passou porque a Nekt **não faz
type-check no deploy**: só a execução faz. Alinhamento de union só se prova executando.

Nem toda diferença de tipo quebra: `conversoes_view_through` e `visualizacoes_video` são INT64
no Google e FLOAT64 no Facebook, e o BigQuery coage para FLOAT64 sem reclamar, porque existe
supertipo comum. INT64 com STRING não tem.

**O cast foi para o lado do Facebook, para INT64**, e não do Google para STRING. O motivo não é
estético: a coluna já estava publicada como INT64, e a junção de funil documentada usa
`rfn_marketing__conversao.id_campanha_google`, **que também é INT64** — mudar o lado do Google
quebraria a junção em vez de consertar algo. Verificado antes de decidir: os 1.172 ids de
campanha do Meta são todos numéricos, de 17 a 18 dígitos, maior valor
120.255.492.656.370.460, dentro do limite do INT64. `SAFE_CAST` e não `CAST`, para que um id
não numérico futuro devolva NULL na coluna em vez de derrubar a execução inteira — o id
verdadeiro sobrevive em `id_desempenho`, que é montado a partir do texto.

Validado **executando a união** antes de publicar, e conferido de novo depois do reprocessamento:

| Plataforma / moeda | Linhas | Chaves | Contas | `id_campanha` nulo | Investimento | Não confiáveis |
|---|---:|---:|---:|---:|---:|---:|
| FACEBOOK_ADS / BRL | 38.942 | 38.942 | 7 | 0 | R$ 2.318.791,22 | 281 |
| GOOGLE_ADS / BRL | 42.346 | 42.346 | 35 | 0 | R$ 1.355.603,00 | 0 |
| GOOGLE_ADS / USD | 858 | 858 | 1 | 0 | US$ 19.925,49 | 0 |

Os 281 não confiáveis do Facebook são as 18 campanhas excluídas no Meta, R$ 94.646,41 — o
valor esperado. Micros do Google BRL: **1.355.603.001.705**, idêntico à Trusted.

O reprocessamento foi **execução manual autorizada**, exceção pontual à regra de só rodar no
horário agendado: o gatilho é evento nas duas queries de Google, que já haviam rodado às
13:48, então a correção só materializaria na terça seguinte e a camada oficial de consumo
ficaria uma semana servindo dado de 03/09.

### Achado: `conta_defasada` não distingue fonte parada de conta pausada

Das 36 contas de Google Ads, **11 disparam a flag — e nenhuma por falha de extração.** As
fontes rodaram hoje; o Google simplesmente não devolve linha para dia sem atividade.

| Cliente | Última entrega | Dias |
|---|---|---:|
| SANTO REMEDIO | 22/06/2025 | 443 |
| BRAGA VAREJO | 30/08/2025 | 374 |
| AMAZONCOPY | 26/11/2025 | 286 |
| STEEL PORT | 27/03/2026 | 165 |
| BRAGA MINI | 05/06/2026 | 95 |
| BRAGA MOTORS BMW | 16/07/2026 | 54 |
| BRAGA POS VENDAS | 23/07/2026 | 47 |
| SMILE PNEUS | 30/07/2026 | 40 |
| DMELO TEMPLO DAS TINTAS | 09/08/2026 | 30 |
| PNEU FORTE DISTRIBUIDORA | 20/08/2026 | 19 |
| DON WATCHES CONTA 2 | 22/08/2026 | 17 |

São contas que pararam de anunciar. Pela definição literal da flag ("última entrega há mais de
9 dias") o valor está certo; pelo **propósito** dela — pegar fonte parada, que foi o problema
que deixou 4 clientes de Facebook congelados sem ninguém notar — está errado em 11 de 36 casos.
Uma flag que dispara permanentemente em 31% das contas perde o valor de sinal, que é a mesma
falha que o ajuste de limiar de hoje consertou por outro caminho.

Separar as duas causas exige comparar `ultima_data_com_entrega` com a **última extração
bem-sucedida da fonte** — dado que existe na API da Nekt (`list_pipeline_runs`) e **não** no
warehouse. Registrado como limitação na descrição da `query-skPU`. Não implementado: mudaria
o contrato de uma tabela publicada e depende de decisão de escopo.
