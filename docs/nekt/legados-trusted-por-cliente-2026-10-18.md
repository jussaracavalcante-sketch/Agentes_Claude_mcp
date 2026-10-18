# Trusted legadas por cliente (Facebook Ads e RD Station) e as três de projeto/usuário — 18/10/2026

Somente leitura. Nada foi desativado, alterado ou apagado. Medido em 18/10/2026 com `list_resources`, `list_pipeline_runs`,
`COUNT(*)` e `MAX(_extraido_at)` nas tabelas reais, e por busca nos 230 arquivos de `sql/trusted` e `sql/refined`.

## Resumo

| grupo | transformações | linhas | custo medido/mês | quem lê |
|---|---:|---:|---:|---|
| Facebook Ads por cliente, fontes **vivas** (semanal, terça) | 11 | 145.686 insight + 1.209 campanha | ~48 execuções | nenhum arquivo do repositório |
| Facebook Ads por cliente, fontes **arquivadas** (dado para em 31/08) | 8 | 45.019 insight + 1.359 campanha | 0 (o gatilho nunca dispara) | nenhum |
| RD Station por cliente (diária) | 8 | 9.952 contatos + 22.010 conversões | ~240 execuções | nenhum |
| `query-GByA` (`trs_vjob__usuario`) | 1 | 278 | ~30 | **22 arquivos do repositório** (não é legada) |
| `query-hamR` (`trs_projetos__projeto`) | 1 | 87 | **~180** (notebook do iClips a cada 4 h) | nenhum arquivo executável (só comentários) |
| `query-ir9k` (aposentada 21/08) | 1 | 98 (parada em 21/08) | 0 (inativa) | nenhum |

Total que roda hoje e não tem leitor no repositório: **~470 execuções/mês, 5,2% do limite de 9.000** (regra oficial: 1 crédito por
execução bem-sucedida). O RD por cliente (~240) e a `hamR` (~180) são 90% disso.

**O que o MCP não mostra:** dependências a jusante (BI, planilhas, painéis fora da Nekt). "Nenhum leitor" vale para o warehouse e o
repositório; a camada semântica não cita nenhuma delas com `@table::` nos cinco documentos mais relevantes da busca. Confirmar na
interface da Nekt (linhagem da tabela) antes de qualquer desligamento.

## Facebook Ads por cliente (19)

Substituídas pela consolidada `vanguardamartech_trusted_facebook_ads.trs_facebook_ads__insight_diario` / `__campanha` (64 contas desde
16/10), que lê a **Raw** de cada camada, não estas tabelas. As Trusted por cliente existem desde 27/08 (R-001: uma camada por fonte).

| slug | tabela (camada) | linhas | última carga | gatilho | situação |
|---|---|---:|---|---|---|
| `query-OTSI` | insight · `acesso_saude` | 21.526 | 14/10 | evento `facebook-ads-Si4U` | viva |
| `query-KVas` | insight · `braga_veiculos` (2 contas) | 64.464 | 14/10 | evento `all` kQ2S+GWZ2 | viva |
| `query-9UYP` | insight · `pmz_loja` | 14.571 | 14/10 | evento `facebook-ads-x4yO` | viva |
| `query-mMpX` | insight · `constroi_incorporadora` | 11.463 | 14/10 | evento `facebook-ads-oB7d` | viva |
| `query-S9Xr` | insight · `colmeia` | 25.210 | 14/10 | evento `facebook-ads-ln1a` | viva |
| `query-qD5G` | insight · `best_car` | 8.452 | 14/10 | evento `facebook-ads-E9RT` | viva |
| `query-U0xi` | insight · `patio_gourmet` | 15.917 | 31/08 | evento `facebook-ads-uJNk` (arquivada) | dormente |
| `query-7WB2` | insight · `nova_era_pvh` | 6.285 | 31/08 | evento `facebook-ads-5HRd` (arquivada) | dormente |
| `query-ktuL` | insight · `nova_era_boa_vista` | 13.578 | 31/08 | evento `facebook-ads-vVCz` (arquivada) | dormente |
| `query-IEGX` | insight · `nova_era` | 9.239 | 31/08 | evento `facebook-ads-MhGm` (arquivada) | dormente |
| `query-zN5N` | campanha · `braga_veiculos` | 212 | 14/10 | evento `all` kQ2S+GWZ2 | viva |
| `query-h76q` | campanha · `pmz_loja` | 114 | 14/10 | evento `facebook-ads-x4yO` | viva |
| `query-5apT` | campanha · `constroi_incorporadora` | 23 | 14/10 | evento `facebook-ads-oB7d` | viva |
| `query-MHyi` | campanha · `colmeia` | 122 | 14/10 | evento `facebook-ads-ln1a` | viva |
| `query-Acup` | campanha · `best_car` | 738 | 14/10 | evento `facebook-ads-E9RT` | viva |
| `query-0S73` | campanha · `patio_gourmet` | 556 | 31/08 | evento `facebook-ads-uJNk` | dormente |
| `query-6By7` | campanha · `nova_era_boa_vista` | 718 | 31/08 | evento `facebook-ads-vVCz` | dormente |
| `query-iUZG` | campanha · `nova_era_pvh` | 27 | 31/08 | evento `facebook-ads-5HRd` | dormente |
| `query-Qhmq` | campanha · `nova_era` | 58 | 31/08 | evento `facebook-ads-MhGm` | dormente |

(Acesso Saúde não tem tabela de campanha por cliente: são 9 de campanha e 10 de insight.) As onze vivas rodam uma vez por semana
(~4,35/mês cada, ~48 no total; `OTSI` e `KVas` tiveram uma execução extra em 14/10, a passada manual). As oito dormentes não custam
nada, mas seguem ativas e ficariam no inventário para sempre. A Nova Era está marcada como desativada desde 05/10 e o Pátio Gourmet
saiu da agência em 16/10.

## RD Station por cliente (8)

Substituídas por `vanguardamartech_trusted.trs_rd_station__contato` e `__conversao` (48 fontes, 260.033 contatos), que leem a Raw.
Cada par grava na camada do cliente (`braga_veiculos`, `best_car`, `pmz_loja`, `colmeia`) e dispara por evento na fonte RD **diária**.

| slug | tabela · camada | linhas | última carga | gatilho |
|---|---|---:|---|---|
| `query-mksA` | contato · `best_car` | 5.837 | 18/10 | evento `rd-station-pG4G` |
| `query-Zng7` | conversão · `best_car` | 5.853 | 18/10 | evento `rd-station-pG4G` |
| `query-mLxg` | contato · `pmz_loja` | 355 | 18/10 | evento `rd-station-bdVN` |
| `query-T9Gl` | conversão · `pmz_loja` | 587 | 18/10 | evento `rd-station-bdVN` |
| `query-sbEw` | contato · `braga_veiculos` | 324 | 18/10 | evento `rd-station-WHAa` |
| `query-01Je` | conversão · `braga_veiculos` | 502 | 18/10 | evento `rd-station-WHAa` |
| `query-g8mN` | contato · `colmeia` | 3.436 | 18/10 | evento `rd-station-VYbu` |
| `query-Y2zz` | conversão · `colmeia` | 15.068 | 18/10 | evento `rd-station-VYbu` |

`query-mksA` tem 54 execuções desde 27/08, uma por dia. ~30/mês cada, **~240/mês** no total, o maior item desta lista. São cópias de
dado pessoal (e-mail, telefone, base legal LGPD, L4) em quatro camadas de cliente além da consolidada; a exclusão de titular, que já
não funciona na consolidada, tampouco alcança estas cópias.

## As três de projeto e usuário

- **`query-GByA` → `vanguardamartech_trusted.trs_vjob__usuario`** (278 linhas, carga 17/10). Não é legada: 22 arquivos de `sql/` a leem
  (squad, acesso, job, cronograma…). Lê o derivado Supabase (`supabase_bronze_vjob__tbusuariointranet`), evento em `supabase-x0tz`,
  diária. **Estava sem arquivo no repositório e com alerta de falha desligado**: arquivo gravado em `sql/trusted/trs_vjob__usuario.sql`
  e alerta ligado hoje.
- **`query-hamR` → `vanguardamartech_trusted.trs_projetos__projeto`** (87 linhas, carga 18/10 13:01 UTC; eram 106 em 18/09, a janela do
  notebook encolhe). Superada por `trs_iclips__projeto` (12.109 projetos). Nenhum `.sql` a lê; as menções em `trs_pi__insercao.sql`,
  `trs_iclips__projeto.sql` e `rfn_qualidade__regra_pi.sql` são comentários históricos. **Roda a cada 4 horas** (cron do notebook
  `notebook-Rbpo` mudou para `0 */4` em 07/10): 111 execuções registradas, ~180/mês. Estava sem arquivo: gravado em
  `sql/trusted/trs_projetos__projeto.sql`. A descrição dela diz "ainda há leitores apontados para cá" (16/09); **não foi possível
  confirmar nenhum**.
- **`query-ir9k`** (aposentada em 21/08, `active=false`): a tabela `vanguardamartech_gestao_de_projetos_do_iclips.trs_projetos__projeto`
  tem 98 linhas paradas em 21/08. Quem resolve a tabela pelo nome da camada pega esta, a morta. Não custa execução.

## Recomendação (decisão dela; nada executado)

1. **RD por cliente (8) é o maior ganho e o menor risco:** ~240 execuções/mês (2,7% do limite) para uma cópia sem leitor de dado pessoal.
   Desativar os 8 gatilhos (`active=false`, sem apagar tabela) e deixar a consolidada como única.
2. **`hamR` (~180/mês, 2%):** confirmar na linhagem da Nekt que nenhum painel lê `trs_projetos__projeto`; se ninguém ler, desativar. Se
   houver leitor, repontar para `trs_iclips__projeto` antes (mesmas colunas de projeto, mais campos).
3. **Facebook por cliente (19):** desativar as 8 dormentes (custo zero, só higiene) e as 11 vivas (~48/mês) depois de a Trusted
   consolidada rodar com as 64 contas (20/10) e a suíte `rfn_qualidade__regra_meta_ads` confirmar 23/23.
4. **Nenhuma tabela deve ser apagada agora:** camada só sai vazia, o Facebook só re-extrai 37 meses (Nova Era e Pátio Gourmet têm
   histórico que acaba em 31/08/2026, anterior ao lookback), e apagar tabela é backoffice. Desativar o gatilho já resolve o custo.
5. **`ir9k` e a `trs_projetos__projeto` da camada `gestao_de_projetos_do_iclips`:** candidatas a exclusão pela interface; são o caso
   de "mesmo nome, camada morta".
6. Somando 1+2+3, o regime cai de ~7.600 para ~7.100 execuções/mês, folga para a expansão planejada (+287/+871).

Desativar gatilho de transformação criada pela casa não é R-002 (essa regra protege fonte publicada), mas é mudança de comportamento
e entra na categoria "pedido explícito" por prudência.
