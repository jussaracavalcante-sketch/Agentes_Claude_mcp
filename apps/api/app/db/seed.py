"""Popula o tenant de demonstracao da Vanguarda.

Executar:  python -m app.db.seed  [--reset]

Os dados reproduzem o cenario levantado na reuniao de 25/08/2026: servicos de
conversa, tarefa e copiloto, com observabilidade, versionamento e governanca.
"""

from __future__ import annotations

import argparse
import random
import sys
from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import generate_api_key, hash_password
from app.core.text import slugify
from app.db.base import new_uid
from app.db.permissions import PERMISSIONS, SYSTEM_ROLES
from app.db.session import SessionLocal, engine, init_db
from app.models import (
    Agent,
    AgentSkill,
    AgentTool,
    ApiKey,
    AuditLog,
    Base,
    BudgetRule,
    Conversation,
    ConversationStatus,
    CurationItem,
    Deployment,
    DeploymentStatus,
    Environment,
    Evaluation,
    EvaluationCase,
    EvaluationRun,
    FeatureFlag,
    Integration,
    KnowledgeBase,
    KnowledgeDocument,
    LLMModel,
    LLMProvider,
    Message,
    Permission,
    PrivacyPolicy,
    ReviewDecision,
    Role,
    RolePermission,
    Service,
    ServiceAgent,
    ServiceStage,
    ServiceStatus,
    ServiceType,
    ServiceVersion,
    Skill,
    Span,
    SpanKind,
    TaskRun,
    TaskStatus,
    Tenant,
    Tool,
    Trace,
    Unit,
    User,
    UserRole,
    VersionStatus,
)
from app.rag import get_embedder, index_document

rng = random.Random(20260825)
NOW = datetime.now(UTC)


# ─────────────────────────────────────────────────────────────────────────────
# Catalogos de demonstracao
# ─────────────────────────────────────────────────────────────────────────────
UNITS = [
    ("CRIA", "Criação", "CC-101", 4_000.0),
    ("MIDIA", "Mídia e Performance", "CC-102", 6_000.0),
    ("PLAN", "Planejamento", "CC-103", 3_000.0),
    ("TECH", "Tecnologia", "CC-104", 12_000.0),
    ("ATEND", "Atendimento", "CC-105", 5_000.0),
    ("ADM", "Administrativo e Jurídico", "CC-106", 2_500.0),
]

PROVIDERS = [
    ("openai", "OpenAI", "https://api.openai.com/v1", [
        ("gpt-4.1", "GPT-4.1", 128_000, 0.0020, 0.0080),
        ("gpt-4.1-mini", "GPT-4.1 mini", 128_000, 0.0004, 0.0016),
    ]),
    ("anthropic", "Claude / Anthropic", "https://api.anthropic.com/v1", [
        ("claude-opus-4", "Claude Opus 4", 200_000, 0.0150, 0.0750),
        ("claude-sonnet-4", "Claude Sonnet 4", 200_000, 0.0030, 0.0150),
    ]),
    ("gemini", "Google Gemini", "https://generativelanguage.googleapis.com/v1", [
        ("gemini-2.5-pro", "Gemini 2.5 Pro", 1_000_000, 0.0013, 0.0050),
    ]),
    ("deepseek", "DeepSeek", "https://api.deepseek.com/v1", [
        ("deepseek-chat", "DeepSeek Chat", 64_000, 0.0003, 0.0011),
    ]),
]

SKILLS = [
    (
        "Qualificação de lead",
        "Aplica os cinco pilares de qualificação e devolve score e próximo passo.",
    ),
    ("Consulta de catálogo", "Busca produto, praça e vigência no catálogo comercial vigente."),
    ("Redação de peça", "Gera título, corpo e CTA respeitando o manual de marca."),
    ("Cálculo de mídia", "Calcula CPM, CPC, alcance estimado e verba por praça."),
    ("Extração de cláusula", "Localiza e resume cláusulas de contrato por tipo."),
    ("Resumo de reunião", "Converte transcrição em ata com decisões e responsáveis."),
    ("Classificação de intenção", "Rotula a mensagem do usuário em intenção de negócio."),
    ("Handoff humano", "Encaminha o atendimento ao operador com contexto consolidado."),
]

TOOLS = [
    ("Consultar CRM", "http", "Lê e grava oportunidades no CRM comercial.", False),
    ("Buscar no ERP", "http", "Consulta cadastro, títulos e notas fiscais.", False),
    ("Gravar tarefa no board", "http", "Cria card de tarefa para a equipe responsável.", False),
    ("Executar SQL de mídia", "sql", "Consulta o data mart de performance de campanhas.", False),
    ("Emitir nota fiscal", "http", "Emite NF de serviço. Exige aprovação humana.", True),
    ("Enviar e-mail transacional", "http", "Dispara e-mail pelo provedor corporativo.", False),
    (
        "RPA — portal do fornecedor",
        "rpa",
        "Automação de interface para portal sem API.",
        True,
    ),
    ("Buscar no conhecimento", "retrieval", "Recupera trechos das bases indexadas.", False),
]

INTEGRATIONS = [
    ("RD Station CRM", "rest", "CRM", "oauth2", "https://api.rd.services", "connected"),
    ("Conexa ERP", "rest", "ERP", "api_key", "https://api.conexa.local", "connected"),
    ("iClips", "rest", "Gestão de agência", "api_key", "https://api.iclips.com.br", "connected"),
    ("Meta Business", "rest", "Mídia", "oauth2", "https://graph.facebook.com/v20.0", "connected"),
    ("Google Ads", "rest", "Mídia", "oauth2", "https://googleads.googleapis.com", "connected"),
    ("WhatsApp Business", "webhook", "Canal", "api_key",
     "https://graph.facebook.com/v20.0", "connected"),
    ("Data mart de mídia", "database", "Dados", "iam", None, "connected"),
    ("Portal do fornecedor", "rpa", "Legado", "credentials", None, "degraded"),
]

# (nome, descricao, classificacao, [(titulo do documento, conteudo)])
# O conteudo e real e recuperavel: sem texto de verdade o RAG nao tem o que
# devolver e a plataforma pareceria funcionar sem funcionar.
KNOWLEDGE = [
    (
        "Manual de marca Vanguarda",
        "Diretrizes de tom, linguagem e uso de marca.",
        "interno",
        [
            (
                "Tom de voz",
                "O tom da Vanguarda é direto e cordial, sem jargão publicitário. "
                "Evite superlativos vazios como 'o melhor do mercado'. Prefira o "
                "verbo no presente e a segunda pessoa do singular no varejo.\n\n"
                "Nunca prometa resultado numérico sem dado que sustente a promessa.",
            ),
            (
                "Uso da assinatura",
                "A assinatura da marca fica sempre no canto inferior direito, com "
                "margem mínima equivalente à altura do logotipo. Não aplique a "
                "assinatura sobre imagem sem tarja de contraste.\n\n"
                "A versão monocromática é obrigatória em impressão de uma cor.",
            ),
            (
                "Aprovação de peça",
                "Toda peça passa por revisão do Guardião de Marca antes do envio ao "
                "cliente. A revisão verifica assinatura, tom, e aderência ao briefing.\n\n"
                "Peça reprovada volta ao redator com o desvio apontado por escrito.",
            ),
        ],
    ),
    (
        "Catálogo comercial VPromo",
        "Produtos, praças, vigências e tabela de preços.",
        "interno",
        [
            (
                "Prazos de veiculação por praça",
                "Manaus: 5 dias úteis entre aprovação da peça e início da veiculação. "
                "Belém: 3 dias úteis. Macapá e Boa Vista: 7 dias úteis.\n\n"
                "O prazo conta a partir da aprovação formal registrada no sistema, "
                "não do envio da peça.",
            ),
            (
                "Produtos elegíveis",
                "Mídia exterior, rádio, patrocínio de conteúdo e ativação em ponto de "
                "venda. Mídia exterior exige contrato mínimo de 14 dias.\n\n"
                "Rádio opera em blocos de 30 inserções. Patrocínio de conteúdo tem "
                "vigência mínima mensal.",
            ),
            (
                "Verba mínima por campanha",
                "A verba mínima para campanha em praça capital é de R$ 12.000. Em "
                "praça interior, R$ 6.000.\n\n"
                "Campanha multipraça soma as verbas mínimas de cada praça envolvida.",
            ),
        ],
    ),
    (
        "Base de contratos e minutas",
        "Modelos contratuais e cláusulas padrão.",
        "confidencial",
        [
            (
                "Cláusula de rescisão",
                "A rescisão exige aviso prévio de 30 dias por escrito. Rescisão sem "
                "aviso incide multa de 20% sobre o saldo do contrato.\n\n"
                "Contratos de mídia já veiculada não são passíveis de rescisão "
                "retroativa.",
            ),
            (
                "Vigência e renovação",
                "A vigência padrão é de 12 meses, com renovação automática por igual "
                "período salvo manifestação contrária em até 60 dias do término.\n\n"
                "Reajuste anual pelo IPCA acumulado.",
            ),
        ],
    ),
    (
        "Playbook de atendimento",
        "Fluxos de atendimento e critérios de escalonamento.",
        "interno",
        [
            (
                "Critério de escalonamento",
                "Se a confiança do agente ficar abaixo de 0,6, transfira imediatamente "
                "para o operador humano com o contexto consolidado da conversa.\n\n"
                "O operador recebe o histórico completo, a intenção classificada e os "
                "dados já coletados. Nunca peça ao cliente que repita informação já "
                "fornecida.",
            ),
            (
                "Identificação do cliente",
                "Confirme CNPJ e nome do responsável antes de tratar dado contratual. "
                "Para consulta de catálogo não é necessário identificar o cliente.\n\n"
                "Dado pessoal só é coletado quando indispensável à solicitação.",
            ),
            (
                "Segunda via de boleto",
                "O atendente deve confirmar CNPJ e competência antes de emitir. A "
                "emissão fica registrada na trilha de auditoria.\n\n"
                "Boleto vencido há mais de 30 dias exige encaminhamento à "
                "controladoria.",
            ),
        ],
    ),
    (
        "Políticas internas e SGQ",
        "POPs, política de IA e normas do SGQ.",
        "interno",
        [
            (
                "Política de uso de IA",
                "É vedado enviar dado pessoal de cliente, dado contratual ou "
                "informação financeira a plataforma de IA externa sem que a "
                "ferramenta esteja homologada e registrada no inventário.\n\n"
                "Toda solução de IA usada em processo produtivo precisa de dono "
                "nomeado e nível de autonomia declarado.",
            ),
            (
                "Níveis de autonomia",
                "N0 sugere e não executa. N1 executa após aprovação humana. N2 executa "
                "ação reversível. N3 executa ação irreversível.\n\n"
                "N4, autonomia plena sem supervisão, é vedado por política.",
            ),
        ],
    ),
]

AGENTS = [
    # (nome, papel, descricao, autonomia)
    ("Supervisor de Jornada", "roteador",
     "Classifica a intenção e encaminha ao especialista.", "n0_sugere"),
    ("Especialista Comercial", "especialista",
     "Qualifica lead, consulta catálogo e monta proposta.", "n1_executa_com_aprovacao"),
    ("Especialista de Mídia", "especialista",
     "Responde sobre performance, verba e praças.", "n1_executa_com_aprovacao"),
    ("Redator de Peças", "gerador",
     "Produz títulos, corpo e CTA dentro do manual de marca.", "n0_sugere"),
    ("Analista de Contratos", "analista",
     "Lê contratos, extrai cláusulas e aponta risco.", "n1_executa_com_aprovacao"),
    ("Auditor de Licenças", "analista",
     "Cruza licenças, donos e custos das ferramentas de IA.", "n2_executa_reversivel"),
    ("Operador de Back-office", "executor",
     "Executa rotinas determinísticas em sistemas internos.", "n2_executa_reversivel"),
    ("Guardião de Marca", "revisor",
     "Verifica aderência da peça ao manual antes da publicação.", "n0_sugere"),
]

SERVICES = [
    # (nome, tipo, status, descricao, canais, unidade, versao_ativa)
    ("Atendimento Comercial — Vanguarda", ServiceType.conversation, ServiceStatus.active,
     "Atendimento N1 no WhatsApp: identifica o cliente da carteira, consulta o catálogo, "
     "responde dúvidas comerciais e encaminha o pleito ao executivo responsável.",
     ["whatsapp", "webchat"], "ATEND", "v4"),
    ("SDR Conversacional — Novos Clientes", ServiceType.conversation, ServiceStatus.active,
     "Pré-venda conversacional: atende o lead, conduz o discovery pelos cinco pilares, "
     "qualifica e prepara o handoff no CRM. O agente não gera nem manipula proposta.",
     ["webchat", "whatsapp"], "ATEND", "v3"),
    ("Central de Mídia — Suporte Interno", ServiceType.conversation, ServiceStatus.active,
     "Assistente interno da equipe de mídia: consulta performance de campanha, verba "
     "disponível por praça e status de veiculação.",
     ["portal", "webchat"], "MIDIA", "v2"),
    ("Concierge de Campanhas — VPromo", ServiceType.conversation, ServiceStatus.active,
     "Compara produtos elegíveis do catálogo promocional, simula investimento e monta "
     "a proposta preliminar para análise do executivo.",
     ["webchat"], "PLAN", "v2"),
    ("Guardião de Marca — Aprovação de Peças", ServiceType.conversation, ServiceStatus.active,
     "Revisa peça submetida contra o manual de marca, aponta desvio e registra o parecer "
     "antes do envio ao cliente.",
     ["portal"], "CRIA", "v1"),
    ("Atendimento VBOT — Nível 1", ServiceType.conversation, ServiceStatus.inactive,
     "Atendimento receptivo por voz e webchat com transbordo para operador humano.",
     ["voice", "webchat"], "ATEND", None),
    ("Analisador de Contratos — Jurídico", ServiceType.task, ServiceStatus.active,
     "Task de análise de contratos: extrai partes, vigência, multa e cláusula de rescisão, "
     "e sinaliza divergência frente à minuta padrão.",
     ["api"], "ADM", "v3"),
    ("Automação Valida NF de Fornecedor", ServiceType.task, ServiceStatus.active,
     "Automação responsável por ler o PDF da nota fiscal, validar contra o pedido no ERP e "
     "criar o arquivo individual de cada fornecedor.",
     ["api"], "ADM", "v2"),
    ("Consolidação de Relatórios de Mídia", ServiceType.task, ServiceStatus.active,
     "Consolida diariamente os dados de Meta e Google Ads no data mart e publica o relatório "
     "por cliente.",
     ["api"], "MIDIA", "v5"),
    ("Esteira de Briefing — Planejamento", ServiceType.task, ServiceStatus.active,
     "Lê o briefing recebido, estrutura objetivo, público e entregáveis, e abre os cards da "
     "equipe no board.",
     ["api"], "PLAN", "v1"),
    ("Auditoria de Licenças de IA", ServiceType.task, ServiceStatus.draft,
     "Inventaria ferramentas de IA em uso, cruza licenças pagas e gratuitas com donos e "
     "custos, e devolve o mapa de duplicidade. Etapa 1 do plano de adoção.",
     ["api"], "TECH", None),
    ("Copiloto do Redator", ServiceType.copilot, ServiceStatus.active,
     "Apoia o redator durante a produção: sugere variações de título, ajusta tom e verifica "
     "aderência ao manual de marca.",
     ["portal"], "CRIA", "v2"),
    ("Copiloto do Analista de Mídia", ServiceType.copilot, ServiceStatus.active,
     "Acompanha o analista na otimização: aponta anomalia de performance e sugere "
     "realocação de verba.",
     ["portal"], "MIDIA", "v1"),
]

STAGES = [
    ("01_BOAS_VINDAS", "Boas-vindas", "Cumprimenta, identifica o interlocutor e a demanda."),
    ("02_QUALIFICACAO", "Qualificação", "Aplica os cinco pilares e registra o score."),
    ("03_ESPECIALISTA", "Especialista", "Aciona o agente especialista da demanda."),
    ("04_VALIDACAO", "Validação", "Confirma dados coletados com o interlocutor."),
    ("05_HANDOFF", "Handoff", "Encaminha ao executivo responsável com o contexto."),
]

USERS = [
    ("Diretoria de Tecnologia", "diretoria.tecnologia", ["admin"], "TECH"),
    ("Gerência de Inovação", "gerencia.inovacao", ["admin"], "TECH"),
    ("Coordenação de Atendimento", "coord.atendimento", ["operator"], "ATEND"),
    ("Coordenação de Mídia", "coord.midia", ["builder"], "MIDIA"),
    ("Coordenação de Criação", "coord.criacao", ["builder"], "CRIA"),
    ("Analista de Dados", "analista.dados", ["builder"], "TECH"),
    ("Analista de Planejamento", "analista.planejamento", ["operator"], "PLAN"),
    ("Jurídico", "juridico", ["auditor"], "ADM"),
    ("Controladoria", "controladoria", ["auditor"], "ADM"),
]

INTENTS = [
    "consulta_catalogo", "solicitacao_proposta", "duvida_contrato", "status_campanha",
    "segunda_via", "reclamacao", "agendamento", "suporte_tecnico",
]

CONV_SNIPPETS = [
    "Atualmente o catálogo está com disponibilidade para a praça de Belém.",
    "Para solicitar a proposta, preciso confirmar o CNPJ da empresa.",
    "No momento não encontrei campanha ativa com esse identificador.",
    "Encaminhei sua solicitação ao executivo responsável pela carteira.",
    "A verba disponível para a praça informada é de R$ 18.400 neste mês.",
    "Não consigo confirmar essa informação. Vou transferir para um atendente.",
    "Você escolheu a opção três, certo? Posso seguir com o agendamento.",
    "A peça está fora do manual de marca no uso da assinatura. Ajuste sugerido enviado.",
]


# ─────────────────────────────────────────────────────────────────────────────
def reset_database() -> None:
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def seed_permissions(db: Session) -> dict[str, Permission]:
    catalog = {}
    for code, description in [("*", "Acesso total ao tenant")] + PERMISSIONS:
        existing = db.scalar(select(Permission).where(Permission.code == code))
        if existing is None:
            resource, _, action = code.partition(":")
            existing = Permission(
                code=code, resource=resource or "*", action=action or "*", description=description
            )
            db.add(existing)
        catalog[code] = existing
    db.flush()
    return catalog


def seed_tenant(db: Session) -> Tenant:
    tenant = Tenant(
        slug=settings.vkb_seed_tenant,
        name="Vanguarda MarTech",
        settings_json={
            "regiao": "Norte",
            "colaboradores": 100,
            "projeto": "VKB e Vanguarda IA",
        },
    )
    db.add(tenant)
    db.flush()
    return tenant


def seed_units(db: Session, tenant: Tenant) -> dict[str, Unit]:
    units = {}
    for code, name, cost_center, budget in UNITS:
        unit = Unit(
            tenant_uid=tenant.uid,
            code=code,
            name=name,
            cost_center=cost_center,
            monthly_budget_brl=budget,
        )
        db.add(unit)
        units[code] = unit
    db.flush()
    return units


def seed_roles(db: Session, tenant: Tenant, permissions: dict[str, Permission]) -> dict[str, Role]:
    roles = {}
    for code, (name, description, perm_codes) in SYSTEM_ROLES.items():
        role = Role(
            tenant_uid=tenant.uid,
            code=code,
            name=name,
            description=description,
            is_system=True,
        )
        db.add(role)
        db.flush()
        for perm_code in dict.fromkeys(perm_codes):
            permission = permissions.get(perm_code)
            if permission is not None:
                db.add(RolePermission(role_uid=role.uid, permission_uid=permission.uid))
        roles[code] = role
    db.flush()
    return roles


def seed_users(
    db: Session, tenant: Tenant, roles: dict[str, Role], units: dict[str, Unit]
) -> User:
    admin = User(
        tenant_uid=tenant.uid,
        email=settings.vkb_seed_admin_email.lower(),
        name="Administração da Plataforma",
        job_title="Administrador VKB",
        password_hash=hash_password(settings.vkb_seed_admin_password),
        unit_uid=units["TECH"].uid,
    )
    db.add(admin)
    db.flush()
    db.add(UserRole(user_uid=admin.uid, role_uid=roles["admin"].uid))

    domain = settings.vkb_seed_admin_email.split("@")[-1]
    for name, local_part, role_codes, unit_code in USERS:
        user = User(
            tenant_uid=tenant.uid,
            email=f"{local_part}@{domain}",
            name=name,
            job_title=name,
            password_hash=hash_password("vanguarda"),
            unit_uid=units[unit_code].uid,
            must_change_password=True,
        )
        db.add(user)
        db.flush()
        for role_code in role_codes:
            db.add(UserRole(user_uid=user.uid, role_uid=roles[role_code].uid))

    db.flush()
    return admin


def seed_llm(db: Session, tenant: Tenant) -> list[LLMModel]:
    models: list[LLMModel] = []
    for code, name, base_url, model_specs in PROVIDERS:
        provider = LLMProvider(
            tenant_uid=tenant.uid,
            code=code,
            name=name,
            base_url=base_url,
            credential_ref=f"secret://vkb/{code}/api-key",
        )
        db.add(provider)
        db.flush()
        for model_code, model_name, window, cost_in, cost_out in model_specs:
            model = LLMModel(
                provider_uid=provider.uid,
                code=model_code,
                name=model_name,
                context_window=window,
                input_cost_per_1k=cost_in,
                output_cost_per_1k=cost_out,
            )
            db.add(model)
            models.append(model)
    db.flush()
    return models


def seed_studio(db: Session, tenant: Tenant, admin: User, models: list[LLMModel]):
    skills = []
    for name, description in SKILLS:
        skill = Skill(
            tenant_uid=tenant.uid,
            name=name,
            slug=slugify(name),
            description=description,
            instruction=f"Objetivo: {description}",
            tags_json=["vanguarda"],
            created_by=admin.email,
            updated_by=admin.email,
        )
        db.add(skill)
        skills.append(skill)

    tools = []
    for name, kind, description, approval in TOOLS:
        tool = Tool(
            tenant_uid=tenant.uid,
            name=name,
            slug=slugify(name),
            kind=kind,
            description=description,
            requires_approval=approval,
            parameters_json={"type": "object", "properties": {}},
            created_by=admin.email,
            updated_by=admin.email,
        )
        db.add(tool)
        tools.append(tool)

    for name, kind, system, auth, base_url, status in INTEGRATIONS:
        db.add(
            Integration(
                tenant_uid=tenant.uid,
                name=name,
                slug=slugify(name),
                kind=kind,
                system=system,
                auth_type=auth,
                base_url=base_url,
                status=status,
                credential_ref=f"secret://vkb/integracoes/{slugify(name)}",
                last_error=(
                    "Timeout na automação de interface em 24/08/2026"
                    if status == "degraded"
                    else None
                ),
                created_by=admin.email,
                updated_by=admin.email,
            )
        )

    bases = []
    embedder = get_embedder("hashing")
    for name, description, classification, documentos in KNOWLEDGE:
        base = KnowledgeBase(
            tenant_uid=tenant.uid,
            name=name,
            description=description,
            data_classification=classification,
            created_by=admin.email,
            updated_by=admin.email,
        )
        db.add(base)
        db.flush()
        for titulo, conteudo in documentos:
            documento = KnowledgeDocument(
                base_uid=base.uid,
                title=titulo,
                source_uri=f"s3://vkb-conhecimento/{slugify(name)}/{slugify(titulo)}.md",
                content=conteudo,
            )
            db.add(documento)
            db.flush()
            # Indexar no seed deixa o RAG utilizavel na primeira subida.
            index_document(db, documento, embedder=embedder)
        bases.append(base)

    db.flush()

    agents = []
    for name, role, description, autonomy in AGENTS:
        agent = Agent(
            tenant_uid=tenant.uid,
            name=name,
            slug=slugify(name),
            role=role,
            description=description,
            instruction=(
                f"Você é o agente '{name}' da Vanguarda MarTech. {description} "
                "Responda em português do Brasil, com objetividade. "
                "Não invente dado que não esteja nas fontes disponíveis. "
                "Quando faltar informação, peça ou encaminhe ao humano responsável."
            ),
            model_uid=rng.choice(models).uid,
            temperature=round(rng.uniform(0.0, 0.4), 2),
            autonomy=autonomy,
            owner_email=admin.email,
            knowledge_base_uid=rng.choice(bases).uid,
            created_by=admin.email,
            updated_by=admin.email,
        )
        db.add(agent)
        db.flush()
        for tool in rng.sample(tools, rng.randint(2, 4)):
            db.add(AgentTool(agent_uid=agent.uid, tool_uid=tool.uid))
        for skill in rng.sample(skills, rng.randint(2, 4)):
            db.add(AgentSkill(agent_uid=agent.uid, skill_uid=skill.uid))
        agents.append(agent)

    db.flush()
    return agents


def seed_services(
    db: Session, tenant: Tenant, admin: User, units: dict[str, Unit], agents: list[Agent]
) -> list[Service]:
    services = []
    for name, service_type, status, description, channels, unit_code, version in SERVICES:
        service = Service(
            tenant_uid=tenant.uid,
            unit_uid=units[unit_code].uid,
            name=name,
            slug=slugify(name),
            type=service_type,
            status=status,
            description=description,
            instruction=(
                f"Serviço '{name}'. {description} Respeite as políticas de dados da Vanguarda "
                "e a classificação de informação definida para este serviço."
            ),
            objectives_json=[
                "Reduzir o tempo de resposta ao interlocutor",
                "Manter rastreabilidade completa da execução",
                "Escalar ao humano quando a confiança for baixa",
            ],
            channels_json=channels,
            owner_email=admin.email,
            active_version=version,
            has_draft=version is None,
            data_classification="confidencial" if unit_code == "ADM" else "interno",
            created_by=admin.email,
            updated_by=admin.email,
        )
        db.add(service)
        db.flush()

        supervisor = next(a for a in agents if a.role == "roteador")
        db.add(
            ServiceAgent(
                service_uid=service.uid,
                agent_uid=supervisor.uid,
                is_supervisor=True,
                position=0,
            )
        )
        specialists = [a for a in agents if a.uid != supervisor.uid]
        for position, agent in enumerate(rng.sample(specialists, rng.randint(1, 3)), start=1):
            db.add(
                ServiceAgent(service_uid=service.uid, agent_uid=agent.uid, position=position)
            )

        if service_type is ServiceType.conversation:
            for position, (code, stage_name, instruction) in enumerate(STAGES):
                db.add(
                    ServiceStage(
                        service_uid=service.uid,
                        code=code,
                        name=stage_name,
                        instruction=instruction,
                        exit_condition="Objetivo do estágio atendido ou usuário pediu humano.",
                        position=position,
                    )
                )
        services.append(service)

    db.flush()
    return services


def seed_versions(db: Session, admin: User, services: list[Service]) -> None:
    for service in services:
        if not service.active_version:
            continue
        total = int(service.active_version.lstrip("v"))
        for number in range(1, total + 1):
            is_active = number == total
            created_at = NOW - timedelta(days=(total - number) * 9 + 2)
            version = ServiceVersion(
                service_uid=service.uid,
                version=f"v{number}",
                status=VersionStatus.published if is_active else VersionStatus.rolled_back,
                is_active=is_active,
                tags_json=["producao"] if is_active else [],
                changelog=(
                    "Publicação inicial do serviço."
                    if number == 1
                    else f"Ajuste de instrução e estágios — revisão {number}."
                ),
                snapshot_json={"service": {"name": service.name, "version": f"v{number}"}},
                approved_by="gerencia.inovacao@vanguardamartech.com.br",
                approved_at=created_at,
                created_by=admin.email,
                updated_by=admin.email,
                created_at=created_at,
                updated_at=created_at,
            )
            db.add(version)
            db.flush()
            db.add(
                Deployment(
                    version_uid=version.uid,
                    environment=Environment.production if is_active else Environment.staging,
                    status=DeploymentStatus.succeeded,
                    requested_by=admin.email,
                    approved_by="gerencia.inovacao@vanguardamartech.com.br",
                    started_at=created_at,
                    finished_at=created_at + timedelta(minutes=2),
                    notes="Publicação automática do seed.",
                    created_by=admin.email,
                    created_at=created_at,
                    updated_at=created_at,
                )
            )
    db.flush()


def _span_tree(trace: Trace, model_code: str) -> list[Span]:
    """Reproduz a arvore de execucao observada no console: middlewares,
    chamada de modelo, ferramentas e guardrails."""
    plan = [
        ("01_BOAS_VINDAS", SpanKind.chain, 0),
        ("PatchToolCallsMiddleware.before_agent", SpanKind.chain, 1),
        ("TurnPreflightMiddleware", SpanKind.chain, 1),
        ("EmptyResponseRetryMiddleware.before_agent", SpanKind.chain, 1),
        ("model", SpanKind.chain, 1),
        ("Supervisor de Jornada", SpanKind.model, 2),
        ("TodoListMiddleware.after_model", SpanKind.chain, 2),
        ("tools", SpanKind.chain, 1),
        ("buscar_no_conhecimento", SpanKind.tool, 2),
        ("consultar_crm", SpanKind.tool, 2),
        ("model", SpanKind.chain, 1),
        ("Especialista Comercial", SpanKind.model, 2),
        ("TodoListMiddleware.after_model", SpanKind.chain, 2),
        ("EmptyResponseRetryMiddleware.after_agent", SpanKind.chain, 1),
        ("OutputGuardrailMiddleware.after_agent", SpanKind.guardrail, 1),
    ]

    spans: list[Span] = []
    cursor = trace.started_at
    # O uid so seria gerado no INSERT; aqui ele precisa existir antes, para que os
    # filhos consigam apontar para o pai dentro da mesma arvore.
    uids = [new_uid() for _ in plan]
    parents: dict[int, str] = {}

    for position, (name, kind, depth) in enumerate(plan):
        if kind is SpanKind.model:
            duration = rng.randint(800, 3_400)
            tokens_in = rng.randint(3_000, 9_000)
            tokens_out = rng.randint(60, 240)
        elif kind is SpanKind.tool:
            duration = rng.randint(90, 420)
            tokens_in = tokens_out = 0
        else:
            duration = rng.randint(0, 12)
            tokens_in = tokens_out = 0

        span = Span(
            uid=uids[position],
            trace_uid=trace.uid,
            parent_uid=parents.get(depth - 1) if depth else None,
            name=name,
            kind=kind,
            status="success",
            started_at=cursor,
            duration_ms=duration,
            position=position,
            depth=depth,
            tokens_in=tokens_in,
            tokens_out=tokens_out,
            cost_usd=round((tokens_in * 0.000002) + (tokens_out * 0.000008), 6),
            model=model_code if kind is SpanKind.model else None,
            input_json={"preview": "…"} if kind is not SpanKind.chain else {},
            output_json={"status": "ok"},
            metadata_json={"span_kind": kind.value},
        )
        spans.append(span)
        parents[depth] = span.uid
        cursor += timedelta(milliseconds=duration)

    # Duracao de um span-pai engloba a dos filhos, como numa arvore real.
    for span in reversed(spans):
        children = [child for child in spans if child.parent_uid == span.uid]
        if children:
            span.duration_ms = max(span.duration_ms, sum(c.duration_ms for c in children))
    return spans


def seed_runtime(db: Session, tenant: Tenant, services: list[Service]) -> None:
    """Gera 90 dias de conversas, tarefas e traces."""
    conversational = [s for s in services if s.type is ServiceType.conversation]
    task_services = [s for s in services if s.type is ServiceType.task]
    conv_id = 23_100
    task_id = 4_100

    for days_ago in range(90, -1, -1):
        day = NOW - timedelta(days=days_ago)
        # Volume maior nos ultimos 7 dias, refletindo a adocao recente.
        conv_volume = rng.randint(8, 22) if days_ago <= 7 else rng.randint(0, 6)
        task_volume = rng.randint(1, 4) if days_ago <= 7 else rng.randint(0, 2)

        for _ in range(conv_volume):
            service = rng.choice(conversational)
            if service.status is ServiceStatus.inactive:
                continue
            conv_id += 1
            started = day.replace(
                hour=rng.randint(8, 19), minute=rng.randint(0, 59), second=rng.randint(0, 59)
            )
            status = rng.choices(
                [
                    ConversationStatus.closed,
                    ConversationStatus.active,
                    ConversationStatus.handoff,
                    ConversationStatus.failed,
                ],
                weights=[62, 20, 15, 3],
            )[0]
            tokens = rng.randint(4_000, 24_000)
            conversation = Conversation(
                tenant_uid=tenant.uid,
                service_uid=service.uid,
                public_id=conv_id,
                channel=rng.choice(service.channels_json or ["webchat"]),
                status=status,
                started_at=started,
                ended_at=(
                    started + timedelta(minutes=rng.randint(2, 25))
                    if status is ConversationStatus.closed
                    else None
                ),
                last_message=rng.choice(CONV_SNIPPETS),
                handoff_at=(
                    started + timedelta(minutes=rng.randint(3, 12))
                    if status is ConversationStatus.handoff
                    else None
                ),
                handoff_reason=(
                    "Confiança abaixo do limiar" if status is ConversationStatus.handoff else None
                ),
                intent=rng.choice(INTENTS),
                csat=rng.choice([None, 3, 4, 4, 5, 5]),
                is_recurrent=rng.random() < 0.18,
                tokens_total=tokens,
                cost_usd=round(tokens * 0.0000035, 5),
            )
            db.add(conversation)
            db.flush()

            cursor = started
            for index in range(rng.randint(2, 6)):
                role = "user" if index % 2 == 0 else "assistant"
                db.add(
                    Message(
                        conversation_uid=conversation.uid,
                        role=role,
                        author=None if role == "user" else service.name,
                        content=(
                            rng.choice(CONV_SNIPPETS)
                            if role == "assistant"
                            else "Preciso de informação sobre o atendimento."
                        ),
                        sent_at=cursor,
                        tokens=rng.randint(40, 600),
                    )
                )
                cursor += timedelta(seconds=rng.randint(20, 180))

            _add_trace(db, tenant, service, origin="chat", conversation=conversation)

        for _ in range(task_volume):
            service = rng.choice(task_services)
            task_id += 1
            started = day.replace(hour=rng.randint(1, 22), minute=rng.randint(0, 59))
            status = rng.choices(
                [
                    TaskStatus.succeeded,
                    TaskStatus.failed,
                    TaskStatus.awaiting_approval,
                    TaskStatus.running,
                ],
                weights=[78, 9, 9, 4],
            )[0]
            duration = rng.randint(4_000, 240_000)
            steps = rng.randint(4, 12)
            tokens = rng.randint(2_000, 40_000)
            task = TaskRun(
                tenant_uid=tenant.uid,
                service_uid=service.uid,
                public_id=task_id,
                trigger=rng.choice(["schedule", "webhook", "manual", "api"]),
                status=status,
                started_at=started,
                finished_at=(
                    started + timedelta(milliseconds=duration)
                    if status in (TaskStatus.succeeded, TaskStatus.failed)
                    else None
                ),
                duration_ms=duration,
                steps_total=steps,
                steps_done=steps if status is TaskStatus.succeeded else rng.randint(1, steps),
                requires_human=status is TaskStatus.awaiting_approval,
                error=(
                    "Integração 'Portal do fornecedor' retornou timeout no passo 4."
                    if status is TaskStatus.failed
                    else None
                ),
                input_json={"origem": "seed", "lote": task_id},
                output_json={"arquivos_gerados": rng.randint(1, 40)},
                tokens_total=tokens,
                cost_usd=round(tokens * 0.0000042, 5),
            )
            db.add(task)
            db.flush()
            _add_trace(db, tenant, service, origin="task", task=task)

    db.flush()


def _add_trace(
    db: Session,
    tenant: Tenant,
    service: Service,
    *,
    origin: str,
    conversation: Conversation | None = None,
    task: TaskRun | None = None,
) -> None:
    provider, model_code = rng.choice(
        [
            ("openai", "gpt-4.1"),
            ("openai", "gpt-4.1-mini"),
            ("anthropic", "claude-sonnet-4"),
            ("gemini", "gemini-2.5-pro"),
        ]
    )
    started = conversation.started_at if conversation else task.started_at
    tokens_in = rng.randint(6_000, 26_000)
    tokens_out = rng.randint(80, 900)
    failed = (task is not None and task.status is TaskStatus.failed) or (
        conversation is not None and conversation.status is ConversationStatus.failed
    )

    trace = Trace(
        tenant_uid=tenant.uid,
        service_uid=service.uid,
        origin=origin,
        conversation_uid=conversation.uid if conversation else None,
        task_run_uid=task.uid if task else None,
        reference_label=(
            f"Chat #{conversation.public_id}" if conversation else f"Task #{task.public_id}"
        ),
        provider=provider,
        model=model_code,
        status="error" if failed else "ok",
        started_at=started,
        duration_ms=0,  # definido abaixo, a partir da raiz da arvore de spans
        tokens_in=tokens_in,
        tokens_out=tokens_out,
        tokens_reasoning=0,
        cost_usd=round((tokens_in * 0.000002) + (tokens_out * 0.000008), 5),
    )
    db.add(trace)
    db.flush()

    spans = _span_tree(trace, model_code)
    for span in spans:
        db.add(span)
    # A duracao do trace e a da raiz da arvore — nao um valor solto, senao o
    # cabecalho do trace contradiz os spans que ele resume.
    trace.duration_ms = next(span.duration_ms for span in spans if span.parent_uid is None)


def seed_governance(
    db: Session, tenant: Tenant, admin: User, services: list[Service], units: dict[str, Unit]
) -> None:
    for service in services[:5]:
        for _ in range(rng.randint(1, 3)):
            db.add(
                CurationItem(
                    tenant_uid=tenant.uid,
                    service_uid=service.uid,
                    question="Qual é o prazo de veiculação para a praça de Manaus?",
                    answer=rng.choice(CONV_SNIPPETS),
                    reason=rng.choice(
                        ["confiança baixa", "usuário sinalizou erro", "amostragem de qualidade"]
                    ),
                    decision=rng.choice(
                        [ReviewDecision.pending, ReviewDecision.pending, ReviewDecision.approved]
                    ),
                )
            )

    for service in services[:6]:
        evaluation = Evaluation(
            tenant_uid=tenant.uid,
            service_uid=service.uid,
            name=f"Regressão — {service.name}",
            description="Casos de regressão executados antes de publicar em produção.",
            metric="accuracy",
            threshold=0.85,
            is_gate=True,
            created_by=admin.email,
            updated_by=admin.email,
        )
        db.add(evaluation)
        db.flush()
        for index in range(rng.randint(6, 14)):
            db.add(
                EvaluationCase(
                    evaluation_uid=evaluation.uid,
                    input_text=f"Caso {index + 1}: pergunta representativa do serviço.",
                    expected="Resposta aderente à política e à base de conhecimento.",
                    tags_json=["regressao"],
                )
            )
        total = rng.randint(6, 14)
        passed = rng.randint(int(total * 0.7), total)
        db.add(
            EvaluationRun(
                evaluation_uid=evaluation.uid,
                score=round(passed / total, 3),
                passed=passed / total >= 0.85,
                total_cases=total,
                passed_cases=passed,
                report_json={"executado_por": admin.email},
            )
        )

    policies = [
        ("Dados de contato de lead", "dado_pessoal", "legitimo_interesse", 180, True),
        ("Contratos e minutas", "dado_confidencial", "execucao_contrato", 1_825, False),
        ("Transcrições de atendimento", "dado_pessoal", "consentimento", 90, True),
        ("Métricas de campanha", "dado_operacional", "legitimo_interesse", 730, False),
    ]
    for name, category, basis, retention, redact in policies:
        db.add(
            PrivacyPolicy(
                tenant_uid=tenant.uid,
                name=name,
                data_category=category,
                legal_basis=basis,
                retention_days=retention,
                redact_pii=redact,
                allow_provider_training=False,
                storage_region="br-sao-paulo",
                notes="Provedores de IA não podem usar estes dados para treinamento.",
                created_by=admin.email,
                updated_by=admin.email,
            )
        )

    for service in services[:6]:
        db.add(
            BudgetRule(
                tenant_uid=tenant.uid,
                scope="service",
                scope_uid=service.uid,
                period="monthly",
                limit_usd=float(rng.choice([50, 100, 250, 500])),
                alert_at_percent=80,
                hard_stop=rng.random() < 0.3,
            )
        )
    for unit in list(units.values())[:3]:
        db.add(
            BudgetRule(
                tenant_uid=tenant.uid,
                scope="unit",
                scope_uid=unit.uid,
                period="monthly",
                limit_usd=1_000.0,
                alert_at_percent=75,
            )
        )

    flags = [
        ("voice_channel", "Canal de voz", "Habilita atendimento por voz nos serviços."),
        ("copilot_studio", "Estúdio de copilotos", "Permite criar serviços do tipo copiloto."),
        ("rpa_runner", "Execução de RPA", "Habilita automação de interface para sistemas sem API."),
        ("auto_curation", "Curadoria automática", "Amostra respostas para revisão humana."),
        ("byo_llm", "Modelos próprios", "Permite conectar contas corporativas de LLM."),
    ]
    for code, name, description in flags:
        db.add(
            FeatureFlag(
                tenant_uid=tenant.uid,
                code=code,
                name=name,
                description=description,
                enabled=code != "rpa_runner",
            )
        )

    raw, prefix, key_hash = generate_api_key()
    db.add(
        ApiKey(
            tenant_uid=tenant.uid,
            name="Portal do Desenvolvedor — integração interna",
            prefix=prefix,
            key_hash=key_hash,
            scopes_json=["services:read", "observability:read"],
            created_by=admin.email,
        )
    )

    actions = [
        ("login", "user", "Login de coord.midia@vanguardamartech.com.br"),
        ("create", "service", "Serviço 'Auditoria de Licenças de IA' criado"),
        ("update", "agent", "Agente 'Especialista Comercial' alterado"),
        ("deploy", "deployment", "Versão v4 publicada em production"),
        ("version_approve", "service_version", "Versão v3 aprovada"),
        ("export", "portability_job", "Exportação de 34 ativos"),
        ("revoke", "api_key", "Chave de API 'Piloto' revogada"),
        ("password_reset", "user", "Senha de juridico@ redefinida por administrador"),
    ]
    for index in range(40):
        action, resource_type, summary = rng.choice(actions)
        db.add(
            AuditLog(
                tenant_uid=tenant.uid,
                actor_email=admin.email,
                action=action,
                resource_type=resource_type,
                summary=summary,
                ip_address="10.20.0." + str(rng.randint(2, 250)),
                payload_json={},
                created_at=NOW - timedelta(hours=index * 5),
            )
        )

    db.flush()
    print(f"  chave de API de demonstração: {raw}")


def main(reset: bool = False) -> None:
    if reset:
        print("→ recriando o schema…")
        reset_database()
    else:
        init_db()

    db: Session = SessionLocal()
    try:
        if db.scalar(select(Tenant).where(Tenant.slug == settings.vkb_seed_tenant)):
            print(
                f"Tenant '{settings.vkb_seed_tenant}' já existe. "
                "Use --reset para recriar do zero."
            )
            return

        print("→ permissões e papéis…")
        permissions = seed_permissions(db)
        tenant = seed_tenant(db)
        units = seed_units(db, tenant)
        roles = seed_roles(db, tenant, permissions)

        print("→ usuários…")
        admin = seed_users(db, tenant, roles, units)

        print("→ LLM Gateway…")
        models = seed_llm(db, tenant)

        print("→ AI Studio (skills, ferramentas, integrações, conhecimento, agentes)…")
        agents = seed_studio(db, tenant, admin, models)

        print("→ serviços…")
        services = seed_services(db, tenant, admin, units, agents)

        print("→ versões e implantações…")
        seed_versions(db, admin, services)

        print("→ execuções, conversas e traces (90 dias)…")
        seed_runtime(db, tenant, services)

        print("→ governança, privacidade e FinOps…")
        seed_governance(db, tenant, admin, services, units)

        db.commit()
        print(
            "\n✓ Seed concluído.\n"
            f"  console:  {settings.vkb_seed_admin_email} / {settings.vkb_seed_admin_password}\n"
            f"  tenant:   {tenant.name} ({tenant.slug})"
        )
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Popula o tenant de demonstração do VKB.")
    parser.add_argument("--reset", action="store_true", help="Recria o schema antes de popular.")
    args = parser.parse_args()
    try:
        main(reset=args.reset)
    except KeyboardInterrupt:
        sys.exit(130)
