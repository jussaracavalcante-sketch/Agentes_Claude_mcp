"""Analytics e FinOps — indicadores por servico, consumo de LLM e custo."""

from __future__ import annotations

from collections import defaultdict
from datetime import timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy import desc, func, select
from sqlalchemy.orm import Session

from app.api.deps import require
from app.api.v1.routers.observability import PERIODS, period_start
from app.db.dialect import day_expr
from app.db.session import get_db
from app.models import Conversation, Service, ServiceStatus, TaskRun, Trace, User
from app.schemas.runtime import (
    LLMConsumption,
    NamedSeries,
    SeriesPoint,
    ServiceAnalytics,
)

router = APIRouter(prefix="/analytics", tags=["analytics"])

TOP_SERIES = 5


def _day_labels(period: str) -> list[str]:
    days = PERIODS.get(period.upper(), 7)
    start = period_start(period)
    return [(start + timedelta(days=i)).strftime("%d/%m") for i in range(days + 1)]


def _daily_series(rows, labels: list[str], limit: int = TOP_SERIES) -> list[NamedSeries]:
    """rows: (nome_do_servico, dia_iso, contagem)."""
    grouped: dict[str, dict[str, float]] = defaultdict(dict)
    totals: dict[str, float] = defaultdict(float)
    for name, day, count in rows:
        label = day[8:10] + "/" + day[5:7] if isinstance(day, str) else day.strftime("%d/%m")
        grouped[name][label] = grouped[name].get(label, 0) + count
        totals[name] += count

    top = sorted(totals, key=totals.get, reverse=True)[:limit]
    return [
        NamedSeries(
            name=name,
            points=[SeriesPoint(label=lb, value=grouped[name].get(lb, 0)) for lb in labels],
        )
        for name in top
    ]


@router.get("/services", response_model=ServiceAnalytics)
def service_analytics(
    period: str = Query("7D", pattern="^(1D|7D|30D|90D)$"),
    user: User = Depends(require("analytics:read")),
    db: Session = Depends(get_db),
):
    since = period_start(period)
    tenant = user.tenant_uid
    labels = _day_labels(period)
    day = day_expr(Conversation.started_at)
    task_day = day_expr(TaskRun.started_at)

    total_conversations = db.scalar(
        select(func.count(Conversation.uid)).where(
            Conversation.tenant_uid == tenant, Conversation.started_at >= since
        )
    ) or 0
    total_tasks = db.scalar(
        select(func.count(TaskRun.uid)).where(
            TaskRun.tenant_uid == tenant, TaskRun.started_at >= since
        )
    ) or 0
    active_services = db.scalar(
        select(func.count(Service.uid)).where(
            Service.tenant_uid == tenant, Service.status == ServiceStatus.active
        )
    ) or 0

    ranking_conv = db.execute(
        select(Service.name, func.count(Conversation.uid))
        .join(Conversation, Conversation.service_uid == Service.uid)
        .where(Conversation.tenant_uid == tenant, Conversation.started_at >= since)
        .group_by(Service.name)
        .order_by(desc(func.count(Conversation.uid)))
        .limit(10)
    ).all()
    ranking_task = db.execute(
        select(Service.name, func.count(TaskRun.uid))
        .join(TaskRun, TaskRun.service_uid == Service.uid)
        .where(TaskRun.tenant_uid == tenant, TaskRun.started_at >= since)
        .group_by(Service.name)
        .order_by(desc(func.count(TaskRun.uid)))
        .limit(10)
    ).all()

    conv_daily = db.execute(
        select(Service.name, day, func.count(Conversation.uid))
        .join(Conversation, Conversation.service_uid == Service.uid)
        .where(Conversation.tenant_uid == tenant, Conversation.started_at >= since)
        .group_by(Service.name, day)
    ).all()
    task_daily = db.execute(
        select(Service.name, task_day, func.count(TaskRun.uid))
        .join(TaskRun, TaskRun.service_uid == Service.uid)
        .where(TaskRun.tenant_uid == tenant, TaskRun.started_at >= since)
        .group_by(Service.name, task_day)
    ).all()

    return ServiceAnalytics(
        period=period,
        total_conversations=total_conversations,
        total_tasks=total_tasks,
        active_services=active_services,
        ranking_conversations=[SeriesPoint(label=n, value=c) for n, c in ranking_conv],
        ranking_tasks=[SeriesPoint(label=n, value=c) for n, c in ranking_task],
        conversations_per_day=_daily_series(conv_daily, labels),
        tasks_per_day=_daily_series(task_daily, labels),
    )


@router.get("/llm", response_model=LLMConsumption)
def llm_consumption(
    period: str = Query("30D", pattern="^(1D|7D|30D|90D)$"),
    user: User = Depends(require("analytics:read")),
    db: Session = Depends(get_db),
):
    since = period_start(period)
    tenant = user.tenant_uid
    base = (Trace.tenant_uid == tenant, Trace.started_at >= since)

    tokens_in = db.scalar(select(func.coalesce(func.sum(Trace.tokens_in), 0)).where(*base)) or 0
    tokens_out = db.scalar(select(func.coalesce(func.sum(Trace.tokens_out), 0)).where(*base)) or 0
    cost = db.scalar(select(func.coalesce(func.sum(Trace.cost_usd), 0.0)).where(*base)) or 0.0

    by_model = db.execute(
        select(Trace.model, func.coalesce(func.sum(Trace.cost_usd), 0.0))
        .where(*base, Trace.model.is_not(None))
        .group_by(Trace.model)
        .order_by(desc(func.sum(Trace.cost_usd)))
    ).all()
    by_provider = db.execute(
        select(Trace.provider, func.coalesce(func.sum(Trace.cost_usd), 0.0))
        .where(*base, Trace.provider.is_not(None))
        .group_by(Trace.provider)
        .order_by(desc(func.sum(Trace.cost_usd)))
    ).all()
    by_service = db.execute(
        select(Service.name, func.coalesce(func.sum(Trace.cost_usd), 0.0))
        .join(Trace, Trace.service_uid == Service.uid)
        .where(*base)
        .group_by(Service.name)
        .order_by(desc(func.sum(Trace.cost_usd)))
        .limit(10)
    ).all()

    day = day_expr(Trace.started_at)
    per_day = db.execute(
        select(day, func.coalesce(func.sum(Trace.cost_usd), 0.0))
        .where(*base)
        .group_by(day)
        .order_by(day)
    ).all()

    return LLMConsumption(
        period=period,
        tokens_in=int(tokens_in),
        tokens_out=int(tokens_out),
        cost_usd=round(float(cost), 4),
        by_model=[SeriesPoint(label=m, value=round(float(c), 4)) for m, c in by_model],
        by_provider=[SeriesPoint(label=p, value=round(float(c), 4)) for p, c in by_provider],
        by_service=[SeriesPoint(label=n, value=round(float(c), 4)) for n, c in by_service],
        cost_per_day=[
            SeriesPoint(label=d[8:10] + "/" + d[5:7], value=round(float(c), 4)) for d, c in per_day
        ],
    )
