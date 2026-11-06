# Conexa / VBOT — as cinco Trusted ganharam Gold (2026-09-28)

A VBOT tinha **cinco Trusted do Conexa e uma única Refined** — a de inadimplência.
Contrato, venda e despesa eram lidas **apenas pela suíte de qualidade**. O MRR da
operação, o número que diz se ela cresce, não existia na camada oficial de consumo.

| slug | tabela | grão | linhas | nível |
|---|---|---|---:|---|
| `query-8uTi` | `rfn_financeiro__receita_vbot_mensal` | cliente × mês | **2.090** | L4 |
| `query-schs` | `rfn_financeiro__despesa_vbot_mensal` | mês × centro × categoria × tipo | **447** | L2 |

Deploy limpo e alerta de falha ligado nas duas. A cadeia do Conexa segue **diária** e
**linear**: `supabase-x0tz` → `mbpv` → `6qKc` → `54P5` → `T3ct` → `rbJW` → `bZT5` →
`8uTi` → `schs`.

---

## 1. O achado: o MRR triplicou em dez meses

| mês | contratos | MRR |
|---|---:|---:|
| 2025-12 | 41 | R$ 30.188,55 |
| 2026-01 | 47 | R$ 36.028,15 |
| 2026-02 | 49 | R$ 41.537,75 |
| 2026-03 | 59 | R$ 51.193,37 |
| 2026-04 | 62 | R$ 59.252,77 |
| 2026-05 | 82 | R$ 77.923,61 |
| 2026-06 | 82 | R$ 78.853,51 |
| 2026-07 | 96 | R$ 87.021,24 |
| 2026-08 | 100 | R$ 96.330,54 |
| **2026-09** | **103** | **R$ 102.470,04** |

**Curva sem um único mês de queda.** 3,4× em dez meses.

---

## 2. A flag foi MEDIDA antes de ser descartada — e aqui ela não mente

Contrato vigente no mês sai da **data**, não de `is_ativo`. Mas a flag foi conferida:
`is_ativo` e a vigência por data concordam em **102 de 102 contratos, zero divergência
nos dois sentidos**, e o MRR bate ao centavo (R$ 102.470,04 dos dois lados).

**Contraste direto com o Conta Azul**, onde 285 de 395 parcelas vencidas **não**
carregam o rótulo `ATRASADO` e filtrar pelo status perde 72% dos casos. Duas fontes
financeiras, uma flag honesta e outra não — **medir antes de supor, por sistema**.

A data manda mesmo assim, e por uma razão que não é desconfiança: **é ela que permite
olhar um mês passado.** A flag só sabe de hoje.

---

## 3. `is_faturada` da venda é ESTÁGIO, não acumulado — a armadilha mais cara

| status canônico | vendas | tem cobrança | `is_faturada` |
|---|---:|---|---|
| PAGA | 2.187 | sim | **false** |
| PAGA_PARCIAL | 20 | sim | **false** |
| FATURADA | 169 | sim | true |
| FATURADA_CANCELADA | 23 | sim | true |
| FATURADA_NEGOCIADA | 2 | sim | true |
| NAO_FATURADA | 950 | não | false |
| CANCELADA | 122 | não | false |

`is_faturada` é TRUE em **194 vendas**; as **2.207 que já foram pagas saem com FALSE**,
embora tenham cobrança. Medir faturamento por ela devolve **194 de 2.401 (8%)** e
**R$ 154.833,48 de R$ 1.419.457,71 (11%)**.

**A invariante correta:** `tem_cobranca = is_faturada OR is_paga`, verdadeira em
**2.401 de 2.401**, zero exceções nos dois sentidos.

---

## 4. Somar venda com cobrança duplica R$ 1,42 milhão

As 2.401 vendas que já estão dentro de uma cobrança somam **R$ 1.419.457,71** e seriam
contadas duas vezes. A ponte é exata: **2.401 ids citados nas cobranças e 2.401 casam,
zero órfãs**.

A tabela emite apenas `valor_vendas_sem_cobranca` — a parte que ainda **não** virou
cobrança, e que por isso **é aditiva** com o faturado.

**A conta fecha:** 3.473 vendas vigentes = 2.401 com cobrança + 122 canceladas + **950
em aberto (R$ 430.069,84)**. E esse pipeline é exatamente o total das `NAO_FATURADA` da
Trusted, ao centavo.

---

## 5. Futuro é maioria nas duas tabelas

- **Receita:** 1.228 das 2.090 linhas (**58,8%**) são de mês futuro — há contrato com
  fim contratado até 2027-09 e venda recorrente já gerada.
- **Despesa:** 374 das 1.221 despesas (30,6%), mas **R$ 1.704.896,82 de R$ 3.065.689,75
  — 55,6% do dinheiro**.

Quem somar qualquer das duas inteira **soma agenda com entrega**. `flag_mes_futuro` é o
filtro, nas duas. Mesma doutrina da recorrência do VJOB (349 de 410 ocorrências são
agenda) e do escopo, com cadastro até 2027.

---

## 6. NULL aqui é ZERO MEDIDO — e essa é a exceção à doutrina da casa

A casa repete "zero não é zero, é NULL". Aqui vale o **inverso**, e por isso foi medido:

- `valor_pago` é NULL em **152 das 874 cobranças** vigentes, e **151 delas têm
  `tem_pagamento = FALSE`**. A origem escreve NULL onde não houve pagamento — e não
  ter havido pagamento é um **fato**, não uma lacuna.
- `valor_em_aberto` é NULL nas **737 quitadas**, pelo mesmo motivo.
- Na despesa, o mesmo: `valor_pago` NULL em 404 (as em aberto), `valor_em_aberto` NULL
  em 817 (as pagas).

Por isso esses levam `IFNULL` dentro da soma **e a taxa não leva**. Sem o `IFNULL`, uma
linha faz o mês inteiro virar NULL. A distinção é: **ausência de registro → NULL;
registro que diz zero → zero.**

---

## 7. O rateio existe na estrutura e não é usado — e o código pondera assim mesmo

A Trusted de despesa declarava: *"uma despesa pode ratear em mais de um centro de custo:
somar por centro sem desaninhar atribui tudo a um só; desaninhar sem ponderar
multiplica"*.

Medido: **`flag_rateio_multiplo` é FALSE nas 1.221 vigentes**, `qtd_centros_custo` é 1
em todas, e o `percentage` é **100 em todas as linhas do array**. A expansão devolve
1.221 linhas para 1.221 despesas — nada multiplica.

**A ponderação continua no código assim mesmo.** A estrutura permite o rateio, e no dia
em que a origem usar, a query já está certa. A identidade prova que ela não distorce
hoje: **o valor rateado soma R$ 3.065.689,75, exatamente o valor direto**.

---

## 8. Uma armadilha de nome evitada: `dim_categoria_vbot` é catálogo de RECEITA

A categoria da despesa **sai sem nome, de propósito**.

Existe uma `dim_categoria_vbot` na Raw com 11 linhas — e ela lista **"Receita
Recorrente", "Planos de Assinatura (Recorrente)", "Setup", "Mídia On", "Serviços
Profissionais"**. É o catálogo do que a VBOT **vende**, não do que ela gasta.

A despesa usa **18 ids** de um plano de contas diferente, e **13 deles nem existem**
naquela tabela. Juntar as duas rotularia 5 categorias de despesa com nomes de receita
**por coincidência numérica**.

Mesmo mecanismo já medido na `trs_vjob__auditoria_servico`, onde `categoria` aponta para
`tbservicosauditoria` e não para `tbcategoriasauditoria`. **Órfão é melhor que falso par.**

**O centro de custo, esse sim, resolve inteiro:** 10 dos 11 cadastrados são usados,
**zero ids órfãos**.

---

## 9. Onde a VBOT gasta

| centro de custo | valor |
|---|---:|
| SUPORTE TÉCNICO | **R$ 1.303.782,05 (42,5%)** |
| DIRETORIA EXECUTIVA | R$ 529.450,00 |
| CORPORATIVO | R$ 400.470,89 |
| COMERCIAL | R$ 299.057,34 |
| OPERAÇÕES | R$ 280.875,27 |
| DIRETORIA DE TECNOLOGIA | R$ 149.564,69 |
| DIRETORIA ADM/FIN | R$ 42.000,00 |
| ADMINISTRATIVO | R$ 33.383,32 |
| FINANCEIRO | R$ 25.177,01 |
| DIRETORIA COMERCIAL | R$ 1.929,18 |

---

## 10. O que NÃO foi feito, e por quê

- **Margem da VBOT não se calcula.** `trs_conexa__despesa` **não tem cliente** — tem
  fornecedor, categoria e centro de custo. As duas tabelas declaram isso, cada uma do
  seu lado. Comparar receita e despesa só é honesto **no total do mês**, nunca por
  cliente.
- **Não somar com `rfn_financeiro__rentabilidade_cliente` nem com
  `rfn_financeiro__fluxo_caixa`.** Esta é a operação VBOT no Conexa; aquelas são a
  Vanguarda Comunicação no iClips e no Conta Azul. A casa já mediu que a cobrança de
  R$ 5,00 da Vanguarda Comunicação aparece nos **dois** lugares.
- **Regras de qualidade sobre as duas** entram quando elas materializarem (amanhã
  01:00). As candidatas são as duas identidades já medidas: o valor rateado da despesa
  reproduzindo o valor direto, e `tem_cobranca = is_faturada OR is_paga` na venda.

---

## 11. Divergência aparente com a inadimplência, explicada

`valor_vencido` aqui soma **R$ 63.704,74**; a Trusted tem **R$ 65.080,94**. A diferença
é **um título vencido de R$ 1.376,20 sem mês de competência**, que esta tabela descarta
por ter grão de mês.

E os **R$ 54.198,56 / 30 títulos** registrados em 25/09 na
`rfn_financeiro__inadimplencia_vbot` são de **antes da carga de 28/09** — hoje a Trusted
tem **46 títulos vencidos vigentes**. **A base andou, não o tratamento.**

---

## 12. Validação — medida antes de publicar

| verificação | receita | despesa |
|---|---|---|
| linhas = chaves | 2.090 = 2.090 | 447 = 447 |
| clientes / centros órfãos | 0 | 0 |
| `id_cliente` nulo nas origens | 0 | — |
| razão faltando onde há valor | 0 | 0 |
| razão presente onde não há valor | 0 | 0 |
| multiplicação pela expansão do array | — | 0 (1.221 → 1.221) |
| totais contra a Trusted | ao centavo | ao centavo |

Receita: faturado R$ 1.458.607,32 · recebido R$ 1.248.927,44 (85,6%) · vencido
R$ 63.704,74 · pipeline R$ 430.069,84.
Despesa: valor R$ 3.065.689,75 · pago R$ 1.205.785,43 · futuro R$ 1.704.896,82.
