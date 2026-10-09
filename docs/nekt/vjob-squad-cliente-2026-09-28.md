# `rfn_operacao__squad_cliente` — quem atende qual cliente, em qual papel, desde quando

**Publicada em 2026-09-28** · `query-ytQ7` · Refined / `operacao` · **4.650 linhas** ·
**L4 PERSONAL_DATA** · gatilho de evento em `query-UDGW` · alerta de falha ligado ·
deploy limpo.

Fecha três Trusted que só eram lidas pela suíte de qualidade — `trs_vjob__squad_alteracao`
(2.346), `trs_vjob__gestor_cliente` (234) e os quinze papéis de
`trs_vjob__cliente_atendimento` (310). O estado vivia no cadastro, a história vivia no log,
e **as duas leituras nunca tinham sido postas lado a lado**.

## O grão é o SLOT, e o denominador é explícito

**310 contas × 15 papéis = 4.650 linhas, 4.650 chaves** (`id_slot` = `<id_atendimento>:<papel>`),
ocupadas ou não. Emitir só o ocupado esconderia o posto vago, que é exatamente o que se quer
enxergar.

| | |
|---|---:|
| slots | 4.650 |
| ocupados | **1.308 (28,1%)** |
| ocupados em conta ativa | 526 |
| pessoas distintas | 144 (57 em conta ativa) |
| contas ativas | 105 |
| **contas ativas sem nenhum papel preenchido** | **4** |

## O ESTADO decide quem atende hoje; o LOG só data

Das **849** chaves que têm log, **838 concordam com o cadastro e 11 divergem** — e
**nenhuma linha do log aponta para um slot que não exista no cadastro**, o que prova que o
de-para entre o nome físico da coluna no log (`analistamktmeta`) e a coluna do cadastro
(`id_analista_mkt_meta`) é exato nos quinze papéis.

**As 11 divergências têm padrão.** Dez são *"o log põe alguém e o cadastro está vazio"* — o
posto foi esvaziado sem gerar linha de log — e **nove das onze estão em conta já
desativada**. A única no sentido inverso é `ALIMENTA COMÉRCIO`, uma atribuição que nunca foi
logada.

| conta | papel | no estado | no log | conta ativa |
|---|---|---|---|---|
| ALIMENTA COMÉRCIO | analistamktmeta | 446 | — | não |
| NOVA ERA (BOA VISTA / MANAUS / PORTO VELHO) | analistamktmeta | — | 235 | não |
| UIARA | analistamktmeta · assistente | — | 370 · 375 | não |
| MORADA CAFÉ | analistamkt | — | 185 | não |
| TROPICAL MULTILOJA | assistente | — | 428 | **sim** |
| OLÁ PONTA NEGRA | analistaseo | — | 353 | **sim** |
| DISLUB | analistaseo | — | 315 | não |
| FÁBRICA DE EVENTOS | assistente | — | 375 | não |

**Portanto o log NÃO é trilha de auditoria completa**, e quem o ler como estado erra em onze
contas. `flag_estado_diverge_do_log` acende e `ocupacao_desde` sai NULL nesses casos — nunca
se escolhe o log.

## `ocupacao_desde` é o início da OCUPAÇÃO ATUAL

Acha-se a última alteração que colocou **outra** pessoa (ou ninguém) e toma-se a primeira
linha posterior a ela que já aponta para o ocupante de hoje. Sem isso, um posto que passou
por A → B → A dataria de quando A chegou na **primeira** vez.

## Cobertura de data é 59,3%, e ela vai junto com o número

Dos 1.308 slots ocupados, **776 têm data e 532 não** — o log começa em **06/11/2024** e as
contas são anteriores. `flag_ocupacao_sem_data` marca. **Ausência de data nunca vira data
antiga por default**: seria inventar antiguidade.

**Consequência que muda a leitura: qualquer taxa de rotatividade tirada daqui é PISO, nunca
taxa.** O conjunto datável é, por construção, o que mudou depois de 11/2024 — ele
super-representa o recente. Em conta ativa: 526 ocupados, **433 com data (82,3%)**,
**278 (52,9% do total ocupado) trocaram de mão nos últimos 90 dias**, mediana de **61 dias**
de ocupação e máximo de **665**. Os outros 248 mudaram antes ou nunca foram logados — a
tabela não distingue os dois.

## Sete papéis sustentam a operação e oito estão praticamente vazios

Slots ocupados em conta ativa, e pessoas distintas em cada:

| papel | ocupados | pessoas |
|---|---:|---:|
| customersuccess | 101 | 13 |
| assistente | 89 | 10 |
| analistasocial | 69 | 13 |
| analistamktmeta | 66 | 7 |
| analistamktgoogle | 63 | 7 |
| analistamkt | 60 | 9 |
| analistaseo | 57 | 9 |
| sac | 16 | **1** |
| criacao | 2 | 1 |
| storymaker · criacao2 · redacao2 | 1 cada | 1 cada |
| criacao3 · redacao · redacao3 | **0** | — |

**A mesma forma aparece no log** (385 a 279 alterações nos sete, 1 a 16 nos demais): não é
lacuna de registro, **é o uso real**. Redação e criação acontecem nesta casa, mas não são
geridas por este quadro — estão em `rfn_operacao__job` e no iClips.

## O especialista roda, o dono da conta fica

Alterações por slot ocupado, em conta ativa:

| papel | alt./slot |
|---|---:|
| analistaseo | **4,37** |
| analistamkt | 4,08 |
| analistamktmeta | 3,08 |
| analistamktgoogle | 3,06 |
| analistasocial | 2,59 |
| assistente | 2,18 |
| customersuccess | **1,64** |

**O posto de relacionamento troca 2,7× menos que o de SEO.**

## Carga

57 pessoas em conta ativa, máximo de **22 contas**, média de 7,2. O topo mostra dois
formatos diferentes de carga:

| pessoa | contas | slots | papéis |
|---|---:|---:|---|
| Marcelo Sá dos Santos | 17 | 34 | google + meta |
| Carlos André Carvalho da Silva | 14 | 28 | google + meta |
| Wilkefor Reis Ribeiro | 13 | 23 | google + meta |
| Fabiane Carvalho e Silva | **22** | 22 | customersuccess |
| Renan Freitas Campos | 19 | 19 | assistente |

Quem cuida de mídia paga carrega **dois postos na mesma conta** (Google e Meta), então
`slots` e `contas` divergem — é por isso que `papel` conta **carga** e `papel_familia` conta
**função**.

## 153 slots apontam para pessoa que não existe no cadastro

**36 pessoas** — 11,7% dos slots ocupados e 25% das pessoas. Gente que saiu e cujo cadastro
não está mais lá. `flag_responsavel_nao_catalogado` acende e `responsavel_nome` sai NULL.
**Leitura por nome cobre 88,3% dos slots ocupados.**

## O gestor é 1:1 com a conta, e a aritmética está declarada

`trs_vjob__gestor_cliente` tem **234 linhas para 234 contas distintas, zero duplicidade** —
mas **39 apontam para conta que não existe** no cadastro de atendimento (conta apagada).
Então **234 − 39 = 195 contas com gestor** e 115 sem (`flag_conta_sem_gestor`, 1.725 slots).
As 39 linhas não aparecem nesta tabela, de propósito: o grão é o slot da conta viva.

**O caso BRAGA MOTORS mostra por que o universo do gestor sai cru.** O gestor id 26 é
`Silvia Calderaro` no catálogo de gestores e o customersuccess id 140 é
`Silvia Letícia Areb Calderaro` no cadastro de usuário — **a mesma pessoa com dois ids em
dois catálogos**, e por isso `flag_gestor_ja_e_papel_na_conta` sai FALSE. Casar por nome
seria casar por rótulo, que esta casa já proíbe.

## A aritmética do log fecha

`SUM(qtd_alteracoes)` = **2.346**, exatamente o total da Trusted. Nenhuma linha do log se
perde e nenhuma é contada duas vezes — **cada uma cai num único slot**. É a identidade que
guarda o de-para, e a candidata natural à suíte de qualidade quando a tabela materializar.

## Limitações — não contorne

1. **Isto não mede trabalho, mede ATRIBUIÇÃO.** Quem está no posto não é quem entregou —
   entrega está em `rfn_operacao__job` e `rfn_operacao__escopo_mensal`.
2. **Não há série histórica de estado.** A tabela é reconstruída inteira a cada execução e
   mostra o estado da carga. Para "quem atendia em março", só o log — e ele cobre 59,3% dos
   postos.
3. **`dias_na_ocupacao_atual` é relativo à data da CARGA.** Para corte histórico estável,
   comparar `ocupacao_desde` contra a data escolhida.
4. **4 contas ativas não têm nenhum papel preenchido.** Não quer dizer que ninguém atende —
   quer dizer que o quadro não foi preenchido.
5. **Carga por pessoa se calcula aqui; margem não.** Não há custo nem hora ligada ao slot.

**FUSO:** relógio local da intranet, herdado das Trusted. Não converter.

## Ainda não materializou

A `mysql-yIOn` rodou em 27/09 01:00→01:51 e esta transformação é posterior. Entra na
passada de domingo, depois de `query-UDGW`. As regras de qualidade sobre ela entram quando
a tabela existir.
