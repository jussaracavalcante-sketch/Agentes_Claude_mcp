# 01/10 — a camada semântica ganhou mídia e cadastro, e as duas órfãs de hoje entraram por ali

**Medido em 2026-10-01**, depois de o inventário da manhã achar duas Refined materializadas
sem registro em lugar nenhum (`docs/nekt/cobertura-de-qualidade-2026-10-01.md`).

## O buraco

A §17 do ADR-0010 manda a definição oficial morar na camada semântica e a §18 diz que a IA
consome **Gold e Semantic Layer**. Em 29/09 a camada ganhou dois documentos de Refined —
as regras de leitura (`ac85112a`) e o inventário de **operação** (`ce20aecc`). Faltavam os
outros domínios.

**As duas tabelas achadas hoje estavam fora dos dois**, e três buscas com vocabulário
distintivo confirmam: `rfn_midia__termo_busca_mensal` e `rfn_cliente__contexto` não
aparecem em nenhum documento devolvido.

**Ressalva de método, a mesma de 25/09:** busca semântica devolve os N mais relevantes e
**não é prova de ausência** — não existe `COUNT(*)` para documento de contexto, ao
contrário do que vale para tabela.

## O que foi feito

| documento | id | tabelas |
|---|---|---|
| **Mídia — as 5 Refined: qual responde a pergunta, e qual NÃO fecha a verba** | `9cd50802-7c58-4d22-842f-723a28f11d92` | 5 |
| **Cadastro e identidade — as 6 Refined de cliente: qual é a chave, e o que NÃO existe** | `cf0bbeed-7bb8-4668-b24a-f10e6f4a7af0` | 6 |
| **Operação — as 17 Refined** (atualizado) | `ce20aecc-a44e-4a40-be06-b3f4099cd732` | 17 |

**Verificados indexados no mesmo dia:** uma busca por *"qual Refined totaliza a verba de
mídia e qual não fecha, e por onde um cliente entra por documento"* devolve os dois novos
em **primeiro e segundo lugar**.

## O eixo do documento de mídia: só UMA das cinco totaliza verba

Era a decisão de escrita. As cinco tabelas de mídia parecem intercambiáveis pelo nome e
não são:

- **`rfn_midia__desempenho_diario` (86.267) é a única que totaliza.** `ctr` reproduz a
  razão dos totais ao centésimo em 100% das linhas com impressão; `cpc` e `cpm` divergem
  por arredondamento e **não se somam entre linhas**.
- **`rfn_midia__termo_busca_mensal` (1.368.269) cobre 61,2% da verba de busca em BRL** —
  o Google não publica termo abaixo do limiar de privacidade. Serve para negativação,
  nunca para total.
- **`rfn_midia__localizacao_mensal` (161.613)** carrega as duas colunas que resumem a
  armadilha inteira: `local_e_alvo` **PARTICIONA** e `tipo_localizacao` **DUPLICA**.
- **`rfn_midia__segmento_mensal` (7.886)**: `tipo_segmento` é **FILTRO, nunca group by** —
  somar as 7.886 linhas dá **~4× o investimento real**.
- **`rfn_midia_off__pi` (3.319)**: PI cancelado carrega valor, 4,4% do faturado.

## O eixo do documento de cadastro: o cliente entra por DOCUMENTO, nunca por nome

Uma regra governa as seis, e ela está escrita no topo com as três medições que a
sustentam — o filtro por `%VANGUARDA%` que erra nas duas pontas, os 8 nomes que divergem
entre as duas bases da casa, e a R-003.

**E o documento fixa a divisão de trabalho da aplicação conectada**, que é o motivo de a
`rfn_cliente__contexto` existir: `execute_sql` para fato estruturado, `get_semantic_context`
para prosa, leitura de volume para binário. **Pedir o hex da paleta de um cliente à busca
semântica não funciona** — e a tabela não finge ter a coluna, porque conteúdo de marca é
dado **autorado** e não existe em nenhuma fonte conectada.

## Duas mudanças de status no documento de operação

`rfn_operacao__tarefa_projeto` (**8.854**) e `rfn_operacao__email_remetente_mensal`
(**1.599**) materializaram em 30/09 e saíram da seção "publicadas, ainda não
materializadas" para a seção consultável, com `@table::` — a anotação só vale para tabela
materializada.

**Os 9 que ficam pendentes são do ramo VJOB**, e isso foi conferido, não suposto:
`rfn_operacao__squad_cliente` responde `table_not_materialized`, e a `mysql-yIOn` rodou
pela última vez em 27/09. Entram em **04/10**.
