# A camada de identidade — `rfn_cadastro__cliente_sk`

**Publicada em 2026-09-23** · `query-4ZDe` · camada `Refined`, folder `cadastro`
· **classificação L2 INTERNAL** · alerta de falha ligado.

É a `cliente_sk` da §6 da arquitetura — a chave técnica central que faltava. Gatilho:
evento em `query-MZdN`, o elo que traz a fonte mais lenta da cadeia.

Arquivo: `sql/refined/rfn_cadastro__cliente_sk.sql`.

---

## O que ela resolve

A arquitetura pede uma chave que consolide o mesmo cliente entre ERP, CRM e plataformas.
**Sem ela é que apareceram** os 96 clientes de escopo sem cadastro, os 1.303 contratos sem
cadastro, e todo casamento por nome que esta casa já proibiu tratar como prova.

**Grão: um cadastro por sistema.** Cada linha continua sendo o cadastro da origem, com
`sistema`, `id_no_sistema` e `rotulo_na_origem` intactos. O `cliente_sk` é a coluna que
agrupa — não é uma fusão que apaga as partes.

---

## O resultado

| Medida | Valor |
|---|---:|
| Cadastros (linhas) | **1.351** |
| Identidades (`cliente_sk`) | **843** |
| Com documento | 1.138 |
| Isolados sem documento | 213 |
| **Identidades em mais de um sistema** | **319** |
| Máximo de sistemas num sk | 4 |

Grão provado: 1.351 linhas, 1.351 chaves, 1.351 hashes.

**319 identidades atravessam sistemas.** É isso que não existia ontem.

### Inventário por sistema

| Sistema | Cadastros | Com CNPJ | Documentos distintos |
|---|---:|---:|---:|
| VJOB | 315 | 166 | 139 |
| iClips | 408 | 349 | 349 |
| Conexa | 133 | 128 | 113 |
| Financeiro | — | — | 495 |

Cruzamento por documento: **VJOB × iClips 118** · VJOB × financeiro 123 ·
iClips × financeiro 225 · iClips × Conexa 38.

---

## Como o `cliente_sk` é formado — dois caminhos, e só dois

| `sk_metodo` | Regra | Linhas |
|---|---|---:|
| `DOCUMENTO` | `DOC:` + dígitos do CNPJ. Mesmo documento = mesma PJ = mesmo sk, em qualquer sistema. | 1.138 |
| `ISOLADO_SEM_DOCUMENTO` | `sistema:id`. **Fica sozinho.** Não é fundido com ninguém. | 213 |

### Nome não forma sk. Nunca.

O casamento por rótulo existe como **`candidato_sk_por_nome`** — sugestão para revisão
humana, **fora do sk**. São 88 candidatos, 2 deles ambíguos.

Dois casos desta casa provam por que a regra é essa:

- `PARA GUARDAR SELF STORAGE` (VJOB) e `PARA GUARDAR` (iClips) **só se ligam pelo nome**;
- no financeiro, a Vanguarda Comunicação entra como `B. R. M. COSTA DE LIMA E CIA` — que não
  contém a palavra "Vanguarda". Filtrar por nome lá **perde R$ 47.544,32 e traz R$ 40.067,03
  de outra empresa**.

### A R-003 continua valendo, e não conflita

A R-003 proíbe fundir **contas** cujo nome começa igual — as 10 `BRAGA *`, as 3 `PMZ *`, as 3
`UNIPAR *`. Aqui **nada é fundido por nome**: o que se agrupa é cadastro com o **mesmo
documento**, que é a mesma pessoa jurídica.

E o cadastro não desaparece dentro do sk. Quem quiser a conta individual lê a linha; quem
quiser a PJ agrupa por `cliente_sk`. É exatamente o que a R-003 permite: *"várias contas
dividirem a mesma tabela desde que não percam identidade dentro dela"*.

---

## Limitações declaradas — não contorne

1. **Metade do VJOB não tem documento.** 149 dos 315 cadastros ficam isolados, um sk cada.
   Não é defeito desta tabela — é o cadastro de origem. Para eles, ligar receita do VJOB a
   custo do iClips continua **impossível por prova**.
2. **O sk agrupa pessoa jurídica, não marca nem operação.** O CNPJ `16.665.666/0001-07`
   carrega três marcas (`PARA GUARDAR`, `HAYA SOLAR`, `PARA CHEGAR`) e vira **um** sk. Vanguarda
   Mídia Digital e VPromo dividem `26.123.250/0001-02` e viram um sk só — são a mesma PJ com
   dois cadastros. Quem precisa de marca lê o rótulo da linha.
3. **Cadastro de teste com CNPJ de verdade entra no sk da empresa real.** `CADASTRO TESTE
   MESMO CNPJ` divide o documento da Vanguarda Comunicação. `flag_rotulo_de_teste` marca
   (3 linhas) **e não remove** — o documento é o mesmo de fato.
4. **`candidato_sk_por_nome` não é conclusão.** Existe só onde o nome normalizado bate
   exatamente, e mesmo assim pode ser homonímia.
5. **Não inclui conta de mídia.** Google Ads e Facebook Ads não carregam CNPJ nas dimensões,
   então não há como ligar por documento. A ponte honesta ali continua sendo `gad_campaignid`.
6. O financeiro não tem cadastro próprio: cada documento distinto vira uma linha, com
   `cliente_nome` como rótulo — e **no financeiro esse campo é a razão social**.
   `gold_mvw_fin_cliente` não tem coluna `razao_social` (a `gold_vw_fin_cliente` tem).

---

## O que isso destrava, e o que ainda não

**Destrava:** receita (VJOB), projeto e peça (iClips), cobrança (Conexa) e lançamento
(financeiro) agora se agrupam pela mesma chave, para as 319 identidades multissistema.
A `rfn_financeiro__receita_cliente_mensal` pode passar a carregar `cliente_sk` em vez de
`id_cliente` do VJOB.

**Não destrava a margem.** Continua faltando `fact_custos`: o escopo conta peças e não horas.
O `custo_hora` do iClips (128 de 850 pessoas) agora **tem como chegar ao cliente certo** pelo
sk — mas sem hora gasta por cliente, não há o que multiplicar. O gargalo mudou de lugar: era
identidade **e** custo; agora é só custo.
