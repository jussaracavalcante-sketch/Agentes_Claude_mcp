# `rfn_qualidade__regra_vjob` — 37 regras, uma identidade nova e uma afirmação publicada derrubada

**Publicada em 2026-09-29** · `query-Rnff` · Refined / `qualidade` · **37 regras** ·
**L2 INTERNAL** · gatilho de evento em `query-c1x0` · alerta ligado · deploy limpo ·
cadência **semanal**.

**A casa passa a ter 173 regras em cinco tabelas** — 84 diárias na principal, 19 semanais
no Conta Azul, 9 diárias no Gmail, 24 semanais em Mídia, 37 semanais no VJOB.

---

## O que estava descoberto

A suíte principal cobre o núcleo do VJOB — cliente, escopo, job, cronograma. **As 16
Trusted publicadas entre 24 e 25/09 ficaram de fora: 111 mil linhas.**

| tabela | linhas | | tabela | linhas |
|---|---:|---|---|---:|
| acesso | 49.434 | | job_arquivo | 1.007 |
| cronograma_alteracao | 18.955 | | comentario_arquivo | 771 |
| sms_notificacao | 11.068 | | recorrencia_ocorrencia | 426 |
| municipio | 5.570 | | cliente_atendimento | 310 |
| checklist_diario | 2.748 | | auditoria_ciclo | 56 |
| squad_alteracao | 2.346 | | servico | 38 |
| auditoria_servico | 1.387 | | job_recorrencia | 30 |
| job_comentario | 1.333 | | blog_pauta | 1.323 |

---

## O gatilho é um só, e uma regra de frescor é que torna isso seguro

A cadeia do VJOB **se abre em vários ramos paralelos** depois de `query-MZdN`, então
**nenhum elo único vem depois de todos os outros**.

A alternativa seria amarrar a suíte a nove gatilhos com `event_rule = "all"` — o que
faria **uma falha qualquer num ramo impedir as 37 regras de rodar**.

Em vez disso ela dispara no elo mais fundo **e mede a premissa**:
`vjob.carga_do_mesmo_dia` compara `MAX(DATE(_extraido_at))` das 16 tabelas e acusa
qualquer uma que tenha ficado numa carga anterior. **Medido: as 16 em 2026-09-27, uma
única data.**

**É um tipo de regra novo nesta casa** — não mede o **conteúdo** de uma tabela, mede se as
tabelas foram escritas na **mesma passada**. Toda suíte que cobre um lote de ramos
paralelos corre esse risco, e até agora ele não era medido em lugar nenhum.

---

## A identidade — a terceira desta casa

`trs_vjob__auditoria_ciclo.itens_batem_com_a_auditoria`: a soma de `qtd_itens` dos **56
ciclos** tem de ser exatamente o número de linhas de `trs_vjob__auditoria_cliente` —
**3.025 dos dois lados, medido**.

Se divergir, **ou um ciclo perdeu itens ou um item perdeu ciclo**, e nenhuma contagem
isolada denuncia. Grão 1, BLOQUEANTE, limiar 1,00. Vem depois do `rateio_fecha_no_centavo`
e do `caixa_reproduz_o_razao`.

---

## A correção: "token = sem-pai" não é linha a linha no módulo aposentado

A descrição da `trs_vjob__comentario_arquivo` afirmava, desde 24/09, que *"85 carregam
`upload_token` e exatamente os mesmos 85 têm `comentario_id` nulo"*, e que a igualdade
valia **dentro de cada origem**, com "tbjobs 15 e 15".

Remedido hoje sobre as 771 linhas:

| origem | token / sem pai | linhas |
|---|---|---:|
| TAREFAS | não / não | 444 |
| TAREFAS | **sim / sim** | **71** |
| ADVISORY | não / não | 6 |
| tbjobs | não / não | 225 |
| **tbjobs** | **não / sim** | **9** |
| **tbjobs** | **sim / não** | **9** |
| tbjobs | sim / sim | 6 |
| tbjobsgeral | não / não | 1 |

- No **módulo vivo** (TAREFAS e ADVISORY) a igualdade vale **linha a linha: zero
  divergências em 521**.
- No **módulo aposentado** (`tbjobs`) vale **só por contagem**: 15 com token e 15 sem pai,
  mas **apenas 6 são os mesmos**.

**A afirmação anterior era verdadeira sobre os totais e falsa sobre as linhas.** Ler "o
anexo com token é o anexo sem pai" no módulo aposentado leva à conclusão errada em 18
linhas.

Por isso a regra foi escrita **só sobre o módulo vivo**, onde a invariante é real; no
aposentado o caso fica **declarado, não medido como falha**. Na `trs_vjob__job_arquivo` a
igualdade vale linha a linha em **todas** as origens — zero divergências em 1.007 — e ali
a regra é BLOQUEANTE sobre a tabela inteira.

**As duas tabelas não se comportam igual, e essa diferença não aparece em contagem
nenhuma.** A descrição, o comentário do código e o arquivo do repositório foram corrigidos
juntos.

---

## As outras que guardam premissa de verdade

- **`cronograma_alteracao.alvo_nunca_ambiguo_preenchido`** — `id_alvo` é indecidível em
  46,4% das linhas porque as sequências de contrato e de parcela se sobrepõem. A Trusted
  só preenche `id_contrato` **ou** `id_parcela` quando o alvo é inequívoco, e **nunca os
  dois**. Se os dois aparecerem juntos, um join por alvo **duplica a linha entre as duas
  pontas**.
- **`recorrencia_ocorrencia.um_job_por_ocorrencia`** — 426 ocorrências para 426 jobs
  distintos. Se soltar, a agenda conta o mesmo job duas vezes e a
  `rfn_operacao__recorrencia_mensal` infla.
- **`auditoria_ciclo.status_concorda_com_carimbo`** — finalizado e carimbo são a mesma
  coisa nos dois sentidos; se soltar, "auditoria fechada" vira ambíguo.
- **`checklist_diario.marcado_sempre_carimbado`** — 2.748 de 2.748.
- **`job_comentario.edicao_so_onde_ha_rastro`** — `editado_em` só existe no módulo de
  TAREFAS; nas outras origens é **ausência de coluna**, não comentário não editado.
- **`cliente_atendimento.ponte_preenchida`** — 310 de 310 declaram o cadastro jurídico; se
  soltar, metade dos módulos do VJOB perde o CNPJ do cliente.

---

## Linhas de base — limiar frouxo de propósito

| regra | medido | limiar |
|---|---|---:|
| `acesso.usuario_presente` | 6 de 49.434 | 0,999 |
| `blog_pauta.escopo_catalogado` | **1 de 1.183** | 0,999 |
| `cliente_atendimento.cliente_catalogado` | 6 de 310 | 0,97 |
| `servico.nome_resolvido` | 4 de 38 | 0,85 |

O `escopo_catalogado` é o mais importante dos quatro: é a **única ponte desta base entre
entrega e a linha de escopo que a pediu**, e se ela se degradar a
`rfn_operacao__blog_mensal` perde o confronto entre os dois registros da mesma entrega.

O `servico.nome_resolvido` sobe sozinho quando a origem consertar — a tabela de domínio do
sistema (`tb_servicos_servico`) veio **vazia**, e o nome vem do derivado Supabase.

---

## Medido em 2026-09-29

A query inteira foi rodada sobre as tabelas materializadas e devolveu **`CONFORME 37`,
zero falhas**. **L2 INTERNAL:** só contagem e taxa — quatro das 16 tabelas são L4
(`acesso`, `sms_notificacao`, `job_comentario`, `comentario_arquivo`) e **nada delas
atravessa**.
