# `rfn_operacao__tarefa_projeto` — a maior Trusted sem Refined desta base

**Publicada em 2026-09-29** · `query-BzKD` · Refined / `operacao` · **8.835 linhas** ·
**L2 INTERNAL** · alerta ligado · deploy limpo.

Grão: **uma tarefa de projeto do iClips**. Chave `id_tarefa_job`, 8.835 para 8.835 linhas.

Origens: `trs_iclips__tarefa` (8.835) · `trs_iclips__projeto` (12.106) ·
`trs_iclips__apontamento` (5.580, só o que liga a tarefa).

`trs_iclips__tarefa` era a **maior Trusted desta base sem nenhuma Refined lendo**.

---

## O gatilho usa `event_rule = "all"`, e isso é novo aqui

As três Trusted de origem disparam **em paralelo** no `notebook-Rbpo`, e esta Refined lê
as três. Uma delas pode materializar depois da outra, e referenciar tabela que ainda não
foi reescrita é o defeito que esta casa já corrigiu **quatro vezes** linearizando cadeia
(GitHub, job do VJOB, Google Ads, notificação de etapa) — sempre **mexendo no gatilho de
transformação publicada de terceiro**.

Aqui a solução é o primitivo que a própria Nekt oferece: `event_rule = "all"` sobre os
três slugs (`query-8nEt`, `query-9nws`, `query-tF7c`). A Refined espera **as três
terminarem**. **Nenhum gatilho publicado foi alterado.**

**Fica registrado como alternativa à linearização:** quando as origens já disparam todas
no mesmo upstream, `"all"` resolve sem tocar em nada de terceiros. Linearizar continua
sendo o caminho quando as origens estão em ramos diferentes da árvore.

---

## O achado: `qtd_apontamentos` da Trusted não conta apontamento

A coluna é `ARRAY_LENGTH($.atividades)` — o número de **atividades dentro da tarefa no
payload do projeto**. Ela **soma 13.353** sobre as 8.835 tarefas.

A `trs_iclips__apontamento` inteira tem **5.580 linhas**, e apenas **103** ligam a uma
tarefa. Somar `qtd_apontamentos` achando que é apontamento mede outra coisa, **2,4×
maior que o universo inteiro de apontamento da base**.

Aqui a coluna sai com o nome do que ela é — **`qtd_atividades_no_payload`** — e o tempo
real vem da tabela de apontamento, por junção, em colunas separadas.

---

## Tempo real cobre 0,9%, e são DUAS causas, não uma

Dos 5.580 apontamentos, **103 têm `id_tarefa_job`** e cobrem **83 das 8.835 tarefas
(0,9%)**, somando **15,6 horas** e **R$ 43,42** de custo apontado. Os 103 casam **100%
— zero órfãos**.

1. **O vínculo é exclusivo**, e a Trusted já declarava: o apontamento se liga **ou** a
   uma etapa de peça **ou** a uma tarefa, nunca aos dois — e o volume está na peça
   (6.810 via peça contra 74 via tarefa na medição original da Trusted).
2. **A janela.** `trs_iclips__apontamento` é uma **janela móvel de cerca de dois meses**
   — medida hoje em **21/07/2026 a 29/09/2026** — enquanto a tarefa vai de **2020 a
   2027**. Mesmo que toda tarefa apontasse hora, esta junção só alcançaria a janela
   corrente.

E dos 83 pares, **69 nem data de play têm** (sentinela anulada na Trusted).

`tempo_gasto_min`, `qtd_executores` e `custo_apontado` saem **NULL nas 8.752 sem
apontamento, nunca zero**.

---

## Zero não é estimativa, é sentinela

**8.477 das 8.835 tarefas (95,9%) têm `tempo_estimado_min = 0`**; só **358 (4,1%)** têm
estimativa de verdade, somando **232,4 horas**.

Média sobre a tabela inteira daria **1,6 minuto** por tarefa; sobre as que têm, dá
**39 minutos**. A coluna sai NULL no zero e `flag_sem_estimativa` marca.

---

## Os dois conjuntos são disjuntos: a razão é NULL em 8.835 de 8.835

As **358** tarefas com estimativa e as **83** com tempo apontado **não têm uma única em
comum**.

`razao_gasto_sobre_estimado` existe, está correta e **hoje não mede nada**. Sai **NULL
em vez de zero** exatamente por isso: zero diria "gastou nada do que foi estimado", que
é uma afirmação, e a base não a faz.

**Não existe, nesta base, comparação entre hora estimada e hora gasta no grão da
tarefa.**

---

## O projeto resolve 100%, e por isso o cliente também

**8.835 de 8.835 casam** com `trs_iclips__projeto`, **zero órfãos**. Dali vem:

- **CNPJ em 8.618 (97,5%)**, 271 documentos distintos, 217 sem CNPJ
- **nome de cliente em 8.789**, 303 clientes
- **2.732 projetos** distintos

`flag_projeto_nao_catalogado` existe mesmo assim: se um dia acender, é sinal de que a
dimensão **perdeu linha** — exatamente como `github_repositories`, que foi de 10 para
zero quando a fonte caiu e deixou os fatos intactos.

---

## O mês é o do início planejado, e há tarefa até 2027

`mes_referencia` é o mês do **início planejado**, não o da execução — **a tarefa não
carrega data de execução nenhuma**. São **82 meses distintos**.

**722 tarefas não têm data planejada** (`flag_sem_data_planejada`) e entram com mês
NULL, nunca descartadas.

O intervalo vai de **01/01/2020 a 24/09/2027** e **55 tarefas começam no futuro**
(`flag_inicio_futuro`). Toda série precisa de recorte de janela explícito, como já vale
no escopo do VJOB e na ocorrência de recorrência.

---

## Limitações — não contorne

1. **A tarefa não tem status nem conclusão.** Não há coluna dizendo se ela foi feita.
   `status_do_projeto` é do **projeto** (4 valores), não da tarefa — usá-lo como se
   fosse da tarefa afirma o que a base não afirma.
2. **O histórico não avança sozinho.** O bronze depende da `supabase-x0tz`; **8.712 das
   8.835 linhas são `BRONZE_HISTORICO`** e 123 vêm do notebook. Com a fonte parada, só
   a ponta do notebook se move — e ela **falhou hoje (29/09) com senha rejeitada**.
3. **`titulo_atividade` é texto livre** — 7.204 títulos distintos em 8.835 tarefas. Não
   é dimensão; agrupar por ele é agrupar por rótulo.
4. **Custo aqui não é o custo da casa.** `custo_apontado` vem do valor/hora do executor
   no apontamento e cobre 0,9% das tarefas, somando R$ 43,42. O custo por cliente está
   em `rfn_operacao__custo_peca`, que rateia e fecha no centavo.

---

## Classificação L2, com a prova do que não atravessa

`trs_iclips__apontamento` é **L4** por trazer **executor identificado e valor/hora**.
**Nenhum dos dois atravessa**: aqui entram apenas `qtd_executores` (contagem distinta) e
`custo_apontado` (soma), nunca o nome nem o valor/hora individual. Mesma prova que fez a
`rfn_operacao__custo_peca` ficar L3 lendo uma L4.

**Fuso:** o iClips já entrega `America/Sao_Paulo` e a Trusted não converte. **Não
converter.**

---

## Medido em 2026-09-29, sobre as tabelas materializadas

8.835 tarefas · 8.835 chaves · 2.732 projetos · 303 clientes · 271 CNPJs · 217 sem CNPJ ·
82 meses · 358 com estimativa (232,4 h) · 83 com tempo real (15,6 h, R$ 43,42) ·
103 apontamentos casando 100% · **zero projeto órfão** · 722 sem data · 55 com início
futuro · soma de `qtd_atividades_no_payload` **13.353** · razão estimado/gasto **NULL em
8.835 de 8.835**.
