from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


# ── LLM Gateway ────────────────────────────────────────────────────────────────
class LLMModelOut(ORMModel):
    uid: str
    code: str
    name: str
    context_window: int
    input_cost_per_1k: float
    output_cost_per_1k: float
    supports_tools: bool
    is_enabled: bool


class LLMProviderOut(ORMModel):
    uid: str
    code: str
    name: str
    base_url: str | None = None
    is_enabled: bool
    credential_ref: str | None = None
    models: list[LLMModelOut] = []


class LLMProviderIn(BaseModel):
    code: str
    name: str
    base_url: str | None = None
    credential_ref: str | None = None
    is_enabled: bool = True


# ── Skills, ferramentas, integracoes ───────────────────────────────────────────
class SkillOut(ORMModel):
    uid: str
    name: str
    slug: str
    description: str
    instruction: str
    tags_json: list = []
    is_enabled: bool
    created_at: datetime
    updated_at: datetime
    created_by: str | None = None


class SkillIn(BaseModel):
    name: str
    description: str = ""
    instruction: str = ""
    tags: list[str] = []
    is_enabled: bool = True


class ToolOut(ORMModel):
    uid: str
    name: str
    slug: str
    kind: str
    description: str
    config_json: dict = {}
    parameters_json: dict = {}
    requires_approval: bool
    is_enabled: bool
    created_at: datetime


class ToolIn(BaseModel):
    name: str
    kind: str = "http"
    description: str = ""
    config: dict = {}
    parameters: dict = {}
    requires_approval: bool = False
    is_enabled: bool = True


class IntegrationOut(ORMModel):
    uid: str
    name: str
    slug: str
    kind: str
    system: str
    auth_type: str
    base_url: str | None = None
    rate_limit_per_min: int
    status: str
    last_error: str | None = None
    created_at: datetime


class IntegrationIn(BaseModel):
    name: str
    kind: str = "rest"
    system: str = ""
    auth_type: str = "oauth2"
    base_url: str | None = None
    credential_ref: str | None = None
    rate_limit_per_min: int = 60


# ── Conhecimento ───────────────────────────────────────────────────────────────
class KnowledgeDocumentOut(ORMModel):
    uid: str
    title: str
    source_uri: str | None = None
    mime_type: str
    chunk_count: int
    status: str
    created_at: datetime


class KnowledgeBaseOut(ORMModel):
    uid: str
    name: str
    description: str
    embedding_model: str
    chunk_size: int
    data_classification: str
    is_enabled: bool
    document_count: int = 0


class KnowledgeBaseIn(BaseModel):
    name: str
    description: str = ""
    embedding_model: str = "text-embedding-3-small"
    chunk_size: int = 800
    data_classification: str = "interno"


# ── Agentes ────────────────────────────────────────────────────────────────────
class AgentOut(ORMModel):
    uid: str
    name: str
    slug: str
    role: str
    description: str
    instruction: str
    temperature: float
    max_tokens: int
    autonomy: str
    owner_email: str | None = None
    model_uid: str | None = None
    model_code: str | None = None
    knowledge_base_uid: str | None = None
    is_enabled: bool
    tool_uids: list[str] = []
    skill_uids: list[str] = []
    created_at: datetime
    updated_at: datetime


class AgentIn(BaseModel):
    name: str
    role: str = ""
    description: str = ""
    instruction: str = ""
    model_uid: str | None = None
    temperature: float = Field(0.2, ge=0.0, le=2.0)
    max_tokens: int = Field(2048, ge=64, le=32_000)
    autonomy: str = "n1_executa_com_aprovacao"
    owner_email: str | None = None
    knowledge_base_uid: str | None = None
    tool_uids: list[str] = []
    skill_uids: list[str] = []
    is_enabled: bool = True


# ── Servicos ───────────────────────────────────────────────────────────────────
class ServiceStageOut(ORMModel):
    uid: str
    code: str
    name: str
    instruction: str
    exit_condition: str
    position: int


class ServiceStageIn(BaseModel):
    code: str
    name: str
    instruction: str = ""
    exit_condition: str = ""
    position: int = 0


class ServiceAgentOut(BaseModel):
    uid: str
    agent_uid: str
    agent_name: str
    agent_role: str
    is_supervisor: bool
    position: int


class ServiceOut(ORMModel):
    uid: str
    name: str
    slug: str
    type: str
    status: str
    description: str
    channels_json: list = []
    owner_email: str | None = None
    active_version: str | None = None
    has_draft: bool
    created_at: datetime
    updated_at: datetime
    created_by: str | None = None
    updated_by: str | None = None


class ServiceDetail(ServiceOut):
    instruction: str = ""
    objectives_json: list = []
    handoff_enabled: bool = True
    data_classification: str = "interno"
    unit_uid: str | None = None
    config_json: dict = {}
    agents: list[ServiceAgentOut] = []
    stages: list[ServiceStageOut] = []


class ServiceIn(BaseModel):
    name: str
    type: str
    description: str = ""
    instruction: str = ""
    objectives: list[str] = []
    channels: list[str] = []
    owner_email: str | None = None
    unit_uid: str | None = None
    handoff_enabled: bool = True
    data_classification: str = "interno"


class ServicePatch(BaseModel):
    name: str | None = None
    description: str | None = None
    instruction: str | None = None
    objectives: list[str] | None = None
    channels: list[str] | None = None
    status: str | None = None
    owner_email: str | None = None
    unit_uid: str | None = None
    handoff_enabled: bool | None = None
    data_classification: str | None = None


class ServiceAgentIn(BaseModel):
    agent_uid: str
    is_supervisor: bool = False
    position: int = 0
