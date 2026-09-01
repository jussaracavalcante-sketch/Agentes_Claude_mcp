# Trusted Google Ads — expansão para 39 contas

**Data:** 2026-09-01 · **Status:** publicado, aguardando a primeira execução agendada

Duas transformações na camada `Trusted`, folder `google_ads`, que leem as tabelas que as
39 fontes de Google Ads **já gravaram** e produzem duas tabelas tratadas.

**Nenhuma fonte foi tocada.** Nem cron, nem stream, nem camada de destino — conforme a R-002.
A expansão é só SQL de leitura.

| Slug | Tabela de saída | Escopo | Grão |
|---|---|---|---|
| `query-zF8L` | `trs_google_ads__campanha` | 39 fontes / 815 campanhas | 1 linha por campanha |
| `query-tL4g` | `trs_google_ads__insight_diario` | 39 fontes / 36 com dado | misto (ver abaixo) |

As duas foram de 5 para 39 fontes em 01/09. Casam por `id_campanha` + `_fonte`.

## O grão misto, e por que ele existe

`trs_google_ads__insight_diario` mistura dois grãos de propósito, marcados na coluna `grao`:

- **`ANUNCIO`** — uma linha por anúncio por dia, de `ad_performance`. É o grão normal.
- **`CAMPANHA`** — uma linha por campanha por dia, de `campaign_performance`, **somente**
  para os pares (campanha, dia) que não existem em `ad_performance`.

O Google não expõe desempenho no nível de anúncio para campanhas `PERFORMANCE_MAX`. Uma
Trusted lida só sobre `ad_performance` perde esse investimento **em silêncio**. Medido em
31/08: Move Rental Cars perdia US$ 1.347,11 de US$ 19.372,45 (7% da conta, 18.072 cliques).

## A premissa, verificada nas 39 contas

O desenho só é exato se a ausência for sempre por **campanha-dia inteiro**. Se houvesse
atribuição parcial — um dia com alguns anúncios mas soma menor que o total da campanha —
a união por presença contaria a menos, e a query precisaria de resíduo por diferença.

Medido em 01/09 sobre `campaign_performance` das 39 fontes:

| Medida | Resultado |
|---|---|
| Pares (campanha, dia) | 42.758 |
| Pares sem nenhuma linha de anúncio | 9.607 (22,5%) |
| **Pares com cobertura parcial** | **0** |
| **Anúncios órfãos** (sem par em `campaign_performance`) | **0** |
| Total de referência | 1.354.538.045.829 micros |
| Total reproduzido pela Trusted | 1.354.538.045.829 micros |

Bate ao micro. **Se um dia aparecer par parcial, a premissa cai** — é esse teste que deve
ser refeito antes de confiar em qualquer soma.

## Três contas sem linha de desempenho

36 das 39 têm dado. As três sem, verificadas uma a uma — nenhuma é problema da query:

| Fonte | Conta | O que tem | Diagnóstico |
|---|---|---|---|
| `google-ads-vE2C` | DON WATCHES CONTA 1 · 855-373-3895 | zero em tudo, inclusive `campaigns` | Sem atividade desde 2023, confirmado na API do Google: R$ 0, 0 impressões. |
| `google-ads-wypN` | DR. CABRAL CONTA 1 · 738-192-0209 | **38 campanhas**, zero desempenho | **Não é falha.** As 6 execuções desde 26/08 deram sucesso e os streams de performance estão habilitados. A conta não teve entrega na janela extraída. |
| `google-ads-rYKp` | RODRIX MOTOS · 973-940-7801 | 1 campanha, zero desempenho | Mesmo caso, em escala menor. |

Os ramos ficam nas queries: custam zero e o dado entra sozinho quando a conta produzir.

> **Para o time de mídia:** 38 campanhas e nenhum investimento na Dr. Cabral conta 1 é
> sinal de conta parada **ou** de janela de extração curta demais. Vale confirmar qual dos dois.

## Armadilhas que este trabalho expôs

- **Nome de camada e prefixo de tabela não identificam a conta.** `don_watches_conta_1_g_ads`
  guarda a conta 2 e vice-versa; `braga_yamaha_consorcios` guarda a Braga Yamaha/Motos;
  `caa` guarda só a CAA Tintas. A conta se resolve pelo `customer_id` extraído do
  `resource_name` (`customers/<id>/...`), nunca pelo nome. Mapa completo dos 39 prefixos
  em [`prefixos-google-ads.md`](prefixos-google-ads.md), cada um sondado contra a base.
- **Duas famílias de unidade.** Dinheiro vem em micros (÷ 1.000.000); taxas vêm como fração
  de 0 a 1, não percentual. Tratar as duas igual erra por um fator de um milhão ou de cem.
- **Não arredondar por linha.** `ROUND` antes do `SUM` derivou R$ 0,50 em R$ 58 mil.
  `investimento_micros` é a fonte exata; arredonde na leitura.
- **`date` chega como TIMESTAMP**, não DATE. Convertido com `DATE()`, sem deslocar fuso —
  o Google já entrega o dia na timezone da conta.
- **Moeda não existe em nenhum stream.** Fixada por fonte no SQL. BRL em tudo menos a Move
  Rental Cars, que é USD. **Não somar investimento entre clientes sem filtrar `moeda`.**

## O rótulo do cliente: como o risco foi eliminado

Na primeira versão, o nome do cliente era **literal digitado no SQL** — 39 em `query-zF8L`
e mais 39 (× 2 grãos) em `query-tL4g`. Um erro de digitação colava o nome de um cliente na
conta de outro, e não havia como perceber: o rótulo não vinha do dado, então não existia
nada com o que conferir.

**A correção:** `trs_google_ads__conta` (`query-jHEX`), uma dimensão de contas semeada a
partir da listagem do **MCC da própria Google** (85 contas), com join chaveado por
`id_conta` — que é derivado do dado, via `REGEXP_EXTRACT` do `resource_name`.

Por que isso fecha a classe de erro:

| Antes | Depois |
|---|---|
| Nome amarrado ao **slug**, digitado 78 vezes | Nome amarrado ao **`id_conta`**, que sai do dado |
| Erro produz rótulo errado, silencioso | Conta sem linha na dimensão sai com `cliente` NULL — contável |
| Nome e moeda inventados no SQL | Vêm da Google; a moeda deixa de ser digitada |
| Conta nova exige editar 2 queries | Já está na dimensão: entra sozinha |

O conector Google Ads da Nekt **não expõe stream de `customer`/account** — por isso o nome
não pode ser lido do warehouse e precisa ser semeado. A digitação não desaparece; ela sai
de 78 lugares para **um**, passa a vir da Google em vez de mim, e fica conferível.

### Duas colunas de nome, de propósito

- **`conta`** — nome exato na plataforma Google. Fonte da verdade, não se edita à mão.
- **`cliente`** — rótulo de negócio da Vanguarda. Vem do bloco de override quando existe;
  senão repete `conta`.

Decisão de 01/09: **os 39 rótulos atuais foram preservados como override explícito**, para
não renomear cliente nenhum de surpresa. A flag `rotulo_diverge_da_plataforma` expõe as
divergências como dado.

### As divergências que apareceram (documentadas, não bloqueiam)

Cruzando os 39 rótulos contra o MCC: **39/39 customer_id existem** (nenhuma conta trocada),
**39/39 moedas conferem**. Mas 27 rótulos diferem do nome da Google além de acento e caixa.
Quatro são só acento; 23 são nome de fato diferente. **Nenhuma afeta o dado** — o
`id_conta` identifica a conta, o rótulo é só exibição. Por isso ficam registradas aqui e
seguem valendo como estão (R-004). A lista completa, com o caso a caso, está em
[`rotulos-google-ads-revisao.md`](rotulos-google-ads-revisao.md); ela existe para consulta
de quem quiser decidir, não como pendência. As mais visíveis:

| Rótulo na Trusted | Nome na plataforma Google |
|---|---|
| `BRAGA MOTORS BMW` | BRAGA VEICULOS LTDA |
| `BRAGA VAREJO` | Braga Motomarcas |
| `BRAGA YAMAHA` | Braga Motos |
| `BRAGA YAMAHA CONSORCIOS` | Braga Consórcio |
| `OLA CASA NOVA` | Olá Empreendimentos |
| `PMZ GRUPO LOJA` | PMZ |
| `DON WATCHES CONTA 1` / `CONTA 2` | Don Watches - Ativa / Ativa Validada |
| `CONSTROI INCORPORADORA` | Constrói Construtora |
| `DEB TRANSPORTADORA` | DEB Transportes |
| `MILLENIUM` | Millennium Shopping |
| `SANTO REMEDIO` | SANTO REMÉDIO VNG |

Cada uma é apelido deliberado **ou** rótulo desatualizado. Sem decisão, fica como está —
o override explícito preserva o comportamento atual indefinidamente.

Uma colisão vale registro por ser a única com consequência futura: `SANTO REMEDIO` é o
nome exato de outra conta do MCC (`5138016841`), ainda não integrada. Se ela for
integrada, dois clientes passam a ter o mesmo rótulo — e aí sim vira tratamento, porque
quebra a distinção que a R-003 exige. Até lá, não é problema.

> **Armadilha registrada:** duas contas do MCC se chamam exatamente
> `TS Clinic - Saúde , Emagrecimento e Performance` (`1752601290` e `6337596664`). Nenhuma
> está integrada hoje. Se forem, o nome sozinho não distingue — usar `id_conta`.

## Estado e próximo passo

`query-jHEX` está publicada (deploy limpo) com cron **06:00 Manaus**, bem antes da cadeia do
Google Ads às 12:43. **As duas queries Trusted seguem intocadas** — ainda com os literais.

O passo seguinte, depois que a dimensão materializar na primeira execução: trocar os literais
`cliente`/`moeda` das 78 ramificações por um `LEFT JOIN` em `trs_google_ads__conta` por
`id_conta`. Fazer isso antes de a tabela existir quebraria as duas pipelines que hoje
funcionam, então a ordem importa.

Nada foi executado manualmente. Sem sync com GitHub, conforme decidido.
