# Camada Refined — início

Registro de 2026-09-03. A Refined é a camada oficial de consumo do ADR-0009: regras de
negócio aplicadas, folder = domínio de negócio.

## Convenção

`vanguardamartech_refined.rfn_<domínio>__<entidade>`, folder = domínio.
Herdada da `rfn_operacao__job` (`query-wpYP`, 26/08), o primeiro data product da camada.

O estilo de descrição também é herdado dela e é obrigatório: regras de negócio numeradas,
bloco de limitações conhecidas com "não contorne", e os números da validação com data.
Quem consome a tabela lê a descrição antes do SQL.

## O que existe agora

| Slug | Tabela | Domínio | Grão | Gatilho |
|---|---|---|---|---|
| `query-wpYP` | `rfn_operacao__job` | Operação | um job | evento |
| `query-skPU` | `rfn_midia__desempenho_diario` | Mídia | (id_conta, id_campanha, data) | evento em `query-tL4g` + `query-zF8L` (regra `all`) |
| `query-tESg` | `rfn_marketing__conversao` | Marketing | um evento de conversão | evento em `query-ehQc` |

Nenhuma das duas novas foi executada à mão — as duas esperam o gatilho agendado.

## `rfn_midia__desempenho_diario`

Sobe o grão do fato da Trusted para campanha-dia. Isso é o ponto: a Trusted guarda grão
misto (linhas de anúncio mais resíduo de campanha para o que o Google não publica por
anúncio, caso PERFORMANCE_MAX) e quem consome não deveria precisar saber disso. Somado em
campanha-dia o investimento fica completo e o truque desaparece da vista, com `grao_origem`
e `qtd_anuncios` guardando a rastreabilidade.

O que a camada agrega além do grão:

- **Identidade pela dimensão.** `cliente`, `conta` e `moeda` vêm de `trs_google_ads__conta`
  via `id_conta`. Nunca de rótulo digitado, nome de camada ou prefixo de tabela — nesta base
  nome de camada não identifica a conta (`don_watches_conta_1_g_ads` guarda a conta 2).
- **Indicadores recalculados dos totais.** CTR, CPC, CPM, CPA, ROAS e as taxas que a
  plataforma devolve por linha são não aditivos. Média de médias está errada. Ao reagregar,
  recalcule dos totais — nunca `AVG` destas colunas.
- **Pacing só quando faz sentido.** `consumo_orcamento_diario_pct` é NULL quando o orçamento
  é compartilhado: o teto vale para o conjunto de campanhas.
- **Joins LEFT de propósito.** INNER perderia investimento em silêncio. As flags
  `flag_campanha_nao_catalogada` e `flag_conta_nao_catalogada` expõem a falta.

Validado em 03/09 rodando a query inteira na forma executada — a lição de 02/09: 4.879 linhas
= 4.879 chaves, 0 órfã nas duas dimensões, 0 moeda divergente, 0 grão misto, investimento
fechando ao micro com a Trusted (114.615.673.464). A Trusted ainda carregava 4 das 39 fontes
nesse momento.

**Confirmado em produção no mesmo dia.** A tabela materializou às 13:49, 25 segundos depois da
Trusted terminar — o gatilho por evento funcionou na estreia. Com a base completa: 42.888
linhas = 42.888 chaves, 36 contas, 36 clientes, 0 sem cliente, 0 não confiável, 0 grão misto,
0 campanha não catalogada, 9.624 pares sem detalhe por anúncio, moedas BRL e USD. O
investimento, 1.361.954.201.918 micros, é **idêntico ao da Trusted, ao micro**: subir o grão de
anúncio-dia (75.552 linhas) para campanha-dia (42.888) não perdeu nem inventou um centavo.

**Moeda:** a tabela mistura BRL e USD (Move Rental Cars). Não há tabela de câmbio na base e
nada é convertido, de propósito. Total que cruze clientes precisa de filtro ou quebra por
moeda.

## `rfn_marketing__conversao`

Este é o caso em que a Refined faz o trabalho que a Trusted não podia fazer.

A RD Station entrega a origem de tráfego em **cinco formatos diferentes dentro do mesmo
campo**, e a Trusted os deixa intactos porque tratamento é trabalho da Refined. Medido em
03/09 sobre 17.602 conversões:

| Formato | Linhas | O que é |
|---|---|---|
| `encoded_<base64>` | 4.995 | JSON com a sessão de origem dentro, ilegível sem decodificar |
| `utm_source=...` | 1.400 | query string |
| texto livre | ~4.200 | nome escrito à mão, ~990 grafias distintas (`FACEBOOK` e `Facebook` convivendo) |
| URL / `android-app://` | ~660 | host ou pacote de aplicativo de referência |
| vazio | 8.354 | a origem não existe no dado |

Lendo só o que a Trusted já extraía, `utm_source` aparecia em 1.400 linhas com **um único
valor distinto**. Depois desta tabela, das 9.248 conversões que têm alguma origem, **9.242
ficam classificadas** e as ~990 grafias colapsam em 75 origens canônicas, em 14 canais.

Dentro do blob base64 a origem mora em `first_session.value` e ainda vem em três dialetos:
UTM em query string, o cookie `__utmz` legado do Analytics (`utmcsr=`/`utmcmd=`/`utmccn=`,
separado por `|`) e URL crua. Os três são lidos. `origem_extraida_de` registra qual arm da
cadeia de prioridade venceu em cada linha — é auditoria, não decoração.

**Decodificador percent-encoding de uso geral.** Monta a cadeia de bytes em hexadecimal e
converte para texto uma vez no fim. É o que faz acento multibyte voltar certo: trocar `%XX`
por caractere um a um corromperia `%C3%A1`. Fragmento malformado tem o `%` literal
restaurado, então string suja não derruba a linha; o que sobrar acende `escape_nao_tratado`
(1 linha em 03/09).

**PAGO exige sinal explícito.** Meio `cpc`/`cpm`/`paid`/`ppc`, origem que nomeia a plataforma
de anúncio, ou auto-tagging do Google. Na dúvida não classifica como pago — inflar a leitura
de resultado de mídia é pior que deixar em `OUTRO`.

`canal_indefinido` não mistura "sem origem" com "origem que não entendi": `sem_origem` marca
as 8.354 em que a origem não existe, `formato_nao_reconhecido` marca as 6 em que existe e o
parser não deu conta. São problemas diferentes e só o segundo sai de `registro_confiavel`.

## A chave de funil — `gad_campaignid`

Achado de 03/09, e o único caminho honesto para ligar mídia e conversão nesta base.

O auto-tagging do Google Ads deixa `gad_source` e `gad_campaignid` na origem de tráfego.
**`gad_campaignid` é o `id_campanha` do Google Ads.** Então:

```sql
rfn_marketing__conversao.id_campanha_google = rfn_midia__desempenho_diario.id_campanha
```

É junção exata, por id. E resolve o cliente de graça: campanha → `id_conta` → `cliente`,
sem casar nome de nada.

Medido em 03/09: 1.083 conversões carregam o parâmetro, em 57 campanhas distintas, das quais
**38 existem na `trs_google_ads__campanha` e cobrem 908 conversões**. As 19 que não casam são
de contas Google Ads fora da Nekt ou anteriores à janela de extração.

**A cobertura é 5,2% e esse é o número certo.** Antes deste achado eu tinha registrado que
não existia chave de funil e que o de-para não deveria ser inventado — a segunda metade
continua valendo, a primeira estava errada e foi corrigida na descrição da `query-skPU`.

### Por que não casar por nome de cliente

Medido em 03/09 com dobra de acento: dos 39 rótulos de cliente do Google Ads e 29 do RD
Station, **8 casam exatamente** — ACESSO SAUDE, AMAZONCOPY, AMZ GERADORES, BA ELETRICA,
BRAGA ACESSORIOS, HOSPITAL SANTA JULIA, REI DAS MANGUEIRAS, STEEL PORT.

O resto são quase-pares que exigem decisão humana:

| Google Ads | RD Station |
|---|---|
| MOVE RENTAL CARS | MOVE |
| DR. CABRAL CONTA 1 | DR. JOSE CABRAL JR |
| COLMEIA | CONSTRUTORA COLMEIA |
| BIGAZINE | BIGAZINE MANAUS |
| MILLENIUM | MILLENIUM SHOPPING |
| PNEU FORTE DISTRIBUIDORA | PNEU FORTE |
| DMELO TEMPLO DAS TINTAS | DMELLO |
| BRAGA MOTORS BMW | BRAGA MOTORS |
| BRAGA VAREJO | BRAGA VEICULOS |
| PMZ GRUPO LOJA + GRUPO ECOMM + ESCOLA DE MECANICOS | PMZ (3 para 1) |
| DON WATCHES CONTA 1 + CONTA 2 | DON WATCHES (2 para 1) |

Os dois últimos são exatamente o que a R-003 proíbe fundir. E 8 clientes do RD (AC DISPLAY,
AMAZON OPEN MALL, BEST CAR, HOPE BAY, INFORCELL, KL RENT A CAR, MARAVILHA MOTOS, VBOT) não
têm Google Ads nenhum.

Cobertura alta obtida por casamento de nome seria número errado. A chave não se troca por
conveniência.

## O que falta para o funil valer de verdade

Nada disso é bloqueio para as duas tabelas acima, que já estão de pé:

1. **Facebook Ads consolidado na Trusted.** Hoje só existem tabelas por cliente, legado.
   Sem isso, conversão classificada como `PAGO_SOCIAL` não tem investimento para cruzar, e a
   `rfn_midia__desempenho_diario` não representa o investimento total do cliente.
2. **De-para cliente ↔ fonte RD**, se a agência quiser cobertura além dos 5,2%. É decisão
   humana, linha por linha, e a R-003 limita o que pode ser fundido.
3. **Auto-tagging ligado nas contas que não têm.** Só 20 dos 29 clientes do RD aparecem com
   `gad_campaignid`. Isso é configuração na plataforma, não tratamento de dado.
