"""Execucao de ferramentas.

Cada `Tool` cadastrado no AI Studio tem um `kind` que decide o executor. O que
nao tem executor implementado falha com mensagem explicita — melhor um erro
claro no trace do que um sucesso silencioso e falso.
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass

import httpx
from sqlalchemy.orm import Session

from app.models import Tool
from app.rag import retrieve

logger = logging.getLogger("vkb.runtime.tools")

MAX_RESULT_CHARS = 8_000


class ToolError(RuntimeError):
    """Falha na execucao de uma ferramenta."""


@dataclass
class ToolResult:
    content: str
    payload: dict


@dataclass
class ToolContext:
    db: Session
    tenant_uid: str
    actor_email: str | None = None


def tool_schema(tool: Tool) -> dict:
    """Descreve a ferramenta no formato que os provedores esperam."""
    return {
        "name": tool.slug.replace("-", "_"),
        "description": tool.description or tool.name,
        "parameters": tool.parameters_json or {"type": "object", "properties": {}},
    }


def execute_tool(tool: Tool, arguments: dict, context: ToolContext) -> ToolResult:
    """Roda a ferramenta e devolve o resultado em texto e em estrutura."""
    if not tool.is_enabled:
        raise ToolError(f"Ferramenta '{tool.name}' esta desabilitada.")

    executor = _EXECUTORS.get(tool.kind)
    if executor is None:
        raise ToolError(
            f"Ferramenta '{tool.name}' e do tipo '{tool.kind}', que ainda nao tem "
            f"executor. Tipos suportados: {', '.join(sorted(_EXECUTORS))}."
        )
    return executor(tool, arguments, context)


def _run_retrieval(tool: Tool, arguments: dict, context: ToolContext) -> ToolResult:
    """Recuperacao semantica nas bases de conhecimento do tenant."""
    del tool
    query = str(arguments.get("query") or arguments.get("q") or "").strip()
    if not query:
        raise ToolError("A recuperacao exige o argumento 'query'.")

    base_uids = arguments.get("base_uids")
    top_k = int(arguments.get("top_k") or 5)

    chunks = retrieve(
        context.db,
        query,
        tenant_uid=context.tenant_uid,
        base_uids=base_uids if isinstance(base_uids, list) else None,
        top_k=max(1, min(top_k, 20)),
    )
    if not chunks:
        return ToolResult(
            content="Nenhum trecho relevante encontrado nas bases de conhecimento.",
            payload={"query": query, "hits": 0, "chunks": []},
        )

    linhas = [
        f"[{index + 1}] {chunk.document_title} (similaridade {chunk.score:.2f})\n{chunk.content}"
        for index, chunk in enumerate(chunks)
    ]
    return ToolResult(
        content=_truncate("\n\n".join(linhas)),
        payload={
            "query": query,
            "hits": len(chunks),
            "chunks": [
                {
                    "document": chunk.document_title,
                    "score": round(chunk.score, 4),
                    "chunk_uid": chunk.chunk_uid,
                }
                for chunk in chunks
            ],
        },
    )


def _run_http(tool: Tool, arguments: dict, context: ToolContext) -> ToolResult:
    """Chamada HTTP configurada na ferramenta.

    A URL e o metodo vem de `config_json` — o modelo preenche apenas os
    parametros declarados, nunca o destino da chamada.
    """
    del context
    config = tool.config_json or {}
    url = config.get("url")
    if not url:
        raise ToolError(f"Ferramenta '{tool.name}' nao tem 'url' em config_json.")

    method = str(config.get("method") or "GET").upper()
    timeout = float(config.get("timeout") or 20.0)
    headers = dict(config.get("headers") or {})

    try:
        if method in {"GET", "HEAD", "DELETE"}:
            response = httpx.request(
                method, url, params=arguments, headers=headers, timeout=timeout
            )
        else:
            response = httpx.request(
                method, url, json=arguments, headers=headers, timeout=timeout
            )
        response.raise_for_status()
    except httpx.HTTPError as exc:
        raise ToolError(f"Chamada a '{url}' falhou: {exc}") from exc

    try:
        body = response.json()
        content = json.dumps(body, ensure_ascii=False)
    except ValueError:
        body = {"text": response.text}
        content = response.text

    return ToolResult(
        content=_truncate(content),
        payload={"status_code": response.status_code, "body": body},
    )


def _run_noop(tool: Tool, arguments: dict, context: ToolContext) -> ToolResult:
    """Ferramenta declarada mas sem efeito — util para ensaiar uma jornada."""
    del context
    return ToolResult(
        content=f"Ferramenta '{tool.name}' registrada sem efeito colateral.",
        payload={"tool": tool.slug, "arguments": arguments, "executed": False},
    )


def _truncate(text: str) -> str:
    if len(text) <= MAX_RESULT_CHARS:
        return text
    return text[:MAX_RESULT_CHARS] + f"\n… (truncado em {MAX_RESULT_CHARS} caracteres)"


# `sql` e `rpa` ficam de fora deliberadamente: executar SQL arbitrario ou
# automacao de interface a partir de saida de modelo exige isolamento que esta
# camada nao tem. Cadastrar a ferramenta e permitido; executar, ainda nao.
_EXECUTORS = {
    "retrieval": _run_retrieval,
    "http": _run_http,
    "noop": _run_noop,
}
