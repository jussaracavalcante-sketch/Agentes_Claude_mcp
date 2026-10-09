# `rfn_operacao__alteracao_cronograma_mensal` — o que muda nos contratos, quando, quanto e por quem

**Publicada em 2026-09-28** · `query-CHK9` · Refined / `operacao` · **1.003 linhas** ·
**L4 PERSONAL_DATA** · gatilho de evento em `query-v4r2` · alerta ligado · deploy limpo.

`tbmudancas` é **o único log de alteração de dinheiro de contrato que esta base tem** —
18.955 eventos, 22/04/2024 a 23/09/2026 — e até hoje **nada na camada de consumo o lia**.
A Trusted existia desde 24/09 e era lida por ninguém, nem pela suíte de qualidade.

**Grão: um mês, uma coluna alterada, uma pessoa.** Chave `id_alteracao_mensal` =
`<mes>:<coluna>:<id_usuario ou SEM_USUARIO>` — 1.003 linhas, 1.003 chaves, 30 meses.

## Ela não junta com contrato nem com parcela, e isso é deliberado

A Trusted declara que `id_alvo` aponta **ora para o CONTRATO ora para a PARCELA** e que em
**8.786 linhas (46,4%) é indecidível** — as duas sequências de id se sobrepõem em 4.121
valores. Um join direto duplicaria essas linhas entre as duas pontas **sem que a contagem
denuncie**.

**Esta Refined resolve o problema não o tendo.** O grão é o evento agregado, nenhum join de
alvo acontece, e o `alvo_resolvido` viaja como **contagem** em cada linha —
`qtd_alvo_contrato`, `qtd_alvo_parcela`, `qtd_alvo_ambiguo`, `qtd_alvo_nao_catalogado`.
A ambiguidade fica visível sem multiplicar o grão, e **a soma das quatro contagens é 18.955,
o total exato da Trusted**.

## O lote de 22/09/2026 muda a leitura de setembro

| | |
|---|---|
| alterações | **1.367** |
| janela | **11 min 28 s** (11:43:18 → 11:54:46) |
| coluna | `servico`, todas |
| alvos distintos | **1.367** — um por alteração |
| valores de usuário | 19 |

Isso não é gente trabalhando, **é script**. E o conteúdo confirma:

| de | para | vezes |
|---|---|---:|
| 56 `Veiculação de Mídia` | **157 `VEICULAÇÃO DE MÍDIA OFF`** | 1.002 |
| 56 `Veiculação de Mídia` | **158 `VEICULAÇÃO DE MÍDIA ON`** | 365 |

Os ids 157 e 158 foram criados em `tbservicoscronograma` em **18/08/2026 22:54**. É uma
**recodificação de catálogo de serviço**, não operação — e **1.368 das 1.401 alterações de
`servico` de toda a história do log (97,6%) são deste único dia**.

**Sem separar, 2026-09 é o maior mês da série** — 1.577 alterações e 22 pessoas, depois de
meses de 228 a 382. E não é.

**Consequência para quem lê série de serviço no cronograma:** `trs_vjob__cronograma` e
`trs_vjob__cronograma_parcela` leem o serviço **vigente**, e a recodificação foi retroativa.
O histórico anterior a 22/09/2026 aparece hoje como OFF/ON, embora na época fosse
"Veiculação de Mídia". Não é erro do tratamento; é o estado da origem.

### O critério de lote é físico, não um limiar escolhido

Um par (dia, coluna) é lote quando tem **≥ 100 eventos E ≥ 1 evento por segundo
sustentado**. Ninguém edita um contrato a cada meio segundo. E a medição mostra que o
critério não está numa zona cinzenta:

| dia | coluna | eventos | por segundo |
|---|---|---:|---:|
| **2026-09-22** | **servico** | **1.367** | **1,99** |
| 2024-07-22 | mesanoreferencia | 889 | 0,09 |
| 2025-10-10 | vencimentocontrato | 109 | 0,01 |
| 2024-07-04 | vencimentocontrato | 145 | 0,00 |
| 2024-09-18 | piocci | 147 | 0,00 |

**22× de folga para o segundo mais denso da base inteira.** `qtd_em_lote` (1.367) e
`qtd_fora_de_lote` (17.588) convivem em toda linha — **série de operação humana se lê em
`qtd_fora_de_lote`**.

## `usuario` é ID e resolve — a Trusted estava errada

A Trusted afirmava, desde 24/09: *"`usuario` É TEXTO, NÃO ID — 42 valores distintos. Não
junta com `trs_vjob__usuario` por chave; quem quiser a pessoa casa por rótulo, e isso é
hipótese, não prova."*

**Medido em 28/09: os 42 valores são todos numéricos e 40 existem em `trs_vjob__usuario`.**
O join é **por id, exato**, e cobre **17.296 de 18.955 linhas (91,2%)**. Os dois que não
resolvem (ids 282 e 347, 706 linhas) só aparecem em 2024 — gente que saiu e cujo cadastro
não está mais lá, o mesmo mecanismo já medido no squad e no gestor.

**Eu não tinha testado o cast.** É a mesma lição já registrada cinco vezes nesta base em
outra direção: *prova de ausência é `COUNT(*)`* — e **prova de que uma coluna não é chave
também**.

A Trusted foi corrigida no mesmo dia (`query-v4r2`): passa a emitir `id_usuario`,
`usuario_nome` e `flag_usuario_nao_catalogado`, com `usuario` preservado cru ao lado.

**Sem pessoa não vira uma pessoa "desconhecida":** `id_usuario` sai NULL e a linha se
distingue por `flag_sem_usuario` (não havia usuário, 953 linhas) ou
`flag_usuario_nao_catalogado` (havia, e o cadastro sumiu, 706). Fundir os dois num balde só
esconderia qual dos dois problemas é.

## Dinheiro só onde há dinheiro

`delta_valor`, `valor_antigo_total`, `valor_novo_total`, `qtd_aumento` e `qtd_reducao` saem
**NULL** fora de `valor` e `comissao` — **nunca zero**. Zero seria somado; NULL obriga a
decidir. Verificado: **zero linha monetária sem delta e zero linha não monetária com delta**.
Nas 444 alterações monetárias 100% dos dois lados são numéricos.

| coluna | eventos | delta | subiu | desceu |
|---|---:|---:|---:|---:|
| `valor` | 355 | **+R$ 160.468,78** | 192 | 163 |
| `comissao` | 89 | **−R$ 311,27** | 25 | 64 |

**`delta_valor` NÃO é "o contrato cresceu".** O campo alterado pertence ora ao contrato ora
à parcela — e a casa já mediu que `tbcronograma.valor` é o valor de **uma parcela**, não do
contrato. O delta é o **movimento líquido do campo logado**, misturando dois grãos de
"valor": serve para ver direção e intensidade, nunca para afirmar tamanho de carteira.

**O delta telescopa e por isso soma.** Alterações sucessivas do mesmo campo (a→b, b→c) somam
para a→c, então somar `delta_valor` entre meses é legítimo. **Entre colunas, não** — `valor`
e `comissao` são grandezas diferentes, e por isso a coluna está no grão.

## A série

| mês | alterações | pessoas | alvos |
|---|---:|---:|---:|
| 2024-07 | 1.818 | 14 | 1.454 |
| 2024-09 | 1.340 | 15 | 687 |
| 2024-10 | 1.375 | 12 | 814 |
| 2025 (média mensal) | ~570 | 9–13 | ~400 |
| 2026-03 a 2026-08 | 228 a 382 | 10–16 | 199–320 |
| **2026-09** | **1.577** | **22** | **1.538** |

**As 18 colunas alteradas, por volume:** `vencimentocontrato` 6.917 · `mesanoreferencia`
5.069 · `nfse` 3.187 · `servico` 1.401 · `piocci` 1.254 · `valor` 355 · `cs` 182 ·
`cliente` 154 · `competencia` 139 · `comissao` 89 · `fornecedor` 85 · `observacoes` 67 ·
`parcelanumero` 18 · `finaldecontrato` 15 · `primeiracobranca` 11 · `iniciodecontrato` 9 ·
`os` 2 · `qtdparcelas` 1. **Não há tabela de domínio** — são nomes físicos de coluna na
origem e saem crus.

## Limitações — não contorne

1. **Isto mede EDIÇÃO, não negócio.** Um contrato cujo valor nunca foi editado não aparece
   aqui, e isso não quer dizer que ele não existe — quer dizer que ninguém editou aquele
   campo naquela tela.
2. **Não há cliente.** O alvo é indecidível em 46,4%, então não se chega ao cliente sem
   inventar. Para dinheiro por cliente, `rfn_financeiro__rentabilidade_cliente`.
3. **8 eventos não alteraram nada** (`qtd_sem_mudanca`). Contam em `qtd_alteracoes` porque
   foram gravados; quem mede mudança de fato subtrai.
4. **`os` (2) e `qtdparcelas` (1)** têm volume próximo de zero. Não tirar tendência.
5. **A série começa em 2024-04.** O módulo de cronograma é mais antigo que o log.

**FUSO:** relógio local da intranet, herdado da Trusted. Não converter.

## Ainda não materializou

A `mysql-yIOn` rodou 27/09 01:00→01:51 e as duas mudanças de hoje são posteriores. Entram na
passada de domingo, na ordem `query-v4r2` → `query-CHK9`. As regras de qualidade entram
quando a tabela existir — a candidata é a identidade aditiva
(`SUM(qtd_alteracoes)` = total da Trusted, e a soma dos quatro `alvo_resolvido` igual a ela).
