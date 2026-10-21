# A Refined entrou na camada semântica — dois documentos, verificados indexados

**Criados em 2026-09-29**, na raiz da camada semântica, mesmo destino dos 12 documentos
de setor e do de classificação L1–L5.

| documento | id | tamanho |
|---|---|---:|
| Regras de leitura da Refined — denominador, zero que é NULL, agenda × entrega | `ac85112a-50c1-4294-90ca-91140ccb22cc` | ~4,6 mil |
| Operação — as 17 Refined: o que cada tabela responde, e qual não existe ainda | `ce20aecc-a44e-4a40-be06-b3f4099cd732` | ~4,8 mil |

**Verificados indexados no mesmo dia:** uma busca por *"qual é o denominador certo para
taxa de conclusão e quando zero vira NULL na Refined"* devolve os dois em **primeiro e
segundo lugar**.

---

## Por que eles existiam de menos

O ADR-0010 é norma e a §17 diz que **métrica tem definição oficial na Semantic Layer**, e
a §18 que **a IA consome Gold e Semantic Layer**. Medido em 29/09, a camada semântica
conhecia **11 tabelas Refined** — e a casa tem **38**. Todas as 12 publicadas entre 27 e
29/09 estavam fora.

Pior: as **regras de leitura** que já mudaram número publicado nesta casa não estavam em
lugar nenhum que a IA consulte. Elas viviam na descrição de cada transformação — que só
é lida por quem já abriu aquela tabela específica, ou seja, por quem já não precisa do
aviso.

---

## O documento de regras: as quatro armadilhas, cada uma com o número

**1. O denominador quase nunca é a contagem total.** Quatro casos medidos, e a
diferença nunca é pequena:

| tabela | denominador errado | denominador certo |
|---|---:|---:|
| `rfn_operacao__conformidade_cliente` (auditoria) | 51,04% | **98,66%** |
| `rfn_operacao__conformidade_cliente` (etapa) | 18,59% | **36,27%** |
| `rfn_operacao__blog_mensal` | 80,42% | **91,96%** |
| `rfn_operacao__recorrencia_mensal` | 7,3% | **44,3%** |

A regra: **quando a tabela tem flag de ativação, meça a taxa de marcação por valor da
flag antes de escolher o denominador.**

**2. Zero de conclusão não é zero, é NULL** — com a lista das flags que marcam o caso, e
**a única exceção medida**: no Conexa a origem escreve NULL onde não houve pagamento, e
isso é um fato. *Ausência de registro → NULL; registro que diz zero → zero.*

**3. Agenda não é entrega.** As flags de futuro são **relativas à data da carga**, porque
as tabelas são reconstruídas inteiras — para corte histórico estável, comparar a data
planejada contra a data escolhida, nunca a flag.

**4. A cobertura viaja junto com o número** — 84% da conclusão de escopo, 0,9% do tempo
por tarefa, 63,5% do rateio de custo, 0,8% da hora apontada, 59,9% do CNPJ do blog.

Mais **"declaração não é prova"** (status 1.064 × link 832 × data 715 no blog) e **o que
nunca se soma**: Trusted com Refined, competência com caixa, VBOT com a casa, tipo de
segmento entre si, fluxo com coorte.

---

## O documento de inventário: e a regra de anotação que ele respeita

Lista as 17 `rfn_operacao__*` com grão, o que cada uma responde e a limitação que decide
a leitura.

**Só as materializadas levam anotação `@table::`.** As 11 publicadas e ainda não
materializadas entram como **texto**, com o aviso de não consultar antes da próxima carga
— referência a tabela não materializada **derruba a query inteira**. É a mesma disciplina
já aplicada aos documentos de setor, onde o que mora na Raw entrou como texto para não
ensinar a IA a consultar o que a §18 proíbe.

Materializadas hoje: `escopo_mensal` 70.961 · `job` 3.188 · `peca` 134.767 ·
`custo_peca` 134.767 · `conformidade_cliente` 510 · `issue_mensal` 13.

E ele fecha com **o que esta camada NÃO responde** — margem (é do financeiro),
recorrência por cliente (o job não resolve cliente), pontualidade de blog (o prazo mora
no escopo), **turnover e tempo de casa** (não há nenhuma Refined de RH, porque a fonte
não está conectada: a única pergunta declarada pelos setores que segue sem origem
governada) e **onboarding e checklist diário**, medidos e deliberadamente sem Refined.
