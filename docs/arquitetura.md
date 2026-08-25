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
| 3 · Inteligência artificial | Provedores, modelos, parâmetros, gateway multi-LLM | `LLMProvider`, `LLMModel`, `/llm/*` |
| 4 · Automação e ferramentas | Ferramentas HTTP/SQL/RPA/retrieval, integrações corporativas | `Tool`, `Integration` |
| 5 · Dados e conhecimento | Bases indexadas, documentos, classificação de dado | `KnowledgeBase`, `KnowledgeDocument` |
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
│   ├── app/models/         37 tabelas do domínio
│   ├── app/schemas/        contratos de entrada e saída
│   ├── app/api/v1/routers/ auth, studio, observability, analytics,
│   │                       lifecycle, security, governance
│   └── tests/              19 testes de RBAC, governança e observabilidade
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
| 9.3 Custos variáveis | Custo por span, trace, serviço, modelo e provedor; orçamento por escopo com alerta e bloqueio duro | `Trace`, `BudgetRule`, `/analytics/llm` |
| 9.4 Qualidade e confiabilidade | Níveis de autonomia (N4 recusado), aprovação humana por ferramenta, evaluations como gate de publicação, rollback de versão | `AutonomyLevel`, `Tool.requires_approval`, `Evaluation.is_gate` |
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

## 7. O que ainda não está aqui

Registrado explicitamente para não ser confundido com escopo entregue:

- **Execução de agente.** A plataforma modela, versiona, governa e observa os
  serviços. O runtime que efetivamente chama o LLM e executa a ferramenta é o
  próximo módulo — o `LLMProvider` já guarda a referência da credencial e o
  `Tool` já guarda o contrato de parâmetros.
- **Indexação vetorial.** `KnowledgeBase` e `KnowledgeDocument` registram a base,
  o modelo de embedding e a contagem de chunks; o índice em si depende de escolha
  de banco vetorial.
- **SSO corporativo.** A autenticação é local. A integração com diretório
  corporativo é uma das perguntas do discovery (seção 10 do relatório) e deve ser
  decidida antes da implementação.
- **Migrações.** O schema é criado por `create_all` em desenvolvimento. Antes de
  produção, adicionar Alembic.
