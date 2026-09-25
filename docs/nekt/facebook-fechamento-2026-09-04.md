# Fechamento do Facebook no medalhão — 2026-09-04

Continuação de `facebook-consolidacao-2026-09-04.md`. Ali ficou a consolidada de insight;
aqui as duas dimensões que faltavam e a Refined das duas plataformas.

## As três peças da Trusted de Facebook

Agora o Facebook tem a mesma estrutura que o Google Ads — fato mais duas dimensões:

| Peça | Query | Tabela | Grão |
|---|---|---|---|
| Fato | `query-QXqC` | `trs_facebook_ads__insight_diario` | anúncio-dia, 137.057 linhas |
| Dimensão de campanha | `query-7aLj` | `trs_facebook_ads__campanha` | campanha, 1.231 linhas |
| Dimensão de conta | `query-HCcd` | `trs_facebook_ads__conta` | conta, 102 linhas |

Todas em `vanguardamartech_trusted_facebook_ads`.

## O que a validação encontrou

### Dimensão de campanha: dedup não é opcional

1.248 linhas na origem para 1.231 ids. A chave do stream é `[id, updated_time]`, então a
origem guarda mais de uma versão da mesma campanha. Sem o `QUALIFY` a dimensão **multiplica
o fato** no join.

### 18 campanhas com entrega e sem dimensão — R$ 94.646,41

4,1% do investimento de Facebook. São campanhas provavelmente excluídas no Meta: o endpoint
de campanhas devolve só as atuais, o insight guarda o histórico.

| Conta | Campanhas | Investimento |
|---|---:|---:|
| Constroi ADS | 6 | 75.006,52 |
| Colmeia - Cartão | 1 | 10.686,49 |
| CA- Braga Motos MAO | 2 | 5.786,53 |
| BEST CAR 2024 | 8 | 3.165,18 |
| PMZ GRUPO LOJA | 1 | 1,69 |

**Consequência de projeto:** o join tem de ser `LEFT`, nunca `INNER`. Com `INNER` esses
R$ 94.646,41 desaparecem em silêncio. Com `LEFT` o investimento fica, os atributos vêm NULL e
a linha sai marcada por `flag_campanha_nao_catalogada`. Está escrito na descrição da dimensão,
em maiúsculas, porque é o erro que qualquer um cometeria.

No sentido inverso: 77 campanhas existem na dimensão e nunca tiveram entrega — normal.

### Zero divergência de conta

Nenhum `id_campanha` casa com `id_conta` diferente entre fato e dimensão. O id de campanha do
Facebook é globalmente único, então o join por id nunca cruza contas. Diferente do Google Ads,
onde nome de camada e prefixo de tabela mentem sobre qual conta guardam.

### A fonte da dimensão de conta está excluída

`facebook-ads-mrJt` está com `deleted: true`, `active: false`, `status: inactive`. Última
extração em **26/08/2026**, e não haverá outra. A `facebook_ads_adaccounts` sobrevive na Raw
como órfã — exclusão de tabela é backoffice.

Então a `trs_facebook_ads__conta` é uma **foto de 26/08**, não o presente. Moeda, fuso e razão
social mudam devagar, então a foto serve; status de conta não, e pode estar velho. Conta
integrada depois de 26/08 não existe ali — e não vira linha sem moeda em silêncio, aparece com
`flag_conta_nao_catalogada` na Refined.

Decisão da Jussara. A alternativa não tomada foi deixar moeda NULL no Facebook, o que evitaria
a dependência morta mas tiraria a base da regra "não some entre moedas" e esconderia os fusos.

### As 7 contas estão em 4 fusos

| Fuso | Offset | Contas |
|---|---|---|
| `America/Manaus` | UTC-4 | Acesso Saúde, Best Car, Braga Veículos Pós Vendas |
| `America/Sao_Paulo` | UTC-3 | Braga Motos MAO, Colmeia |
| `America/La_Paz` | UTC-4 | Constroi ADS |
| `America/Puerto_Rico` | UTC-4 | PMZ GRUPO LOJA |

O `date_start` dos insights do Facebook vem **no fuso da conta**, não num fuso fixo. Então
"dia" não significa exatamente a mesma coisa entre contas: o dia das contas UTC-3 fecha uma
hora antes, em UTC, que o das UTC-4.

**Não é corrigível** com esta extração — o Facebook agrega no fuso da conta e não devolve o
detalhe horário (existe um stream `adsinsights_hourly_advertiser_timezone`, de outra fonte,
que resolveria). Por isso a coluna `fuso_conta` chega até a Refined: quem cruzar Facebook com
outra plataforma no mesmo dia precisa saber da hora de desalinhamento na fronteira do dia.
Comparação mensal não é afetada na prática.

## A Refined das duas plataformas

`rfn_midia__desempenho_diario` passa a ter 65 colunas e uma coluna `plataforma` que vale
`GOOGLE_ADS` ou `FACEBOOK_ADS`. Grão: `(plataforma, id_conta, id_campanha, data)`.

Validação da perna do Facebook, rodada sobre as tabelas materializadas:

| | |
|---|---:|
| Linhas campanha-dia | 38.777 |
| Chaves únicas | 38.777 |
| Contas | 7 |
| Investimento | R$ 2.304.065,61 |
| Linhas sem campanha catalogada | 281 (R$ 94.646,41) |
| Linhas sem conta | 0 |
| Janela | 01/01/2024 a 04/09/2026 |

O investimento fecha **ao centavo** com a Trusted. Subir o grão de 137.057 linhas anúncio-dia
para 38.777 campanha-dia não perdeu nada.

### Regra 8 — conversão no Facebook

Escolha da Jussara: `conversoes = leads + compras + conversas_iniciadas_7d`.

| Ação | Total | Peso |
|---|---:|---:|
| `conversas_iniciadas_7d` | 249.087 | 90,7% |
| `leads` | 25.376 | 9,2% |
| `compras` | 64 | 0,02% |
| **conversões** | **274.527** | |

**O CPA que isso produz é R$ 8,39.** Se a regra fosse só lead e compra, seria R$ 90,57 — dez
vezes. A diferença é o peso das conversas, que dominam o número. As três ações continuam em
colunas próprias (`conversoes_leads`, `conversoes_compras`, `conversoes_conversas`) para quem
quiser recompor.

Alternativa considerada e não tomada: conversão pelo objetivo da campanha, usando o
`objetivo_canonico` da dimensão — campanha de leads conta lead, de vendas conta compra, de
engajamento conta conversa. Fica registrada aqui caso a leitura do CPA incomode.

### O que fica NULL no Facebook, de propósito

Nada é preenchido por analogia. A ausência é informação:

- `canal` / `subcanal` — conceito do Google (`advertising_channel_type`). O equivalente do
  Facebook é o objetivo, que sai em `objetivo`, `objetivo_canonico` e `geracao_objetivo`.
- `interacoes` e `taxa_interacao_pct` — `interactions` é conceito do Google, sem equivalente fiel.
- `todas_conversoes`, `valor_todas_conversoes`, `conversoes_view_through` — idem.
- `status_campanha_no_dia` — o insight do Facebook não carrega status por dia, só o atual.
- `rotulo_customizado` e `rotulo_diverge_da_plataforma` — não existe rótulo curado da Vanguarda
  para o Facebook. Sem rótulo não há divergência a apontar.
- **`orcamento_diario`, `orcamento_compartilhado` e `consumo_orcamento_diario_pct`** — a unidade
  do orçamento do Facebook não está verificada (o teste de 27/08 na Best Car não confirmou
  centavos). Dividir por 100 sem prova produziria número errado com cara de certo.

E `taxa_conversao_pct` no Facebook usa clique como base, não interação, porque interação não
existe ali. Está anotado na query.

### Frescor agora vale para as duas plataformas

`ultima_data_com_entrega`, `dias_sem_entrega` e `conta_defasada` passaram a ser calculados
**dentro da Refined**, por `(plataforma, id_conta)`, em vez de herdados da Trusted do Facebook.
Uma regra só, as duas plataformas — o Google Ads ganhou a mesma proteção de graça.

## Estado: falta materializar

As três tabelas de Trusted do Facebook **ainda não existem**. Os gatilhos:

- `query-QXqC` e `query-7aLj` — evento nas 7 fontes, que rodam 05:00 (SP)
- `query-HCcd` — cron 03:00 America/Manaus (04:00 SP), antes das fontes

Primeira materialização: **05/09/2026, entre 04:00 e 05:10 (SP)**.

A Refined das duas plataformas está escrita e validada em `sql/refined/`, mas **não foi
publicada**, porque referência a tabela catalogada e não materializada derruba a query inteira
— e derrubar a `rfn_midia__desempenho_diario` tiraria o Google Ads do ar junto. O deploy é
amanhã, depois de um `COUNT(*)` nas três.

Nenhuma pipeline foi executada à mão, conforme a regra.

## Ainda não mexido

As 12 queries de Facebook por cliente (6 pares das contas vivas mais 8 órfãs) continuam
rodando. Aposentá-las é decisão à parte, depois de a consolidada rodar em produção — não se
apaga o que ainda não foi substituído de fato.
