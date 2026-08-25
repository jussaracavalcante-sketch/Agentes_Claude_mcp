"""Ciclo de vida — versionamento, implantacao entre ambientes, rollback e
portabilidade (importar / exportar)."""

from __future__ import annotations

import hashlib
import json
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.api.deps import record_audit, require
from app.core.text import next_version
from app.db.session import get_db
from app.models import (
    Agent,
    Deployment,
    DeploymentStatus,
    Environment,
    PortabilityJob,
    Service,
    ServiceAgent,
    ServiceStatus,
    ServiceVersion,
    Skill,
    Tool,
    User,
    VersionStatus,
)
from app.schemas.common import Message
from app.schemas.lifecycle import (
    DeploymentIn,
    DeploymentOut,
    ExportRequest,
    PortabilityJobOut,
    VersionDetail,
    VersionIn,
    VersionOut,
)

router = APIRouter(tags=["ciclo-de-vida"])


def _snapshot(service: Service) -> dict:
    """Snapshot completo do servico — base do rollback e da portabilidade."""
    return {
        "service": {
            "name": service.name,
            "slug": service.slug,
            "type": service.type.value if hasattr(service.type, "value") else service.type,
            "description": service.description,
            "instruction": service.instruction,
            "objectives": service.objectives_json,
            "channels": service.channels_json,
            "handoff_enabled": service.handoff_enabled,
            "data_classification": service.data_classification,
            "config": service.config_json,
        },
        "agents": [
            {
                "agent_uid": sa.agent_uid,
                "name": sa.agent.name if sa.agent else None,
                "role": sa.agent.role if sa.agent else None,
                "instruction": sa.agent.instruction if sa.agent else None,
                "model_uid": sa.agent.model_uid if sa.agent else None,
                "temperature": sa.agent.temperature if sa.agent else None,
                "autonomy": (
                    sa.agent.autonomy.value
                    if sa.agent and hasattr(sa.agent.autonomy, "value")
                    else (sa.agent.autonomy if sa.agent else None)
                ),
                "is_supervisor": sa.is_supervisor,
                "position": sa.position,
            }
            for sa in service.agents
        ],
        "stages": [
            {
                "code": st.code,
                "name": st.name,
                "instruction": st.instruction,
                "exit_condition": st.exit_condition,
                "position": st.position,
            }
            for st in service.stages
        ],
    }


def _version_out(version: ServiceVersion, service_name: str) -> VersionOut:
    out = VersionOut.model_validate(version)
    out.service_name = service_name
    return out


def _load_service(db: Session, tenant_uid: str, uid: str) -> Service:
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


# ── Versoes ────────────────────────────────────────────────────────────────────
@router.get("/versions", response_model=list[VersionOut])
def list_versions(
    service_uid: str | None = None,
    status_filter: str | None = Query(None, alias="status"),
    q: str | None = None,
    user: User = Depends(require("lifecycle:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(ServiceVersion, Service.name)
        .join(Service, ServiceVersion.service_uid == Service.uid)
        .where(Service.tenant_uid == user.tenant_uid)
    )
    if service_uid:
        stmt = stmt.where(ServiceVersion.service_uid == service_uid)
    if status_filter:
        stmt = stmt.where(ServiceVersion.status == status_filter)
    if q:
        stmt = stmt.where(ServiceVersion.version.ilike(f"%{q}%") | Service.name.ilike(f"%{q}%"))

    rows = db.execute(stmt.order_by(ServiceVersion.created_at.desc())).all()
    return [_version_out(v, name) for v, name in rows]


@router.post("/services/{service_uid}/versions", response_model=VersionDetail, status_code=201)
def create_version(
    service_uid: str,
    payload: VersionIn,
    request: Request,
    user: User = Depends(require("lifecycle:write")),
    db: Session = Depends(get_db),
):
    """Salvar versao — congela o rascunho atual do servico."""
    service = _load_service(db, user.tenant_uid, service_uid)
    latest = db.scalar(
        select(ServiceVersion)
        .where(ServiceVersion.service_uid == service.uid)
        .order_by(ServiceVersion.created_at.desc())
    )
    version_label = payload.version or next_version(latest.version if latest else None)

    exists = db.scalar(
        select(func.count(ServiceVersion.uid)).where(
            ServiceVersion.service_uid == service.uid, ServiceVersion.version == version_label
        )
    )
    if exists:
        raise HTTPException(status.HTTP_409_CONFLICT, f"Versao {version_label} ja existe.")

    version = ServiceVersion(
        service_uid=service.uid,
        version=version_label,
        status=VersionStatus.draft,
        tags_json=payload.tags,
        changelog=payload.changelog,
        snapshot_json=_snapshot(service),
        created_by=user.email,
        updated_by=user.email,
    )
    db.add(version)
    service.has_draft = False
    db.commit()
    db.refresh(version)
    record_audit(
        db,
        user=user,
        action="version_create",
        resource_type="service_version",
        resource_uid=version.uid,
        summary=f"Versao {version_label} de '{service.name}' salva",
        request=request,
    )

    detail = VersionDetail.model_validate(version)
    detail.service_name = service.name
    return detail


@router.get("/versions/{uid}", response_model=VersionDetail)
def get_version(
    uid: str,
    user: User = Depends(require("lifecycle:read")),
    db: Session = Depends(get_db),
):
    row = db.execute(
        select(ServiceVersion, Service.name)
        .join(Service, ServiceVersion.service_uid == Service.uid)
        .options(selectinload(ServiceVersion.deployments))
        .where(ServiceVersion.uid == uid, Service.tenant_uid == user.tenant_uid)
    ).first()
    if row is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Versao nao encontrada.")
    version, service_name = row
    detail = VersionDetail.model_validate(version)
    detail.service_name = service_name
    detail.deployments = [DeploymentOut.model_validate(d) for d in version.deployments]
    return detail


@router.post("/versions/{uid}/approve", response_model=VersionOut)
def approve_version(
    uid: str,
    request: Request,
    user: User = Depends(require("lifecycle:approve")),
    db: Session = Depends(get_db),
):
    version, service = _version_with_service(db, user.tenant_uid, uid)
    if version.created_by == user.email:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Segregacao de funcoes: quem cria a versao nao pode aprova-la.",
        )
    version.status = VersionStatus.approved
    version.approved_by = user.email
    version.approved_at = datetime.now(UTC)
    db.commit()
    db.refresh(version)
    record_audit(
        db,
        user=user,
        action="version_approve",
        resource_type="service_version",
        resource_uid=version.uid,
        summary=f"Versao {version.version} de '{service.name}' aprovada",
        request=request,
    )
    return _version_out(version, service.name)


def _version_with_service(db: Session, tenant_uid: str, uid: str):
    row = db.execute(
        select(ServiceVersion, Service)
        .join(Service, ServiceVersion.service_uid == Service.uid)
        .where(ServiceVersion.uid == uid, Service.tenant_uid == tenant_uid)
    ).first()
    if row is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Versao nao encontrada.")
    return row


# ── Implantacoes ───────────────────────────────────────────────────────────────
@router.get("/deployments", response_model=list[DeploymentOut])
def list_deployments(
    environment: str | None = None,
    user: User = Depends(require("lifecycle:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(Deployment)
        .join(ServiceVersion, Deployment.version_uid == ServiceVersion.uid)
        .join(Service, ServiceVersion.service_uid == Service.uid)
        .where(Service.tenant_uid == user.tenant_uid)
    )
    if environment:
        stmt = stmt.where(Deployment.environment == environment)
    rows = db.scalars(stmt.order_by(Deployment.created_at.desc())).all()
    return [DeploymentOut.model_validate(d) for d in rows]


@router.post("/versions/{uid}/deploy", response_model=DeploymentOut, status_code=201)
def deploy_version(
    uid: str,
    payload: DeploymentIn,
    request: Request,
    user: User = Depends(require("lifecycle:deploy")),
    db: Session = Depends(get_db),
):
    version, service = _version_with_service(db, user.tenant_uid, uid)
    try:
        environment = Environment(payload.environment)
    except ValueError as exc:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Ambiente invalido.") from exc

    if environment is Environment.production and version.status != VersionStatus.approved:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Producao exige versao aprovada. Aprove a versao antes de publicar.",
        )

    now = datetime.now(UTC)
    deployment = Deployment(
        version_uid=version.uid,
        environment=environment,
        status=DeploymentStatus.succeeded,
        requested_by=user.email,
        approved_by=version.approved_by,
        started_at=now,
        finished_at=now,
        notes=payload.notes,
        created_by=user.email,
    )
    db.add(deployment)

    if environment is Environment.production:
        db.execute(
            ServiceVersion.__table__.update()
            .where(ServiceVersion.service_uid == service.uid)
            .values(is_active=False)
        )
        version.is_active = True
        version.status = VersionStatus.published
        service.active_version = version.version
        service.status = ServiceStatus.active

    db.commit()
    db.refresh(deployment)
    record_audit(
        db,
        user=user,
        action="deploy",
        resource_type="deployment",
        resource_uid=deployment.uid,
        summary=f"Versao {version.version} de '{service.name}' publicada em {environment.value}",
        request=request,
    )
    return DeploymentOut.model_validate(deployment)


@router.post("/versions/{uid}/rollback", response_model=DeploymentOut, status_code=201)
def rollback_to_version(
    uid: str,
    request: Request,
    user: User = Depends(require("lifecycle:deploy")),
    db: Session = Depends(get_db),
):
    """Retorna a producao para uma versao anterior — sem recriar rascunho."""
    version, service = _version_with_service(db, user.tenant_uid, uid)
    current = db.scalar(
        select(ServiceVersion).where(
            ServiceVersion.service_uid == service.uid, ServiceVersion.is_active.is_(True)
        )
    )
    if current and current.uid == version.uid:
        raise HTTPException(status.HTTP_409_CONFLICT, "Esta versao ja esta ativa em producao.")

    now = datetime.now(UTC)
    deployment = Deployment(
        version_uid=version.uid,
        environment=Environment.production,
        status=DeploymentStatus.rolled_back,
        requested_by=user.email,
        started_at=now,
        finished_at=now,
        rollback_of_uid=current.uid if current else None,
        notes=f"Rollback a partir de {current.version if current else 'sem versao ativa'}",
        created_by=user.email,
    )
    db.add(deployment)

    if current:
        current.is_active = False
        current.status = VersionStatus.rolled_back
    version.is_active = True
    version.status = VersionStatus.published
    service.active_version = version.version

    db.commit()
    db.refresh(deployment)
    record_audit(
        db,
        user=user,
        action="rollback",
        resource_type="deployment",
        resource_uid=deployment.uid,
        summary=f"'{service.name}' revertido para {version.version}",
        request=request,
    )
    return DeploymentOut.model_validate(deployment)


# ── Portabilidade ──────────────────────────────────────────────────────────────
@router.get("/portability", response_model=list[PortabilityJobOut])
def list_portability_jobs(
    user: User = Depends(require("lifecycle:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(PortabilityJob)
        .where(PortabilityJob.tenant_uid == user.tenant_uid)
        .order_by(PortabilityJob.created_at.desc())
    )
    return [PortabilityJobOut.model_validate(j) for j in db.scalars(stmt).all()]


@router.post("/portability/export", response_model=dict, status_code=201)
def export_assets(
    payload: ExportRequest,
    request: Request,
    user: User = Depends(require("lifecycle:export")),
    db: Session = Depends(get_db),
):
    """Exporta agentes, servicos e integracoes em JSON aberto.

    A portabilidade e requisito do relatorio (secao 9.1): ativos estrategicos
    nao podem ficar presos a formato proprietario.
    """
    tenant = user.tenant_uid
    bundle: dict = {"tenant": tenant, "exported_at": datetime.now(UTC).isoformat()}

    if "services" in payload.scope:
        stmt = (
            select(Service)
            .options(
                selectinload(Service.agents).selectinload(ServiceAgent.agent),
                selectinload(Service.stages),
            )
            .where(Service.tenant_uid == tenant)
        )
        if payload.service_uids:
            stmt = stmt.where(Service.uid.in_(payload.service_uids))
        bundle["services"] = [_snapshot(s) for s in db.scalars(stmt).all()]

    if "agents" in payload.scope:
        bundle["agents"] = [
            {
                "name": a.name,
                "role": a.role,
                "instruction": a.instruction,
                "temperature": a.temperature,
                "max_tokens": a.max_tokens,
                "autonomy": a.autonomy.value if hasattr(a.autonomy, "value") else a.autonomy,
                "owner_email": a.owner_email,
            }
            for a in db.scalars(select(Agent).where(Agent.tenant_uid == tenant)).all()
        ]

    if "skills" in payload.scope:
        bundle["skills"] = [
            {"name": s.name, "description": s.description, "instruction": s.instruction}
            for s in db.scalars(select(Skill).where(Skill.tenant_uid == tenant)).all()
        ]

    if "tools" in payload.scope:
        bundle["tools"] = [
            {"name": t.name, "kind": t.kind, "parameters": t.parameters_json}
            for t in db.scalars(select(Tool).where(Tool.tenant_uid == tenant)).all()
        ]

    raw = json.dumps(bundle, ensure_ascii=False, sort_keys=True).encode()
    checksum = hashlib.sha256(raw).hexdigest()
    item_count = sum(len(v) for v in bundle.values() if isinstance(v, list))

    job = PortabilityJob(
        tenant_uid=tenant,
        direction="export",
        scope_json=payload.scope,
        status="succeeded",
        item_count=item_count,
        checksum=checksum,
        message=f"{item_count} ativos exportados",
        created_by=user.email,
    )
    db.add(job)
    db.commit()
    record_audit(
        db,
        user=user,
        action="export",
        resource_type="portability_job",
        resource_uid=job.uid,
        summary=f"Exportacao de {item_count} ativos ({', '.join(payload.scope)})",
        request=request,
    )
    return {"job_uid": job.uid, "checksum": checksum, "item_count": item_count, "bundle": bundle}


@router.delete("/versions/{uid}", response_model=Message)
def terminate_version(
    uid: str,
    user: User = Depends(require("lifecycle:write")),
    db: Session = Depends(get_db),
):
    version, _service = _version_with_service(db, user.tenant_uid, uid)
    if version.is_active:
        raise HTTPException(
            status.HTTP_409_CONFLICT, "Versao ativa em producao nao pode ser encerrada."
        )
    version.status = VersionStatus.terminated
    db.commit()
    return Message(detail="Versao encerrada.")
