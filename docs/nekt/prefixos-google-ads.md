# Prefixos de tabela das camadas de Google Ads

Estado em 2026-09-01. Arquivo de trabalho para a expansão da Trusted.

**Por que este arquivo existe:** o nome da tabela é `<prefixo><stream>`, e o
prefixo **não é derivável** do nome da camada. Não há regra — há exceções demais.
Sem esta tabela, cada expansão da Trusted vira arqueologia de catálogo.

## Confirmados (16 de 39)

Os 5 já na Trusted, mais 11 descobertos.

| Camada (`database_name` sem `vanguardamartech_`) | Prefixo | Como foi confirmado |
|---|---|---|
| `acesso_saude_google_ads` | `google_ads_acesso_saude` | em produção |
| `ola_casa_nova_g_ads` | `google_ads_ola_casa_nova` | em produção |
| `move_rental_cars_g_ads` | `google_ads_move_rental` | em produção — **perde o `_cars`** |
| `don_watches_conta_1_g_ads` | `google_ads_don_watches_2` | em produção — **camada diz 1, guarda a conta 2** |
| `don_watches_conta_2` | `google_ads_watches_2` | em produção — **os dois prefixos dizem "2"** |
| `steel_port_g_ads` | `google_ads_steel_port` | `list_tables` |
| `constroi_incorporadora_g_ads` | `google_ads_constroi` | catálogo — **encurtado** |
| `amz_geradores_g_ads` | `google_ads_amz_geradores` | catálogo |
| `arena_tintas_g_ads` | `google_ads_arena_tintas` | catálogo |
| `bigazine_g_ads` | `google_ads_bigazine` | catálogo |
| `braga_acessorios` | `google_ads_braga_acessorios` | catálogo |
| `deb_transportadora_g_ads` | `google_ads_deb_transportadora` | catálogo |
| `dmelo` | `google_ads_dmelo` | catálogo |
| `pneu_express` | `google_ads_pneu_express` | catálogo |
| `rei_das_mangueiras_g_ads` | `google_ads_rei_das_mangueiras` | catálogo |

## A descobrir (24)

Palpite = `google_ads_` + nome da camada sem `_g_ads`. **Não confiar** — o palpite
já falhou em `move_rental_cars`, `constroi_incorporadora` e nas duas Don Watches.

`ba_eletrica_g_ads`, `braga_motorrad`, `braga_motors_bmw_g_ads`,
`braga_motors_mini`, `braga_varejo`, `braga_veiculos`, `braga_yamaha_consorcios`,
`braga_yamaha_consorcios_2`, `caa`, `caa_aluminio`, `colmeia`, `doctor_mais_g_ads`,
`dr_cabral_conta_1`, `hospital_santa_julia_g_ads`, `millenium_g_ads`,
`pmz_escola_de_mecanicos`, `pmz_grupo_ecomm`, `pmz_loja`,
`pneu_forte_distribuidora`, `rodrix_g_ads`, `royal_enfield`, `santo_remedio_g_ads`,
`smile_pneus`, `amazoncopy_g_ads`

## Fora do escopo

As 3 da Unipar (`unipar_boa_vista`, `unipar_neo_vila`, `unipar_torres`) e os 2
rascunhos (Pneu Forte Varejo, Dr. Cabral conta 2) não têm tabela materializada —
nunca tiveram extração bem-sucedida. Incluí-las na união quebraria a query inteira.

## Métodos de descoberta, e o que cada um custa

| Método | Resultado |
|---|---|
| `list_layers` | inútil — devolve 20 camadas e omite as `_g_ads` |
| `INFORMATION_SCHEMA` | bloqueado: sem permissão no projeto, e por dataset falha no wrapper `EXPORT DATA` da Nekt |
| `get_relevant_tables_ddl` com `selected_tables` | **não é teste de existência** — ignora parte da lista e devolve por semelhança. Confirmou 8 de 34 e omitiu `steel_port`, que existe |
| `list_tables` paginado | determinístico e completo, mas são 23 páginas de 100 tabelas |
| `execute_sql` probe (`SELECT COUNT(*)`) | determinístico, resposta minúscula, **1 tabela por chamada** |

## O atalho de verdade

Renomear as camadas para o padrão `<cliente>_g_ads` (item C5 das pendências)
resolve isso de uma vez: com nome previsível, o prefixo passa a ser derivável e
toda expansão futura da Trusted vira um laço mecânico em vez de arqueologia.
Enquanto não for feito, cada conta nova custa uma descoberta manual.
