# 01/10 — a camada semântica ganhou os SEIS inventários de domínio da Refined, e um índice

**Medido e publicado em 2026-10-01.** Começou com o inventário da manhã achando duas Refined
materializadas sem registro (`docs/nekt/cobertura-de-qualidade-2026-10-01.md`) e terminou com
a camada oficial de consumo inteira descrita onde a §17 manda ela morar.

## O buraco

A §17 do ADR-0010 manda a definição oficial morar na camada semântica e a §18 diz que a IA
consome **Gold e Semantic Layer**. Em 29/09 a camada ganhou dois documentos de Refined — as
regras de leitura (`ac85112a`) e o inventário de **operação** (`ce20aecc`). **Os outros cinco
domínios não tinham nenhum**, e as duas tabelas achadas hoje não apareciam em lugar nenhum.

**Ressalva de método, a mesma de 25/09:** busca semântica devolve os N mais relevantes e
**não é prova de ausência** — não existe `COUNT(*)` para documento de contexto, ao contrário
do que vale para tabela.

## Os sete documentos

| documento | id | tabelas |
|---|---|---|
| **Índice — os seis inventários de domínio da Refined** | `8f8ed60e-4bcb-4eda-ac87-e46c4629e095` | — |
| **Mídia — as 5 Refined: qual responde, e qual NÃO fecha a verba** | `9cd50802-7c58-4d22-842f-723a28f11d92` | 5 |
| **Cadastro e identidade — as 6 Refined de cliente** | `cf0bbeed-7bb8-4668-b24a-f10e6f4a7af0` | 6 |
| **Financeiro — as 6 Refined: margem, receita, caixa e inadimplência** | `a237708d-9271-47ba-90eb-822ed8bd679f` | 6 |
| **Marketing — a Refined de conversão** | `fcd7d6fb-94c0-445c-873a-9d3b7a89cd2c` | 1 |
| **Qualidade — as 12 suítes** | `2da109d6-5f57-4467-a8cc-0619a9dd69f1` | 12 |
| **Operação — as 17 Refined** (atualizado) | `ce20aecc-a44e-4a40-be06-b3f4099cd732` | 17 |

**Todos verificados indexados no mesmo dia**, com buscas usando o vocabulário distintivo de
cada um — mídia e cadastro em 1º e 2º lugar, financeiro em 3º, marketing em 4º, qualidade em
1º.

## O eixo de cada documento

**Mídia — só UMA das cinco totaliza verba.** As tabelas parecem intercambiáveis pelo nome e
não são: `rfn_midia__desempenho_diario` (86.267) é a única; termo cobre **61,2%** da verba de
busca em BRL, segmento **80,8%**, localização **93,4%**. E as duas armadilhas de soma entraram
juntas porque são a mesma lição por dois lados: `local_e_alvo` **PARTICIONA** e
`tipo_localizacao` **DUPLICA** na mesma tabela; `tipo_segmento` é **FILTRO, nunca group by** —
somar as 7.886 linhas dá **~4× a verba real**.

**Cadastro — o cliente entra por DOCUMENTO, nunca por nome**, com as três medições que
sustentam a regra no topo. E o documento fixa a divisão de trabalho da aplicação conectada,
que é o motivo de a `rfn_cliente__contexto` existir: `execute_sql` para fato estruturado,
`get_semantic_context` para prosa, volume para binário. **Pedir o hex da paleta de um cliente
à busca semântica não funciona**, e a tabela não finge ter a coluna.

**Financeiro — a pergunta que decide a tabela é COMPETÊNCIA ou CAIXA.** Os dois conjuntos se
sobrepõem de 2025-12 a 2026-05 e **não são versões do mesmo número**. O documento traz a
prova em três caminhos de que a receita de mídia é **comissão** (e portanto `margem_total` é
A margem, +R$ 5.833.203,89), a regra de usar as colunas de **janela** para ranking, e a
limitação que manda: **o caixa realizado começa em 25/05/2026** e série anterior não existe
em lugar nenhum deste warehouse.

**Marketing — o primeiro filtro não é de data nem de cliente.** **76,8% da base é carga em
lote**, importação para dentro do RD, não conversão. Qualquer leitura de resultado começa por
`carga_em_lote = FALSE`.

**Qualidade — como saber se o dado é confiável.** Doze suítes, contrato de colunas idêntico,
`familia` dizendo de onde veio cada linha. O documento explica **por que são doze e não uma**
(a principal tem 57 KB e `update_transformation` substitui o código inteiro), lista as **oito
identidades contábeis**, e declara as três doutrinas que governam o que vira regra — inclusive
a formulada hoje de manhã: **regra que compara flag gravada contra o relógio não é segura**.

## O índice existe porque os blocos de referência cruzada ficaram parciais

Os seis documentos foram escritos em ordens diferentes e cada um cita só os irmãos que já
existiam quando ele nasceu. Uniformizar exigiria reescrever os seis inteiros; em vez disso,
**o índice (`8f8ed60e`) declara que os blocos internos são parciais e que a lista completa é
a dele** — um documento curto que fica atual sozinho, em vez de seis que se desatualizam
juntos.

## Duas mudanças de status no documento de operação

`rfn_operacao__tarefa_projeto` (**8.854**) e `rfn_operacao__email_remetente_mensal`
(**1.599**) materializaram em 30/09 e saíram da seção de pendentes, ganhando `@table::` — a
anotação só vale para tabela materializada.

**Os 9 que ficam são do ramo VJOB, e isso foi conferido, não suposto:**
`rfn_operacao__squad_cliente` responde `table_not_materialized` e a `mysql-yIOn` rodou pela
última vez em 27/09. Entram em **04/10**.

## Estado medido da qualidade em 01/10

**294 regras materializadas em nove suítes, uma falha** — a `futura_decompoe`, corrigida hoje
de manhã. As três sem materializar: VJOB (37, entra domingo), Mídia Gold (30) e Mídia Termo
(12), as duas últimas na passada de terça do Google Ads.
