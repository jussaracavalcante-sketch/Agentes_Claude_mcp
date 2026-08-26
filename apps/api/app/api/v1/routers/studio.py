"""AI Studio — servicos, agentes, skills, ferramentas, integracoes,
conhecimento e LLM Gateway."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.api.deps import get_current_user, record_audit, require
from app.core.text import slugify
from app.db.session import get_db
from app.models import (
    Agent,
    AgentSkill,
    AgentTool,
    Integration,
    KnowledgeBase,
    KnowledgeDocument,
    LLMModel,
    LLMProvider,
    Service,
    ServiceAgent,
    ServiceStage,
    ServiceStatus,
    ServiceType,
    Skill,
    Tool,
    User,
)
from app.schemas.common import Message
from app.schemas.studio import (
    AgentIn,
    AgentOut,
    IntegrationIn,
    IntegrationOut,
    KnowledgeBaseIn,
    KnowledgeBaseOut,
    KnowledgeDocumentOut,
    LLMProviderIn,
    LLMProviderOut,
    ServiceAgentIn,
    ServiceAgentOut,
    ServiceDetail,
    ServiceIn,
    ServiceOut,
    ServicePatch,
    ServiceStageIn,
    ServiceStageOut,
    SkillIn,
    SkillOut,
    ToolIn,
    ToolOut,
)

router = APIRouter(tags=["ai-studio"])


# ── Servicos ───────────────────────────────────────────────────────────────────
def _service_detail(service: Service) -> ServiceDetail:
    # `agents` e `stages` no ORM sao vinculos; no schema sao projecoes achatadas,
    # por isso a validacao parte do resumo e as listas sao montadas em seguida.
    detail = ServiceDetail(
        **ServiceOut.model_validate(service).model_dump(),
        instruction=service.instruction,
        objectives_json=service.objectives_json,
        handoff_enabled=service.handoff_enabled,
        data_classification=service.data_classification,
        unit_uid=service.unit_uid,
        config_json=service.config_json,
    )
    detail.agents = [
        ServiceAgentOut(
            uid=sa.uid,
            agent_uid=sa.agent_uid,
            agent_name=sa.agent.name if sa.agent else "",
            agent_role=sa.agent.role if sa.agent else "",
            is_supervisor=sa.is_supervisor,
            position=sa.position,
        )
        for sa in sorted(service.agents, key=lambda s: s.position)
    ]
    detail.stages = [ServiceStageOut.model_validate(s) for s in service.stages]
    return detail


def _get_service(db: Session, tenant_uid: str, uid: str) -> Service:
    service = db.scalar(
        select(Service)
        .options(
            selectinload(Service.agents).selectinload(ServiceAgent.agent),
            selectinload(Service.stages),
        )
        .where(Service.uid == uid, Service.tenant_uid == tenant_uid)
    )
    if service is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Servico nao encontrado.")
    return service


@router.get("/services", response_model=list[ServiceOut])
def list_services(
    type: ServiceType | None = None,
    status_filter: ServiceStatus | None = Query(None, alias="status"),
    q: str | None = None,
    user: User = Depends(require("services:read")),
    db: Session = Depends(get_db),
):
    stmt = select(Service).where(Service.tenant_uid == user.tenant_uid)
    if type is not None:
        stmt = stmt.where(Service.type == type)
    if status_filter is not None:
        stmt = stmt.where(Service.status == status_filter)
    if q:
        stmt = stmt.where(Service.name.ilike(f"%{q}%"))
    stmt = stmt.order_by(Service.updated_at.desc())
    return [ServiceOut.model_validate(s) for s in db.scalars(stmt).all()]


@router.post("/services", response_model=ServiceDetail, status_code=201)
def create_service(
    payload: ServiceIn,
    request: Request,
    user: User = Depends(require("services:write")),
    db: Session = Depends(get_db),
):
    try:
        service_type = ServiceType(payload.type)
    except ValueError as exc:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Tipo invalido.") from exc

    service = Service(
        tenant_uid=user.tenant_uid,
        unit_uid=payload.unit_uid,
        name=payload.name,
        slug=slugify(payload.name),
        type=service_type,
        status=ServiceStatus.draft,
        description=payload.description,
        instruction=payload.instruction,
        objectives_json=payload.objectives,
        channels_json=payload.channels,
        owner_email=payload.owner_email or user.email,
        handoff_enabled=payload.handoff_enabled,
        data_classification=payload.data_classification,
        created_by=user.email,
        updated_by=user.email,
    )
    db.add(service)
    db.commit()
    db.refresh(service)
    record_audit(
        db,
        user=user,
        action="create",
        resource_type="service",
        resource_uid=service.uid,
        summary=f"Servico '{service.name}' criado",
        request=request,
    )
    return _service_detail(service)


@router.get("/services/{uid}", response_model=ServiceDetail)
def get_service(
    uid: str,
    user: User = Depends(require("services:read")),
    db: Session = Depends(get_db),
):
    return _service_detail(_get_service(db, user.tenant_uid, uid))


@router.patch("/services/{uid}", response_model=ServiceDetail)
def update_service(
    uid: str,
    payload: ServicePatch,
    request: Request,
    user: User = Depends(require("services:write")),
    db: Session = Depends(get_db),
):
    service = _get_service(db, user.tenant_uid, uid)
    data = payload.model_dump(exclude_unset=True)

    if "objectives" in data:
        service.objectives_json = data.pop("objectives")
    if "channels" in data:
        service.channels_json = data.pop("channels")
    if "status" in data and data["status"] is not None:
        service.status = ServiceStatus(data.pop("status"))
    if "name" in data and data["name"]:
        service.slug = slugify(data["name"])

    for field, value in data.items():
        if value is not None:
            setattr(service, field, value)

    service.updated_by = user.email
    service.has_draft = True
    db.commit()
    db.refresh(service)
    record_audit(
        db,
        user=user,
        action="update",
        resource_type="service",
        resource_uid=service.uid,
        summary=f"Servico '{service.name}' alterado",
        payload={"fields": sorted(payload.model_dump(exclude_unset=True))},
        request=request,
    )
    return _service_detail(service)


@router.delete("/services/{uid}", response_model=Message)
def delete_service(
    uid: str,
    request: Request,
    user: User = Depends(require("services:delete")),
    db: Session = Depends(get_db),
):
    service = _get_service(db, user.tenant_uid, uid)
    name = service.name
    db.delete(service)
    db.commit()
    record_audit(
        db,
        user=user,
        action="delete",
        resource_type="service",
        resource_uid=uid,
        summary=f"Servico '{name}' removido",
        request=request,
    )
    return Message(detail="Servico removido.")


@router.post("/services/{uid}/agents", response_model=ServiceDetail, status_code=201)
def attach_agent(
    uid: str,
    payload: ServiceAgentIn,
    user: User = Depends(require("services:write")),
    db: Session = Depends(get_db),
):
    service = _get_service(db, user.tenant_uid, uid)
    agent = db.scalar(
        select(Agent).where(Agent.uid == payload.agent_uid, Agent.tenant_uid == user.tenant_uid)
    )
    if agent is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Agente nao encontrado.")
    if any(sa.agent_uid == agent.uid for sa in service.agents):
        raise HTTPException(status.HTTP_409_CONFLICT, "Agente ja vinculado ao servico.")

    db.add(
        ServiceAgent(
            service_uid=service.uid,
            agent_uid=agent.uid,
            is_supervisor=payload.is_supervisor,
            position=payload.position,
        )
    )
    service.has_draft = True
    db.commit()
    db.refresh(service)
    return _service_detail(service)


@router.delete("/services/{uid}/agents/{link_uid}", response_model=ServiceDetail)
def detach_agent(
    uid: str,
    link_uid: str,
    user: User = Depends(require("services:write")),
    db: Session = Depends(get_db),
):
    service = _get_service(db, user.tenant_uid, uid)
    link = next((sa for sa in service.agents if sa.uid == link_uid), None)
    if link is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Vinculo nao encontrado.")
    db.delete(link)
    service.has_draft = True
    db.commit()
    db.refresh(service)
    return _service_detail(service)


@router.post("/services/{uid}/stages", response_model=ServiceDetail, status_code=201)
def add_stage(
    uid: str,
    payload: ServiceStageIn,
    user: User = Depends(require("services:write")),
    db: Session = Depends(get_db),
):
    service = _get_service(db, user.tenant_uid, uid)
    db.add(ServiceStage(service_uid=service.uid, **payload.model_dump()))
    service.has_draft = True
    db.commit()
    db.refresh(service)
    return _service_detail(service)


@router.delete("/services/{uid}/stages/{stage_uid}", response_model=ServiceDetail)
def remove_stage(
    uid: str,
    stage_uid: str,
    user: User = Depends(require("services:write")),
    db: Session = Depends(get_db),
):
    service = _get_service(db, user.tenant_uid, uid)
    stage = next((s for s in service.stages if s.uid == stage_uid), None)
    if stage is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Estagio nao encontrado.")
    db.delete(stage)
    service.has_draft = True
    db.commit()
    db.refresh(service)
    return _service_detail(service)


# ── Agentes ────────────────────────────────────────────────────────────────────
def _agent_out(agent: Agent) -> AgentOut:
    out = AgentOut.model_validate(agent)
    out.model_code = agent.model.code if agent.model else None
    out.tool_uids = [at.tool_uid for at in agent.tools]
    out.skill_uids = [asx.skill_uid for asx in agent.skills]
    return out


@router.get("/agents", response_model=list[AgentOut])
def list_agents(
    q: str | None = None,
    user: User = Depends(require("agents:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(Agent)
        .options(selectinload(Agent.tools), selectinload(Agent.skills), selectinload(Agent.model))
        .where(Agent.tenant_uid == user.tenant_uid)
    )
    if q:
        stmt = stmt.where(Agent.name.ilike(f"%{q}%"))
    return [_agent_out(a) for a in db.scalars(stmt.order_by(Agent.name)).all()]


@router.post("/agents", response_model=AgentOut, status_code=201)
def create_agent(
    payload: AgentIn,
    request: Request,
    user: User = Depends(require("agents:write")),
    db: Session = Depends(get_db),
):
    if payload.autonomy == "n4_autonomo":
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            "Autonomia N4 e vedada pela politica de governanca.",
        )
    agent = Agent(
        tenant_uid=user.tenant_uid,
        name=payload.name,
        slug=slugify(payload.name),
        role=payload.role,
        description=payload.description,
        instruction=payload.instruction,
        model_uid=payload.model_uid,
        temperature=payload.temperature,
        max_tokens=payload.max_tokens,
        autonomy=payload.autonomy,
        owner_email=payload.owner_email or user.email,
        knowledge_base_uid=payload.knowledge_base_uid,
        is_enabled=payload.is_enabled,
        created_by=user.email,
        updated_by=user.email,
    )
    db.add(agent)
    db.flush()
    for tool_uid in payload.tool_uids:
        db.add(AgentTool(agent_uid=agent.uid, tool_uid=tool_uid))
    for skill_uid in payload.skill_uids:
        db.add(AgentSkill(agent_uid=agent.uid, skill_uid=skill_uid))
    db.commit()
    db.refresh(agent)
    record_audit(
        db,
        user=user,
        action="create",
        resource_type="agent",
        resource_uid=agent.uid,
        summary=f"Agente '{agent.name}' criado",
        request=request,
    )
    return _agent_out(agent)


@router.get("/agents/{uid}", response_model=AgentOut)
def get_agent(
    uid: str,
    user: User = Depends(require("agents:read")),
    db: Session = Depends(get_db),
):
    agent = db.scalar(select(Agent).where(Agent.uid == uid, Agent.tenant_uid == user.tenant_uid))
    if agent is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Agente nao encontrado.")
    return _agent_out(agent)


@router.put("/agents/{uid}", response_model=AgentOut)
def update_agent(
    uid: str,
    payload: AgentIn,
    request: Request,
    user: User = Depends(require("agents:write")),
    db: Session = Depends(get_db),
):
    agent = db.scalar(select(Agent).where(Agent.uid == uid, Agent.tenant_uid == user.tenant_uid))
    if agent is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Agente nao encontrado.")

    data = payload.model_dump(exclude={"tool_uids", "skill_uids"})
    for field, value in data.items():
        setattr(agent, field, value)
    agent.slug = slugify(payload.name)
    agent.updated_by = user.email

    for link in list(agent.tools):
        db.delete(link)
    for link in list(agent.skills):
        db.delete(link)
    db.flush()
    for tool_uid in payload.tool_uids:
        db.add(AgentTool(agent_uid=agent.uid, tool_uid=tool_uid))
    for skill_uid in payload.skill_uids:
        db.add(AgentSkill(agent_uid=agent.uid, skill_uid=skill_uid))

    db.commit()
    db.refresh(agent)
    record_audit(
        db,
        user=user,
        action="update",
        resource_type="agent",
        resource_uid=agent.uid,
        summary=f"Agente '{agent.name}' alterado",
        request=request,
    )
    return _agent_out(agent)


@router.delete("/agents/{uid}", response_model=Message)
def delete_agent(
    uid: str,
    user: User = Depends(require("agents:delete")),
    db: Session = Depends(get_db),
):
    agent = db.scalar(select(Agent).where(Agent.uid == uid, Agent.tenant_uid == user.tenant_uid))
    if agent is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Agente nao encontrado.")
    db.delete(agent)
    db.commit()
    return Message(detail="Agente removido.")


# ── Skills ─────────────────────────────────────────────────────────────────────
@router.get("/skills", response_model=list[SkillOut])
def list_skills(
    user: User = Depends(require("skills:read")),
    db: Session = Depends(get_db),
):
    stmt = select(Skill).where(Skill.tenant_uid == user.tenant_uid).order_by(Skill.name)
    return [SkillOut.model_validate(s) for s in db.scalars(stmt).all()]


@router.post("/skills", response_model=SkillOut, status_code=201)
def create_skill(
    payload: SkillIn,
    user: User = Depends(require("skills:write")),
    db: Session = Depends(get_db),
):
    skill = Skill(
        tenant_uid=user.tenant_uid,
        name=payload.name,
        slug=slugify(payload.name),
        description=payload.description,
        instruction=payload.instruction,
        tags_json=payload.tags,
        is_enabled=payload.is_enabled,
        created_by=user.email,
        updated_by=user.email,
    )
    db.add(skill)
    db.commit()
    db.refresh(skill)
    return SkillOut.model_validate(skill)


# ── Ferramentas ────────────────────────────────────────────────────────────────
@router.get("/tools", response_model=list[ToolOut])
def list_tools(
    user: User = Depends(require("tools:read")),
    db: Session = Depends(get_db),
):
    stmt = select(Tool).where(Tool.tenant_uid == user.tenant_uid).order_by(Tool.name)
    return [ToolOut.model_validate(t) for t in db.scalars(stmt).all()]


@router.post("/tools", response_model=ToolOut, status_code=201)
def create_tool(
    payload: ToolIn,
    user: User = Depends(require("tools:write")),
    db: Session = Depends(get_db),
):
    tool = Tool(
        tenant_uid=user.tenant_uid,
        name=payload.name,
        slug=slugify(payload.name),
        kind=payload.kind,
        description=payload.description,
        config_json=payload.config,
        parameters_json=payload.parameters,
        requires_approval=payload.requires_approval,
        is_enabled=payload.is_enabled,
        created_by=user.email,
        updated_by=user.email,
    )
    db.add(tool)
    db.commit()
    db.refresh(tool)
    return ToolOut.model_validate(tool)


# ── Integracoes ────────────────────────────────────────────────────────────────
@router.get("/integrations", response_model=list[IntegrationOut])
def list_integrations(
    user: User = Depends(require("integrations:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(Integration)
        .where(Integration.tenant_uid == user.tenant_uid)
        .order_by(Integration.name)
    )
    return [IntegrationOut.model_validate(i) for i in db.scalars(stmt).all()]


@router.post("/integrations", response_model=IntegrationOut, status_code=201)
def create_integration(
    payload: IntegrationIn,
    user: User = Depends(require("integrations:write")),
    db: Session = Depends(get_db),
):
    integration = Integration(
        tenant_uid=user.tenant_uid,
        name=payload.name,
        slug=slugify(payload.name),
        kind=payload.kind,
        system=payload.system,
        auth_type=payload.auth_type,
        base_url=payload.base_url,
        credential_ref=payload.credential_ref,
        rate_limit_per_min=payload.rate_limit_per_min,
        created_by=user.email,
        updated_by=user.email,
    )
    db.add(integration)
    db.commit()
    db.refresh(integration)
    return IntegrationOut.model_validate(integration)


# ── Conhecimento ───────────────────────────────────────────────────────────────
@router.get("/knowledge", response_model=list[KnowledgeBaseOut])
def list_knowledge_bases(
    user: User = Depends(require("knowledge:read")),
    db: Session = Depends(get_db),
):
    counts = dict(
        db.execute(
            select(KnowledgeDocument.base_uid, func.count(KnowledgeDocument.uid)).group_by(
                KnowledgeDocument.base_uid
            )
        ).all()
    )
    stmt = (
        select(KnowledgeBase)
        .where(KnowledgeBase.tenant_uid == user.tenant_uid)
        .order_by(KnowledgeBase.name)
    )
    result = []
    for base in db.scalars(stmt).all():
        out = KnowledgeBaseOut.model_validate(base)
        out.document_count = counts.get(base.uid, 0)
        result.append(out)
    return result


@router.post("/knowledge", response_model=KnowledgeBaseOut, status_code=201)
def create_knowledge_base(
    payload: KnowledgeBaseIn,
    user: User = Depends(require("knowledge:write")),
    db: Session = Depends(get_db),
):
    base = KnowledgeBase(
        tenant_uid=user.tenant_uid, created_by=user.email, updated_by=user.email,
        **payload.model_dump(),
    )
    db.add(base)
    db.commit()
    db.refresh(base)
    return KnowledgeBaseOut.model_validate(base)


@router.get("/knowledge/{uid}/documents", response_model=list[KnowledgeDocumentOut])
def list_documents(
    uid: str,
    user: User = Depends(require("knowledge:read")),
    db: Session = Depends(get_db),
):
    base = db.scalar(
        select(KnowledgeBase).where(
            KnowledgeBase.uid == uid, KnowledgeBase.tenant_uid == user.tenant_uid
        )
    )
    if base is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Base nao encontrada.")
    return [KnowledgeDocumentOut.model_validate(d) for d in base.documents]


# ── LLM Gateway ────────────────────────────────────────────────────────────────
@router.get("/llm/providers", response_model=list[LLMProviderOut])
def list_providers(
    user: User = Depends(require("llm:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(LLMProvider)
        .options(selectinload(LLMProvider.models))
        .where(LLMProvider.tenant_uid == user.tenant_uid)
        .order_by(LLMProvider.name)
    )
    return [LLMProviderOut.model_validate(p) for p in db.scalars(stmt).all()]


@router.post("/llm/providers", response_model=LLMProviderOut, status_code=201)
def create_provider(
    payload: LLMProviderIn,
    user: User = Depends(require("llm:write")),
    db: Session = Depends(get_db),
):
    provider = LLMProvider(tenant_uid=user.tenant_uid, **payload.model_dump())
    db.add(provider)
    db.commit()
    db.refresh(provider)
    return LLMProviderOut.model_validate(provider)


@router.get("/llm/models", response_model=list[dict])
def list_models(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    rows = db.execute(
        select(LLMModel, LLMProvider)
        .join(LLMProvider, LLMModel.provider_uid == LLMProvider.uid)
        .where(LLMProvider.tenant_uid == user.tenant_uid)
        .order_by(LLMProvider.name, LLMModel.name)
    ).all()
    return [
        {
            "uid": model.uid,
            "code": model.code,
            "name": model.name,
            "provider": provider.name,
            "provider_code": provider.code,
            "input_cost_per_1k": model.input_cost_per_1k,
            "output_cost_per_1k": model.output_cost_per_1k,
            "context_window": model.context_window,
            "is_enabled": model.is_enabled and provider.is_enabled,
        }
        for model, provider in rows
    ]
