# Derivado Supabase do VJOB · metade do escopo não tem conclusão registrada

Medido em 2026-09-21 sobre `vanguardamartech_raw.supabase_silver_vjob_escopo` (183.455 linhas).
Achado colateral ao levantamento do cadastro `TESTE HUGO SENNA`, e maior que ele.

> **CORREÇÃO DE SUJEITO — 2026-09-21, no mesmo dia.** Este documento fala do **derivado
> financeiro tratado** que as fontes Supabase publicam, **não do VJOB**. A distinção foi
> informada depois da medição: `supabase-fEvu` e `supabase-3gKz` carregam informação já
> tratada e empurrada para a plataforma; o **VJOB completo** está em `mysql-yIOn` (MySQL
> `vjob_2024`, 199 tabelas, camada `vanguardamartech_vjob_real_mysql`).
> **Os números abaixo continuam válidos sobre o derivado.** O que está **pendente de
> remedição** é se o mesmo padrão existe no sistema — e a fonte nova tem `tbescopofinal`,
> `tbescopofinal_datas` e `tbescopos`, que são as tabelas de escopo de verdade.
> Não citar nenhum número deste documento como "do VJOB" antes dessa remedição.

## O número

Janela 2025–2026, no VJOB inteiro:

| Métrica | Valor |
|---|---:|
| Clientes com escopo planejado | 251 |
| **Clientes com ZERO conclusão** | **86** |
| Escopos planejados | 146.336 |
| **Escopos em clientes que nunca concluíram nada** | **71.210 (48,7%)** |

Dos 86 clientes sem nenhuma conclusão: **38 estão marcados `cliente_ativo = true`** e
**23 têm `cliente_nome` vazio**.

## Não é a base que parou de registrar

A conclusão existe e continua acontecendo na base. O que caiu é a taxa:

| Ano | Escopos | Concluídos | Taxa |
|---|---:|---:|---:|
| 2023 | 19.322 | 10.506 | 54,4% |
| 2024 | 29.505 | 18.445 | 62,5% |
| 2025 | 62.868 | 20.120 | **32,0%** |
| 2026 | 83.448 | 18.840 | **22,6%** |

Duas coisas acontecem juntas: o volume planejado **triplicou** (29,5 mil → 83,4 mil) e a taxa
de conclusão **caiu à metade**. Então "zero conclusão num cliente" não é efeito de a base ter
parado — é específico daquele cliente.

## Os maiores casos

Todos com escopo até 10/2026 e **zero** conclusão desde 01/2025:

| id | Cliente | `cliente_ativo` | Escopos 25–26 |
|---:|---|---|---:|
| 26 | DENTIFY ODONTOLOGIA | false | 2.345 |
| 78 | REVEMAR AMAZONAS | **true** | 2.199 |
| 58 | PIZZARIA 2 GO | **true** | 2.167 |
| 141 | BRAGA VEÍCULOS PÓS VENDA | **true** | 1.974 |
| 98 | PNEU FORTE | false | 1.957 |
| 135 | CASTELINHO MATERIAL DE CONSTRUÇÃO | false | 1.824 |
| 50 | *(sem nome)* | false | 1.721 |
| 47 | DOCTOR MAIS SAÚDE | **true** | 1.704 |
| 127 | *(sem nome)* | false | 1.646 |
| 49 | AMAZOMIX | **true** | 1.643 |
| 44 | ALMEIDA & BARRETO ADVOGADOS | **true** | 1.626 |
| 75 | TROPICAL ATACADÃO | **true** | 1.568 |
| 56 | ORTHODONTIC | **true** | 1.548 |
| 153 | SKN INCORPORADORA | false | 1.462 |
| 97 | SMILE PNEUS | **true** | 1.449 |
| 60 | CAA TINTAS | **true** | 1.433 |
| 99 | DISTRIBUIDORA PNEU FORTE | **true** | 1.327 |
| 404 | *(sem nome)* | false | 1.258 — escopo até **01/2027** |
| 69 | ASLAN IDIOMAS | **true** | 1.256 |

## Duas causas possíveis, e o que separa uma da outra

**Causa A — o trabalho existe, o registro não.** 14 dos 86 casam por rótulo com cliente que
tem PI emitido desde 01/2025, somando **12.217 escopos**. Aí há entrega comprovada em outro
sistema e nenhuma conclusão no VJOB. O Tropical Atacadão tem 111 PIs na
`trs_pi__insercao`; a Braga Venda Direta, 55.

**Causa B — o escopo recorrente ficou ligado depois de a operação acabar.** O caso do
`TESTE HUGO SENNA` (id 146): 878 escopos em 2025–2026 e **nenhum rastro** em iClips, Conexa,
financeiro ou PI. Nada fora do VJOB.

**O que NÃO se afirma:** qual das duas vale para cada um dos 86. Para 49 deles não há evidência
independente em nenhuma direção, e os 23 sem nome não são identificáveis pelo dado. A
separação por rótulo (causa A) é **indicação, não prova** — o `silver_vjob_escopo` não tem CNPJ,
então o casamento com o PI é por nome.

## Contraprova — o registro funciona onde alguém registra

| id | Cliente | Escopos 25–26 | Concluídos |
|---:|---|---:|---:|
| 130 | VBOT | 817 | **702 (86%)** |
| 305 | CLIENTE TESTE | 1.196 | 7 |
| 74 | PARA GUARDAR SELF STORAGE | 950 | **0** |
| 146 | TESTE HUGO SENNA | 878 | **0** |

A VBOT, empresa do próprio grupo, mantém 86% de conclusão na mesma janela e na mesma tabela.
A mecânica do VJOB não está quebrada.

## O caso que originou o levantamento

`TESTE HUGO SENNA` (VJOB `id_cliente` 146) — **não é artefato de teste**, ao contrário do que o
nome sugere e do que este repositório afirmou até 21/09/2026.

**É um escopo completo de agência**, mensal, em 20 serviços: CARDS (320), BLOGS (102),
E-MAIL MKT (102), REELS (100), APROVAÇÃO PLANEJAMENTO CLIENTE (43), RELATÓRIOS (42),
APROVAÇÃO PI ON (41), REUNIÃO PLANEJAMENTO (36), FLUXO DE NUTRIÇÃO (34), PI MÍDIA PAGA (34),
CADASTRO SOCIAL/INBOUND ICLIPS (67), RELATÓRIO INBOUND/SOCIAL/MÍDIA PAGA (96),
VISITA AO CLIENTE (28), LANDING PAGE (17), MATERIAL RICO (14, trimestral) e outros.
Social, inbound, mídia paga e off — a carteira inteira.

**E pessoas reais trabalharam nele:**

| Ano | Escopos | Concluídos | Taxa | Pessoas distintas que marcaram |
|---|---:|---:|---:|---:|
| 2023 | 48 | 17 | 35% | 5 |
| 2024 | 237 | 180 | **76%** | 10 |
| 2025 | 502 | 0 | 0% | **0** |
| 2026 | 376 | 0 | 0% | **0** |

**O corte é exato.** Mês a mês na virada:

| Mês | Escopos | Concluídos | Pessoas |
|---|---:|---:|---:|
| 08/2024 | 17 | 17 | 6 |
| 09/2024 | 22 | 22 | 6 |
| 10/2024 | 28 | 22 | 6 |
| 11/2024 | 29 | 8 | 5 |
| **12/2024** | 30 | **0** | **0** |
| 01/2025 | 28 | 0 | 0 |
| … | … | **0** | **0** |
| 10/2026 | — | **0** | **0** |

Novembro/2024 é o último mês com qualquer conclusão. De dezembro/2024 em diante é zero todos
os meses, por 23 meses seguidos, enquanto o escopo mensal continuou sendo gerado.

## Consequência para indicador

A casa já classificou o **contador de atraso** do VJOB como inválido para uso como KPI. Este
achado estende o mesmo problema para a **conclusão**:

- **Taxa de conclusão agregada do VJOB não serve para nada** enquanto 48,7% do escopo estiver
  em clientes com zero conclusão — o denominador carrega escopo que ninguém trabalha ou
  ninguém marca, e os dois casos são indistinguíveis no dado.
- **Por cliente, conferir primeiro se existe QUALQUER conclusão na janela.** Zero conclusão com
  centenas de escopos planejados não é "100% de atraso"; é ausência de registro.
- **`cliente_ativo` não ajuda a separar:** 38 dos 86 estão marcados ativos.
- **Escopo futuro existe na base** — o cadastro 404 tem escopo até 01/2027. Qualquer contagem
  sem recorte de janela soma mês que ainda não aconteceu.

## Encaminhamento

Não é decisão de dados, é de quem opera o VJOB — a força-tarefa de prazos já existe e é
conduzida pela Jéssica Nery. O que o dado entrega pronto:

1. A lista dos 86 com id, rótulo, flag `cliente_ativo` e volume.
2. A separação dos 14 com PI desde 2025 (causa A provável) dos demais.
3. Os 23 cadastros sem nome, que precisam de identificação na origem.

**Nada foi alterado na origem nem na Nekt por conta deste achado.** É leitura e documentação.
