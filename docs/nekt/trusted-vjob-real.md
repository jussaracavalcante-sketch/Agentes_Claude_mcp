# Trusted do VJOB real (MySQL) — cliente e escopo

**Publicadas em 2026-09-23** · camada `Trusted`, folder `vjob` · alerta de falha ligado nas duas.

| Tabela | Slug | Linhas | Gatilho |
|---|---|---:|---|
| `trs_vjob__cliente` | `query-MZdN` | 315 | evento em `mysql-yIOn` |
| `trs_vjob__escopo` | `query-Ty76` | 195.163 | evento em `query-MZdN` |

A segunda dispara **na primeira**, não na fonte: depende dela para resolver o cliente.
A cadeia anda **semanal** — `mysql-yIOn` roda domingo 00:00 `America/Manaus`.

Arquivos: `sql/trusted/trs_vjob__{cliente,escopo}.sql`.

## O fuso: medido, não herdado

A convenção da casa diz que o VJOB grava hora local. Essa convenção foi estabelecida
sobre o **derivado Supabase**, e a fonte agora é outra — então foi medida de novo, por
dois caminhos independentes:

**(a) O mesmo registro nos dois lados.** `tbjobs` id 1461 no MySQL e no payload bronze
do Supabase carrega o relógio idêntico: `2026-08-24 11:15:59`. A extração não deslocou.

**(b) O almoço.** A distribuição horária das 57.163 marcações de escopo:

| Hora | 9 | 10 | 11 | **12** | 13 | 14 | 15 | 16 | 17 | 18 | 19 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Marcações | 2.421 | 7.744 | 5.456 | **9.566** | 1.982 | 1.711 | 4.471 | 5.083 | 5.118 | 5.870 | 3.638 |

Pico às 12h, queda às 13-14h, retomada até as 19h. É o almoço da casa. Se o dado fosse
UTC, esse "almoço" cairia às 10-11h — que não é almoço de ninguém.

**Portanto `DATETIME(ts)` sem argumento de fuso.** Aplicar `'America/Sao_Paulo'` aqui
subtrairia 3 horas de um dado que já é local — o espelho exato da armadilha que custou
seis tabelas do iClips entre agosto e setembro.

### Uma consequência: dois números que reportei em 21/09 estavam 3 horas adiantados

`tbjobs` tem último cadastro **24/08/2026 11:15:59** e última checagem/aprovação
**02/09/2026 11:26:33**. Em 21/09 registrei 14:15:59 e 14:26:33 — exatamente +3h.
Caí na armadilha que este repositório documenta. Os números de escopo daquele dia
(11/09 18:11:09) estavam certos.

## O achado: 96 clientes com escopo não têm cadastro

**96 dos 251 clientes do escopo (38%) não existem em `tbclientes`**, e carregam
**44.356 escopos (23% da base), dos quais 19.416 concluídos**.

Não é falha de extração — as duas tabelas vieram da mesma carga, no mesmo minuto. É a
origem que tem escopo apontando para cadastro que não existe mais.

**O join está certo, e isso foi testado.** A hipótese natural era que `id_cliente`
apontasse para `tbclientesatedimentos` (308 linhas, que existe e tem `id_tbclientes`).
Testada contra os nomes já resolvidos no derivado:

| Tabela candidata | Nomes que batem |
|---|---:|
| `tbclientes` | **155 de 156** |
| `tbclientesatedimentos` | **0** |

Hipótese descartada. `flag_cliente_nao_catalogado` acende nas 44.356 linhas, e o LEFT
JOIN é proposital — com `INNER`, um quarto da base sumiria sem nenhum sinal.

Isso também explica o que eu tinha visto pelo derivado: os "23 dos 86 clientes com
`cliente_nome` vazio" registrados em 21/09 são parte deste mesmo buraco. O derivado
resolve nome para 156 dos 251 — os outros 95 são praticamente os 96 órfãos.

## O que o sistema tem e o derivado não

**`datahoramarcado`.** A coluna que data a conclusão existe aqui e **não existe** em
`supabase_silver_vjob_escopo`. Até 21/09 a casa registrava que "a tabela de escopo não
carimba quando a conclusão foi marcada" — verdade sobre o derivado, falso sobre o
sistema. O derivado perdeu a coluna no caminho.

**11.708 linhas.** 195.163 no sistema contra 183.455 no derivado.

**`tbclientes`.** A tabela-pai de cliente, com CNPJ. Até 21/09 este repositório
afirmava que ela não existia em nenhum stream — verdade sobre o Supabase.

## Cobertura das medições

| Medida | Valor | Cobertura |
|---|---:|---|
| Escopos | 195.163 | 100% |
| Concluídos (`status = 1`) | 68.016 | 34,9% da base |
| Conclusões **com** carimbo | 57.090 | **84% das conclusões** |
| Conclusões sem carimbo | 10.926 | 16% — não datam a ação |
| Carimbo sem conclusão | 73 | marcado e desmarcado |
| Cadastros com CNPJ | 166 de 315 | 53%, em 139 CNPJs distintos |

**Qualquer série temporal de conclusão cobre 84% das conclusões**, e a cobertura tem de
vir junto com o número. `flag_concluido_sem_carimbo` existe para isso.

## Dado pessoal fica fora

`tbclientes` traz `cpf` (21 linhas), `responsavel`, `telefone`, `email`,
`emailfinanceiro` e `endereco` — contato de pessoa física. A Trusted emite apenas
**flags de presença** (`tem_cpf`, `tem_email`, `tem_endereco`…), para que a completude
do cadastro possa ser medida sem o dado sair. Mesmo critério do e-mail no Linear e no
GitHub.

As 14 colunas de papel (`customersuccess`, `analistamkt`, `analistasocial`…) saem como
**ids** de usuário da intranet, mais um `qtd_papeis_alocados` (média 3,43, máximo 9).
Resolver esses ids contra `tbusuariointranet` esbarra em CPF, RG e dado de RH — quem
for montar essa dimensão trata disso antes.

## Limitações declaradas — não contorne

1. **A ponte por documento cobre metade.** 166 de 315 cadastros têm CNPJ. Para os 149
   sem documento, ligar a iClips ou ao financeiro é casamento **por nome** — hipótese
   declarada, nunca prova.
2. **139 CNPJs distintos para 166 preenchidos**: há CNPJ repetido entre cadastros.
   Cadastro não é empresa. Agrupar por `cnpj_digitos` pode fundir contas que a R-003
   manda manter separadas.
3. **Contar conclusão pelo mês de cadastro inverte o sinal** — foi o que aconteceu em
   21/09. Use `marcado_em`, nunca `cadastrado_em`.
4. **A base tem escopo futuro** — competência até 09/2027. Contagem sem recorte de
   janela soma mês que ainda não aconteceu.
5. **`id_servico` sai como id, sem nome.** A tabela de domínio de serviços não foi
   localizada no catálogo nesta passagem. O derivado resolve 34 dos 38 e deixa 4 como
   "(outro)" (ids 10, 17, 19 e 27, somando 7.980 escopos), então herdar dele também não
   fecharia. Maiores por volume: CARDS 71.195 · REELS 15.398 · STORIES 13.370 ·
   E-MAIL MKT 11.512 · BLOGS 9.575.
6. **Campos mortos, fora da tabela:** `setor` (valor 0 nas 195.163 linhas),
   `servicoextra` (0 em todas), `id_canal_publicacao` (um único valor distinto),
   `google_event_id` (1 linha), `nicho` do cliente (vazio nas 315).
   `status2` a `status7` são quase vazios (90, 33, 238, 3, 4 e 76 linhas).
7. **O derivado marca 82 linhas como concluídas que o sistema marca `status = 0`**, e
   essas 82 têm `status2..status7` todos nulos — a divergência não se explica por
   nenhuma coluna de status. O sistema é a fonte de verdade.
8. `nome_quemmarcou` está preenchido em 66.422 linhas contra 57.163 marcações — sobra
   nome sem carimbo. Identidade por `id_quemmarcou` (156 pessoas), nunca pelo rótulo.

## Pendente

- **Achar a tabela de domínio de serviços** para resolver os 38 ids. Sem ela, o escopo
  é contável mas não legível por serviço na Refined.
- **`tbclientes` tem 315 cadastros e o escopo referencia 96 ids que não estão lá.**
  Saber se são cadastros excluídos ou outra tabela ainda não localizada é trabalho de
  origem, não de query.
- `id_insercao` está preenchido em **148.617 escopos (76%)** e é string. Pode ser a
  ponte com PI/inserção — não medido nesta passagem.
- `tbcronograma` / `tbcronogramadatas` (10.036 linhas, com valor e faturamento) e
  `tbjobs` (1.354) seguem sem Trusted sobre o sistema. Existe uma `trs_vjob__job` em
  `vanguardamartech_trusted` com 1.514 linhas, construída sobre o **derivado** — ela
  precisa ser remedida contra o MySQL ou aposentada.
- **`ia_cliente_config`** (3 linhas) tem `biblia_resumo`, `tom_voz`, `palavras_evitar`,
  `regras_inegociaveis`, `fatos_verificados` e `elementos_visuais` — é a estrutura de
  contexto de marca que `contexto-cliente-arquitetura.md` presumia não existir.
  Preenchida para 3 clientes.
