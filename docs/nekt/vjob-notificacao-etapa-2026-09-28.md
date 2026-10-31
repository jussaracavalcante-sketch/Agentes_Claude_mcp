# `rfn_operacao__notificacao_etapa` — o alerta de vencimento funcionou 25 dias e foi desligado

**Publicada em 2026-09-28** · `query-4cZZ` · Refined / `operacao` · **2.283 linhas** ·
**L4 PERSONAL_DATA por linhagem** · gatilho de evento em `query-UpoG` · alerta ligado ·
deploy limpo.

Grão: um **tipo de notificação**, um cliente, uma etapa, um mês de envio.
Origem: `trs_vjob__sms_notificacao` (11.068) + `trs_vjob__cliente_atendimento` (só para a
pista de nome).

## A Trusted estava errada sobre o que ela é

A descrição publicada em 24/09 dizia: *"notificação automática de **etapa vencida** por
cliente"*. Medido em 28/09: **são duas famílias de mensagem, e a de vencimento é a menor.**

| família | formato | envios | clientes | etapas | período |
|---|---|---:|---:|---:|---|
| **CONCLUSAO** | `Olá, <CLIENTE>. A etapa <ETAPA> já foi finalizada.` | **7.920 (71,6%)** | 48 | 64 | 22/05/2025 → **25/09/2026** · viva |
| **VENCIMENTO** | `Venceu desde (DD/MM/AAAA) a etapa <ETAPA> do cliente <CLIENTE>` | **3.148 (28,4%)** | 22 | 51 | 23/05/2025 → **16/06/2025** · morta |

**Os dois padrões cobrem 11.068 de 11.068 — zero não reconhecidas.**
`flag_padrao_nao_reconhecido` é o gatilho de manutenção do parser: mensagem nova sumiria da
leitura por tipo **sem a contagem mudar**, o mesmo mecanismo já declarado no parser da
`trs_vjob__acao_administrativa`.

## O achado

**3.148 envios para apenas 164 situações distintas** (cliente, etapa, data de vencimento) —
média de **19,2 envios por situação**, janela média de 5,2 dias e máxima de 24. Era **cobrança
diária**. Depois de **16/06/2025 não houve mais nenhuma**, enquanto a notificação de conclusão
seguiu até 25/09/2026.

**Não é ausência de etapa vencida.** A `rfn_operacao__conformidade_cliente` mede **60,8% das
marcações de etapa acontecendo depois do prazo**. O que parou foi o **aviso**, não o atraso.

Quem lesse a descrição antiga concluiria que a casa notifica atraso hoje. Ela não notifica
desde junho de 2025.

## `qtd_envios` não é "quantas vezes avisou"

É "quantos SMS saíram" — e as duas famílias se comportam ao contrário. Medido no grão
(situação, dia):

| família | situação-dia | envios/dia | destinos/dia | envios > destinos |
|---|---:|---:|---:|---:|
| VENCIMENTO | 787 | **4,00** | **4,00** | **0 de 787** |
| CONCLUSAO | 2.172 | 3,65 | 2,70 | **1.051 de 2.172** |

**VENCIMENTO: quatro destinatários fixos, um SMS cada, todo dia. Zero duplicidade.**
**CONCLUSAO: há disparo em duplicidade, e só nela** — pico de **50 envios para 6 destinos num
único dia**.

No total, **2.058 dos 11.068 envios (18,6%) são duplicata do mesmo destino no mesmo dia**, em
1.013 das 2.283 linhas. Por isso a tabela emite `qtd_envios`, `qtd_destinos_distintos` e
`qtd_envios_duplicados`: **quem quer alcance lê destinos, quem quer custo lê envios, quem quer
defeito lê a diferença.**

## Cliente e etapa são rótulo, não id

Os dois vêm de texto livre dentro da mensagem. **63 rótulos distintos de cliente: 47 casam com
`trs_vjob__cliente_atendimento` por nome e TRÊS casam com mais de uma conta.**

O id sai em `candidato_id_atendimento_por_nome` **só quando o casamento é único** (1.999
linhas), com `flag_nome_ambiguo` (122) e `flag_nome_sem_correspondente` (162) nos demais —
mesma doutrina do `candidato_sk_por_nome`: **pista fora da chave, nunca dentro dela**. A R-003
proíbe fundir conta por nome parecido, e isto respeita a regra.

## A etapa não tem domínio nesta base — conferido, não suposto

`trs_vjob__etapa_cliente` tem `id_servico` (67 valores) e **nenhum nome de etapa**;
`tbetapas` tem **4 linhas** e `tbetapas2` tem **5** — nenhuma é o domínio dos 67.

Então **o nome da etapa só existe aqui, dentro do SMS**, e não há como ligar a notificação ao
registro da etapa por prova. Ligar por rótulo seria hipótese, não junção.

## As outras regras

**R4 — `venceu_em` só existe na família de vencimento**, e sai NULL na outra: nunca uma data
inventada. Verificado nos dois sentidos — 2.095 linhas de CONCLUSAO com NULL (100%) e 188 de
VENCIMENTO com data (100%). `dias_ate_a_ultima_cobranca` tem máximo de **44 dias**. Datas de
vencimento medidas: 28/04/2025 a 15/06/2025.

**R5 — o mês é o do ENVIO**, não o do vencimento. A notificação é o evento; o vencimento é o
assunto dela.

## Classificação L4 por linhagem, com a prova do que passou

O **telefone não é emitido** (só contagem de destinos distintos) e o **corpo da mensagem não é
emitido** (só o comprimento máximo). O que passa é `cliente_rotulo`, e ele **pode ser nome de
pessoa física** — medido, há ao menos um cliente PF entre os 63 rótulos. Por isso o nível **não
desce** de L4, ao contrário da `rfn_operacao__custo_peca`, que provou que nenhum dado pessoal
atravessou.

## Limitações — não contorne

1. **SMS registrado não é SMS entregue.** Não há status, retorno de operadora nem custo em
   lugar nenhum desta base. Contar envio é contar intenção.
2. **1.210 dos 7.920 envios de CONCLUSAO (15,3%) não têm telefone em forma válida** — e
   **zero** dos de VENCIMENTO.
3. **48 clientes, não a carteira.** A notificação cobre um recorte pequeno.
4. **Não medir atraso por aqui.** Atraso se mede na `rfn_operacao__conformidade_cliente`, que
   compara marcação contra prazo. Esta tabela mede o **aviso**.

**FUSO:** relógio local da intranet, herdado da Trusted. Não converter.

## A cadeia foi linearizada — quarta vez

`query-UpoG` disparava em `query-MZdN`, **em paralelo com `query-BuYc`** — e esta Refined lê as
duas. Repontado:

`mysql-yIOn` → `query-MZdN` → `query-BuYc` → `query-UpoG` → `query-4cZZ`

**Evento em paralelo não garante ordem.** A descrição da Trusted foi atualizada junto, e o
comentário do código dela também — a afirmação falsa não podia sobreviver em nenhum dos dois.

## Ainda não materializou

Entra na passada de domingo. As regras de qualidade sobre ela entram quando a tabela existir; a
candidata é a identidade aditiva (`SUM(qtd_envios)` = total da Trusted) e a cobertura do parser
(`flag_padrao_nao_reconhecido` = 0).
