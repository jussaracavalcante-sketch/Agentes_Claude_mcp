"""Ciclo de vida — versoes, implantacoes entre ambientes e portabilidade."""

from __future__ import annotations

import enum
from datetime import datetime

from sqlalchemy import JSON, Boolean, DateTime, Enum, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import AuthorshipMixin, Base, TimestampMixin, UIDMixin


class Environment(str, enum.Enum):
    development = "development"
    staging = "staging"
    production = "production"


class VersionStatus(str, enum.Enum):
    draft = "draft"
    review = "review"
    approved = "approved"
    published = "published"
    rolled_back = "rolled_back"
    terminated = "terminated"


class DeploymentStatus(str, enum.Enum):
    queued = "queued"
    running = "running"
    succeeded = "succeeded"
    failed = "failed"
    rolled_back = "rolled_back"


class ServiceVersion(UIDMixin, TimestampMixin, AuthorshipMixin, Base):
    """Snapshot imutavel do servico. Permite reverter comportamento indevido."""

    __tablename__ = "service_versions"

    service_uid: Mapped[str] = mapped_column(
        ForeignKey("services.uid", ondelete="CASCADE"), index=True
    )
    version: Mapped[str] = mapped_column(String(32), index=True)
    status: Mapped[VersionStatus] = mapped_column(
        Enum(VersionStatus, native_enum=False, length=16), default=VersionStatus.draft
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=False)
    tags_json: Mapped[list] = mapped_column(JSON, default=list)
    changelog: Mapped[str] = mapped_column(Text, default="")
    snapshot_json: Mapped[dict] = mapped_column(JSON, default=dict)
    approved_by: Mapped[str | None] = mapped_column(String(160), nullable=True)
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    service: Mapped[Service] = relationship()  # noqa: F821
    deployments: Mapped[list[Deployment]] = relationship(
        back_populates="version", cascade="all, delete-orphan"
    )


class Deployment(UIDMixin, TimestampMixin, AuthorshipMixin, Base):
    """Publicacao de uma versao em um ambiente."""

    __tablename__ = "deployments"

    version_uid: Mapped[str] = mapped_column(
        ForeignKey("service_versions.uid", ondelete="CASCADE"), index=True
    )
    environment: Mapped[Environment] = mapped_column(
        Enum(Environment, native_enum=False, length=16), index=True
    )
    status: Mapped[DeploymentStatus] = mapped_column(
        Enum(DeploymentStatus, native_enum=False, length=16), default=DeploymentStatus.queued
    )
    requested_by: Mapped[str | None] = mapped_column(String(160), nullable=True)
    approved_by: Mapped[str | None] = mapped_column(String(160), nullable=True)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    rollback_of_uid: Mapped[str | None] = mapped_column(String(36), nullable=True)
    notes: Mapped[str] = mapped_column(Text, default="")

    version: Mapped[ServiceVersion] = relationship(back_populates="deployments")


class PortabilityJob(UIDMixin, TimestampMixin, AuthorshipMixin, Base):
    """Importar / Exportar — garante que agentes e fluxos saiam da plataforma."""

    __tablename__ = "portability_jobs"

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    direction: Mapped[str] = mapped_column(String(16))  # export | import
    scope_json: Mapped[list] = mapped_column(JSON, default=list)
    status: Mapped[str] = mapped_column(String(24), default="queued")
    item_count: Mapped[int] = mapped_column(Integer, default=0)
    artifact_uri: Mapped[str | None] = mapped_column(String(500), nullable=True)
    checksum: Mapped[str | None] = mapped_column(String(96), nullable=True)
    message: Mapped[str] = mapped_column(Text, default="")
