"""Seguranca — usuarios, papeis, permissoes, unidades, chaves e auditoria."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.api.deps import get_current_user, record_audit, require
from app.core.security import generate_api_key, hash_password
from app.db.session import get_db
from app.models import (
    ApiKey,
    AuditLog,
    FeatureFlag,
    Permission,
    Role,
    RolePermission,
    Unit,
    User,
    UserRole,
)
from app.schemas.common import Message, Page
from app.schemas.tenancy import (
    ApiKeyCreated,
    ApiKeyIn,
    ApiKeyOut,
    AuditLogOut,
    FeatureFlagOut,
    PermissionOut,
    RoleIn,
    RoleOut,
    SecurityOverview,
    UnitIn,
    UnitOut,
    UserIn,
    UserOut,
    UserPatch,
)

router = APIRouter(prefix="/security", tags=["seguranca"])


def _user_out(user: User) -> UserOut:
    """Montado campo a campo: `roles` no ORM sao vinculos, no schema sao codigos."""
    return UserOut(
        uid=user.uid,
        email=user.email,
        name=user.name,
        job_title=user.job_title,
        is_active=user.is_active,
        must_change_password=user.must_change_password,
        last_login_at=user.last_login_at,
        created_at=user.created_at,
        unit=UnitOut.model_validate(user.unit) if user.unit else None,
        roles=user.role_codes,
    )


def _role_out(role: Role) -> RoleOut:
    return RoleOut(
        uid=role.uid,
        code=role.code,
        name=role.name,
        description=role.description,
        is_system=role.is_system,
        permissions=sorted(rp.permission.code for rp in role.permissions if rp.permission),
    )


@router.get("/overview", response_model=SecurityOverview)
def overview(
    user: User = Depends(require("security:read")),
    db: Session = Depends(get_db),
):
    tenant = user.tenant_uid
    since = datetime.now(UTC) - timedelta(days=30)
    return SecurityOverview(
        users_total=db.scalar(
            select(func.count(User.uid)).where(User.tenant_uid == tenant)
        ) or 0,
        users_active=db.scalar(
            select(func.count(User.uid)).where(User.tenant_uid == tenant, User.is_active)
        ) or 0,
        roles_total=db.scalar(
            select(func.count(Role.uid)).where(Role.tenant_uid == tenant)
        ) or 0,
        api_keys_active=db.scalar(
            select(func.count(ApiKey.uid)).where(ApiKey.tenant_uid == tenant, ApiKey.is_active)
        ) or 0,
        units_total=db.scalar(
            select(func.count(Unit.uid)).where(Unit.tenant_uid == tenant)
        ) or 0,
        audit_events_30d=db.scalar(
            select(func.count(AuditLog.uid)).where(
                AuditLog.tenant_uid == tenant, AuditLog.created_at >= since
            )
        ) or 0,
    )


# ── Usuarios ───────────────────────────────────────────────────────────────────
@router.get("/users", response_model=list[UserOut])
def list_users(
    q: str | None = None,
    user: User = Depends(require("security:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(User)
        .options(selectinload(User.roles).selectinload(UserRole.role), selectinload(User.unit))
        .where(User.tenant_uid == user.tenant_uid)
    )
    if q:
        stmt = stmt.where(User.name.ilike(f"%{q}%") | User.email.ilike(f"%{q}%"))
    return [_user_out(u) for u in db.scalars(stmt.order_by(User.name)).all()]


@router.post("/users", response_model=UserOut, status_code=201)
def create_user(
    payload: UserIn,
    request: Request,
    user: User = Depends(require("security:write")),
    db: Session = Depends(get_db),
):
    email = payload.email.lower()
    exists = db.scalar(
        select(User).where(User.tenant_uid == user.tenant_uid, User.email == email)
    )
    if exists:
        raise HTTPException(status.HTTP_409_CONFLICT, "E-mail ja cadastrado no tenant.")

    created = User(
        tenant_uid=user.tenant_uid,
        email=email,
        name=payload.name,
        job_title=payload.job_title,
        password_hash=hash_password(payload.password),
        unit_uid=payload.unit_uid,
        must_change_password=True,
    )
    db.add(created)
    db.flush()
    _assign_roles(db, created, payload.roles)
    db.commit()
    db.refresh(created)
    record_audit(
        db,
        user=user,
        action="create",
        resource_type="user",
        resource_uid=created.uid,
        summary=f"Usuario {created.email} criado",
        payload={"roles": payload.roles},
        request=request,
    )
    return _user_out(created)


def _assign_roles(db: Session, target: User, role_codes: list[str]) -> None:
    for link in list(target.roles):
        db.delete(link)
    db.flush()
    if not role_codes:
        return
    roles = db.scalars(
        select(Role).where(Role.tenant_uid == target.tenant_uid, Role.code.in_(role_codes))
    ).all()
    found = {r.code for r in roles}
    missing = set(role_codes) - found
    if missing:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            f"Papeis inexistentes: {', '.join(sorted(missing))}.",
        )
    for role in roles:
        db.add(UserRole(user_uid=target.uid, role_uid=role.uid))


@router.patch("/users/{uid}", response_model=UserOut)
def update_user(
    uid: str,
    payload: UserPatch,
    request: Request,
    user: User = Depends(require("security:write")),
    db: Session = Depends(get_db),
):
    target = db.scalar(select(User).where(User.uid == uid, User.tenant_uid == user.tenant_uid))
    if target is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Usuario nao encontrado.")

    data = payload.model_dump(exclude_unset=True)
    roles = data.pop("roles", None)
    for field, value in data.items():
        if value is not None:
            setattr(target, field, value)
    if roles is not None:
        _assign_roles(db, target, roles)

    db.commit()
    db.refresh(target)
    record_audit(
        db,
        user=user,
        action="update",
        resource_type="user",
        resource_uid=target.uid,
        summary=f"Usuario {target.email} alterado",
        request=request,
    )
    return _user_out(target)


@router.post("/users/{uid}/reset-password", response_model=Message)
def reset_password(
    uid: str,
    request: Request,
    user: User = Depends(require("security:write")),
    db: Session = Depends(get_db),
):
    target = db.scalar(select(User).where(User.uid == uid, User.tenant_uid == user.tenant_uid))
    if target is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Usuario nao encontrado.")
    temporary = generate_api_key()[0][:16]
    target.password_hash = hash_password(temporary)
    target.must_change_password = True
    db.commit()
    record_audit(
        db,
        user=user,
        action="password_reset",
        resource_type="user",
        resource_uid=target.uid,
        summary=f"Senha de {target.email} redefinida por administrador",
        request=request,
    )
    return Message(detail=f"Senha temporaria: {temporary}")


# ── Papeis e permissoes ────────────────────────────────────────────────────────
@router.get("/roles", response_model=list[RoleOut])
def list_roles(
    user: User = Depends(require("security:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(Role)
        .options(selectinload(Role.permissions).selectinload(RolePermission.permission))
        .where(Role.tenant_uid == user.tenant_uid)
        .order_by(Role.name)
    )
    return [_role_out(r) for r in db.scalars(stmt).all()]


@router.post("/roles", response_model=RoleOut, status_code=201)
def create_role(
    payload: RoleIn,
    request: Request,
    user: User = Depends(require("security:write")),
    db: Session = Depends(get_db),
):
    role = Role(
        tenant_uid=user.tenant_uid,
        code=payload.code,
        name=payload.name,
        description=payload.description,
    )
    db.add(role)
    db.flush()
    _set_role_permissions(db, role, payload.permissions)
    db.commit()
    db.refresh(role)
    record_audit(
        db,
        user=user,
        action="create",
        resource_type="role",
        resource_uid=role.uid,
        summary=f"Papel '{role.name}' criado",
        request=request,
    )
    return _role_out(role)


def _set_role_permissions(db: Session, role: Role, codes: list[str]) -> None:
    for link in list(role.permissions):
        db.delete(link)
    db.flush()
    if not codes:
        return
    permissions = db.scalars(select(Permission).where(Permission.code.in_(codes))).all()
    for permission in permissions:
        db.add(RolePermission(role_uid=role.uid, permission_uid=permission.uid))


@router.put("/roles/{uid}", response_model=RoleOut)
def update_role(
    uid: str,
    payload: RoleIn,
    user: User = Depends(require("security:write")),
    db: Session = Depends(get_db),
):
    role = db.scalar(select(Role).where(Role.uid == uid, Role.tenant_uid == user.tenant_uid))
    if role is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Papel nao encontrado.")
    if role.is_system:
        raise HTTPException(status.HTTP_409_CONFLICT, "Papel de sistema nao e editavel.")
    role.name = payload.name
    role.description = payload.description
    _set_role_permissions(db, role, payload.permissions)
    db.commit()
    db.refresh(role)
    return _role_out(role)


@router.get("/permissions", response_model=list[PermissionOut])
def list_permissions(
    _: User = Depends(require("security:read")),
    db: Session = Depends(get_db),
):
    stmt = select(Permission).order_by(Permission.resource, Permission.action)
    return [PermissionOut.model_validate(p) for p in db.scalars(stmt).all()]


# ── Unidades ───────────────────────────────────────────────────────────────────
@router.get("/units", response_model=list[UnitOut])
def list_units(
    user: User = Depends(require("security:read")),
    db: Session = Depends(get_db),
):
    stmt = select(Unit).where(Unit.tenant_uid == user.tenant_uid).order_by(Unit.name)
    return [UnitOut.model_validate(u) for u in db.scalars(stmt).all()]


@router.post("/units", response_model=UnitOut, status_code=201)
def create_unit(
    payload: UnitIn,
    user: User = Depends(require("security:write")),
    db: Session = Depends(get_db),
):
    unit = Unit(tenant_uid=user.tenant_uid, **payload.model_dump())
    db.add(unit)
    db.commit()
    db.refresh(unit)
    return UnitOut.model_validate(unit)


# ── Chaves de API ──────────────────────────────────────────────────────────────
@router.get("/api-keys", response_model=list[ApiKeyOut])
def list_api_keys(
    user: User = Depends(require("security:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(ApiKey)
        .where(ApiKey.tenant_uid == user.tenant_uid)
        .order_by(ApiKey.created_at.desc())
    )
    return [ApiKeyOut.model_validate(k) for k in db.scalars(stmt).all()]


@router.post("/api-keys", response_model=ApiKeyCreated, status_code=201)
def create_api_key(
    payload: ApiKeyIn,
    request: Request,
    user: User = Depends(require("security:write")),
    db: Session = Depends(get_db),
):
    raw, prefix, key_hash = generate_api_key()
    key = ApiKey(
        tenant_uid=user.tenant_uid,
        name=payload.name,
        prefix=prefix,
        key_hash=key_hash,
        scopes_json=payload.scopes,
        expires_at=payload.expires_at,
        created_by=user.email,
    )
    db.add(key)
    db.commit()
    db.refresh(key)
    record_audit(
        db,
        user=user,
        action="create",
        resource_type="api_key",
        resource_uid=key.uid,
        summary=f"Chave de API '{key.name}' emitida ({prefix}…)",
        request=request,
    )
    out = ApiKeyCreated.model_validate(key)
    out.secret = raw
    return out


@router.delete("/api-keys/{uid}", response_model=Message)
def revoke_api_key(
    uid: str,
    request: Request,
    user: User = Depends(require("security:write")),
    db: Session = Depends(get_db),
):
    key = db.scalar(select(ApiKey).where(ApiKey.uid == uid, ApiKey.tenant_uid == user.tenant_uid))
    if key is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Chave nao encontrada.")
    key.is_active = False
    db.commit()
    record_audit(
        db,
        user=user,
        action="revoke",
        resource_type="api_key",
        resource_uid=key.uid,
        summary=f"Chave de API '{key.name}' revogada",
        request=request,
    )
    return Message(detail="Chave revogada.")


# ── Funcionalidades ────────────────────────────────────────────────────────────
@router.get("/feature-flags", response_model=list[FeatureFlagOut])
def list_flags(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    stmt = (
        select(FeatureFlag)
        .where(FeatureFlag.tenant_uid == user.tenant_uid)
        .order_by(FeatureFlag.name)
    )
    return [FeatureFlagOut.model_validate(f) for f in db.scalars(stmt).all()]


@router.patch("/feature-flags/{uid}", response_model=FeatureFlagOut)
def toggle_flag(
    uid: str,
    enabled: bool,
    user: User = Depends(require("security:write")),
    db: Session = Depends(get_db),
):
    flag = db.scalar(
        select(FeatureFlag).where(
            FeatureFlag.uid == uid, FeatureFlag.tenant_uid == user.tenant_uid
        )
    )
    if flag is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Funcionalidade nao encontrada.")
    flag.enabled = enabled
    db.commit()
    db.refresh(flag)
    return FeatureFlagOut.model_validate(flag)


# ── Auditoria ──────────────────────────────────────────────────────────────────
@router.get("/audit-logs", response_model=Page[AuditLogOut])
def list_audit_logs(
    action: str | None = None,
    resource_type: str | None = None,
    actor: str | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    user: User = Depends(require("audit:read")),
    db: Session = Depends(get_db),
):
    stmt = select(AuditLog).where(AuditLog.tenant_uid == user.tenant_uid)
    if action:
        stmt = stmt.where(AuditLog.action == action)
    if resource_type:
        stmt = stmt.where(AuditLog.resource_type == resource_type)
    if actor:
        stmt = stmt.where(AuditLog.actor_email.ilike(f"%{actor}%"))

    total = db.scalar(select(func.count()).select_from(stmt.subquery())) or 0
    rows = db.scalars(
        stmt.order_by(AuditLog.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    ).all()
    return Page[AuditLogOut](
        items=[AuditLogOut.model_validate(r) for r in rows],
        total=total,
        page=page,
        page_size=page_size,
    )
