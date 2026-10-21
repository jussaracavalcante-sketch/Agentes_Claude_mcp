# 30/09 — a suíte do Linear: 19 regras, e não sobra tabela materializada sem regra

`rfn_qualidade__regra_linear` (`query-APFG`, Refined / `qualidade`, **L2 INTERNAL**, gatilho de
evento em `query-v0NV`, alerta ligado, deploy limpo, **cadência diária**).

**`trs_linear__issue` (230 linhas) era a última tabela materializada sem uma única regra.**
A casa passa a ter **380 regras em onze tabelas de qualidade**.

## O que ela NÃO duplica, e como isso foi conferido

A `rfn_qualidade__regra` já tem **duas** regras de Linear, as duas sobre a Refined:
`id_issue_mensal` (unicidade da chave) e `conclusao_nao_atravessa_mes`. **Nenhuma das 19 repete
essas duas.**

A mais próxima, `chave_concorda_com_o_grao`, mede coisa diferente — que a chave **reproduz** o
grão, não que ela é única. E `media_nunca_sem_conclusao` verifica a **coerência** de
`flag_conclusao_atravessa_mes` com `qtd_conclusoes_de_outro_mes`, enquanto a da principal afirma
que a travessia **nunca acontece**.

**Cobertura se confere consultando a suíte por `tabela`, nunca pela memória do que foi escrito** —
foi exatamente assim que o inventário desta manhã se corrigiu de "seis tabelas sem regra" para
quatro.

## As três identidades, todas entre camadas — e elas são o próprio teste de frescor

| identidade | os dois lados |
|---|---:|
| `criadas_reproduzem_a_trusted` | **230 = 230** |
| `concluidas_reproduzem_a_trusted` | **67 = 67** |
| `balde_sem_projeto_nao_perde_issue` | **26 = 26** |

**A terceira é a que guarda a sentinela, e ela pega o que as outras duas não pegam.** 26 das 230
issues não têm projeto, e a Refined **não pode deixá-las de fora** porque `id_unidade` é parte da
chave. Em vez de NULL, ela usa o rótulo explícito `(sem projeto)`. Se o balde perder issue, **as
outras duas identidades continuam fechando** — a issue some do balde e some do total do mesmo
jeito — e **só esta denuncia**.

**Não há regra de frescor de carga aqui**, e a ausência é a decisão: uma Gold defasada divergiria
da Trusted na hora. Mesmo desenho da suíte da VBOT, publicada hoje.

## A que guarda o fuso, e ela tem história nesta tabela

`dt_criacao_reproduz_a_data_local`.

O Linear produziu o **segundo caso confirmado desta base de DATA disfarçada de TIMESTAMP**, e
nele o dano seria de **100%**: das 83 issues com `dueDate`, **zero** têm hora diferente de
00:00:00 e **todas as 83** mudariam de dia se lidas com `DATE(dueDate,'America/Sao_Paulo')`.

Na **mesma tabela**, `createdAt` e `completedAt` são instantes de verdade e **precisam** da
conversão. Os dois tratamentos convivem — é a confirmação prática do *medir coluna a coluna,
nunca aplicar fuso por família*.

A Trusted resolveu isso coluna a coluna. A regra fixa o resultado: `dt_criacao` é
`DATE(criada_em)` **sem segunda conversão**. Se alguém reaplicar fuso sobre um valor já local,
ela acende.

## As outras que guardam premissa

- **`identificador_unico`** — `VAN-5` é a chave **humana**, a que aparece em branch, URL e em
  toda conversa. Duplicata ali quebra referência **sem** quebrar o `id_issue`.
- **`estado_tipo_conhecido`** — os cinco tipos canônicos do Linear (`backlog`, `unstarted`,
  `started`, `completed`, `canceled`). Tipo novo cairia **fora** de toda leitura por estado sem a
  contagem de linhas mudar. A regra é segura aqui porque o conjunto é **fixo na plataforma**, ao
  contrário de um `tipo_evento` que a própria casa espera ver crescer — e por isso a suíte de
  Marketing deixou aquela de fora.
- **`conclusao_concorda_com_o_carimbo`** — e nunca concluída **e** cancelada ao mesmo tempo.
- **`dias_ate_conclusao_reproduz_as_datas`** — existe **só** com conclusão, nunca zero. Média de
  1,88 dia e 40 das 67 no mesmo dia: se a coluna passar a sair zero onde não há conclusão, a
  média despenca e nada denuncia.
- **`parte_nunca_excede_a_coorte`** — coorte e fluxo são populações diferentes e **não se dividem
  uma pela outra**; a regra guarda o lado que **é** comparável.

## O que NÃO entrou, e a ausência é a decisão

- **Equipe única.** Há **uma só** equipe (VAN) nas 230 issues, mas uma regra exigindo isso
  transformaria crescimento legítimo em falha. Entrou `equipe_preenchida`.
- **Os quatro campos mortos** já declarados na Trusted (`cycle`, `estimate`, `archivedAt`,
  `previousIdentifiers`) — **não são emitidos**, então não há o que medir. Emitir para depois
  medir seria o erro do `stats` do GitHub.
- **Responsável.** 196 das 230 (85%) não têm, e isso é da **origem**. Limiar ali acusaria o que é
  legítimo.
- **Frescor de carga.** A `linear-byrt` roda diária com 100% de sucesso, mas **o Linear parou de
  ser usado**: última issue criada 28/07/2026, última conclusão 25/06. Uma regra de "dado
  recente" acusaria todo dia um fato já conhecido e documentado — a fonte está sã, o que não há é
  atividade nova.

## Validação

A query inteira foi rodada sobre as tabelas materializadas **antes do deploy**: **19 regras, 19
ids distintos, CONFORME 19, zero falhas**.

## O painel fechado

| suíte | regras | cadência |
|---|---:|---|
| `rfn_qualidade__regra` (principal) | 84 | diária |
| `rfn_qualidade__regra_iclips` | 45 | `notebook-Rbpo` |
| `rfn_qualidade__regra_midia` | 43 | semanal |
| `rfn_qualidade__regra_vjob` | 37 | semanal |
| `rfn_qualidade__regra_cadastro` | 34 | diária |
| `rfn_qualidade__regra_midia_gold` | 30 | Google Ads / PI |
| `rfn_qualidade__regra_marketing` | 24 | diária |
| `rfn_qualidade__regra_vbot` | 23 | diária |
| `rfn_qualidade__regra_gmail` | 22 | diária |
| **`rfn_qualidade__regra_linear`** | **19** | **diária** |
| `rfn_qualidade__regra_contazul` | 19 | semanal |
| **total** | **380** | |

## O que continua de fora, e por quê

As **3 Trusted do GitHub** e a `rfn_operacao__repositorio_mensal` — **não existem como tabela**.
A fonte `github-s0VO` está **desativada** desde 26/09 com `401 Bad credentials`, o gatilho de
evento nunca disparou. Referenciar tabela não materializada derruba a query inteira. A troca de
credencial é na interface web da Nekt e é decisão dela.
