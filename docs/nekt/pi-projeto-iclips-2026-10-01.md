# 01/10 — o PI lia a tabela errada de projeto: 11 PIs casavam, 967 deveriam

`trs_pi__insercao` (`query-iX2P`) ligava o PI ao projeto do iClips por `numero_projeto` contra
`trs_projetos__projeto` (91 projetos). Trocada para `trs_iclips__projeto` (12.109).

## O que foi medido (2026-10-01, sobre 3.348 PIs e 238 `numero_projeto` distintos)

| tabela de projeto | PIs que casam | projetos distintos |
|---|---:|---:|
| `trs_projetos__projeto` (antes) | 11 (0,3%) | — |
| `trs_iclips__projeto` (agora) | **967 (28,9%)** | 99 |

88× no grão da linha. O cabeçalho antigo dizia que a baixa cobertura era "janela, não chave" e
que subiria sozinha; não subiu. **O motivo de a tabela de 91 ser tão menor não foi investigado.**

**A troca não muda o que já existia:** os 91 projetos da tabela antiga existem todos na nova e
em 91/91 nome, status, grupo, responsável, verba, peças, tarefas, apontamentos, entrada e
conclusão são idênticos. Única diferença: `cliente_efetivo_nome` em 2 (Grupo Nova Era, cliente
vazio) — a semântica `COALESCE(cliente, grupo)` foi replicada. Tipos preservados.
Bônus: a tabela antiga tinha `data_conclusao` nula nos 91; `projeto_data_conclusao` agora
tem valor.

## A ponte tem duas evidências independentes

1. Nome do projeto bate em **966 de 967** (TRIM/UPPER).
2. CNPJ do cliente no monitoramento (Supabase) = CNPJ do projeto (iClips) em **855 de 856** PIs
   que têm os dois (99,88%).

**A única divergência é o caso R-003:** PI 22889 diz `CAA ALUMÍNIO`, o projeto 30287 é
`CAA l AGOSTO 2026`, CNPJs `09675751000182` × `16640671000157`. Não foi desempatado:
`flag_projeto_nome_diverge` e `flag_documento_projeto_diverge` acendem nessa linha (1 cada).

## Colunas novas (todas aditivas — nenhuma existente mudou de nome ou tipo)

`projeto_cliente_id` · `projeto_cliente_cnpj` (dígitos) · `projeto_cliente_is_pf` ·
`flag_projeto_nome_diverge` · `flag_documento_projeto_diverge`.

**Ganho:** o PI passa a ter documento de cliente pelo projeto em **966** PIs e preenche **110**
que o monitoramento deixa sem `cliente_cnpj` (49 não cancelados, R$ 270.499,48). Sobram
**79 PIs não cancelados sem documento por nenhum caminho**. Os dois documentos ficam lado a lado.

## O que continua parcial

139 dos 238 projetos citados (58%) não existem na `trs_iclips__projeto`. Causa **não
verificada** (hipótese: a API entrega por janela). `tem_projeto_no_iclips = false` não é "PI sem
projeto".

**Defasagem declarada:** o gatilho é a `supabase-x0tz`; a `trs_iclips__projeto` vem do
`notebook-Rbpo`. O projeto lido pode ser o da passada anterior (até 1 dia). Gatilho não
acoplado de propósito.

## Dívida datada (entra depois da carga de 02/10 ~01:00)

Nada disto existe como coluna materializada ainda; regra de qualidade que cite coluna
inexistente derruba a suíte inteira.
1. Regras na suíte de Mídia Gold: `flag_documento_projeto_diverge` ≤ limiar de linha de base
   (hoje 1 de 856) e `flag_projeto_nome_diverge` idem.
2. `rfn_cliente__contexto` liga o PI por **rótulo** (`pi_vinculado_por`). Com
   `projeto_cliente_cnpj` passa a existir caminho por documento para 966 PIs; trocar só depois de
   medir sobre a tabela materializada.
3. Repontar a menção em `rfn_cadastro__cliente_vbot` ("PI 22557 tem `tem_projeto_no_iclips =
   false`") só depois de medir se o PI passa a casar.

Validação antes do deploy: 3.348 linhas / 3.348 chaves, 967 com projeto, 966 com documento,
flags 1 e 1, 110 documentos ganhos. Deploy limpo (`deploy_failed: false`).
