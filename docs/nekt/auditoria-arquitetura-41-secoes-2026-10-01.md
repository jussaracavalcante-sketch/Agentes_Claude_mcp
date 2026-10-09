# 01/10 — auditoria das 41 seções do documento de arquitetura (ADR-0010)

Documento auditado: "Arquitetura de Data Lake Medalhão — Agência MarTech" (camada semântica,
`0eb3e456-e92e-4a14-bdca-cd005eb0f2d9`), lido na íntegra. Cada linha cita a evidência.
Legenda: ✅ atendida · 🟡 parcial · 🔴 não atendida · ⚪ não verificável pelo MCP · ◻ síntese/decisão (fora da contagem).

## Placar (34 seções avaliáveis)

| | seções |
|---|---:|
| ✅ atendida | **4** |
| 🟡 parcial | **16** |
| ⚪ não verificável | **2** |
| 🔴 não atendida | **12** |
| ◻ síntese ou decisão (1, 2, 8, 22, 27, 28, 29) | 7 |

**Bloco de dados (§3–§29, 21 avaliáveis): 4 ✅ · 14 🟡 · 3 🔴.**
**Bloco de segurança e acesso (§20, §30–§41, 13 avaliáveis): 0 ✅ · 2 🟡 · 2 ⚪ · 9 🔴.**

## As 41 seções

| § | Seção | | Evidência |
|---|---|---|---|
| 1 | Objetivo | ◻ | herda das demais |
| 2 | Visão geral | ◻ | herda das demais |
| 3 | ERP interno | ✅ | VJOB entra por extração semanal; não vira banco analítico |
| 4 | Bronze | 🟡 | preserva e rastreia (Raw, folder por sistema); **não é histórica**: `mysql-yIOn` é FULL_SYNC nos 199 streams (sobrescreve), sem partição por data de ingestão |
| 5 | Silver | ✅ | 80 Trusted: tipagem, dedup, fuso, documento, ids, chaves |
| 6 | Identidade | 🟡 | `cliente_sk` cobre VJOB, iClips, Conexa, financeiro (843 identidades); **conta de mídia fora** (o diagrama da §6 inclui Google Ads ID); ponte por CNPJ cobre 34 de 407 clientes |
| 7 | Gold | 🟡 | domínios: financeiro, mídia, operação, cadastro, marketing, cliente. **Faltam:** comercial (pipeline, performance), operacional/horas/capacidade, cliente/LTV, marketing/ROI e funil |
| 8 | Modelo dimensional | ◻ | decidido: "mantenha o padrão largo" |
| 9 | Domínios de dados | 🟡 | sete domínios existem exceto comercial; **owner, SLA e consumidores por domínio não estão registrados** |
| 10 | Campanhas e mídia | 🟡 | Google Ads e Meta ✅; **sem GA4** (nenhuma das 99 fontes); `campaign_performance` sem receita/ROI |
| 11 | CDC do ERP | 🔴 | extração FULL_SYNC; não há old/new value. Só os logs nativos do VJOB (`tbmudancas` etc.) foram tratados |
| 12 | Auditoria (dados) | 🟡 | logs do ERP tratados (alteração de contrato 18.955, squad, prazo, analista); **não há área `audit/` padronizada** nem cobertura de campanhas |
| 13 | Data Quality | ✅ | 402 regras em 12 suítes, geradas automaticamente, com limiar por regra |
| 14 | Quarantine | 🔴 | **divergência deliberada**: "marcar, nunca apagar"; o dado inválido entra marcado |
| 15 | Data Catalog | 🟡 | catálogo Nekt + descrições detalhadas; classificação L1–L5 na descrição de ~86 de 153 transformações; owner e SLA por tabela não registrados |
| 16 | Data Lineage | ✅ | Nekt registra tabelas de entrada e saída e gatilhos por transformação (nível de tabela, não de coluna) |
| 17 | Semantic Layer | 🟡 | 12 documentos de setor + 7 inventários + regras de leitura; **métricas são texto, não definições executáveis**, e nada obriga BI/IA a usá-las |
| 18 | IA e RAG | 🟡 | desenho Gold + semântica + busca vetorial existe; **nada impede a IA de ler a Raw** (ver §35) |
| 19 | Customer 360 | 🟡 | peças existem (sk, contexto, receita, margem, PI, conformidade); **não há tabela `customer_360`**, nem LTV |
| 20 | Segurança (perfis) | 🔴 | 3 grupos (`All`, `Administrador_`, `Usuário_comum`); nenhum perfil por função |
| 21 | LGPD | 🟡 | campos e níveis documentados; **sem mascaramento/anonimização; exclusão de titular não funciona; retenção sem controle** |
| 22 | Stack | ◻ | Nekt + BigQuery no lugar da stack sugerida; sem Power BI |
| 23 | Estrutura física | 🟡 | Raw/Trusted/Refined com folders ✅; **não existem `audit/`, `quarantine/`, `metadata/`** |
| 24 | Pipeline padrão | 🟡 | extrair → Raw → Trusted → Refined encadeado por evento ✅; **DQ roda depois da carga (gate), não antes**; sem quarentena; catálogo/lineage não atualizados pelo pipeline |
| 25 | Observabilidade | 🟡 | histórico de execuções e alerta de falha nas transformações novas ✅; **sem painel único, sem `records_rejected`, sem SLA compliance**; alerta em 100% não verificado |
| 26 | Backup e retenção | 🔴 | política não definida; retenção de 5 anos é definição, não controle |
| 27 | Arquitetura final | ◻ | síntese |
| 28 | Roadmap | ◻ | F1 ✅ · F2 🟡 (sem CDC) · F3 🟡 · F4 🔴 · F5 🟡 |
| 29 | Resultado esperado | ◻ | síntese |
| 30 | Matriz de acesso | 🔴 | **não existe matriz por perfil** |
| 31 | Classificação | 🟡 | cinco níveis, documento e ~86/153 transformações; **L5 materializado na Raw** (senha, token), contra o que a própria §31 manda |
| 32 | RBAC + ABAC | 🔴 | sem papéis por função nem atributos |
| 33 | IAM | ⚪ | SSO e MFA não verificáveis pelo MCP |
| 34 | Segurança do ERP | ⚪ | ambientes dev/homolog/prod e acesso do desenvolvedor ao lake não verificáveis |
| 35 | Segurança IA/RAG | 🔴 | **os 3 tokens MCP herdam as permissões do criador** (`use_created_by_permissions`, nenhum escopo granular, `tool_scope` nulo = todas as ferramentas, inclusive escrita); o criador é do `Administrador_` (manager em 16 camadas, Raw incluída) |
| 36 | RLS e CLS | 🔴 | nenhuma aplicada |
| 37 | Auditoria de acesso | 🟡 | Nekt registra por token: ação, rota, status, IP, ferramenta, dono, hora ✅; **sem motivo, cliente, exportação**; cobre tokens MCP |
| 38 | Ciclo de vida de permissões | 🔴 | grupos criados em 23/09; não há processo de entrada, mudança ou revogação |
| 39 | Princípios de segurança | 🔴 | menor privilégio violado pelos tokens de IA; deny by default não demonstrado |
| 40 | Política por colaborador | 🔴 | não existe |
| 41 | Regra de ouro | 🔴 | tokens de IA e integrações herdam acesso de administrador |

## Correção a algo que eu afirmei hoje

Eu disse que a `github-s0VO` seguia a "única fonte caída". **Não é mais o caso.** Existe a
`github-2Upt` ("Repositório de códigos institucional Vanguarda"), criada em **29/09 12:15**, com
credencial nova: uma tentativa falhou às 12:22 e a seguinte **teve sucesso às 12:30**. A
`github-s0VO` não aparece mais na lista de fontes.

**Mas "sucesso" não é dado:** a camada nova (`vanguardamartech_repositorio_de_codigos_institucionais`,
uma camada por fonte, conforme a R-001) tem `github_institucionalrepositories` com **0 linhas**, e
`github_institucionalcommits` e `github_institucionalpull_requests` **não materializaram**. É o
mesmo caso de `rd-station-socq`: execução com sucesso e nenhuma tabela de dado. Causa **não
verificada** (os repositórios da configuração são mascarados). A fonte é **semanal (domingo 01:00)** e
só rodou uma vez, em 29/09.

**Consequência:** as 4 transformações do GitHub (`query-UFhj`, `45Rs`, `3vaR`, `Dbfg`) disparam por
evento na `github-s0VO` e leem as tabelas antigas (790 commits, 16 PRs, 0 repositórios). **Não vão
rodar.** Não as reapontei: a fonte nova ainda não entrega dado, e decidir se a base nova substitui ou
soma a antiga é escolha de negócio.

## Achado de segurança que pesa mais que o resto

Os **3 tokens MCP** (`integração com claude` ×2 e `VANGUARDA IA`) não têm escopo: herdam as
permissões de quem os criou. Quem os criou está no grupo `Administrador_`. Logo, **a IA lê e escreve
em todas as camadas, inclusive a Raw** — o que a §18, a §35 e a §41 proíbem. Este próprio trabalho
fez isso hoje (consultas a `vanguardamartech_raw`). Há também um quarto token ("IA conector", de outro
administrador) que aparece no log de acesso.
Corrigir é recriar os tokens com escopo granular (`tables`, `semantic_layer`, sem escrita); **mexe
em acesso e não foi feito** (R-005 não cobre acesso de pessoas ou integrações).
