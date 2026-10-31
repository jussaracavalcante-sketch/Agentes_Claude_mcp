# Frente H1 — VBOT white-label e Simples Nacional (19/10/2026)

Fonte `supabase-x0tz`. Nada de fonte tocado, nenhum cron/stream/gatilho de fonte alterado, nenhum commit. Transformacoes novas rodadas a mao (autorizado no BRIEF), 3 por vez. Conferido com `list_resources` que cada transformacao existe UMA vez (sem duplicata) antes de criar as Refined.

## A) 12 tabelas Raw -> 9 Trusted (todas materializadas, `COUNT(*)` na tabela real, cron segunda 06:00 America/Manaus, alerta ligado, deploy limpo)
| Trusted | slug | linhas = chaves | nivel | origem (Raw) |
|---|---|---:|---|---|
| trs_vbot__uso_wl_conta_mes | query-uSUb | 572 / 572 | L3 | mvw_custo_wl_uso_conta_mes + vw_consumo_vbot_faixas (mesmas 572 chaves, colunas em comum identicas) |
| trs_vbot__consumo_wl_cliente_mes | query-fz02 | 550 / 550 | L3 | vw_consumo_vbot_cliente + vw_consumo_vbot_unitarios (mesmas 550 chaves, 13 colunas identicas) |
| trs_vbot__preco_wl | query-pOn6 | 16 / 16 | L3 | meta_custo_wl_preco |
| trs_fiscal__simples_vbot_mes | query-bJwI | 18 / 18 | L3 | vw_simples_vbot_mes + vw_simples_vbot_conferencia |
| trs_fiscal__simples_vbot_cliente_mes | query-RD2A | 619 / 619 (catalogo dizia 618) | L3 | vw_simples_vbot_cliente |
| trs_fiscal__simples_vbot_nf_mes | query-AQ3H | 12 / 12 (catalogo dizia 10) | L3 | vw_simples_vbot_nf_defasagem |
| trs_fiscal__simples_vbot_nf_excecao | query-vSVV | 260 / 260 (catalogo dizia 259) | L3 | vw_simples_vbot_nf_excecoes |
| trs_fiscal__simples_anexo3_faixa | query-yC3x | 6 / 6 | L2 | meta_simples_anexo3 |
| trs_fiscal__simples_receita_declarada | query-aQ8u | 13 / 13 | L3 | meta_simples_rpa_declarada |

Valores conferidos na tabela real: custo_helena do uso R$ 298.702,92; custo liquido por cliente R$ 280.919,62; DAS simulado somado dos clientes R$ 168.511,24; excecoes R$ 354.209,65; receita declarada R$ 1.026.446,17.

**O Simples esta declarado como SIMULACAO NAO CONFERIDA em maiusculas nas descricoes, e cada linha das duas tabelas de simulacao carrega `natureza = 'SIMULACAO_NAO_CONFERIDA'`** (regra BLOQUEANTE da suite).

## B) Refined (5, todas materializadas e conferidas contra a Trusted)
| Refined | slug | linhas | nivel | gatilho | identidade medida na tabela real |
|---|---|---:|---|---|---|
| rfn_financeiro__custo_wl_mensal | query-VAZA | 8 | L3 | all em uSUb + fz02 | fatura R$ 280.881,21; liquido por cliente R$ 280.919,62; identidade fecha 8 de 8; dif. de instancia R$ 38,41 em 6 periodos |
| rfn_financeiro__preco_wl_resumo | query-nuwZ | 9 | L3 | evento em pOn6 | 16 faixas = 16; 3 cortesias, 4 abertas |
| rfn_financeiro__mix_produto_vbot_mensal | query-xWNR | 21 | L3 | evento em uMba (Trusted ja existente) | 1.475 linhas; MRR R$ 725.972,79 |
| rfn_operacao__conexa_dominio_resumo | query-6Y5l | 8 | L2 | evento em RC2E (Trusted ja existente) | 329 itens = 329 |
| rfn_fiscal__simples_vbot_mensal | query-hJmB | 18 | L3 | all nas 6 Trusted fiscais | 619 clientes; DAS clientes R$ 168.511,24; backlog vigente 86 = R$ 95.985,78 |

As 5 Trusted que estavam sem Refined (trs_custo_wl__conta/fatura/instancia, trs_vbot__mix_produto_mes, trs_conexa__dominio) conferidas por `grep` em `sql/refined`: nenhuma era lida por Refined. Agora todas sao.

## C) Suite rfn_qualidade__regra_vbot_wl_simples (query-ExE6, L2, evento "all" nas 5 Refined, alerta ligado)
**Primeira execucao real (19/10 16:13Z): 69 regras, 69 ids distintos, 56 BLOQUEANTE + 13 ALERTA, 69 CONFORME, zero falha.**
- Cobre 12 Trusted e 5 Refined: unicidade, identidades Refined x Trusted, decomposicoes, fidelidade do metodo da origem, governanca (natureza simulacao), linhas de base com limiar medido e frescor semanal.
- Linhas de base (limiar medido): dias_de_contrato 569/572 (0,99); atendimentos medidos 527/550 (0,90); cliente com match por nome 522/550 (0,90); excecao existe e vigente no Conexa 260/260 (0,98).

## O que ficou de fora, com o motivo medido
- Nada das 12 tabelas Raw ficou sem tratar. Doze viraram nove Trusted porque os pares sao a mesma chave com colunas em comum identicas (zero divergencias).
- Raw `vw_custo_wl_*` (fechamento, marginal, rateio_check, sem_receita, conferencia) ja estavam declaradas derivadas na triagem de 18/10; nao refeitas.
- Nenhuma regra de futuro contra o relogio (criterio de 01/10).
- `trs_vbot__uso_wl_conta_mes` nao multiplica `app_*` pelo preco: a unidade nao e a da tabela de preco (R$ 16.749,20 contra custo_apps R$ 651,30 em 2026-01).

## Erros meus, corrigidos no mesmo dia
1. A descricao da suite afirmou que trs_custo_wl__* , o mix e o dominio ja tinham regra em outras suites. Conferido por busca: so a fatura e o mix tinham. Foram acrescentadas 7 regras (r_extra) e a descricao reescrita.
2. A faixa de `dif_das_mes_menos_clientes` saiu errada duas vezes no cabecalho da Refined fiscal (primeiro -R$ 964,68 por eu ter omitido julho; depois um ajuste meu errado). Valor medido: de -R$ 52,01 (2025-12) a -R$ 1.051,32 (2026-07). Cabecalho corrigido; a descricao publicada ja nasceu com o valor certo.
3. Cabecalhos de rascunho: "is_ativo existe em 4 dos 8 dominios" (sao 6) e "4 periodos x 7 pares" no mix (sao 21 grupos). Corrigidos antes de publicar.
4. `execute_sql` com `UNION ALL` devolveu uma linha so (limite conhecido): refeito com `STRING_AGG`.
5. Tentei a conferencia de `trs_fiscal__simples_receita_declarada` antes de a ultima Trusted terminar (`table_not_materialized`): esperei o run e refiz.

## Observacoes que nao sao minhas e nao foram alteradas
- `trs_custo_wl__instancia_mensal` (cabecalho: "18 linhas repetem a chave") marca `flag_chave_repetida` em 31 linhas (18 repeticoes extras dentro de grupos que somam 31). Texto de outra frente; nao alterado.
- `trs_vbot__consumo_wl_cliente_mes` e `trs_vbot__uso_wl_conta_mes` dependem do mesmo congelamento do custo (ultimo periodo 2026-08).
- As 5 Refined e a suite usam `event_rule = all`; o CLAUDE.md registra que `all` ja travou uma vez em `pending_events`. A regra de frescor da propria suite mede a premissa.

## Arquivos gravados
sql/trusted: trs_vbot__uso_wl_conta_mes, trs_vbot__consumo_wl_cliente_mes, trs_vbot__preco_wl, trs_fiscal__simples_vbot_mes, trs_fiscal__simples_vbot_cliente_mes, trs_fiscal__simples_vbot_nf_mes, trs_fiscal__simples_vbot_nf_excecao, trs_fiscal__simples_anexo3_faixa, trs_fiscal__simples_receita_declarada (.sql)
sql/refined: rfn_financeiro__custo_wl_mensal, rfn_financeiro__preco_wl_resumo, rfn_financeiro__mix_produto_vbot_mensal, rfn_operacao__conexa_dominio_resumo, rfn_fiscal__simples_vbot_mensal, rfn_qualidade__regra_vbot_wl_simples (.sql)
docs/nekt: vbot-wl-simples-2026-10-19.md (copia deste relatorio)
