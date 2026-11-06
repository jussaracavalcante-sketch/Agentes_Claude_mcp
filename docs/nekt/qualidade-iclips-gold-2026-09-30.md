# 30/09 — a suíte do iClips vai a 45 regras: a Gold de tarefa entrou

`rfn_qualidade__regra_iclips` (`query-Sh4v`) **de 33 para 45 regras**, deploy limpo.
**A casa passa a ter 338 regras em nove tabelas.**

## A lacuna tinha data, e a data chegou

A suíte nasceu em 29/09 declarando no próprio código o que ficava de fora:

> `rfn_operacao__tarefa_projeto` (query-BzKD) fica de fora porque foi publicada hoje e
> NÃO MATERIALIZOU — referenciar tabela não materializada derruba a query inteira.

Ela materializou em 30/09 com **8.854 linhas** — eram 8.835 na medição de 29/09; **a base
andou, não o tratamento**. Era a maior Trusted desta base sem Refined lendo; agora a Gold
dela também está medida.

## O gatilho mudou, e a razão é ordem

Até aqui a suíte e a Gold eram **irmãs**: as duas disparavam nas Trusted do `notebook-Rbpo`
em paralelo. A suíte mediria a Gold da passada **anterior** — mediria certo e mediria velho,
que é o pior tipo de medição porque **nada denuncia**.

`query-BzKD` entrou no conjunto `"all"`:

```
notebook-Rbpo → 8nEt + 9nws + tF7c + vHzW → BzKD → Sh4v
                └──────── "all" ────────────────┘
```

**O custo está declarado e é o mesmo já aceito para a `query-8nEt`:** se a Gold falhar, a
suíte inteira não roda. Melhor não medir do que medir velho.

**Isto não é linearização** — nenhum gatilho de terceiro foi alterado. É o mesmo primitivo
`"all"` que a `rfn_operacao__tarefa_projeto` já usava, com um elo a mais no conjunto.

## As 12 regras, medidas na tabela materializada antes de publicar

| regra | avaliadas | falhas |
|---|---:|---:|
| `id_tarefa_job_unico` | 8.854 | 0 |
| `projeto_catalogado` (órfão **e** flag) | 8.854 | 0 |
| `documento_tem_forma` | 8.618 | 0 |
| `flag_sem_cnpj_concorda` | 8.854 | 0 |
| `flag_sem_estimativa_concorda` | 8.854 | 0 |
| `flag_sem_tempo_conta_apontamento` | 8.854 | 0 |
| `razao_so_existe_com_os_dois_lados` | 8.854 | 0 |
| `mes_referencia_e_o_primeiro_dia` | 8.854 | 0 |
| `duracao_reproduz_as_datas` | 7.829 | 0 |
| `horas_reproduzem_os_minutos` | 8.854 | 0 |
| `metrica_nao_negativa` | 8.854 | 0 |
| `origem_do_registro_conhecida` | 8.854 | 0 |

Contexto medido: 236 com `flag_sem_cnpj`, 8.496 sem estimativa, 8.770 sem apontamento,
740 sem início planejado (e as mesmas 740 sem mês de referência), 8.712 `BRONZE_HISTORICO`
contra 142 `NOTEBOOK_VIVO`, 271 documentos distintos, 91 deles de pessoa física.

## A que exigiu escolher IMPLICAÇÃO em vez de igualdade

`razao_so_existe_com_os_dois_lados`. Hoje `razao_gasto_sobre_estimado` é **NULL em 8.854 de
8.854**, porque os dois conjuntos são **disjuntos**: as 358 tarefas com estimativa e as 83
com tempo apontado **não têm uma única em comum**.

Uma regra exigindo "sempre NULL" transformaria a **melhoria esperada** — o dia em que uma
tarefa tiver os dois lados — **em falha**. O que se afirma sem prender o futuro é o outro
lado: a razão nunca existe sem os dois. Mesma doutrina da
`venda_conta_azul_implica_a_flag`, na suíte de Mídia Gold.

## A que fixa uma definição que parece detalhe e não é

`flag_sem_tempo_conta_apontamento`. Medido: **70 tarefas têm apontamento real e
`tempo_gasto_min` = 0** — o apontamento existe e não registrou minuto (a Trusted já declara
que 69 dos 83 pares nem data de play têm).

Se alguém reescrever a flag como "minuto zero", essas 70 **mudam de lado em silêncio**:
passam a contar como "sem tempo apontado" quando o apontamento existe. A regra fixa que a
flag conta **APONTAMENTO**.

## A guarda da correção de 29/09, agora na camada de consumo

`rfn_operacao__tarefa_projeto.documento_tem_forma`. A `trs_iclips__projeto` emitia o CNPJ
**com máscara** e não juntava com nada; esta Gold herda o documento dela.

A regra irmã na Trusted dispara se a máscara voltar **na origem**; esta dispara se ela
voltar a **atravessar** até o consumo. São duas de propósito, porque a Gold pode ganhar
tratamento próprio e as duas perguntas deixariam de ser a mesma.

## O erro que eu cometi medindo, e que virou comentário no código

`duracao_reproduz_as_datas` comparada no nível do **TIMESTAMP** acusa **46 de 7.829**; com
`DATE()` dos dois lados, **ZERO**. A duração é em **dias de calendário** e a hora não entra.

Quarenta e seis falsos positivos bastariam para ensinar a ignorar a suíte — e esta casa já
pagou por isso uma vez, com os 2.555 CPFs da `rfn_operacao__peca`.

## O que NÃO entrou, e a ausência é a decisão

- **`qtd_atividades_no_payload` × apontamento** — a Gold já declara que ela **não conta
  apontamento**: é `ARRAY_LENGTH($.atividades)` do payload do projeto, soma **13.353**
  enquanto a `trs_iclips__apontamento` inteira tem **5.580** linhas. Não há identidade a
  testar; são grandezas diferentes.
- **`flag_inicio_futuro`** — relativa à **data da carga**, e a tabela é reconstruída inteira
  a cada execução. A regra mediria o relógio, não o dado. Mesmo precedente do
  `flag_ocorrencia_futura` da recorrência do VJOB.
- **Cobertura de tempo apontado** (83 de 8.854, 0,9%) — é consequência de o vínculo do
  apontamento ser **exclusivo** e o volume estar na PEÇA, o que a Trusted já declara. Limiar
  ali acusaria o que é legítimo.

## Validação

As 12 novas foram rodadas **unidas a uma CTE antiga** (`r_cat`, 3 regras) — é o que testa o
alinhamento do `UNION` entre bloco novo e bloco antigo, o único risco real de estender uma
suíte existente em vez de criar outra. Resultado: **15 regras, 15 ids distintos, CONFORME 15,
zero falhas**.

O código publicado e o arquivo do repositório foram montados a partir das **mesmas fontes**,
com asserções por trecho editado; o repositório carrega a linha 1 com o slug, que o deploy
não leva, e nada mais. O deploy voltou limpo, o que por si prova que a referência nova
(`rfn_operacao__tarefa_projeto`) resolveu no catálogo — ela só aparece no bloco novo.

## O painel

| suíte | regras | cadência |
|---|---:|---|
| `rfn_qualidade__regra` (principal) | 84 | diária |
| `rfn_qualidade__regra_midia` | 43 | semanal |
| `rfn_qualidade__regra_iclips` | **45** | `notebook-Rbpo` |
| `rfn_qualidade__regra_vjob` | 37 | semanal |
| `rfn_qualidade__regra_cadastro` | 34 | diária |
| `rfn_qualidade__regra_midia_gold` | 30 | Google Ads / PI |
| `rfn_qualidade__regra_marketing` | 24 | diária |
| `rfn_qualidade__regra_gmail` | 22 | diária |
| `rfn_qualidade__regra_contazul` | 19 | semanal |
| **total** | **338** | |

## Ainda sem regra, entre o materializado

Três tabelas: `trs_linear__issue` (230 — a Refined dela, `rfn_operacao__issue_mensal`, já
tem 2 regras na suíte principal) e a dupla VBOT Gold,
`rfn_financeiro__receita_vbot_mensal` (2.103) + `rfn_financeiro__despesa_vbot_mensal` (447).
