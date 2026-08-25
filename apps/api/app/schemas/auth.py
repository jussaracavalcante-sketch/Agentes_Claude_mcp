from __future__ import annotations

from pydantic import BaseModel, EmailStr

from app.schemas.common import ORMModel


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    tenant: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class CurrentUser(ORMModel):
    uid: str
    email: str
    name: str
    job_title: str | None = None
    tenant_uid: str
    tenant_slug: str
    tenant_name: str
    roles: list[str] = []
    permissions: list[str] = []


class PasswordChange(BaseModel):
    current_password: str
    new_password: str
