"""Dependencias de request: sessao, identidade, tenant e verificacao de permissao."""

from __future__ import annotations

from collections.abc import Callable
from datetime import UTC, datetime

from fastapi import Depends, Header, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import decode_access_token, hash_api_key
from app.db.session import get_db
from app.models import ApiKey, AuditLog, User

bearer = HTTPBearer(auto_error=False)


def get_current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    x_api_key: str | None = Header(default=None, alias="X-API-Key"),
    db: Session = Depends(get_db),
) -> User:
    """Aceita token de sessao (Bearer) ou chave de API do tenant."""
    if x_api_key:
        key = db.scalar(
            select(ApiKey).where(ApiKey.key_hash == hash_api_key(x_api_key), ApiKey.is_active)
        )
        if key is None:
            raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Chave de API invalida.")
        if key.expires_at and key.expires_at < datetime.now(UTC):
            raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Chave de API expirada.")
        key.last_used_at = datetime.now(UTC)
        db.commit()
        service_user = db.scalar(
            select(User).where(User.tenant_uid == key.tenant_uid, User.is_active).limit(1)
        )
        if service_user is None:
            raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Tenant sem usuario ativo.")
        request.state.auth_kind = "api_key"
        return service_user

    if credentials is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Credencial ausente.")

    payload = decode_access_token(credentials.credentials)
    if payload is None or "sub" not in payload:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token invalido ou expirado.")

    user = db.get(User, payload["sub"])
    if user is None or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Usuario inativo ou inexistente.")

    request.state.auth_kind = "session"
    return user


def get_tenant_uid(user: User = Depends(get_current_user)) -> str:
    return user.tenant_uid


def require(*permissions: str) -> Callable[[User], User]:
    """Guarda de rota. `*` em qualquer papel concede acesso total ao tenant."""

    def guard(user: User = Depends(get_current_user)) -> User:
        granted = user.permission_codes
        if "*" in granted:
            return user
        missing = [p for p in permissions if p not in granted]
        if missing:
            raise HTTPException(
                status.HTTP_403_FORBIDDEN,
                f"Permissao insuficiente. Requer: {', '.join(missing)}.",
            )
        return user

    return guard


def record_audit(
    db: Session,
    *,
    user: User,
    action: str,
    resource_type: str,
    resource_uid: str | None = None,
    summary: str = "",
    payload: dict | None = None,
    request: Request | None = None,
) -> None:
    """Grava a trilha de auditoria. Nunca lanca — auditoria nao bloqueia operacao."""
    try:
        db.add(
            AuditLog(
                tenant_uid=user.tenant_uid,
                actor_email=user.email,
                action=action,
                resource_type=resource_type,
                resource_uid=resource_uid,
                summary=summary,
                ip_address=request.client.host if request and request.client else None,
                payload_json=payload or {},
            )
        )
        db.commit()
    except Exception:  # noqa: BLE001 — auditoria e best-effort
        db.rollback()
