"""Gravacao do trace durante a execucao.

Cada execucao produz um `Trace` e uma arvore de `Span` com duracao medida,
tokens contados e custo calculado a partir do preco do modelo no banco. E o que
faz a observabilidade deixar de ser dado semeado e passar a refletir o que
realmente aconteceu.
"""

from __future__ import annotations

import time
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import UTC, datetime

from sqlalchemy.orm import Session

from app.db.base import new_uid
from app.models import Span, SpanKind, Trace


@dataclass
class _OpenSpan:
    uid: str
    name: str
    kind: SpanKind
    depth: int
    started_at: datetime
    started_perf: float
    parent_uid: str | None = None
    tokens_in: int = 0
    tokens_out: int = 0
    cost_usd: float = 0.0
    model: str | None = None
    status: str = "success"
    error: str | None = None
    input_json: dict = field(default_factory=dict)
    output_json: dict = field(default_factory=dict)
    metadata_json: dict = field(default_factory=dict)


class SpanRecorder:
    """Acumula spans em memoria e persiste tudo no fim da execucao.

    Persistir ao final, e nao span a span, mantem o trace consistente mesmo se a
    execucao falhar no meio: ou grava a arvore inteira, ou nao grava nada.
    """

    def __init__(
        self,
        db: Session,
        *,
        tenant_uid: str,
        service_uid: str,
        origin: str,
        reference_label: str,
        provider: str | None = None,
        model: str | None = None,
        conversation_uid: str | None = None,
        task_run_uid: str | None = None,
    ) -> None:
        self.db = db
        self.trace_uid = new_uid()
        self.tenant_uid = tenant_uid
        self.service_uid = service_uid
        self.origin = origin
        self.reference_label = reference_label
        self.provider = provider
        self.model = model
        self.conversation_uid = conversation_uid
        self.task_run_uid = task_run_uid

        self.started_at = datetime.now(UTC)
        self._started_perf = time.perf_counter()
        self._spans: list[_OpenSpan] = []
        self._stack: list[_OpenSpan] = []
        self._closed: dict[str, int] = {}
        self.status = "ok"

    @contextmanager
    def span(self, name: str, kind: SpanKind, **fields):
        parent = self._stack[-1] if self._stack else None
        entry = _OpenSpan(
            uid=new_uid(),
            name=name,
            kind=kind,
            depth=len(self._stack),
            started_at=datetime.now(UTC),
            started_perf=time.perf_counter(),
            parent_uid=parent.uid if parent else None,
            **fields,
        )
        self._spans.append(entry)
        self._stack.append(entry)
        try:
            yield entry
        except Exception as exc:
            entry.status = "error"
            entry.error = f"{type(exc).__name__}: {exc}"
            self.status = "error"
            raise
        finally:
            self._closed[entry.uid] = int((time.perf_counter() - entry.started_perf) * 1000)
            self._stack.pop()

    @property
    def tokens_in(self) -> int:
        return sum(span.tokens_in for span in self._spans)

    @property
    def tokens_out(self) -> int:
        return sum(span.tokens_out for span in self._spans)

    @property
    def cost_usd(self) -> float:
        return round(sum(span.cost_usd for span in self._spans), 6)

    def flush(self) -> Trace:
        """Persiste o trace e os spans. Chame uma unica vez, no fim."""
        duration = int((time.perf_counter() - self._started_perf) * 1000)

        trace = Trace(
            uid=self.trace_uid,
            tenant_uid=self.tenant_uid,
            service_uid=self.service_uid,
            origin=self.origin,
            conversation_uid=self.conversation_uid,
            task_run_uid=self.task_run_uid,
            reference_label=self.reference_label,
            provider=self.provider,
            model=self.model,
            status=self.status,
            started_at=self.started_at,
            duration_ms=duration,
            tokens_in=self.tokens_in,
            tokens_out=self.tokens_out,
            tokens_reasoning=0,
            cost_usd=self.cost_usd,
        )
        self.db.add(trace)

        for position, entry in enumerate(self._spans):
            self.db.add(
                Span(
                    uid=entry.uid,
                    trace_uid=self.trace_uid,
                    parent_uid=entry.parent_uid,
                    name=entry.name,
                    kind=entry.kind,
                    status=entry.status,
                    started_at=entry.started_at,
                    duration_ms=self._closed.get(entry.uid, 0),
                    position=position,
                    depth=entry.depth,
                    tokens_in=entry.tokens_in,
                    tokens_out=entry.tokens_out,
                    cost_usd=round(entry.cost_usd, 6),
                    model=entry.model,
                    input_json=entry.input_json,
                    output_json=entry.output_json,
                    metadata_json=entry.metadata_json,
                    error=entry.error,
                )
            )

        self.db.flush()
        return trace
