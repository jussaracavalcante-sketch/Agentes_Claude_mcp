# Saúde das fontes e backlog de tratamento — 2026-09-18

Medido pelo histórico de execução (`list_pipeline_runs`) e pela entrega real no
warehouse, nunca por `status`/`active` — que descrevem o deploy, não a execução.

## 1. Inventário

97 fontes: 92 ativas, 5 inativas.

| Conector | Total | Ativas | Inativas | Entregando | Último dado |
|---|---:|---:|---:|---:|---|
| google-ads | 45 | 43 | 2 | 36 | 2026-09-14 |
| rd-station | 34 | 33 | 1 | 30 | 2026-09-18 |
| facebook-ads | 7 | 7 | 0 | 7 | 2026-09-15 |
| supabase | 3 | 3 | 0 | 3 | 2026-09-18 |
| rest-api | 3 | 2 | 1 | 2 | 2026-09-18 |
| gmail | 2 | 2 | 0 | 2 | 2026-09-18 |
| github | 1 | 1 | 0 | 1 | 2026-09-18 |
| linear | 1 | 1 | 0 | 1 | 2026-09-18 |
| semrush | 1 | 0 | 1 | 0 | — |
| **Total** | **97** | **92** | **5** | **82** | |

**Inativas:** `semrush-OnLY` (chave rejeitada pela API), `rd-station-YLIU` (CDL),
`rest-api-Sn8O` (Qulture rocks), `google-ads-H3hJ` e `google-ads-4YJU` (rascunho,
`last_run: null` — nunca executaram).

## 2. Cadência: mídia paga é SEMANAL

Google Ads e Facebook Ads passaram de diário para **semanal, às terças**, por
volta de 2026-09-04. Verificado em `google-ads-cwt3` (15/09, 08/09, 03/09, 02/09,
01/09 — o salto de 04/09 para 08/09) e `facebook-ads-kQ2S` (15/09, 08/09, 04/09,
03/09). As Trusted dessas famílias são event-triggered, então seguem o mesmo ritmo:
`query-tL4g` rodou 15/09 13:48, `query-QXqC` 15/09 07:48.

**Consequência:** em 18/09 o dado de mídia tem 3-4 dias de atraso por desenho, não
por falha. Próxima carga: terça 22/09. Ler atraso de mídia paga como incidente é
erro de leitura.

RD Station, Supabase, iClips, GitHub, Linear e Gmail rodam **diários** e estavam em
dia em 18/09.

## 3. Contas Google Ads sem entrega há mais de 7 dias

11 fontes. Todas com `_extraido_at` = 2026-09-15, ou seja, **a extração roda; a conta
é que não veicula**. Não é falha técnica.

| Fonte | Último dia com entrega |
|---|---|
| google-ads-AMd2 | 2025-07-16 |
| google-ads-PmFB | 2025-08-30 |
| google-ads-fwxw | 2025-11-26 |
| google-ads-x20o | 2026-03-27 |
| google-ads-RCRU | 2026-06-05 |
| google-ads-cFrH | 2026-07-22 |
| google-ads-PsES | 2026-07-23 |
| google-ads-Jl1R | 2026-07-30 |
| google-ads-QuKh | 2026-08-22 |
| google-ads-URNQ | 2026-08-24 |
| google-ads-C4Aq | 2026-09-11 |

## 4. Tratamento: 58 transformações ativas

51 Trusted + 7 Refined (1 aposentada, `query-ir9k`).

| Família | Transformações | Fontes cobertas |
|---|---:|---|
| Google Ads | 8 | 42 das 45 |
| Facebook Ads | 22 | 7 das 7 |
| RD Station | 10 | 30 das 34 |
| iClips | 7 + 1 notebook | `rest-api-73hk` |
| VJOB | 2 | `supabase-fEvu` |
| PI | 1 | `supabase-x0tz` |
| Refined | 7 | — |

Gatilho: 5 por cron, 53 por evento da fonte a montante. Nenhuma manual.

## 5. Backlog — 15 fontes sem Trusted

### Ativas e saudáveis, faltando o estágio de tratamento (6)

| Fonte | O que é | Execução |
|---|---|---|
| `supabase-3gKz` | VJOB II | 1ª run 18/09 12:19→12:53, sucesso |
| `rest-api-xk4P` | iClips — cadastros de apoio | diária, 30 runs, sucesso |
| `gmail-cF2Q` | workspace | diária, 18 runs |
| `gmail-c3ku` | contato | semanal, 3 runs |
| `github-s0VO` | repositórios | diária, 26 runs |
| `linear-byrt` | issues/projetos | diária, 24 runs |

Todas são sistema interno: destino é a camada `Raw`, folder = sistema de origem,
prefixo Trusted `trs_<sistema>__<entidade>` conforme ADR-0009.

### Ativas com problema de configuração (4)

- **`google-ads-OzfZ` (Prestex)** — única execução bem-sucedida em 08/09, 5 runs no
  total, sem cadência desde então. É a única fonte ativa que não atualiza. Mexer no
  cron de fonte publicada exige pedido explícito (R-002).
- **`rd-station-socq` (AMZ Imports)** — catalogada, não materializada. Já documentado
  no CLAUDE.md: entrada no catálogo não é tabela existente.
- **`rd-station-1eaJ` e `rd-station-bjQx`** — as duas descritas como "BD - RD STATION -
  VANGUARDA". A `bjQx` está com `output_folder: null`. Duplicidade aparente.

### Inativas, bloqueadas por terceiro (5)

`semrush-OnLY`, `rd-station-YLIU`, `rest-api-Sn8O`, `google-ads-H3hJ`, `google-ads-4YJU`.

## 6. Pendências datadas

| Quando | O quê |
|---|---|
| 19/09 madrugada | `query-iX2P` e `query-SguJ` disparam pela 1ª vez — são event-trigger no `supabase-x0tz` (01:00), criadas depois da carga de 18/09 |
| 22/09 (terça) | 1ª execução das 7 Trusted de Google Ads já com as 42 fontes, Unipar incluída |

## 7. O que NÃO foi feito, e por quê

- Não alterei o cron do `google-ads-OzfZ`: R-002 protege fonte publicada.
- Não excluí `rd-station-1eaJ`/`bjQx`: exclusão exige a conferência prévia da seção
  "Antes de excluir qualquer coisa" — repontar fonte não move dado.
- Não rodei nenhuma pipeline à mão: a prova é a execução agendada.

---

## Verificação de 2026-09-21 (segunda)

**Cadeia de PI viva.** `query-iX2P` e `query-SguJ` dispararam nas três madrugadas
seguintes (19, 20 e 21/09), todas com sucesso, pelo evento do `supabase-x0tz`.
Carga de hoje às 03:32 (Manaus).

`trs_pi__insercao` reproduz a validação de 18/09 sem desvio: 3.348 PIs, 3.348
`id_pi` distintos, R$ 47.083.182,87, 228 cancelados.

`rfn_midia_off__pi` — 3.319 PIs (os 29 de `Internet` saem pela regra 1) e **zero
"sem causa identificada"**:

| motivo_sem_acompanhamento | PIs | Valor |
|---|---:|---:|
| coberto | 3.063 | R$ 44.601.441,11 |
| cancelado (a view exclui, corretamente) | 224 | R$ 2.072.158,35 |
| tipo de mídia fora da view do Supabase | 25 | R$ 253.598,39 |
| cliente de teste ou interno | 5 | R$ 30.744,00 |
| sem data de início | 2 | R$ 0,00 |

**Correção neste documento:** a cadência semanal de mídia paga é **terça**, não
segunda. 01/09, 08/09 e 15/09 são todas terças. A data da próxima carga (22/09)
estava certa; o nome do dia estava errado.
