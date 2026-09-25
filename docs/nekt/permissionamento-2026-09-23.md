# Permissionamento na Nekt — o que está concedido hoje

**Medido em 2026-09-23, só leitura.** Nada foi alterado: conceder e revogar acesso muda o
que pessoas reais enxergam, e isso é decisão sua, não default técnico.

## O que existe

Três grupos. **Dois foram criados hoje, às 11:17 e 11:18** — o permissionamento começou a
ser montado antes desta sessão tratar de classificação.

| grupo | descrição | pessoas |
|---|---|---:|
| `All` | (automático, todo mundo) | 9 |
| `Administrador_` | "visão geral do data lake" | 3 |
| `Usuário_comum` | "apenas_google ADS-facebook_ADS" | 5 |

## Os três achados

### 1. `Usuário_comum` não tem concessão nenhuma

O grupo existe, tem 5 pessoas e a descrição diz **"apenas google ADS - facebook ADS"** —
mas **zero linhas de permissão apontam para ele**. A intenção está escrita no nome; a
concessão não foi feita. Na prática essas 5 pessoas não alcançam nem Google Ads nem
Facebook Ads por esse caminho.

### 2. `Administrador_` tem `manager` em 16 camadas, incluindo as três do medalhão

Raw, Trusted e Refined estão lá, junto com `supabase_vjob_2`, Prestex, Gestão de Projetos
do iClips e as camadas de Facebook dos clientes. É coerente com "visão geral do data lake"
— e significa que **as tabelas L3 e L4 publicadas hoje são, por concessão, acessíveis só a
essas 3 pessoas**. Essa é a postura certa para margem e folha.

### 3. A única concessão ao grupo `All` é em "Sample data"

`manager` para os 9, na camada `Sample data`, desde 11/08/2026 — data de criação do
workspace, sem `granted_by`. É dado de exemplo, não é risco.

Fora isso há **3 concessões individuais** a uma mesma pessoa (id 3701), todas `viewer`:
`RD_marketing` e duas camadas que **não aparecem em `list_layers`** (`cb68d0bd…` e
`2732d2c6…`). Pela armadilha já registrada, `list_layers` omite as `_g_ads`, então o mais
provável é que sejam camadas de Google Ads — **mas isso é inferência, não medição.**

## A ressalva que decide tudo

A descrição da camada **"Gestão de Projetos do iClips"** já registra, desde 17/09:

> *"isso só significa acesso restrito nos planos Growth ou Custom. **No plano Starter a
> permissão em nível de dado não existe e TODO membro do workspace tem nível Manager por
> padrão, concessão ou não.** Conferir o plano em Workspace Settings > Billing antes de
> tratar esta camada como protegida."*

**O plano não é verificável pelo MCP.** Então o quadro acima descreve as concessões
registradas, e não necessariamente o acesso efetivo. Se o workspace estiver em Starter,
os 9 membros têm Manager em tudo — inclusive na Trusted que carrega a folha nominal
(4.944 linhas, 277 CPFs, R$ 15,7 mi) e na Refined que carrega a margem por cliente.

**Conferir o plano é o primeiro passo, e é o único que muda a leitura.**

## O que fica para você decidir

1. **Conferir o plano** em Workspace Settings › Billing. Sem isso, "restrito" é hipótese.
2. **Conceder ao `Usuário_comum` o que o nome dele promete** — as camadas de Google Ads e
   Facebook Ads. Não fiz porque as camadas `_g_ads` não aparecem no `list_layers` e eu
   erraria a lista para mais ou para menos.
3. **Decidir sobre as camadas com dado pessoal**: `Gestão de Projetos do iClips` (104 CPFs
   e 84 valores-hora no payload), `Raw` (senha, token, prontuário de RH) e `Trusted`
   (folha nominal). Hoje as três estão concedidas ao `Administrador_` inteiro, sem
   separação entre "ver o medalhão" e "ver dado pessoal".

Referência: `docs/nekt/classificacao` na camada semântica
(`29eca9d5-010d-419b-8efa-eebbe8c81ba4`) e §30 da arquitetura.
