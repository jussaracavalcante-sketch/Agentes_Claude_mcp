"""Observabilidade — monitoramento, conversas, tarefas e traces."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import desc, func, select
from sqlalchemy.orm import Session, selectinload

from app.api.deps import require
from app.db.session import get_db
from app.models import (
    Conversation,
    ConversationStatus,
    Service,
    ServiceStatus,
    ServiceType,
    Span,
    TaskRun,
    TaskStatus,
    Trace,
    User,
)
from app.schemas.common import Page
from app.schemas.runtime import (
    ConversationDetail,
    ConversationOut,
    HomeOverview,
    MessageOut,
    MonitoringOverview,
    SeriesPoint,
    SpanOut,
    TaskRunDetail,
    TaskRunOut,
    TraceDetail,
    TraceOut,
)

router = APIRouter(tags=["observabilidade"])

PERIODS = {"1D": 1, "7D": 7, "30D": 30, "90D": 90}


def period_start(period: str) -> datetime:
    days = PERIODS.get(period.upper(), 1)
    return datetime.now(UTC) - timedelta(days=days)


def _conversation_out(conv: Conversation, trace_uid: str | None = None) -> ConversationOut:
    out = ConversationOut.model_validate(conv)
    out.service_name = conv.service.name if conv.service else ""
    out.trace_uid = trace_uid
    return out


def _task_out(task: TaskRun, trace_uid: str | None = None) -> TaskRunOut:
    out = TaskRunOut.model_validate(task)
    out.service_name = task.service.name if task.service else ""
    out.trace_uid = trace_uid
    return out


def _trace_uids_for(db: Session, column, uids: list[str]) -> dict[str, str]:
    if not uids:
        return {}
    rows = db.execute(select(column, Trace.uid).where(column.in_(uids))).all()
    return {ref: trace_uid for ref, trace_uid in rows if ref}


# ── Home ───────────────────────────────────────────────────────────────────────
@router.get("/home/overview", response_model=HomeOverview)
def home_overview(
    user: User = Depends(require("observability:read")),
    db: Session = Depends(get_db),
):
    def count_services(service_type: ServiceType) -> int:
        return db.scalar(
            select(func.count(Service.uid)).where(
                Service.tenant_uid == user.tenant_uid,
                Service.type == service_type,
                Service.status == ServiceStatus.active,
            )
        ) or 0

    today = datetime.now(UTC).replace(hour=0, minute=0, second=0, microsecond=0)
    conversations_today = db.scalar(
        select(func.count(Conversation.uid)).where(
            Conversation.tenant_uid == user.tenant_uid, Conversation.started_at >= today
        )
    ) or 0
    tasks_today = db.scalar(
        select(func.count(TaskRun.uid)).where(
            TaskRun.tenant_uid == user.tenant_uid, TaskRun.started_at >= today
        )
    ) or 0
    incidents = db.scalar(
        select(func.count(TaskRun.uid)).where(
            TaskRun.tenant_uid == user.tenant_uid, TaskRun.status == TaskStatus.failed
        )
    ) or 0

    return HomeOverview(
        greeting_date=datetime.now(UTC),
        conversation_services=count_services(ServiceType.conversation),
        task_services=count_services(ServiceType.task),
        copilot_services=count_services(ServiceType.copilot),
        conversations_today=conversations_today,
        tasks_today=tasks_today,
        open_incidents=incidents,
    )


# ── Monitoramento ──────────────────────────────────────────────────────────────
@router.get("/monitoring", response_model=MonitoringOverview)
def monitoring(
    period: str = Query("1D", pattern="^(1D|7D|30D|90D)$"),
    user: User = Depends(require("observability:read")),
    db: Session = Depends(get_db),
):
    since = period_start(period)
    tenant = user.tenant_uid

    conversations = db.scalar(
        select(func.count(Conversation.uid)).where(
            Conversation.tenant_uid == tenant, Conversation.started_at >= since
        )
    ) or 0
    live_chats = db.scalar(
        select(func.count(Conversation.uid)).where(
            Conversation.tenant_uid == tenant,
            Conversation.status.in_([ConversationStatus.active, ConversationStatus.waiting]),
        )
    ) or 0
    tasks = db.scalar(
        select(func.count(TaskRun.uid)).where(
            TaskRun.tenant_uid == tenant, TaskRun.started_at >= since
        )
    ) or 0
    traces = db.scalar(
        select(func.count(Trace.uid)).where(
            Trace.tenant_uid == tenant, Trace.started_at >= since
        )
    ) or 0

    by_service = db.execute(
        select(Service.name, func.count(Conversation.uid))
        .join(Conversation, Conversation.service_uid == Service.uid)
        .where(Conversation.tenant_uid == tenant, Conversation.started_at >= since)
        .group_by(Service.name)
        .order_by(desc(func.count(Conversation.uid)))
        .limit(10)
    ).all()

    recent_convs = db.scalars(
        select(Conversation)
        .options(selectinload(Conversation.service))
        .where(Conversation.tenant_uid == tenant, Conversation.started_at >= since)
        .order_by(Conversation.started_at.desc())
        .limit(8)
    ).all()
    recent_tasks = db.scalars(
        select(TaskRun)
        .options(selectinload(TaskRun.service))
        .where(TaskRun.tenant_uid == tenant, TaskRun.started_at >= since)
        .order_by(TaskRun.started_at.desc())
        .limit(8)
    ).all()

    conv_traces = _trace_uids_for(db, Trace.conversation_uid, [c.uid for c in recent_convs])
    task_traces = _trace_uids_for(db, Trace.task_run_uid, [t.uid for t in recent_tasks])

    return MonitoringOverview(
        period=period,
        conversations=conversations,
        live_chats=live_chats,
        tasks=tasks,
        traces=traces,
        conversations_by_service=[SeriesPoint(label=n, value=c) for n, c in by_service],
        recent_conversations=[_conversation_out(c, conv_traces.get(c.uid)) for c in recent_convs],
        recent_tasks=[_task_out(t, task_traces.get(t.uid)) for t in recent_tasks],
    )


# ── Conversas ──────────────────────────────────────────────────────────────────
@router.get("/conversations", response_model=Page[ConversationOut])
def list_conversations(
    q: str | None = None,
    service_uid: str | None = None,
    channel: str | None = None,
    status_filter: str | None = Query(None, alias="status"),
    only_recurrent: bool = False,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=200),
    user: User = Depends(require("observability:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(Conversation)
        .options(selectinload(Conversation.service))
        .where(Conversation.tenant_uid == user.tenant_uid)
    )
    if q:
        stmt = stmt.where(Conversation.last_message.ilike(f"%{q}%"))
    if service_uid:
        stmt = stmt.where(Conversation.service_uid == service_uid)
    if channel:
        stmt = stmt.where(Conversation.channel == channel)
    if status_filter:
        stmt = stmt.where(Conversation.status == status_filter)
    if only_recurrent:
        stmt = stmt.where(Conversation.is_recurrent.is_(True))
    if date_from:
        stmt = stmt.where(Conversation.started_at >= date_from)
    if date_to:
        stmt = stmt.where(Conversation.started_at <= date_to)

    total = db.scalar(select(func.count()).select_from(stmt.subquery())) or 0
    rows = db.scalars(
        stmt.order_by(Conversation.started_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()
    trace_map = _trace_uids_for(db, Trace.conversation_uid, [c.uid for c in rows])

    return Page[ConversationOut](
        items=[_conversation_out(c, trace_map.get(c.uid)) for c in rows],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/conversations/{uid}", response_model=ConversationDetail)
def get_conversation(
    uid: str,
    user: User = Depends(require("observability:read")),
    db: Session = Depends(get_db),
):
    conv = db.scalar(
        select(Conversation)
        .options(selectinload(Conversation.service), selectinload(Conversation.messages))
        .where(Conversation.uid == uid, Conversation.tenant_uid == user.tenant_uid)
    )
    if conv is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Conversa nao encontrada.")

    trace_uid = db.scalar(select(Trace.uid).where(Trace.conversation_uid == conv.uid))
    detail = ConversationDetail.model_validate(conv)
    detail.service_name = conv.service.name if conv.service else ""
    detail.trace_uid = trace_uid
    detail.messages = [MessageOut.model_validate(m) for m in conv.messages]
    return detail


# ── Tarefas ────────────────────────────────────────────────────────────────────
@router.get("/tasks", response_model=Page[TaskRunOut])
def list_tasks(
    service_uid: str | None = None,
    status_filter: str | None = Query(None, alias="status"),
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=200),
    user: User = Depends(require("observability:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(TaskRun)
        .options(selectinload(TaskRun.service))
        .where(TaskRun.tenant_uid == user.tenant_uid)
    )
    if service_uid:
        stmt = stmt.where(TaskRun.service_uid == service_uid)
    if status_filter:
        stmt = stmt.where(TaskRun.status == status_filter)

    total = db.scalar(select(func.count()).select_from(stmt.subquery())) or 0
    rows = db.scalars(
        stmt.order_by(TaskRun.started_at.desc()).offset((page - 1) * page_size).limit(page_size)
    ).all()
    trace_map = _trace_uids_for(db, Trace.task_run_uid, [t.uid for t in rows])

    return Page[TaskRunOut](
        items=[_task_out(t, trace_map.get(t.uid)) for t in rows],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/tasks/{uid}", response_model=TaskRunDetail)
def get_task(
    uid: str,
    user: User = Depends(require("observability:read")),
    db: Session = Depends(get_db),
):
    task = db.scalar(
        select(TaskRun)
        .options(selectinload(TaskRun.service))
        .where(TaskRun.uid == uid, TaskRun.tenant_uid == user.tenant_uid)
    )
    if task is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Tarefa nao encontrada.")
    detail = TaskRunDetail.model_validate(task)
    detail.service_name = task.service.name if task.service else ""
    detail.trace_uid = db.scalar(select(Trace.uid).where(Trace.task_run_uid == task.uid))
    return detail


# ── Traces ─────────────────────────────────────────────────────────────────────
def _trace_out(trace: Trace, span_count: int) -> TraceOut:
    out = TraceOut.model_validate(trace)
    out.service_name = trace.service.name if trace.service else ""
    out.span_count = span_count
    return out


@router.get("/traces", response_model=Page[TraceOut])
def list_traces(
    q: str | None = Query(None, description="Trace UID, Chat ID ou Task ID"),
    service_uid: str | None = None,
    origin: str | None = None,
    status_filter: str | None = Query(None, alias="status"),
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=200),
    user: User = Depends(require("observability:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(Trace)
        .options(selectinload(Trace.service))
        .where(Trace.tenant_uid == user.tenant_uid)
    )
    if q:
        like = f"%{q}%"
        stmt = stmt.where(
            Trace.uid.ilike(like)
            | Trace.reference_label.ilike(like)
            | Trace.model.ilike(like)
        )
    if service_uid:
        stmt = stmt.where(Trace.service_uid == service_uid)
    if origin:
        stmt = stmt.where(Trace.origin == origin)
    if status_filter:
        stmt = stmt.where(Trace.status == status_filter)

    total = db.scalar(select(func.count()).select_from(stmt.subquery())) or 0
    rows = db.scalars(
        stmt.order_by(Trace.started_at.desc()).offset((page - 1) * page_size).limit(page_size)
    ).all()
    counts = dict(
        db.execute(
            select(Span.trace_uid, func.count(Span.uid))
            .where(Span.trace_uid.in_([t.uid for t in rows] or [""]))
            .group_by(Span.trace_uid)
        ).all()
    )

    return Page[TraceOut](
        items=[_trace_out(t, counts.get(t.uid, 0)) for t in rows],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/traces/{uid}", response_model=TraceDetail)
def get_trace(
    uid: str,
    user: User = Depends(require("observability:read")),
    db: Session = Depends(get_db),
):
    trace = db.scalar(
        select(Trace)
        .options(selectinload(Trace.service), selectinload(Trace.spans))
        .where(Trace.uid == uid, Trace.tenant_uid == user.tenant_uid)
    )
    if trace is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Trace nao encontrado.")

    detail = TraceDetail.model_validate(trace)
    detail.service_name = trace.service.name if trace.service else ""
    detail.spans = [SpanOut.model_validate(s) for s in trace.spans]
    detail.span_count = len(detail.spans)
    return detail
