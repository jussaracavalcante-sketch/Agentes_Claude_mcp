# Consolidação da Trusted de Facebook Ads — 2026-09-04

## O que foi feito

Criada a `trs_facebook_ads__insight_diario` consolidada (`query-QXqC`), na camada nova
**Trusted Facebook Ads** (`vanguardamartech_trusted_facebook_ads`). Substitui o padrão de
uma query por cliente — 10 tabelas espalhadas pelas camadas dos clientes — por uma tabela só.

Grão: um anúncio por dia, chave `(id_anuncio, data)`.

## Cobertura: 7 contas, 6 clientes

| Conta | id_conta | Fonte |
|---|---|---|
| Acesso Saúde | 261401095311098 | `facebook-ads-Si4U` |
| CA- Braga Veículos Pós Vendas | 1966625676863140 | `facebook-ads-kQ2S` |
| CA- Braga Motos MAO | 1172209193972759 | `facebook-ads-GWZ2` |
| PMZ GRUPO LOJA | 839811160322414 | `facebook-ads-x4yO` |
| Colmeia - Cartão | 781268383219049 | `facebook-ads-ln1a` |
| BEST CAR 2024 | 235333404360431 | `facebook-ads-E9RT` |
| Constroi ADS | 526683429550109 | `facebook-ads-oB7d` |

As duas contas da Braga são linhas distintas, com `id_conta` e `cliente` próprios, conforme
a R-003. Não existe "GRUPO BRAGA" na tabela.

**Fora da consolidada, de propósito:** Pátio Gourmet, Nova Era BV, Nova Era PVH e
Nova Era MAO. As fontes foram retiradas deliberadamente; as tabelas por cliente continuam
existindo com dado congelado.

## Validação

Rodada antes de publicar, no BigQuery, com a query final:

| Métrica | Valor |
|---|---|
| Linhas | 137.057 |
| Chaves únicas `(id_anuncio, data)` | 137.057 |
| Hashes únicos | 137.057 |
| Contas / fontes | 7 / 7 |
| Investimento | R$ 2.304.065,61 |
| Itens de ação desaninhados | 965.321 |

**Reconciliação com o que substitui:** as 6 tabelas por cliente somam exatamente
137.057 linhas e R$ 2.304.065,61. A consolidada reproduz os dois números ao centavo —
não perde nem inventa linha.

| Camada de origem | Linhas | Investimento |
|---|---:|---:|
| `acesso_saude` | 20.417 | 175.339,54 |
| `braga_veiculos` | 62.554 | 364.719,82 |
| `pmz_loja` | 13.200 | 505.356,30 |
| `colmeia` | 23.182 | 530.808,12 |
| `best_car` | 7.190 | 431.651,15 |
| `constroi_incorporadora` | 10.514 | 296.190,68 |
| **Total** | **137.057** | **2.304.065,61** |

## A flag de defasagem

É a única lógica nova (o resto é herdado da `query-OTSI`, validada em 26/08). Três colunas:
`ultima_data_com_entrega`, `dias_sem_entrega`, `conta_defasada` (> 2 dias).

Conserta a falha estrutural que deixou 4 clientes congelados por 4 a 6 dias sem ninguém notar:
**transformação com trigger de evento sobre fonte inexistente não roda, não falha e não
alerta** — e a tabela segue respondendo consulta com dado velho com cara de dado bom. Aqui a
defasagem aparece na leitura, não no monitoramento.

Usa a última data **com entrega**, não `MAX(data)`: dia sem entrega não é sinal de vida. A
diferença é real — o Pátio Gourmet tinha carga de 30/08 e última entrega de 29/08.

Validada nos dois sentidos em 2026-09-04:

| Conta | Última entrega | Dias | Flag |
|---|---|---:|---|
| LOJA \| PÁTIO GOURMET \| BOLETO | 29/08 | 6 | dispara |
| LOJA \| NOVA ERA BV \| BOLETO | 31/08 | 4 | dispara |
| ECOMM \| NOVA ERA MAO \| CART | 31/08 | 4 | dispara |
| LOJA \| NOVA ERA PVH \| CART | 31/08 | 4 | dispara |
| as 7 contas vivas | 04/09 | 0 | não dispara |

## Decisões tomadas, e as alternativas que não foram

**Camada nova em vez da `Trusted` compartilhada.** A `trs_google_ads__insight_diario`
(39 contas de cliente) e a `trs_rd_station__conversao` (30 fontes) moram na `Trusted`, então
a consistência apontava para lá. A escolha foi isolar a plataforma, para não misturar dado de
cliente com o medalhão dos sistemas internos da Vanguarda. Custo aceito: assimetria com o
Google Ads.

**Regra de evento `any`, não `all`.** Com `all`, uma única fonte que falhasse bloquearia a
consolidada indefinidamente — exatamente a armadilha silenciosa que a flag existe para
eliminar. Custo: 6 execuções extras por dia de uma query que varre 134 MB.

**`cliente` recebe o nome da conta na plataforma.** Não existe dimensão de conta do Facebook
equivalente à `trs_google_ads__conta`, então não há rótulo curado para comparar. Se um dia
existir, a coluna passa a vir dela.

## Estado e o que falta

A transformação está publicada e com deploy limpo (`status: idle`, `deploy_failed: false`),
mas **a tabela ainda não existe**. As 7 fontes de Facebook rodam às 05:00 (SP) e a de hoje já
passou, então a primeira materialização é amanhã, 05/09, por volta das 05:00. Não foi
executada à mão por decisão da Jussara: pipeline roda só no horário agendado.

Consequência prática, pela armadilha já registrada na CLAUDE.md: **tabela no catálogo não é
tabela existente.** Enquanto não materializar, qualquer referência a ela derruba a query
inteira, não só aquele ramo.

Por isso o próximo passo — somar o Facebook ao `rfn_midia__desempenho_diario` — **só pode ser
feito depois da primeira execução**, com um `COUNT(*)` de confirmação antes.

Também continuam de pé, sem mexer: as 12 queries por cliente do Facebook (6 pares de
dimensão + insight das contas vivas, mais 8 órfãs). Aposentá-las é decisão à parte, depois de
a consolidada rodar em produção — não se apaga o que ainda não foi substituído de fato.
