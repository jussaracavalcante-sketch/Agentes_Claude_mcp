# 01/10 — o inventário achou duas Refined sem regra, e uma é a maior da casa

Em **30/09 eu escrevi que "não sobra tabela materializada sem regra nesta base". Era falso.**

Um inventário cruzando as **152 transformações ativas da Nekt** contra os **122 arquivos `.sql`
do repositório** achou **duas Refined materializadas com zero regra** — e nenhuma das duas
estava registrada no `CLAUDE.md`:

| tabela | slug | linhas | publicada | regras |
|---|---|---:|---|---:|
| `rfn_midia__termo_busca_mensal` | `query-sGXo` | **1.368.269** | 28/09 | **0** |
| `rfn_cliente__contexto` | `query-2k3p` | 410 | 25/09 | **0** |

A primeira é a **maior tabela Refined da casa**. As duas existem no deploy **e** no repositório;
o que faltava era o **registro** — e com ele, a cobertura.

**A lição é de método: cobertura se confere cruzando a plataforma contra o repositório, nunca
pela memória do que foi escrito.** O mesmo erro que ontem me fez dizer "seis tabelas sem regra"
quando eram quatro, e que a consulta à própria suíte por `tabela` corrigiu.

## `rfn_midia__termo_busca_mensal` → suíte própria (`query-XAmt`, 12 regras)

### Por que suíte própria, e a razão não é tamanho — é acoplamento e ordem

A suíte de Mídia (`query-4tgF`, 43 regras) dispara em `query-SGbQ`. **Medido:** na passada de
29/09 a `SGbQ` rodou às **13:52** e a `sGXo` às **16:49** — **três horas depois**. Hospedar as 12
regras lá faria a suíte medir a tabela da **semana anterior**: mediria certo e mediria velho.

A alternativa era acrescentar `sGXo` ao conjunto `"all"` da 4tgF, como se fez com a `query-BzKD`
na suíte do iClips em 30/09. **Não foi tomada**, e o motivo está medido: isso acoplaria as **43
regras que cobrem o núcleo do negócio da casa** — conta, campanha, termo, faixa etária, gênero,
geográfico, localização, Facebook — ao sucesso de **uma** Gold. Se a `sGXo` falhar, as 43 param
junto. Com suíte própria, cada uma cai sozinha.

### A desigualdade, com o GRUPO como grão

`investimento_nao_excede_a_conta_no_mes`. O termo de busca é um **recorte** do investimento da
conta: só campanha de busca gera termo, e o Google não publica termo abaixo do limiar de
privacidade. Então a soma por **(conta, mês)** nunca pode passar do total da conta no mês em
`trs_google_ads__insight_diario`.

**Medido: 531 grupos, ZERO sem par no insight, ZERO excedendo, maior excesso ZERO.**
R$ 669.929,44 de termo contra R$ 1.522.197,48 de insight — 44%, consistente com a cobertura de
61,2% da verba de **busca** que a própria Gold declara (o insight carrega toda a verba, não só a
de busca).

**Se passar, o grão duplicou — e nada na contagem de linhas denuncia, porque a chave continua
única.**

### A única linha de base, com o limiar medido e não escolhido

`clique_nunca_excede_impressao`, ALERTA **0,998** contra **2.239 de 1.368.269 (0,16%)**.
Investigado **antes** de virar limiar:

- maior excesso **três cliques**, média **1,01**
- **nenhum** caso com impressão zero
- são as **mesmas 2.239 linhas** em que `interacoes` também excede — zero de um lado só

É o arredondamento de atribuição do próprio Google, a mesma família já medida em localização
(273 de 161.613, 0,998), segmento (3 de 7.886, 0,999) e desempenho diário (4 de 86.267).
**Limiar único aplicado por simetria reprovaria o que é legítimo.**

### O que não entrou, e a ausência é a decisão

- **Cobertura de verba** — a Gold declara que **não fecha a verba** e que isso é da origem: o
  Google omite termo abaixo do limiar de privacidade, e a cobertura vai de **15,7%** (MILLENIUM)
  a **86,8%** (SANTO REMÉDIO) por conta.
- **`flag_excluido_em_alguma_campanha`** — a Gold declara que **não há data de negativação**:
  EXCLUDED diz o estado na extração, não quando passou a valer. Não há invariante a testar.
- **Métrica derivada** — é decisão de negócio calculada ali de propósito, e sai NULL sem
  denominador. CPC e CPM já ficaram de fora da suíte de Mídia Gold por divergirem no
  arredondamento de duas casas.

## `rfn_cliente__contexto` → suíte de Cadastro (`query-5p6u`, +10 → 44 regras)

Mesmo domínio: a tabela lê `rfn_cadastro__cliente` e `rfn_cadastro__conta`, as duas já medidas
ali. Como `conta` e `receita`, ela **não está no gatilho** e é medida como estiver materializada;
na prática roda um minuto antes (01/10: contexto 07:08:30, suíte 07:09). As 10 regras são todas
**invariantes no tempo**, e a única que depende de data usa `DATE(_extraido_at)` — escrita já com
o critério que a `futura_decompoe` custou para formular, nesta mesma manhã.

**As três que guardam o que aquela tabela declara:**

- **`classe_conhecida`** — a Regra 3 dela diz que `classe` separa terceiro de casa própria **sem
  apagar nenhum dos dois**, e que a aplicação de relatório filtra TERCEIRO. Classe nova cairia
  fora de **todo** filtro existente sem a contagem de linhas mudar.
- **`pi_decompoe_e_o_vinculo_e_rotulo`** — a Limitação 2 vira teste. O histórico de PI entra por
  **rótulo**, não por documento, e a tabela declara que *"zero PI NÃO significa cliente sem mídia
  off, significa que o rótulo não casou"*. `pi_vinculado_por` existe para ninguém ler a contagem
  como prova.
- **`chave_concorda_com_o_metodo`** — se soltar, o mesmo cliente aparece em duas linhas e o
  **lookup determinístico, que é a razão de a tabela existir**, devolve a errada.

**O que não entrou:** cobertura de conta de mídia. A tabela declara em maiúsculas que
**cobertura baixa é o número certo, não defeito a contornar** — 34 dos 410 clientes têm conta
amarrada, e a maioria porque a conta não tem CNPJ na origem (147 das 190). Casar por nome está
**proibido pela R-003**, e a própria tabela mede que o nome diverge em pelo menos 8 dos 38 que
existem nas duas bases.

## Validação

Cada bloco foi rodado **unido a uma CTE de outra suíte**, que é o que testa o alinhamento do
`UNION` entre bloco novo e antigo:

| bloco | resultado |
|---|---|
| 11 do termo + 1 antiga (`geo_alvo.tres_copias_lidas`) | **12 regras, 12 ids, CONFORME 12, zero falhas** |
| 10 do contexto + 1 antiga (`cliente_vbot.cnpj_e_o_da_empresa`) | **11 regras, 11 ids, CONFORME 11, zero falhas** |

## O painel

| suíte | regras | cadência |
|---|---:|---|
| `rfn_qualidade__regra` (principal) | 84 | diária |
| `rfn_qualidade__regra_iclips` | 45 | `notebook-Rbpo` |
| **`rfn_qualidade__regra_cadastro`** | **44** | diária |
| `rfn_qualidade__regra_midia` | 43 | semanal |
| `rfn_qualidade__regra_vjob` | 37 | semanal |
| `rfn_qualidade__regra_midia_gold` | 30 | Google Ads / PI |
| `rfn_qualidade__regra_marketing` | 24 | diária |
| `rfn_qualidade__regra_vbot` | 23 | diária |
| `rfn_qualidade__regra_gmail` | 22 | diária |
| `rfn_qualidade__regra_contazul` | 19 | semanal |
| `rfn_qualidade__regra_linear` | 19 | diária |
| **`rfn_qualidade__regra_midia_termo`** | **12** | semanal |
| **total** | **402** | |
