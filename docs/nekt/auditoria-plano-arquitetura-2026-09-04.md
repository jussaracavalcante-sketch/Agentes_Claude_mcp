# Auditoria do plano de arquitetura contra a base real — 2026-09-04

Plano recebido em 2026-09-04, seções 2 a 8. Este documento confere cada recomendação contra
o que a base efetivamente tem, medindo em vez de opinar. Nada aqui foi aplicado — é insumo
de decisão.

## Veredito curto

O plano está tecnicamente correto na maior parte. Três coisas:

1. **Boa parte já está feita** — não por seguir o plano, por convergência.
2. **Dois pontos conflitam com decisões já tomadas** pela Jussara e não devem ser aplicados
   sem reabrir a decisão.
3. **Um ponto é um risco real, e eu o medi hoje pela primeira vez.** O plano acertou ao
   chamá-lo de "o erro mais caro". Detalhe na seção própria.

---

## O achado: reconciliação com a plataforma

O plano diz que reconciliar spend com a interface das plataformas é "o teste de confiança
número um". Eu nunca tinha feito — todas as minhas validações até hoje foram **internas**
(Trusted contra Raw, Refined contra Trusted). Consistência interna não prova nada sobre
fidelidade à plataforma.

Feito hoje contra a API do Google Ads, 4 contas, 12 meses-conta:

### Investimento: passa

**Bate ao centavo em todos os meses fechados, em todas as contas testadas.** Exemplos:

| Conta | Mês | Nossa Trusted | API Google Ads |
|---|---|---:|---:|
| PMZ GRUPO ECOMM | ago/26 | 32.425,99 | 32.425,99 |
| PMZ GRUPO ECOMM | jul/26 | 19.759,50 | 19.759,50 |
| PMZ GRUPO LOJA | ago/26 | 18.905,71 | 18.905,71 |
| BIGAZINE | jun/26 | 2.901,62 | 2.901,62 |

A tolerância de ±1–2% que o plano sugere é folgada demais para o nosso caso: estamos em 0%.

### Conversões: não passa em toda conta

| Conta | Mês | Nossa | API | Δ |
|---|---|---:|---:|---:|
| PMZ GRUPO LOJA | jun/26 | 4.740 | 4.740 | 0 |
| PMZ GRUPO LOJA | jul/26 | 8.483 | 8.483 | 0 |
| PMZ GRUPO LOJA | ago/26 | 8.020 | 8.020 | 0 |
| BIGAZINE | jun/26 | 138,760731 | 138,760731 | 0 |
| BIGAZINE | jul/26 | 211,137940 | 211,137940 | 0 |
| BIGAZINE | ago/26 | 72,681037 | 75,767999 | **−4,1%** |
| PMZ GRUPO ECOMM | mai/26 | 119,29 | 119,29 | 0 |
| PMZ GRUPO ECOMM | jun/26 | 198,28 | 203,38 | **−2,5%** |
| PMZ GRUPO ECOMM | jul/26 | 263,72 | 268,96 | **−1,9%** |
| PMZ GRUPO ECOMM | ago/26 | 261,19 | 270,44 | **−3,4%** |

**Diagnóstico, com o cuidado de não exagerar:**

- O mês mais recente diverge em **todas** as contas com conversão fracionária (−3 a −4%).
  Isso é atribuição em curso e é esperado.
- A BIGAZINE **converge** em junho e julho. Isso prova que o reprocessamento funciona: dado
  antigo é relido e assenta.
- A PMZ GRUPO ECOMM **não converge** em junho nem julho, meses fechados há 1 e 2 meses. Para
  essa conta a reatribuição vai além do que a extração relê.
- Contas com conversão **inteira** (last-click) batem exato sempre — não há reatribuição a
  perseguir.

**O que não sei:** o valor da janela de reprocessamento. O campo `lookback_window` existe no
`connector_config` das fontes de Google Ads e de Facebook, mas o MCP redige o valor (`"***"`).
Só é legível na interface web da Nekt.

**O que sei e é acionável:** `settings_full_sync_cron` é **null** nas fontes que inspecionei
(`google-ads-rSav`, `facebook-ads-Si4U`). Não existe ressincronização periódica completa.
Então o único mecanismo que corrige histórico é a janela de lookback, e para a PMZ ECOMM ela
não está alcançando.

**Exposição:** das 32 contas de Google Ads com dado desde junho, **12 usam conversão
fracionária**, e essas 12 carregam **R$ 215.011,89 de R$ 270.156,20 — 79,6% do investimento**.
Não medi as 12; medi 2. A extrapolação seria minha, não da evidência.

---

## O que o plano recomenda e já está feito

| Recomendação do plano | Estado na base |
|---|---|
| Fato unificado com `plataforma` como dimensão | Feito hoje. `rfn_midia__desempenho_diario`, 65 colunas, `GOOGLE_ADS` + `FACEBOOK_ADS` |
| Dimensão unificada de campanha | `trs_google_ads__campanha` e `trs_facebook_ads__campanha` |
| Tipagem e unidades (micros vs decimal) | Feito. Google soma em micros e divide na saída; Facebook multiplica por 1e6 para alinhar |
| Deduplicação por chave composta | Feito. `QUALIFY ROW_NUMBER() ... ORDER BY updated_time DESC` |
| De-para de objetivos para taxonomia única | `objetivo_canonico` na dimensão de Facebook, tratando ODAX vs legado |
| Métricas derivadas calculadas na camada de serviço, não no BI | Feito e documentado: recalculadas dos totais, com aviso explícito de nunca usar `AVG` |
| Metadados de ingestão | `_extraido_at`, `_fonte`, `_payload_hash` |
| Granularidade mínima diária por conta+campanha | Melhor que o pedido: anúncio-dia na Trusted |
| Freshness check | Feito hoje, e melhor que o proposto: `conta_defasada` vive **na tabela**, não num monitor externo |

## O que conflita com decisão já tomada

**1. Layers por estágio compartilhadas com `client_id` como partição lógica.**
Conflita com a R-001, que é política da empresa: cada fonte grava na sua própria camada, e o
motivo declarado é permissionamento. O plano reconhece a exceção ("segregação física por
exigência contratual") — na Vanguarda a política já decidiu por segregação. Não aplicar sem a
Jussara reabrir a R-001.

**2. Converter tudo para moeda única com tabela de câmbio diária.**
A `rfn_midia__desempenho_diario` **não converte, de propósito**, e declara "não some entre
moedas sem filtrar". Não existe tabela de câmbio nesta base. Converter sem ela seria inventar
número; criar a tabela é projeto próprio, não um ajuste.

## O que é gap real e não está feito

**1. SCD tipo 2 nas dimensões.** O plano está certo e a Nekt tem suporte nativo: cada stream
tem `process_as_scd_type_2_on_destinations`, e está **`false` em todos** os streams que
inspecionei. Hoje as dimensões guardam só o estado atual — campanha renomeada reescreve o
passado. Mitigação parcial existente: `campanha_no_dia` e `status_campanha_no_dia` no Google
preservam o valor do dia a partir do fato. No Facebook o `status_campanha_no_dia` é NULL,
porque o insight não carrega status por dia.

**2. Camada semântica.** Zero documentos de contexto cadastrados. É o diferencial da
plataforma e está inteiramente por fazer. Toda regra de negócio numerada nas descrições das
transformações é candidata direta.

**3. Convenção de nomenclatura de campanha.** O plano diz que a implantação é o momento de
impor uma. Não existe convenção nesta base, e sem ela não há atributo analítico extraível do
nome. É decisão de operação de mídia, não de engenharia de dados.

**4. Breakdowns.** O plano pede age, gender, placement, device. As fontes de Google Ads já
extraem `age_range_performance`, `gender_performance`, `geographic_performance`,
`user_location_performance` e `search_term_performance` — os streams estão **habilitados** e a
Raw tem os dados. Nada disso tem Trusted. Dado pago e ingerido que ninguém usa.

**5. Alertas.** Estado misto, e aqui eu errei antes: na varredura de 03/09 afirmei "alertas
desligados na maioria das fontes" sem ter como saber — o campo `subscribed_to_alerts` não vem
na listagem, só no detalhe fonte por fonte, e eu não abri as 84. Medido hoje por amostra:
`facebook-ads-Si4U` está com alerta **ligado**; `google-ads-rSav` está **desligado**; as
transformações que inspecionei (`query-OTSI`, `query-MHyi`, `query-skPU`) estão desligadas.
O número real exige varrer as 84 fontes uma a uma.

**6. ROAS blended e pacing.** As fórmulas do plano que não existem hoje: ROAS blended (exige
receita de CRM/GA4, que não está integrado) e pacing de budget contra verba **contratada** —
essa não sai da plataforma, sai do contrato, e não há fonte dela na base.

## Sobre o roadmap proposto

O plano propõe 7 semanas começando por "definição de nomenclatura de layers e conexão de um
cliente piloto". Isso descreve um projeto começando do zero. A base tem **95 fontes vivas,
41 transformações e 21 camadas**, com Google Ads e RD Station consolidados e o Facebook
fechado hoje. O roadmap útil não é o de implantação: é o de fechar os gaps acima, e nessa
ordem eu poria (1) reconciliação como rotina, (2) camada semântica, (3) Trusted dos
breakdowns já ingeridos.
