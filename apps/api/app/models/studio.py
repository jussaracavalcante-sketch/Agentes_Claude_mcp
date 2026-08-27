"""Camadas 3, 4 e 5 — AI Studio: servicos, agentes, skills, ferramentas,
integracoes, provedores de LLM e base de conhecimento."""

from __future__ import annotations

import enum

from sqlalchemy import (
    JSON,
    Boolean,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import AuthorshipMixin, Base, TimestampMixin, UIDMixin


class ServiceType(str, enum.Enum):
    """Os tres grupos de servico do relatorio (secao 5)."""

    conversation = "conversation"
    task = "task"
    copilot = "copilot"


class ServiceStatus(str, enum.Enum):
    draft = "draft"
    active = "active"
    inactive = "inactive"
    archived = "archived"


class Channel(str, enum.Enum):
    webchat = "webchat"
    whatsapp = "whatsapp"
    voice = "voice"
    email = "email"
    api = "api"
    portal = "portal"


class AutonomyLevel(str, enum.Enum):
    """Niveis de autonomia — N4 vedado por politica (governance/autonomy-levels)."""

    n0_sugere = "n0_sugere"
    n1_executa_com_aprovacao = "n1_executa_com_aprovacao"
    n2_executa_reversivel = "n2_executa_reversivel"
    n3_executa_irreversivel = "n3_executa_irreversivel"


class LLMProvider(UIDMixin, TimestampMixin, Base):
    """Provedor do LLM Gateway. A plataforma nao depende de um unico fornecedor."""

    __tablename__ = "llm_providers"

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    code: Mapped[str] = mapped_column(String(48), index=True)
    name: Mapped[str] = mapped_column(String(120))
    base_url: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    # Credencial corporativa: somente referencia ao segredo, nunca o valor.
    credential_ref: Mapped[str | None] = mapped_column(String(160), nullable=True)

    models: Mapped[list[LLMModel]] = relationship(
        back_populates="provider", cascade="all, delete-orphan"
    )


class LLMModel(UIDMixin, TimestampMixin, Base):
    __tablename__ = "llm_models"

    provider_uid: Mapped[str] = mapped_column(ForeignKey("llm_providers.uid", ondelete="CASCADE"))
    code: Mapped[str] = mapped_column(String(96), index=True)
    name: Mapped[str] = mapped_column(String(120))
    context_window: Mapped[int] = mapped_column(Integer, default=128_000)
    input_cost_per_1k: Mapped[float] = mapped_column(Float, default=0.0)
    output_cost_per_1k: Mapped[float] = mapped_column(Float, default=0.0)
    supports_tools: Mapped[bool] = mapped_column(Boolean, default=True)
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True)

    provider: Mapped[LLMProvider] = relationship(back_populates="models")


class Skill(UIDMixin, TimestampMixin, AuthorshipMixin, Base):
    """Habilidade reutilizavel entre agentes."""

    __tablename__ = "skills"

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(160), index=True)
    slug: Mapped[str] = mapped_column(String(160), index=True)
    description: Mapped[str] = mapped_column(Text, default="")
    instruction: Mapped[str] = mapped_column(Text, default="")
    input_schema_json: Mapped[dict] = mapped_column(JSON, default=dict)
    tags_json: Mapped[list] = mapped_column(JSON, default=list)
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True)


class Tool(UIDMixin, TimestampMixin, AuthorshipMixin, Base):
    """Ferramenta chamavel pelo agente (HTTP, SQL, MCP, RPA)."""

    __tablename__ = "tools"

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(160), index=True)
    slug: Mapped[str] = mapped_column(String(160), index=True)
    kind: Mapped[str] = mapped_column(String(32), default="http")
    description: Mapped[str] = mapped_column(Text, default="")
    config_json: Mapped[dict] = mapped_column(JSON, default=dict)
    parameters_json: Mapped[dict] = mapped_column(JSON, default=dict)
    requires_approval: Mapped[bool] = mapped_column(Boolean, default=False)
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True)


class Integration(UIDMixin, TimestampMixin, AuthorshipMixin, Base):
    """Conector com sistema corporativo (CRM, ERP, banco, canal, RPA)."""

    __tablename__ = "integrations"

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(160), index=True)
    slug: Mapped[str] = mapped_column(String(160), index=True)
    kind: Mapped[str] = mapped_column(String(48), default="rest")
    system: Mapped[str] = mapped_column(String(96), default="")
    auth_type: Mapped[str] = mapped_column(String(48), default="oauth2")
    base_url: Mapped[str | None] = mapped_column(String(255), nullable=True)
    credential_ref: Mapped[str | None] = mapped_column(String(160), nullable=True)
    rate_limit_per_min: Mapped[int] = mapped_column(Integer, default=60)
    status: Mapped[str] = mapped_column(String(32), default="connected")
    last_error: Mapped[str | None] = mapped_column(Text, nullable=True)
    config_json: Mapped[dict] = mapped_column(JSON, default=dict)


class KnowledgeBase(UIDMixin, TimestampMixin, AuthorshipMixin, Base):
    """Camada 5 — repositorio de conhecimento para RAG."""

    __tablename__ = "knowledge_bases"

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(160), index=True)
    description: Mapped[str] = mapped_column(Text, default="")
    embedding_model: Mapped[str] = mapped_column(String(96), default="text-embedding-3-small")
    chunk_size: Mapped[int] = mapped_column(Integer, default=800)
    data_classification: Mapped[str] = mapped_column(String(32), default="interno")
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True)

    documents: Mapped[list[KnowledgeDocument]] = relationship(
        back_populates="base", cascade="all, delete-orphan"
    )


class KnowledgeDocument(UIDMixin, TimestampMixin, Base):
    __tablename__ = "knowledge_documents"

    base_uid: Mapped[str] = mapped_column(ForeignKey("knowledge_bases.uid", ondelete="CASCADE"))
    title: Mapped[str] = mapped_column(String(255))
    source_uri: Mapped[str | None] = mapped_column(String(500), nullable=True)
    mime_type: Mapped[str] = mapped_column(String(96), default="text/markdown")
    content: Mapped[str] = mapped_column(Text, default="")
    chunk_count: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(32), default="indexed")

    base: Mapped[KnowledgeBase] = relationship(back_populates="documents")
    chunks: Mapped[list[KnowledgeChunk]] = relationship(
        back_populates="document", cascade="all, delete-orphan", order_by="KnowledgeChunk.ordinal"
    )


class KnowledgeChunk(UIDMixin, TimestampMixin, Base):
    """Trecho indexado de um documento, com o vetor da recuperacao semantica.

    O vetor e guardado como JSON para nao amarrar o schema a uma extensao de
    banco. Em Postgres com pgvector a busca usa o indice; sem ele, a similaridade
    e calculada na aplicacao (ver app/rag/retrieval.py).
    """

    __tablename__ = "knowledge_chunks"
    __table_args__ = (
        UniqueConstraint("document_uid", "ordinal", name="uq_chunk_document_ordinal"),
    )

    base_uid: Mapped[str] = mapped_column(
        ForeignKey("knowledge_bases.uid", ondelete="CASCADE"), index=True
    )
    document_uid: Mapped[str] = mapped_column(
        ForeignKey("knowledge_documents.uid", ondelete="CASCADE"), index=True
    )
    ordinal: Mapped[int] = mapped_column(Integer, default=0)
    content: Mapped[str] = mapped_column(Text, default="")
    token_count: Mapped[int] = mapped_column(Integer, default=0)
    embedder: Mapped[str] = mapped_column(String(32), default="hashing")
    dimensions: Mapped[int] = mapped_column(Integer, default=0)
    embedding_json: Mapped[list] = mapped_column(JSON, default=list)

    document: Mapped[KnowledgeDocument] = relationship(back_populates="chunks")


class Agent(UIDMixin, TimestampMixin, AuthorshipMixin, Base):
    """Agente especializado — instrucao, papel, modelo e ferramentas."""

    __tablename__ = "agents"

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(160), index=True)
    slug: Mapped[str] = mapped_column(String(160), index=True)
    role: Mapped[str] = mapped_column(String(120), default="")
    description: Mapped[str] = mapped_column(Text, default="")
    instruction: Mapped[str] = mapped_column(Text, default="")
    model_uid: Mapped[str | None] = mapped_column(
        ForeignKey("llm_models.uid", ondelete="SET NULL"), nullable=True
    )
    temperature: Mapped[float] = mapped_column(Float, default=0.2)
    max_tokens: Mapped[int] = mapped_column(Integer, default=2048)
    autonomy: Mapped[AutonomyLevel] = mapped_column(
        Enum(AutonomyLevel, native_enum=False, length=32),
        default=AutonomyLevel.n1_executa_com_aprovacao,
    )
    owner_email: Mapped[str | None] = mapped_column(String(160), nullable=True)
    knowledge_base_uid: Mapped[str | None] = mapped_column(
        ForeignKey("knowledge_bases.uid", ondelete="SET NULL"), nullable=True
    )
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True)

    model: Mapped[LLMModel | None] = relationship()
    tools: Mapped[list[AgentTool]] = relationship(
        back_populates="agent", cascade="all, delete-orphan"
    )
    skills: Mapped[list[AgentSkill]] = relationship(
        back_populates="agent", cascade="all, delete-orphan"
    )


class AgentTool(UIDMixin, Base):
    __tablename__ = "agent_tools"

    agent_uid: Mapped[str] = mapped_column(ForeignKey("agents.uid", ondelete="CASCADE"))
    tool_uid: Mapped[str] = mapped_column(ForeignKey("tools.uid", ondelete="CASCADE"))

    agent: Mapped[Agent] = relationship(back_populates="tools")
    tool: Mapped[Tool] = relationship()


class AgentSkill(UIDMixin, Base):
    __tablename__ = "agent_skills"

    agent_uid: Mapped[str] = mapped_column(ForeignKey("agents.uid", ondelete="CASCADE"))
    skill_uid: Mapped[str] = mapped_column(ForeignKey("skills.uid", ondelete="CASCADE"))

    agent: Mapped[Agent] = relationship(back_populates="skills")
    skill: Mapped[Skill] = relationship()


class Service(UIDMixin, TimestampMixin, AuthorshipMixin, Base):
    """Servico de IA publicado — conversa, tarefa ou copiloto."""

    __tablename__ = "services"

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    unit_uid: Mapped[str | None] = mapped_column(
        ForeignKey("units.uid", ondelete="SET NULL"), nullable=True
    )
    name: Mapped[str] = mapped_column(String(200), index=True)
    slug: Mapped[str] = mapped_column(String(200), index=True)
    type: Mapped[ServiceType] = mapped_column(
        Enum(ServiceType, native_enum=False, length=16), index=True
    )
    status: Mapped[ServiceStatus] = mapped_column(
        Enum(ServiceStatus, native_enum=False, length=16), default=ServiceStatus.draft, index=True
    )
    description: Mapped[str] = mapped_column(Text, default="")
    instruction: Mapped[str] = mapped_column(Text, default="")
    objectives_json: Mapped[list] = mapped_column(JSON, default=list)
    channels_json: Mapped[list] = mapped_column(JSON, default=list)
    owner_email: Mapped[str | None] = mapped_column(String(160), nullable=True)
    active_version: Mapped[str | None] = mapped_column(String(32), nullable=True)
    has_draft: Mapped[bool] = mapped_column(Boolean, default=True)
    handoff_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    data_classification: Mapped[str] = mapped_column(String(32), default="interno")
    config_json: Mapped[dict] = mapped_column(JSON, default=dict)

    agents: Mapped[list[ServiceAgent]] = relationship(
        back_populates="service", cascade="all, delete-orphan"
    )
    stages: Mapped[list[ServiceStage]] = relationship(
        back_populates="service", cascade="all, delete-orphan", order_by="ServiceStage.position"
    )


class ServiceAgent(UIDMixin, Base):
    """Agente vinculado ao servico. `is_supervisor` marca o roteador da jornada."""

    __tablename__ = "service_agents"

    service_uid: Mapped[str] = mapped_column(ForeignKey("services.uid", ondelete="CASCADE"))
    agent_uid: Mapped[str] = mapped_column(ForeignKey("agents.uid", ondelete="CASCADE"))
    is_supervisor: Mapped[bool] = mapped_column(Boolean, default=False)
    position: Mapped[int] = mapped_column(Integer, default=0)

    service: Mapped[Service] = relationship(back_populates="agents")
    agent: Mapped[Agent] = relationship()


class ServiceStage(UIDMixin, Base):
    """Estagio da jornada (ex.: 01_BOAS_VINDAS, 02_QUALIFICACAO)."""

    __tablename__ = "service_stages"

    service_uid: Mapped[str] = mapped_column(ForeignKey("services.uid", ondelete="CASCADE"))
    code: Mapped[str] = mapped_column(String(64))
    name: Mapped[str] = mapped_column(String(160))
    instruction: Mapped[str] = mapped_column(Text, default="")
    exit_condition: Mapped[str] = mapped_column(Text, default="")
    position: Mapped[int] = mapped_column(Integer, default=0)

    service: Mapped[Service] = relationship(back_populates="stages")
