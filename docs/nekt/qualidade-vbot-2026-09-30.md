# 30/09 — a suíte da VBOT: 23 regras, e a oitava identidade da casa

`rfn_qualidade__regra_vbot` (`query-SxaY`, Refined / `qualidade`, **L2 INTERNAL**, gatilho de
evento em `query-schs`, alerta ligado, deploy limpo, **cadência diária**).
**A casa passa a ter 361 regras em dez tabelas.**

## O que ficava de fora

As duas Gold da VBOT — `rfn_financeiro__receita_vbot_mensal` (`query-8uTi`, **2.103** linhas)
e `rfn_financeiro__despesa_vbot_mensal` (`query-schs`, **447**) — foram publicadas em 28/09 e
**nunca rodaram**, porque a `supabase-x0tz` caiu com senha rejeitada em 29/09. A senha foi
trocada e as duas **materializaram em 30/09 06:36**.

Até aqui, as duas tabelas que respondem **MRR, faturamento, recebimento e custo da VBOT** não
tinham uma única regra. As 10 regras das **Trusted** do Conexa já moram na suíte principal;
estas 23 são das **Gold**.

## A suíte é o próprio teste de frescor, e por isso não há regra de carga aqui

As outras suítes de lote comparam `MAX(DATE(_extraido_at))` entre tabelas irmãs. Aqui seria
redundante: **quatro das 23 regras comparam a Gold contra a Trusted por TOTAL**, e uma Gold
defasada divergiria da Trusted na hora.

A cadeia é estritamente linear a partir de uma fonte só:

```
supabase-x0tz → mbpv → 6qKc → 54P5 → T3ct → rbJW → bZT5 → 8uTi → schs → SxaY
```

A suíte dispara no **último elo** e mede tudo recém-escrito.

## A OITAVA identidade da casa

`rfn_financeiro__despesa_vbot_mensal.rateio_reproduz_o_valor_direto`.

Uma despesa pode ratear em mais de um centro de custo (`centros_custo` com `percentage`), então
a Gold **expande** a despesa por centro e **pondera** o valor. A estrutura permite o rateio, mas
hoje `percentage` é **100 em todas as 1.222** — e é justamente por isso que a identidade é
verificável: a expansão ponderada tem de reproduzir a soma direta da Trusted, **ao centavo**.

**Medido: R$ 3.071.330,75 dos dois lados.**

Se um dia houver rateio real ela **continua valendo**, porque os pesos somam 1 por despesa. O
que ela pega é a expansão **sem** ponderação (multiplicaria o valor pelo número de centros) e a
ponderação **sem** expansão (atribuiria tudo a um centro só). **Nenhuma das duas muda a contagem
de linhas.**

A irmã dela, `despesas_reproduzem_a_trusted`, mede **cardinalidade**: **1.222 dos dois lados**,
nenhuma despesa vigente perdida nem duplicada.

## O achado: o faturado inclui cobrança cancelada e as outras duas colunas não

Na receita, a identidade óbvia — recebido mais em aberto reproduz o faturado — **falharia em 11
de 659**. Medido:

| | pares | falham |
|---|---:|---:|
| **sem** cobrança cancelada | 648 | **0** |
| **com** cobrança cancelada | 11 | **11** |

**Nenhuma exceção em nenhuma das duas direções** — é a prova de que o mecanismo é o cancelamento
e não ruído. A lacuna é **R$ 18.067,93 em 8 clientes**.

A regra saiu **condicional**, com a condição medida e não suposta. Escrevê-la sem a condição
criaria falha permanente que ninguém pode resolver, que é o que ensina a ignorar a suíte.

## A decomposição da despesa NÃO virou regra, e a razão é outra

`pago + em aberto = valor` falha em **15 de 447** — e aqui a causa **não é cancelamento**: há
**zero** despesa cancelada nas 447. São dois mecanismos:

- **12 grupos com juros, multa ou desconto** (de −R$ 73,61 a +R$ 72,99) — o mesmo que a
  `rfn_financeiro__fluxo_caixa` já mediu em 772 parcelas do Conta Azul.
- **3 grupos da DIRETORIA EXECUTIVA com pagamento PARCIAL registrado como pago** — R$ 9.000,
  R$ 5.000 e R$ 5.000, redondos.

Líquido de **R$ 18.811,87**.

O que **vale**, e vale nas duas pontas, é o **acoplamento**: grupo inteiramente pago tem em
aberto **zero** (254 de 254) e grupo sem nenhuma paga tem em aberto **igual ao valor** (188 de
188). Os 5 grupos parciais ficam de fora do denominador, declarados.

## As outras duas identidades, do lado da receita

- **`vendas_reproduzem_a_trusted`** — 3.486 dos dois lados, exato.
- **`cobrancas_reproduzem_a_trusted`** — 873 na Gold contra 876 vigentes na Trusted, e a
  diferença está **medida e não arredondada**: são exatamente as **3 cobranças sem mês de
  referência**, que uma tabela de grão mensal descarta por construção. A regra compara contra
  *vigente E com mês* — **873 de 873**. A Gold já declarava esse descarte em palavras ("um título
  de R$ 1.376,20 sem competência"); agora é teste.

## As outras que guardam premissa

- **`faturado_nulo_exatamente_sem_cobranca`** — faturado NULO é "não houve cobrança no mês",
  nunca "faturou zero". **1.444 dos dois lados.** Se soltar, zero vira número e entra em média —
  a doutrina do *zero de conclusão não é zero, é NULL*.
- **`pj_e_pf_particionam`** — CPF de 11 dígitos é documento **válido**, e foi o falso positivo
  dos 2.555 CPFs da `rfn_operacao__peca` que ensinou isso a esta casa.
- **`centro_catalogado`** — o centro resolve inteiro, zero órfãos. A flag existe porque uma
  **dimensão pode esvaziar**: a `github_repositories` foi de 10 linhas para ZERO quando a fonte
  caiu, enquanto os fatos continuaram lá.
- as duas **`chave_concorda_com_o_grao`** — chave incoerente parte o mesmo grupo em duas linhas
  **sem mudar nenhum total**.

## O que NÃO entrou, e a ausência é a decisão

- **Nome de categoria na despesa.** A Gold emite a categoria **sem nome de propósito**: os ids da
  despesa apontam para outro plano de contas e **13 deles nem existem** no catálogo de RECEITA
  (`dim_categoria_vbot`), então juntar rotularia despesa com nome de receita por coincidência
  numérica. Uma regra de completude ali exigiria o que a tabela decidiu **não** fazer.
- **`flag_mes_futuro`, nas duas.** É relativa à **data da carga** e as tabelas são reconstruídas
  inteiras a cada execução: a regra mediria o relógio, não o dado. Mesmo critério já aplicado
  hoje ao `flag_inicio_futuro` e antes ao `flag_ocorrencia_futura`.
- **Margem.** `trs_conexa__despesa` **não tem cliente**, então receita e despesa só se comparam
  no total do mês. Não há identidade a testar entre as duas tabelas.

## Validação

A query inteira foi rodada sobre as tabelas materializadas **antes do deploy**: **23 regras, 23
ids distintos, CONFORME 23, zero falhas**. Resultado esperado na primeira execução: 23 conformes.

O arquivo do repositório foi montado do mesmo corpo validado, com **asserção por trecho editado**
— cada diferença entre o rascunho e o publicado foi aplicada por substituição única e verificada.
Linha 1 carrega o slug, que o deploy não leva; nada mais difere.

## As oito identidades da casa, em ordem

1. `rfn_operacao__custo_peca.rateio_fecha_no_centavo` — o rateio do custo por peça
2. `rfn_financeiro__fluxo_caixa.caixa_reproduz_o_razao` — o caixa contra o razão Conta Azul
3. `trs_vjob__auditoria_ciclo.itens_batem_com_a_auditoria` — ciclo × item
4. `trs_iclips__apontamento.custo_reproduz_hora_vezes_valor_hora` — a primeira a validar a
   aritmética de um **terceiro**
5. `rfn_marketing__conversao.reproduz_a_trusted_linha_a_linha` — a primeira **entre camadas**
6. `rfn_cadastro__cliente.honorario_mais_repasse_e_o_total` — a decomposição exaustiva
7. as três de Mídia (partição do alvo e as duas somas de participação)
8. **`rfn_financeiro__despesa_vbot_mensal.rateio_reproduz_o_valor_direto`** — a primeira que
   guarda uma **expansão ponderada**

Mais a desigualdade `trs_google_ads__*.nao_excede_o_total` e a condicional de hoje,
`faturado_decompoe_sem_cancelada`.

## O painel

| suíte | regras | cadência |
|---|---:|---|
| `rfn_qualidade__regra` (principal) | 84 | diária |
| `rfn_qualidade__regra_iclips` | 45 | `notebook-Rbpo` |
| `rfn_qualidade__regra_midia` | 43 | semanal |
| `rfn_qualidade__regra_vjob` | 37 | semanal |
| `rfn_qualidade__regra_cadastro` | 34 | diária |
| `rfn_qualidade__regra_midia_gold` | 30 | Google Ads / PI |
| `rfn_qualidade__regra_marketing` | 24 | diária |
| **`rfn_qualidade__regra_vbot`** | **23** | **diária** |
| `rfn_qualidade__regra_gmail` | 22 | diária |
| `rfn_qualidade__regra_contazul` | 19 | semanal |
| **total** | **361** | |

## Fica sem regra, entre o materializado: uma só

`trs_linear__issue` (230). A Refined dela, `rfn_operacao__issue_mensal`, já tem 2 regras na
suíte principal.
