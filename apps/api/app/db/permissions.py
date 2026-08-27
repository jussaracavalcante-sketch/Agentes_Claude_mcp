"""Catalogo de permissoes e papeis de sistema."""

from __future__ import annotations

PERMISSIONS: list[tuple[str, str]] = [
    ("services:read", "Visualizar servicos"),
    ("services:write", "Criar e alterar servicos"),
    ("services:delete", "Remover servicos"),
    ("agents:read", "Visualizar agentes"),
    ("agents:write", "Criar e alterar agentes"),
    ("agents:delete", "Remover agentes"),
    ("skills:read", "Visualizar skills"),
    ("skills:write", "Criar e alterar skills"),
    ("tools:read", "Visualizar ferramentas"),
    ("tools:write", "Criar e alterar ferramentas"),
    ("integrations:read", "Visualizar integracoes"),
    ("integrations:write", "Configurar integracoes"),
    ("knowledge:read", "Consultar bases de conhecimento"),
    ("knowledge:write", "Gerir bases de conhecimento"),
    ("llm:read", "Visualizar provedores e modelos"),
    ("llm:write", "Configurar provedores e modelos"),
    ("observability:read", "Acompanhar execucoes, conversas e traces"),
    ("analytics:read", "Consultar indicadores e consumo"),
    ("lifecycle:read", "Visualizar versoes e implantacoes"),
    ("lifecycle:write", "Salvar versoes"),
    ("lifecycle:approve", "Aprovar versoes"),
    ("lifecycle:deploy", "Publicar e reverter em producao"),
    ("lifecycle:export", "Exportar ativos da plataforma"),
    ("security:read", "Visualizar usuarios, papeis e chaves"),
    ("security:write", "Gerir usuarios, papeis e chaves"),
    ("audit:read", "Consultar trilha de auditoria"),
    ("curation:read", "Visualizar fila de curadoria"),
    ("curation:write", "Decidir itens de curadoria"),
    ("evaluations:read", "Visualizar avaliacoes"),
    ("evaluations:write", "Criar avaliacoes"),
    ("privacy:read", "Visualizar politicas de privacidade"),
    ("privacy:write", "Definir politicas de privacidade"),
    ("finops:read", "Visualizar orcamentos e custos"),
    ("finops:write", "Definir limites de consumo"),
]

# Permissoes da camada de execucao.
PERMISSIONS += [
    ("runtime:execute", "Executar servicos de IA"),
    ("runtime:approve", "Aprovar ou rejeitar acao retida"),
    ("knowledge:index", "Indexar e reindexar bases de conhecimento"),
]

READ_ONLY = [code for code, _ in PERMISSIONS if code.endswith(":read")]

BUILDER = READ_ONLY + [
    "services:write",
    "agents:write",
    "skills:write",
    "tools:write",
    "integrations:write",
    "knowledge:write",
    "lifecycle:write",
    "evaluations:write",
    "curation:write",
    "runtime:execute",
    "knowledge:index",
]

OPERATOR = READ_ONLY + [
    "curation:write",
    "lifecycle:deploy",
    "runtime:execute",
    "runtime:approve",
]

# Papeis de sistema. `*` concede acesso total ao tenant.
SYSTEM_ROLES: dict[str, tuple[str, str, list[str]]] = {
    "admin": (
        "Administrador da plataforma",
        "Acesso total ao tenant, incluindo seguranca e auditoria.",
        ["*"],
    ),
    "builder": (
        "Construtor de agentes",
        "Cria e altera servicos, agentes e integracoes. Nao publica em producao.",
        BUILDER,
    ),
    "operator": (
        "Operador",
        "Acompanha execucoes, cura respostas e publica versoes ja aprovadas.",
        OPERATOR,
    ),
    "auditor": (
        "Auditoria e governanca",
        "Somente leitura, com acesso a trilha de auditoria e privacidade.",
        READ_ONLY,
    ),
}
