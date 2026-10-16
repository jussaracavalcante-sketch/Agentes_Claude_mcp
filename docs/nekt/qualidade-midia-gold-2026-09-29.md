# A suíte das duas Gold de mídia — 30 regras

**29/09/2026.** `rfn_qualidade__regra_midia_gold` (`query-qkoF`), Refined / `qualidade`,
**L2 INTERNAL**, gatilho de evento em `query-skPU`, alerta ligado, deploy limpo.

**A casa passa a ter 294 regras em NOVE tabelas:** 84 na principal, 19 no Conta Azul, 9
no Gmail, 24 em Mídia, 37 no VJOB, 33 no iClips, 24 em Marketing, 34 em Cadastro e 30
aqui.

## O que ficava de fora

As **duas Gold de mídia** — o negócio principal da casa na camada oficial de consumo —
**89.586 linhas materializadas sem uma única regra**:

| tabela | linhas | transformação |
|---|---:|---|
| `rfn_midia__desempenho_diario` | 86.267 | `query-skPU` |
| `rfn_midia_off__pi` | 3.319 | `query-SguJ` |

A suíte de Mídia existente (`query-4tgF`, 24 regras) cobre as **Trusted** de Google e
Facebook Ads; estas duas são **Gold** e nunca foram medidas.

## Por que uma nona suíte

Somar 30 regras à suíte de Mídia exigiria reescrever aquela query inteira, e a principal
está em **57 KB e 84 regras** — é o caso declarado de *"query grande demais é query que
não se conserta"*. O contrato de colunas é idêntico ao das outras oito.

## O gatilho é um só, e as duas vêm de cadeias diferentes

`query-skPU` dispara em `query-tL4g` + `query-zF8L` com regra `"all"` (cadeia do Google
Ads); `query-SguJ` dispara em `query-iX2P` (`trs_pi__insercao`, cadeia do PI). Amarrar as
duas com `"all"` faria **uma falha em qualquer ramo impedir as 30 regras de rodar**. O
gatilho é a Gold maior, e a do PI é medida como estiver materializada.

**Pelo mesmo motivo não há regra de frescor aqui** — as duas não compartilham fonte, e uma
regra de "carga do mesmo dia" falharia **por desenho**.

## As quatro que guardam premissa declarada na própria descrição da Gold de mídia paga

**1. `desempenho_diario.grao_misto_nunca_acende`.** A descrição daquela tabela diz, com
todas as letras, que `flag_grao_misto` *"marca o caso que NÃO deve existir — se aparecer,
a premissa da Trusted caiu e há dupla contagem"*. Era afirmação medida uma vez (zero em
03/09/2026); agora é teste. **Medido: ZERO em 86.267.** BLOQUEANTE, limiar 1,00.

**2. `desempenho_diario.investimento_reproduz_os_micros`.** A regra 3 daquela tabela diz
que o investimento é somado em micros INT64 e dividido por 1e6 **só na saída** —
*"somar o FLOAT64 acumula erro"* — e que o spend do Facebook é multiplicado por 1e6 para
somar igual. Se a divisão ou a conversão de unidade escorregar, **a verba inteira muda de
ordem de grandeza e a contagem de linhas não muda**. Medido: **86.267 avaliadas, ZERO fora
de meio centavo, nas duas plataformas.**

**3. `desempenho_diario.ctr_reproduz_a_razao_dos_totais`.** A regra 4 diz que CTR, CPC,
CPM, CPA e as taxas são **recalculados dos totais** e nunca herdados linha a linha, porque
média de médias está errada. O CTR é o **único** dos derivados que reproduz a razão ao
centésimo em 100% das linhas com impressão (**80.232, zero falhas**) — e por isso é ele
que vira regra. **CPC e CPM não entraram:** divergem em 372 e 12.210 linhas por
arredondamento de duas casas sobre valores pequenos, e regra que acusa o que é legítimo
ensina a ignorar a suíte.

**4. `desempenho_diario.conversao_do_facebook_decompoe`.** A regra 8 declara que conversão
no Facebook é leads + compras + conversas iniciadas em 7 dias — uma **escolha** que muda o
CPA de R$ 8,39 para R$ 90,57, **uma ordem de grandeza**. As três parcelas ficam expostas
justamente para quem quiser refazer a conta; a regra garante que continuam somando o
total. Medido: **39.843 avaliadas, ZERO.**

**E uma quinta, do lado do PI:** `midia_off__pi.toda_linha_tem_causa`. A regra 4 daquela
tabela termina com *"VALIDADO … e ZERO em 'sem causa identificada'. Toda linha tem
causa"*. Era validação de um dia; agora é teste. Medido: **3.319 com motivo, ZERO sem.**

## As outras que guardam mecanismo medido

- **`registro_confiavel_nunca_convive_com_flag`** — a porta de entrada para consumo,
  escrita como **implicação** e não como igualdade, de propósito: a fórmula exata da
  coluna **não é observável hoje**, porque `flag_grao_misto` é FALSE em todas as linhas e
  as duas leituras candidatas dão o mesmo resultado. Uma igualdade chutada viraria falso
  positivo no dia em que a flag acender; a implicação vale sob as duas.
- **`conta_defasada_decompoe`** — o limiar de 9 dias é escolha declarada e ligada à
  cadência semanal das 46 fontes de mídia. **Se a cadência mudar, este número muda com
  ela**, e a regra é o lugar onde isso aparece. Hoje: 3.931 defasadas, zero divergência.
- **`pacing_nulo_em_orcamento_compartilhado`** — a regra 5: o teto vale para o conjunto de
  campanhas, então o consumo não se calcula.
- **`midia_off__pi.escopo_exclui_internet`** — a regra 1 usa **lista negra de um item**
  justamente para que tipo novo apareça. A regra guarda o único item da lista.
- **`midia_off__pi.venda_conta_azul_implica_a_flag`** — também implicação, não igualdade:
  `tem_conta_azul` está TRUE em **3.063** linhas e `ca_n_vendas > 0` em **440**, então a
  flag significa outra coisa. O que se pode afirmar, e se afirma, é que **venda registrada
  nunca aparece sem a flag**. Zero violações.

## As quatro linhas de base, de propósito

- **`midia_off__pi.liquido_mais_comissao_e_o_negociado`**, ALERTA 0,999. **Seria a sétima
  identidade desta casa** e a segunda a validar a aritmética de um sistema de terceiro
  (depois de `custo_reproduz_hora_vezes_valor_hora`, do iClips) — **mas ela não fecha**:
  1 PI em 3.319 diverge, o **22236**, com comissão R$ 1.000,01 contra R$ 1.000,00. É **um
  centavo**, e ele é da **origem**: a descrição da Gold declara que a comissão vem como
  `valor_comissao_veiculo` e **não é recalculada**. Por isso ALERTA e não BLOQUEANTE — o
  que se quer detectar é a divergência **crescer**. Medido: R$ 37.570.784,98 +
  R$ 9.387.156,88 = R$ 46.957.941,86 contra R$ 46.957.941,85.
- **`desempenho_diario.campanha_catalogada`**, ALERTA 0,98 contra **99,67%** (281 de
  86.267). A regra 7 daquela tabela declara que os joins são LEFT de propósito e que os
  281 pares campanha-dia vêm de **18 campanhas excluídas no Meta** — o endpoint devolve só
  as atuais, o insight guarda o histórico, e são **R$ 94.646,41** que com INNER sumiriam.
  Não é defeito: é o mecanismo **dimensão-fotografia contra fato-histórico**, já registrado
  no gestor deletado do VJOB.
- **`desempenho_diario.clique_nunca_excede_impressao`**, ALERTA 0,999 contra **4 linhas de
  86.267**. Os números vêm da plataforma e esta camada **não os recalcula**.
- **`midia_off__pi.acompanhamento_financeiro_no_pi_vivo`**, ALERTA 0,95 sobre os **3.095
  PIs vivos** (32 fora, 98,97%) — **nunca sobre a tabela inteira**, porque cancelado sem
  acompanhamento é o comportamento **correto** da view do Supabase.

## O que não entrou, e a ausência é a decisão

`desempenho_diario.conta_catalogada` — **zero órfãs hoje**, mas a dimensão de conta do
Facebook é um **snapshot congelado** de 26/08/2026, de uma fonte excluída. A regra seria
correta e inútil: a dimensão nunca mais muda por conta própria.

## Validação

A query inteira foi rodada antes de publicar: **30 regras, 30 ids distintos, CONFORME 30,
zero falhas** — com as quatro linhas de base dentro do limiar, exatamente como desenhadas.
