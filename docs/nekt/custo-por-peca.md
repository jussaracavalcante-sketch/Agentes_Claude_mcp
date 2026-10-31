# Custo por peça — a cadeia que destrava a margem

**Data:** 2026-09-23 · **Pedido:** "esqueça as horas, devemos calcular custo por peça."

## O que mudou

Até hoje a casa só sabia calcular custo de peça por **hora apontada**, e a própria
`rfn_operacao__peca` avisa na descrição que isso não funciona: hora real existe em
**1.050 de 134.751 peças (0,8%)**. Custo por hora não é uma base de custo — é uma
amostra de menos de um por cento.

A troca de caminho: em vez de medir o esforço de cada peça, ratear o **custo
operacional real do mês** sobre as peças daquele mês, usando o **valor de tabela da
peça** como peso de complexidade.

| caminho | peças com custo | % |
|---|---:|---:|
| hora apontada (o que existia) | 1.050 | 0,8% |
| rateio por peça (o que existe agora) | **85.539** | **63,5%** |

## As três tabelas publicadas

| slug | tabela | camada | linhas | gatilho |
|---|---|---|---:|---|
| `query-wzIg` | `trs_iclips__peca_tipo` | Trusted / `iclips` | 1.049 | evento em `query-jdUw` |
| `query-NnxD` | `trs_financeiro__movimento` | Trusted / `financeiro` | 45.154 | evento em `query-wzIg` |
| `query-VMUW` | `rfn_operacao__custo_peca` | Refined / `operacao` | 134.751 | evento em `query-NnxD` |

Cadeia linear, cada elo dispara no anterior. Alerta de falha ligado nos três.

## 1. `trs_iclips__peca_tipo` — o valor unitário existia e ninguém tinha olhado

O catálogo de peças do iClips (`supabase_silver_iclips_peca`) carrega uma coluna
`valor`: **147 dos 1.049 tipos** têm valor de tabela.

**Equivalência provada com o catálogo canônico.** `dim_peca_canonica.valor_referencia`
não é uma segunda fonte — é cópia desta. Dos 65 tipos com valor nos dois lados,
**65 batem ao centavo e zero divergem**. No grão da entrega a prova se repete:
**13.720 de 13.720 iguais**. E o iClips cobre mais (147 contra 65), então o valor sai
dele e o canônico entra só como rótulo.

**Zero é sentinela.** 902 dos 1.049 tipos têm `valor = 0` e nenhum tem NULL. Zero
aqui significa "não precificado" e vira NULL.

**A duplicata de caixa não é cosmética.** `Off` e `OFF` são categorias distintas na
origem — e não são a mesma geração de catálogo: **`Off` tem 95% dos tipos
precificados e `OFF` tem zero**. Por isso a coluna crua e a normalizada convivem.

## 2. `trs_financeiro__movimento` — o `fact_custos` que faltava

É a divergência nº 5 do ADR-0010. `codigo` é chave provada: 45.154 distintos em
45.154 linhas.

**`classe_financeira` impede somar coisas diferentes.** Sem ela o custo operacional
da casa (**R$ 29,85 mi**) é lido como **R$ 46,80 mi — 57% a mais**:

| classe | saída | entrada |
|---|---:|---:|
| OPERACIONAL | R$ 31,35 mi | — |
| REPASSE_CONTA_ORDEM | R$ 7,82 mi | R$ 8,15 mi |
| SOCIOS | R$ 9,16 mi | — |
| FINANCEIRO | R$ 1,25 mi | R$ 0,94 mi |
| CAPEX | R$ 0,82 mi | — |
| RECEITA | — | R$ 42,13 mi |

Realizado, sem projeção: **custo operacional R$ 29.850.726,93** (22.911 lançamentos)
e **receita operacional R$ 38.129.752,74** (12.364).

**Escolha declarada:** `Tributos` (R$ 4,34 mi) entra em OPERACIONAL. A alternativa não
tomada era tratá-lo como dedução de receita. Quem preferir a outra leitura filtra por
`categoria = 'Tributos'`, que continua visível na linha.

## 3. `rfn_operacao__custo_peca` — o rateio que fecha no centavo

No mês *m*, com **C** = custo operacional realizado, **n** = peças do mês,
**k** = peças com valor de tabela, **V** = soma dos valores:

```
peça COM valor v ....... custo = C · (k/n) · (v/V)    → soma  C·(k/n)
peça SEM valor ......... custo = C / n                → soma  C·(n−k)/n
                                                      total = C, sempre
```

**Provado:** nos 42 meses fechados a diferença entre a soma rateada e o custo do mês é
**zero até a sexta casa decimal**.

### Duas alternativas descartadas, com número

1. **Distribuir C inteiro só entre as peças com valor** — encareceria cada uma em
   ~2,5 vezes e zeraria as outras 57%.
2. **Imputar valor pela mediana da categoria** — Social Media tem **70.257 peças e só
   23,1% precificadas**; imputar a mediana de R$ 95 inventaria peso para 54 mil peças.
   Nada é imputado; `origem_do_custo` declara a rota linha a linha.

### O corte de mês não é uma data escrita à mão

A despesa está completa até a competência **2026-05**; 2026-06 tem 6 lançamentos e
2026-07 em diante tem zero, enquanto a base de peças segue até 2026-09. Somar assim
mostraria o custo desabando e a margem explodindo.

O critério: o mês é fechado quando tem ao menos **30% da mediana de lançamentos dos
meses de 2023 em diante** (mediana medida = 379, piso = 114). Ele fecha
**2022-12 a 2026-05** e deixa de fora 2021-01 a 2022-11 (0 a 33 lançamentos por mês,
quando a despesa ainda não era lançada) e 2026-06 em diante. **Nenhuma data precisa
ser reescrita quando a base andar.**

### Resultado por rota

| `origem_do_custo` | peças | custo |
|---|---:|---:|
| RATEIO_SIMPLES_SEM_VALOR | 53.218 | R$ 18.490.260,70 |
| RATEIO_PONDERADO_POR_VALOR | 32.321 | R$ 11.274.892,74 |
| MES_SEM_DESPESA_NA_BASE | 29.904 | — |
| MES_SEM_CUSTO_FECHADO | 15.027 | — |
| SEM_MES_REFERENCIA | 4.281 | — |

Custo atribuído **R$ 29.765.153,44** de R$ 29.850.726,93. A diferença de
**R$ 85.573,49** é de meses fechados sem peça registrada — não há onde ratear.

## O que ainda não se pode afirmar

1. **O rateio é atribuição, não medição.** Ele responde "quanto do custo da casa coube
   a esta peça", não "quanto esta peça consumiu". A regra é escolha declarada.
2. **O peso diferencia bem OFF e mal social.** Off 95%, Inbound 97%, Dev 99% contra
   **Social Media 23% — e Social Media é 52% da base**.
3. **"Peça entregue" não é provável.** `status_peca_codigo` tem 5 valores (5, −1, 6,
   12, 13) e não existe tabela de domínio dizendo qual é "concluída". O rateio é sobre
   a peça **registrada** no mês.
4. **Custo de mídia não está aqui.** Veiculação e impulsionamento por conta e ordem são
   repasse, ficam fora de `is_custo_operacional` e não pertencem ao custo de produção.
5. **`cliente_sk` ficou de fora de propósito.** A `rfn_cadastro__cliente_sk` anda na
   cadeia semanal do VJOB e esta cadeia anda com o iClips; amarrar as duas faria uma
   quebrar a outra. Junta-se por `cliente_cnpj` = `documento` na leitura.

## O gargalo da margem

Registrado no CLAUDE.md em 2026-09-23: *"Era identidade **e** custo; agora é só custo."*
**Deixou de ser.** Com estas três tabelas existem os dois lados:

- receita por cliente/mês → `rfn_financeiro__receita_cliente_mensal` (`query-awMU`)
- custo por cliente/mês → agregação de `rfn_operacao__custo_peca` por
  `cliente_cnpj` + `mes_referencia`

A margem por cliente é a próxima Refined, e a janela em que ela existe é
**2022-12 a 2026-05**.
