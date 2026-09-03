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

## Impacto a jusante

O domínio Operação está parado, e já estava antes desta falha:

| Tabela | Última carga |
|---|---|
| `trs_vjob__job` | 31/08 16:37 UTC |
| `rfn_operacao__job` | 31/08 16:37 UTC |

Nada quebrou — as tabelas continuam consistentes, só não recebem dado novo. O que precisa
de atenção é que a Trusted do VJOB não roda desde 31/08, o que é um segundo problema,
separado da credencial, e ainda não investigado.
