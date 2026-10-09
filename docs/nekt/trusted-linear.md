# Trusted do Linear — `trs_linear__issue`

**Publicada em 2026-09-21** · `query-lhYJ` · camada `Trusted`, folder `linear`
· gatilho: evento em `linear-byrt` · alerta de falha **ligado**.

Arquivo: `sql/trusted/trs_linear__issue.sql`

## Por que essa fonte estava invisível

A skill de contexto afirmava "**Linear está vazio** — não é fonte, não insistir".
É falso: são **230 issues**, 7 streams habilitados, 24 execuções bem-sucedidas.

O que produziu a afirmação foi a armadilha de prefixo, a mesma já registrada no
Google Ads: o prefixo é `linear_vanguarda` **colado ao nome do stream**, então a
tabela de issues é `linear_vanguardaissues` — não `linear_issues`. Procurar pelo
nome que faria sentido devolve `not_in_catalog`, que se lê como ausência de dado.

## Grão e unicidade — medido em 2026-09-21

| medida | valor |
|---|---|
| linhas | 230 |
| `id` distintos | 230 |
| `identifier` distintos (VAN-nnn) | 230 |
| `_payload_hash` distintos | 230 |

Unicidade provada nas **duas** chaves. Grão = issue.
Janela: criação de 01/04/2026 a 28/07/2026; último `updatedAt` 01/08/2026 01:25 local.

A query validada reproduziu, uma a uma, todas as contagens feitas direto no cru:
67 concluídas · 13 canceladas · 72 subtarefas · 196 sem responsável · 26 sem projeto
· 83 com prazo · 88 comentários · 49 rótulos · média de 1,9 dia entre criação e conclusão.

## Fuso: dois tratamentos na mesma tabela

Foi medido coluna a coluna, e as colunas não se comportam igual.

**Instantes de verdade, em UTC** — `createdAt` (226 de 230 com hora ≠ 00),
`updatedAt`, `startedAt`, `completedAt` (64 de 67), `canceledAt`.
Convertem com `DATETIME(ts,'America/Sao_Paulo')`, o padrão da família Facebook Ads.
Nunca `TIMESTAMP(dt,'America/Sao_Paulo')`, que não converte — soma 3 horas a um dado
que já é local e custou seis tabelas do iClips entre 21/08 e 15/09/2026.

**Data disfarçada de TIMESTAMP** — `dueDate`. Das 83 linhas preenchidas, **zero** têm
hora ≠ 00:00:00 e **todas as 83** mudariam de dia com `DATE(dueDate,'America/Sao_Paulo')`,
porque meia-noite UTC é 21h do dia anterior em São Paulo. Por isso `DATE(dueDate)` puro.

Segundo caso confirmado dessa armadilha na base — o primeiro foi
`supabase_silver_pi_insercao`. Ali ela atingia 1.968 de 3.348 linhas; aqui atinge 100%.

## O que ficou fora, e por quê

**E-mail.** O stream traz `assignee.email`, `creator.email`, `subscribers[].email` e
`comments[].user.email`. A Trusted emite id, nome e `displayName` — nunca o endereço.
Precedente na casa: a descrição da camada `Gestão de Projetos do iClips` manda descartar
`cpf` e `valorHora` na leitura.

**Array.** `rotulos` sai como texto separado por `" | "` em vez de `ARRAY<STRING>`, porque
o wrapper da Nekt exporta via `EXPORT DATA` e qualquer `SELECT *` sobre coluna repetida
quebra com *"Only simple types may be exported as CSV"* — era exatamente o que impedia ler
o stream cru.

**Corpo do comentário.** Texto livre é assunto de camada semântica, não de Trusted. Ficam
`qtd_comentarios` e `ultimo_comentario_em`.

**Campos mortos.** `cycle` 100% NULL · `estimate` 0% preenchido · `archivedAt` 100% NULL ·
`previousIdentifiers` 100% vazio · `customerTicketCount` zero em todas as linhas.
`boardOrder` e `sortOrder` são ordenação de tela, não negócio.

## Limitações declaradas — não contorne

1. Não há indicador de esforço nesta fonte (`estimate` vazio) nem de ciclo/sprint (`cycle` vazio).
2. **85% das issues não têm responsável.** Indicador por responsável cobre 15% da base;
   a cobertura tem de vir junto com o número. A flag `flag_sem_responsavel` existe para isso.
3. **Existe uma única equipe** (`VAN`). `team` fica na tabela para o dia em que houver a segunda.
4. **A issue não carrega cliente.** `project.name` é projeto interno da agência — 9 projetos:
   SGQ v4.0 (73 issues), Vanguarda BI Hub v2 (38), App01 E-mail Marketing (32),
   Saneamento iClips (21), Fechamento Contábil 02/2026 (20), APP02 Mídia Performance (13),
   Reestruturação FCx_ICLIPS (6), Inteligência Competitiva (1), sem projeto (26).
   Não ligar a `rfn_cadastro__cliente`: casaria por rótulo e produziria cliente falso.
5. **Não há histórico de mudança de estado.** `dias_ate_conclusao` é a distância entre os dois
   únicos eventos dateáveis (criação e conclusão), **não** lead time de processo.
6. Agrupar por `estado_tipo` (5 valores canônicos da API: backlog 77, completed 67,
   unstarted 61, canceled 13, started 12), nunca por `estado_rotulo`, que a equipe renomeia
   no board.
7. `prioridade = 0` **não** é ausência: 14 issues estão explicitamente em "No priority".
   Distribuição: Urgent 60, High 102, Medium 49, Low 5, No priority 14.

## Pendente

- **Corrigir a skill `contexto-head-ia-vanguarda`**, que ainda diz "Linear está vazio" em
  duas linhas. Ela é sincronizada de fora do repositório, então a correção não sai daqui —
  enquanto não sair, a afirmação volta a cada sessão nova. A correção está registrada no
  `CLAUDE.md`, que prevalece.
- Os outros 6 streams (`projects`, `cycles`, `teams`, `users`, `customers`, `issue_labels`)
  não foram tratados. `cycles` e `users` provavelmente não valem tabela: o ciclo não é
  referenciado por nenhuma issue e o usuário só apareceria para sustentar um indicador que
  cobre 15% da base.
