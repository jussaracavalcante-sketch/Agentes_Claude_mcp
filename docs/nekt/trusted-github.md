# Trusted do GitHub — três tabelas

**Publicadas em 2026-09-23** · camada `Trusted`, folder `github` · alerta de falha ligado nas três.

| Tabela | Slug | Linhas | Gatilho |
|---|---|---:|---|
| `trs_github__repositorio` | `query-UFhj` | 10 | evento em `github-s0VO` |
| `trs_github__commit` | `query-45Rs` | 790 | evento em `query-UFhj` |
| `trs_github__pull_request` | `query-3vaR` | 16 | evento em `query-UFhj` |

As duas últimas disparam na **primeira**, não na fonte. Elas dependem da tabela de
repositório para resolver o cadastro, e o evento encadeado garante a ordem — gatilho
nas três na mesma fonte seria corrida.

Arquivos: `sql/trusted/trs_github__{repositorio,commit,pull_request}.sql`.

## Unicidade — medida em 2026-09-23

| Tabela | Linhas | Chave | Distintos |
|---|---:|---|---:|
| repositório | 10 | `id` · `full_name` | 10 · 10 |
| commit | 790 | `sha` | **790 — unicidade global**, não só por repositório |
| pull request | 16 | `id` · (repositório, número) | 16 · 16 |

O `sha` do commit é único na base inteira: a chave composta `owner/repo/sha` também dá
790. Não é preciso qualificar por repositório.

## Os três achados que mudam como se lê esta fonte

**1. Três em cada quatro commits são de repositório fork.** 580 dos 790 (73,4%) vêm de
`system-prompts-and-models-of-ai-tools` (518) e `claude-user-memory` (62), os dois forks
de repositório público. Isso é histórico do repositório de origem, não trabalho da casa.
Qualquer indicador de produtividade filtra `flag_repo_fork = FALSE` — a coluna está
denormalizada na tabela de commit justamente para o filtro não exigir join.

Sem o filtro, a base parece ter 790 commits de trabalho. Com ele, tem 210.

**2. Não há volume de código em lugar nenhum desta fonte.** `stats` (adições, deleções)
é **100% NULL** nos 790 commits, e na tabela de PR `additions`, `deletions`,
`changed_files`, `commits`, `comments` e `review_comments` são **NULL nas 16 linhas**.
É a assinatura do endpoint de *listagem* do GitHub, que não devolve esses campos — só a
chamada por item individual devolveria.

As colunas ficaram **fora** das Trusted de propósito. Emiti-las como NULL convidaria a
somar e obter zero, que é um número, quando o certo é ausência.

**3. Todo PR mesclado entrou no mesmo dia.** Os 11 mesclados têm `dias_ate_merge` = 0,
média e máximo. Nenhum esperou um dia sequer. O indicador existe na tabela, mas só passa
a dizer alguma coisa quando a base crescer.

## Um repositório tem commit e não tem cadastro

`jussaracavalcante-sketch/ai-hub-agencia-aws` aparece em 3 commits (09/09/2026) e **não
existe** na tabela de repositórios: o stream `commits` alcança 11 repositórios e o
`repositories` cadastra 10.

Por isso o join é **LEFT** e acende `flag_repo_nao_catalogado`. Com `INNER` os 3 commits
sumiriam sem nenhum sinal — mesmo padrão do `flag_conta_nao_catalogada` na
`trs_google_ads__campanha`.

## Distribuição dos commits

| Repositório | Commits | Fork |
|---|---:|:-:|
| system-prompts-and-models-of-ai-tools | 518 | sim |
| Governan-a_vanguarda | 66 | |
| claude-user-memory | 62 | sim |
| Agentes_Claude_mcp | 43 | |
| app-head-ia | 35 | |
| VANGUARDA_IA_FUNCIONAL | 35 | |
| Vanguardabuilders | 20 | |
| Mapeamento_vanguarda_gov | 3 | |
| Repo_prompts_IA | 3 | |
| **ai-hub-agencia-aws** | **3** | *sem cadastro* |
| farol-da-criacao | 2 | |

## Fuso: sem surpresa, mas medido

Todos os TIMESTAMP das três tabelas são instantes de verdade em UTC — 786 de 790
`committed_at`, 10 de 10 `created_at`/`pushed_at` de repositório, 16 de 16 `created_at`
e 11 de 11 `merged_at` de PR têm hora ≠ 00:00:00. Convertem com
`DATETIME(ts,'America/Sao_Paulo')`.

**Nenhuma data disfarçada de TIMESTAMP aqui**, ao contrário do `dueDate` do Linear, onde
as 83 linhas preenchidas mudariam de dia com o fuso aplicado. Foi medido coluna a coluna
mesmo assim — é o que a casa já pagou caro para aprender.

## Duas datas de commit, e não são a mesma coisa

`commit.author.date` é quando o código foi escrito; `commit.committer.date` é quando
entrou na árvore. O campo `committed_at` da fonte é **idêntico ao committer nas 790
linhas** e difere do author em **3** — rebase ou cherry-pick, marcados com
`flag_reescrito`.

As duas ficam na tabela: quem mede entrega usa `commitado_em`, quem mede autoria usa
`escrito_em`.

## O que ficou fora, e por quê

**E-mail.** `commit.author.email` e `commit.committer.email` trazem endereço de pessoa.
Saem id, nome e, quando o GitHub resolveu a identidade, o login. Mesmo critério da
`trs_linear__issue`. Os structs de usuário de repositório e de PR **não têm e-mail** —
só o de commit tem.

**Credencial.** `temp_clone_token` é NULL nas 10 linhas e sai mesmo assim: campo de
credencial não entra em camada de consumo nem vazio. `permissions` (pull/push/admin)
também sai — descreve o token da extração, não o repositório.

**~60 colunas de URL de API.** `branches_url`, `git_refs_url`, `milestones_url` e
companhia são template de endpoint. Sobrevivem `html_url` e `clone_url`.

**O repositório embutido duas vezes no PR.** `head` e `base` carregam o objeto de
repositório completo (~90 campos cada, com `owner` dentro). Saem só `ref` e `sha` de
cada lado — de onde para onde é a informação.

## Limitações declaradas — não contorne

1. Volume de código não se mede aqui (achado 2).
2. Indicador de produtividade sem `flag_repo_fork = FALSE` é três quartos ruído (achado 1).
3. **18 commits não têm usuário GitHub resolvido** — o e-mail do commit não casou com
   conta nenhuma. Sobra o nome digitado no git, que não é identidade. Não somar por
   `autor_nome` esperando pessoa única.
4. **Não há branch no dado de commit.** O stream traz commits alcançáveis sem dizer de
   qual branch, então não dá para separar trabalho em branch de trabalho na principal.
5. **Não existe indicador de revisão.** Quem aprovou, quantas rodadas e quanto tempo
   levou exigiriam o stream `reviews`, que a fonte não traz. `assignee` é NULL nos 16 PRs.
6. `Governan-a_vanguarda` tem como branch padrão `claude/prompts-repo-infrastructure-08dmf1`,
   uma branch de trabalho. O campo está fiel à origem; comparar "commits na branch padrão"
   entre repositórios compara coisas diferentes.
7. Os 10 repositórios são **públicos** (`private = FALSE` em todos) e 8 dos 10 não têm
   descrição. Não dá para classificar repositório por conteúdo a partir desta fonte.

## Pendente

- O stream `reviews` não existe na fonte. Habilitá-lo é mexer em fonte publicada (R-002)
  e depende de pedido — sem ele, não há como medir revisão de código.
- A tabela de PR só cobre 3 dos 11 repositórios com commit. Isso pode ser real (os outros
  não usam PR) ou recorte do stream; não foi medido contra a API.
