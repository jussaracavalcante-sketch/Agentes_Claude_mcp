# `google-ads-OzfZ` (Prestex) — catálogo registrado, nenhuma tabela existe

Verificado em 2026-09-03.

## Estado

| | |
|---|---|
| Fonte | `google-ads-OzfZ`, descrição "fonte prestex" |
| Criada | 03/09 11:38 |
| Camada | `Prestex` (`vanguardamartech_prestex`) |
| Prefixo | `google_ads_prestex_` |
| Streams habilitados | 23 |
| Cron | `0 2 * * *` America/Manaus |
| Execuções | 2, **as duas falharam** (16:12 e 16:14) |
| Tabelas materializadas | **0 de 23** |

O catálogo está registrado e **nenhuma tabela existe**. Não é inconsistência: a Nekt cria a
entrada no catálogo quando a fonte é configurada, e a tabela só nasce na primeira execução que
**escreve dado**. Nenhuma execução teve sucesso, então não há o que escrever.

Confirmado consultando `vanguardamartech_prestex.google_ads_prestex_campaigns`:

> IS registered in the Nekt catalog, but Google BigQuery could not resolve it.

**Consequência imediata:** incluir a Prestex em qualquer união — a `trs_google_ads__campanha`
ou a `trs_google_ads__insight_diario` — derruba a query inteira, não só aquele ramo. A fonte só
entra nas Trusted depois de uma extração bem-sucedida.

## O erro

```
403 PERMISSION_DENIED em /v25/customers/7120717819/googleAds:search
USER_PERMISSION_DENIED — User doesn't have permission to access customer.
```

## A conta não é o problema

`7120717819` é a **Prestex**, e ela **está** na listagem do MCC da Vanguarda (uma das 85 contas).
Mais que isso: ela está ativa e gastando. Consultada hoje pela credencial do MCP do Google,
últimos 30 dias:

| Métrica | Valor |
|---|---|
| Investimento | R$ 16.320,27 |
| Impressões | 42.247 |
| Cliques | 3.116 |
| Conversões | 181 |
| Custo por conversão | R$ 90,17 |

Então: a conta existe, é da Vanguarda, tem entrega, e é legível **por uma credencial**. A que
não lê é a da Nekt.

## Por que isso é diferente do caso Unipar

As 3 fontes da Unipar falham com o mesmo código de erro, mas por outro motivo: aquelas contas
pendem do MCC do **cliente** (7749545148), não do MCC da Vanguarda, e a conta Google do OAuth da
Nekt não tem acesso a esse MCC.

A Prestex está no MCC da Vanguarda, de onde a Nekt já lê 39 outras contas sem problema. Logo o
MCC não é a barreira — o que falta é acesso **daquele usuário específico** à conta Prestex.

Detalhe que fecha o raciocínio: o `connector_config` desta fonte não tem campo
`login_customer_id`. As chaves são `oauth_credentials.refresh_token`, `customer_id`,
`lookback_window`, `start_date`, `performance_granularity` e os `enable_*`. Sem esse campo, o tap
depende de o usuário do OAuth ter acesso **direto** à conta; não há como apontar o MCC como
manager na chamada.

## O que resolve

Conceder ao usuário Google que autorizou a Nekt acesso à conta Prestex (`712-071-7819`) dentro do
Google Ads. É permissão na plataforma, não configuração na Nekt.

Vale a armadilha já registrada no `CLAUDE.md`: **validar a conta contra a API não valida a
credencial da Nekt.** A consulta acima, que trouxe R$ 16 mil de investimento, usou outra
credencial — ela prova que a conta está viva, não que a Nekt vai conseguir ler.

## Dois pontos que agravam

- **`settings_max_consecutive_failures: 3`** e já são 2 falhas. Na execução das 02:00 Manaus de
  amanhã a Nekt para de executar a fonte sozinha, e some até o sintoma.
- **`subscribed_to_alerts: false`** — ninguém é avisado. Mesmo caso da `supabase-x0tz`, que ficou
  duas noites falhando em silêncio.
