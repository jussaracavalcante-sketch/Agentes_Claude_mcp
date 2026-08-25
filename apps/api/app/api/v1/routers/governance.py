"""Curadoria, avaliacoes, privacidade (LGPD) e orcamento FinOps."""

from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.deps import record_audit, require
from app.db.session import get_db
from app.models import (
    BudgetRule,
    CurationItem,
    Evaluation,
    EvaluationCase,
    EvaluationRun,
    PrivacyPolicy,
    ReviewDecision,
    Service,
    Trace,
    Unit,
    User,
)
from app.schemas.common import Message
from app.schemas.governance import (
    BudgetRuleIn,
    BudgetRuleOut,
    CurationDecision,
    CurationItemOut,
    EvaluationIn,
    EvaluationOut,
    EvaluationRunOut,
    PrivacyPolicyIn,
    PrivacyPolicyOut,
)

router = APIRouter(tags=["governanca"])


# ── Curadoria ──────────────────────────────────────────────────────────────────
@router.get("/curation", response_model=list[CurationItemOut])
def list_curation(
    decision: str | None = Query(None),
    user: User = Depends(require("curation:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(CurationItem, Service.name)
        .join(Service, CurationItem.service_uid == Service.uid)
        .where(CurationItem.tenant_uid == user.tenant_uid)
    )
    if decision:
        stmt = stmt.where(CurationItem.decision == decision)

    result = []
    for item, service_name in db.execute(stmt.order_by(CurationItem.created_at.desc())).all():
        out = CurationItemOut.model_validate(item)
        out.service_name = service_name
        result.append(out)
    return result


@router.post("/curation/{uid}/decide", response_model=CurationItemOut)
def decide_curation(
    uid: str,
    payload: CurationDecision,
    request: Request,
    user: User = Depends(require("curation:write")),
    db: Session = Depends(get_db),
):
    item = db.scalar(
        select(CurationItem).where(
            CurationItem.uid == uid, CurationItem.tenant_uid == user.tenant_uid
        )
    )
    if item is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Item nao encontrado.")
    try:
        item.decision = ReviewDecision(payload.decision)
    except ValueError as exc:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Decisao invalida.") from exc

    item.expected_answer = payload.expected_answer or item.expected_answer
    item.reviewer_email = user.email
    item.reviewed_at = datetime.now(UTC)
    db.commit()
    db.refresh(item)
    record_audit(
        db,
        user=user,
        action="curation_decide",
        resource_type="curation_item",
        resource_uid=item.uid,
        summary=f"Curadoria: {payload.decision}",
        request=request,
    )
    out = CurationItemOut.model_validate(item)
    out.service_name = item.service_uid
    return out


# ── Evaluations ────────────────────────────────────────────────────────────────
@router.get("/evaluations", response_model=list[EvaluationOut])
def list_evaluations(
    user: User = Depends(require("evaluations:read")),
    db: Session = Depends(get_db),
):
    rows = db.execute(
        select(Evaluation, Service.name)
        .join(Service, Evaluation.service_uid == Service.uid)
        .where(Evaluation.tenant_uid == user.tenant_uid)
        .order_by(Evaluation.name)
    ).all()

    case_counts = dict(
        db.execute(
            select(EvaluationCase.evaluation_uid, func.count(EvaluationCase.uid)).group_by(
                EvaluationCase.evaluation_uid
            )
        ).all()
    )

    result = []
    for evaluation, service_name in rows:
        out = EvaluationOut.model_validate(evaluation)
        out.service_name = service_name
        out.case_count = case_counts.get(evaluation.uid, 0)
        last = db.scalar(
            select(EvaluationRun)
            .where(EvaluationRun.evaluation_uid == evaluation.uid)
            .order_by(EvaluationRun.created_at.desc())
        )
        if last:
            out.last_score = last.score
            out.last_passed = last.passed
        result.append(out)
    return result


@router.post("/evaluations", response_model=EvaluationOut, status_code=201)
def create_evaluation(
    payload: EvaluationIn,
    user: User = Depends(require("evaluations:write")),
    db: Session = Depends(get_db),
):
    evaluation = Evaluation(
        tenant_uid=user.tenant_uid, created_by=user.email, updated_by=user.email,
        **payload.model_dump(),
    )
    db.add(evaluation)
    db.commit()
    db.refresh(evaluation)
    return EvaluationOut.model_validate(evaluation)


@router.get("/evaluations/{uid}/runs", response_model=list[EvaluationRunOut])
def list_evaluation_runs(
    uid: str,
    user: User = Depends(require("evaluations:read")),
    db: Session = Depends(get_db),
):
    evaluation = db.scalar(
        select(Evaluation).where(
            Evaluation.uid == uid, Evaluation.tenant_uid == user.tenant_uid
        )
    )
    if evaluation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Avaliacao nao encontrada.")
    stmt = (
        select(EvaluationRun)
        .where(EvaluationRun.evaluation_uid == uid)
        .order_by(EvaluationRun.created_at.desc())
    )
    return [EvaluationRunOut.model_validate(r) for r in db.scalars(stmt).all()]


# ── Privacidade ────────────────────────────────────────────────────────────────
@router.get("/privacy/policies", response_model=list[PrivacyPolicyOut])
def list_policies(
    user: User = Depends(require("privacy:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(PrivacyPolicy)
        .where(PrivacyPolicy.tenant_uid == user.tenant_uid)
        .order_by(PrivacyPolicy.name)
    )
    return [PrivacyPolicyOut.model_validate(p) for p in db.scalars(stmt).all()]


@router.post("/privacy/policies", response_model=PrivacyPolicyOut, status_code=201)
def create_policy(
    payload: PrivacyPolicyIn,
    request: Request,
    user: User = Depends(require("privacy:write")),
    db: Session = Depends(get_db),
):
    policy = PrivacyPolicy(
        tenant_uid=user.tenant_uid, created_by=user.email, updated_by=user.email,
        **payload.model_dump(),
    )
    db.add(policy)
    db.commit()
    db.refresh(policy)
    record_audit(
        db,
        user=user,
        action="create",
        resource_type="privacy_policy",
        resource_uid=policy.uid,
        summary=f"Politica de privacidade '{policy.name}' criada",
        request=request,
    )
    return PrivacyPolicyOut.model_validate(policy)


# ── FinOps ─────────────────────────────────────────────────────────────────────
@router.get("/finops/budgets", response_model=list[BudgetRuleOut])
def list_budgets(
    user: User = Depends(require("finops:read")),
    db: Session = Depends(get_db),
):
    rules = db.scalars(
        select(BudgetRule).where(BudgetRule.tenant_uid == user.tenant_uid)
    ).all()

    service_names = dict(
        db.execute(
            select(Service.uid, Service.name).where(Service.tenant_uid == user.tenant_uid)
        ).all()
    )
    unit_names = dict(
        db.execute(select(Unit.uid, Unit.name).where(Unit.tenant_uid == user.tenant_uid)).all()
    )

    month_start = datetime.now(UTC).replace(
        day=1, hour=0, minute=0, second=0, microsecond=0
    )

    result = []
    for rule in rules:
        out = BudgetRuleOut.model_validate(rule)
        if rule.scope == "service":
            out.scope_label = service_names.get(rule.scope_uid or "", "Todos os servicos")
            consumed = db.scalar(
                select(func.coalesce(func.sum(Trace.cost_usd), 0.0)).where(
                    Trace.tenant_uid == user.tenant_uid,
                    Trace.service_uid == rule.scope_uid,
                    Trace.started_at >= month_start,
                )
            )
        elif rule.scope == "unit":
            out.scope_label = unit_names.get(rule.scope_uid or "", "Todas as unidades")
            consumed = db.scalar(
                select(func.coalesce(func.sum(Trace.cost_usd), 0.0))
                .join(Service, Trace.service_uid == Service.uid)
                .where(
                    Trace.tenant_uid == user.tenant_uid,
                    Service.unit_uid == rule.scope_uid,
                    Trace.started_at >= month_start,
                )
            )
        else:
            out.scope_label = rule.scope_uid or "Tenant"
            consumed = db.scalar(
                select(func.coalesce(func.sum(Trace.cost_usd), 0.0)).where(
                    Trace.tenant_uid == user.tenant_uid, Trace.started_at >= month_start
                )
            )
        out.consumed_usd = round(float(consumed or 0.0), 4)
        result.append(out)
    return result


@router.post("/finops/budgets", response_model=BudgetRuleOut, status_code=201)
def create_budget(
    payload: BudgetRuleIn,
    user: User = Depends(require("finops:write")),
    db: Session = Depends(get_db),
):
    rule = BudgetRule(tenant_uid=user.tenant_uid, **payload.model_dump())
    db.add(rule)
    db.commit()
    db.refresh(rule)
    return BudgetRuleOut.model_validate(rule)


@router.delete("/finops/budgets/{uid}", response_model=Message)
def delete_budget(
    uid: str,
    user: User = Depends(require("finops:write")),
    db: Session = Depends(get_db),
):
    rule = db.scalar(
        select(BudgetRule).where(BudgetRule.uid == uid, BudgetRule.tenant_uid == user.tenant_uid)
    )
    if rule is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Regra nao encontrada.")
    db.delete(rule)
    db.commit()
    return Message(detail="Regra removida.")
