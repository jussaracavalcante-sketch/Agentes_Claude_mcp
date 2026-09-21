# VAN-SEM-001 · verificação das regras dos setores

Verificado em 2026-09-21 sobre o arquivo enviado
(`VANSEM001_Camada_Semantica_por_Setor_2.xlsx`, md5 `3ec409fbd0018ecd3ee76a6a0d953de9`).

**O arquivo é byte-idêntico ao recebido em 18/09.** Nenhum setor novo preencheu. Isso não é
crítica ao time — é o estado, e muda a ordem do trabalho.

---

## 1. Preenchimento real — 2 de 12 setores prontos

Critério é o da própria planilha, aba Consolidado: ficha completa (5 campos), ≥2 perguntas,
≥3 indicadores e ≥3 termos.

| Setor | Ficha /5 | Perguntas | Indicadores | Com "não vale" | Termos | Situação |
|---|---:|---:|---:|---:|---:|---|
| **Mídia Paga** | 5 | 3 | 4 | 4 | 4 | **PRONTO** |
| **Mídia off** | 5 | 2 | 3 | 2 | 5 | **PRONTO** |
| Social Media | 5 | 5 | 1 | 1 | 1 | incompleto |
| Inbound | 5 | 2 | 2 | 2 | 3 | incompleto |
| Account | 0 | 2 | 2 | 2 | 3 | incompleto |
| Criação | 0 | 2 | 2 | 2 | 3 | incompleto |
| Financeiro | 0 | 2 | 2 | 2 | 3 | incompleto |
| RH | 0 | 2 | 2 | 2 | 2 | incompleto |
| Dir. Executiva | 0 | 2 | 2 | 2 | 2 | incompleto |
| Dir. Operações | 0 | 1 | 1 | 1 | 2 | incompleto |
| Planej. Estrat. e Inovação | 0 | 2 | 1 | 1 | 2 | incompleto |
| Direção de Arte | 0 | 1 | 1 | 1 | 1 | incompleto |

**Os 8 com ficha = 0 não foram preenchidos por ninguém.** O conteúdo que aparece neles é a
linha azul pré-preenchida pela plataforma, não resposta do setor. As instruções da planilha
são explícitas: "Azul-claro = já preenchido, para validar."

### Correção de um registro meu

Em 18/09 indexei **quatro** setores na camada semântica tratando-os como preenchidos: Mídia
OFF, Social Media, Mídia Paga e Inbound. Pelo critério da planilha, **dois deles não estão**:

- **Social Media** — ficha 5 e 5 perguntas, mas **1 indicador e 1 termo**.
- **Inbound** — ficha 5, mas **2 indicadores** (o mínimo é 3).

Os dois documentos existem na camada semântica e **podem afirmar mais do que o setor validou**.
Não os apaguei: eles carregam pergunta de setor real, que é útil. Mas o nome deles diz
"validada pelo próprio setor", e isso é forte demais para o caso do Social Media e do Inbound.
**Pendência: qualificar o título dos dois**, ou completar com o setor.

---

## 2. As regras dos dois setores prontos, e o que elas cobram da plataforma

### Mídia Paga — João Araújo, Supervisor de mídia paga

Sistemas declarados: Semrush, Google Ads, Meta Ads, TikTok Ads, Kwai Ads, LinkedIn Ads,
Google Analytics, Biblioteca de Anúncios. Decide a cada 3 dias ou semanalmente.

| Indicador | Cálculo declarado | O que NÃO vale |
|---|---|---|
| Investimento | `SUM(investimento_micros) / 1.000.000` | **não** somar a coluna `investimento` (arredondada por linha: R$ 0,90 em 42 mil linhas); **não** somar BRL com USD |
| Cobertura demográfica | verba não-PMax ÷ verba total | **não** usar faixa etária/gênero para totalizar verba — `PERFORMANCE_MAX` não publica breakdown demográfico |
| Cobertura de termo de busca | verba com termo ÷ verba de SEARCH+SHOPPING | **não** usar verba total como denominador — DISPLAY, VIDEO e PMax não têm termo |
| Conta defasada | dias desde a última data com entrega | **não** ler como fonte parada: em **11 de 36** contas a extração rodou com sucesso — a conta é que parou de anunciar |

**Estado na plataforma: as quatro regras estão honradas e presentes na camada semântica.**
Verificado por busca no conteúdo indexado: `investimento_micros` 5 ocorrências,
`PERFORMANCE_MAX` 3, `termo de busca` 2, `defasada` 3, `BRL` 4. Dois documentos carregam a
regra de investimento — o do setor e o `Mídia — Métricas e KPIs da Refined`.

A regra 4 foi confirmada de forma independente em 21/09: medi **11 contas** com mais de 7 dias
sem entrega e `_extraido_at` recente em todas. O número do setor e o meu batem.

### Mídia off — Gilmar Miranda, Analista de Mídia

Sistemas declarados: iClips, VJOB, GloboAds, Ibope. Decide diariamente.

| Indicador | Cálculo declarado | O que NÃO vale |
|---|---|---|
| PIs criadas no período | contar PIs abertas — *"confirmar sistema de registro (iClips/VJOB)"* | — |
| Faturamento do mês + comissão | somar valor faturado de veiculação off e aplicar o percentual contratual | **não** misturar mídia off com on |
| Tarefas criadas para o setor | contar jobs abertos no VJOB para Mídia Off | **não** usar isoladamente como desempenho — cruzar com prazo e status |

**Duas observações que o dado já resolve, e uma que ele contradiz:**

- A dúvida do setor — *"confirmar sistema de registro (iClips/VJOB)"* — **está respondida**:
  medido em 18/09, PI não vem do iClips na Nekt, vem do Supabase, e a ponte é o
  `numero_projeto`. Consolidado em `trs_pi__insercao`.
- A regra "não misturar off com on" está implementada na `rfn_midia_off__pi`, regra 1
  (exclui `tipo_midia = 'Internet'`).
- **O indicador 3 depende do VJOB, e é o que está mais frágil:** o módulo de job do derivado
  Supabase está parado desde 24/08 (cadastro) e 02/09 (ação humana). E a fonte certa —
  `mysql-yIOn`, o VJOB real — foi conectada em 21/09 e ainda não materializou.

---

## 3. Falso alarme meu, registrado porque a verificação valeu

Ao ler a regra 1 de Mídia Paga, concluí que os números dos pilotos que eu havia acabado de
reportar violavam-na — eu usei `SUM(investimento)`, e a regra diz para não somar essa coluna.

**Medi antes de afirmar, e a diferença é zero** — nos 3 pilotos e na base inteira:

| Moeda | Linhas | Pela coluna | Pela regra (micros) | Diferença |
|---|---:|---:|---:|---:|
| BRL | 76.510 | R$ 1.378.300,95 | R$ 1.378.300,95 | **0** |
| USD | 1.306 | US$ 20.857,02 | US$ 20.857,02 | **0** |

**O motivo:** a `trs_google_ads__insight_diario` **deriva** `investimento` de
`investimento_micros / 1000000` (linha 297 do SQL). Na Trusted as duas colunas são idênticas
por construção — não existe coluna arredondada para somar por engano.

**Consequência para a regra:** ela está certa e é sobre a coluna **crua** do Google Ads
(`metrics_cost`), que a Trusted deliberadamente não usa. Como está escrita, alerta contra uma
coluna que na Trusted é segura. **Vale qualificar o escopo da regra** — "não somar a coluna
`investimento` **da Raw**" — para ninguém perder tempo com um falso positivo como o meu.

---

## 4. O que isto muda na replicação dos pilotos

O padrão dos pilotos **não é só SQL** — é Trusted **mais** as regras de leitura declaradas pelo
setor que consome. No Google Ads funcionou porque Mídia Paga respondeu.

Para as fontes restantes, o setor consumidor **não respondeu**:

| Fonte sem Trusted | Setor que consumiria | Ficha do setor |
|---|---|---|
| `github-s0VO` | time de dados / Planej. e Inovação | 0 |
| `linear-byrt` | time de dados / Planej. e Inovação | 0 |
| `rest-api-xk4P` (iClips apoio) | Criação, Dir. Operações | 0 |
| `gmail-c3ku`, `gmail-cF2Q` | Account, Dir. Executiva | 0 |
| `supabase-3gKz` | — (é o derivado financeiro do VJOB) | — |

**Ordem que a evidência sugere:**

1. **`github-s0VO` e `linear-byrt`** — sistemas técnicos, sem interpretação de setor a
   declarar: o consumidor é o próprio time de dados. Construir agora.
2. **`rest-api-xk4P`** — dimensão de apoio do iClips (templates de workflow, categorias).
   Alimenta tabelas que já existem; o grão é de cadastro, não de métrica.
3. **Gmail ×2 e `supabase-3gKz`** — esperar. Gmail tem dado pessoal e o setor consumidor não
   declarou o que precisa; a `3gKz` é o derivado financeiro que a Head corrigiu em 21/09.

## 5. O que NÃO foi feito, e por quê

- **Nenhum documento semântico apagado ou reescrito.** Os de Social Media e Inbound ficam,
  com a pendência de qualificar o título registrada acima.
- **Nenhuma regra de setor alterada por conta própria.** A sugestão de qualificar o escopo da
  regra 1 está escrita aqui, não aplicada — a regra é do setor.
- **Nenhuma Trusted construída neste levantamento.** A ordem acima é proposta com a evidência
  do preenchimento, não executada.
