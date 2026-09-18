# Varredura profunda das camadas — 2026-09-03

Levantamento de tudo que está no ar e do que está sobrando. Números medidos hoje, não estimados.

---

## Panorama

| | Total | Ativas não-rascunho | Observação |
|---|---|---|---|
| **Fontes** | 95 + 3 rascunhos | 87 | 8 inativas |
| **Transformações** | 40 | 39 | **8 órfãs** |
| **Camadas** | 20+ | — | listagem do MCP é incompleta |

**Um acerto que vale registrar:** os 91 crons estão **todos** em `America/Manaus`. A convenção
operacional está sendo respeitada sem exceção.

### Fontes por conector

| Conector | Total | Situação |
|---|---|---|
| Google Ads | 45 | 39 na união + Prestex pausada + 3 Unipar inativas + 2 rascunhos |
| RD Station | 34 | 33 ativas (**2 duplicadas**) + 1 rascunho |
| Facebook Ads | 7 | 11 contas com dado; 4 fontes retiradas de propósito |
| Supabase | 2 | x0tz e o rascunho m4aV |
| REST API | 2 | 1 inativa (bug da Nekt) |
| Gmail, Semrush, Linear, GitHub | 5 | Semrush inativa (chave inválida) |

---

## O que está desperdiçando recurso

### 1. Oito transformações órfãs — nunca disparam

**Resolvido em 2026-09-03:** as 4 fontes foram retiradas de propósito. Confirmado pela Jussara.
Não é incidente, não há cliente congelado por engano e não há o que restaurar. O que sobra é
resíduo de configuração — as 8 transformações continuam cadastradas apontando para fontes que
não existem. Ficam registradas aqui; remoção não é urgente e não se faz sem pedido (R-002).

Apontam por evento para fontes que **não existem mais**. Não falham: simplesmente nunca são
acionadas. Nenhum alerta dispara porque não há execução para falhar.

| Transformação | Aponta para | Cliente |
|---|---|---|
| `query-0S73`, `query-U0xi` | `facebook-ads-uJNk` | Pátio Gourmet |
| `query-6By7`, `query-ktuL` | `facebook-ads-vVCz` | Nova Era BV |
| `query-iUZG`, `query-7WB2` | `facebook-ads-5HRd` | Nova Era PVH |
| `query-Qhmq`, `query-IEGX` | `facebook-ads-MhGm` | Nova Era MAO |

As tabelas de Pátio Gourmet (última carga em **30/08**) e das três Nova Era (**31/08**)
somam **45.019 linhas** que não recebem mais nada — por decisão, não por falha.

O mecanismo, esse sim, continua valendo como aprendizado: **transformação com trigger de evento
sobre fonte inexistente é invisível.** Não roda, não falha, não alerta, e a tabela segue
respondendo consulta com dado velho. Se um dia uma fonte sumir por engano, é assim que vai
parecer — igual a esta, que foi de propósito.

### 2. Duas fontes de RD Station duplicadas, rodando todo dia

| Fonte | Cron | Descrição |
|---|---|---|
| `rd-station-1eaJ` | 10:20 | BD - RD STATION - VANGUARDA |
| `rd-station-bjQx` | 10:30 | BD - RD STATION - VANGUARDA |
| `rd-station-pDLk` | 11:20 | RD_clientes_vanguarda |

Confirmado em 01/09: o conteúdo de `1eaJ` e `bjQx` está contido em `pDLk`. As três rodam
diariamente; duas não acrescentam nada.

### 3. Prestex — 23 tabelas no catálogo, nenhuma existe

Fonte pausada hoje por falta de permissão. As entradas ficam no catálogo. **Não incluir em
nenhuma união** antes de uma extração bem-sucedida: referência a tabela catalogada mas não
materializada derruba a query inteira.

### 4. Três rascunhos que nunca rodaram

`rd-station-YLIU` (CDL), `google-ads-H3hJ` (Pneu Forte Varejo), `google-ads-4YJU`
(Dr. Cabral conta 2). Não consomem crédito, mas poluem o inventário e podem ser confundidos
com fontes reais.

---

## Camada Raw — o que não deveria estar lá

### Credenciais ainda materializadas

Os streams de `auth` e `vault` foram desabilitados em 31/08. **Desabilitar não apaga.** As
tabelas continuam no warehouse com o conteúdo daquela data:

| Tabela | Linhas |
|---|---|
| `supabase_auth_users` | 20 |
| `supabase_auth_refresh_tokens` | 34 |
| `supabase_auth_identities` | 20 |
| `supabase_auth_sessions` | 9 |

Os números são **idênticos** aos medidos em 31/08, o que confirma que a desabilitação funcionou
— o dado está congelado, não crescendo. Mas continua acessível a quem tem a camada.

A exclusão é backoffice: não há endpoint na API. Enquanto não for feita, são tokens de sessão e
identidades de 20 usuários parados no warehouse.

### Ruído de schema interno

Sobraram habilitados os streams de `information_schema`, `storage`, `realtime`, `extensions` e
`cron`. Amostra de duas tabelas: 453 + 323 linhas. Sem risco, mas é volume e crédito gastos
todo dia para trazer metadado do Postgres.

---

## Camada Trusted — fragmentada em dois padrões

Convivem duas arquiteturas opostas:

**Consolidada (o padrão bom)** — uma tabela por sistema, todas as contas dentro, distinguidas
por `id_conta`:

| Tabela | Linhas | Contas |
|---|---|---|
| `trs_google_ads__insight_diario` | 75.552 | 36 com dado |
| `trs_google_ads__campanha` | 816 | 38 |
| `trs_google_ads__conta` | 85 | dimensão do MCC |
| `trs_rd_station__conversao` | 31.640 | 29 clientes |
| `trs_rd_station__contato` | 23.861 | 29 clientes |
| `trs_vjob__job` | 1.514 | — |

**Por cliente (o padrão antigo)** — o Facebook Ads tem **10 tabelas separadas**, uma por
cliente, cada uma com sua própria query:

| Cliente | Linhas |
|---|---|
| Braga (2 contas) | 62.521 |
| Colmeia | 23.133 |
| Acesso Saúde | 20.401 |
| Pátio Gourmet | 15.917 |
| Nova Era BV | 13.578 |
| PMZ Grupo Loja | 13.187 |
| Construí | 10.489 |
| Nova Era MAO | 9.239 |
| Best Car | 7.161 |
| Nova Era PVH | 6.285 |
| **Total** | **181.911** |

São cópia 1:1 da Raw (182.911 linhas). Consolidar sem aposentar as 10 criaria uma **terceira**
cópia dos mesmos dados.

O RD Station tem situação parecida em menor escala: 8 queries legadas por cliente, pendentes de
comparação número a número antes de aposentar.

---

## Camada Refined — pequena e coerente

| Tabela | Linhas | Domínio |
|---|---|---|
| `rfn_midia__desempenho_diario` | 42.888 | Mídia |
| `rfn_marketing__conversao` | 31.640 | Marketing |
| `rfn_operacao__job` | 1.514 | Operação |

Todas carregadas hoje. É a camada mais saudável — e a menor, porque só o Google Ads chegou até
aqui pelo lado da mídia.

---

## Onde as camadas NÃO estão otimizadas

Em ordem de impacto:

1. **Facebook fragmentado em 10 tabelas.** Impede a Refined de representar o investimento total
   do cliente, e cada nova conta exige uma query nova.
2. **Duas fontes de RD duplicadas** rodando diariamente sem acrescentar nada.
3. **Credenciais materializadas na Raw** desde 31/08, esperando exclusão por backoffice.
4. **Ruído de `information_schema` e afins** sendo extraído todo dia.
5. **Alertas desligados na maioria das fontes.** Foi por isso que a `supabase-x0tz` falhou duas
   noites em silêncio sem ninguém notar.
6. **8 transformações órfãs** de fontes retiradas de propósito — resíduo, não incidente.

## O que já está bem

- Fuso único em todos os 91 crons.
- Google Ads e RD Station consolidados, com identidade resolvida por chave e não por rótulo.
- Refined com regras de negócio documentadas e validação numérica registrada.
- Investimento fechando ao micro entre Trusted e Refined.
