# 02/10 — quanto falta para finalizar o tratamento das fontes

Medido em 2026-10-02. Duas visões: por **fonte** (99 cadastradas) e por **stream** do `mysql-yIOn` (199).

## Por fonte (99)

| situação | fontes | % |
|---|---:|---:|
| Tratadas até a Refined | 83 | 83,8% |
| Tratadas só até a Trusted (`rest-api-xk4P`, `google-ads-wypN`) | 2 | 2,0% |
| **Tratadas no total** | **85** | **85,9%** |
| Sem o que tratar, medido (`supabase-fEvu`, `supabase-3gKz`, `rd-station-socq`, `rd-station-1eaJ`, `rd-station-bjQx`, `google-ads-vE2C`) | 6 | 6,1% |
| Bloqueadas (`github-2Upt` 0 linhas, `webhook-v2-nZdJ` Z-API 0 linhas, `facebook-pages-ftS8` nunca rodou, `google-ads-OzfZ` sem permissão) | 4 | 4,0% |
| Desativadas (`semrush-OnLY`, `rd-station-YLIU`, `google-ads-H3hJ`, `google-ads-4YJU`) | 4 | 4,0% |

Elegíveis (sem desativadas e sem as 6 sem dado): 89. Tratadas: 85 (95,5%). Faltam 4, todas dependem de credencial, permissão ou decisão.
Conferido em banco: Google Ads 40 fontes no insight diário, Facebook 7, RD 30 em contato e conversão. O restante vem da cadeia medida nos dias anteriores.

## Por stream do `mysql-yIOn` (199, COUNT(*) em cada tabela)

| situação | streams | linhas | % das linhas |
|---|---:|---:|---:|
| Tratados (tabela citada por alguma Trusted ou Refined) | 68 | 329,290 | 92,8% |
| Descarte declarado (backup, lixeira, teste) | 11 | 11.770 | 3,3% |
| Decidido não tratar, com medição | 13 | 11.097 | 3,1% |
| Credencial ou segredo (L5), não tratar | 13 | 1.289 | 0,4% |
| Vazios | 15 | 0 | 0,0% |
| **Sem tratamento e com linha** | **79** | **1.281** | **0,4%** |

Por stream, 34,2% estão tratados; por volume, 92,8%. Dos 147 streams elegíveis (fora descarte, decididos, credencial e vazios), 68 estão tratados (46,3%) e 79 faltam, **todos com 92 linhas ou menos**, 1.281 linhas no total. É cauda de tabelas pequenas de domínio, configuração e links.

### Os 79 que faltam (linhas)

| stream | linhas |
|---|---:|
| `tblinks` | 92 |
| `tbvideoextra` | 90 |
| `tblinks2` | 84 |
| `tbescopo_public_links` | 70 |
| `sms_logs_dashboard` | 63 |
| `tbonboardingetapas2` | 63 |
| `tbcheckin_semanal_config` | 60 |
| `tbcheckin_social_media_config` | 55 |
| `tblinks3` | 54 |
| `tbfuncao` | 49 |
| `postagemblog` | 42 |
| `tbchecklistclientes` | 34 |
| `tbservicoatendimento` | 34 |
| `tb_sub_servicos_servico` | 29 |
| `tbatividades2` | 28 |
| `tbonboardingetapas` | 28 |
| `tarefas_tbtiposdesenvolvimento` | 26 |
| `tbgaleriafotos` | 24 |
| `tbsubgrupo` | 20 |
| `tbsetor` | 17 |
| `tbagendaextra` | 16 |
| `tbdownloads` | 16 |
| `local_atuacao_rh` | 15 |
| `tbagenda` | 15 |
| `advisory_tbtiposdesenvolvimento` | 14 |
| `contazul_sincronizacoes` | 13 |
| `advisory_tbresponsaveis_externos` | 12 |
| `tbcronogramadatas_arquivos` | 11 |
| `ia_solicitacao_anexos` | 10 |
| `rotinas_cadastros` | 9 |
| `tblinkgrupo2` | 9 |
| `tbmalaextras` | 9 |
| `tbsubgrupodownload` | 9 |
| `tbtiposgeral` | 9 |
| `tarefas` | 8 |
| `tbnoticias` | 8 |
| `tbtiposdesenvolvimento` | 8 |
| `rotinas_tipos_prazo` | 7 |
| `tbescopofinal_datas` | 7 |
| `tbescopo_distribuicao_config` | 6 |
| `tbhistorico` | 6 |
| `tiposcronograma` | 6 |
| `tbcanalpublicacao` | 5 |
| `tbcategoria` | 5 |
| `tbcheck_horarios` | 5 |
| `tbetapas2` | 5 |
| `tbetapas_onboarding` | 5 |
| `tbsetorckdiario` | 5 |
| `sms_logs_onboarding` | 4 |
| `tbetapas` | 4 |
| `tbfaseschecklist` | 4 |
| `tbsgisubgrupo` | 4 |
| `tb_categoria_servico` | 3 |
| `tbenqueteextras` | 3 |
| `tbferiados` | 3 |
| `tbgrupo` | 3 |
| `tblinkgrupo` | 3 |
| `tbsgi` | 3 |
| `tbsubgrupolink` | 3 |
| `contazul_vendas_envios` | 2 |
| `ia_provedores` | 2 |
| `quinzena` | 2 |
| `tbclientescronograma` | 2 |
| `tbdownloadgrupo` | 2 |
| `tbgaleria` | 2 |
| `tbpdf_atas` | 2 |
| `tbsgigrupo` | 2 |
| `tbsubgrupolink2` | 2 |
| `avaliacaocs_clientes` | 1 |
| `contazul_vendas_envios_historico` | 1 |
| `tarefas_tbjobs_comentarios_clientes` | 1 |
| `tbatividades` | 1 |
| `tbcheck_atividade` | 1 |
| `tbempresa` | 1 |
| `tbenquete` | 1 |
| `tbenqueterespostas` | 1 |
| `tbmaladireta` | 1 |
| `tbmr` | 1 |
| `tbquemsomos` | 1 |

## Ressalvas

- "Tratado" aqui é: alguma transformação do repositório (fora as suítes de qualidade) cita a tabela. Inclui dimensão lida por join, não só Trusted dedicada. A medição de 24/09 (33 streams com Trusted) usava critério mais estrito, então os números não são comparáveis um a um.
- Repositório e deploy foram tratados como iguais; não conferi cada Trusted contra `get_code` nem a materialização das 41 tabelas.
- Contagens variaram em relação a 24/09 porque a origem andou (ex.: `tbescopofinal` 195.161, `acessos2` 48.083).
- `acessos` e `acessos2` estão no grupo tratado (`trs_vjob__acesso`, só log de evento), por isso não entram em credencial.
