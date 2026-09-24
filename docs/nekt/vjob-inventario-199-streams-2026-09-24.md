# VJOB real (`mysql-yIOn`) — inventário dos 199 streams

**Medido em 2026-09-24, com `COUNT(*)` em todas as 199 tabelas materializadas.** Não é
metadado do catálogo: o `Number of rows` do DDL já errou nesta base pelo menos quatro vezes
(`github_commits`, `supabase_silver_vjob_escopo`, `tarefas_tbjobs_comentarios_arquivos`,
`advisory_tbjobs_arquivos`), e por isso cada número aqui foi contado.

## O quadro

| | streams | linhas |
|---|---:|---:|
| **Total** | **199** | **354.190** |
| Com Trusted publicada | 33 | 230.976 (65,2%) |
| Descarte declarado (backup, lixeira, teste) | 11 | 11.758 |
| Vazias | 21 | 0 |
| **Sem tratamento e com linha** | **136** | **111.456 (31,5%)** |

Todos os 199 estão **habilitados**, todos são **FULL_SYNC** e 196 têm chave primária.
A concentração é extrema: `tbescopofinal` sozinha tem **195.163 linhas — 55% de tudo**, e
as 12 maiores tabelas somam 87%. **91 streams têm 10 linhas ou menos** (70 com 1 a 10, 21
vazias), o que confirma o padrão de sobre-coleta já registrado nas fontes Supabase.

## O que o inventário ACHOU, e que nenhuma outra medição tinha achado

### 1. `tbjobs_arquivos` existe e tem 688 linhas — 69% dos anexos estavam fora

A `trs_vjob__job_arquivo`, publicada horas antes neste mesmo dia, tinha **302 linhas** e a
descrição dizia, com todas as letras, que *"o módulo APOSENTADO não tem tabela de arquivo —
conferido, não suposto"*. **Não estava conferido.** Eu pedi o DDL dela **pelo nome exato** a
`get_relevant_tables_ddl` e a ferramenta devolveu **outra tabela**, sem dizer que a pedida
não estava no resultado.

**A lição, pela terceira vez nesta base:** `get_relevant_tables_ddl` com `selected_tables`
**não é busca por nome** — ela filtra candidatos semânticos e **omite em silêncio** o que não
casou. Prova de ausência é `COUNT(*)`. Casos anteriores: `ia_geracoes` (86 linhas, declarada
inexistente) e `tbjobs_comentarios` (656 linhas, achada só ao procurar pelo prefixo antigo).

Corrigida no mesmo dia: **990 linhas, 4 origens**.

### 2. Mais duas origens estavam fora, pelo mesmo mecanismo

- `tbjobs_comentarios_geral` (21) → `trs_vjob__job_comentario` foi de **1.290 para 1.311**.
  E ela trouxe junto o buraco de cadastro: **4 das 21** apontam para job que não existe.
- `tbjobs_prazo_hist_geral` (1) → `trs_vjob__job_prazo_alteracao` foi de **224 para 225**.
  A única linha é **órfã**. Vale pelo mecanismo, não pelo volume.

### 3. `acessos2` tem 47.857 linhas e é a segunda maior tabela da base

Este repositório listava `acessos2` entre as *"12 duplicatas com sufixo 2/3"* a descartar.
**`acessos` tem 1.349 linhas e `acessos2` tem 47.857** — a com sufixo é 35× maior e é o log
de acesso de verdade. É o mesmo caso do `tbetapasxclientes2`, já corrigido.
**O sufixo `2` não prova nada em nenhuma direção.** Medir antes de descartar, sempre.

Na mesma classe: `tbnoticiasextra2` (3.732 contra 460 de `tbnoticiasextra`),
`tbonboardingclientes2` (103 contra 213), `tblinks2` (84) e `tblinks3` (54) contra
`tblinks` (92), `tbatividades2` (28 contra **1**). Só `tbetapas2` (5 contra 4) e
`tbsubgrupolink2` (2 contra 3) são de fato pequenas.

### 4. Três tabelas grandes e sem tratamento que ninguém tinha olhado

- **`tbmudancas` — 18.932 linhas.** A terceira maior da base. Nenhuma medição anterior a
  menciona.
- **`sms_logs` — 11.054**, mais `sms_logs_dashboard` 63, `sms_logs_onboarding` 4 e
  `sms_logs_agenda` 0.
- **`tb_logs_squad` — 2.332** e **`tbservicoauditoria` — 1.387**.

Nenhuma delas foi caracterizada: o inventário conta linhas, não diz o que a tabela significa.

### 5. Uma família inteira de anexos de COMENTÁRIO está fora do medalhão

Grão diferente do anexo de job — o pai é o comentário, não o job:
`tarefas_tbjobs_comentarios_arquivos` 498 · `tbjobs_comentarios_arquivos` 249 ·
`advisory_tbjobs_comentarios_arquivos` 6 · `tbjobs_comentarios_arquivos_geral` 1.
**754 linhas**, nenhuma tratada.

E `tarefas_tbjobs_recorrencia_ocorrencias` (**410**) é o outro lado da
`trs_vjob__job_recorrencia`: as 30 regras geraram 410 ocorrências.

### 6. A família Conta Azul tem 2.796 linhas e nenhum tratamento

`contazul_fornecedores` 1.299 · `contazul_clientes` 661 · `contazul_servicos` 403 ·
`contazul_categorias` 382 · `contazul_vendedores` 20 · `contazul_sincronizacoes` 13 ·
`contazul_vinculos` 10 · `contazul_vendas_envios` 2 · e mais quatro com 1 linha, entre elas
as duas de OAuth (**L5**, já registradas).

## Os 21 streams vazios

`__tbjobs__` · `avaliacaocs_avaliacoes` · `ia_usuario_cliente` · `rotinas_cadastros_responsaveis` ·
`rotinas_comentarios` · `rotinas_historico` · `rotinas_lancamentos` · `sms_logs_agenda` ·
`tarefas_tbresponsaveis_externos` · `tb_servicos_servico` · `tbcheck_marcacao` ·
`tbcronograma_pedido_compra_clientes` · `tbescopos` · `tbetapasxclientes2_data_historico` ·
`tbjobs_arquivos_geral` · `tbonboardingetapas_onboarding` · `tbportaldocumentos` ·
`tbportalnotificacoes` · `tbriscos` · `tbsetupcolaborador_atividades` · `tbsetupcolaborador_itens`

**`tb_servicos_servico` continua vazia** — é a tabela de domínio de serviços do escopo, e
enquanto estiver assim o nome do serviço não existe no sistema (a `trs_vjob__servico` lê o
derivado Supabase, com `origem_do_nome` declarada).

## Os 16 streams que carregam acesso ou credencial — todos materializados

| stream | linhas | o que carrega |
|---|---:|---|
| `acessos2` | 47.857 | **L5** log de acesso |
| `acessos` | 1.349 | **L5** |
| `tarefas_tb_acl_cliente_usuario` | 486 | L3 ACL |
| `tbusuariointranet` | 272 | **L5** `senha` + prontuário de RH |
| `tbclientes_acessos` | 253 | **L5** |
| `tbrh_renovacoes` | 125 | **L4** |
| `tbportalusuarios` | 73 | **L5** `senha_hash` |
| `tarefas_tbjobs_aprovacao_inicial_tokens` | 46 | **L5** token |
| `tbpermissoes` | 8 | L3 |
| `usuario` | 7 | L4 |
| `contazul_oauth_conexoes` | 1 | **L5** access/refresh token |
| `contazul_oauth_config` | 1 | **L5** `client_secret` |
| `ia_usuario_cliente` | 0 | L3 |
| `tbportaldocumentos` | 0 | L3 |
| `tbportalnotificacoes` | 0 | L3 |

**Desabilitar stream não apaga tabela já materializada** e a exclusão é backoffice. A §31 da
arquitetura diz que secret não deve estar no Data Lake; nada disso está em Trusted ou Refined.

## Contagem completa dos 199, do maior para o menor

| stream | linhas |
|---|---:|
| `tbescopofinal` | 195.163 |
| `acessos2` | 47.857 |
| `tbmudancas` | 18.932 |
| `sms_logs` | 11.054 |
| `tbcronogramadatas` | 10.056 |
| `tbetapasxclientes2` | 7.782 |
| `tbcronograma` | 6.774 |
| `tbclientexservico` | 6.094 |
| `municipio` | 5.570 |
| `deleted_tbcronogramadatas_individual` | 3.916 |
| `tbnoticiasextra2` | 3.732 |
| `deleted_tbcronogramadatas` | 3.580 |
| `tbauditoriaclientes` | 3.025 |
| `checklist_diario` | 2.748 |
| `tbauditoriaclientes_bkp_20260120` | 2.416 |
| `tb_logs_squad` | 2.332 |
| `tbexcluidos2` | 1.435 |
| `tarefas_tbjobs_responsaveis` | 1.395 |
| `tbservicoauditoria` | 1.387 |
| `tbjobs` | 1.354 |
| `acessos` | 1.349 |
| `tarefas_tbjobs` | 1.343 |
| `tbblogs` | 1.323 |
| `contazul_fornecedores` | 1.299 |
| `tbjobs_arquivos` | 688 |
| `contazul_clientes` | 661 |
| `tbjobs_comentarios` | 656 |
| `tarefas_tbjobs_comentarios` | 620 |
| `tarefas_tbjobs_comentarios_arquivos` | 498 |
| `tarefas_tb_acl_cliente_usuario` | 486 |
| `tbnoticiasextra` | 460 |
| `tbrelatorioacoes` | 430 |
| `tarefas_tbjobs_recorrencia_ocorrencias` | 410 |
| `contazul_servicos` | 403 |
| `contazul_categorias` | 382 |
| `tbclientes` | 317 |
| `tbescopofinal_backup_202505` | 317 |
| `tbclientesatedimentos` | 310 |
| `tarefas_tbjobs_arquivos` | 293 |
| `tbcronogramadatas_analista_historico` | 282 |
| `tbusuariointranet` | 272 |
| `advisory_tbjobs` | 256 |
| `tbclientes_acessos` | 253 |
| `tbjobs_comentarios_arquivos` | 249 |
| `tbgestoresclientes` | 234 |
| `tbonboardingclientes` | 213 |
| `tbfornecedorescronograma` | 212 |
| `tbetapasxclientes` | 207 |
| `tbsetupcolaborador_status` | 198 |
| `tbjobsgeral` | 160 |
| `tbrh_renovacoes` | 125 |
| `tbjobs_prazo_hist` | 123 |
| `tbonboardingclientes2` | 103 |
| `tarefas_tbjobs_prazo_hist` | 93 |
| `tblinks` | 92 |
| `tbvideoextra` | 90 |
| `ia_geracoes` | 86 |
| `ia_solicitacoes` | 86 |
| `tblinks2` | 84 |
| `ia_geracao_arquivos` | 78 |
| `tbportalusuarios` | 73 |
| `tbescopo_public_links` | 70 |
| `tbcronograma_on_verbas` | 65 |
| `sms_logs_dashboard` | 63 |
| `tbonboardingetapas2` | 63 |
| `tbcheckin_semanal_config` | 60 |
| `tbauditorias` | 56 |
| `tbcheckin_social_media_config` | 55 |
| `tbarquivosauditoria` | 54 |
| `tblinks3` | 54 |
| `tbfuncao` | 49 |
| `tarefas_tbjobs_aprovacao_inicial_tokens` | 46 |
| `postagemblog` | 42 |
| `tbarquivosauditoria_bkp_20260120` | 36 |
| `tbchecklist` | 34 |
| `tbchecklistclientes` | 34 |
| `tbservicoatendimento` | 34 |
| `tborcamento` | 31 |
| `tarefas_tbjobs_recorrencias` | 30 |
| `tbservicoscronograma` | 30 |
| `tb_sub_servicos_servico` | 29 |
| `tarefas_tbjobs_aprovacao_inicial` | 28 |
| `tbatividades2` | 28 |
| `tbonboardingetapas` | 28 |
| `estado` | 27 |
| `tbservicosauditoria` | 27 |
| `backup_tbcronogramadatas_nfse_20260909` | 26 |
| `deleted_tbcronograma` | 26 |
| `tarefas_tbtiposdesenvolvimento` | 26 |
| `tbgaleriafotos` | 24 |
| `vmkt_atividades` | 24 |
| `vmkt_atividades_clientes` | 24 |
| `advisory_tbjobs_comentarios_clientes` | 22 |
| `ia_cliente_documentos` | 21 |
| `tbjobs_comentarios_geral` | 21 |
| `contazul_vendedores` | 20 |
| `tbsubgrupo` | 20 |
| `tbsetor` | 17 |
| `tbagendaextra` | 16 |
| `tbdownloads` | 16 |
| `local_atuacao_rh` | 15 |
| `tbagenda` | 15 |
| `tbgestores` | 15 |
| `advisory_tbjobs_comentarios` | 14 |
| `advisory_tbtiposdesenvolvimento` | 14 |
| `contazul_sincronizacoes` | 13 |
| `advisory_tbresponsaveis_externos` | 12 |
| `tbcronogramadatas_arquivos` | 11 |
| `contazul_vinculos` | 10 |
| `ia_solicitacao_anexos` | 10 |
| `advisory_tbjobs_arquivos` | 9 |
| `rotinas_cadastros` | 9 |
| `tblinkgrupo2` | 9 |
| `tbmalaextras` | 9 |
| `tbsubgrupodownload` | 9 |
| `tbtiposgeral` | 9 |
| `advisory_tbjobs_prazo_hist` | 8 |
| `tarefas` | 8 |
| `tbnoticias` | 8 |
| `tbpermissoes` | 8 |
| `tbtiposdesenvolvimento` | 8 |
| `rotinas_tipos_prazo` | 7 |
| `tbescopofinal_datas` | 7 |
| `usuario` | 7 |
| `advisory_tbjobs_comentarios_arquivos` | 6 |
| `tbescopo_distribuicao_config` | 6 |
| `tbetapasxclientes_onboarding` | 6 |
| `tbhistorico` | 6 |
| `tiposcronograma` | 6 |
| `tbcanalpublicacao` | 5 |
| `tbcategoria` | 5 |
| `tbcheck_horarios` | 5 |
| `tbetapas2` | 5 |
| `tbetapas_onboarding` | 5 |
| `tbsetorckdiario` | 5 |
| `tbsetoresauditoria` | 5 |
| `sms_logs_onboarding` | 4 |
| `tbcategoriasauditoria` | 4 |
| `tbetapas` | 4 |
| `tbexcluidos` | 4 |
| `tbfaseschecklist` | 4 |
| `tbsgisubgrupo` | 4 |
| `vmkt_setores` | 4 |
| `ia_cliente_config` | 3 |
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
| `tbescopofinalteste` | 2 |
| `tbgaleria` | 2 |
| `tbpdf_atas` | 2 |
| `tbsgigrupo` | 2 |
| `tbsubgrupolink2` | 2 |
| `avaliacaocs_clientes` | 1 |
| `checklist_diario2` | 1 |
| `contazul_empresas` | 1 |
| `contazul_oauth_conexoes` | 1 |
| `contazul_oauth_config` | 1 |
| `contazul_vendas_envios_historico` | 1 |
| `tarefas_tbjobs_comentarios_clientes` | 1 |
| `tbatividades` | 1 |
| `tbcheck_atividade` | 1 |
| `tbempresa` | 1 |
| `tbenquete` | 1 |
| `tbenqueterespostas` | 1 |
| `tbjobs_comentarios_arquivos_geral` | 1 |
| `tbjobs_prazo_hist_geral` | 1 |
| `tbmaladireta` | 1 |
| `tbmr` | 1 |
| `tbquemsomos` | 1 |
| `__tbjobs__` | 0 |
| `avaliacaocs_avaliacoes` | 0 |
| `ia_usuario_cliente` | 0 |
| `rotinas_cadastros_responsaveis` | 0 |
| `rotinas_comentarios` | 0 |
| `rotinas_historico` | 0 |
| `rotinas_lancamentos` | 0 |
| `sms_logs_agenda` | 0 |
| `tarefas_tbresponsaveis_externos` | 0 |
| `tb_servicos_servico` | 0 |
| `tbcheck_marcacao` | 0 |
| `tbcronograma_pedido_compra_clientes` | 0 |
| `tbescopos` | 0 |
| `tbetapasxclientes2_data_historico` | 0 |
| `tbjobs_arquivos_geral` | 0 |
| `tbonboardingetapas_onboarding` | 0 |
| `tbportaldocumentos` | 0 |
| `tbportalnotificacoes` | 0 |
| `tbriscos` | 0 |
| `tbsetupcolaborador_atividades` | 0 |
| `tbsetupcolaborador_itens` | 0 |
