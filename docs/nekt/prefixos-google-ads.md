# Prefixos de tabela das camadas de Google Ads

Mapa completo, levantado em 2026-09-01. **39 de 39 fontes ativas.**

**Por que este arquivo existe:** o nome da tabela é `<prefixo><stream>` e o prefixo
**não é derivável** do nome da camada. Não há regra. Sem esta tabela, cada
expansão da Trusted vira arqueologia de catálogo.

## Mapa completo

| Camada (`database_name` sem `vanguardamartech_`) | Prefixo | Campanhas |
|---|---|---|
| `acesso_saude_google_ads` | `google_ads_acesso_saude` | 36 |
| `ola_casa_nova_g_ads` | `google_ads_ola_casa_nova` | 19 |
| `move_rental_cars_g_ads` | `google_ads_move_rental` | 22 |
| `don_watches_conta_1_g_ads` | `google_ads_don_watches_2` | 2 |
| `don_watches_conta_2` | `google_ads_watches_2` | 0 |
| `amazoncopy_g_ads` | `google_ads_amazoncopy` | 8 |
| `amz_geradores_g_ads` | `google_ads_amz_geradores` | — |
| `arena_tintas_g_ads` | `google_ads_arena_tintas` | — |
| `ba_eletrica_g_ads` | `google_ads_ba_eletrica` | 5 |
| `bigazine_g_ads` | `google_ads_bigazine` | — |
| `braga_acessorios` | `google_ads_braga_acessorios` | — |
| `braga_motorrad` | `google_ads_braga_motorrad` | 32 |
| `braga_motors_bmw_g_ads` | `google_ads_braga_bmw` | 17 |
| `braga_motors_mini` | `google_ads_braga_mini` | 27 |
| `braga_varejo` | `google_ads_braga_varejo` | 2 |
| `braga_veiculos` | `google_ads_pos_vendas` | 5 |
| `braga_yamaha_consorcios` | `google_ads_braga_yamaha_consorc` | 67 |
| `braga_yamaha_consorcios_2` | `google_ads_yamaha_2` | 8 |
| `caa` | `google_ads_caa_tintas` | 3 |
| `caa_aluminio` | `google_ads_caa_aluminio` | 6 |
| `colmeia` | `google_ads_colmeia` | 12 |
| `constroi_incorporadora_g_ads` | `google_ads_constroi` | — |
| `deb_transportadora_g_ads` | `google_ads_deb_transportadora` | — |
| `dmelo` | `google_ads_dmelo` | — |
| `doctor_mais_g_ads` | `google_ads_doctor_mais` | 7 |
| `dr_cabral_conta_1` | `google_ads_dr_cabral_1` | 38 |
| `hospital_santa_julia_g_ads` | `google_ads_h_santa_julia` | 12 |
| `millenium_g_ads` | `google_ads_millenium` | 177 |
| `pmz_escola_de_mecanicos` | `google_ads_pmz_escola_mecanicos` | 13 |
| `pmz_grupo_ecomm` | `google_ads_pmz_ecomm` | 19 |
| `pmz_loja` | `google_pmz_grupo_loja` | 156 |
| `pneu_express` | `google_ads_pneu_express` | — |
| `pneu_forte_distribuidora` | `google_ads_pneu_forte_dist` | 4 |
| `rei_das_mangueiras_g_ads` | `google_ads_rei_das_mangueiras` | — |
| `rodrix_g_ads` | `google_ads_rodrix_motos` | 1 |
| `royal_enfield` | `google_ads_royal_enfield` | 14 |
| `santo_remedio_g_ads` | `google_ads_santo_remedio` | 7 |
| `smile_pneus` | `google_ads_smile_pneus` | 1 |
| `steel_port_g_ads` | `google_ads_steel_port` | — |

## As armadilhas que este mapa expõe

- **`pmz_loja` → `google_pmz_grupo_loja`.** Nem começa com `google_ads_`. Qualquer
  varredura que filtre por esse prefixo perde a conta inteira — 156 campanhas.
- **`braga_veiculos` → `google_ads_pos_vendas`.** A fonte de Google Ads que grava
  nessa camada é a **BRAGA PÓS VENDAS**, não a Braga Veículos. A camada também tem
  tabelas de Facebook (`facebook_ads_braga_*`), o desvio de R-001 já conhecido.
- **`hospital_santa_julia_g_ads` → `google_ads_h_santa_julia`.** Abreviado.
- **`braga_yamaha_consorcios_2` → `google_ads_yamaha_2`.** Nada em comum com o nome
  da camada.
- Encurtamentos sem regra: `constroi_incorporadora` → `constroi`,
  `move_rental_cars` → `move_rental`, `pneu_forte_distribuidora` → `pneu_forte_dist`,
  `pmz_grupo_ecomm` → `pmz_ecomm`, `braga_motors_bmw` → `braga_bmw`.

Não é truncamento por comprimento: `google_ads_braga_yamaha_consorc` tem 30
caracteres e `google_ads_move_rental_cars` teria 27 e mesmo assim foi encurtado.
O prefixo é o que foi digitado na criação de cada fonte.

## Fora do escopo

As 3 da Unipar (`unipar_boa_vista`, `unipar_neo_vila`, `unipar_torres`) e os 2
rascunhos (Pneu Forte Varejo, Dr. Cabral conta 2) **não têm tabela materializada** —
nunca tiveram extração bem-sucedida. Incluí-las na união quebraria a query inteira.

## Métodos de descoberta, e o que cada um custa

| Método | Resultado |
|---|---|
| `list_layers` | inútil — devolve 20 camadas e omite as `_g_ads` |
| `INFORMATION_SCHEMA` | bloqueado: sem permissão no projeto, e por dataset falha no wrapper `EXPORT DATA` |
| tabela curinga com `_TABLE_SUFFIX` | bloqueado: *"EXPORT DATA statement cannot reference meta tables"* |
| `get_relevant_tables_ddl` com `selected_tables` | **não é teste de existência** — ignora parte da lista e responde por semelhança |
| `get_relevant_tables_ddl` com pergunta por cliente | funcionou bem: resposta grande vai para arquivo e se lê com `jq` + `grep` |
| `execute_sql` probe (`SELECT COUNT(*)`) | determinístico e barato, mas o lote inteiro falha na **primeira** tabela ausente |

O que funcionou: perguntar por cliente ao `get_relevant_tables_ddl`, extrair os
nomes do arquivo, e confirmar em lote com `execute_sql`.

## O atalho de verdade

Renomear as camadas para `<cliente>_g_ads` **e** padronizar os prefixos (item C5 das
pendências) torna o prefixo derivável e transforma toda expansão futura num laço
mecânico. Enquanto não for feito, este arquivo é a única fonte confiável — mantê-lo
atualizado a cada conta nova.
