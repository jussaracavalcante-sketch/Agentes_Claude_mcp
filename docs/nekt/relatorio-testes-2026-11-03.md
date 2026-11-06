# Relatório de testes — camadas semânticas, fontes e carga (03/11/2026)

Escopo pedido: testes de qualidade nas camadas semânticas e nas fontes, testes como usuário e testes de carga, com subagentes. Quatro subagentes somente leitura rodaram por volta de 09h–10h de Brasília, **no meio da passada semanal de terça** (Meta e Google Ads ainda carregando). Nenhum pipeline foi rodado pelos subagentes. Brutos em `/tmp/claude-0/-home-user-Agentes-Claude-mcp/187754c1-8d2c-5c55-878d-19623df74717/scratchpad/qa-*.md` (não versionados).

## 1. Resumo

| Frente | Resultado |
|---|---|
| Qualidade dos dados das fontes | 7 famílias de teste; 0 duplicatas em 22 tabelas; 5 suítes revalidadas por SQL independente, nenhuma mentiu; 1 falha bloqueante real (margem VBOT, **corrigida**, ver §3); congelamentos de Google Ads e iClips; ramo Facebook do `desempenho_diario` defasado |
| Camada semântica (estrutura) | 31 documentos alcançados, 0 não achados; 2 anotações mortas em 1 documento; 286 tabelas citadas, 4 inexistentes e 2 publicadas sem materializar; 25 divergências numéricas (6 acima de 40%); 8 contradições entre documentos |
| Personas (30 perguntas, 5 personas) | 14 corretas, 14 com ressalva, 2 sem resposta governada, 0 erro; resposta sempre saiu de tabela Refined |
| Carga | ~110 chamadas SQL, **zero erro de plataforma**, joelho **não encontrado** até 18 consultas simultâneas; ~1,98 GB escaneados |

## 2. Qualidade dos dados das fontes

| Teste | Objetos | Passaram | Falharam |
|---|---:|---:|---:|
| Frescor | 25 | 20 | 1 atrasada, 4 congeladas |
| Unicidade de chave | 22 | 22 | 0 |
| Completude | 16 | 10 | 6 (NULL > 5% em coluna-chave) |
| Validade | 8 | 5 | 3 |
| Reconciliação entre camadas | 12 pares | 11 | 1 |
| Sucesso sem dado | 2 fontes + 7 contas Meta | confirmados | 0 |
| Suítes revalidadas por SQL | 5 regras | 5 | 0 |

**Congeladas e atrasada.** Google Ads (insight 86.978 linhas, extração de 22/10) e `rfn_midia__desempenho_diario` Google; iClips peça (134.883) e tarefa (8.970) em 19/10. O ramo Facebook do `desempenho_diario` está em 20/10 enquanto a Trusted Meta vai a 27/10: R$ 63.866,06 (5.646 linhas) de 21 a 27/10 ficam fora da Refined, mais R$ 9.276,05 (0,15%) de diferença antes de 20/10.

**Suítes não mentiram, mas medem dado velho.** Principal (84) e iClips (53) têm carga de 19/10; as sete de mídia/Google Ads de 23/10. A suíte principal mediu 529.650 linhas na Trusted Meta que hoje tem 539.904.

**Completude e validade (o que importa).**
- VJOB escopo: 47.457 de 207.213 (22,9%) sem cliente; CNPJ NULL 41,0%; `dt_prazo` NULL 30,6%; 2 prazos com ano 0002.
- iClips peça: 134.559 de 134.883 (99,8%) sem data planejada.
- RH `colaborador_mes`: setor NULL 39,4%, cargo NULL 20,5%.
- Conta Azul: 177 parcelas com competência 2029–2033 (R$ 975.121); contraparte não catalogada em 12,8% do movimento.
- Meta: cliques maiores que impressões em 67 de 539.904; 51 de 64 contas com entrega nos últimos 9 dias (as "13 de 64" da suíte).
- Linear: 196 de 230 issues sem responsável. GitHub e webhook Z-API: `COUNT(*)` = 0.

**Reconciliação.** Fecham sem diferença: Meta Trusted × Refined mensal, RD conversão (443.926), Conta Azul movimento × categoria × fluxo, Instagram 1.994 mídias, Páginas 563 posts, TikTok 1.379 vídeos, VJOB escopo (207.213 nas três camadas), GA4 (sessões 9.986.402, receita 4.195.123,50). Falha: ramo Facebook do `desempenho_diario`.

## 3. Falha bloqueante da margem VBOT — causa e correção

`rfn_financeiro__margem_vbot_mensal` (`query-WsJj`) falhava em `x0tz_gold` ("receita_conexa reproduz a Trusted", 1 de 1). Causa: **carga desalinhada, não defeito de lógica.** A Refined rodou em 02/11 10:01:46Z e a Trusted de origem (`trs_vbot__margem_cliente`) terminou 33 s depois. Out/2026 ficou R$ 13.030,20 abaixo e nov/2026 R$ 25.716,85 abaixo (R$ 38.747,05 no total); 2025-12 a 2026-09 batiam ao centavo.

**Correção (autorizada pela usuária):** a `query-WsJj` estava em `pending_events` (o disparo direto é recusado nesse estado). Rodei o upstream `query-E3Xr` (`trs_vbot__conta_mes`, 09:56, 11 s); o `all` completou e a `query-WsJj` rodou sozinha às 09:57 (sucesso). **Conferido na tabela:** set R$ 220.948,92, out R$ 220.823,64, nov R$ 60.235,48, iguais à Trusted. O classificador negou o disparo manual da `query-UEOA`, que não foi necessário (o evento dela já existia). A suíte `x0tz_gold` só reflete isso na próxima execução; **não foi relida**.

## 4. Camada semântica — estrutura

- **Anotações:** 2 mortas, ambas em Governança (`8350ebe2`): `@table::Refined::rfn_operacao__fato_job` (não existe; o certo é `rfn_operacao__job`) e `@source::facebook-ads-mrJt` (fonte excluída). Nenhum `@table::` aponta para tabela não materializada.
- **Números velhos (25 divergências, 10 documentos):** Mídia (`9cd50802`) diz `rfn_midia__desempenho_diario` = 87.774 linhas, medido 189.760 (+116%); Operação/Account trazem `job` 3.372 e 3.433, medido 4.596; `escopo_mensal` 71.036 contra 74.272; `cliente_sk` aparece com três valores (1.353, 1.372, 1.376 medido); RD 277.001 contatos contra 279.273.
- **Contradições:** RH setor diz que turnover só sai da Raw (existe `rfn_rh__turnover_mensal`); Diretoria Executiva diz que caixa realizado × projetado não tem resposta (existe `rfn_financeiro__fluxo_caixa`); Inbound e Mídia Paga dizem que GA4 não tem fonte (são 51); Governança diz 7 contas de Facebook e 36 de Google (medido 64 e 40).
- **Qualidade e Índice** (`2da109d6`, `8f8ed60e`) dizem "1.631 regras, todas conformes": a leitura era 1.630 + 1 falha (a da margem, agora corrigida).
- Documentos de setor: banner "NÃO validado" nos 6 pré-preenchidos e ausente nos 4 validados, como esperado.

## 5. Testes por persona (30 perguntas)

14 corretas, 14 com ressalva, 2 sem resposta governada. Latência do SQL principal 276–814 ms. **O problema é o tamanho da resposta semântica:** 58–340 KB, 28 das 30 estouraram o limite de tokens e foram para arquivo; 3 de 10 perguntas compostas voltaram `matched:false`.

Ressalvas mais graves:
1. **PII na camada de consumo:** `rfn_marketing__conversao.campos_conversao_json` preenchido em 443.926 de 443.926 linhas, com e-mail em 443.914, telefone em 182.333 e nome em 297.698 (agregados; nenhum valor reproduzido). O documento de Marketing diz que `custom_fields` não atravessa; o de Inbound manda consumir essa tabela. **Não corrigido; é decisão sobre dado pessoal.**
2. **Defasagem invisível na Mídia:** `conta_defasada` e `dias_sem_entrega` são gravados na carga, então 51 de 64 contas Meta aparecem "em dia" com 14 dias parados; a comparação set→out fica distorcida.
3. **Denominador circular na conformidade:** itens ativos = marcados em todos os meses de 2026-05 a 11 (taxa recente 100% por construção) contra 38,3% acumulado.
4. **Margem por cliente:** `SUM(margem_mes_total)` = R$ 3,26 mi; a âncora de R$ 5,83 mi só sai de receita − custo, porque 2.611 de 4.537 linhas têm margem mensal NULL. Nenhum documento dá a fórmula do total.
5. **Caixa sem outubro:** REALIZADO vai de 25/05 a 28/09 (carga de 01/11); setembro tem 233 parcelas PREVISTAS já vencidas. Causa não investigada.
6. **Cegueira da camada semântica:** GA4 e uso de IA não retornam; faltam documentos para `rfn_site__*`, `ia_uso_mensal` e saúde de fontes; "quem atende cliente X" não acha `squad_cliente`.
7. **Conversão Google:** UNKNOWN/INDEFINIDA = 14.227 de ~18,1 mil conversões de campanha (set+out).
8. **Sem aviso de armadilha:** MRR VBOT de set/2026 R$ 98.960 (era R$ 102.470 em 28/09); SEM_CATEGORIA = 39% da entrada vigente; 42 dos 184 jobs vencidos abertos são do módulo aposentado.

## 6. Teste de carga (somente leitura, MCP Nekt/BigQuery)

| Degrau | Chamadas | OK | p50 / p95 / máx (ms) |
|---|---:|---:|---|
| Serial (5 classes × 5) | 25 | 25 | 341 / ~700 / 757 |
| Concorrência 5 | 5 | 5 | 399 / 538 / 538 |
| Concorrência 10 | 10 | 10 | ~371 / 456 / 456 |
| Concorrência 18 | 18 | 18 | ~410 / ~695 / 695 |
| Soak 3×10 | 30 | 29 | ~340 / ~450 / 548 |
| Mesma consulta 10× | 10 | 10 | 358 / 460 / 460 |
| `get_semantic_context` serial / paralelo | 10 / 10 | 10 / 10 | ~3,5 s (máx 7,2 s) / 7,2 s de parede (~5× de ganho) |

Os erros apareceram só em SQL dos próprios testes (3), nunca da plataforma. Concorrência segura medida: **18 consultas**; p50 subiu ~20% e o máximo ficou em 1,0–1,3× o serial (critério de parada era 5×). **Sem cache de resultado:** repetir a mesma consulta rescaneia e cobra (80.340.334 bytes por execução). Filtrar `trs_google_ads__termo_busca` por mês não reduz o escaneamento (80,3 MB em qualquer mês).

## 7. Limites

- Tudo foi lido no meio da passada de terça; frescor de Meta, Instagram, Páginas e TikTok é "aguardando a passada de hoje".
- Concorrência de SQL: só há `execution_time_ms` do servidor, sem relógio de parede; não prova que o MCP não serializou parte das chamadas. Teto de 18 por rajada; não se sabe acima disso. A carga de fundo da passada de terça não foi isolada.
- Não testados: SELECT na Raw, joins com mais de 3 tabelas, `page_token` em paralelo, COUNT de 2 tabelas Raw do LGPD, 15 afirmações numéricas dentro do texto, permissões e pastas dos documentos (não há pastas), catálogo inteiro (tabelas Refined que nenhum documento cita).
- Busca semântica devolve só os N mais relevantes: "31 documentos" é piso. Cadência esperada é a documentada, não medida. Nenhum dado pessoal foi reproduzido.

## 8. O que fazer (por quem pode)

| Item | Quem | Observação |
|---|---|---|
| Reautorizar Google Ads (43 fontes) e trocar a chave do iClips | usuária, na interface da Nekt | congelam Trusted, Refined e as suítes principal/iClips |
| `campos_conversao_json` com e-mail, telefone e nome em consumo | decisão da usuária | corrigir a Refined ou os documentos de Marketing/Inbound |
| Reescrever documentos com número velho e contradição (Mídia, Operação, Account, RH, Diretoria Executiva, Inbound, Governança, Qualidade, Índice) | dá para fazer pelo MCP | só atualiza documento; nada disso foi feito |
| Criar documentos de GA4 (`rfn_site__*`), uso de IA e saúde de fontes; fórmula de margem total e fim da série de caixa | dá para fazer pelo MCP | idem |
| Ramo Facebook do `desempenho_diario` (flags de defasagem congeladas) | decisão | depende da cadeia Google Ads (`query-tL4g`, `query-zF8L`) que não rodou em 27/10 |
