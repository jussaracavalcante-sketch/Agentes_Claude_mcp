# `supabase-x0tz` — falha de conexão, 2026-09-03

## Os dois erros não são o mesmo erro

O erro que apareceu na tela e o erro que a Nekt registrou são diferentes, e essa é a
parte importante do diagnóstico. Os dois contra o mesmo host,
`aws-1-sa-east-1.pooler.supabase.com:5432`:

| Onde | Mensagem | O que significa |
|---|---|---|
| Tela | `FATAL: (ENOIDENTIFIER) no tenant identifier provided (external_id or sni_hostname required)` | O pooler **não descobriu qual projeto** é o alvo. Erro de roteamento. |
| Log da Nekt, execução de 03/09 01:00 | `FATAL: password authentication failed for user "postgres"` | O pooler **descobriu o projeto** e rejeitou a senha. Erro de credencial. |

São dois estágios da mesma conexão. No host compartilhado do Supavisor, o usuário
precisa carregar o identificador do projeto — `postgres.<project_ref>`, não `postgres`.
Sem o sufixo, o pooler não sabe para onde rotear e devolve `ENOIDENTIFIER`. Com o
sufixo, ele roteia e aí valida a senha.

O que confunde: o Supavisor reporta o erro de senha **sem** o sufixo, como
`user "postgres"`. Então a mensagem de senha rejeitada não é evidência de que o usuário
está errado — pelo contrário, ela prova que o tenant foi resolvido.

Conclusão: o `ENOIDENTIFIER` da tela veio de uma tentativa em que o usuário foi digitado
sem o `.<project_ref>`. O que está gravado na Nekt tem o sufixo (chegou na etapa de
senha) e a **senha é que não serve mais**.

## Confirmado ao vivo

`validate_source_connector_config` na fonte publicada devolveu `status: "failed"`, sem
streams. A credencial gravada hoje não conecta — não é log velho.

## Quando quebrou

| Execução (cron `0 0 * * *` Manaus) | Resultado |
|---|---|
| 01/09 01:00 → 03:27 | sucesso, 2h27 de extração |
| 02/09 01:00 | falha em 1min46 |
| 03/09 01:00 | falha em 1min30 |

Quebrou entre 01/09 03:27 e 02/09 01:00. A falha é imediata (menos de dois minutos, contra
2h27 de uma execução real), o que é a assinatura de erro de conexão, não de extração.

A configuração da fonte não foi alterada nesse intervalo — o último `updated_at` é
31/08 14:32, que foi a desabilitação dos streams de `auth` e `vault`. Ou seja: **o host
sempre foi `aws-1`, e funcionava**. Não é migração de pooler. É a senha que mudou do lado
do Supabase.

## Não é problema da Nekt nem da rede

A outra fonte Supabase, `supabase-fEvu`, rodou **hoje 03/09 às 03:45 com sucesso**, como
em todos os dias anteriores. O problema é específico desta credencial.

## O que fazer

1. **Conferir se a senha do banco foi rotacionada** entre 01 e 02/09. É a hipótese que
   sobra depois de descartar host, config e rede.
2. **Reentrar a senha na interface web da Nekt.** Não passa pelo MCP: o `get_setup_link`
   só aceita fonte em rascunho (*"Setup links can only be generated for draft sources"*),
   e credencial de fonte viva se edita só na web. Credencial não passa por chat.
3. **Ao reentrar, o usuário tem de ser `postgres.<project_ref>`** — se ficar `postgres`,
   volta o `ENOIDENTIFIER` e a impressão errada de que a senha está errada de novo.

## Dois pontos que agravaram

- **`subscribed_to_alerts: false`.** Ninguém foi avisado. A fonte falhou duas noites em
  silêncio. Ligar o alerta é mudança de comportamento em fonte publicada, então fica como
  recomendação, não como algo já feito.
- **`settings_max_consecutive_failures: 3`.** São duas falhas. Na terceira — a execução de
  04/09 01:00 Manaus — a Nekt para de executar a fonte sozinha, e aí some até o sintoma.

## Impacto a jusante — e uma leitura errada minha

Durante a falha eu registrei aqui que "a Trusted do VJOB não roda desde 31/08". **Isso estava
errado**, e o erro foi de leitura, não de dado.

Eu usei `MAX(_extraido_at)` da `trs_vjob__job` como se fosse o horário em que a transformação
rodou. Não é. Na `query-4XbY` a coluna é `fetched_at AS _extraido_at` — o carimbo de quando a
**fonte** buscou a linha, herdado da Raw. Nas tabelas de Google Ads o `_extraido_at` é da carga
da própria transformação, e eu transportei essa expectativa para cá sem conferir.

O correto: a `query-4XbY` **nunca falhou**. Nove execuções, nove sucessos, todas por evento na
`supabase-x0tz`. A de hoje rodou às 14:38:21, 25 segundos depois de a fonte terminar às
14:37:56.

**Como conferir se uma transformação rodou:** `list_pipeline_runs(pipeline_slug=...)`. O
`_extraido_at` só serve para isso quando a própria query o define; quando ele vem de
`fetched_at`, responde outra pergunta.

## O que de fato merece atenção no VJOB

A extração está saudável e o dado não cresce:

| Tabela | Linhas | Registro mais recente |
|---|---|---|
| `raw.supabase_bronze_vjob__tbjobs` | 1.354 | cadastro em **24/08 11:15** |
| `raw.supabase_bronze_vjob__tbjobsgeral` | 160 | cadastro em **05/06** |
| `trusted.trs_vjob__job` | 1.514 | — |

1.354 + 160 = 1.514, exatamente o total da Trusted: a fidelidade está certa. As três tabelas
Raw carregam o mesmo `fetched_at` (13:11:03 de hoje), o que confirma FULL_SYNC carimbando tudo
de uma vez.

Ou seja: **nenhum job novo foi cadastrado no VJOB desde 24/08**, e no `tbjobsgeral` desde
junho. O pipeline entrega todo dia o mesmo conteúdo. Se a operação continua registrando job na
intranet, o problema é de origem — escopo do stream ou tabela errada — e não da Nekt. Se a
operação de fato parou de usar o VJOB, não há nada a corrigir aqui, e o dado está certo.

Registrado como observação: `fetched_at` de hoje é 13:11:03 UTC, mas a execução que o escreveu
rodou entre 15:06 e 17:37 UTC. O carimbo cai fora da janela quando lido como UTC e dentro dela
quando lido como horário local (-03), o que sugere hora local gravada com rótulo de UTC. Um
ponto só não fecha o caso, e não afeta o tratamento — todas as linhas dividem o mesmo valor e
não há duplicata para desempatar. Fica anotado, não vira ajuste.
