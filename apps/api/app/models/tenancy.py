"""Camada 6 — Governanca e seguranca: tenant, identidade, papeis, auditoria."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import JSON, Boolean, DateTime, ForeignKey, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import AuthorshipMixin, Base, TimestampMixin, UIDMixin

# Vinculos N:N declarados como tabelas de associacao com uid proprio, para que
# a trilha de auditoria consiga referenciar a concessao individual.


class Tenant(UIDMixin, TimestampMixin, Base):
    __tablename__ = "tenants"

    slug: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(160))
    document: Mapped[str | None] = mapped_column(String(32), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    settings_json: Mapped[dict] = mapped_column(JSON, default=dict)

    users: Mapped[list[User]] = relationship(back_populates="tenant", cascade="all, delete-orphan")
    units: Mapped[list[Unit]] = relationship(back_populates="tenant", cascade="all, delete-orphan")


class Unit(UIDMixin, TimestampMixin, Base):
    """Unidade organizacional — centro de custo para o FinOps."""

    __tablename__ = "units"
    __table_args__ = (UniqueConstraint("tenant_uid", "code", name="uq_unit_tenant_code"),)

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    code: Mapped[str] = mapped_column(String(48))
    name: Mapped[str] = mapped_column(String(160))
    cost_center: Mapped[str | None] = mapped_column(String(64), nullable=True)
    monthly_budget_brl: Mapped[float] = mapped_column(default=0.0)

    tenant: Mapped[Tenant] = relationship(back_populates="units")


class Permission(UIDMixin, Base):
    """Permissao atomica no formato recurso:acao (ex.: services:publish)."""

    __tablename__ = "permissions"

    code: Mapped[str] = mapped_column(String(96), unique=True, index=True)
    resource: Mapped[str] = mapped_column(String(48))
    action: Mapped[str] = mapped_column(String(32))
    description: Mapped[str] = mapped_column(String(255), default="")


class Role(UIDMixin, TimestampMixin, Base):
    __tablename__ = "roles"
    __table_args__ = (UniqueConstraint("tenant_uid", "code", name="uq_role_tenant_code"),)

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    code: Mapped[str] = mapped_column(String(48))
    name: Mapped[str] = mapped_column(String(120))
    description: Mapped[str] = mapped_column(String(255), default="")
    is_system: Mapped[bool] = mapped_column(Boolean, default=False)

    permissions: Mapped[list[RolePermission]] = relationship(
        back_populates="role", cascade="all, delete-orphan"
    )


class RolePermission(UIDMixin, Base):
    __tablename__ = "role_permissions"
    __table_args__ = (UniqueConstraint("role_uid", "permission_uid", name="uq_role_permission"),)

    role_uid: Mapped[str] = mapped_column(ForeignKey("roles.uid", ondelete="CASCADE"))
    permission_uid: Mapped[str] = mapped_column(ForeignKey("permissions.uid", ondelete="CASCADE"))

    role: Mapped[Role] = relationship(back_populates="permissions")
    permission: Mapped[Permission] = relationship()


class User(UIDMixin, TimestampMixin, Base):
    __tablename__ = "users"
    __table_args__ = (UniqueConstraint("tenant_uid", "email", name="uq_user_tenant_email"),)

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    unit_uid: Mapped[str | None] = mapped_column(
        ForeignKey("units.uid", ondelete="SET NULL"), nullable=True
    )
    email: Mapped[str] = mapped_column(String(160), index=True)
    name: Mapped[str] = mapped_column(String(160))
    job_title: Mapped[str | None] = mapped_column(String(120), nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    must_change_password: Mapped[bool] = mapped_column(Boolean, default=False)
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    tenant: Mapped[Tenant] = relationship(back_populates="users")
    unit: Mapped[Unit | None] = relationship()
    roles: Mapped[list[UserRole]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )

    @property
    def role_codes(self) -> list[str]:
        return [ur.role.code for ur in self.roles if ur.role is not None]

    @property
    def permission_codes(self) -> set[str]:
        codes: set[str] = set()
        for ur in self.roles:
            if ur.role is None:
                continue
            codes.update(rp.permission.code for rp in ur.role.permissions if rp.permission)
        return codes


class UserRole(UIDMixin, TimestampMixin, Base):
    __tablename__ = "user_roles"
    __table_args__ = (UniqueConstraint("user_uid", "role_uid", name="uq_user_role"),)

    user_uid: Mapped[str] = mapped_column(ForeignKey("users.uid", ondelete="CASCADE"))
    role_uid: Mapped[str] = mapped_column(ForeignKey("roles.uid", ondelete="CASCADE"))
    granted_by: Mapped[str | None] = mapped_column(String(160), nullable=True)

    user: Mapped[User] = relationship(back_populates="roles")
    role: Mapped[Role] = relationship()


class ApiKey(UIDMixin, TimestampMixin, AuthorshipMixin, Base):
    """Chave de API do tenant. Somente o hash e persistido."""

    __tablename__ = "api_keys"

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(120))
    prefix: Mapped[str] = mapped_column(String(16), index=True)
    key_hash: Mapped[str] = mapped_column(String(128), unique=True)
    scopes_json: Mapped[list] = mapped_column(JSON, default=list)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class FeatureFlag(UIDMixin, TimestampMixin, Base):
    """Funcionalidades habilitadas por tenant."""

    __tablename__ = "feature_flags"
    __table_args__ = (UniqueConstraint("tenant_uid", "code", name="uq_flag_tenant_code"),)

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    code: Mapped[str] = mapped_column(String(64))
    name: Mapped[str] = mapped_column(String(160))
    description: Mapped[str] = mapped_column(String(255), default="")
    enabled: Mapped[bool] = mapped_column(Boolean, default=False)


class AuditLog(UIDMixin, TimestampMixin, Base):
    """Trilha de auditoria — append-only, exportavel."""

    __tablename__ = "audit_logs"

    tenant_uid: Mapped[str] = mapped_column(
        ForeignKey("tenants.uid", ondelete="CASCADE"), index=True
    )
    actor_email: Mapped[str | None] = mapped_column(String(160), nullable=True, index=True)
    action: Mapped[str] = mapped_column(String(64), index=True)
    resource_type: Mapped[str] = mapped_column(String(48), index=True)
    resource_uid: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    summary: Mapped[str] = mapped_column(Text, default="")
    ip_address: Mapped[str | None] = mapped_column(String(64), nullable=True)
    payload_json: Mapped[dict] = mapped_column(JSON, default=dict)
