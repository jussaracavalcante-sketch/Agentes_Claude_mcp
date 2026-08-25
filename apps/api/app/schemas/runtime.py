from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel

from app.schemas.common import ORMModel


class MessageOut(ORMModel):
    uid: str
    role: str
    author: str | None = None
    content: str
    sent_at: datetime
    tokens: int


class ConversationOut(ORMModel):
    uid: str
    public_id: int
    service_uid: str
    service_name: str = ""
    contact: str | None = None
    channel: str
    status: str
    started_at: datetime
    ended_at: datetime | None = None
    last_message: str
    handoff_at: datetime | None = None
    intent: str | None = None
    csat: int | None = None
    is_recurrent: bool
    tokens_total: int
    cost_usd: float
    trace_uid: str | None = None


class ConversationDetail(ConversationOut):
    handoff_reason: str | None = None
    messages: list[MessageOut] = []


class TaskRunOut(ORMModel):
    uid: str
    public_id: int
    service_uid: str
    service_name: str = ""
    trigger: str
    status: str
    started_at: datetime
    finished_at: datetime | None = None
    duration_ms: int
    steps_total: int
    steps_done: int
    requires_human: bool
    error: str | None = None
    tokens_total: int
    cost_usd: float
    trace_uid: str | None = None


class TaskRunDetail(TaskRunOut):
    input_json: dict = {}
    output_json: dict = {}


class SpanOut(ORMModel):
    uid: str
    parent_uid: str | None = None
    name: str
    kind: str
    status: str
    started_at: datetime
    duration_ms: int
    position: int
    depth: int
    tokens_in: int
    tokens_out: int
    cost_usd: float
    model: str | None = None
    input_json: dict = {}
    output_json: dict = {}
    metadata_json: dict = {}
    error: str | None = None


class TraceOut(ORMModel):
    uid: str
    service_uid: str
    service_name: str = ""
    origin: str
    reference_label: str
    provider: str | None = None
    model: str | None = None
    status: str
    started_at: datetime
    duration_ms: int
    tokens_in: int
    tokens_out: int
    tokens_reasoning: int
    cost_usd: float
    span_count: int = 0


class TraceDetail(TraceOut):
    conversation_uid: str | None = None
    task_run_uid: str | None = None
    spans: list[SpanOut] = []


# ── Observabilidade / analytics ────────────────────────────────────────────────
class KpiCard(BaseModel):
    key: str
    label: str
    value: float
    hint: str | None = None


class SeriesPoint(BaseModel):
    label: str
    value: float


class NamedSeries(BaseModel):
    name: str
    points: list[SeriesPoint]


class MonitoringOverview(BaseModel):
    period: str
    conversations: int
    live_chats: int
    tasks: int
    traces: int
    conversations_by_service: list[SeriesPoint]
    recent_conversations: list[ConversationOut]
    recent_tasks: list[TaskRunOut]


class HomeOverview(BaseModel):
    greeting_date: datetime
    conversation_services: int
    task_services: int
    copilot_services: int
    conversations_today: int
    tasks_today: int
    open_incidents: int


class ServiceAnalytics(BaseModel):
    period: str
    total_conversations: int
    total_tasks: int
    active_services: int
    ranking_conversations: list[SeriesPoint]
    ranking_tasks: list[SeriesPoint]
    conversations_per_day: list[NamedSeries]
    tasks_per_day: list[NamedSeries]


class LLMConsumption(BaseModel):
    period: str
    tokens_in: int
    tokens_out: int
    cost_usd: float
    by_model: list[SeriesPoint]
    by_provider: list[SeriesPoint]
    by_service: list[SeriesPoint]
    cost_per_day: list[SeriesPoint]
