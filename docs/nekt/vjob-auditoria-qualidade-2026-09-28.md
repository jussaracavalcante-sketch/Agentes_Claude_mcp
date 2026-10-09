# `rfn_operacao__auditoria_qualidade_mensal` — qual serviço e qual setor falham na auditoria

**Publicada em 2026-09-28** · `query-8m13` · Refined / `operacao` · **281 linhas** ·
**L2 INTERNAL** · gatilho de evento em `query-LQ5u` · alerta ligado · deploy limpo.

Fecha a lacuna que a própria `rfn_operacao__conformidade_cliente` declarou. Aquela deixou
`id_servico` fora do grão de propósito — *"não é comparável entre as origens, 1.339 valores
na auditoria contra 67 na etapa"* — então **ela responde por CLIENTE e esta responde por
SERVIÇO**. As duas se leem juntas e **não se somam**: o mesmo item entra nas duas com
recortes diferentes.

**Grão: um mês de prazo, um setor, um subserviço.** 281 linhas, 281 chaves, 3.025 itens.

## O achado: quase tudo é feito, e quase nada é feito no prazo

Conclusão sobre item **ativo**: 99,4% no Inbound · 98,4% no Social Media · **100%** em
Mídia Paga e Blog/SEO · 94,1% no Account. **Pontualidade no mesmo universo: 526 de 1.541 —
34,1%.**

| setor | feitos | no prazo | atrasados | atraso médio | mediano | máximo | > 30 dias |
|---|---:|---:|---:|---:|---:|---:|---:|
| INBOUND | 699 | 220 | 479 | 11,9 | 8 | 78 | 36 |
| SOCIAL MEDIA | 566 | 193 | 373 | 14,4 | 9 | 68 | 51 |
| MÍDIA PAGA | 129 | 60 | 69 | 14,2 | 12 | **100** | 4 |
| ACCOUNT | 111 | 38 | 73 | 16,7 | 13 | 52 | 7 |
| BLOG e SEO | 36 | 15 | 21 | **21,5** | **21** | 49 | 5 |

**103 itens atrasaram mais de 30 dias.**

**O indicador que discrimina aqui é PONTUALIDADE, não conclusão.** Conclusão está saturada
perto de 100% em todo setor — ela não separa ninguém. Quem montar painel de qualidade por
taxa de conclusão vai ver cinco setores perfeitos e nenhum problema.

## As seis regras

**R1 — o mês é o do PRAZO, nunca o da marcação.** Contar pela marcação inverte o sinal, erro
que o derivado Supabase do escopo já produziu nesta casa. Os 9 itens sem prazo entram com
`mes_referencia` NULL e `flag_sem_prazo` acesa (3 linhas do grão), nunca descartados.

**R2 — o denominador é o item ATIVO.** Item inativo não é item atrasado: saiu do checklist.
São **1.462 inativos com 2 marcados** contra 1.563 ativos com 1.543. Sem isso a taxa cai de
98,7% para 51% sem nada ter deixado de ser feito. `qtd_itens` e `qtd_itens_ativos` convivem
para quem quiser o outro denominador de olhos abertos.

**R3 — zero de conclusão não é zero, é NULL, e o mesmo vale para atraso.** Grupo sem nenhuma
marcação recebe `taxa_conclusao` NULL (7 linhas); grupo **sem nenhum item atrasado** recebe
`atraso_medio_dias`, `atraso_mediano_dias` e `atraso_max_dias` **NULL, nunca zero** — **84
das 281 linhas**. Zero seria somado e puxaria qualquer média para baixo.

**R4 — `taxa_pontualidade` tem como denominador o FEITO COM PRAZO**, não o previsto. Item não
feito não está atrasado nem pontual; item feito sem prazo não é avaliável. 1.545 feitos,
1.541 com prazo, NULL em 10 linhas.

**R5 — `SEM_SUBSERVICO` é um balde explícito, e ele é a maioria.** **1.937 dos 3.025 itens
(64%) não têm subserviço** — o catálogo traz subserviço zero (sentinela) em 318 dos 1.387
serviços. E o buraco é desigual ao extremo:

| setor | itens | sem subserviço |
|---|---:|---:|
| BLOG e SEO | 272 | **272 (100%)** |
| MÍDIA PAGA | 312 | 239 |
| INBOUND | 1.383 | 948 |
| SOCIAL MEDIA | 923 | 478 |
| ACCOUNT | 135 | **0** |

**Descartar o balde apagaria BLOG e SEO inteiro da leitura.** Por isso ele é chave, com
`flag_sem_subservico` acesa em 32 linhas.

**R6 — o serviço não entra no grão, e isso é medido.** São **1.339 serviços distintos para
3.025 itens** — 2,3 itens por serviço. Um grão por serviço seria quase 1:1 com o item e não
agregaria nada. O subserviço (26) e a categoria (4) são os níveis que agrupam;
`qtd_servicos_distintos` preserva a granularidade perdida.

## As três dimensões resolvem 100%

Zero serviço órfão, zero setor órfão e zero conta órfã em 3.025 itens — o que **não era
verdade até 24/09**, quando a Trusted apontava para as dimensões erradas. **60 itens têm
setor diferente do setor do serviço no catálogo**: o do item manda, e
`qtd_setor_diverge_do_catalogo` mantém o conflito visível em vez de escolhido em silêncio.

**Evidência é rara:** 295 dos 3.025 itens (9,8%) têm URL de evidência. `taxa_evidencia`
existe para que isso apareça — não confundir com qualidade do que foi auditado.

## Limitações — não contorne

1. **Atraso aqui é de REGISTRO ou de entrega, e a base não separa os dois.** A auditoria
   carimba quando alguém marcou, não quando o trabalho ficou pronto.
2. **46 contas não são a base da casa.** Esta auditoria cobre um recorte.
3. **Mês futuro entra, marcado** (`flag_mes_futuro`). Prazo vai até 30/09/2026.
4. **`qtd_pessoas_marcaram` é contagem distinta, não lista** — é por isso que a tabela é L2
   e não L4. Quem marcou, individualmente, fica na Trusted.
5. **BLOG e SEO tem 272 itens e só 35 ativos.** Qualquer taxa daquele setor repousa sobre 36
   conclusões; a cobertura vai junto com o número.

**FUSO:** nada se converte. A Trusted entrega o relógio local do MySQL intacto.

## Ainda não materializou

Entra na passada de domingo, depois de `query-LQ5u`. As regras de qualidade sobre ela entram
quando a tabela existir.
