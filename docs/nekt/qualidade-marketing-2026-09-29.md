# Marketing / RD Station — 24 regras, a quinta identidade, e dois arquivos que nunca existiram

**2026-09-29.** `rfn_qualidade__regra_marketing` (`query-3EQy`, Refined / `qualidade`,
**L2 INTERNAL**, gatilho de evento em `query-tESg`, alerta ligado, deploy limpo,
**cadência diária**).

A casa passa a ter **230 regras em sete tabelas**: 84 diárias na suíte principal,
19 semanais no Conta Azul, 9 diárias no Gmail, 24 semanais em Mídia, 37 semanais no
VJOB, 33 no iClips e 24 diárias aqui.

---

## 1. A família RD inteira estava sem uma única regra

**229.517 linhas materializadas**, e é a maior fonte de lead da casa:

| tabela | slug | linhas | cadência |
|---|---|---:|---|
| `trs_rd_station__contato` | `query-9dz7` | **108.925** | cron 13:10 `America/Manaus` |
| `trs_rd_station__conversao` | `query-ehQc` | **120.592** | cron 13:20 `America/Manaus` |
| `rfn_marketing__conversao` | `query-tESg` | **120.592** | evento em `ehQc` |

**E as duas Trusted NUNCA tiveram arquivo no repositório.** Publicadas em 01/09,
recuperadas de `get_code` e gravadas hoje. É a quarta vez em uma semana que o
repositório diverge do deploy — e a primeira em que o arquivo simplesmente não
existia.

**O alerta de falha estava DESLIGADO nas três** — ligado hoje.

---

## 2. Armadilha de camada, e ela custou a primeira medição

`get_relevant_tables_ddl` pedido com `vanguardamartech_trusted.trs_rd_station__*`
**devolveu `vanguardamartech_braga_veiculos.trs_rd_station__*`** sem avisar da troca.
São as **homônimas por cliente**, geradas pelas queries antigas (`query-Y2zz`,
`01Je`, `T9Gl`, `Zng7` e as de contato, todas de 27/08).

A consolidada é a de `vanguardamartech_trusted`. **Apontar para a camada errada
devolve um cliente e parece a base inteira** — exatamente a armadilha já registrada
nas onze `trs_facebook_ads__insight_diario`. Toda referência na suíte é explícita, e
o aviso está no código.

---

## 3. A quinta identidade da casa, e a primeira ENTRE CAMADAS

`rfn_marketing__conversao.reproduz_a_trusted_linha_a_linha` — BLOQUEANTE, limiar 1,00.

A Refined **não agrega nem filtra**: ela classifica a origem de tráfego e devolve o
**mesmo grão** da Trusted. Então a contagem das duas tem de ser idêntica —
**120.592 dos dois lados, medido**. Se divergir, ou a Refined perdeu linha num join
(e a leitura de marketing passa a subcontar em silêncio) ou duplicou.

As quatro anteriores — `rateio_fecha_no_centavo`, `caixa_reproduz_o_razao`,
`itens_batem_com_a_auditoria`, `custo_reproduz_hora_vezes_valor_hora` — comparam
**valor**. **Esta compara cardinalidade entre Silver e Gold.**

---

## 4. A decomposição exata

`canal_indefinido_decompoe`. A Refined declara que `canal_indefinido` **não mistura**
"sem origem" com "origem que não entendi" — são problemas diferentes e só o segundo
derruba `registro_confiavel`.

Medido: `canal_indefinido` é exatamente `sem_origem OR formato_nao_reconhecido` —
**101.938 = 101.928 + 10, zero divergência**. Se soltar, a distinção que a própria
descrição promete deixa de valer e **a contagem de linhas não muda**.

---

## 5. O número que manda nesta tabela: 76,8% é carga em lote

**92.580 das 120.592 linhas** de `rfn_marketing__conversao` são **importação de base**
para dentro da RD Station, não conversão. A Refined já as marca com `carga_em_lote`.

**Não virou regra, e a decisão está declarada:** carga nova é um evento legítimo do
negócio. Mas o número está na descrição da suíte porque é a coisa mais importante a
saber sobre a tabela — **qualquer leitura de resultado de marketing começa filtrando
`carga_em_lote = FALSE`**, e sem isso três quartos da base são contato importado.

---

## 6. As 24 regras

| grupo | regras | destaque |
|---|---:|---|
| `trs_rd_station__contato` | 7 | as duas flags que separam grão completo de grão mínimo |
| `trs_rd_station__conversao` | 6 | fuso, flag de origem, ponte com contato |
| `rfn_marketing__conversao` | 9 | a decomposição, a taxonomia de 14 canais |
| identidade | 1 | Refined = Trusted, linha a linha |
| frescor | 1 | as três tabelas da família RD |

**Outras que guardam premissa de verdade:**

- **`contato.tem_detalhe_concorda`** — a Trusted avisa, em maiúsculas, para **não
  tratar NULL como "não tem"**: um contato sem telefone pode ser um contato sem
  telefone ou um contato de fonte que não extrai telefone, e `tem_detalhe` é o único
  separador. Se a flag deixar de concordar com `origem_contato`, **toda taxa de
  preenchimento desta base sai errada por construção**.
- **`refinada.canal_pago_concorda`** — `canal_pago` tem de ser exatamente os canais
  que começam com `PAGO`. Se divergirem, a leitura de resultado de mídia infla ou
  desinfla sem aviso. Zero nos dois sentidos.
- **`refinada.canal_conhecido`** — a taxonomia tem 14 valores e sai de um `CASE` da
  própria Refined. Valor novo só aparece se o código mudar, e é isso que a regra pega.

**As quatro linhas de base:**

- **`conversao.contato_catalogado`** (ALERTA 0,99) — hoje **120.592 de 120.592
  resolvem**, mas a Trusted declara que "evento antigo pode apontar para contato que
  saiu da base" e manda usar LEFT JOIN. **Exclusão de titular por LGPD produz
  exatamente esse caso** — limiar 1,00 aqui viraria alarme legítimo.
- `contato.dominio_email_extraido` (0,999) — 47 de 108.925.
- `refinada.escape_tratado` (0,9999) — 1 de 120.592.
- `refinada.formato_reconhecido` (0,999) — **10 das 18.664 linhas QUE TÊM origem**. O
  denominador exclui `sem_origem` de propósito: medir sobre a base inteira diluiria o
  defeito por 120 mil linhas e a regra nunca dispararia.

---

## 7. O que ficou de fora, e por quê

**`conversao.tipo_evento_conhecido`** — hoje `CONVERSION` e `CDP` em 100% das linhas,
mas a Trusted declara que *"se um dia aparecer outro tipo, ele entra sozinho e a
coluna `tipo_evento` passa a discriminar"*. Uma regra exigindo `CONVERSION`
transformaria uma melhoria esperada em falha. **Aqui a ausência da regra é a
decisão.**

---

## 8. Validação

A query inteira foi rodada antes de publicar: **`CONFORME 24`, zero falhas.**
