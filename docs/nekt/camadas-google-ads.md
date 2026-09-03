# Camadas Google Ads — inventário e plano de padronização

Levantado em 2026-08-31 varrendo o catálogo completo da Nekt
(2.261 tabelas, 23 páginas de `list_tables`) e cruzando `output_layer` das
44 fontes `google-ads-*`.

## Situação

44 fontes Google Ads: **39 ativas**, 2 drafts (`google-ads-H3hJ` Pneu Forte
Varejo, `google-ads-4YJU` Dr. Cabral conta 2) e 3 desativadas de propósito
(as três UNIPAR).

As camadas de destino foram criadas manualmente, uma por conta, e ficaram com
quatro convenções diferentes convivendo:

| Padrão | Exemplo | Quantidade |
|---|---|---|
| `<cliente>_g_ads` | `vanguardamartech_steel_port_g_ads` | 18 |
| `<cliente>_google_ads` | `vanguardamartech_acesso_saude_google_ads` | 1 |
| `<cliente>` (sem sufixo) | `vanguardamartech_dmelo` | 20 |
| camada de cliente compartilhada (R-001) | `vanguardamartech_braga_veiculos` | 3 |

Os slugs também misturam hífen e underscore (`steel-port_g_ads`,
`don_watches-conta-2`), o que não afeta consulta — o que vale em SQL é o
`database_name` — mas polui a navegação.

## Defeitos confirmados contra o dado

Não são divergências cosméticas: em três casos o nome da camada contradiz o
`customer_id` realmente gravado. Verificado lendo `resource_name`
(`customers/<id>/...`) em `*account_budget`.

| Camada | Diz ser | Contém de fato | Fonte |
|---|---|---|---|
| `vanguardamartech_don_watches_conta_1_g_ads` | Don Watches conta 1 | **conta 2** — `945-172-6644` | `google-ads-QuKh` |
| `vanguardamartech_don_watches_conta_2` | Don Watches conta 2 | **conta 1** — `855-373-3895`, **e está vazia** | `google-ads-vE2C` |
| `vanguardamartech_braga_yamaha_consorcios` | Braga Yamaha Consórcios | **Braga Yamaha / Motos** — `187-499-5593` | `google-ads-Pk69` |
| `vanguardamartech_braga_yamaha_consorcios_2` | (sufixo `_2` sobrando) | Braga Yamaha Consórcios — `421-608-6233` ✔ | `google-ads-5J1y` |
| `vanguardamartech_caa` | grupo CAA | **só CAA Tintas** — `883-795-0560` | `google-ads-mEnk` |

Os prefixos de tabela herdaram o mesmo erro: a camada de Braga Yamaha/Motos
tem tabelas `google_ads_braga_yamaha_consorc*`, e a de Don Watches conta 2 tem
`google_ads_don_watches_2*`.

**Regra prática enquanto não for corrigido:** nunca inferir a conta pelo nome
da camada nem pelo prefixo da tabela. Usar `customer_id` extraído de
`resource_name`.

### `don_watches_conta_2` vazia

A fonte `google-ads-vE2C` (Don Watches conta 1, `855-373-3895`) roda com
sucesso todo dia desde 2026-08-27, mas todas as tabelas da camada têm 0 linhas
(`campaigns`, `ad_groups`, `campaign_performance`, `account_budget`).
Run de sucesso com zero linhas ainda consome 1 crédito Nekt por dia.
Investigar se a conta tem campanhas ativas antes de manter o cron.

## Convenção adotada

`<cliente>_g_ads` — minúsculas, underscore, sem hífen, sufixo `_g_ads`.
Escolhido por ser o padrão já majoritário entre as camadas dedicadas.

Convive com R-001: fonte de cliente que **já tem catálogo próprio** grava no
catálogo do cliente (`Braga_veiculos`, `Colmeia`, `PMZ_loja`), não numa camada
`_g_ads` separada. As camadas `_g_ads` são o destino de contas cujo cliente
ainda não tem catálogo.

## Renomeações pendentes (backoffice)

Renomear camada não existe no MCP nem na API da Nekt — `GET /api/v1/layers/`
e `PATCH` só de descrição. É operação de backoffice.

Prioridade 1 — nome contradiz o conteúdo:

| De | Para |
|---|---|
| `don_watches_conta_1_g_ads` | `don_watches_conta_2_g_ads` |
| `don_watches_conta_2` | `don_watches_conta_1_g_ads` |
| `braga_yamaha_consorcios` | `braga_yamaha_g_ads` |
| `braga_yamaha_consorcios_2` | `braga_yamaha_consorcios_g_ads` |
| `caa` | `caa_tintas_g_ads` |

(as duas primeiras são uma troca; renomear uma para um nome temporário antes.)

Prioridade 2 — só padronização de sufixo:

`acesso_saude_google_ads` → `acesso_saude_g_ads`;
e acrescentar `_g_ads` em `dr_cabral_conta_1`, `unipar_torres`,
`unipar_neo_vila`, `unipar_boa_vista`, `caa_aluminio`, `dmelo`,
`braga_varejo`, `royal_enfield`, `braga_acessorios`, `braga_motors_mini`,
`braga_motorrad`, `pneu_forte_distribuidora`, `pneu_express`, `smile_pneus`,
`pmz_grupo_ecomm`, `pmz_escola_de_mecanicos`, `constroi_incorporadora_g_ads`
(já ok).

Já no padrão, nada a fazer: `steel_port_g_ads`, `ola_casa_nova_g_ads`,
`braga_motors_bmw_g_ads`, `move_rental_cars_g_ads`, `ba_eletrica_g_ads`,
`arena_tintas_g_ads`, `bigazine_g_ads`, `amazoncopy_g_ads`,
`doctor_mais_g_ads`, `hospital_santa_julia_g_ads`, `santo_remedio_g_ads`,
`amz_geradores_g_ads`, `millenium_g_ads`, `rei_das_mangueiras_g_ads`,
`deb_transportadora_g_ads`, `rodrix_g_ads`, `constroi_incorporadora_g_ads`.

## Mitigação já aplicada

Sem poder renomear, as descrições das 5 camadas com defeito foram reescritas
via `update_resource_description` em 2026-08-31, registrando o `customer_id`
real e o nome de destino. A descrição é o que a busca semântica e a IA leem,
então isso remove a leitura errada mesmo antes do rename.

## Nota sobre `list_layers`

A ferramenta MCP `list_layers` devolveu apenas 20 camadas, omitindo todas as
`_g_ads`. O inventário completo só sai paginando `list_tables` e agrupando por
`layer_id`. `INFORMATION_SCHEMA.SCHEMATA` do BigQuery está bloqueado
(sem `bigquery.datasets.get` no nível do projeto), e `INFORMATION_SCHEMA` por
dataset também falha porque a Nekt encapsula a query em `EXPORT DATA`.
