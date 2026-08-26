# VKB · Vanguarda IA

Plataforma corporativa de orquestração e governança de agentes de IA, automações e
integrações da **Vanguarda MarTech**.

Nasce do relatório técnico de 25 de agosto de 2026, que descreveu o problema em uma
frase: a Vanguarda tem iniciativas úteis de IA, mas **fragmentadas** — sem visão
consolidada de quem construiu o quê, quem usa, quanto custa e o que está exposto.
Este repositório é a camada que faz essas iniciativas convergirem.

---

## O que a plataforma faz

**AI Studio** — cria e versiona os três tipos de serviço identificados na reunião:
conversação, tarefa (back-office) e copiloto. Cada serviço tem instrução,
objetivos, canais, agentes especializados e estágios de jornada.

**Observabilidade** — toda execução vira um trace com árvore de spans: qual modelo
foi acionado, qual ferramenta rodou, quantos tokens, quanto custou, onde falhou.

**Ciclo de vida** — rascunho → versão → aprovação → implantação → rollback. Quem
cria não aprova. Produção exige versão aprovada.

**Governança** — RBAC por permissão atômica, trilha de auditoria append-only,
políticas de retenção com base legal (LGPD) e níveis de autonomia por agente.

**FinOps** — custo por modelo, provedor, serviço e unidade, com orçamento por
escopo, alerta percentual e bloqueio duro.

**Portabilidade** — exportação de serviços, agentes, skills e ferramentas em JSON
aberto com checksum. Nenhum ativo estratégico fica preso a formato proprietário.

---

## Subir em desenvolvimento

Requer Python 3.11+ e Node 22+.

```bash
make setup     # cria a venv da API e instala o console
make reset     # cria o schema e popula o tenant de demonstração
make api       # API em http://localhost:8000  (docs em /docs)
make web       # console em http://localhost:5173
```

Acesso do seed:

```
admin@vanguardamartech.com.br / vanguarda
```

O seed cria a Vanguarda MarTech com 6 unidades, 10 usuários em 4 papéis, 13
serviços, 8 agentes, 4 provedores de LLM e 90 dias de conversas, tarefas e traces.

### Em containers

```bash
cp .env.example .env
make up        # Postgres + API (8000) + console (8080)
docker compose exec api python -m app.db.seed
```

---

## Estrutura

```
apps/api/     FastAPI + SQLAlchemy 2 + Pydantic v2 — 37 tabelas, 7 routers
apps/web/     React 18 + Vite + TypeScript + Tailwind — console completo
docs/         arquitetura em camadas e rastreio ao relatório
.github/      CI: ruff, pytest, typecheck, build e varredura de credenciais
```

`docs/arquitetura.md` mapeia cada camada da arquitetura conceitual do relatório
(seção 7) ao código que a implementa, e cada risco (seção 9) ao controle que a
plataforma impõe.

---

## Verificação

```bash
make test      # 19 testes: RBAC, governança, observabilidade
make lint      # ruff na API, typecheck no console
make build     # build de produção do console
```

Os testes cobrem o que a plataforma precisa **impor**, não apenas documentar:
segregação de funções na aprovação, gate de produção, recusa de autonomia N4,
isolamento por tenant, trilha de auditoria em toda escrita e integridade da árvore
de spans.

---

## Segurança

- Senhas com PBKDF2-SHA256, 240 mil rodadas, sal por usuário.
- Chaves de API armazenadas só como hash SHA-256; o segredo aparece uma vez.
- Credenciais de provedores e integrações ficam em cofre externo — o banco guarda
  apenas a referência (`secret://…`).
- Toda escrita registra autor, IP, recurso e resumo na trilha de auditoria.
- A CI bloqueia o merge se detectar padrão de credencial no diff.

Nunca commite `.env`. Use `.env.example` como referência.

---

## Próximos passos

O relatório recomenda discovery técnico, demonstração orientada e prova de conceito
antes de qualquer decisão de contratação. Esta plataforma cobre a **Etapa 1** desse
plano — o inventário deixa de ser planilha e passa a ser sistema: o serviço
"Auditoria de Licenças de IA" já está modelado para cruzar ferramentas, licenças,
donos e custos.

O que falta para produção está listado sem eufemismo em
[`docs/arquitetura.md`](docs/arquitetura.md#7-o-que-ainda-não-está-aqui):
runtime de execução dos agentes, indexação vetorial, SSO corporativo e migrações.
