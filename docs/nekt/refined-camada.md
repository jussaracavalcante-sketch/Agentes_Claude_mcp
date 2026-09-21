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

## `rfn_midia_off__pi` · `query-SguJ` · folder `midia_off`

Grão: um PI de mídia OFF. Lê `trusted.trs_pi__insercao`, gatilho por evento nela.
Espelha o Dashboard de Mídia OFF do VJOB com as escolhas declaradas e numeradas (regras 1 a 6).

Escopo: tudo que não é `Internet` — lista negra de um item, para que tipo novo apareça
em vez de sumir. Cancelado é marcado (`eh_vigente`), não excluído. Grafia de `tipo_midia`
normalizada sem fundir mídias distintas.

A coluna que justifica a tabela é `motivo_sem_acompanhamento`, calculada da própria base:
`coberto` · `cancelado` · `tipo de mídia fora da view do Supabase` · `cliente de teste ou
interno` · `sem data de início`. Validado em 18/09/2026 sobre 3.319 PIs em escopo, com
**zero** em "sem causa identificada".

**Não use para fechar mês.** Contra o painel do VJOB em setembro/2026: 32 PIs aqui contra
113 lá, R$ 218.628,60 contra R$ 970.799,32. A origem está parada em 06/08/2026.

Dois indicadores do painel ficaram **de fora de propósito** — "iniciando em até 3 dias" e
"em veiculação hoje" dependem de `CURRENT_DATE` e congelariam ao materializar. O SQL de
leitura dos dois está na descrição.

---

## `rfn_cadastro__cliente_vbot` · `query-NxG1` · folder `cadastro`
## `rfn_cadastro__cliente_vanguarda_comunicacao` · `query-hH5g` · folder `cadastro`

Par de tabelas com o **mesmo formato e as mesmas colunas**. Grão: um **cadastro** da
empresa como cliente, **por sistema**. Chave: `id_cadastro` = sistema + id no sistema.
Gatilho por evento após `query-8nEt` e `query-iX2P`, regra any. Alerta de falha ligado
nas duas.

Existem para separar na leitura o trabalho e o custo **intragrupo** — sem apagar nada na
ingestão. As duas empresas são, ao mesmo tempo, companhia do grupo e cliente da agência.

### A regra que sustenta as duas: a chave é o documento, nunca o rótulo

Medido em 21/09/2026: no financeiro (`supabase_gold_mvw_fin_cliente`) a Vanguarda
Comunicação aparece pela **razão social** `B. R. M. COSTA DE LIMA E CIA SOCIEDADE SIMPLES
PURA`, não pelo nome fantasia. Um filtro `cliente_nome LIKE '%VANGUARDA%'` pega
R$ 40.067,03 — que é da **Vanguarda Mídia Digital, outra empresa** — e **perde os
R$ 47.544,32 desta**. Ou seja: o filtro por nome erra as duas pontas ao mesmo tempo.
A coluna `chave_por` declara, linha a linha, se valeu `CNPJ`, `ID_SISTEMA` ou `ROTULO`.

### O que ficou fora de cada tabela, de propósito

| Quem | CNPJ | Por quê |
|---|---|---|
| Vanguarda Mídia Digital / VPromo | 26.123.250/0001-02 | **Terceira** empresa do grupo. Mesma PJ com dois cadastros no iClips (1511 e 3893). Nenhuma tabela pedida. Não fundir por conter "VANGUARDA". |
| Vanguarda Internacional | 59.772.810/0001-09 | **Cliente real.** Projetos LAVENDER (onboarding, on/social, off), 21 atividades em 6 departamentos. |
| Para Guardar | 16.665.666/0001-07 | **Cliente real.** iClips 1683/2842/2843, 29 projetos. Três marcas sob um CNPJ (`PARA GUARDAR`, `HAYA SOLAR`, `PARA CHEGAR`) e razão social `EF LOCAÇÃO DE IMÓVEIS PRÓPRIOS LTDA.` no financeiro. |
| Cliente Teste | 62.361.814/0001-09 | Artefato de teste — e tem CNPJ próprio, o que o faz passar por cliente. |
| Teste Hugo Senna | — | VJOB `id_cliente` 146, 1.163 escopos, `cliente_ativo = true`. Existe **só no VJOB**: busca por "SENNA" nas outras bases dá zero. |

**Correções aplicadas em 21/09/2026, no mesmo dia da publicação.** Duas afirmações desta
página estavam mais fortes que a evidência: (a) "Teste Hugo Senna é teste sobre nome de cliente
real" — não há cliente Hugo Senna na base, era leitura do nome; (b) os 1.493 escopos do VJOB
atribuídos ao CNPJ da Para Guardar — o VJOB **não tem CNPJ**, então a ligação é por nome, não
por documento. Nenhuma das duas afeta as tabelas publicadas (nenhuma inclui a Para Guardar),
mas as duas eram o mesmo erro que o par existe para impedir.

### Validado por execução em 21/09/2026, antes do deploy

**VBOT** (CNPJ 61.077.352/0001-30) — 4 linhas:
`ICLIPS 3552` 23 projetos e 160 peças · `ICLIPS 3894` 1 e 1 · `VJOB 130` 1.263 escopos,
1.099 concluídos, ativo · `PI` 1 PI de R$ 5.720,00.
Sem cadastro no **Conexa** (coerente — a VBOT opera o Conexa, não é cliente nele) e sem
lançamento no **financeiro**.

**Vanguarda Comunicação** (CNPJ 07.865.616/0001-74) — 5 linhas:
`ICLIPS 263` 227 projetos e 953 peças · `VJOB 160` 1 escopo, **inativo** ·
`CONEXA 74` 1 cobrança de R$ 5,00, ativo, classe `EMPRESA` ·
`CONEXA 96` 0 cobranças, ativo, classe `TESTE_SOBRE_O_CNPJ` ·
`FINANCEIRO` 4 lançamentos, R$ 47.544,32. Sem PI.

O `CONEXA 96` é o cadastro literalmente chamado `CADASTRO TESTE MESMO CNPJ`: divide o CNPJ
da empresa, está `is_ativo = true` e **conta na base de 122 clientes da VBOT**. Ele entra
na tabela marcado pela coluna `classe` — não é fundido (esconderia que existe) nem
descartado (esconderia que conta).

### Limitações — não contorne

1. **A linha de PI é chaveada por rótulo.** Os PIs intragrupo têm `cliente_cnpj` **vazio**
   na origem (o 1 da VBOT e os 7 de Cliente Teste). Renomear o cliente no PI derruba a
   linha em silêncio. É a única chave fraca do par e está declarada em `chave_por`.
2. **As colunas de volume não se somam entre sistemas** — projeto, peça, escopo, cobrança,
   PI e lançamento são grãos diferentes.
3. **Ausência de linha ≠ volume zero.** Significa "sem cadastro naquele sistema". Os casos
   conferidos estão escritos na descrição de cada tabela para não virarem dúvida depois.
4. **Os R$ 5,00 do Conexa são valor de teste, não receita.** Para receita intragrupo vale o
   financeiro: R$ 47.544,32.
5. **DECISÃO PENDENTE** — o cadastro `ICLIPS 1562` é **pessoa física** cujo nome reproduz a
   raiz da razão social da Vanguarda Comunicação, com 2 projetos e 0 peças, última atividade
   em 19/04/2021, e **sem CNPJ**. Ficou **fora**: incluí-lo seria resolver identidade por
   semelhança de nome, o que a regra 1 proíbe. Alternativa não tomada: incluir como cadastro
   da empresa. Precisa de confirmação de quem conhece o cadastro.

### Peso do intragrupo na base, para dimensionar

Consistente em ~2% em todas as tabelas medidas em 21/09/2026:
`vjob_escopo` 3.728 de 195.163 (1,91%) · `fato_atividade` 1.159 de 54.056 (2,18%) ·
`dim_peca_entrega` 813 de 41.456 (2,01%) · `iclips_job_cliente` 263 de 12.069 (2,20%) ·
`fato_job` 90 de 2.859 (3,22%).
