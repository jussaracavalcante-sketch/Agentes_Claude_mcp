# `rfn_operacao__blog_mensal` — o primeiro confronto entre dois registros da mesma entrega

**Publicada em 2026-09-29** · `query-9lxy` · Refined / `operacao` · **573 linhas** ·
**L2 INTERNAL** · gatilho de evento em `query-8JWf` · alerta ligado · deploy limpo.

Grão: **uma conta de atendimento em um mês de competência**. Chave `id_blog_mensal`
(`<id_atendimento>:<mes>`), **573 para 573 linhas**.

Origens: `trs_vjob__blog_pauta` (1.323) · `trs_vjob__escopo` (só as linhas citadas) ·
`trs_vjob__cliente_atendimento` (310).

A `trs_vjob__blog_pauta` é **a única tabela desta base que liga uma entrega à linha de
escopo que a pediu**, e estava sem nenhuma Refined lendo.

---

## A ponte com o escopo é coerente pelos dois lados, não só pelo id

Antes de usar a ligação, ela foi conferida além do join:

- **1.182 de 1.183** pautas com `id_escopo` resolvem (1 órfã).
- **O escopo é sempre do serviço `BLOGS`** — 1.182 de 1.182, **um único `id_servico`**.
- **A competência bate em 1.182 de 1.182, zero divergências** entre o `mes_referencia`
  da pauta e a `competencia` do escopo.

Um id que resolve prova apenas que o número existe do outro lado. Serviço e competência
concordando provam que é **a mesma linha de trabalho**.

---

## O achado: conclusão de escopo não prova entrega, e a assimetria é total

| | escopo concluído | escopo não concluído |
|---|---:|---:|
| **pauta publicada** | **954** | **ZERO** |
| **pauta não publicada** | **176** | 52 |

**Não existe uma única pauta publicada cujo escopo não esteja marcado como concluído.**
A conclusão do escopo é um **superconjunto** da publicação.

E a diferença não é ruído: das **176** linhas de escopo concluído sem pauta publicada,
**101 (57%) a própria pauta declara mortas** — **66 `cancelado`** e **35 `churn`**.
Nenhuma das 66 canceladas tem link de publicação.

**Quem contar entrega de blog pela marcação do escopo conta 176 entregas que não
saíram**, 66 delas canceladas pelo próprio registro seguinte.

Isto **não contradiz** a `rfn_operacao__escopo_mensal`, que mede o que foi **marcado**.
Mede outra coisa — o que foi **entregue** — e mostra que as duas não são a mesma
pergunta. É o primeiro lugar desta base onde dois registros independentes da mesma
entrega podem ser confrontados. `qtd_escopo_concluido_com_pauta_morta` existe para esse
filtro.

---

## O denominador exclui cancelada e churn, e isso vale 11,5 pontos

Pauta retirada não é entrega falhada — mesmo mecanismo do item inativo da auditoria, que
já mudou uma taxa de 51,04% para 98,66% nesta base.

| taxa | valor |
|---|---:|
| publicação sobre as **vivas** (1.157) | **91,96%** |
| publicação sobre **todas** (1.323) | 80,42% |
| publicação **com prova** sobre as vivas | 71,91% |

`qtd_pautas` e `qtd_pautas_vivas` convivem na linha para ninguém dividir pelo
denominador errado sem perceber.

**Sem pauta viva a taxa é NULL, nunca zero** — **61 dos 573 pares (10,6%)** têm todas as
pautas canceladas ou em churn. `flag_sem_pauta_viva` acende.

---

## Três contagens de entrega convivem, da mais fraca para a mais forte

- status `publicado`: **1.064**
- publicado **com link**: **832**
- **com data válida**: **715**

E `qtd_com_link` (849) sai separada porque **17 pautas têm link sem estar publicadas**.
"Publicado" é declaração; o link é a evidência. Quem agregar tem de dizer qual usou.

---

## A relação escopo:pauta é N:1, não 1:1

1.183 pautas citam **1.115 escopos distintos**: **40 escopos recebem mais de uma pauta**,
um deles **11**. `flag_escopo_compartilhado` acende em **23 dos 573 pares**. Contar
escopo pedido pela contagem de pauta superconta.

---

## A data de publicação tinha 4 valores que não são datas

Achado ao montar a Gold, corrigido na Trusted no mesmo dia.

`publicado_em` trazia:

- **2 sentinelas `0001-01-01`** (as duas em pauta `churn`, id 595 e 596)
- **2 com o ano digitado `0205` em vez de `2025`** — `0205-02-13` (id 576) e
  `0205-02-21` (id 693), as duas em pauta `publicado` **e com link**

`tem_data_publicacao` acendia nas quatro, então a cobertura de data saía **719 quando é
715**. **Não aparece em contagem de linha nem em unicidade** — só em
`MIN(publicado_em)`, que devolvia o ano 1.

Agora: `publicado_em` só carrega data válida · `publicado_em_origem` preserva o cru ·
`flag_data_publicacao_invalida` marca as 4.

**A correção do ano fica FORA da medida, como candidato.** Duas rotas independentes dão a
**mesma** data — ler `0205` como `2025`, e completar o ano pela competência da própria
linha (2025-01 e 2025-02) — e as duas caem depois do cadastro. Mesmo corroborada, ela sai
em `candidato_data_publicacao_corrigida`, pelo precedente do telefone do SMS: **a
aritmética sozinha não promove valor a chave nem a medida**. A alternativa não tomada era
aceitar as duas direto em `publicado_em`, o que mudaria a série de publicação de
fevereiro/2025.

**A guarda na Gold tem prazo declarado:** enquanto a Trusted corrigida não materializa, é
o `IF(publicado_em < DATE '1900-01-01', NULL, …)` da Refined que faz a contagem fechar em
715. Depois da próxima carga ela é redundante e inofensiva, e fica.

---

## O módulo está parado

Último cadastro **18/12/2025**, última publicação **02/10/2025**; a janela de publicação
vai de **06/01/2024 a 02/10/2025**. Vale como histórico, não para acompanhar trabalho
corrente — mesma leitura já registrada para o Linear. **236 dos 573 pares não têm nenhuma
publicação datada.**

---

## Limitações — não contorne

1. **Não há data de PEDIDO da pauta em si.** `mes_referencia` é a competência (dia 1),
   não data de entrega, e o prazo real mora no escopo. **Pontualidade de blog não se mede
   aqui** — mede-se na `rfn_operacao__conformidade_cliente`, com outro grão.
2. **CNPJ cobre 59,9%** — 792 das 1.323 pautas, 43 documentos distintos, **241 dos 573
   pares sem documento**. Por conta de atendimento cobre tudo menos 2 órfãs.
3. **`motivo_cancelamento` é campo morto na origem** — zero preenchidos nas 108
   canceladas. Não há, em lugar nenhum desta base, por que a pauta foi cancelada.
4. **`link_iclips` (1.010 pautas) não foi resolvido contra o iClips.** É uma URL, não um
   id — a ponte existe e **não foi construída**, o que fica declarado como candidato, não
   como feito.

---

## Classificação L2, com a prova do que não atravessa

Contagens, datas, nome de conta e de cliente PJ. Os **10 analistas** e **12
cadastradores** resolvem **100%** contra `trs_vjob__usuario`, e **só a contagem distinta
atravessa** — nenhum nome de pessoa é emitido.

**Fuso:** relógio local da intranet. **Não converter.**

---

## Medido em 2026-09-29, sobre a tabela materializada

573 linhas · 573 chaves · 71 contas (2 não catalogadas) · 33 meses (2023-04 a 2025-12) ·
1.323 pautas · 1.157 vivas · 1.064 publicadas / 832 com prova / 715 com data ·
108 canceladas · 58 churn · 1.183 com escopo (1.115 distintos, 1 órfão) · 1.130 escopos
concluídos · **176 concluídos sem publicação, 101 deles com pauta morta** · **zero
publicadas sem escopo concluído** · 61 pares sem pauta viva · 23 com escopo compartilhado ·
1.010 com link do iClips · 4 classes de conta.
