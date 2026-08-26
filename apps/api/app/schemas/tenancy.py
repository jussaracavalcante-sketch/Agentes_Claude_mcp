from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from app.schemas.common import ORMModel


class UnitOut(ORMModel):
    uid: str
    code: str
    name: str
    cost_center: str | None = None
    monthly_budget_brl: float


class UnitIn(BaseModel):
    code: str
    name: str
    cost_center: str | None = None
    monthly_budget_brl: float = 0.0


class PermissionOut(ORMModel):
    uid: str
    code: str
    resource: str
    action: str
    description: str


class RoleOut(ORMModel):
    uid: str
    code: str
    name: str
    description: str
    is_system: bool
    permissions: list[str] = []


class RoleIn(BaseModel):
    code: str
    name: str
    description: str = ""
    permissions: list[str] = []


class UserOut(ORMModel):
    uid: str
    email: str
    name: str
    job_title: str | None = None
    is_active: bool
    must_change_password: bool
    last_login_at: datetime | None = None
    created_at: datetime
    unit: UnitOut | None = None
    roles: list[str] = []


class UserIn(BaseModel):
    email: EmailStr
    name: str
    job_title: str | None = None
    password: str = Field(min_length=8)
    unit_uid: str | None = None
    roles: list[str] = []


class UserPatch(BaseModel):
    name: str | None = None
    job_title: str | None = None
    is_active: bool | None = None
    unit_uid: str | None = None
    roles: list[str] | None = None


class ApiKeyOut(ORMModel):
    uid: str
    name: str
    prefix: str
    scopes_json: list = []
    is_active: bool
    expires_at: datetime | None = None
    last_used_at: datetime | None = None
    created_at: datetime
    created_by: str | None = None


class ApiKeyCreated(ApiKeyOut):
    secret: str = Field(description="Exibido uma unica vez, no momento da criacao.")


class ApiKeyIn(BaseModel):
    name: str
    scopes: list[str] = []
    expires_at: datetime | None = None


class FeatureFlagOut(ORMModel):
    uid: str
    code: str
    name: str
    description: str
    enabled: bool


class AuditLogOut(ORMModel):
    uid: str
    created_at: datetime
    actor_email: str | None = None
    action: str
    resource_type: str
    resource_uid: str | None = None
    summary: str
    ip_address: str | None = None
    payload_json: dict = {}


class SecurityOverview(BaseModel):
    users_total: int
    users_active: int
    roles_total: int
    api_keys_active: int
    units_total: int
    audit_events_30d: int
