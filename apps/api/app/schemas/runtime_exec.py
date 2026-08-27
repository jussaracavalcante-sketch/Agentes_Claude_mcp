"""Contratos da camada de execucao."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class RunRequest(BaseModel):
    message: str = Field(min_length=1, max_length=8_000)
    conversation_uid: str | None = Field(
        None, description="Continua uma conversa existente; omitido, abre uma nova."
    )
    stage_code: str | None = None
    channel: str = "webchat"


class ToolCallOut(BaseModel):
    tool: str
    arguments: dict = {}
    ok: bool
    erro: str | None = None


class RunResponse(BaseModel):
    status: str
    text: str
    trace_uid: str
    conversation_uid: str | None = None
    tokens_in: int
    tokens_out: int
    cost_usd: float
    provider: str | None = None
    model: str | None = None
    pending_action_uid: str | None = None
    tool_calls: list[ToolCallOut] = []


class TaskRunRequest(BaseModel):
    input: dict = {}
    note: str = ""


class PendingActionOut(ORMModel):
    uid: str
    service_uid: str
    service_name: str = ""
    tool_name: str
    arguments_json: dict = {}
    reason: str
    status: str
    conversation_uid: str | None = None
    task_run_uid: str | None = None
    trace_uid: str | None = None
    decided_by: str | None = None
    decided_at: datetime | None = None
    result_json: dict = {}
    error: str | None = None
    created_at: datetime


class ActionDecision(BaseModel):
    approve: bool


class IndexRequest(BaseModel):
    embedder: str = Field("hashing", description="hashing (local) ou http (provedor)")


class IndexResponse(BaseModel):
    base_uid: str
    base_name: str
    documents: int
    chunks: int
    embedder: str


class RetrieveRequest(BaseModel):
    query: str = Field(min_length=1, max_length=2_000)
    base_uids: list[str] = []
    top_k: int = Field(5, ge=1, le=20)
    min_score: float = Field(0.0, ge=0.0, le=1.0)


class RetrievedChunkOut(BaseModel):
    chunk_uid: str
    document_uid: str
    document_title: str
    base_uid: str
    ordinal: int
    content: str
    score: float


class RetrieveResponse(BaseModel):
    query: str
    embedder: str
    hits: int
    chunks: list[RetrievedChunkOut]
