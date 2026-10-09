# Google Ads — os quatro breakdowns ganharam camada de consumo (2026-09-28)

Até hoje a agência tinha **quatro Trusted de segmentação do Google Ads, 1.342.152 linhas,
e nenhuma Refined lendo nenhuma delas**. Era o maior buraco de Gold da casa no negócio
principal. Fechado com **três transformações**: uma dimensão e duas Refined.

| slug | tabela | camada | linhas | nível |
|---|---|---|---:|---|
| `query-Jn5l` | `trs_google_ads__geo_alvo` | Trusted / `google_ads` | **270.938** | L2 |
| `query-mkcu` | `rfn_midia__segmento_mensal` | Refined / `midia` | **7.886** | L2 |
| `query-SGbQ` | `rfn_midia__localizacao_mensal` | Refined / `midia` | **161.041** | L2 |

Deploy limpo e alerta de falha ligado nas três.

---

## 1. A dimensão geográfica existe, e a descrição da casa dizia que não

A descrição publicada da `trs_google_ads__segmento_localizacao_usuario` afirmava, em letra
maiúscula, que *"não existe tabela de dimensão geográfica nesta base — o stream
`geo_target_constant` não está habilitado em nenhuma fonte"*.

**Está habilitado em TODA camada de conta Google Ads**, e cada uma guarda **270.938 linhas**:
a lista global de alvos geográficos do Google inteira, com nome, nome canônico, tipo de alvo
e código de país.

É o **sexto caso** nesta base de *"a busca não devolveu, logo não existe"* — depois de
`ia_geracoes` (86 linhas), `tbjobs_comentarios` (656), `tbjobs_arquivos` (688) e `municipio`
(5.570). **Prova de ausência é `COUNT(*)`**, nunca uma busca que voltou vazia. A descrição
da Trusted foi corrigida no mesmo dia, com a correção declarada e não apagada.

### Por que ler três cópias e não as 40 — medido, não suposto

O Google devolve a lista global inteira **para cada conta**, então as 40 camadas guardam a
mesma tabela: ~10,8 milhões de linhas duplicadas no warehouse. Medido em três contas
(`dr_cabral_conta_1`, `acesso_saude`, `braga_varejo`): **270.938 linhas nas três e o mesmo
hash agregado da tabela inteira** — `557640a956c05678bce0c32d6d5f1516`. Idênticas byte a byte.

Pelo conteúdo, **uma cópia bastaria**. Lemos três por **resiliência**, e a razão tem
precedente medido nesta base: a `github-s0VO` caiu com `401` e a extração **esvaziou a
dimensão** `github_repositories` (10 → 0 linhas) enquanto os fatos continuaram lá. Com três
cópias, uma fonte que esvazie não apaga a dimensão.

`qtd_copias_lidas` e `flag_copias_divergem` tornam o caso visível: hoje **270.938 ids com 3
cópias e ZERO divergência**. Se um id passar a divergir, a flag acende em vez de a query
escolher em silêncio.

### O nome do país tem duas rotas, declaradas linha a linha

- `LINHA_COUNTRY` (autoridade) — a linha de tipo `Country` casada por `country_code`.
  **219 dos 247 códigos** a têm.
- `ULTIMO_ELEMENTO_DO_CANONICO` — os outros 28 (PR, HK, TW, GL, MO, PS, XK, territórios em
  geral) não têm linha própria de país. **1.569 linhas, 0,6%.**

O fallback é a segunda rota e nunca a primeira porque `canonical_name` é texto separado por
vírgula: um topônimo com vírgula quebraria o corte.

### Colunas não emitidas, de propósito

- `status` — constante `ENABLED` nas 270.938 linhas. Campo morto; emitido, convidaria a
  filtrar por algo que não varia. Mesma doutrina do `stats` do GitHub.
- `resource_name` — é literalmente `geoTargetConstants/<id>`, redundante com a chave.

### Cobertura contra quem consome

| consumidor | nível | resolve | órfãos |
|---|---|---:|---:|
| `segmento_localizacao_usuario` | país | 152 de 152 | **0** |
| | região | 1.461 de 1.467 | 6 (328 linhas) |
| | cidade | 9.928 de 9.965 | 37 (829 linhas) |
| `segmento_geografico` | país | 197 de 199 | 2 |

Órfão aqui é **0,1% das linhas** e **não é sentinela** — nenhum é zero. São ids de alvo que
a constante extraída não traz (alvo criado ou retirado depois da carga). Join **LEFT com
flag** nos dois consumidores: com INNER as linhas sumiriam sem sinal.

---

## 2. `rfn_midia__segmento_mensal` — quem viu e clicou

Grão: **uma conta, um tipo de segmento, um valor de segmento, um mês.**
7.886 linhas, 7.886 chaves, 40 contas, 21 meses (2025-01 a 2026-09).

### A regra que decide tudo

**`tipo_segmento` é FILTRO, nunca group by para somar entre tipos.** A mesma verba aparece
em cada tipo — o Google quebra o mesmo gasto por idade **e** por gênero **e** por país.
Somar as 7.886 linhas devolve ~4× o investimento real. Dentro de **um** `tipo_segmento` a
soma é correta e fecha com a Trusted ao centavo.

### Por que o tipo de localização entrou no `tipo_segmento`

A Trusted geográfica tem `tipo_localizacao` com dois valores que **também** quebram o mesmo
gasto. Medido em 2026-09-28:

| `tipo_localizacao` | investimento |
|---|---:|
| `LOCATION_OF_PRESENCE` | R$ 1.224.598,99 |
| `AREA_OF_INTEREST` | R$ 295.528,43 |
| **soma** | **R$ 1.520.127,42** — mais que o investimento real da conta |

Deixar os dois como um recorte interno convidaria a somar. **Dobrados dentro do próprio
`tipo_segmento`** (`PAIS_PRESENCA` e `PAIS_INTERESSE`), a regra passa a ser **uma só, sem
exceção**: some dentro do tipo, nunca entre tipos.

Os quatro tipos: `FAIXA_ETARIA` (3.787 linhas) · `GENERO` (1.663) · `PAIS_PRESENCA` (1.773) ·
`PAIS_INTERESSE` (663).

### O maior público da casa é "não identificado"

Medido em BRL sobre a janela inteira:

| faixa etária | investimento | | gênero | investimento |
|---|---:|---|---|---:|
| **AGE_RANGE_UNDETERMINED** | **R$ 259.468,31** | | MALE | R$ 588.195,33 |
| 25-34 | R$ 256.062,93 | | FEMALE | R$ 366.097,90 |
| 35-44 | R$ 248.444,45 | | **UNDETERMINED** | **R$ 255.953,30** |
| 45-54 | R$ 181.015,69 | | | |
| 18-24 | R$ 120.073,21 | | | |
| 55-64 | R$ 94.139,70 | | | |
| 65 ou mais | R$ 51.043,41 | | | |

**A maior "faixa etária" da casa é a que o Google não conseguiu atribuir**, à frente de
25-34. No gênero, 21,1% da verba é `UNDETERMINED`. Isso **não é um público** — é ausência de
atribuição. `flag_segmento_nao_identificado` existe para que ninguém escreva "nosso público
é 25-34" sem separar o balde que é maior que ele.

### Cobertura — não fecha a verba, e o motivo é do Google

Campanha sem sinal demográfico (PMax, parte de Display e Video) não publica breakdown.
Medido contra `trs_google_ads__insight_diario`:

| moeda | total da conta | faixa etária | gênero | país presença |
|---|---:|---:|---:|---:|
| BRL | R$ 1.498.466,27 | R$ 1.210.247,70 (80,8%) | R$ 1.210.246,53 (80,8%) | R$ 1.208.269,86 (80,6%) |
| USD | US$ 21.661,59 | US$ 20.314,47 (93,8%) | — | US$ 16.329,13 (75,4%) |

**Serve para ler perfil, nunca para totalizar verba.** O total é a `insight_diario`.

Faixa etária e gênero cobrem quase exatamente o mesmo dinheiro (diferença de **R$ 1,17** em
1,2 milhão). Isso **não é duplicidade**: são dois recortes do mesmo gasto.

---

## 3. `rfn_midia__localizacao_mensal` — onde o dinheiro foi gasto

Grão: **uma conta, um país, uma região, uma cidade, um mês.**
161.041 linhas, 161.041 chaves, 40 contas, 9.965 cidades, 21 meses.

**É a leitura que a dimensão destravou.** A Trusted de origem é a maior dos quatro
breakdowns (827.446 linhas) e carregava **só id numérico** — 9.965 cidades e 1.467 regiões,
nenhum nome.

### Por que é uma tabela separada, e não mais um `tipo_segmento`

A localização do usuário é **hierárquica** (país, região, cidade); as outras três são planas.
Espremer três níveis num único `valor_segmento` obrigaria a escolher um nível e perder os
outros dois. Duas tabelas de propósito, mesmo precedente do anexo de job e do anexo de
comentário no VJOB. **E pela mesma razão não se somam**: quebram o mesmo gasto por eixos
diferentes.

### `local_e_alvo` PARTICIONA — e isso foi medido, não suposto

R$ 1.172.578,73 dentro do alvo + R$ 247.031,45 fora = **R$ 1.419.610,18**, exatamente o total
da Trusted. E a partição fecha em **todas as 161.041 linhas** — zero com diferença acima de
meio centavo.

Como particiona, ela **não entra no grão**: vira duas medidas
(`investimento_em_local_alvo` / `investimento_fora_do_alvo`) mais
`participacao_local_alvo`. Somar as duas é correto e `investimento` continua sendo o total da
linha. Responde: *"quanto do que gastei nesta cidade caiu em localização que eu mirei"* —
vazamento de veiculação.

**Contraste direto com o `tipo_localizacao` da tabela geográfica, que duplica.** Duas colunas
do mesmo sistema, uma que particiona e outra que não — medir antes de somar, sempre.

### A carteira é geograficamente concentrada

Top cidades em BRL: **Manaus R$ 921.218,79** · Boa Vista R$ 71.135,69 · São Luís R$ 51.484,67
· Macapá R$ 40.164,95 · Belém R$ 38.599,93 · Fortaleza R$ 34.265,38 · Cuiabá R$ 31.095,41 ·
Natal R$ 16.437,53. **99,3% da verba cai em alvo do Brasil** (R$ 1.409.626,23 de
R$ 1.419.610,18).

### A região nem sempre é "estado" e a cidade nem sempre é "cidade"

Medido pelos tipos de alvo da dimensão:

- nível de região: `State` 137.935 · `Region` 10.811 · `Province` 6.657 · `Department` 2.493
  · `Governorate` 1.271 · `County` 711 · `Canton` 459 · `Prefecture` 344
- nível de cidade: `City` 160.027 · `Municipality` 886

São as divisões administrativas de cada país. `tipo_regiao` e `tipo_cidade` saem na tabela
**para que ninguém escreva "UF" onde o Google não disse UF**.

### Nome de cidade não é chave

**9.965 ids de cidade para 9.098 nomes distintos** — há homônimo entre estados e entre
países. Agrupar por `cidade` funde lugares diferentes em silêncio; a chave é `id_cidade`.
Mesma armadilha já medida em `trs_vjob__municipio`, onde 506 municípios repetem nome entre UFs.

### Cobertura

BRL R$ 1.399.131,92 de R$ 1.498.466,27 (**93,4%**); USD US$ 20.478,26 de US$ 21.661,59
(**94,5%**). É a melhor cobertura dos quatro breakdowns, e ainda assim **não é o total**.

---

## 4. A cadeia foi LINEARIZADA

Os quatro breakdowns disparavam **em paralelo** na fonte `google-ads-cwt3`. As duas Refined
de hoje leem vários deles ao mesmo tempo, e **evento em paralelo não garante ordem**: a
Refined podia rodar antes de um breakdown materializar e **derrubar a query inteira**.

```
google-ads-cwt3  (terça, 12:43 America/Manaus)
  └─ query-HAB1  trs_google_ads__segmento_faixa_etaria
     └─ query-C8qO  trs_google_ads__segmento_genero
        └─ query-tmws  trs_google_ads__segmento_geografico
           └─ query-pYmL  trs_google_ads__segmento_localizacao_usuario
              └─ query-Jn5l  trs_google_ads__geo_alvo
                 └─ query-mkcu  rfn_midia__segmento_mensal
                    └─ query-SGbQ  rfn_midia__localizacao_mensal
```

Três gatilhos alterados (`C8qO`, `tmws`, `pYmL`) e as três descrições correspondentes
atualizadas na Nekt, para que nenhuma delas continue dizendo "evento na fonte
google-ads-cwt3". **Registro com buraco não é registro.**

**A cadência não muda.** A `cwt3` tem o cron mais tarde das 39 (12:43 `America/Manaus`) e
continua sendo o marcador de fim do ciclo: a cadeia inteira roda **uma vez por terça**,
depois de todas as fontes.

O ramo do termo de busca (`query-vdre` → `query-sGXo`) continua pendurado direto na `cwt3` e
não foi tocado: ele não lê nenhum dos quatro breakdowns.

---

## 5. Validação — medida antes de publicar

A dimensão `trs_google_ads__geo_alvo` ainda não materializou (a cadeia roda terça), então as
duas Refined foram validadas **reproduzindo a dimensão sobre a Raw** — mesmo método já usado
na `rfn_qualidade__regra_contazul`.

| verificação | `segmento_mensal` | `localizacao_mensal` |
|---|---|---|
| linhas = chaves distintas | 7.886 = 7.886 | 161.041 = 161.041 |
| contas órfãs | 0 | 0 |
| sem moeda / sem cliente | 0 / 0 | 0 / 0 |
| conversão > 0 e CPA NULL | 0 | 0 |
| conversão = 0 e CPA preenchido | 0 | 0 |
| partição de `local_e_alvo` quebrada | — | **0** |
| totais contra a Trusted | ao centavo | ao centavo |

As 15 linhas sem `rotulo_segmento` na `segmento_mensal` são **exatamente** os 15 países
órfãos — consistente, não resíduo.

---

## 6. O que fica pendente

- **As regras de qualidade sobre as três tabelas** entram quando elas materializarem
  (terça). Referenciar tabela não materializada derruba a suíte inteira.
- As candidatas naturais: unicidade de `id_alvo_geo`, `flag_copias_divergem` = FALSE em
  100%, unicidade das duas chaves de Refined, e — a que guarda premissa de verdade — a
  **identidade contábil da partição de `local_e_alvo`**, que hoje fecha em 161.041 de
  161.041 linhas. Seria a terceira identidade contábil da casa, depois do
  `rateio_fecha_no_centavo` e do `caixa_reproduz_o_razao`.
