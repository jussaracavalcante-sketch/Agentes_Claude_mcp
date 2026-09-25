# Conta Azul — o tratamento, e os dois sistemas que têm o mesmo nome

Medido em 2026-09-25. Tudo com `COUNT(*)` na tabela materializada, nunca com o
metadado do catálogo.

## 1. São dois Conta Azul, e eles não têm nada em comum além do nome

| | onde | o que é | linhas | dinheiro |
|---|---|---|---:|---|
| **(a) Espelho** | `mysql-yIOn` → `mysql_vjobvjob_2024_contazul_*` | catálogo de entidades + fila de envio, escrito pela integração que a casa construiu | 2.796 em 12 streams | **nenhum** |
| **(b) Razão** | `supabase-x0tz` → `raw.supabase_conta_azul_ca_fato_evento_financeiro` | o razão financeiro do ERP: parcelas a pagar e a receber, baixa, conta bancária, conciliação | 6.768 | **R$ 49,82 mi** |

O espelho **não tem valor nenhum**; o razão **não tem nome nem documento de
contraparte** — só `id_pessoa` como UUID. É por isso que o tratamento junta os dois:
sozinho, nenhum dos dois identifica quem pagou ou recebeu.

## 2. O achado: o razão mudou de sistema em junho/2026

Lançamentos por competência, os dois razões lado a lado:

| competência | iClips (`fato_movimento_financeiro`) | Conta Azul |
|---|---:|---:|
| 2026-03 | 966 | 28 |
| 2026-04 | 1.048 | 58 |
| 2026-05 | 708 | 397 |
| **2026-06** | **13** | **1.120** |
| 2026-07 | 0 | 1.089 |
| 2026-08 | 0 | 1.129 |
| 2026-09 | 0 | 614 |

A `trs_financeiro__movimento` declara a despesa "completa até a competência **2026-05**"
e a `rfn_operacao__custo_peca` fecha o mês por volume de lançamento, descartando 2026-06
em diante. **Não é mês não fechado — é handoff.** O razão continuou, em outro sistema, e
está no lake desde sempre, na Raw, sem tratamento.

Consequência: a janela em que a margem existe (**2022-12 a 2026-05**) é o fim do razão do
iClips, **não o fim do dado**.

**O que NÃO foi feito, e por quê.** Estender a margem exige decidir a sobreposição de
**2025-12 a 2026-05**, em que os dois razões têm lançamento. Isso é escolha de negócio com
risco de contar o mesmo dinheiro duas vezes; fica declarado nas descrições das duas
Trusted, medido, e não executado.

## 3. As quatro Trusted publicadas

| tabela | slug | linhas | nível | gatilho |
|---|---|---:|---|---|
| `trs_contazul__entidade` | `query-kwIs` | **1.828** | **L4** | evento em `query-MZdN` |
| `trs_contazul__categoria` | `query-y2xj` | 382 | L2 | evento em `query-kwIs` |
| `trs_contazul__vinculo` | `query-PdzT` | 10 | L2 | evento em `query-y2xj` |
| `trs_contazul__movimento` | `query-rtu2` | **6.768** | **L4** | evento em `query-PdzT` |

Cadeia linear, alerta de falha ligado nas quatro, deploy limpo nas quatro.
`mysql-yIOn` (domingo 00:00 `America/Manaus`) → `MZdN` → `kwIs` → `y2xj` → `PdzT` → `rtu2`.

**Cadência declarada:** o razão é atualizado **diariamente** pela `supabase-x0tz`, mas a
`trs_contazul__movimento` anda **semanal**, porque depende do espelho de entidade, que vem
do MySQL semanal. Pendurar o movimento na `supabase-x0tz` faria a query rodar antes de a
dimensão existir e derrubaria a query inteira. O custo é 6 dias de latência no pior caso.

## 4. As armadilhas medidas

### 4.1 — 37,7% do dinheiro do razão está REMOVIDO na origem
**1.518 de 6.768 parcelas** têm `removido_em` preenchido, somando **R$ 18.769.466,63 de
R$ 49.824.862,25**. Somar sem filtrar infla o total em **60%**. Vivo: saída R$ 14,51 mi,
entrada R$ 16,55 mi. A linha fica (marcar, nunca apagar) com `is_vigente`/`is_removido`.

### 4.2 — `data_pagamento` é 100% NULL e a data da baixa existe
**Zero** das 6.768 linhas tem `data_pagamento`; **3.329** têm a data dentro do JSON
`baixas[0].data_pagamento`. Uma série de caixa construída sobre a coluna devolve **vazio**,
e vazio parece um resultado. `data_emissao` também é 100% NULL — e por isso **não é
emitida**, mesma doutrina do `stats` do GitHub.

### 4.3 — `status_traduzido` mente sobre a direção
A origem escreve `RECEBIDO` também em parcela **a pagar** — 1.461 linhas. Ali "recebido"
quer dizer **quitado**. `status_canonico` traduz; `status_traduzido_origem` preserva o cru.
String vazia é sentinela em 505 linhas.

### 4.4 — "Transferência entre contas" vem em três grafias, e uma tem erro de digitação
`transferencia entre contas` · `transferencia entre  contas` (espaço duplo) ·
**`tranferencia entre contas`** (sem o `s`). O Conta Azul lança transferência dos **dois**
lados: sem separar, o mesmo dinheiro entra e sai e infla os dois totais. Só as três juntas
somam R$ 2.286.119,78. O padrão `tra%sferencia entre%contas` pega as três; `categoria`
preserva a grafia crua, porque normalizar antes de medir apaga o sintoma.

### 4.5 — O fornecedor é chamado de "veículo" pelo próprio sistema, e não é
O log `contazul_sincronizacoes` nomeia a carga de fornecedores de **`veiculos`**, e os
números batem exatamente (1.297 e depois 1.299). Mas dos **541** documentos válidos de
fornecedor, apenas **4** casam com os 92 CNPJs de veículo da `trs_pi__insercao`. O rótulo
diverge do conteúdo — **não usar como dimensão de veículo de mídia**.

### 4.6 — O mesmo fragmento de CNPJ, pelo quarto sistema
O único documento inválido dos 1.828 cadastros é **`871768534`** — nove dígitos, a máscara
`87.176.853/4___-__` preenchida pela metade. É exatamente o fragmento já registrado no VJOB
(cadastros 335/336, MOVE RENTAL CARS) e no financeiro (MOVE COMPANY LLC). **Nenhum `LPAD`
foi aplicado**: o valor corrigido não existe entre os documentos válidos desta base, e a
autoridade é o conjunto de documentos válidos, nunca a aritmética.

### 4.7 — Sete categorias duplicadas no plano de contas
382 categorias para **376 nomes** (375 após normalizar). Seis pares têm grafia **idêntica**
e dois UUIDs — "Custo com time", "Custo com freelancer", "Ajustes", "Ferramenta",
"Sistemas", "Outras Despesas Administrativas" — e um difere só na caixa. Agrupar custo por
`id_categoria` **parte "Custo com time" em dois**; agrupar por `nome` os junta. A tabela não
escolhe: emite os dois com `flag_nome_duplicado`.

## 5. O de-para de 10 linhas que prova a doutrina da casa

`contazul_vinculos` tem **10 linhas, todas MANUAL, todas ativas**, e **10 de 10 resolvem
dos dois lados, zero órfãos**. Em **seis** delas o nome é diferente nas duas pontas:

| VJOB | Conta Azul |
|---|---|
| VANGUARDA COMUNICAÇÃO | VANGUARDA COMUNICACAO DIGITAL LTDA |
| OLÁ CASA NOVA | FIT PONTA NEGRA - OLA CASA NOVA |
| Veiculação de Mídia | [MÍDIA PERFORMANCE] Comissão Mídia On - RT |
| VEICULAÇÃO DE MÍDIA ON | [MÍDIA PERFORMANCE] Comissão Mídia On |
| Manutenção de site | [DEV] Manutenção de Site |
| TIKTOK ADS / META ADS | [MÍDIA PERFORMANCE] Impulsionamento - ... |

Casamento por nome encontraria no máximo 4 dos 10. **Identidade por id, nunca por rótulo** —
e aqui isso não é doutrina, é o motivo pelo qual alguém teve de mapear à mão.

**Terceira confirmação independente:** os três vínculos de tipo `cliente` apontam para
**`tbclientesatedimentos`**, não para `tbclientes`. A integração que a própria casa escreveu
escolheu essa tabela. As duas evidências anteriores eram contagem de órfãos e casamento por
nome; esta é independente das duas.

## 6. Cobertura da junção, medida

| junção | cobre |
|---|---|
| evento → entidade (`id_pessoa`) | **5.395 de 6.768 (79,7%)** |
| evento → documento | **4.950 (73,1%)** |
| evento → categoria com nome | 6.314 de 6.768 (93,3%), por duas rotas |
| evento sem `id_pessoa` | 551 |
| `id_pessoa` que o espelho não tem | 822 |

As 822 não são defeito da junção: **o espelho parou de sincronizar em 17/08/2026** e o razão
recebe dado até 15/09. A cobertura só piora enquanto a sincronização não voltar.

**Contribuição para a identidade da casa:** dos 625 documentos válidos distintos de cliente
do Conta Azul, **414 existem em `rfn_cadastro__cliente_sk`**, 381 em
`trs_financeiro__movimento` e 122 em `trs_vjob__cliente`. São **211 documentos que o Conta
Azul conhece e a camada de identidade ainda não** — candidatos a entrar na `cliente_sk`, o
que **não foi feito** aqui.

## 7. O que NÃO virou tabela, e por quê

| stream | linhas | decisão |
|---|---:|---|
| `contazul_servicos` | 403 | **Não tratado.** O `nome` não é nome de serviço: **280 das 403 têm mais de 60 caracteres** e são linhas de descrição de nota fiscal (`"- 10,0 M³ DE CONCRETO FCK 35,0 MPA SLUMP 10 + / - 2 …"`). Não é dimensão. Entra na `trs_contazul__vinculo` só como rótulo. |
| `contazul_vendedores` | 20 | Absorvido na `trs_contazul__entidade` como papel `VENDEDOR` — mesmo esquema, mesmo espaço de chave. |
| `contazul_empresas` | 1 | Desnormalizado nas tabelas (documento e nome fantasia). Uma linha não é tabela. |
| `contazul_sincronizacoes` | 13 | **Não tratado.** É o log das cargas, e ele **não fecha com as tabelas**: três cargas de serviços registram `recebidos = 5000` (teto de paginação da API) quando a tabela tem 403. Serve para datar o congelamento (17/08/2026), e é o que está declarado nas descrições. |
| `contazul_vendas_envios` + `_historico` | 2 + 1 | **Não tratado.** São **envios de teste**: `motivo = "testes hugo"`, `PI 2147483647` (o máximo de um inteiro de 32 bits) e `PI 9999999999`. E **nenhum dos dois casa** com os 105 `contaazul_venda_id` distintos da `trs_vjob__cronograma_parcela` — são universos diferentes. |
| `contazul_oauth_conexoes` | 1 | **Nunca.** `access_token_criptografado`, `refresh_token_criptografado`. §31: secret é L5 e não deve estar no Data Lake. |
| `contazul_oauth_config` | 1 | **Nunca.** `client_secret_criptografado`. |

## 8. Escopo: uma empresa só

`empresa_chave` é constante em todas as 1.980 linhas do espelho e resolve para
`07.865.616/0001-74` — **VANGUARDA COMUNICAÇÃO**, razão social `B R M COSTA DE LIMA`.
No razão, `operacao` tem **BRM e VD**, e **não tem VBOT** — ao contrário da
`supabase_gold_mvw_fin_cliente`, que tem as três. **As duas fontes não são somáveis.**

## 9. O que a camada semântica ganha com isso

Os documentos de Financeiro (`a034ca75`) e Account (`64dc365b`), publicados em 25/09,
declaram que **fluxo de caixa diário**, **caixa realizado × projetado** e **"o que está por
faturar"** só existem na camada **Raw** — e a §18 diz que a IA não consulta a Raw.

A `trs_contazul__movimento` move o razão do ERP para a Trusted, com competência,
vencimento, data de baixa, conta bancária, método de pagamento e conciliação. **Três das
cinco perguntas sem resposta passam a ter origem governada** — falta a Refined que as
responda, e ela não foi feita hoje.

Ainda sem resposta na camada oficial: **inadimplência** (`vw_inad_titulos_vbot`) e
**turnover/tempo de casa** (`silver_colaborador_rel` — e RH continua sem nenhuma `rfn_`).

---

## 10. A Refined saiu no mesmo dia — `rfn_financeiro__fluxo_caixa` (`query-FDpl`)

**5.237 linhas, 5.237 chaves, L4, gatilho de evento em `query-rtu2`, alerta ligado, deploy
limpo.** Grão: uma parcela do razão em um regime de caixa. Chave: `<id_movimento>:<regime>`.

**Fecha três das cinco perguntas órfãs da camada semântica** — fluxo de caixa por dia, caixa
realizado × projetado e aging/inadimplência de BRM e VD. Continuam sem resposta a
inadimplência da **VBOT** (operação que não existe no razão Conta Azul) e "o que está por
faturar" antes de virar parcela (funil, ainda na Raw).

### Os dois regimes, e por que eles não duplicam

| regime | `data_caixa` | `valor_caixa` | linhas | soma |
|---|---|---|---:|---:|
| REALIZADO | data da baixa | `valor_pago` | 3.205 | **R$ 21.227.444,68** |
| PREVISTO | vencimento | `valor_nao_pago` | 2.032 | **R$ 9.793.507,73** |

Os dois totais batem **ao centavo** com `SUM(valor_pago)` e `SUM(valor_nao_pago)` do razão.
Uma parcela parcialmente paga aparece nos dois, com o valor repartido — 3 casos.

### O que a construção obrigou a decidir, medido

**As 16 parcelas zeradas ficam de fora.** `valor_pago = 0` **e** `valor_nao_pago = 0`, com
R$ 30.252,20 de valor de face. Não são caixa nem saldo. 5.250 vigentes → 5.237 linhas:
5.234 parcelas presentes, 3 em dois regimes, **16 ausentes**, declarado.

**O que entrou no banco não é o valor de face, em 760 parcelas.** `valor_pago + valor_nao_pago`
rompe a face em **772 das 5.250** — 694 para mais (juros, multa), 78 para menos (desconto),
maior diferença **R$ 10.167,16**. Caixa se mede com `valor_caixa`; `valor_face` fica ao lado e
`diferenca_para_a_face` mostra o quanto, com sinal.

**A situação vem da data, nunca do rótulo de status.** 395 parcelas estão vencidas pela data e
**285 delas não carregam `ATRASADO`** na origem — só 110 carregam. **Filtrar atraso pelo status
da origem perde 72% dos casos.**

**Uma parcela paga sem data de baixa (R$ 27.500) entra com o vencimento**, com
`flag_data_caixa_estimada` acesa. Descartá-la faria o caixa realizado divergir do razão; a
alternativa não tomada — deixar sem data — está escrita na descrição.

### Aging medido em 25/09

| | vencido | a vencer |
|---|---:|---:|
| **a receber** | **R$ 1.046.743,14** (233 parcelas) | R$ 4.815.921,93 (815) |
| **a pagar** | R$ 481.933,17 (162) | R$ 3.448.909,49 (822) |

A inadimplência concentra-se na primeira faixa: **171 parcelas e R$ 829.218,24 com até 30
dias**. `is_inadimplencia` exclui TRANSFERENCIA, FINANCEIRO e SOCIOS — transferência entre
contas próprias, mútuo e adiantamento de sócio não são inadimplência de terceiro.

### Caixa realizado por mês

2026-05 R$ 15.501,23 (5 parcelas, cauda da migração) · 06 R$ 5,40 mi · 07 R$ 7,12 mi ·
08 R$ 6,91 mi · 09 (até o dia 15) R$ 1,75 mi.

### A limitação que manda

**O caixa realizado começa em 25/05/2026.** Não há **uma única baixa** anterior, embora a
competência vá até 2025-02: o Conta Azul recebeu os saldos em aberto na migração e só passou a
registrar liquidação depois. **Série de caixa antes de junho de 2026 não existe nesta base** — e
o iClips, que cobre o período anterior, **não registra data de pagamento por parcela**. Quem
pedir caixa de 2025 não tem resposta em lugar nenhum deste warehouse.

E **não somar com `trs_financeiro__movimento` nem com `rfn_financeiro__receita_cliente_mensal`**:
aquelas medem **competência**, esta mede **caixa**, sobre períodos que se sobrepõem de 2025-12 a
2026-05.

---

## 11. As regras de qualidade — `rfn_qualidade__regra_contazul` (`query-AQjU`)

**19 regras, L2, gatilho de evento em `query-FDpl`, alerta ligado, deploy limpo.** A Nekt
detectou exatamente **5 input tables** — as cinco do Conta Azul. Publicado e escrito conferem.

### Por que uma segunda tabela de qualidade, e por que não é duplicação

A suíte principal (`rfn_qualidade__regra`, 61 regras) dispara em `query-dGga`, que roda **todo
dia ~07:10**. A família Conta Azul dispara em `mysql-yIOn`, que roda **domingo**. Duas
consequências, e as duas decidem:

1. **As cinco tabelas não existem ainda** — foram publicadas hoje, depois da última carga da
   `mysql-yIOn` (24/09 12:43). Referenciar tabela não materializada **derruba a query inteira**.
   Somar estas 19 regras à suíte principal a faria **falhar amanhã às 07:10 e levaria as 61
   regras junto, todo dia, até domingo**.
2. Aqui elas rodam como **gate de pós-carga**: o gatilho é o último elo da cadeia do Conta Azul,
   então medem a tabela **no instante em que ela acabou de ser reescrita** — não seis dias depois.

**O contrato de colunas é idêntico** ao da suíte principal, de propósito: um `UNION ALL` entre as
duas dá o painel único, e a coluna `familia` diz de onde veio cada linha. Fundir é opção futura;
hoje seria trocar 61 regras diárias por um erro.

### As 19 regras, medidas antes de publicar

Todas medidas sobre a Raw e o espelho, reproduzindo a lógica das Trusted linha a linha, porque as
tabelas ainda não existem. **Resultado esperado na primeira execução: 19 conformes, zero falhas.**

| família | regras | medição |
|---|---:|---|
| `trs_contazul__entidade` | 4 | chave 1.828/1.828 · dedup não diverge 0/1.828 · documento em forma 1 falha em 1.053 (99,91%) · tem documento 1.052/1.828 (57,6%) |
| `trs_contazul__categoria` | 2 | chave 382/382 · nome preenchido 0 falhas |
| `trs_contazul__vinculo` | 2 | os dois lados do de-para resolvem, 10 de 10 em cada |
| `trs_contazul__movimento` | 6 | chave 6.768/6.768 · valor ≥ 0 · classe conhecida · competência preenchida · contraparte 79,7% · categoria com nome 93,3% |
| `rfn_financeiro__fluxo_caixa` | 5 | chave 5.237/5.237 · data preenchida · data não estimada 1/3.205 · zero órfãos · **a identidade contábil** |

### A regra que importa mais é uma identidade contábil

**`rfn_financeiro__fluxo_caixa.caixa_reproduz_o_razao`.** O fluxo promete que a soma de cada
regime reproduz o razão — REALIZADO = `SUM(valor_pago)` e PREVISTO = `SUM(valor_nao_pago)` das
parcelas vigentes. Até aqui isso era **afirmação na descrição, medida à mão uma vez**. Agora é
teste, com grão **REGIME**: 2 linhas avaliadas, **diferença ZERO nas duas**
(R$ 21.227.444,68 e R$ 9.793.507,73 dos dois lados). BLOQUEANTE, limiar 1,00 — se ela falhar,
todo número de caixa desta casa está errado. É a irmã da
`rfn_operacao__custo_peca.rateio_fecha_no_centavo`.

### Dois limiares são linha de base de propósito, e um existe para PIORAR

- **`entidade.tem_documento` em 0,55** contra 57,6% medido. 42% do cadastro não tem documento e
  isso é da **origem** — não vai se corrigir sozinho. Limiar apertado ali só ensinaria a ignorar
  a suíte, que é o erro que esta casa já cometeu e registrou.
- **`movimento.contraparte_resolvida` em 0,75** contra 79,7% medido. **É a única regra da leva
  que existe para piorar:** o espelho de entidades parou de sincronizar em 17/08/2026 e o razão
  recebe dado até hoje, então a cobertura cai sozinha a cada semana. **Cruzar o limiar significa
  que a sincronização precisa voltar** — não que o tratamento quebrou.

### A hipótese que foi testada e REPROVADA

A candidata óbvia era **"transferência entre contas bate nos dois lados"** — o Conta Azul lança a
transferência como saída numa conta e entrada na outra, então os dois totais deveriam ser iguais.
**Medido: não batem.** Nas 115 linhas vigentes de TRANSFERENCIA a entrada soma
**R$ 1.145.265,94** e a saída **R$ 835.452,42** — **R$ 309.813,52 de diferença**, um lado sem par.

Publicar isso como regra criaria uma falha permanente que ninguém pode resolver, que é exatamente
o que ensina a ignorar a suíte. Fica como **achado**: quem somar a classe TRANSFERENCIA encontra
um líquido de R$ 309 mil que é **artefato de pareamento, não dinheiro** — e isso reforça por que
`is_caixa_operacional` a exclui.
