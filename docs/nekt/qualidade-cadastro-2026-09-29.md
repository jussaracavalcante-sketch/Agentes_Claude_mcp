# A suíte de CADASTRO — 34 regras, e a sexta identidade da casa

**29/09/2026.** `rfn_qualidade__regra_cadastro` (`query-5p6u`), Refined / `qualidade`,
**L2 INTERNAL**, gatilho de evento em `query-65kE` + `query-NxG1` + `query-hH5g` com
regra **`"all"`**, alerta ligado, deploy limpo. Cadência **diária**.

**A casa passa a ter 264 regras em OITO tabelas:** 84 diárias na principal, 19 semanais
no Conta Azul, 9 diárias no Gmail, 24 semanais em Mídia, 37 semanais no VJOB, 33 diárias
no iClips, 24 diárias em Marketing e 34 diárias aqui.

## O que ficava de fora

A família **cadastro inteira** — as três dimensões de identidade da casa e a Gold de
receita — **8.059 linhas materializadas sem uma única regra**:

| tabela | linhas | transformação |
|---|---:|---|
| `rfn_cadastro__cliente` | 409 | `query-65kE` |
| `rfn_cadastro__conta` | 190 | `query-Y1Yt` |
| `rfn_cadastro__cliente_vbot` | 4 | `query-NxG1` |
| `rfn_cadastro__cliente_vanguarda_comunicacao` | 5 | `query-hH5g` |
| `rfn_financeiro__receita_cliente_mensal` | 7.451 | `query-awMU` |

`rfn_cadastro__cliente_sk` **não** entra: o grão dela já é medido pela suíte principal
(1.353/1.353).

## Por que uma oitava suíte

Mesmo motivo da do Gmail, da do iClips e da de Marketing: a `rfn_qualidade__regra` está
com **57 KB e 84 regras** e `update_transformation` substitui o **código inteiro** —
somar regras lá exigiria reescrever 57 mil caracteres sem errar um, que é literalmente o
caso de *"query grande demais é query que não se conserta"* já registrado nesta casa.

O **contrato de colunas é idêntico** ao das outras sete, então um `UNION ALL` dá o painel
único e `familia` diz de onde veio cada linha.

## O gatilho cita três das cinco, e isso é o certo

As cinco vêm de **três cadeias diferentes**:

- `65kE`, `NxG1` e `hH5g` disparam as três em `query-8nEt` (iClips, **diária**);
- `Y1Yt` dispara em `jHEX`+`HCcd` (dimensões de conta de mídia);
- `awMU` dispara em `query-V3c3`, no fim da cadeia **semanal** do VJOB.

Amarrar as cinco com `"all"` faria a suíte **esperar a passada semanal para medir o que
muda todo dia** — e uma falha em qualquer ramo impediria as 34 regras de rodar, que é
exatamente a armadilha declarada na suíte do VJOB. O gatilho é `"all"` sobre os **três
irmãos que compartilham o mesmo upstream**; as outras duas são medidas como estiverem
materializadas.

**E por isso a regra de frescor tem escopo de FONTE, não de família.**
`cadastro.carga_do_mesmo_dia` compara `MAX(DATE(_extraido_at))` das **três tabelas do
gatilho, e só delas**. Incluir `conta` (outra cadeia) ou `receita` (semanal) faria a regra
falhar **por desenho, todo dia** — o mesmo erro que a suíte do iClips já evitou ao deixar
`peca_atributo` e `peca_categoria` de fora do frescor.

## A SEXTA IDENTIDADE DA CASA

`rfn_financeiro__receita_cliente_mensal.honorario_mais_repasse_e_o_total`.

A R2 daquela tabela diz, em maiúsculas, que **honorário e repasse não se somam como
receita da casa** — parcela sem fornecedor é entrega da casa (Fee Mensal, manutenção),
parcela com fornecedor tem um terceiro que recebe (veiculação, produção, comissão). As
duas colunas existem justamente para não serem confundidas, e `valor_total` existe só
para reconciliar com a Trusted.

A identidade testa que a decomposição é **exaustiva**: se um dia aparecer parcela que não
cai em nenhum dos dois lados, ela **some da leitura de honorário E da de repasse**,
`valor_total` continua batendo com a Trusted e **nada na contagem de linhas denuncia**.

**Medido, linha a linha: 7.451 avaliadas, ZERO fora de um centavo.**
R$ 19.757.217,94 + R$ 91.778.852,74 = **R$ 111.536.070,68**. BLOQUEANTE, limiar 1,00.

As cinco anteriores: `rateio_fecha_no_centavo` (custo) · `caixa_reproduz_o_razao`
(Conta Azul) · `itens_batem_com_a_auditoria` (VJOB) ·
`custo_reproduz_hora_vezes_valor_hora` (iClips) · `reproduz_a_trusted_linha_a_linha`
(Marketing).

## A segunda que importa guarda a R-003

`rfn_cadastro__conta.ambiguidade_nunca_vira_cnpj`. A Regra 2 daquela tabela declara que
nome do iClips apontando para **mais de um CNPJ é descartado** da ponte, e a conta recebe
`cnpj` NULL com `cnpj_ambiguo_na_origem = TRUE` — *"escolher um deles seria inventar
identidade jurídica"*. Hoje é **1 conta bloqueada de 190**. Se uma linha ambígua sair
**com** CNPJ, a tabela passa a atribuir empresa a conta por desempate — o que a R-003
proíbe — e a contagem de linhas não muda.

## A terceira é o que define as duas tabelas intragrupo

`..._vbot.cnpj_e_o_da_empresa` (`61077352000130`) e
`..._vanguarda_comunicacao.cnpj_e_o_da_empresa` (`07865616000174`).

Essas duas tabelas **não são recorte de conveniência**: elas existem porque **um CNPJ
define a empresa**, e a própria descrição delas avisa que filtrar por nome traz
R$ 40.067,03 de outra empresa e perde os R$ 47.544,32 que eram o alvo. Se um CNPJ
diferente aparecer, o filtro que dá nome à tabela se soltou. BLOQUEANTE, sobre 4 e 5
linhas.

## As outras que guardam premissa de verdade

- **`cliente.chave_concorda_com_o_metodo`** — a R1 usa fallback declarado: a chave é
  `CNPJ:<14 dígitos>` ou `ICLIPS:<id>`, e `chave_por` diz qual valeu. Chavear só por CNPJ
  perderia **60 dos 409 clientes (14,7%)**. Se a chave deixar de concordar com o método,
  o mesmo cliente pode aparecer em duas linhas — uma por CNPJ e outra por id — e o total
  continua parecendo certo.
- **`cliente.variacao_de_nome_decompoe`** e **`cliente.cadastro_duplicado_decompoe`** —
  as flags da R3 e da R4 têm de ser exatamente `qtd > 1`. São os únicos sinais de que a
  origem escreve o mesmo cliente de mais de um jeito.
- **`receita.cliente_sem_registro_nao_recebe_taxa`** — a R6 herda a doutrina da casa:
  zero de conclusão é NULL, nunca zero.
- **`receita.toda_linha_tem_um_lado`** — a R8 usa FULL OUTER e declara que **54% da
  receita** está em cliente-mês **sem** escopo; linha sem nenhum dos dois lados seria
  linha que o join inventou.
- **`receita.competencia_e_o_primeiro_dia`** — guarda a família de defeito já custosa
  nesta base: `DATE(MAX(ano), MAX(mes), 1)` combina ano e mês máximos
  **independentemente** e inventou 9 meses de erro no CNPJ 26.123.250/0001-02.

## Uma linha de base, de propósito

`receita.cliente_catalogado`, limiar **0,70** contra **76,2%** medido (1.772 de 7.451 com
`flag_cliente_nao_catalogado`). O buraco de cadastro do VJOB — escopo e contrato
apontando para cliente que não existe em `tbclientes` — é **da origem** e já está medido
nesta casa. Limiar apertado aqui só ensinaria a ignorar a suíte; o que se quer detectar é
**piora**. Mesmo precedente do 0,70 do escopo e do cronograma e do 0,78 da origem do PI.

## O que ficou de fora, e a ausência é a decisão

`rfn_cadastro__conta.fonte_nekt` preenchida. **Medido: 141 das 190 contas (74%) não têm
fonte Nekt** — são as contas que o MCC enxerga e a casa não integrou, mais a **dimensão
congelada** do Facebook (a fonte `facebook-ads-mrJt` foi excluída em 26/08 e a tabela é
uma foto daquele dia). Uma regra de completude ali acusaria o que é legítimo, e **regra
que acusa o que é legítimo ensina a ignorar a suíte**.

## Validação

A query inteira foi rodada antes de publicar: **34 regras, 34 ids distintos, CONFORME 34,
zero falhas.** A Nekt detectou **5 input tables** — as cinco da família; publicado e
escrito conferem.

Medições de apoio, todas sobre a tabela materializada em 29/09:

- `rfn_cadastro__cliente` — 409 linhas, 409 chaves, **349 por CNPJ + 60 por id do iClips**,
  349 com documento e **zero fora da forma**, zero sem nome, zero incoerências de chave,
  zero flags que não decompõem, zero janelas invertidas.
- `rfn_cadastro__conta` — 190 linhas, 190 chaves, 43 com CNPJ e **zero fora de 14 dígitos**,
  **1 ambígua e ela não tem CNPJ**, zero divergências de `cnpj_resolvido_por`,
  `identidade_juridica_resolvida` e `sem_razao_social`.
- intragrupo — VBOT 4 cadastros (ICLIPS, PI, VJOB), Vanguarda Comunicação 5 (CONEXA,
  FINANCEIRO, ICLIPS, VJOB), **zero CNPJ divergente nas duas** e `chave_por` em
  `CNPJ | ROTULO | ID_SISTEMA`.
- `rfn_financeiro__receita_cliente_mensal` — 7.451 linhas, 7.451 chaves e **7.451 pares
  (cliente, competência)**, identidade contábil com zero quebras, e zero falhas nas nove
  regras de consistência (taxa, lados, escopo, NFSe, competência, futuro, valor).
