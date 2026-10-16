# Tarefa VJOB #1749 — análise de créditos da Nekt contra o limite de 9.000 por mês

Posição de 15/10/2026. Somente leitura: cadência de cada fonte e transformação, lida na Nekt (238 fontes não arquivadas e 215 transformações), propagada pelos gatilhos de evento.

## O que é medido e o que é suposto

- **Suposição central: 1 crédito por execução de pipeline**, de fonte ou de transformação. Vem dos registros desta casa (`pendencias.md`: "9 fontes × ~30 execuções/mês = ~270 créditos"; `camadas-google-ads.md`: "run de sucesso com zero linhas ainda consome 1 crédito"; `diario-2026-08-31.md`: "1 crédito em vez de 5"). **Não foi confirmada contra a cobrança**: o MCP da Nekt não expõe consumo nem saldo. A conferência é em Workspace Settings › Billing, comparando o consumido de 01 a 15/10 com os ~3.800 estimados abaixo mais as execuções manuais.
- **Validação parcial da cadência:** o notebook do iClips rodou 6 vezes por dia em 12 a 15/10 e a `trs_iclips__projeto` (`query-8nEt`) rodou atrás de cada execução bem-sucedida, como o modelo prevê. Nos três disparos de 13/10 em que o notebook falhou, a cadeia não rodou.
- **Fora da conta:** execuções manuais, reexecuções e a cadência das 25 fontes de Páginas e Instagram (hoje manuais, zero agendado).

## Consumo estimado em regime (por mês)

| | execuções/mês | % do limite |
|---|---:|---:|
| **Total** | **~7.600** | **84%** |
| Transformações (SQL e notebook) | ~5.700 | 63% |
| Fontes | ~1.900 | 21% |

Por família (fonte raiz mais toda a cadeia de transformações que dispara atrás dela):

| família | execuções/mês | % do total |
|---|---:|---:|
| **iClips: notebook a cada 4h + Trusted, Refined e suítes** | ~3.300 | 43% |
| RD Station: 32 fontes diárias e 20 semanais + Trusted de RD | ~1.300 | 17% |
| Supabase `x0tz` (diária): Conexa, PI, Conta Azul, financeiro | ~840 | 11% |
| Meta Ads: 84 fontes semanais (terça) + Trusted das 7 antigas | ~470 | 6% |
| Google Ads (terça): 41 fontes + mídia | ~420 | 5% |
| MySQL do VJOB (domingo) e cadeia | ~400 | 5% |
| Transformações com cron próprio (RD 13:10/13:20, `query-jHEX`, `query-HCcd`) e cadeias | ~365 | 5% |
| Gmail, Linear, iClips de apoio, Supabase `3gKz`/`fEvu`, webhook, GitHub | ~500 | 7% |

Uma passada completa custa: **~93** (MySQL do VJOB, fonte mais as 92 transformações atrás dela), **~97** (terça do Google Ads), **~28** (Supabase `x0tz` diária) e **~20** (cada passada do notebook do iClips).

## Folga contra o limite

- Regime atual: ~7.600 de 9.000 (**~1.400 de folga, 16%**).
- Expansão já planejada nas pendências (18 rascunhos Meta, 12 Google, 5 RD e 8 de TikTok e LinkedIn, todos semanais): **+~200/mês**, chegando a ~7.800 (87%).
- Execuções manuais pesam: o disparo em massa de 14/10 mais as passadas manuais do MySQL (06, 07 e 14/10, ~93 cada) somam algumas centenas no mês. Com elas, o mês fica perto de **~8.100 a 8.300 (90 a 92%)**.
- **Cuidado ao somar as novas fontes Meta à Trusted consolidada:** as duas consolidadas do Facebook (`query-7aLj` e `query-QXqC`) disparam com regra "qualquer" (`any`) sobre 7 fontes, ~30 execuções por mês cada. Se as 76 fontes novas forem somadas ao gatilho com `any`, cada consolidada passa a rodar uma vez por fonte e por terça: **+~330 por mês em cada, ~+660 no total**. Com a regra "todas" (`all`) fica em ~4 por mês. A escolha da regra decide ~700 créditos.

**Conclusão:** a casa cabe nos 9.000, mas com folga de 8 a 10% depois da expansão. O que decide é a cadência do notebook do iClips, que sozinho consome 43%.

## Alavancas, em ordem de economia (todas dependem de decisão; R-002)

| alavanca | economia/mês | consequência |
|---|---:|---|
| Notebook do iClips de 4h para 8h | ~1.650 | dado do iClips com até 8h de atraso, em vez de 4h |
| ... para 12h | ~2.200 | até 12h de atraso |
| ... para 1x por dia | ~2.750 | atraso de até 1 dia (era o cron `0 6 * * *` até 07/10) |
| 32 fontes RD diárias para semanais | ~840 | contatos e conversões com até 7 dias de atraso |
| Fontes que rodam e não entregam dado (`rd-station-socq`, `webhook-v2-nZdJ`, `supabase-fEvu`, as duas cópias `1eaJ` e `bjQx` da conta da Vanguarda) | ~150 | nenhuma: não entregam nada que já não exista |
| Evitar disparo manual em massa | ~100 por passada evitada | nenhuma |

O cron do notebook foi mudado de diário para 4 em 4 horas **a pedido, em 07/10**, então a decisão de voltar é de quem pediu.

## O que fica de fora desta análise

Duração de cada execução (se o crédito depender do tempo de máquina, a `supabase-x0tz` com ~160 minutos por dia pesa muito mais do que a contagem sugere), custo de falhas e reexecuções, e o saldo de créditos do mês. Os três só se medem na página de cobrança da Nekt.
