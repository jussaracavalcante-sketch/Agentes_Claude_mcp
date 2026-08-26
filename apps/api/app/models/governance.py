"""Governanca aplicada: curadoria, avaliacoes, privacidade e orcamento FinOps."""

from __future__ import annotations

import enum
from datetime import datetime

from sqlalchemy import JSON, Boolean, DateTime, Enum, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import AuthorshipMixin, Base, TimestampMixin, UIDMixin


class ReviewDecision(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
    needs_revision = "needs_revision"


class CurationItem(UIDMixin, TimestampMixin, Base):
    """Fila de curadoria — resposta marcada para revisao humana."""

    __tablename__ = "curation_items"

    tenant_uid: Mapped[str] = mapped_column(
        ForeignKey("tenants.uid", ondelete="CASCADE"), index=True
    )
    service_uid: Mapped[str] = mapped_column(ForeignKey("services.uid", ondelete="CASCADE"))
    trace_uid: Mapped[str | None] = mapped_column(String(36), nullable=True)
    question: Mapped[str] = mapped_column(Text, default="")
    answer: Mapped[str] = mapped_column(Text, default="")
    expected_answer: Mapped[str | None] = mapped_column(Text, nullable=True)
    reason: Mapped[str] = mapped_column(String(160), default="")
    decision: Mapped[ReviewDecision] = mapped_column(
        Enum(ReviewDecision, native_enum=False, length=20), default=ReviewDecision.pending
    )
    reviewer_email: Mapped[str | None] = mapped_column(String(160), nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class Evaluation(UIDMixin, TimestampMixin, AuthorshipMixin, Base):
    """Suite de testes automatizados de um servico."""

    __tablename__ = "evaluations"

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    service_uid: Mapped[str] = mapped_column(ForeignKey("services.uid", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(160))
    description: Mapped[str] = mapped_column(Text, default="")
    metric: Mapped[str] = mapped_column(String(48), default="accuracy")
    threshold: Mapped[float] = mapped_column(Float, default=0.8)
    is_gate: Mapped[bool] = mapped_column(Boolean, default=False)

    cases: Mapped[list[EvaluationCase]] = relationship(
        back_populates="evaluation", cascade="all, delete-orphan"
    )
    runs: Mapped[list[EvaluationRun]] = relationship(
        back_populates="evaluation", cascade="all, delete-orphan"
    )


class EvaluationCase(UIDMixin, Base):
    __tablename__ = "evaluation_cases"

    evaluation_uid: Mapped[str] = mapped_column(
        ForeignKey("evaluations.uid", ondelete="CASCADE")
    )
    input_text: Mapped[str] = mapped_column(Text, default="")
    expected: Mapped[str] = mapped_column(Text, default="")
    tags_json: Mapped[list] = mapped_column(JSON, default=list)

    evaluation: Mapped[Evaluation] = relationship(back_populates="cases")


class EvaluationRun(UIDMixin, TimestampMixin, Base):
    __tablename__ = "evaluation_runs"

    evaluation_uid: Mapped[str] = mapped_column(
        ForeignKey("evaluations.uid", ondelete="CASCADE"), index=True
    )
    version_uid: Mapped[str | None] = mapped_column(String(36), nullable=True)
    score: Mapped[float] = mapped_column(Float, default=0.0)
    passed: Mapped[bool] = mapped_column(Boolean, default=False)
    total_cases: Mapped[int] = mapped_column(Integer, default=0)
    passed_cases: Mapped[int] = mapped_column(Integer, default=0)
    report_json: Mapped[dict] = mapped_column(JSON, default=dict)

    evaluation: Mapped[Evaluation] = relationship(back_populates="runs")


class PrivacyPolicy(UIDMixin, TimestampMixin, AuthorshipMixin, Base):
    """Politica de retencao e tratamento de dado pessoal (LGPD)."""

    __tablename__ = "privacy_policies"

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(160))
    data_category: Mapped[str] = mapped_column(String(64), default="dado_pessoal")
    legal_basis: Mapped[str] = mapped_column(String(96), default="legitimo_interesse")
    retention_days: Mapped[int] = mapped_column(Integer, default=180)
    redact_pii: Mapped[bool] = mapped_column(Boolean, default=True)
    allow_provider_training: Mapped[bool] = mapped_column(Boolean, default=False)
    storage_region: Mapped[str] = mapped_column(String(48), default="br-sao-paulo")
    notes: Mapped[str] = mapped_column(Text, default="")


class BudgetRule(UIDMixin, TimestampMixin, Base):
    """Limite de consumo FinOps por unidade, servico ou usuario."""

    __tablename__ = "budget_rules"

    tenant_uid: Mapped[str] = mapped_column(ForeignKey("tenants.uid", ondelete="CASCADE"))
    scope: Mapped[str] = mapped_column(String(24), default="service")  # unit | service | user
    scope_uid: Mapped[str | None] = mapped_column(String(36), nullable=True)
    period: Mapped[str] = mapped_column(String(16), default="monthly")
    limit_usd: Mapped[float] = mapped_column(Float, default=100.0)
    alert_at_percent: Mapped[int] = mapped_column(Integer, default=80)
    hard_stop: Mapped[bool] = mapped_column(Boolean, default=False)
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
