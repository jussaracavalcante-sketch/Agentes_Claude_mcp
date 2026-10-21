# Qualidade do iClips — 33 regras, e o CNPJ que não juntava com nada

**2026-09-29.** `rfn_qualidade__regra_iclips` (`query-Sh4v`, Refined / `qualidade`, **L2
INTERNAL**, gatilho de evento em `query-8nEt` + `query-9nws` + `query-tF7c` +
`query-vHzW` com regra `"all"`, alerta ligado, deploy limpo).

A casa passa a ter **206 regras em seis tabelas**: 84 diárias na suíte principal,
19 semanais no Conta Azul, 9 diárias no Gmail, 24 semanais em Mídia, 37 semanais no
VJOB e 33 nesta.

---

## 1. O achado: `trs_iclips__projeto` emitia o CNPJ COM MÁSCARA

A descrição publicada dizia, desde 16/09, que esta era *"a dimensão de cliente mais
completa que existe na base hoje"* — 11.568 projetos com CNPJ. **Ela tinha os
documentos e nenhum deles casava**, porque o payload do iClips entrega
`84.466.424/0001-36` e **coluna de junção não compara com pontuação**.

Medido em 29/09, antes do conserto:

| | hoje | em dígitos |
|---|---:|---:|
| documentos distintos que casam com `trs_iclips__peca_atributo` | **3** | **174** |
| documentos distintos que casam com `rfn_cadastro__cliente_sk` | **3** | **359** |
| **linhas** que casam com a peça | **100** | **8.603** |

**86× mais no grão da linha.** E a comparação é contra a `trs_iclips__peca_atributo`,
que é **do mesmo sistema** e já guardava dígitos — as duas tabelas do iClips não
juntavam uma com a outra.

**A correção, publicada no mesmo dia** (`query-8nEt`), é a mesma já aplicada ao
`cnpj_veiculo` da `trs_pi__insercao`: só é documento o que tem **14 dígitos (CNPJ) ou
11 (CPF)**; `cliente_cnpj` passa a sair em dígitos, `cliente_cnpj_origem` preserva o
cru, `flag_cnpj_invalido` marca e `cliente_is_pf` distingue as **327 linhas de pessoa
física**. Uma linha traz `__.___.___/____-__` — a máscara do formulário em branco,
que não é documento.

**`sem_cnpj` muda de sentido junto:** era "campo vazio" (538), passa a ser "sem
documento válido" (539).

**Validação por execução, antes do deploy:** 12.106 projetos, 12.106 ids distintos,
**11.567 com documento válido**, 366 documentos distintos, 327 CPF, 1 inválido,
**zero fora da forma 14/11**, `sem_cnpj` concorda com `cliente_cnpj IS NULL` em
12.106 de 12.106.

**A `rfn_operacao__tarefa_projeto` não muda de número e herda o conserto sozinha** —
ela passa a coluna adiante, e continua em 8.618 tarefas com documento e 271
documentos distintos. O que muda é que agora eles juntam.

**O arquivo do repositório estava divergindo do deploy** — faltava a coluna `_fuso`,
acrescentada na correção de 16/09. Recuperado de `get_code` e regravado. É a terceira
vez numa semana; **ao corrigir código na Nekt, o arquivo é parte da correção.**

---

## 2. Por que uma quarta suíte

O mesmo motivo da do Gmail: a `rfn_qualidade__regra` está com **57 KB e 84 regras** e
`update_transformation` substitui o código inteiro. A alternativa não tomada —
reescrever a principal — está declarada.

**O que ficava de fora:** seis tabelas materializadas somando **595.542 linhas** sem
uma única regra. A suíte principal cobria só `trs_iclips__peca` e
`trs_iclips__peca_tipo`.

---

## 3. A quarta identidade da casa — e a primeira que valida um sistema de terceiro

`trs_iclips__apontamento.custo_reproduz_hora_vezes_valor_hora` — BLOQUEANTE, limiar
1,00.

A Trusted declara, em maiúsculas, que **não recalcula métrica derivada**:
`custo_estimado` passa como o iClips entrega. **Justamente por isso dá para testar se
o número do iClips é coerente com os outros dois que ele mesmo entrega.** Medido:
`custo_estimado` reproduz `tempo_gasto_min / 60 * valor_hora` **dentro de um centavo
em 5.580 de 5.580 linhas, zero exceções**.

As outras três identidades da casa — `rateio_fecha_no_centavo`,
`caixa_reproduz_o_razao`, `itens_batem_com_a_auditoria` — verificam contas da própria
casa. **Esta verifica a conta da plataforma.** Se quebrar, ou o iClips mudou a fórmula
ou uma das três colunas mudou de significado, e nenhuma contagem de linha denuncia.

---

## 4. Frescor com escopo de FONTE, não de sistema

A suíte do VJOB compara a carga das 16 tabelas porque as 16 vêm da **mesma fonte**.
No iClips as seis vêm de **três**: quatro do `notebook-Rbpo`, a `peca_atributo` da
`supabase-x0tz` e a `peca_categoria` da `rest-api-xk4P`.

Medido: as quatro do notebook carregam **2026-09-29** e a `peca_atributo` carrega
**2026-09-15**, porque a `supabase-x0tz` está parada com senha rejeitada. Uma regra de
"carga do mesmo dia" sobre as seis **falharia por desenho, todo dia**, e ensinaria a
ignorar a suíte. **O escopo da regra de frescor é a fonte.**

---

## 5. As 33 regras

| tabela | regras | destaque |
|---|---:|---|
| `trs_iclips__apontamento` | 9 | a identidade do custo; o vínculo exclusivo; a sentinela |
| `trs_iclips__etapa` | 6 | refação bool × texto; duas linhas de base de data |
| `trs_iclips__projeto` | 5 | as duas guardas da correção de hoje |
| `trs_iclips__tarefa` | 4 | guarda a afirmação da `rfn_operacao__tarefa_projeto` |
| `trs_iclips__peca_atributo` | 5 | forma de documento e as flags |
| `trs_iclips__peca_categoria` | 3 | id único e a linha sem nome |
| frescor | 1 | as quatro do `notebook-Rbpo` |

**Outras que guardam premissa de verdade:**

- **`apontamento.vinculo_exclusivo_e_declarado`** — a Trusted promete que todo
  apontamento está OU numa peça OU numa tarefa, nunca nos dois e nunca em nenhum, e
  emite `vinculo` para ninguém testar dois NULLs. Se quebrar, quem filtrar por
  `vinculo` perde linha em silêncio. 0 falhas em 5.580.
- **`apontamento.sentinela_nunca_esconde_hora`** — a Trusted anula a sentinela
  `1800-01-01` em 1.177 linhas, e a **justificativa escrita** para isso ser seguro é
  que todas têm `tempo_gasto_min` = 0. **Isto transforma a justificativa em teste.**
- **`etapa.refacao_concorda_com_o_tipo`** — `refacao_tipo` (texto, só no bronze,
  distingue "Alteração Cliente" de "Alteração Interna") e `refacao` (bool, comparável
  entre fontes) concordam em **514.909 de 514.909**.

**As quatro linhas de base, e por que o limiar não é 1,00:**

- **`etapa.fim_nunca_antes_do_inicio`** (ALERTA 0,999) — **430 de 489.500** etapas com
  o par de datas terminam antes de começar. É da origem, e o extremo prova: **há etapa
  com início em 7202 e fim em 1923**. 338 das 430 invertem por menos de um dia.
- **`etapa.data_em_ano_plausivel`** (ALERTA 0,9999) — 9 de 497.904 fora de 1990–2100.
  É a regra que acha o caso acima pela raiz.
- **`projeto.documento_presente`** (ALERTA 0,94) — 11.567 de 12.106 (95,55%).
- **`peca_categoria.nome_preenchido`** (ALERTA 0,95) — 28 de 29; a categoria 41 não
  tem nome e isso já estava declarado na Trusted.

---

## 6. O que ficou de fora, com a medição que sustenta

- **`apontamento.peca_catalogada`** — 1.386 dos 5.477 apontamentos de peça (25,3%)
  apontam para peça que não está na `trs_iclips__peca_atributo`; e
  **`etapa.peca_catalogada`** — 342.054 de 514.909 (66,4%).
  **Nos dois casos não é buraco de cadastro:** a `peca_atributo` é uma **fotografia**
  de 54.056 peças vinda da `supabase-x0tz`, enquanto apontamento e etapa carregam
  histórico profundo do bronze e a janela móvel do notebook. A razão entre os dois
  muda sozinha a cada carga. **Regra que acusa o que é legítimo ensina a ignorar a
  suíte** — esta casa já pagou por isso com os 2.555 CPFs da `rfn_operacao__peca`.
- **`rfn_operacao__tarefa_projeto`** (`query-BzKD`) — publicada em 28/09 e ainda não
  materializada. Referenciar tabela não materializada derruba a query inteira.

---

## 7. Validação

A query inteira foi rodada antes de publicar e devolveu **CONFORME 32** e uma única
falha: `trs_iclips__projeto.documento_tem_forma`, que falha **hoje** porque a tabela
ainda carrega a máscara e só será reescrita na próxima passada do `notebook-Rbpo`.
**O gatilho garante que a primeira execução real aconteça depois dessa reescrita** —
esperado: **33 conformes, zero falhas**.
