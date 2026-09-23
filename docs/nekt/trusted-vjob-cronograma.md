# Cronograma do VJOB — contrato e parcela

**Publicadas em 2026-09-23.** É o dinheiro do VJOB entrando na base tratada.

| Tabela | Slug | Linhas | Gatilho |
|---|---|---:|---|
| `trs_vjob__cronograma` | `query-bc9M` | 6.754 | evento em `query-MZdN` (cliente) |
| `trs_vjob__cronograma_parcela` | `query-VxBS` | 10.036 | evento em `query-bc9M` |

A cadeia do VJOB agora tem dois ramos a partir do cliente:

```
mysql-yIOn ──► query-MZdN ──┬─► query-Ty76 ─► query-lCot ─► query-V3c3
(domingo 00h)   cliente      │   escopo       serviço      rfn escopo mensal
                315          │   195.163      38           70.963
                             └─► query-bc9M ─► query-VxBS
                                 cronograma    parcela
                                 6.754         10.036
```

Arquivos: `sql/trusted/trs_vjob__cronograma.sql`, `sql/trusted/trs_vjob__cronograma_parcela.sql`.

---

## A regra do valor — o número mais perigoso desta família

**`tbcronograma.valor` não é o valor do contrato. É o valor de uma parcela.**

Somar `valor` entre contratos mistura mensalidades de contratos com durações diferentes e
não produz grandeza nenhuma. Duas provas medidas:

**Prova 1.** Dos 785 contratos em que a soma das parcelas difere do `valor`, **todos** têm
parcela maior — nenhum menor. E **696 deles (89%) são exatamente `valor × número de
parcelas`**: o valor mensal repetido em cada parcela.

**Prova 2.** Os 98 contratos de `tipocronograma = 6` têm **`valor` zero em todos** — e suas
parcelas somam **R$ 547.783,03**. Quem somar `valor` conclui que esse tipo não vale nada.

| Como somar | Resultado |
|---|---:|
| `SUM(valor)` no contrato — **errado** | R$ 84.923.957,85 |
| `SUM(valormensal)` na parcela — **certo** | **R$ 111.209.496,44** |

A diferença é **R$ 26,3 milhões**, e ela não aparece em contagem nem em unicidade.

**Por que o defeito passava despercebido:** em 5.969 dos 6.754 contratos (88%) há uma parcela
só, e aí os dois números coincidem. Só os 785 de múltiplas parcelas denunciam.

Na Trusted a coluna saiu renomeada para **`valor_parcela`** — o nome dizendo o que é — e
`valor_contrato_calculado` traz a soma real das parcelas, medida, nunca multiplicada.

---

## Não existe flag de faturamento confiável

Esta é a segunda armadilha, e é do mesmo tipo: um campo que parece responder e responde zero.

- **`faturado = 1` em ZERO das 10.036 parcelas.**
- **`status` está vazio em 10.007.** Só 29 linhas têm valor: 18 `FATURADO`, 8 `BOLETO EMITIDO`,
  3 `A FATURA`.
- `data_faturamento` preenchida em **119** (1,2%).

Medir faturamento por qualquer um desses devolve praticamente zero — e zero parece um
resultado.

**O único sinal com cobertura real é a NFSe: 9.146 das 10.036 (91%).** `tem_nfse` existe para
isso e é o mais próximo de "faturado" que a base oferece. **Não é a mesma coisa**, e quem usar
declara a escolha.

**E a NFSe não é chave:** 9.146 preenchidas para **7.977 números distintos** — 1.169
repetições. Uma nota cobre mais de uma parcela. Contar parcela por NFSe distinta subconta;
contar NFSe por parcela superconta.

---

## Fornecedor separa repasse de honorário, e isso é medido

Os tipos 1, 2, 3 e 4 têm fornecedor em **100%** das linhas (6.106 de 6.106).
Os tipos 5 e 6 têm fornecedor em **0%** (648 de 648). **Não há meio-termo.**

| Tipo | Contratos | Parcelas | Valor das parcelas | Fornecedor | Serviços |
|---:|---:|---:|---:|:-:|---|
| 2 | 3.595 | 4.424 | R$ 66.465.425,67 | sim | Veiculação de Mídia OFF, Setup, Produção |
| 5 | 550 | 2.695 | R$ 19.205.373,71 | **não** | Fee Mensal, sites |
| 1 | 1.508 | 1.613 | R$ 18.284.389,89 | sim | Veiculação de Mídia ON |
| 3 | 516 | 545 | R$ 5.441.481,94 | sim | Comissão (várias) |
| 4 | 487 | 577 | R$ 1.265.042,20 | sim | Produção, sites |
| 6 | 98 | 182 | R$ 547.783,03 | **não** | comissão, mídia |

Pelo conteúdo dos serviços, os tipos com fornecedor são veiculação, produção e comissão — há
um terceiro que recebe. Os sem fornecedor são Fee Mensal e manutenção — a casa entrega.

**Com fornecedor: R$ 91,46 mi. Sem fornecedor: R$ 19,75 mi.** Tratar os dois como a mesma
grandeza infla a receita própria em quase cinco vezes. É o mesmo mecanismo do `tipo_receita`
CLIENTE vs CONTA_ORDEM que a casa já declarou no financeiro.

A Trusted emite **`tem_fornecedor`, que é o fato**. A leitura "repasse vs honorário" é
hipótese coerente com os rótulos e está **declarada na descrição, não codificada numa coluna**
— `tipocronograma` não tem tabela de domínio nesta base e rotular os seis tipos sem confirmar
na origem seria inventar.

---

## Duas dimensões que resolvem 100%

Diferente do escopo, aqui **não há órfão**:

- os 26 serviços casam com `tbservicoscronograma` (30 linhas)
- os 187 fornecedores casam com `tbfornecedorescronograma` (212)

O serviço do cronograma **tem nome** — ao contrário do serviço do escopo, cuja tabela de
domínio veio vazia.

---

## Outras limitações declaradas

1. **Vigência é escassa:** só 648 contratos têm `iniciodecontrato` e 647 têm `finaldecontrato`,
   de 6.754 (**10%**). Indicador de contrato vigente cobre 10% da base.
2. **`mesanoreferencia` não é competência limpa:** 327 das 10.036 não caem no dia 1.
   `competencia` trunca para o mês e `dt_referencia_origem` guarda o cru.
3. **A integração Conta Azul mal começou:** 126 parcelas com `contaazul_venda_id`, 75 com NF
   emitida, **5 com venda recebida**, de 10.036. As colunas ficam, mas não sustentam
   indicador de recebimento.
4. **Campos mortos:** `email_enviado` (zero em todas as linhas) e toda a família de e-mail,
   `arquivo` (1), `nfseterceiro` (2), `databoleto` (2), `dataemissao` (24).
5. **1.303 contratos apontam para cliente que não existe em `tbclientes`** — o mesmo buraco de
   cadastro já documentado no escopo. `flag_cliente_nao_catalogado` acende, o join é LEFT.
6. `comissao` é STRING na origem; `pi`, `os` e `ci` são identificadores fracos, sem integridade
   conferida contra a `trs_pi__insercao`. Passam como texto.

---

## O que isso destrava

Com escopo e cronograma na mesma base tratada, dá para pôr **entrega e dinheiro lado a lado
por cliente e competência** — que é o que uma Refined de rentabilidade precisa. Os dois já
compartilham `id_cliente` e competência mensal.

O que ainda falta antes disso:

- **A ponte com o PI.** `pi_texto` existe no contrato mas não foi conferido contra a
  `trs_pi__insercao`. Enquanto não for, não há como ligar cronograma a inserção.
- **Os 96 clientes de escopo e 1.303 contratos sem cadastro** continuam sendo o mesmo problema
  de origem.
- **`trs_vjob__job`** segue construída sobre o derivado e precisa ser remedida ou aposentada.
