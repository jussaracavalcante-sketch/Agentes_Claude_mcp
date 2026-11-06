# `rfn_operacao__recorrencia_mensal` — a agenda que já foi desfeita

**Publicada em 2026-09-29** · `query-FJzZ` · Refined / `operacao` · **111 linhas** ·
**L2 INTERNAL** · gatilho de evento em `query-r7ps` · alerta ligado · deploy limpo.

Grão: **uma regra de recorrência em um mês de prazo planejado**. Chave
`id_recorrencia_mensal` (`<id_recorrencia>:<mes>`), **111 para 111 linhas**.

Origens: `trs_vjob__recorrencia_ocorrencia` (426) · `trs_vjob__job_recorrencia` (30) ·
`trs_vjob__job_tarefa` (só o job que originou a regra).

Fecha as duas últimas Trusted de recorrência, que eram lidas **só pela suíte de
qualidade**.

---

## O achado: 90 das 356 ocorrências futuras já estão canceladas

**25,3% da agenda futura já foi desfeita.** A máquina continua gerando e alguém cancela
adiantado.

| mês | ocorrências | futuras | futuras já canceladas |
|---|---:|---:|---:|
| 2026-09 | 82 | 12 | 5 |
| 2026-10 | 123 | 123 | **35** |
| 2026-11 | 115 | 115 | **34** |
| 2026-12 | 106 | 106 | **16** |

**Isto não é agenda que vai acontecer nem entrega que aconteceu — é agenda já desfeita**,
e ela some das duas leituras se ninguém separar: quem filtra
`flag_ocorrencia_futura = FALSE` para medir entrega não a vê, e quem conta agenda futura
a conta como trabalho previsto.

Mais **2 ocorrências de dezembro que já constam CONCLUÍDAS**, com prazo futuro.

---

## O denominador da conclusão é a ocorrência vencida, e a diferença é de seis vezes

Das 426 ocorrências, **só 70 já venceram**:

| | n | sobre as vencidas |
|---|---:|---:|
| concluídas | **31** | **44,3%** |
| canceladas | 25 | 35,7% |
| ainda abertas | 14 | 20,0% |

Sobre o total de 426, a taxa de conclusão sairia **7,3%** — e pareceria uma operação
parada, quando o que há é agenda que ainda não chegou. Mesmo mecanismo do item inativo da
auditoria e da pauta cancelada do blog.

`qtd_ocorrencias`, `qtd_vencidas` e `qtd_futuras` convivem na linha para ninguém dividir
pelo denominador errado sem perceber.

**Sem ocorrência vencida a taxa é NULL, nunca zero** — são **84 das 111 linhas (75,7%)**,
quase toda a tabela. `flag_sem_ocorrencia_vencida` acende.

---

## A agenda é de três meses e meio, e 83,6% dela ainda não venceu

De **04/09 a 25/12/2026**. `flag_ocorrencia_futura` da Trusted é **relativa à data da
carga**, não a uma data fixa — a tabela é reconstruída inteira a cada execução, então esta
divisão se move. Para corte histórico estável, comparar `primeiro_prazo` / `ultimo_prazo`
contra a data escolhida, nunca a flag.

---

## `ocorrencias` da regra é campo morto

**Zero preenchidos nas 30 regras.** Sai **NULL, nunca zero** — zero diria "esta regra
prevê nenhuma ocorrência", que é uma afirmação, e a origem não a faz.

**Não há como saber quantas ocorrências uma regra deveria gerar**; só quantas gerou.

---

## A ligação é 1:1 e exata

426 ocorrências, **426 `id_job_unico` distintos**, 30 regras, **zero órfãos nos dois
lados**. Nenhuma ocorrência divide job, nenhuma regra sem cadastro. As 30 regras
produziram de 1 a 16 ocorrências cada.

**O prazo quase nunca muda:** só **4 das 426** têm `flag_prazo_alterado` — a ocorrência
guarda o prazo **original** e o job guarda o **vigente**, e os dois batem em 422.
Deslocamento de 1 a 3 dias, nada parecido com os 365 do maior adiamento da base.

---

## Limitações — não contorne

1. **NÃO HÁ CLIENTE AQUI.** O job da recorrência carrega `projeto`, que é numérico e não
   resolve contra nenhuma tabela-pai no catálogo — e, medido, **as 30 regras apontam para
   um único projeto**. Recorrência por cliente não se mede nesta base.
2. **`resumo` repete: 30 regras para 12 resumos distintos.** É rótulo de cadência, não
   identificador. `atividade_da_regra` tem 17 valores — não agrupar por ele esperando
   dimensão.
3. **A recorrência é 1,9% da operação** — 30 de 1.585 jobs do módulo TAREFAS têm regra, e
   **24 das 30 não terminam nunca**. Dois tipos só: `semanal` e `personalizada`.
4. **Ocorrência não é entrega.** O que ela diz é que a máquina criou um job para aquela
   data. A conclusão vem do status do job.

**L2 INTERNAL:** ids, datas, contagens e rótulos de cadência. Nenhum nome de pessoa é
emitido. **Fuso:** relógio local da intranet, não converter.

---

## Medido em 2026-09-29

111 linhas · 111 chaves · 30 regras · 4 meses · 426 ocorrências (= 70 vencidas + 356
futuras, fecha) · 70 vencidas = 31 concluídas + 25 canceladas + 14 abertas, fecha ·
**90 futuras já canceladas** · 2 futuras já concluídas · 4 com prazo alterado · **zero
regra órfã e zero job órfão** · 84 linhas sem ocorrência vencida · 17 atividades ·
12 resumos · zero com `ocorrencias` preenchido.

---

# E o checklist diário NÃO recebeu Gold — a medição decide contra

`trs_vjob__checklist_diario` (2.748, `query-OFX4`) foi medida e **fica sem Refined**, pelo
mesmo precedente do `tbclientexservico` e do módulo `vmkt_*`: estrutura boa não é uso.

**88,7% do volume está em DOIS meses.**

| mês | itens | contas | dias | marcados |
|---|---:|---:|---:|---:|
| 2025-04 | 1 | 1 | 1 | 0 |
| **2025-05** | **1.324** | 41 | 18 | 1.305 |
| **2025-06** | **1.114** | 40 | 16 | 1.110 |
| 2025-07 | 218 | 8 | 13 | 217 |
| 2025-08 | 68 | 8 | 4 | 68 |
| 2025-09 | 18 | 9 | 2 | 15 |
| 2025-11 | 3 | 2 | 2 | 0 |
| 2026-02 | 2 | 1 | 1 | 0 |

E o instrumento **não discrimina nada**: **2.715 de 2.748 marcados (98,8%)**, e
**2.700 dos marcados no próprio dia previsto** — 48 depois, **zero antes**. `fase` é
**constante** (um único valor nas 2.748) e só **8 das 34 atividades** do catálogo foram
usadas.

Uma Refined aqui apresentaria como indicador operacional um instrumento usado por dois
meses e abandonado, com taxa saturada em 98,8% e uma dimensão constante. **A Raw e a
Trusted continuam lá** — não se apaga nada. O que não se faz é publicar como indicador o
que ninguém usou.
