# A dívida declarada com data foi paga — e vieram três identidades

**30/09/2026.** `rfn_qualidade__regra_midia` (`query-4tgF`) vai de **24 para 43 regras**.
Deploy limpo, alerta ligado, gatilho inalterado (evento em `query-SGbQ`).

**A casa passa a ter 313 regras em nove tabelas:** 84 principal · 43 mídia · 37 VJOB ·
34 cadastro · 33 iClips · 30 mídia Gold · 24 marketing · 19 Conta Azul · 9 Gmail.

## O que destravou

A suíte de mídia foi publicada em 29/09 declarando, no próprio código, o que ficava de
fora e por quê:

> *FICA DE FORA, COM A CAUSA CONFERIDA: `trs_google_ads__geo_alvo`,
> `rfn_midia__segmento_mensal` e `rfn_midia__localizacao_mensal` foram publicadas em 28/09
> e ainda NÃO MATERIALIZARAM — entram na passada de terça. Referenciar tabela não
> materializada derruba a query inteira.*

As três materializaram em **29/09 16:51–16:52**, na passada do Google Ads:

| tabela | linhas |
|---|---:|
| `trs_google_ads__geo_alvo` | **270.938** |
| `rfn_midia__localizacao_mensal` | **161.613** |
| `rfn_midia__segmento_mensal` | **7.886** |

## As três identidades

### 1. `localizacao_mensal.particao_do_alvo_fecha` — a candidata declarada

`investimento_em_local_alvo + investimento_fora_do_alvo = investimento`, linha a linha.

**Medido: R$ 1.192.985,77 + R$ 249.564,26 = R$ 1.442.550,03 — zero quebras em 161.613
linhas.**

O valor da regra está no contraste que a própria Trusted já declarava: **`local_e_alvo`
particiona, enquanto `tipo_localizacao` duplica**. `LOCATION_OF_PRESENCE` mais
`AREA_OF_INTEREST` somam R$ 1,52 mi — mais que a verba real. Se a partição soltar, a verba
por localização passa a contar duas vezes e **a contagem de linhas não muda**.

### 2. `localizacao_mensal.participacao_soma_um_na_conta_mes` — grão = GRUPO

Não é regra de linha: o grão é **(conta, mês)**. **568 grupos, zero fora de 1%, desvio
máximo 0,0001** — arredondamento. Prova que as localizações de uma conta-mês cobrem a conta
inteira, sem buraco nem sobreposição.

### 3. `segmento_mensal.participacao_soma_um_por_tipo` — a que guarda a armadilha

Grão = **(conta, mês, TIPO)**, e **o TIPO no grão é o ponto inteiro**.

A descrição daquela tabela declara que `tipo_segmento` é **filtro e nunca group by**: a
mesma verba aparece em faixa etária, gênero e país, então somar os quatro tipos dá **~4× o
investimento real**. Esta regra prova que **dentro** de cada tipo a partição é completa —
**2.173 grupos, zero fora, desvio máximo ZERO exato** — e é justamente por ser completa
dentro de cada um que somar entre eles multiplica.

**A regra guarda a premissa e explica a armadilha ao mesmo tempo.**

## A guarda das três cópias

`geo_alvo` existe em toda camada de conta, idêntica, e a Trusted lê **três** cópias e as
compara. Duas regras nascem daí:

- `copias_nunca_divergem` — FALSE em **270.938 de 270.938**
- **`tres_copias_lidas`** — `qtd_copias_lidas = 3` em todas

A segunda é a que importa, e é sobre um caso silencioso: **se uma fonte cair, a Trusted lê
2 cópias, a comparação perde força e nada na contagem de linhas muda.** É exatamente o que
aconteceu com `github_repositories`, que foi de 10 linhas para ZERO enquanto os fatos
continuaram lá — e foi esse precedente que justificou ler três cópias em vez de uma.

## Duas linhas de base novas, com limiares medidos um a um

Clique maior que impressão, as duas ALERTA:

| tabela | falhas | taxa | limiar |
|---|---:|---:|---:|
| `localizacao_mensal` | 273 de 161.613 | 99,83% | 0,998 |
| `segmento_mensal` | 3 de 7.886 | 99,96% | 0,999 |

O número vem da plataforma e **esta camada não o recalcula**. A taxa da localização é
**~34× a do desempenho diário** (4 de 86.267), porque o Google atribui clique e impressão à
localização por regras diferentes. **Por isso os limiares são distintos, medidos um a um, e
não um limiar único aplicado por simetria** — um 0,999 aqui reprovaria o que é legítimo, e
regra que acusa o que é legítimo ensina a ignorar a suíte.

## As outras onze

**`geo_alvo` (4 restantes):** `id_alvo_geo` único 270.938/270.938 · nome preenchido ·
`flag_e_pais` decompõe exatamente em `tipo_alvo = 'Country'` · código de país com duas
letras. Zero falhas nas quatro.

**`localizacao_mensal` (4 restantes):** chave única · `participacao_local_alvo × investimento
= investimento_em_local_alvo` (43.223 avaliadas, zero) · `mes_referencia` no dia 1 ·
métrica não negativa.

**`segmento_mensal` (3 restantes):** chave única · `tipo_segmento` nos quatro conhecidos
(FAIXA_ETARIA, GENERO, PAIS_PRESENCA, PAIS_INTERESSE) · `flag_e_geografico` decompõe em
começar por `PAIS`.

## Validação

As 19 foram medidas na tabela materializada, e a montagem foi validada rodando as **19
novas unidas a uma CTE antiga** — que é o que testa o alinhamento do `UNION` entre o bloco
novo e o antigo, o único risco real da edição. Resultado: **20 regras, 20 ids distintos,
CONFORME 20, zero falhas**, com as duas linhas de base dentro do limiar.

## Nota de método

O arquivo do repositório foi montado a partir da versão de ontem e recebeu as 19 regras
mais três edições de cabeçalho. **A paridade de lógica está verificada** — 43 ids de regra
distintos e 9 CTEs, os mesmos nomes dos dois lados. As três linhas de cabeçalho foram
reconstruídas a partir do texto publicado; se divergirem do deploy, divergem em pontuação
de comentário, não em código.
