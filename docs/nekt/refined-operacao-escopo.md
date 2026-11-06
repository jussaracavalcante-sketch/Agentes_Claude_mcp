# Próximo nível do VJOB — dimensão de serviço e a primeira Refined

**Publicadas em 2026-09-23.** A cadeia do VJOB agora vai da fonte até a camada de consumo,
encadeada por evento e andando junto, uma vez por semana:

```
mysql-yIOn ──► query-MZdN ──► query-Ty76 ──► query-lCot ──► query-V3c3
(domingo 00h)   cliente        escopo         serviço       rfn escopo mensal
                315            195.163        38            70.963
```

Cada elo dispara no anterior, não na fonte. Quando o último roda, os três de cima já
materializaram — não há corrida.

| Recurso | Slug | Camada | Linhas |
|---|---|---|---:|
| `trs_vjob__servico` | `query-lCot` | Trusted / `vjob` | 38 |
| `rfn_operacao__escopo_mensal` | `query-V3c3` | Refined / `operacao` | 70.963 |

Arquivos: `sql/trusted/trs_vjob__servico.sql`, `sql/refined/rfn_operacao__escopo_mensal.sql`.

---

## 1. A tabela de domínio de serviços existe — e está vazia

Ontem eu disse que ela "não foi localizada". Localizei:
`mysql_vjobvjob_2024_tb_servicos_servico`, com `id`, `categoria`, `subcategoria`, `nome` e
`datacriacao`. A forma é exatamente a que faltava.

**Ela tem zero linhas** — e a extração da `mysql-yIOn` terminou com sucesso em 21/09 17:38.
Então, enquanto ela estiver assim, **o nome do serviço não existe no sistema**.

O único lugar da base com os rótulos é o derivado Supabase, que resolve 34 dos 38 e entrega
4 como o literal `"(outro)"` — ids 10, 17, 19 e 27, somando **7.980 escopos (4,1%)**.

Por isso a dimensão lê o derivado, com `origem_do_nome` declarada linha a linha
(`DERIVADO_SUPABASE` ou `NAO_RESOLVIDO`). É o padrão que a `trs_iclips__tarefa` já usa para
juntar bronze e notebook. **Quando `tb_servicos_servico` materializar com linha, a query passa
a ler o sistema e mantém o derivado só como resíduo** — e a coluna `origem_do_nome` é o que
torna essa troca auditável. Está escrito na descrição.

Também se perde `categoria` e `subcategoria`: existem no esquema do sistema e não chegam.
**Não há agrupamento de serviço por família nesta base hoje.**

---

## 2. A Refined: onde o zero deixa de mentir

Grão: **um cliente, uma competência, um serviço**. 70.963 linhas, 70.963 chaves distintas,
70.963 hashes — grão provado. E os totais fecham com a Trusted:

| | Trusted | Refined |
|---|---:|---:|
| Escopos planejados | 195.163 | 195.163 |
| Concluídos | 68.016 | 68.016 |
| Concluídos com carimbo | 57.090 | 57.090 |

A Trusted responde *quantos escopos existem e quantos estão marcados*. Ela não sabe quando um
zero significa "não fez" e quando significa "ninguém registrou". Essa distinção é regra de
negócio, e é o que esta camada adiciona.

### As sete regras, numeradas na descrição

**R1 — Competência futura fica marcada, não removida.** Há escopo cadastrado até 09/2027.
`is_competencia_futura` acende em **2.988 linhas**. Somar sem esse filtro conta mês que ainda
não aconteceu como se fosse atraso. A linha fica: planejamento futuro é informação, só não
entra em indicador de execução.

**R2 — Conclusão é `status = 1` do sistema, e só isso.** O derivado marca 82 linhas como
concluídas que o sistema marca 0, com `status2..status7` todos nulos. Aqui vale o sistema.

**R3 — Cliente sem nenhuma conclusão na janela não recebe taxa.** Esta é a regra que existe
por causa de um erro de leitura real. Dos 251 clientes com escopo de 2025 em diante, **86 não
têm uma conclusão sequer**, carregando **71.210 escopos**. Para esses, "0% de conclusão" não é
desempenho — é ausência de registro. `taxa_conclusao` sai **NULL, não zero**: zero é um número
e seria somado; NULL obriga quem lê a decidir. São **26.532 linhas** com taxa nula.

**R4 — 62 desses 86 têm data de parada, e é a mesma.**

Este é o achado novo do dia. Eles concluíam no **quarto trimestre de 2024** e não concluem nada
desde então. Os outros 24 se dividem em 21 que nunca concluíram nada em tempo algum e 3 que
pararam antes do Q4/2024.

Isso muda a leitura do problema. Em 21/09 eu registrei os 86 como "metade do escopo sem
conclusão registrada", com duas causas possíveis e nenhuma evidência para 49 deles. Agora há
uma terceira leitura, mais simples e mais provável: **não são 86 histórias separadas de cliente
inativo — é um evento único no fim de 2024 que 62 operações atravessaram juntas.** Mudança de
processo, de ferramenta ou de equipe. É o mesmo padrão que documentei no `TESTE HUGO SENNA`
(conclusão parou em novembro/2024), agora em escala.

`is_parou_q4_2024` marca essas linhas.

**R5 — A cobertura do carimbo viaja com o número.** 16% das conclusões (10.926 de 68.016) não
têm `datahoramarcado`. `cobertura_carimbo` está na linha para que qualquer série declare sobre
quanto ela fala.

**R6 — Cliente é o cadastro, nunca o grupo** (R-003). Nada de consolidar BRAGA, PMZ ou UNIPAR
aqui.

**R7 — Cliente sem cadastro permanece, marcado.** 96 dos 251 (38%) não existem em
`tbclientes`. `flag_cliente_nao_catalogado` acende em **16.523 linhas**.

---

## 3. Limitações declaradas — não contorne

1. **`taxa_conclusao` NULL não é zero e não se soma.** Ao agregar, recalcule da razão de somas
   (`SUM(qtd_concluido)/SUM(qtd_planejado)`) **e exclua os clientes com
   `is_cliente_sem_registro`** — senão o denominador carrega 71 mil escopos que ninguém marcou.
2. O nome do serviço é rótulo de segunda mão. 4 dos 38 não têm nome (7.980 escopos).
3. `media_dias_prazo_vs_marcacao` só existe onde há carimbo **e** prazo. Não mede atraso de
   processo: mede a distância entre o prazo cadastrado e o momento em que alguém clicou.
4. **Esta tabela não carrega dinheiro.** Escopo é planejamento de entrega; receita está em
   `tbcronograma`/`tbcronogramadatas`, que ainda não têm Trusted.

---

## 4. Uma correção do que publiquei hoje de manhã

Eu disse que o derivado tinha **183.455 linhas, 11.708 a menos** que o sistema. **Errado.**
Contado direto, `supabase_silver_vjob_escopo` tem as **mesmas 195.163**.

O 183.455 veio do campo `Number of rows` que a Nekt mostra no DDL do catálogo — **metadado
antigo, não contagem**. O mesmo campo dizia 710 commits do GitHub quando havia 790.

O derivado não perde linha. Perde a **coluna** `datahoramarcado`, que é outra coisa — e essa
parte continua valendo. Corrigido na descrição da `query-Ty76` e no arquivo SQL.

---

## 5. O que falta no VJOB

- **`tbcronograma` / `tbcronogramadatas`** (10.036 linhas, com valor, faturamento e integração
  Conta Azul). É o dinheiro, e não tem Trusted. É o próximo passo natural.
- **`trs_vjob__job`** existe em `vanguardamartech_trusted` com 1.514 linhas, construída sobre o
  **derivado**. Precisa ser remedida contra o MySQL ou aposentada.
- **Os 96 clientes de escopo sem cadastro** — saber se são cadastros excluídos ou outra tabela
  ainda não localizada é trabalho de origem, não de query.
- **`ia_cliente_config`** (3 linhas, com `biblia_resumo`, `tom_voz`, `regras_inegociaveis`,
  `elementos_visuais`) é a estrutura de contexto de marca que a arquitetura presumia não
  existir. Não foi tratada.
