# Inventário das tabelas tratadas — da conexão da Nekt até 2026-09-24

Medido com `COUNT(*)` na tabela materializada, **nunca** com o `Number of rows` do DDL do
catálogo, que é metadado antigo. As que não existem fisicamente estão declaradas como
pendentes, **não como zero**.

## Resumo

| | transformações | tabelas | linhas |
|---|---:|---:|---:|
| Trusted materializada | 69 | 69 | **6.115.687** |
| Refined materializada | 17 | 17 | **566.846** |
| Publicada, **ainda não materializada** | 11 | 11 | (11.297 + 34.482 medidos antes de publicar) |
| **Total publicado** | **97** | **97** | — |
| No repositório, **nunca publicada** | — | 1 | `trs_rh__colaborador` |

A relação é **1:1**: cada transformação escreve exatamente uma tabela. Das 97, 96 estão
ativas e 1 está aposentada (`query-ir9k`).

**As linhas da Trusted e da Refined não se somam** — a Refined deriva da Trusted.

---

## Trusted — VJOB real (`mysql-yIOn`), camada `vanguardamartech_trusted`

| tabela | slug | linhas |
|---|---|---:|
| `trs_vjob__escopo` | `query-Ty76` | 195.163 |
| `trs_vjob__cronograma_parcela` | `query-VxBS` | 10.056 |
| `trs_vjob__etapa_cliente` | `query-DYWJ` | 7.782 |
| `trs_vjob__cronograma` | `query-bc9M` | 6.774 |
| `trs_vjob__auditoria_cliente` | `query-LQ5u` | 3.025 |
| `trs_vjob__job_tarefa` | `query-tfHg` | 1.599 |
| `trs_vjob__job` | `query-4XbY` | 1.514 |
| `trs_vjob__job_responsavel` | `query-tc97` | 1.395 |
| `trs_vjob__cliente` | `query-MZdN` | 317 |
| `trs_vjob__usuario` | `query-GByA` | 272 |
| `trs_vjob__job_prazo_alteracao` | `query-l08y` | 224 |
| `trs_vjob__ia_solicitacao` | `query-GbCw` | 86 |
| `trs_vjob__ia_geracao` | `query-awpp` | 86 |
| `trs_vjob__ia_geracao_arquivo` | `query-wZoc` | 78 |
| `trs_vjob__servico` | `query-lCot` | 38 |
| `trs_vjob__ia_documento` | `query-cAhw` | 21 |
| `trs_vjob__ia_cliente_config` | `query-vqwG` | 3 |
| **17 tabelas** | | **228.433** |

## Trusted — iClips

| tabela | slug | linhas |
|---|---|---:|
| `trs_iclips__etapa` | `query-vHzW` | 514.981 |
| `trs_iclips__peca` | `query-W3zE` | 134.768 |
| `trs_iclips__peca_atributo` | `query-07tG` | 54.056 |
| `trs_iclips__projeto` | `query-8nEt` | 12.108 |
| `trs_iclips__tarefa` | `query-tF7c` | 8.829 |
| `trs_iclips__apontamento` | `query-9nws` | 5.687 |
| `trs_iclips__peca_tipo` | `query-wzIg` | 1.049 |
| **7 tabelas** | | **731.478** |

Mais duas `trs_projetos__projeto`, que são a geração anterior e continuam no ar:
`vanguardamartech_gestao_de_projetos_do_iclips` **98** (`query-hamR`, viva) e
`vanguardamartech_trusted` **99** (`query-ir9k`, **aposentada em 2026-08-21** — tabela
parada, não apontar query nova para ela).

## Trusted — Google Ads (consolidadas nas 42 fontes)

| tabela | slug | linhas |
|---|---|---:|
| `trs_google_ads__termo_busca` | `query-vdre` | 3.096.346 |
| `trs_google_ads__segmento_localizacao_usuario` | `query-pYmL` | 827.446 |
| `trs_google_ads__segmento_faixa_etaria` | `query-HAB1` | 296.566 |
| `trs_google_ads__segmento_genero` | `query-C8qO` | 143.895 |
| `trs_google_ads__insight_diario` | `query-tL4g` | 82.141 |
| `trs_google_ads__segmento_geografico` | `query-tmws` | 74.245 |
| `trs_google_ads__campanha` | `query-zF8L` | 827 |
| `trs_google_ads__conta` | `query-jHEX` | 88 |
| **8 tabelas** | | **4.521.554** |

## Trusted — Facebook Ads consolidada (`vanguardamartech_trusted_facebook_ads`)

| tabela | slug | linhas |
|---|---|---:|
| `trs_facebook_ads__insight_diario` | `query-QXqC` | 140.715 |
| `trs_facebook_ads__campanha` | `query-7aLj` | 1.233 |
| `trs_facebook_ads__conta` | `query-HCcd` | 102 |
| **3 tabelas** | | **142.050** |

**Armadilha de camada:** a consolidada é `vanguardamartech_trusted_facebook_ads`, **não**
`vanguardamartech_trusted`. Apontar para a camada errada devolve um cliente só.

## Trusted — RD Station consolidada

| tabela | slug | linhas |
|---|---|---:|
| `trs_rd_station__conversao` | `query-ehQc` | 119.528 |
| `trs_rd_station__contato` | `query-9dz7` | 108.412 |
| **2 tabelas** | | **227.940** |

## Trusted — financeiro, PI e Linear

| tabela | slug | linhas |
|---|---|---:|
| `trs_financeiro__movimento` | `query-NnxD` | 45.154 |
| `trs_pi__insercao` | `query-iX2P` | 3.348 |
| `trs_linear__issue` | `query-lhYJ` | 230 |
| **3 tabelas** | | **48.732** |

## Trusted — geração POR CLIENTE, anterior à consolidação (27 tabelas, vivas)

Continuam rodando; a R-002 proíbe mexer em fonte publicada sem pedido.

**`trs_facebook_ads__insight_diario`, uma por camada de cliente — 10 tabelas, 185.734:**
braga_veiculos 63.522 · colmeia 23.990 · acesso_saude 20.884 · patio_gourmet 15.917 ·
pmz_loja 13.674 · nova_era_boa_vista 13.578 · constroi_incorporadora 10.895 ·
nova_era (MAO) 9.239 · best_car 7.750 · nova_era_pvh 6.285

**`trs_facebook_ads__campanha`, uma por camada — 9 tabelas, 2.559:**
best_car 738 · nova_era_boa_vista 718 · patio_gourmet 556 · braga_veiculos 212 ·
colmeia 122 · pmz_loja 105 · nova_era 58 · nova_era_pvh 27 · constroi 23

**RD Station por cliente — 8 tabelas, 27.010:**
colmeia conversão 11.395 / contato 2.725 · best_car 5.794 / 5.791 ·
pmz_loja 457 / 262 · braga_veiculos 363 / 223

| **27 tabelas** | | **215.303** |

---

## Refined — camada oficial de consumo (`vanguardamartech_refined`)

| tabela | slug | linhas |
|---|---|---:|
| `rfn_operacao__peca` | `query-jdUw` | 134.768 |
| `rfn_operacao__custo_peca` | `query-VMUW` | 134.768 |
| `rfn_marketing__conversao` | `query-tESg` | 119.528 |
| `rfn_midia__desempenho_diario` | `query-skPU` | 85.487 |
| `rfn_operacao__escopo_mensal` | `query-V3c3` | 70.963 |
| `rfn_financeiro__receita_cliente_mensal` | `query-awMU` | 7.457 |
| `rfn_financeiro__rentabilidade_cliente` | `query-dGga` | 4.537 |
| `rfn_midia_off__pi` | `query-SguJ` | 3.319 |
| `rfn_operacao__job` | `query-wpYP` | 3.113 |
| `rfn_cadastro__cliente_sk` | `query-4ZDe` | 1.353 |
| `rfn_operacao__conformidade_cliente` | `query-ecYs` | 510 |
| `rfn_cadastro__cliente` | `query-65kE` | 408 |
| `rfn_cliente__contexto` | `query-2k3p` | 408 |
| `rfn_cadastro__conta` | `query-Y1Yt` | 190 |
| `rfn_qualidade__regra` | `query-wD6c` | 28 |
| `rfn_cadastro__cliente_vanguarda_comunicacao` | `query-hH5g` | 5 |
| `rfn_cadastro__cliente_vbot` | `query-NxG1` | 4 |
| **17 tabelas** | | **566.846** |

**`rfn_qualidade__regra` = 28 e não 61.** A suíte foi para 61 regras hoje; a tabela
materializada é a execução das **07:12**, com 28. As 61 valem na próxima passada da cadeia.

---

## Publicadas e AINDA NÃO materializadas — 11 tabelas

Publicar não é materializar. A prova é a execução agendada.

**VJOB — 8 tabelas.** A `mysql-yIOn` rodou hoje **11:51 → 12:43**; as oito foram publicadas
**depois** disso. Entram na próxima passada, pela ordem do gatilho de evento.

| tabela | slug | linhas medidas antes de publicar |
|---|---|---:|
| `trs_vjob__cronograma_alteracao` | `query-v4r2` | 18.932 |
| `trs_vjob__sms_notificacao` | `query-UpoG` | 11.054 |
| `trs_vjob__squad_alteracao` | `query-SLRc` | 2.332 |
| `trs_vjob__job_comentario` | `query-D6HS` | 1.311 |
| `trs_vjob__job_arquivo` | `query-8QxL` | 990 |
| `trs_vjob__comentario_arquivo` | `query-uR7K` | 754 |
| `trs_vjob__recorrencia_ocorrencia` | `query-r7ps` | 410 |
| `trs_vjob__job_recorrencia` | `query-UCso` | 30 |
| | | **35.813** |

**GitHub — 3 tabelas.** Não é esquecimento: a fonte `github-s0VO` está com
`401 Bad credentials` desde 24/09 04:10 e o gatilho de evento nunca disparou.

| tabela | slug | linhas medidas na Raw |
|---|---|---:|
| `trs_github__commit` | `query-45Rs` | 790 |
| `trs_github__pull_request` | `query-3vaR` | 16 |
| `trs_github__repositorio` | `query-UFhj` | 10 |
| | | **816** |

## No repositório e nunca publicada — 1

`sql/trusted/trs_rh__colaborador.sql`. A fonte (planilha do Farol de RH) ainda não existe na
Nekt; o arquivo declara isso no cabeçalho e não deve receber deploy.

---

## Duas ressalvas de leitura

1. **Trusted e Refined não se somam.** A Refined lê a Trusted; somar as duas conta o mesmo
   dado duas vezes.
2. **A geração por cliente e a consolidada também não se somam.** As 27 tabelas por cliente
   e as 5 consolidadas (3 Facebook + 2 RD) cobrem o mesmo dado em grãos diferentes.
   O dado de Facebook Ads e RD Station tratado nesta base é o das consolidadas.
