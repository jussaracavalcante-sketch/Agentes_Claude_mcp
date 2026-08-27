# Arquitetura — VKB · Vanguarda IA

Este documento descreve a infraestrutura implementada neste repositório e como ela
responde ao que foi levantado na reunião de 25 de agosto de 2026 entre Vanguarda
MarTech e UFLY (relatório técnico de avaliação da plataforma IASE).

O relatório propôs, na seção 7, uma arquitetura conceitual em sete camadas. O que
está aqui é a materialização dessas camadas em código próprio da Vanguarda — a
plataforma corporativa a que os projetos hoje dispersos podem convergir.

---

## 1. Visão em camadas

| Camada | O que é | Onde vive |
|---|---|---|
| 1 · Canais e interfaces | Console web, portal, webchat, WhatsApp, voz, e-mail, API | `apps/web`, `Channel` em `models/studio.py` |
| 2 · Orquestração | Serviços, agentes, supervisor, estágios da jornada, transbordo | `models/studio.py`, `api/v1/routers/studio.py` |
| 3 · Inteligência artificial | Provedores, modelos, parâmetros, gateway multi-LLM, motor de execução | `LLMProvider`, `LLMModel`, `/llm/*`, `app/runtime/` |
| 4 · Automação e ferramentas | Ferramentas HTTP/SQL/RPA/retrieval, integrações corporativas | `Tool`, `Integration` |
| 5 · Dados e conhecimento | Bases indexadas, trechos vetorizados, recuperação | `KnowledgeBase`, `KnowledgeDocument`, `KnowledgeChunk`, `app/rag/` |
| 6 · Governança e segurança | Tenant, identidade, RBAC, unidades, chaves, auditoria | `models/tenancy.py`, `routers/security.py` |
| 7 · Observabilidade e FinOps | Conversas, tarefas, traces, spans, tokens, custo, orçamento | `models/runtime.py`, `routers/observability.py`, `routers/analytics.py` |

O ciclo de vida (versão → aprovação → implantação → rollback → portabilidade)
atravessa as camadas 2 a 7 e está em `models/lifecycle.py` e `routers/lifecycle.py`.

---

## 2. Componentes

```
apps/
├── api/                    FastAPI + SQLAlchemy 2 + Pydantic v2
│   ├── app/core/           configuração, segurança, utilitários
│   ├── app/db/             sessão, base declarativa, permissões, seed
│   ├── app/models/         39 tabelas do domínio
│   ├── app/rag/            chunking, embedding e recuperação
│   ├── app/runtime/        motor, provedores, ferramentas e tracing
│   ├── migrations/         revisões Alembic
│   ├── app/schemas/        contratos de entrada e saída
│   ├── app/api/v1/routers/ auth, studio, observability, analytics,
│   │                       lifecycle, security, governance
│   └── tests/              46 testes de RBAC, governança, observabilidade,
│                           runtime e recuperação
└── web/                    React 18 + Vite + TypeScript + Tailwind
    ├── src/components/     UI, ícones e gráficos SVG
    ├── src/pages/          telas do console
    ├── src/layouts/        shell com navegação
    └── src/lib/            cliente HTTP, tipos, sessão, formatação
```

**Banco de dados.** Postgres em produção, SQLite em desenvolvimento. As chaves
primárias são UUID em texto e as expressões dependentes de dialeto ficam isoladas
em `app/db/dialect.py`, para que o mesmo código rode nos dois.

**Autenticação.** Duas credenciais, ambas auditadas: token de sessão (JWT, para o
console) e chave de API (hash SHA-256, para integração servidor a servidor). Só o
hash da chave é persistido; o segredo aparece uma única vez, na emissão.

**Senhas.** PBKDF2-SHA256 com 240 mil rodadas e sal por usuário.

---

## 3. Controles que a plataforma impõe

O relatório aponta, na seção 9, riscos que uma plataforma centralizada não resolve
sozinha. Estes são os que aqui viraram regra executável, não recomendação:

| Risco (relatório) | Controle implementado | Onde |
|---|---|---|
| 9.1 Dependência do fornecedor | Exportação de serviços, agentes, skills e ferramentas em JSON aberto, com checksum | `POST /portability/export` |
| 9.2 Segurança e privacidade | RBAC por permissão atômica; trilha de auditoria append-only; políticas de retenção e base legal por categoria de dado | `deps.require()`, `AuditLog`, `PrivacyPolicy` |
| 9.3 Custos variáveis | Custo medido por span e trace na execução real; orçamento por escopo com bloqueio duro que recusa o turno antes de gastar | `Trace`, `BudgetRule`, `AgentEngine._assert_budget` |
| 9.4 Qualidade e confiabilidade | Níveis de autonomia impostos na execução (N4 recusado), aprovação humana antes de agir, evaluations como gate, rollback de versão | `AutonomyLevel`, `PendingAction`, `Evaluation.is_gate` |
| 9.5 Integração com sistemas | Registro de conector com tipo de auth, limite de requisição, status e último erro | `Integration` |
| 9.6 Proliferação de agentes | Rascunho → versão → aprovação → publicação, com segregação de funções | `routers/lifecycle.py` |

### Segregação de funções

Quem cria uma versão não pode aprová-la. A tentativa devolve `403`:

```
POST /api/v1/versions/{uid}/approve
→ 403 Segregacao de funcoes: quem cria a versao nao pode aprova-la.
```

### Gate de produção

Publicar em produção exige versão aprovada. Homologação, não:

```
POST /api/v1/versions/{uid}/deploy {"environment": "production"}
→ 409 Producao exige versao aprovada.
```

### Autonomia limitada por política

`n4_autonomo` não existe no enum e é recusado na criação do agente. Os quatro
níveis admitidos vão de `n0_sugere` a `n3_executa_irreversivel`.

---

## 4. Modelo de observabilidade

Cada execução — chat ou task — gera um `Trace` com uma árvore de `Span`. O span
carrega tipo (`chain`, `model`, `tool`, `skill`, `retrieval`, `guardrail`,
`handoff`), duração, status, tokens de entrada e saída, custo, modelo acionado e
os payloads de entrada e saída.

A duração de um span-pai engloba a dos filhos, e cada filho aponta para o pai por
`parent_uid` — a árvore é navegável e auditável do início ao fim da requisição.

Isso é o que sustenta as três perguntas que a Vanguarda precisa responder:

- **o que rodou** — lista de traces por serviço, origem e status;
- **por que custou isso** — tokens e custo por span, agregados por modelo,
  provedor, serviço e unidade;
- **onde falhou** — span com status de erro, dentro do contexto da árvore.

---

## 5. Multi-tenant e centros de custo

Todo dado de negócio pende de `tenant_uid`. As consultas filtram por tenant a
partir da identidade do requisitante — não há endpoint que devolva dado fora do
tenant do token.

`Unit` representa a unidade organizacional (Criação, Mídia, Planejamento,
Tecnologia, Atendimento, Administrativo) com centro de custo e orçamento mensal.
Serviços pendem de unidade, e o FinOps agrega custo por essa via.

---

## 6. Ambientes

`Environment` distingue `development`, `staging` e `production`. Uma versão pode
ser implantada em qualquer um; só produção exige aprovação prévia e só uma versão
fica ativa por serviço. O rollback registra qual versão substituiu qual.

---

## 7. Execução de agentes

O motor está em `app/runtime/`. Um turno percorre esta sequência:

1. resolve serviço, agente supervisor e modelo;
2. checa o orçamento do mês — limite com `hard_stop` estourado recusa a execução
   antes de gastar qualquer token;
3. monta o prompt com instrução do serviço, papel do agente e estágio corrente;
4. chama o provedor; se ele pedir ferramenta, aplica o nível de autonomia;
5. executa a ferramenta **ou** retém a ação para aprovação humana;
6. devolve o resultado ao modelo e fecha o turno;
7. grava o trace com a árvore de spans, tokens medidos e custo calculado.

### Provedores

Três adaptadores, mesma interface (`app/runtime/providers.py`):

| Adaptador | Formato | Quando entra |
|---|---|---|
| `echo` | nenhum — local | Padrão sem credencial: determinístico, sem rede, sem custo |
| `openai_compatible` | `POST /chat/completions` com `tools` | Provedor configurado com credencial |
| `anthropic_messages` | `POST /messages` com blocos `tool_use` | Provedor cujo código é `anthropic`/`claude` |

URL base, código do modelo e credencial vêm da configuração do tenant no LLM
Gateway — não há valor fixo no código. O `echo` não raciocina: ele resume o
contexto e devolve resposta previsível, o que permite exercitar o loop, o trace
e a fila de aprovação de ponta a ponta sem contratar provedor.

**O trace registra o que executou, não o que estava configurado.** Se o motor
cair no `echo` por falta de credencial, o trace diz `echo` e o custo é zero; o
provedor configurado fica em `metadata_json` do span do modelo. Registrar o
contrário inflaria o FinOps e mentiria na observabilidade.

### Ferramentas

`app/runtime/tools.py` executa por `kind`:

- `retrieval` — recuperação semântica nas bases do tenant (usa a camada 5);
- `http` — chamada configurada em `config_json`; o modelo preenche só os
  parâmetros declarados, nunca o destino;
- `noop` — ferramenta declarada sem efeito, para ensaiar uma jornada.

`sql` e `rpa` ficam **deliberadamente sem executor**: rodar SQL arbitrário ou
automação de interface a partir de saída de modelo exige isolamento que esta
camada não tem. Cadastrar é permitido; executar devolve erro explícito no trace.

### Autonomia e aprovação

A tabela `pending_actions` materializa o nível de autonomia:

| Situação | Resultado |
|---|---|
| Ferramenta com `requires_approval` | Retém, qualquer que seja a autonomia do agente |
| Agente N0 (sugere) | Retém |
| Agente N1 (executa com aprovação) | Retém |
| Agente N2 / N3 | Executa |

A marca na ferramenta tem precedência sobre a autonomia do agente. Aprovar
executa a ferramenta naquele momento e registra quem decidiu; a execução não
acontece no turno original porque entre a retenção e a decisão pode passar tempo
indefinido.

---

## 8. Recuperação de conhecimento (RAG)

`app/rag/` faz chunking, embedding e recuperação.

**Chunking** quebra por parágrafo e depois por frase, com sobreposição — cortar
no meio de uma frase degrada a recuperação. Nenhum trecho excede o limite de
tokens pedido, mesmo quando a sobreposição precisa ser descartada para isso.

**Embedders** plugáveis:

- `hashing` — projeção por hash sobre tokens normalizados. É **léxico, não
  semântico**: dobra acento (`mínima` → `minima`), radicaliza sufixos do
  português (`escalonamento` e `escalonar` → `escalon`) e descarta palavras
  funcionais. Local, determinístico, sem custo. É o padrão.
- `http` — endpoint `/embeddings` do provedor, no formato
  `{"input": [...], "model": "..."}`.

O título do documento entra no texto vetorizado, mas não no conteúdo devolvido:
ele costuma carregar o termo que o usuário digita e que o corpo do trecho às
vezes não repete.

**Busca**: em Postgres, tenta o operador de distância do pgvector; sem a extensão
(ou em SQLite), calcula cosseno na aplicação. O ranking é o mesmo; muda onde o
custo é pago. Trechos indexados por outro embedder são ignorados na comparação e
o log avisa — comparar vetores de embedders diferentes produz ranking sem sentido.

### Qualidade medida

`tests/test_rag.py` roda uma avaliação de 10 consultas contra o conhecimento do
seed e exige **80% de acerto no top-1** como piso. O estado atual é 10/10. Não é
um teste de unidade: é um guarda de qualidade — mexer no tokenizador, no
radicalizador ou no chunking e piorar o ranking derruba a suíte.

---

## 9. Migrações

`apps/api/migrations/`, geridas por Alembic. A URL e o metadata vêm de
`app.core.config` e `app.models`, para que migração e modelo não divirjam de
configuração.

```bash
make migrate                      # aplica as pendentes
make migration m="descrição"      # gera revisão a partir do diff modelos x banco
make migrate-down                 # desfaz a última
```

As revisões usam `sa.func.now()` em vez de sintaxe de um dialeto específico. O
container da API aplica `alembic upgrade head` no entrypoint antes de servir —
idempotente, no-op quando já está na última revisão.

`init_db()` (`create_all`) segue existindo, mas é atalho de desenvolvimento e de
teste. Em ambiente compartilhado o caminho é a migração, que preserva os dados.

---

## 10. O que ainda não está aqui

Registrado explicitamente para não ser confundido com escopo entregue:

- **Provedores reais não exercitados.** Os adaptadores HTTP estão
  implementados, mas este ambiente não tem credencial de nenhum provedor: o
  caminho que foi executado de ponta a ponta é o `echo`. Antes de confiar em
  produção, rodar um turno real contra cada provedor pretendido.
- **Resolvedor de cofre.** `LLMProvider.credential_ref` guarda `secret://…` e
  `_resolve_credential` devolve `None` para essa forma — de propósito, porque a
  integração com cofre é decisão do discovery de infraestrutura. Sem ela, o
  motor cai no adaptador local.
- **pgvector não exercitado.** O caminho nativo está implementado e o fallback
  em aplicação foi testado; falta rodar contra um Postgres com a extensão
  instalada. As migrações também só foram validadas em SQLite (upgrade,
  downgrade e paridade com os modelos) — não houve Postgres neste ambiente.
- **Embedder semântico.** O `hashing` é léxico. Sinonímia sem sobreposição de
  radical (“transbordo” x “escalonamento”) continua fora do alcance dele.
- **Execução assíncrona.** O motor é síncrono e in-process. `TaskRun` já modela
  fila (`status=queued`), então trocar por Celery/RQ/arq muda quem chama
  `run_turn`, não o motor.
- **SSO corporativo.** A autenticação é local. A integração com diretório
  corporativo é uma das perguntas do discovery (seção 10 do relatório) e deve ser
  decidida antes da implementação.
