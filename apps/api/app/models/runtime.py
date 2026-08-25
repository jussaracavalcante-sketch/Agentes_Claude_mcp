"""Camada 7 — execucao observavel: conversas, tarefas, traces e spans."""

from __future__ import annotations

import enum
from datetime import datetime

from sqlalchemy import (
    JSON,
    Boolean,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UIDMixin
from app.models.studio import Channel


class ConversationStatus(str, enum.Enum):
    active = "active"
    waiting = "waiting"
    handoff = "handoff"
    closed = "closed"
    failed = "failed"


class TaskStatus(str, enum.Enum):
    queued = "queued"
    running = "running"
    succeeded = "succeeded"
    failed = "failed"
    awaiting_approval = "awaiting_approval"
    cancelled = "cancelled"


class SpanKind(str, enum.Enum):
    chain = "chain"
    model = "model"
    tool = "tool"
    skill = "skill"
    retrieval = "retrieval"
    guardrail = "guardrail"
    handoff = "handoff"


class Conversation(UIDMixin, TimestampMixin, Base):
    __tablename__ = "conversations"

    tenant_uid: Mapped[str] = mapped_column(
        ForeignKey("tenants.uid", ondelete="CASCADE"), index=True
    )
    service_uid: Mapped[str] = mapped_column(
        ForeignKey("services.uid", ondelete="CASCADE"), index=True
    )
    public_id: Mapped[int] = mapped_column(Integer, index=True)
    contact: Mapped[str | None] = mapped_column(String(160), nullable=True)
    channel: Mapped[Channel] = mapped_column(
        Enum(Channel, native_enum=False, length=16), default=Channel.webchat
    )
    status: Mapped[ConversationStatus] = mapped_column(
        Enum(ConversationStatus, native_enum=False, length=16),
        default=ConversationStatus.active,
        index=True,
    )
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_message: Mapped[str] = mapped_column(Text, default="")
    handoff_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    handoff_reason: Mapped[str | None] = mapped_column(String(255), nullable=True)
    intent: Mapped[str | None] = mapped_column(String(120), nullable=True, index=True)
    csat: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_recurrent: Mapped[bool] = mapped_column(Boolean, default=False)
    tokens_total: Mapped[int] = mapped_column(Integer, default=0)
    cost_usd: Mapped[float] = mapped_column(Float, default=0.0)

    service: Mapped[Service] = relationship()  # noqa: F821
    messages: Mapped[list[Message]] = relationship(
        back_populates="conversation", cascade="all, delete-orphan", order_by="Message.sent_at"
    )


class Message(UIDMixin, Base):
    __tablename__ = "messages"

    conversation_uid: Mapped[str] = mapped_column(
        ForeignKey("conversations.uid", ondelete="CASCADE"), index=True
    )
    role: Mapped[str] = mapped_column(String(16))  # user | assistant | system | agent
    author: Mapped[str | None] = mapped_column(String(120), nullable=True)
    content: Mapped[str] = mapped_column(Text, default="")
    sent_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    tokens: Mapped[int] = mapped_column(Integer, default=0)

    conversation: Mapped[Conversation] = relationship(back_populates="messages")


class TaskRun(UIDMixin, TimestampMixin, Base):
    """Execucao autonoma de um servico de tarefa (back-office)."""

    __tablename__ = "task_runs"

    tenant_uid: Mapped[str] = mapped_column(
        ForeignKey("tenants.uid", ondelete="CASCADE"), index=True
    )
    service_uid: Mapped[str] = mapped_column(
        ForeignKey("services.uid", ondelete="CASCADE"), index=True
    )
    public_id: Mapped[int] = mapped_column(Integer, index=True)
    trigger: Mapped[str] = mapped_column(String(48), default="schedule")
    status: Mapped[TaskStatus] = mapped_column(
        Enum(TaskStatus, native_enum=False, length=24), default=TaskStatus.queued, index=True
    )
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    duration_ms: Mapped[int] = mapped_column(Integer, default=0)
    input_json: Mapped[dict] = mapped_column(JSON, default=dict)
    output_json: Mapped[dict] = mapped_column(JSON, default=dict)
    error: Mapped[str | None] = mapped_column(Text, nullable=True)
    steps_total: Mapped[int] = mapped_column(Integer, default=0)
    steps_done: Mapped[int] = mapped_column(Integer, default=0)
    requires_human: Mapped[bool] = mapped_column(Boolean, default=False)
    tokens_total: Mapped[int] = mapped_column(Integer, default=0)
    cost_usd: Mapped[float] = mapped_column(Float, default=0.0)

    service: Mapped[Service] = relationship()  # noqa: F821


class Trace(UIDMixin, TimestampMixin, Base):
    """Arvore de execucao de um chat ou task, com tokens e custo por span."""

    __tablename__ = "traces"

    tenant_uid: Mapped[str] = mapped_column(
        ForeignKey("tenants.uid", ondelete="CASCADE"), index=True
    )
    service_uid: Mapped[str] = mapped_column(
        ForeignKey("services.uid", ondelete="CASCADE"), index=True
    )
    origin: Mapped[str] = mapped_column(String(16), default="chat")  # chat | task
    conversation_uid: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    task_run_uid: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    reference_label: Mapped[str] = mapped_column(String(64), default="")
    provider: Mapped[str | None] = mapped_column(String(64), nullable=True)
    model: Mapped[str | None] = mapped_column(String(96), nullable=True)
    status: Mapped[str] = mapped_column(String(16), default="ok", index=True)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    duration_ms: Mapped[int] = mapped_column(Integer, default=0)
    tokens_in: Mapped[int] = mapped_column(Integer, default=0)
    tokens_out: Mapped[int] = mapped_column(Integer, default=0)
    tokens_reasoning: Mapped[int] = mapped_column(Integer, default=0)
    cost_usd: Mapped[float] = mapped_column(Float, default=0.0)

    service: Mapped[Service] = relationship()  # noqa: F821
    spans: Mapped[list[Span]] = relationship(
        back_populates="trace", cascade="all, delete-orphan", order_by="Span.position"
    )


class Span(UIDMixin, Base):
    __tablename__ = "spans"

    trace_uid: Mapped[str] = mapped_column(ForeignKey("traces.uid", ondelete="CASCADE"), index=True)
    parent_uid: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    name: Mapped[str] = mapped_column(String(160))
    kind: Mapped[SpanKind] = mapped_column(Enum(SpanKind, native_enum=False, length=16))
    status: Mapped[str] = mapped_column(String(16), default="success")
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    duration_ms: Mapped[int] = mapped_column(Integer, default=0)
    position: Mapped[int] = mapped_column(Integer, default=0)
    depth: Mapped[int] = mapped_column(Integer, default=0)
    tokens_in: Mapped[int] = mapped_column(Integer, default=0)
    tokens_out: Mapped[int] = mapped_column(Integer, default=0)
    cost_usd: Mapped[float] = mapped_column(Float, default=0.0)
    model: Mapped[str | None] = mapped_column(String(96), nullable=True)
    input_json: Mapped[dict] = mapped_column(JSON, default=dict)
    output_json: Mapped[dict] = mapped_column(JSON, default=dict)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)
    error: Mapped[str | None] = mapped_column(Text, nullable=True)

    trace: Mapped[Trace] = relationship(back_populates="spans")
