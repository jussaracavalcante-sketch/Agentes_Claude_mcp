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
