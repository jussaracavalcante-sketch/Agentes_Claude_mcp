"""Autenticacao e sessao do console."""

from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, record_audit
from app.core.config import settings
from app.core.security import create_access_token, hash_password, verify_password
from app.db.session import get_db
from app.models import Tenant, User
from app.schemas.auth import CurrentUser, LoginRequest, PasswordChange, TokenResponse
from app.schemas.common import Message

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, request: Request, db: Session = Depends(get_db)):
    stmt = select(User).join(Tenant).where(User.email == payload.email.lower())
    if payload.tenant:
        stmt = stmt.where(Tenant.slug == payload.tenant)
    user = db.scalar(stmt)

    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Credenciais invalidas.")
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Usuario desativado.")

    user.last_login_at = datetime.now(UTC)
    db.commit()
    record_audit(
        db,
        user=user,
        action="login",
        resource_type="user",
        resource_uid=user.uid,
        summary=f"Login de {user.email}",
        request=request,
    )

    token = create_access_token(user.uid, {"tenant": user.tenant_uid, "email": user.email})
    return TokenResponse(
        access_token=token, expires_in=settings.vkb_access_token_ttl_min * 60
    )


@router.get("/me", response_model=CurrentUser)
def me(user: User = Depends(get_current_user)):
    return CurrentUser(
        uid=user.uid,
        email=user.email,
        name=user.name,
        job_title=user.job_title,
        tenant_uid=user.tenant_uid,
        tenant_slug=user.tenant.slug,
        tenant_name=user.tenant.name,
        roles=user.role_codes,
        permissions=sorted(user.permission_codes),
    )


@router.post("/password", response_model=Message)
def change_password(
    payload: PasswordChange,
    request: Request,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not verify_password(payload.current_password, user.password_hash):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Senha atual incorreta.")
    if len(payload.new_password) < 8:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "A nova senha precisa de 8 caracteres.")

    user.password_hash = hash_password(payload.new_password)
    user.must_change_password = False
    db.commit()
    record_audit(
        db,
        user=user,
        action="password_change",
        resource_type="user",
        resource_uid=user.uid,
        summary="Senha alterada pelo proprio usuario",
        request=request,
    )
    return Message(detail="Senha alterada.")
