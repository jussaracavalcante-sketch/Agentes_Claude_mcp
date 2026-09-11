# Google Ads e Meta passam a rodar semanalmente — 2026-09-04

## O que mudou

**46 fontes** saíram de execução diária para **terça-feira**, mantendo o horário de cada uma
(o escalonamento das 04:00 às 12:43, em `America/Manaus`, existe para não concentrar carga e
foi preservado).

| Plataforma | Fontes alteradas |
|---|---:|
| Google Ads | 39 |
| Facebook Ads (Meta) | 7 |

Das 39 do Google Ads, 38 eram diárias e a `google-ads-vE2C` já era semanal às segundas —
alinhada para terça, para o parque ficar uniforme.

**Não alteradas, e por quê:**

- `google-ads-3eFc`, `google-ads-mvUx`, `google-ads-hBlk` (Unipar) — inativas, falhando com
  `USER_PERMISSION_DENIED`. O cron não dispara; mudá-lo não teria efeito.
- `google-ads-OzfZ` (Prestex) — em manual, pausada em 03/09 a pedido.
- `google-ads-H3hJ`, `google-ads-4YJU` — rascunhos, sem gatilho.
- `facebook-ads-mrJt` — excluída em 26/08.

Verificado depois da mudança: os únicos `* * *` restantes entre as fontes de Google Ads são
as três da Unipar, inativas.

## O risco que isso cria, declarado antes de executar

A janela de reprocessamento é de **7 dias** — medido em 2026-09-04, ver
`lookback-medicao-2026-09-04.md`.

Com execução **diária**, um dia é relido cerca de 7 vezes antes de sair da janela. Com
execução **semanal**, cada dia é relido **exatamente uma vez**. Isso significa:

**Se a execução semanal falhar, aquela semana nunca mais é lida.** Não é atraso, é buraco
permanente. A Nekt para a fonte após 3 falhas consecutivas, mas basta uma para perder a
semana.

**O conserto é subir o `lookback_window` para 14 dias**, o que devolve a redundância: cada
dia volta a ser lido duas vezes e uma falha isolada deixa de causar perda. Esse campo só é
editável na interface web da Nekt — o MCP redige o valor e não há como alterá-lo por aqui.

Decisão da Jussara em 2026-09-04: seguir com a mudança de cron agora, e subir o lookback na
interface depois. A mudança de cron é reversível em minutos.

## Consequências operacionais

### As tabelas de Facebook materializam em 09/09, não em 05/09

A `query-QXqC` (fato) e a `query-7aLj` (dimensão de campanha) são disparadas por evento nas
7 fontes de Facebook. Com as fontes na terça, elas passam a rodar **09/09**.

A `query-HCcd` (dimensão de conta) é cron diário às 03:00 e materializa normalmente em 05/09
— ela lê uma tabela órfã e congelada, então a cadência diária não custa quase nada.

A publicação da Refined das duas plataformas fica para depois de 09/09, com o `COUNT(*)` de
confirmação nas três.

### A flag `conta_defasada` fica não confiável até o próximo deploy

O limiar de `> 2 dias` foi calibrado para carga diária. Com carga na terça, o dado de uma
segunda-feira fica legitimamente **8 dias** sem atualização até a terça seguinte — a flag
passaria a acusar **todas as contas, quase todo dia**. Alarme constante é pior que alarme
nenhum: ensina a ignorar.

O limiar correto é `> 9` (8 dias de defasagem legítima mais 1 de margem). Está aplicado em:

- `sql/refined/rfn_midia__desempenho_diario.sql` — ainda não publicada, então o arquivo é a
  fonte da verdade e sai correta quando for ao ar.
- `sql/trusted/trs_facebook_ads__insight_diario.sql` — **aplicado no arquivo, NÃO em
  produção.**

**A conta da Nekt está sem saldo e não se pode fazer deploy**, então a `query-QXqC` segue
com `> 2`. O arquivo carrega um aviso em maiúsculas no topo dizendo que está à frente da
produção, para ninguém assumir que o repositório espelha o que está rodando.

**Até que isso seja publicado, ignore a coluna `conta_defasada` do Facebook.** Para saber se
uma conta parou de verdade, use `ultima_data_com_entrega` e compare com a terça mais recente.

## Ponta solta

Sem saldo, as execuções de terça podem falhar por falta de crédito, e não por problema de
fonte. Se em 09/09 as tabelas não materializarem, conferir o saldo antes de investigar
credencial ou permissão — o sintoma é o mesmo e a causa não.
