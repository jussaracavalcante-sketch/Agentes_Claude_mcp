# Correção na skill `contexto-head-ia-vanguarda` — a afirmação sobre o Linear

**Medido em 2026-09-23.** A skill afirma, em dois lugares, que o Linear está vazio.
**Está errado** — e a afirmação volta a cada sessão nova, porque a skill é carregada
antes de qualquer medição.

**Não dá para corrigir daqui.** A skill vive em
`/root/.claude/skills/synced/…/contexto-head-ia-vanguarda/SKILL.md`, sincronizada da sua
biblioteca de skills. Editar a cópia local vale só para esta sessão e nem aparece para
você. A correção é na skill da sua conta — abaixo está o texto exato.

## O que medir mostrou

| | |
|---|---:|
| issues | **230** |
| identificadores distintos | 230 |
| projetos | 8 |
| concluídas | 67 |
| **último criado** | **2026-07-28 16:19** |
| **último atualizado** | **2026-08-01 04:25** |

E a extração está **sã**: a fonte `linear-byrt` tem **29 execuções, todas com sucesso**,
a última **hoje às 04:20**. Sete streams habilitados, todos INCREMENTAL por `updatedAt`.

**Então as duas leituras simples estão erradas.** "Vazio" é falso — tem 230 issues. "Fonte
viva" também é falso — **nada foi criado depois de 28/07 e nada atualizado depois de
01/08**, apesar de a extração rodar todo dia e funcionar. O Linear não está quebrado: ele
parou de ser usado, em 1º de agosto.

## As duas linhas para trocar

**Linha 40** — hoje:

```
**Linear está vazio** — não é fonte, não insistir.
```

Trocar por:

```
**Linear tem 230 issues, mas parou em 01/08/2026** — a fonte `linear-byrt` extrai todo
dia às 03:20 e as 29 execuções deram certo; o que não há é atividade nova. Serve para
histórico até julho, não para acompanhar trabalho corrente. A issue **não carrega
cliente**: `project.name` é projeto interno (SGQ v4.0, Vanguarda BI Hub v2, Fechamento
Contábil…), e **85% não têm responsável**.
```

**Linha 113** — hoje:

```
Google Drive, Jira/Confluence, Notion, Nekt, Semrush, Lovable, Supabase, Linear (vazio).
```

Trocar por:

```
Google Drive, Jira/Confluence, Notion, Nekt, Semrush, Lovable, Supabase, Linear (230
issues, sem atividade desde 01/08/2026).
```

## Por que isso importa mais do que parece

A skill é o contexto que abre toda sessão de trabalho. Uma afirmação errada ali não é um
detalhe de documentação: ela **impede a pergunta**. "Não é fonte, não insistir" fecha a
porta antes de alguém olhar — e foi exatamente o que aconteceu até 21/09.

Tratado na `trs_linear__issue` (`query-lhYJ`), que já declara as limitações reais:
`cycle` 100% NULL, `estimate` 0%, `archivedAt` 100% NULL, uma única equipe (VAN) e 196
das 230 issues sem responsável.
