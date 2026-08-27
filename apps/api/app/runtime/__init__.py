"""Camada de execucao — o motor que roda um servico de IA.

O que a plataforma ja fazia era modelar, versionar, governar e observar. Este
pacote executa: monta o prompt, chama o provedor, invoca ferramentas, aplica o
nivel de autonomia e o limite de orcamento, e grava o trace com os spans reais.
"""

from app.runtime.engine import AgentEngine, RunOutcome
from app.runtime.providers import (
    PROVIDERS,
    ChatMessage,
    LLMResponse,
    Provider,
    ToolCall,
    build_provider,
)
from app.runtime.tracing import SpanRecorder

__all__ = [
    "AgentEngine",
    "RunOutcome",
    "Provider",
    "PROVIDERS",
    "ChatMessage",
    "LLMResponse",
    "ToolCall",
    "build_provider",
    "SpanRecorder",
]
