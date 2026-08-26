"""Base declarativa e mixins compartilhados pelos modelos."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import DateTime, String, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


def new_uid() -> str:
    return str(uuid.uuid4())


def utcnow() -> datetime:
    return datetime.now(UTC)


class Base(DeclarativeBase):
    """Base declarativa do dominio VKB."""


class UIDMixin:
    """Chave primaria em UUID textual — portavel entre SQLite e Postgres."""

    uid: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uid)


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), default=utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), default=utcnow, onupdate=utcnow
    )


class AuthorshipMixin:
    """Autoria de criacao e alteracao — exigida pela camada de governanca."""

    created_by: Mapped[str | None] = mapped_column(String(160), nullable=True)
    updated_by: Mapped[str | None] = mapped_column(String(160), nullable=True)
