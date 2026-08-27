"""Execucao: conversar com um servico, rodar uma task, aprovar acao retida e
indexar/recuperar conhecimento."""

from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.api.deps import record_audit, require
from app.db.session import get_db
from app.models import (
    Conversation,
    ConversationStatus,
    KnowledgeBase,
    Message,
    PendingAction,
    Service,
    ServiceType,
    TaskRun,
    TaskStatus,
    User,
)
from app.rag import get_embedder, reindex_base, retrieve
from app.runtime import AgentEngine
from app.runtime.engine import RuntimeRefusal
from app.runtime.providers import ChatMessage
from app.schemas.runtime_exec import (
    ActionDecision,
    IndexRequest,
    IndexResponse,
    PendingActionOut,
    RetrievedChunkOut,
    RetrieveRequest,
    RetrieveResponse,
    RunRequest,
    RunResponse,
    TaskRunRequest,
)

router = APIRouter(tags=["execucao"])

# Quantos turnos anteriores entram no contexto. Mais que isso cresce o custo
# sem melhorar a resposta na maioria das jornadas de atendimento.
HISTORY_TURNS = 12


def _service_or_404(db: Session, tenant_uid: str, uid: str) -> Service:
    service = db.scalar(
        select(Service).where(Service.uid == uid, Service.tenant_uid == tenant_uid)
    )
    if service is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Servico nao encontrado.")
    return service


def _next_public_id(db: Session, model, tenant_uid: str, floor: int) -> int:
    current = db.scalar(
        select(func.max(model.public_id)).where(model.tenant_uid == tenant_uid)
    )
    return max(int(current or 0), floor) + 1


# ── Conversar com um servico ───────────────────────────────────────────────────
@router.post("/services/{uid}/run", response_model=RunResponse)
def run_service(
    uid: str,
    payload: RunRequest,
    request: Request,
    user: User = Depends(require("runtime:execute")),
    db: Session = Depends(get_db),
):
    """Executa um turno conversacional e devolve a resposta do agente."""
    service = _service_or_404(db, user.tenant_uid, uid)
    if service.type is ServiceType.task:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Servico de tarefa nao aceita turno conversacional; use /run-task.",
        )

    conversation = _load_or_open_conversation(db, user, service, payload)
    history = _history_for(conversation)

    now = datetime.now(UTC)
    db.add(
        Message(
            conversation_uid=conversation.uid,
            role="user",
            content=payload.message,
            sent_at=now,
            tokens=max(1, len(payload.message) // 4),
        )
    )
    db.flush()

    engine = AgentEngine(db, tenant_uid=user.tenant_uid, actor_email=user.email)
    try:
        outcome = engine.run_turn(
            service.uid,
            payload.message,
            history=history,
            stage_code=payload.stage_code,
            conversation_uid=conversation.uid,
            origin="chat",
            reference_label=f"Chat #{conversation.public_id}",
        )
    except RuntimeRefusal as exc:
        raise HTTPException(status.HTTP_409_CONFLICT, str(exc)) from exc

    db.add(
        Message(
            conversation_uid=conversation.uid,
            role="assistant",
            author=service.name,
            content=outcome.text,
            sent_at=datetime.now(UTC),
            tokens=outcome.tokens_out,
        )
    )
    conversation.last_message = outcome.text[:500]
    conversation.tokens_total += outcome.tokens_in + outcome.tokens_out
    conversation.cost_usd = round(conversation.cost_usd + outcome.cost_usd, 6)
    if outcome.awaiting_approval:
        conversation.status = ConversationStatus.waiting
    elif outcome.status == "error":
        conversation.status = ConversationStatus.failed
    db.commit()

    record_audit(
        db,
        user=user,
        action="run",
        resource_type="service",
        resource_uid=service.uid,
        summary=f"Turno executado em '{service.name}' (trace {outcome.trace_uid[:8]})",
        payload={"conversation": conversation.uid, "status": outcome.status},
        request=request,
    )

    return RunResponse(
        status=outcome.status,
        text=outcome.text,
        trace_uid=outcome.trace_uid,
        conversation_uid=conversation.uid,
        tokens_in=outcome.tokens_in,
        tokens_out=outcome.tokens_out,
        cost_usd=outcome.cost_usd,
        provider=outcome.provider,
        model=outcome.model,
        pending_action_uid=outcome.pending_action_uid,
        tool_calls=outcome.tool_calls,
    )


def _load_or_open_conversation(
    db: Session, user: User, service: Service, payload: RunRequest
) -> Conversation:
    if payload.conversation_uid:
        conversation = db.scalar(
            select(Conversation)
            .options(selectinload(Conversation.messages))
            .where(
                Conversation.uid == payload.conversation_uid,
                Conversation.tenant_uid == user.tenant_uid,
            )
        )
        if conversation is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Conversa nao encontrada.")
        return conversation

    conversation = Conversation(
        tenant_uid=user.tenant_uid,
        service_uid=service.uid,
        public_id=_next_public_id(db, Conversation, user.tenant_uid, 23_000),
        contact=user.email,
        channel=payload.channel,
        status=ConversationStatus.active,
        started_at=datetime.now(UTC),
    )
    db.add(conversation)
    db.flush()
    return conversation


def _history_for(conversation: Conversation) -> list[ChatMessage]:
    recent = conversation.messages[-HISTORY_TURNS:] if conversation.messages else []
    return [
        ChatMessage("user" if message.role == "user" else "assistant", message.content)
        for message in recent
        if message.role in {"user", "assistant"}
    ]


# ── Rodar uma task ─────────────────────────────────────────────────────────────
@router.post("/services/{uid}/run-task", response_model=RunResponse)
def run_task(
    uid: str,
    payload: TaskRunRequest,
    request: Request,
    user: User = Depends(require("runtime:execute")),
    db: Session = Depends(get_db),
):
    """Dispara uma execucao autonoma de servico de tarefa."""
    service = _service_or_404(db, user.tenant_uid, uid)
    if service.type is not ServiceType.task:
        raise HTTPException(
            status.HTTP_409_CONFLICT, "Somente servico de tarefa aceita /run-task."
        )

    started = datetime.now(UTC)
    task = TaskRun(
        tenant_uid=user.tenant_uid,
        service_uid=service.uid,
        public_id=_next_public_id(db, TaskRun, user.tenant_uid, 4_000),
        trigger="manual",
        status=TaskStatus.running,
        started_at=started,
        input_json=payload.input,
        steps_total=1,
    )
    db.add(task)
    db.flush()

    instrucao = payload.note or "Execute a tarefa conforme a instrucao do servico."
    engine = AgentEngine(db, tenant_uid=user.tenant_uid, actor_email=user.email)
    try:
        outcome = engine.run_turn(
            service.uid,
            instrucao,
            task_run_uid=task.uid,
            origin="task",
            reference_label=f"Task #{task.public_id}",
        )
    except RuntimeRefusal as exc:
        task.status = TaskStatus.failed
        task.error = str(exc)
        task.finished_at = datetime.now(UTC)
        db.commit()
        raise HTTPException(status.HTTP_409_CONFLICT, str(exc)) from exc

    finished = datetime.now(UTC)
    task.finished_at = finished
    task.duration_ms = int((finished - started).total_seconds() * 1000)
    task.output_json = {"text": outcome.text, "tool_calls": outcome.tool_calls}
    task.tokens_total = outcome.tokens_in + outcome.tokens_out
    task.cost_usd = outcome.cost_usd

    if outcome.awaiting_approval:
        task.status = TaskStatus.awaiting_approval
        task.requires_human = True
    elif outcome.status == "error":
        task.status = TaskStatus.failed
        task.error = outcome.text
    else:
        task.status = TaskStatus.succeeded
        task.steps_done = task.steps_total
    db.commit()

    record_audit(
        db,
        user=user,
        action="run_task",
        resource_type="task_run",
        resource_uid=task.uid,
        summary=f"Task #{task.public_id} de '{service.name}': {task.status.value}",
        request=request,
    )

    return RunResponse(
        status=outcome.status,
        text=outcome.text,
        trace_uid=outcome.trace_uid,
        tokens_in=outcome.tokens_in,
        tokens_out=outcome.tokens_out,
        cost_usd=outcome.cost_usd,
        provider=outcome.provider,
        model=outcome.model,
        pending_action_uid=outcome.pending_action_uid,
        tool_calls=outcome.tool_calls,
    )


# ── Fila de aprovacoes ─────────────────────────────────────────────────────────
@router.get("/approvals", response_model=list[PendingActionOut])
def list_approvals(
    status_filter: str | None = Query("pending", alias="status"),
    user: User = Depends(require("observability:read")),
    db: Session = Depends(get_db),
):
    stmt = (
        select(PendingAction, Service.name)
        .join(Service, PendingAction.service_uid == Service.uid)
        .where(PendingAction.tenant_uid == user.tenant_uid)
    )
    if status_filter:
        stmt = stmt.where(PendingAction.status == status_filter)

    result = []
    for action, service_name in db.execute(
        stmt.order_by(PendingAction.created_at.desc())
    ).all():
        out = PendingActionOut.model_validate(action)
        out.service_name = service_name
        result.append(out)
    return result


@router.post("/approvals/{uid}/decide", response_model=PendingActionOut)
def decide_approval(
    uid: str,
    payload: ActionDecision,
    request: Request,
    user: User = Depends(require("runtime:approve")),
    db: Session = Depends(get_db),
):
    """Aprova (e executa) ou rejeita uma acao retida."""
    engine = AgentEngine(db, tenant_uid=user.tenant_uid, actor_email=user.email)
    try:
        action = engine.decide_action(uid, approve=payload.approve, decided_by=user.email)
    except RuntimeRefusal as exc:
        raise HTTPException(status.HTTP_409_CONFLICT, str(exc)) from exc

    record_audit(
        db,
        user=user,
        action="approve" if payload.approve else "reject",
        resource_type="pending_action",
        resource_uid=action.uid,
        summary=(
            f"Acao '{action.tool_name}' "
            f"{'aprovada' if payload.approve else 'rejeitada'} por {user.email}"
        ),
        request=request,
    )

    service_name = db.scalar(select(Service.name).where(Service.uid == action.service_uid))
    out = PendingActionOut.model_validate(action)
    out.service_name = service_name or ""
    return out


# ── Conhecimento: indexar e recuperar ──────────────────────────────────────────
@router.post("/knowledge/{uid}/index", response_model=IndexResponse)
def index_knowledge_base(
    uid: str,
    payload: IndexRequest,
    request: Request,
    user: User = Depends(require("knowledge:index")),
    db: Session = Depends(get_db),
):
    """Reindexa todos os documentos da base."""
    base = db.scalar(
        select(KnowledgeBase)
        .options(selectinload(KnowledgeBase.documents))
        .where(KnowledgeBase.uid == uid, KnowledgeBase.tenant_uid == user.tenant_uid)
    )
    if base is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Base nao encontrada.")

    try:
        embedder = get_embedder(payload.embedder)
    except ValueError as exc:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, str(exc)) from exc

    chunks = reindex_base(db, base, embedder=embedder)
    db.commit()

    record_audit(
        db,
        user=user,
        action="index",
        resource_type="knowledge_base",
        resource_uid=base.uid,
        summary=f"Base '{base.name}' reindexada: {chunks} trechos ({embedder.name})",
        request=request,
    )

    return IndexResponse(
        base_uid=base.uid,
        base_name=base.name,
        documents=len(base.documents),
        chunks=chunks,
        embedder=embedder.name,
    )


@router.post("/knowledge/retrieve", response_model=RetrieveResponse)
def retrieve_knowledge(
    payload: RetrieveRequest,
    user: User = Depends(require("knowledge:read")),
    db: Session = Depends(get_db),
):
    """Recupera trechos relevantes — a mesma busca que o agente usa."""
    embedder = get_embedder("hashing")
    chunks = retrieve(
        db,
        payload.query,
        tenant_uid=user.tenant_uid,
        base_uids=payload.base_uids or None,
        top_k=payload.top_k,
        min_score=payload.min_score,
        embedder=embedder,
    )
    return RetrieveResponse(
        query=payload.query,
        embedder=embedder.name,
        hits=len(chunks),
        chunks=[
            RetrievedChunkOut(
                chunk_uid=chunk.chunk_uid,
                document_uid=chunk.document_uid,
                document_title=chunk.document_title,
                base_uid=chunk.base_uid,
                ordinal=chunk.ordinal,
                content=chunk.content,
                score=round(chunk.score, 4),
            )
            for chunk in chunks
        ],
    )
