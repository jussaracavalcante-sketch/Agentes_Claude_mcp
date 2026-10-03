# Os 136 streams sem tratamento do VJOB — o que foi tratado, o que foi declarado

**Medido em 2026-09-24.** O inventário dos 199 streams deixou **136 sem tratamento com
linha, somando 111.456 (31,5% da base)**. Este documento diz o que aconteceu com eles.

**Não viraram 136 tabelas Trusted, e isso é decisão declarada.** 91 dos 199 streams têm
10 linhas ou menos, boa parte é tabela de junção sem conteúdo próprio, e 10 carregam
credencial — uma Trusted por stream produziria dezenas de tabelas que ninguém consultaria
e algumas que a §31 proíbe. O critério foi: **trata o que carrega informação que nenhuma
outra tabela carrega; declara o resto, com a medição que sustenta a decisão.**

## O quadro

| | streams | linhas |
|---|---:|---:|
| Sem tratamento antes de hoje | 136 | 111.456 |
| **Tratados hoje** | **12** | **55.154 (49,5%)** |
| Restam declarados | 124 | 56.302 |

---

## O achado que reorganizou tudo: o VJOB tem DOIS cadastros de cliente

`tbclientes` (317) é o cadastro **jurídico** — CNPJ, razão social, responsável.
`tbclientesatedimentos` (310) é a **conta de atendimento** — squad, grupo, carteira,
classe, data de contrato, desativação. A ponte é `id_tbclientes`, e ela cobre
**310 de 310, com 6 sem correspondente**.

Esta base vinha medindo **todo** módulo contra `tbclientes` e chamando o resultado de
"buraco de cadastro da origem". Medido, órfãos contra cada um:

| tabela | vs `tbclientesatedimentos` | vs `tbclientes` |
|---|---:|---:|
| `tbauditoriaclientes` 3.025 | **0** | 1.372 (45,4%) |
| `tb_logs_squad` 2.332 | **0** | 923 (39,6%) |
| `tbauditorias` 56 | **0** | 28 |
| `tbarquivosauditoria` 54 | **0** | 28 |
| `tbblogs` 1.323 | **2** | 252 |
| `checklist_diario` 2.748 | **5** | 214 |
| `tbetapasxclientes2` 7.782 | 1.856 | **882** |
| `tbescopofinal` 195.163 | 24.778 | **43.329** |

**Não é uma regra, é uma medição por tabela.** Escopo e etapa continuam pendendo de
`tbclientes` — no escopo isso já tinha sido provado por NOME (155 de 156 rótulos casam lá,
zero aqui), e a contagem de órfãos sozinha teria levado à conclusão errada.

### E não era falta de dado: era identidade TROCADA

Dos 46 ids de cliente da auditoria, **20 encontravam par em `tbclientes`** — e nos **vinte
o nome diverge** do nome da conta. **Zero batem.** A `rfn_operacao__conformidade_cliente`
publicada hoje de manhã estava atribuindo **nome e CNPJ de outra empresa** a 20 dos 46
clientes da auditoria, e chamando os outros 26 de "sem cadastro".

Casar por id de outra sequência é o mesmo erro de casar por rótulo: **produz par onde não
há.** Corrigido no mesmo dia.

---

## As 6 Trusted publicadas (12 streams, 55.154 linhas)

| tabela | slug | linhas | streams cobertos |
|---|---|---:|---|
| `trs_vjob__acesso` | `query-OwrE` | **49.206** | `acessos2` 47.857 + `acessos` 1.349 |
| `trs_vjob__checklist_diario` | `query-OFX4` | 2.748 | `checklist_diario` + `tbchecklist` 34 |
| `trs_vjob__auditoria_servico` | `query-TkGA` | 1.387 | + `tbservicosauditoria` 27, `tbcategoriasauditoria` 4, `tbsetoresauditoria` 5 |
| `trs_vjob__blog_pauta` | `query-8JWf` | 1.323 | `tbblogs` |
| `trs_vjob__cliente_atendimento` | `query-BuYc` | 310 | `tbclientesatedimentos` |
| `trs_vjob__auditoria_ciclo` | `query-w4wL` | 56 | `tbauditorias` + `tbarquivosauditoria` 54 |

**O que cada uma compra, que nenhuma outra tabela tinha:**

- **`trs_vjob__acesso`** — o maior volume sem tratamento da base. Quem entrou na intranet e
  quando, de 23/05/2019 a **24/09/2026 10:49** (hoje). **É L4, não L5:** as duas origens têm
  três colunas (`id`, `idusuario`, `datahora`) e nenhuma credencial — o inventário as
  classificava junto com os tokens do Conta Azul. São **duas origens independentes**: zero
  pares (usuário, data-hora) em comum e janelas que se sobrepõem.
- **`trs_vjob__auditoria_servico`** — a dimensão que a `trs_vjob__auditoria_cliente`
  declarou não existir. Resolve **3.025 de 3.025 itens e 1.339 de 1.339 ids, zero órfãos**.
  Armadilha: a coluna chamada `categoria` aponta para `tbservicosauditoria` (subserviço),
  não para `tbcategoriasauditoria` — 0 órfãos contra a primeira, 699 contra a segunda.
- **`trs_vjob__blog_pauta`** — **a única tabela desta base que liga uma entrega à linha de
  escopo que a pediu**: `id_escopo` resolve 1.183 de 1.323 com **1 órfão**. E carrega
  `link_iclips`, uma segunda ponte para fora do VJOB. Módulo parado em 18/12/2025.
  "Publicado" é declaração, não prova: 1.064 com status, **849 com link, 719 com data**.
- **`trs_vjob__checklist_diario`** — terceiro instrumento da base em que a conclusão sempre
  data a ação: **2.748 de 2.748 com carimbo**. Só 8 das 34 atividades do catálogo foram
  usadas. Parado em 04/02/2026.
- **`trs_vjob__auditoria_ciclo`** — os 56 ciclos somam **exatamente 3.025 itens** e nenhum
  está vazio. 54 finalizados = 54 com data. **36 dos 56 (64%) não registram quem abriu**, e
  os 20 restantes são todos da mesma pessoa.
- **`trs_vjob__cliente_atendimento`** — o estado de squad que o log declarava não existir,
  e a chave que destrava as outras.

## As 3 correções em tabelas já publicadas

| tabela | slug | o que mudou |
|---|---|---|
| `trs_vjob__auditoria_cliente` | `query-LQ5u` | cliente, setor e serviço passam a resolver pela dimensão certa: **0 órfãos nos três** (eram 1.372, 584 e "não existe"). CNPJ sobe de 17 para **37 das 46 contas**, 2.282 dos 3.025 itens. |
| `trs_vjob__squad_alteracao` | `query-SLRc` | cliente pela conta de atendimento: **0 órfãos** (eram 923). Ganha nome da conta e ponte jurídica, **zero nulos nas duas**. |
| `rfn_operacao__conformidade_cliente` | `query-ecYs` | cada origem resolve contra **a sua** dimensão. O join único atribuía cliente errado a 20 dos 46 da auditoria. Surgem **33 CNPJs presentes nos dois instrumentos** — antes o cruzamento era impossível. |

**Os números de conformidade não mudam** (510 linhas, taxa 98,66% e 36,27%, pontualidade
34,07% e 39,12%): a identidade não entra no grão nem no denominador. **O que muda é quem é
o cliente de cada linha.**

## A cadeia ficou linear, e isso não é detalhe

```
mysql-yIOn → query-MZdN → query-BuYc → query-TkGA → query-8JWf
           → query-OFX4 → query-LQ5u → query-DYWJ → query-ecYs
```
Mais `query-w4wL` e `query-SLRc`, que penduram em `TkGA` e `BuYc` e não têm dependente.
Evento em paralelo não garante ordem; aqui cada elo dispara no anterior.

---

## Os 124 que ficam, e por quê

### Não entram em Trusted por política — 10 streams, 1.272 linhas
`tbusuariointranet` 272 (senha + prontuário de RH; já entra minimizada na
`trs_vjob__usuario`) · `tarefas_tb_acl_cliente_usuario` 486 · `tbclientes_acessos` 253 ·
**`tbrh_renovacoes` 125** (salário **criptografado** em `novo_salario` — é folha) ·
`tbportalusuarios` 73 · `tarefas_tbjobs_aprovacao_inicial_tokens` 46 · `tbpermissoes` 8 ·
`usuario` 7 · `contazul_oauth_conexoes` 1 · `contazul_oauth_config` 1.

A §31 diz que secret não deve estar no Data Lake. Estão na Raw desde 21/09 e **desabilitar
stream não apaga** — a exclusão é backoffice.

### Já decidido, com medição — 1 stream, 6.094 linhas
`tbclientexservico`: das ~60.940 células de flag possíveis, **sete** estão preenchidas.
Uma Trusted emitiria dez colunas constantes zero.

### Junção sem conteúdo próprio — 3 streams, 4.200 linhas
`tbnoticiasextra2` 3.732 e `tbnoticiasextra` 460 são `(id, idnoticia, idusuarios)` — **recibo
de leitura**. O conteúdo é `tbnoticias`, que tem **8 linhas**. 4.192 recibos para 8 notícias.

### Candidatos reais, medidos e não tratados hoje — os próximos
- **Conta Azul, 2.796 em 12 streams** — `contazul_fornecedores` 1.299, `clientes` 661,
  `servicos` 403, `categorias` 382. É integração financeira viva e merece Trusted própria.
- **`municipio` 5.570 + `estado` 27** — dimensão geográfica IBGE. **Tem consumidor:**
  `trs_vjob__cliente` carrega `id_cidade` e `uf`.
- `tbrelatorioacoes` 430 — log de ação de usuário em texto livre.
- `tbcronogramadatas_analista_historico` 282 — troca de analista na parcela; mesma família
  do `squad_alteracao`.
- `tbgestoresclientes` 234 + `tbgestores` 15 — gestor por cliente.
- `tbonboardingclientes` 213 + `tbonboardingclientes2` 103 + `tbonboardingetapas2` 63 +
  `tbonboardingetapas` 28 — **as datas vêm NULL na amostra**; medir o preenchimento antes de
  tratar, pelo precedente do `tbclientexservico`.
- `tbetapasxclientes` 207 — a v1 da etapa; 107 órfãos contra `tbclientes`.
- `tbsetupcolaborador_status` 198 · `tblinks`+`2`+`3` 230 · `tbcheckin_*_config` 115 ·
  `tbvideoextra` 90 · `tbescopo_public_links` 70 (**token, L5**) ·
  `tbcronograma_on_verbas` 65 · `tbfuncao` 49 · `tb_sub_servicos_servico` 29.

### A cauda — ~70 streams com 10 linhas ou menos
Tabelas de domínio de módulos mortos e restos de configuração. Contadas no inventário,
não caracterizadas. **Não se apaga nada**; o que não se faz é criar Trusted para cada uma.

---

## Duas lições que valem além deste lote

1. **Contagem de órfãos sozinha não identifica o pai.** No escopo ela apontaria para
   `tbclientesatedimentos` (24.778 contra 43.329) e o pai é `tbclientes` — provado por nome.
   **Medir nos dois sentidos e confirmar com uma segunda evidência.**
2. **Órfão é melhor que falso par.** O join errado da auditoria não deixava a linha vazia:
   preenchia com outra empresa. Uma flag acesa é visível; um nome errado não é.
