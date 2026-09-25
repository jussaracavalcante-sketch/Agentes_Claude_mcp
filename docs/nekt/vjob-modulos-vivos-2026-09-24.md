# VJOB — o que ainda está vivo, e onde (medido em 2026-09-24)

Sessão de finalização do tratamento do VJOB real (`mysql-yIOn`, banco `vjob_2024`,
camada `vanguardamartech_vjob_real_mysql`, prefixo `mysql_vjobvjob_2024_`).

Tudo abaixo foi **medido no sistema**, não herdado do derivado Supabase e não deduzido do
`Number of rows` do DDL — que este repositório já registra como metadado antigo.

---

## 1. O achado que muda o diagnóstico: o módulo de job NÃO parou, mudou de tabela

Este repositório registrava que "o módulo de JOB do VJOB está parado desde 24/08/2026".
**Está errado.** As tabelas que a `trs_vjob__job` lê pararam; o trabalho continuou em
outras duas, que nenhuma tabela desta base lia.

| tabela | linhas | primeiro cadastro | último cadastro |
|---|---:|---|---|
| `tbjobs` | 1.354 | 04/08/2025 | **24/08/2026** — aposentada |
| `tbjobsgeral` | 160 | — | 05/06/2026 — aposentada |
| **`tarefas_tbjobs`** | **1.329** | 04/03/2026 | **23/09/2026** |
| **`advisory_tbjobs`** | **256** | 26/01/2026 | **18/09/2026** |

**Não é cópia, e isso foi testado.** A hipótese óbvia — migração que duplicou linhas —
foi medida e descartada: entre `tbjobs` e `tarefas_tbjobs` há **zero** linhas que casem
por `(projeto, atividade, data_cadastro)` e **zero** por `(id, data_cadastro)`. Os 1.229
ids em comum são coincidência de sequência numérica. As duas contam trabalho diferente.

**A chave é composta**, pelo mesmo motivo da `trs_vjob__job`: 1.585 linhas, **1.585
chaves `(origem, id_job)` e apenas 1.330 ids crus** — 255 ids aparecem nas duas origens.

**As duas origens têm vocabulário de status diferente:**

- TAREFAS: `Aprovado` 676 · `A fazer` 449 · `Cancelado` 185 · `Em andamento` 10 ·
  `Aguardando analista` 6 · `Aprovação cliente` 3
- ADVISORY: **`Feito`** 213 · `A fazer` 23 · `Em andamento` 13 · `Cancelado` 7

E se comportam ao contrário em quem executa: **TAREFAS é 100% interno** (1.329 de 1.329),
**ADVISORY é 70% externo** (179 de 256).

`checado_em` é campo morto no módulo novo: **zero das 1.329 linhas de TAREFAS**, contra
66 das 256 de ADVISORY e 1.051 das 1.354 do módulo aposentado. A etapa de checagem
deixou de existir no fluxo novo.

→ Tratado em **`trs_vjob__job_tarefa`** (`query-tfHg`), 1.585 linhas, L4 por linhagem.
A `trs_vjob__job` **não é substituída**: ela cobre o período que a outra não cobre, e o
corte está em 24/08/2026.

---

## 2. O módulo `ia_*` tem cadeia completa — e custo medido

`docs/nekt/contexto-cliente-arquitetura.md` foi escrito presumindo que não havia lugar
onde a casa autora conteúdo de marca. Havia, e está em uso.

| tabela | linhas | tratada em |
|---|---:|---|
| `ia_cliente_config` | 3 | `trs_vjob__ia_cliente_config` (`query-vqwG`) · L3 |
| `ia_cliente_documentos` | 21 | `trs_vjob__ia_documento` (`query-cAhw`) · L3 |
| `ia_solicitacoes` | 86 | `trs_vjob__ia_solicitacao` (`query-GbCw`) · L3 |
| `ia_geracoes` | 86 | `trs_vjob__ia_geracao` (`query-awpp`) · L3 |
| `ia_geracao_arquivos` | 78 | `trs_vjob__ia_geracao_arquivo` (`query-wZoc`) · L2 |
| `ia_usuario_cliente` | **0** | não tratada — não há controle de acesso registrado |

**A adoção é de 3 clientes em 315 (0,95%), e só 2 têm contexto utilizável.**
`PRESTEX ENCOMENDAS` (136) tem a configuração aberta, `ativo = 1` e **zero caractere**
nos 7 campos de conteúdo. `MOVE RENTAL CARS` (336) tem 8.588 caracteres em 5 campos e
`THEREZINHA RUIZ` (339) 3.402 em 6. `fatos_verificados` está **vazio nos três**.

**Documentos:** 21, dois clientes. 14 IMAGEM (34.193 caracteres extraídos, **4 sem
conteúdo nenhum**), 5 COMPACTADO (505 — praticamente nada) e 2 PDF (13.324). Total
48.022 caracteres, dos quais o texto útil está em 17 dos 21.

**Solicitações:** 86, 3 clientes, 4 usuários, 23/06 → 17/09/2026. 75 concluídas, 7 em
erro. Os 6 `erro` têm prompt de 31.123 caracteres em média contra 19.759 dos concluídos —
**o pedido que falha é o pedido grande** (observação de 6 linhas, não indicador).

**Custo da operação de IA: US$ 14,04 em três meses** (US$ 14,043281). Maior geração
US$ 0,528973. **Um único modelo (`gpt-5.4`) e um único provedor.** 75 das 86 têm custo;
11 não — os 6 `erro`, os 3 `aguardando_configuracao` e **2 concluídas sem explicação na
base**. Nos onze, `custo_estimado_usd` sai **NULL, nunca zero**.

**A cadeia fecha:** das 86 solicitações, **73 das 75 concluídas têm arquivo e nenhuma das
11 não concluídas tem**. 78 arquivos (59 PNG, 19 SVG) para 73 gerações.

### Correção de uma afirmação minha, no mesmo dia

Publiquei na descrição da `trs_vjob__ia_solicitacao` que "a peça gerada NÃO está aqui,
não há coluna com o que a IA devolveu". **Há.** `ia_geracoes` existe, tem 86 linhas e
carrega `resultado`. Eu tinha visto `ia_geracao_arquivos`, procurado a tabela-pai pelo
catálogo semântico, recebido "não encontrada" e concluído que não existia — **sem contar
as linhas dela**. Um `COUNT(*)` respondeu 86. Corrigido na descrição publicada e nas
duas tabelas novas.

**A lição é a mesma já registrada sobre catálogo:** busca semântica que não devolve a
tabela **não prova que a tabela não existe**. Conferir com `COUNT(*)` antes de afirmar
ausência.

---

## 3. `tbclientexservico` — 6.094 linhas, e o checklist está vazio

Não recebeu Trusted, e a decisão está medida.

A tabela é um **checklist de entrega**: dez itens (`kv`, `planejamento`, `ultimo_post`,
`blogs`, `email_mkt`, `material_rico`, `ads`, `lp`, `relatorio`, `extras`), cada um com
flag, data e coluna de texto.

- **6.094 linhas**, 265 valores de `id_cliente` — **969 delas com `id_cliente = 0`**
- 1.740 sem gestor
- período 05/03/2023 a **06/10/2026** (futuro)
- **das ~60.940 células de flag possíveis, 7 estão preenchidas**: `kv` 4 e
  `planejamento` 3. Os outros oito itens são **zero em todas as 6.094 linhas**.

Uma Trusted sobre ela emitiria dez colunas constantes zero — exatamente o erro que esta
casa já declarou sobre `stats` do GitHub: *"emitidas como NULL, convidariam a somar e
obter zero, que é um número, quando o certo é ausência"*. É o mesmo padrão de "registro
ausente" já documentado no escopo sem conclusão, agora em 99,99% da tabela.

**A Raw continua lá** — não se apaga nada. O que não se faz é apresentar como indicador
de entrega uma tabela que ninguém preencheu.

---

## 4. Outras tabelas vivas do VJOB ainda sem tratamento

Medidas nesta sessão, em ordem de valor aparente:

| tabela | linhas | último evento | o que é |
|---|---:|---|---|
| `contazul_fornecedores` | 1.299 | — | espelho da integração Conta Azul |
| `tarefas_tbjobs_responsaveis` | 1.329 | — | satélite do módulo de job novo (N responsáveis por job) |
| `tbblogs` | 1.323 | cadastro **18/12/2025** | calendário editorial — **parado há 9 meses** |
| `contazul_clientes` | 661 | — | espelho da integração |
| `tbjobs_comentarios` | 656 | — | satélite do módulo aposentado |
| `tarefas_tbjobs_comentarios` | 589 | — | satélite do módulo novo |
| `contazul_servicos` | 403 | — | espelho |
| `contazul_categorias` | 382 | — | espelho |
| `tbclientesatedimentos` | 308 | — | cadastro paralelo de cliente (**não** resolve o `id_cliente` do escopo — já testado, bate zero) |
| `tarefas_tbjobs_arquivos` | 282 | — | satélite |
| `tbrh_renovacoes` | 125 | — | RH, **L4** |
| `tarefas_tbjobs_prazo_hist` | 75 | — | satélite |
| `tbcronograma_on_verbas` | 60 | — | verba por fornecedor no cronograma |

**`tbetapasxclientes2` e `tbauditoriaclientes` saíram desta lista** — foram tratadas
nesta mesma sessão (seção 5). Sobre a primeira vale a lição: este repositório lista doze
tabelas com sufixo `2`/`3` como duplicatas descartáveis, e `tbetapas2` é uma delas.
**`tbetapasxclientes2` é outra tabela**, tem 7.782 linhas e recebeu marcação ontem.
**O sufixo não prova descarte; medir a data do último evento prova.**

---

## 5. O que esta sessão publicou

Oito Trusted novas, todas com gatilho de evento em `query-MZdN` (`trs_vjob__cliente`),
entrando na cadeia semanal do VJOB real, e **alerta de falha ligado nas oito**:

| slug | tabela | linhas | nível |
|---|---|---:|---|
| `query-tfHg` | `trs_vjob__job_tarefa` | 1.585 | L4 |
| `query-vqwG` | `trs_vjob__ia_cliente_config` | 3 | L3 |
| `query-cAhw` | `trs_vjob__ia_documento` | 21 | L3 |
| `query-GbCw` | `trs_vjob__ia_solicitacao` | 86 | L3 |
| `query-awpp` | `trs_vjob__ia_geracao` | 86 | L3 |
| `query-wZoc` | `trs_vjob__ia_geracao_arquivo` | 78 | L2 |
| `query-LQ5u` | `trs_vjob__auditoria_cliente` | 3.025 | L2 |
| `query-DYWJ` | `trs_vjob__etapa_cliente` | 7.782 | L2 |

**Nenhuma delas materializou ainda.** Publicar não é materializar; a prova é a execução
agendada, e a cadeia do VJOB depende da `mysql-yIOn`. As regras da suíte de qualidade
sobre estas oito só podem ser escritas **depois** que as tabelas existirem — referenciar
tabela não materializada derruba a query inteira.

### 6. Os dois achados de invariante

Vale destacar, porque são de espécie diferente de tudo o que já havia medido:

**`tbauditoriaclientes` tem a invariante que o escopo não tem.** `status = 1` e
`datahoramarcacao IS NOT NULL` coincidem **exatamente**: 1.544 e 1.544, zero exceções nas
duas direções. Série temporal de auditoria cobre **100%** das conclusões, enquanto a de
escopo cobre 84% (10.926 de 68.016 conclusões sem carimbo). A invariante virou coluna —
`flag_status_sem_carimbo`, hoje FALSE em 3.025 de 3.025 — para que uma quebra futura seja
visível sem ninguém precisar lembrar de conferir.

**`tbetapasxclientes2` tem TRÊS estados, não dois.** `ativo` é NULL em **3.790 das 7.782
(48,7%)**, e **nenhuma dessas 3.790 tem marcação** — nem uma. A taxa de marcação muda de
sentido conforme o denominador: **18,6% sobre a tabela inteira, 36,3% sobre as ativas**.
`flag_nunca_ativada` existe para que ninguém divida pelo denominador errado sem perceber.

E o buraco de cadastro aparece nas duas, consistente com o resto do VJOB: **1.372 de
3.025 (45,4%)** na auditoria e **882 de 7.782 (11,3%)** nas etapas apontam para cliente
que não existe em `tbclientes`. Todos os joins são LEFT, com flag.

### 7. Correção de catálogo

`tbsetor` tem **17 linhas e começa no id 5** (5 Diretoria, 6 Inbound Marketing,
7 Social Media, 8 Account Manager, 9 Criação, depois 11–24), não no id 11 como este
repositório registrava. O que continua verdadeiro é que `tbjobsgeral.id_setor = 1` não
resolve contra ele — o campo segue morto.
