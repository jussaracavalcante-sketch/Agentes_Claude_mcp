from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel

from app.schemas.common import ORMModel


class CurationItemOut(ORMModel):
    uid: str
    service_uid: str
    service_name: str = ""
    trace_uid: str | None = None
    question: str
    answer: str
    expected_answer: str | None = None
    reason: str
    decision: str
    reviewer_email: str | None = None
    reviewed_at: datetime | None = None
    created_at: datetime


class CurationDecision(BaseModel):
    decision: str
    expected_answer: str | None = None


class EvaluationOut(ORMModel):
    uid: str
    service_uid: str
    service_name: str = ""
    name: str
    description: str
    metric: str
    threshold: float
    is_gate: bool
    case_count: int = 0
    last_score: float | None = None
    last_passed: bool | None = None
    created_at: datetime


class EvaluationIn(BaseModel):
    service_uid: str
    name: str
    description: str = ""
    metric: str = "accuracy"
    threshold: float = 0.8
    is_gate: bool = False


class EvaluationRunOut(ORMModel):
    uid: str
    evaluation_uid: str
    version_uid: str | None = None
    score: float
    passed: bool
    total_cases: int
    passed_cases: int
    created_at: datetime


class PrivacyPolicyOut(ORMModel):
    uid: str
    name: str
    data_category: str
    legal_basis: str
    retention_days: int
    redact_pii: bool
    allow_provider_training: bool
    storage_region: str
    notes: str


class PrivacyPolicyIn(BaseModel):
    name: str
    data_category: str = "dado_pessoal"
    legal_basis: str = "legitimo_interesse"
    retention_days: int = 180
    redact_pii: bool = True
    allow_provider_training: bool = False
    storage_region: str = "br-sao-paulo"
    notes: str = ""


class BudgetRuleOut(ORMModel):
    uid: str
    scope: str
    scope_uid: str | None = None
    scope_label: str = ""
    period: str
    limit_usd: float
    alert_at_percent: int
    hard_stop: bool
    is_enabled: bool
    consumed_usd: float = 0.0


class BudgetRuleIn(BaseModel):
    scope: str = "service"
    scope_uid: str | None = None
    period: str = "monthly"
    limit_usd: float = 100.0
    alert_at_percent: int = 80
    hard_stop: bool = False
