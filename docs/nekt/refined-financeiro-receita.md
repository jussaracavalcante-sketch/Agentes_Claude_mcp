# Receita por cliente e competência — `rfn_financeiro__receita_cliente_mensal`

**Publicada em 2026-09-23** · `query-awMU` · camada `Refined`, folder `financeiro`
· **classificação L3 CONFIDENTIAL** (arquitetura §31) · alerta de falha ligado.

Grão: **um cliente, uma competência**. 7.455 linhas, 7.455 chaves, 7.455 hashes — grão provado.

Arquivo: `sql/refined/rfn_financeiro__receita_cliente_mensal.sql`.

Na arquitetura de referência isto é `gold/comercial/receita_cliente` somado a
`gold/financeiro/faturamento` (§7). O **padrão de tabela larga foi mantido a pedido**, em
vez do modelo dimensional da §8.

---

## Por que não se chama rentabilidade

**Porque não existe custo.** A arquitetura espera um `fact_custos` (§8) que esta base não tem.
Medido antes de escrever uma linha de SQL:

- o **escopo do VJOB conta peças, não horas**;
- o único `custo_hora` da base está em `supabase_public_dim_colaborador` — **128 de 850
  pessoas (15%)**, do iClips;
- ligá-lo ao VJOB só dá **por nome**: 122 dos 166 marcadores casam, **55 com custo**.

Sem hora gasta, custo/hora não multiplica nada. **Margem não se calcula com o que há hoje.**
Esta tabela é o insumo dela — e a R1 da descrição diz isso em letras claras, para que ninguém
derive margem daqui.

---

## Os totais fecham com a Trusted

| Medida | Refined | Trusted |
|---|---:|---:|
| Valor total | R$ 111.209.496,44 | R$ 111.209.496,44 |
| Escopos planejados | 195.163 | 195.163 |
| Escopos concluídos | 68.016 | 68.016 |

E a composição bate exata:

**R$ 19.753.156,74 (honorário) + R$ 91.456.339,70 (repasse) = R$ 111.209.496,44**

---

## As oito regras

**R1 — Não calcula margem, porque não existe custo.** Acima.

**R2 — Honorário e repasse não se somam como receita da casa.** Parcela **sem fornecedor** é
entrega da casa (Fee Mensal, manutenção); **com fornecedor** há um terceiro que recebe
(veiculação, produção, comissão). As duas saem em colunas separadas. `valor_total` existe
para reconciliar com a Trusted, **não para ser lido como faturamento da agência** — ler o
total como receita própria infla em quase cinco vezes.

**R3 — A grandeza aditiva é a da parcela.** Somar `valor` do contrato daria R$ 84,9 mi contra
os R$ 111,2 mi reais — R$ 26,3 milhões de diferença.

**R4 — "Faturado" não existe na origem.** `faturado = 1` em zero das 10.036 parcelas.
`valor_com_nfse` usa a NFSe, que cobre 91% das parcelas e **94% do valor**
(R$ 104.476.640,06) — e **não é a mesma coisa que faturado**. A NFSe também não é chave, então
não contar notas aqui.

**R5 — Competência futura fica marcada, não removida.** 563 linhas.

**R6 — Cliente sem registro de conclusão não recebe taxa.** Herda a regra da
`rfn_operacao__escopo_mensal`: 86 clientes, `taxa_conclusao` e `honorario_por_escopo_concluido`
saem **NULL, nunca zero**. 4.014 linhas com taxa nula.

**R7 — Cliente é o cadastro, nunca o grupo** (R-003).

**R8 — FULL OUTER, e isso não é preciosismo.**

| Linhas | Quantidade |
|---|---:|
| com receita **e** escopo | 1.771 |
| só receita | 1.272 |
| só escopo | 4.412 |

**R$ 60.359.435,98 — 54% da receita — estão em cliente-mês sem nenhum escopo.** Um `INNER
JOIN` aqui destruiria metade do dinheiro em silêncio. `tem_receita` e `tem_escopo` dizem qual
lado sustenta cada linha.

---

## Limitações declaradas — não contorne

1. **Isto não é faturamento realizado.** É valor contratado por competência. O que de fato
   entrou está no financeiro do Supabase (`gold_mvw_fin_cliente`), que tem outra chave (razão
   social / `cliente_doc`) e **ainda não foi reconciliado** com esta tabela. **Não somar as
   duas fontes** — a casa já tem caso registrado de dinheiro contado duas vezes entre Conexa e
   financeiro.
2. **Não existe `cliente_sk`** (arquitetura §6). O `id_cliente` é o id do VJOB e não consolida
   iClips, Conexa nem Google Ads.
3. `honorario_por_escopo_concluido` usa **só o honorário** no numerador. Dividir repasse de
   mídia por peça entregue não significa nada.
4. A cobertura do carimbo de conclusão é de **84%**.

---

## A cadeia completa do VJOB

```
mysql-yIOn ──► query-MZdN ──┬─► query-Ty76 ─► query-lCot ─► query-V3c3 ──► query-awMU
(domingo 00h)   cliente      │   escopo       serviço      rfn escopo      rfn receita
                315          │   195.163      38           70.963          7.455
                             └─► query-bc9M ─► query-VxBS
                                 cronograma    parcela
                                 6.754         10.036
```

Sete recursos, todos encadeados por evento, todos com alerta de falha. A cadeia anda **uma vez
por semana**, no domingo.

---

## O que falta para a margem

1. **`fact_custos`** — hora trabalhada por cliente. Não existe no VJOB. O iClips tem
   `fato_atividade` com `estimated_time` e `employee_hourly_cost`, mas é outro sistema, com
   outro cadastro de cliente.
2. **`cliente_sk`** (§6) — sem ele, o custo do iClips não se liga à receita do VJOB por prova,
   só por nome.

Os dois são o mesmo problema: **a camada de identidade da arquitetura não existe**. Ela é
pré-requisito da margem, não um refinamento posterior.
