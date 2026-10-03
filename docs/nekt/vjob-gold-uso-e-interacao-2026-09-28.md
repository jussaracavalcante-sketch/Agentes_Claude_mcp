# VJOB — uso e interação ganharam Gold (2026-09-28)

Duas Refined que fecham **cinco Trusted** sem camada de consumo, e uma delas derruba a
explicação mais simples para o achado mais consequente desta base.

| slug | tabela | grão | linhas | nível |
|---|---|---|---:|---|
| `query-yGBh` | `rfn_operacao__acesso_mensal` | usuário × mês | **2.109** | L4 |
| `query-c1x0` | `rfn_operacao__job_interacao` | job | **3.188** | L4 |

Deploy limpo e alerta de falha ligado nas duas.

---

## 1. O achado: o uso do VJOB não caiu no Q4/2024 — ele TRIPLICOU

Em 2026-09-23 esta casa mediu que **62 dos 86 clientes sem conclusão pararam no mesmo
trimestre**, o quarto de 2024, e registrou: *"não são 86 histórias separadas de cliente
inativo — é um evento único no fim de 2024 que 62 operações atravessaram juntas (mudança
de processo, de ferramenta ou de equipe)"*.

A hipótese mais simples — **o sistema foi abandonado** — está descartada por medição.

| mês | acessos | usuários ativos |
|---|---:|---:|
| 2024-06 | 487 | 46 |
| 2024-07 | 533 | 49 |
| 2024-08 | 486 | 53 |
| 2024-09 | 955 | 66 |
| **2024-10** | **1.628** | 63 |
| 2024-11 | 1.326 | 67 |
| 2024-12 | 1.457 | 67 |
| … | | |
| 2026-09 | **2.804** | 70 |

**O salto acontece exatamente no trimestre em que as conclusões pararam, e é para cima.**
A série nunca voltou ao patamar anterior.

**As pessoas continuaram entrando, e em maior número. O que mudou foi o que elas foram
fazer lá dentro.** Isso estreita a explicação daquele evento sem fechá-la: sobra mudança
de processo ou de ferramenta *para aquela etapa específica*, não abandono do sistema.

---

## 2. `rfn_operacao__acesso_mensal` — quem usa, quanto e desde quando

Grão: **um usuário, um mês.** 2.109 linhas, 305 usuários, 85 meses (2019-05 a 2026-09).

### O fuso foi reconferido nesta tabela, não herdado

| hora | acessos |
|---|---:|
| 9h | **7.386** (pico) |
| 10h | 5.330 |
| 11h | 4.876 |
| **12h** | **1.799** (vale) |
| 13h | 2.693 |
| 14h | 5.275 |

Chegada, almoço e volta. Em UTC o pico cairia às 6h, que não é hora de ninguém chegar.
**Hora local, sem conversão** — como a Trusted já entrega.

O almoço aqui é às **12h**; nas marcações de escopo é às **13-14h**. São gestos diferentes
— entrar no sistema e marcar entrega — e não precisam coincidir.

### Regras que mudam a leitura

- **`qtd_dias_ativos` é mais honesto que `qtd_acessos`.** Acesso é login, e quem perde a
  sessão loga de novo: a Trusted já mediu **400 pares (usuário, data-hora) repetidos**.
- **Coorte separada de recorrência.** `flag_primeiro_mes` (305 linhas, uma por usuário) e
  `flag_retorno_apos_ausencia` (140 linhas) existem porque um COUNT de usuários ativos
  junta quem é novo, quem nunca parou e quem voltou, sem avisar.
- **6 acessos sem usuário ficam fora do grão** — a soma de `qtd_acessos` devolve **49.428**,
  não os 49.434 da Trusted. Declarado, não perdido.
- **97 dos 305 usuários (31,8%) não existem em `trs_vjob__usuario`.** `usuario_nome` sai
  NULL e a flag acende — **qualquer leitura por nome cobre 68% dos usuários**.

### Limitações

Acesso **não é trabalho**. Não há sessão, não há duração, não há tela, não há cliente — a
origem tem três colunas: id, usuário e data-hora. E a série começa em 2019-05 com
instrumentação rasa: comparar 2019 com 2026 compara instrumentação, não comportamento.

---

## 3. `rfn_operacao__job_interacao` — quais jobs tiveram conversa

Grão: **um job.** 3.188 linhas, uma por job da `rfn_operacao__job`. **Fecha quatro Trusted
de uma vez** — comentário interno, comentário de cliente, anexo de job e anexo de
comentário. As quatro eram lidas apenas pela suíte de qualidade.

### O universo é o JOB, não a união dos satélites

Partir dos satélites daria 754 jobs com comentário e **esconderia os 2.434 sem nenhum**.

### A cobertura é baixa e é o número certo

- **754 de 3.188 jobs (23,7%)** têm comentário interno
- 674 (21,1%) têm anexo de job
- **apenas 16 (0,5%)** têm comentário de cliente
- **1.940 jobs (60,9%) não têm interação NENHUMA**

Job sem conversa é a regra, não a exceção. `flag_sem_interacao` existe para que isso seja
filtrável em vez de deduzido.

### A aritmética de cada lado, medida e declarada

| origem | na Trusted | chega a um job | diferença |
|---|---:|---:|---|
| comentário interno | 1.333 | **1.329** | 4 de job não catalogado |
| comentário de cliente | 22 | **22** | — |
| anexo de job | 1.007 | **978** | 29 `flag_anexo_sem_job` |
| anexo de comentário | 771 | **684** | 86 sem comentário-pai + 1 de job não catalogado |

O anexo de comentário sobe até o job **pelo comentário**, e a ponte é exata: **685 dos 771
casam por (origem, id_comentario), zero órfãos** entre os que têm pai. Os 86 sem pai são os
do fluxo de upload por token — a Trusted já mediu que **token e sem-pai são o mesmo
conjunto**, pela terceira vez nesta base.

**Total de anexo do VJOB continua sendo 1.007 + 771 = 1.778; o que chega a um job é
978 + 684 = 1.662.**

### Duas colunas, não uma

- **Comentário interno e comentário de cliente** são populações disjuntas (quatro origens
  internas contra uma externa), então somam — e a soma sai declarada em
  `qtd_comentarios_total`. O que não pode é ler só uma.
- **Anexo de job e anexo de comentário** são grãos diferentes porque o pai é outro, mesmo
  precedente já aplicado nas Trusted.
- **Comentário vazio não é conversa:** 120 sem texto (15,7% no módulo aposentado, 2,7% no
  de tarefas). `flag_teve_conversa` exige comentário **com** texto.

### O que a tabela não diz

`dias_ate_o_primeiro_comentario` (0 a 53 dias, NULL quando não houve comentário) **não é
tempo de resposta** — não há destinatário, não há pergunta, não há leitura. É só a
distância entre o cadastro do job e a primeira vez que alguém escreveu nele.

E `editado_em` só existe no módulo de TAREFAS: por isso saem
`qtd_comentarios_com_edicao_rastreavel` ao lado de `qtd_comentarios_editados` — a razão
entre os dois é a única leitura honesta de "quanto se edita".

---

## 4. A cadeia de job foi LINEARIZADA

`query-8QxL` (anexo) e `query-D6HS` (comentário) disparavam **em paralelo** em
`query-tfHg`, junto com a própria `rfn_operacao__job`. A nova Refined lê **cinco** tabelas
desse ramo, e evento em paralelo não garante ordem.

```
mysql-yIOn (domingo 00h)
  └─ query-MZdN   trs_vjob__cliente
     └─ query-4XbY   trs_vjob__job
        └─ query-tfHg   trs_vjob__job_tarefa
           └─ query-wpYP   rfn_operacao__job
              └─ query-8QxL   trs_vjob__job_arquivo
                 └─ query-D6HS   trs_vjob__job_comentario
                    └─ query-uR7K   trs_vjob__comentario_arquivo
                       └─ query-ijFf   trs_vjob__job_comentario_cliente
                          └─ query-c1x0   rfn_operacao__job_interacao
```

Dois gatilhos alterados (`8QxL` e `D6HS`) **e as duas descrições correspondentes
atualizadas na Nekt** — descrição que continua dizendo o gatilho antigo é registro com
buraco.

A `rfn_operacao__acesso_mensal` entra pelo outro ramo, em `query-OwrE`.

---

## 5. A base andou entre a publicação das Trusted e hoje

Remedido na tabela materializada, e é origem, não tratamento:

| tabela | publicada em 24-25/09 | hoje |
|---|---:|---:|
| `trs_vjob__job_comentario` | 1.311 | **1.333** |
| `trs_vjob__job_arquivo` | 990 | **1.007** |
| `trs_vjob__comentario_arquivo` | 754 | **771** |
| `trs_vjob__recorrencia_ocorrencia` | 410 | **426** |
| `trs_vjob__acesso` | 49.206 | **49.434** |

As duas descrições Trusted atualizadas levaram a remedição junto.

---

## 6. Validação — medida antes de publicar

| verificação | acesso mensal | job interação |
|---|---|---|
| linhas = chaves | 2.109 = 2.109 | 3.188 = 3.188 |
| soma reproduz a Trusted | 49.428 (= 49.434 − 6) | as quatro, com causa declarada |
| invariante de coorte | 305 primeiros meses, um por usuário | — |
| contradição primeiro-mês × retorno | 0 | — |
| flag × NULL do nome | concordam em 2.109 de 2.109 | — |
| razão ausente / indevida | 0 / 0 | 0 / 0 |
| valores negativos | — | 0 (nenhum comentário nasce antes do job) |

---

## 7. O que fica pendente

- **Regras de qualidade sobre as duas** entram quando materializarem (domingo, com a
  `mysql-yIOn`). As candidatas mais fortes: a soma de `qtd_acessos` reproduzindo a Trusted
  menos os 6 sem usuário; a ponte anexo-de-comentário → comentário (685 de 685); e a
  invariante "um primeiro mês por usuário".
- **Ainda sem Refined no VJOB:** `trs_vjob__cronograma_alteracao` (18.955, mas 46,4%
  indecidível entre contrato e parcela — a Trusted já declara que escolher seria inventar),
  `trs_vjob__sms_notificacao` (11.068), `trs_vjob__squad_alteracao` (2.346),
  `trs_vjob__recorrencia_ocorrencia` (426), `trs_vjob__blog_pauta` (1.323),
  `trs_vjob__checklist_diario` (2.748), `trs_vjob__auditoria_servico` e `__auditoria_ciclo`.
- **Gmail** segue sem Refined: `trs_gmail__mensagem` (32.870) foi publicada hoje e ainda
  não materializou.
