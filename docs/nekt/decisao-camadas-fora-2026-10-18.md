# Residuos de camadas — o que ganhou tratamento e o que fica de fora, com a medicao (2026-10-18)

Medido com `COUNT(*)` e amostra nas tabelas reais, somente leitura. Nada foi executado a mao e nenhuma fonte foi alterada (R-002).

## 1. Linear (`linear-byrt`) — 4 Trusted, 1 Refined, 1 suite

| stream | linhas | resultado |
|---|---:|---|
| projects | 9 | `trs_linear__projeto` (`query-HyD5`, L4 baixa) |
| issue_labels | 8 | `trs_linear__rotulo` (`query-rJgF`, L4 baixa) |
| users | 5 | `trs_linear__usuario` (`query-pdft`, L4) |
| teams | 1 | `trs_linear__equipe` (`query-aVpr`, L2) |
| cycles | 0 | sem Trusted: zero linhas; a equipe tem `cyclesEnabled = FALSE` |
| customers | 0 | sem Trusted: zero linhas |

- Refined `rfn_operacao__linear_projeto` (`query-cFzx`, L2, evento `all` em `query-HyD5` + `query-lhYJ`): 10 linhas previstas (9 projetos + balde "(sem projeto)"), soma de issues 230, concluidas 67, canceladas 22, rotulos aplicados 49. Suite `rfn_qualidade__regra_linear_estrutura` (`query-bUBo`): 26 regras, validadas reproduzindo as Trusted sobre a Raw — 26 conformes, zero falhas. As cinco tabelas novas **nao materializaram** (primeira carga agendada: `linear-byrt` 03:20 America/Manaus).
- Achados medidos: `scope` do projeto = issues nao canceladas em 9 de 9; `progress` do Linear **nao** e concluidas/escopo (3 de 8 divergem); `members` e `teams` do projeto chegam vazios; `targetDate` e data disfarcada de timestamp (0 de 5 com hora); `createdIssueCount` soma 230 = total de issues; os 3 rotulos do workspace nao tem equipe.
- **Correcao ao registro do Linear:** o Linear nao esta 100% parado. Entre 02/10 e 13/10/2026, **9 issues foram canceladas** (todas sem projeto) e 17 foram tocadas desde 30/09: as canceladas passaram de 13 para 22 (`state.type`). Continua verdade que a ultima issue criada e de 28/07 e a ultima conclusao de 25/06. A atividade recente e limpeza de backlog.

## 2. Instagram (12 fontes) — nao publicado

| stream | linhas nas 12 fontes | medicao |
|---|---:|---|
| comments | **1** | so em `instagram-JJJ4`; as outras 11 = 0 (`automaster` ainda sem tabela) |
| media_collaborators | **1** | so em `JJJ4`; as outras 11 = 0 (`automaster` sem tabela) |
| comment_replies | 0 | tabela **nao materializada** em varias camadas (acesso_saude, ac_display, amazon_open_mall, amazoncopy, ba_eletrica...) |

Decisao: **nao publicar.** Uma Trusted emitiria 1 linha. Contexto medido: as 12 fontes juntas tem 40 midias (13 a 14/10/2026), `comments_count` soma **1** — o unico comentario existente, e e o que chegou. Reabrir se `comments` passar de poucas dezenas apos a primeira carga semanal.

## 3. Paginas do Facebook (48 fontes) — nao publicado

Streams das 48 fontes (8): posts, post_insights, post_media_views_breakdown, reviews, daily_page_insights, page, page_media_views_breakdown (todos com Trusted) e **post_comments**. `COUNT(*)` de `facebook_pages_post_comments` nas 48 camadas: **1 linha** (fonte `wRty`, Constroi). Tabela existe vazia nas outras 47. Decisao: **nao publicar**, mesmo criterio do Instagram. Texto de comentario seria L4 e nao atravessa.

## 4. MySQL `mysql-yIOn` — 39 streams com linha e sem Trusted

Contagens de hoje (`matriz18/mysql_unread_counts.txt`). Os 14 instrumentos foram **remedidos hoje** (colunas, celulas com valor diferente de nulo/vazio/zero, janela de datas).

### 4.1 Instrumentos abandonados (14) — 13 permanecem fora, 1 passou a ser tratado

| stream | linhas | medicao (2026-10-18) | decisao | motivo |
|---|---:|---|---|---|
| **tborcamento** | 31 | descricao, valor e datacricao 31/31; subtotal/quantidade em 2/31; 2020-10-07 a 2025-03-11 | **TRATADO** `trs_vjob__orcamento_item` (`query-bzyG`, L3) | e a **tabela de precos** de servicos (R$ 21.042,43 somados), nao colunas mortas. Decisao de 24/09 revertida: o argumento "subtotal em 2 de 31" mirava a coluna errada |
| tbclientexservico | 6.275 | 37 colunas, 29 constantes; so id/cliente/gestor/data variam; flags (`kv`, `planejamento`, textos) em 5 linhas, todas de 2023-03 | fora | andaime mensal gerado (~180 clientes por mes, **ate 2026-11**: crescimento e geracao automatica, nao uso). 5 a 7 celulas de flag em ~62.750 |
| tbnoticiasextra | 462 | 40 noticias, 154 usuarios, 2019-06-26 a 2026-10-15; **7 leituras em 2026, 2 desde setembro** | fora (candidata) | recibo de leitura sem uso recente. **Correcao:** o registro de 24/09 dizia "8 noticias"; sao 40. E a mesma familia de `trs_vjob__intranet_leitura` (video, mala, enquete, agenda), que nao inclui noticia: se alguem quiser "noticia lida", criar `trs_vjob__noticia_leitura` separada |
| tbnoticiasextra2 | 3.732 | 53 noticias, 407 usuarios, **sem data**, 3 colunas todas preenchidas | fora | recibo sem carimbo de tempo: nao responde quando; junto com a acima, 4.194 recibos (eram 4.192) |
| tbonboardingclientes | 213 | datas em 11 linhas (5,2%), 2022-09-23 a 2023-05-02 | fora | instrumento parado ha 3,5 anos; e-mails enviados em 3 a 8 linhas |
| tbonboardingclientes2 | 103 | 24 colunas, datas em **1** linha (2023-05-02 a 31) | fora | idem |
| tbetapasxclientes | 207 | 6 colunas: id, cliente, servico, area; **zero datas** | fora | v1 da relacao ja tratada na v2 (`trs_vjob__etapa_cliente`, 7.782); tabela de vinculo sem evento |
| tbetapasxclientes_onboarding | 6 | id, cliente, servico, ativo (3) | fora | vinculo de onboarding, 6 linhas |
| tbsetupcolaborador_status | 198 | 4 de 5 colunas constantes; so `usuario_id`; um unico carimbo (2026-08-04 11:18) | fora | snapshot de provisionamento sem informacao alem de uma lista de usuarios |
| vmkt_setores | 4 | 2 janelas de 11 s em 2026-01-05 | fora | piloto `vmkt_*` abandonado |
| vmkt_atividades | 24 | 8 colunas 100% preenchidas, 2026-01-05 | fora | **catalogo** do piloto (24 atividades com prazo e responsavel em texto); sem execucao |
| vmkt_atividades_clientes | 24 | `data_prevista` ate 2026-01-15; `feito` constante (zero concluidas) | fora | **zero execucao**: piloto parado em janeiro |
| checklist_diario2 | 1 | 13 colunas constantes, 2025-05-14 | fora | 1 linha |
| tbclientescronograma | 2 | id, nomecliente; 2024-03-01 | fora | 2 linhas, cadastro de teste |

### 4.2 Credencial, segredo ou ACL (11) — nao tratar

`usuario` 7 · `tbportalusuarios` 74 (`senha_hash`) · `tbpermissoes` 8 · `tbclientes_acessos` 284 · `tarefas_tb_acl_cliente_usuario` 626 · `tarefas_tbjobs_aprovacao_inicial_tokens` 74 · `advisory_tbresponsaveis_externos` 12 · `ia_provedores` 2 · `contazul_oauth_config` 1 · `contazul_oauth_conexoes` 1 · `tbrh_renovacoes` 125 (salario criptografado). Segredo e L5 (§31): fica na Raw, nunca na Trusted. A exclusao da Raw e backoffice.

### 4.3 Descarte declarado (10) — nao tratar

Lixeiras: `tbexcluidos` 4 · `tbexcluidos2` 1.435 · `deleted_tbcronograma` 26 · `deleted_tbcronogramadatas` 3.580 · `deleted_tbcronogramadatas_individual` 3.969. Backups: `backup_tbcronogramadatas_nfse_20260909` 26 · `tbescopofinal_backup_202505` 317 · `tbauditoriaclientes_bkp_20260120` 2.416 · `tbarquivosauditoria_bkp_20260120` 36. Teste: `tbescopofinalteste` 2.

### 4.4 Conta Azul (3) e 1 de 1 linha

`contazul_vendas_envios` 4 e `_historico` 1 (envios de teste, "testes hugo", zero casamento com as parcelas) · `contazul_sincronizacoes` 13 (nao fecha com as tabelas: tres cargas registram o teto de 5.000 da API para uma tabela de 403). `tarefas_tbjobs_comentarios_clientes` 1 linha: decidida em 02/10 (anexa-la a `trs_vjob__job_comentario_cliente` mexeria na `rfn_operacao__job_interacao`).

Soma: 14 + 11 + 10 + 3 + 1 = 39.
