"""Adaptadores de provedor de LLM.

A plataforma nao depende de um fornecedor. Cada adaptador recebe URL base,
codigo do modelo e credencial da configuracao do tenant — nada de valor fixo
no codigo. Trocar de provedor e trocar a linha em LLM Gateway.

Tres adaptadores:

* `echo` — deterministico, local, sem rede e sem custo. E o padrao quando o
  provedor nao tem credencial: permite exercitar o loop do agente, o trace e a
  aprovacao de ponta a ponta sem contratar ninguem. Nao raciocina.
* `openai_compatible` — POST /chat/completions com `tools`, o formato que a
  maior parte dos provedores expoe.
* `anthropic_messages` — POST /messages, com `tools` e blocos `tool_use`.
"""

from __future__ import annotations

import json
import re
from abc import ABC, abstractmethod
from dataclasses import dataclass, field

import httpx


@dataclass
class ChatMessage:
    role: str  # system | user | assistant | tool
    content: str
    name: str | None = None
    tool_call_id: str | None = None


@dataclass
class ToolCall:
    id: str
    name: str
    arguments: dict


@dataclass
class LLMResponse:
    text: str
    tokens_in: int = 0
    tokens_out: int = 0
    tool_calls: list[ToolCall] = field(default_factory=list)
    finish_reason: str = "stop"
    raw: dict = field(default_factory=dict)


class Provider(ABC):
    """Contrato de um provedor de chat."""

    name: str

    def __init__(
        self,
        model: str,
        base_url: str | None = None,
        api_key: str | None = None,
        timeout: float = 60.0,
    ) -> None:
        self.model = model
        self.base_url = (base_url or "").rstrip("/")
        self.api_key = api_key
        self.timeout = timeout

    @abstractmethod
    def complete(
        self,
        messages: list[ChatMessage],
        *,
        tools: list[dict] | None = None,
        temperature: float = 0.2,
        max_tokens: int = 2048,
    ) -> LLMResponse: ...


# ── Echo ──────────────────────────────────────────────────────────────────────
_TOOL_HINT = re.compile(r"\[\[usar:\s*([a-z0-9_\-]+)(?:\s+(\{.*\}))?\s*\]\]", re.IGNORECASE)


class EchoProvider(Provider):
    """Provedor local e deterministico, para desenvolvimento e teste.

    Ele nao gera linguagem: resume o contexto que recebeu e devolve uma resposta
    previsivel. Se a ultima mensagem do usuario contiver a marca
    `[[usar: nome_da_ferramenta {"arg": 1}]]`, emite a chamada de ferramenta
    correspondente — e assim o loop de ferramentas fica exercitavel sem rede.
    """

    name = "echo"

    def complete(
        self,
        messages: list[ChatMessage],
        *,
        tools: list[dict] | None = None,
        temperature: float = 0.2,
        max_tokens: int = 2048,
    ) -> LLMResponse:
        del temperature, max_tokens  # o echo nao amostra

        user_turns = [m for m in messages if m.role == "user"]
        last = user_turns[-1].content if user_turns else ""
        tool_results = [m for m in messages if m.role == "tool"]
        available = {tool["name"] for tool in (tools or [])}

        hint = _TOOL_HINT.search(last)
        # Uma marca so vira chamada se a ferramenta existir e ainda nao rodou.
        if hint and hint.group(1) in available and not tool_results:
            try:
                arguments = json.loads(hint.group(2)) if hint.group(2) else {}
            except json.JSONDecodeError:
                arguments = {}
            return LLMResponse(
                text="",
                tokens_in=_estimate([m.content for m in messages]),
                tokens_out=0,
                tool_calls=[ToolCall(id="echo-1", name=hint.group(1), arguments=arguments)],
                finish_reason="tool_calls",
            )

        pergunta = _TOOL_HINT.sub("", last).strip()
        if tool_results:
            trecho = tool_results[-1].content.strip()
            corpo = (
                f"Com base no que consultei: {trecho[:400]}"
                if trecho
                else "Consultei a ferramenta, mas ela nao devolveu conteudo."
            )
        elif pergunta:
            corpo = (
                f"Recebi sua mensagem: “{pergunta[:200]}”. Este ambiente esta com o provedor "
                "'echo', que responde de forma deterministica e nao consulta um modelo de "
                "linguagem. Configure um provedor no LLM Gateway para respostas geradas."
            )
        else:
            corpo = "Nao recebi conteudo na mensagem."

        return LLMResponse(
            text=corpo,
            tokens_in=_estimate([m.content for m in messages]),
            tokens_out=_estimate([corpo]),
        )


def _estimate(parts: list[str]) -> int:
    return max(1, sum(len(part) for part in parts) // 4)


# ── HTTP: formato /chat/completions ───────────────────────────────────────────
class OpenAICompatibleProvider(Provider):
    """POST {base_url}/chat/completions no formato de mensagens com `tools`."""

    name = "openai_compatible"

    def complete(
        self,
        messages: list[ChatMessage],
        *,
        tools: list[dict] | None = None,
        temperature: float = 0.2,
        max_tokens: int = 2048,
    ) -> LLMResponse:
        payload: dict = {
            "model": self.model,
            "messages": [_to_openai_message(m) for m in messages],
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        if tools:
            payload["tools"] = [
                {
                    "type": "function",
                    "function": {
                        "name": tool["name"],
                        "description": tool.get("description", ""),
                        "parameters": tool.get("parameters")
                        or {"type": "object", "properties": {}},
                    },
                }
                for tool in tools
            ]

        data = _post(f"{self.base_url}/chat/completions", payload, self.api_key, self.timeout)

        choice = (data.get("choices") or [{}])[0]
        message = choice.get("message") or {}
        usage = data.get("usage") or {}

        calls: list[ToolCall] = []
        for raw_call in message.get("tool_calls") or []:
            function = raw_call.get("function") or {}
            calls.append(
                ToolCall(
                    id=raw_call.get("id") or f"call-{len(calls)}",
                    name=function.get("name", ""),
                    arguments=_loads(function.get("arguments")),
                )
            )

        return LLMResponse(
            text=message.get("content") or "",
            tokens_in=int(usage.get("prompt_tokens") or 0),
            tokens_out=int(usage.get("completion_tokens") or 0),
            tool_calls=calls,
            finish_reason=choice.get("finish_reason") or "stop",
            raw=data,
        )


def _to_openai_message(message: ChatMessage) -> dict:
    if message.role == "tool":
        return {
            "role": "tool",
            "content": message.content,
            "tool_call_id": message.tool_call_id or "",
        }
    payload = {"role": message.role, "content": message.content}
    if message.name:
        payload["name"] = message.name
    return payload


# ── HTTP: formato /messages ───────────────────────────────────────────────────
class AnthropicMessagesProvider(Provider):
    """POST {base_url}/messages, com blocos de conteudo e `tool_use`."""

    name = "anthropic_messages"
    api_version = "2023-06-01"

    def complete(
        self,
        messages: list[ChatMessage],
        *,
        tools: list[dict] | None = None,
        temperature: float = 0.2,
        max_tokens: int = 2048,
    ) -> LLMResponse:
        system = "\n\n".join(m.content for m in messages if m.role == "system")
        turns: list[dict] = []
        for message in messages:
            if message.role == "system":
                continue
            if message.role == "tool":
                turns.append(
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "tool_result",
                                "tool_use_id": message.tool_call_id or "",
                                "content": message.content,
                            }
                        ],
                    }
                )
                continue
            turns.append({"role": message.role, "content": message.content})

        payload: dict = {
            "model": self.model,
            "messages": turns,
            "max_tokens": max_tokens,
            "temperature": temperature,
        }
        if system:
            payload["system"] = system
        if tools:
            payload["tools"] = [
                {
                    "name": tool["name"],
                    "description": tool.get("description", ""),
                    "input_schema": tool.get("parameters")
                    or {"type": "object", "properties": {}},
                }
                for tool in tools
            ]

        headers = {"anthropic-version": self.api_version}
        data = _post(
            f"{self.base_url}/messages", payload, self.api_key, self.timeout, extra=headers
        )

        text_parts: list[str] = []
        calls: list[ToolCall] = []
        for block in data.get("content") or []:
            if block.get("type") == "text":
                text_parts.append(block.get("text") or "")
            elif block.get("type") == "tool_use":
                calls.append(
                    ToolCall(
                        id=block.get("id") or f"call-{len(calls)}",
                        name=block.get("name", ""),
                        arguments=block.get("input") or {},
                    )
                )

        usage = data.get("usage") or {}
        return LLMResponse(
            text="".join(text_parts),
            tokens_in=int(usage.get("input_tokens") or 0),
            tokens_out=int(usage.get("output_tokens") or 0),
            tool_calls=calls,
            finish_reason=data.get("stop_reason") or "stop",
            raw=data,
        )


def _post(
    url: str,
    payload: dict,
    api_key: str | None,
    timeout: float,
    extra: dict | None = None,
) -> dict:
    headers = {"Content-Type": "application/json"}
    if api_key:
        # Os dois formatos aceitam Bearer; x-api-key cobre quem exige o header proprio.
        headers["Authorization"] = f"Bearer {api_key}"
        headers["x-api-key"] = api_key
    headers.update(extra or {})

    response = httpx.post(url, headers=headers, json=payload, timeout=timeout)
    response.raise_for_status()
    return response.json()


def _loads(value) -> dict:
    if isinstance(value, dict):
        return value
    if not value:
        return {}
    try:
        parsed = json.loads(value)
    except (json.JSONDecodeError, TypeError):
        return {}
    return parsed if isinstance(parsed, dict) else {}


PROVIDERS: dict[str, type[Provider]] = {
    "echo": EchoProvider,
    "openai_compatible": OpenAICompatibleProvider,
    "anthropic_messages": AnthropicMessagesProvider,
}

# Codigo do provedor no LLM Gateway -> adaptador. O que nao estiver aqui e
# tratado como compativel com /chat/completions, que e o formato mais comum.
PROVIDER_DIALECTS: dict[str, str] = {
    "anthropic": "anthropic_messages",
    "claude": "anthropic_messages",
}


def build_provider(
    provider_code: str,
    model: str,
    *,
    base_url: str | None = None,
    api_key: str | None = None,
    dialect: str | None = None,
) -> Provider:
    """Instancia o adaptador do provedor.

    Sem credencial nao ha como chamar servico externo: cai no `echo`, para que a
    plataforma continue operavel e observavel em desenvolvimento.
    """
    if not api_key or not base_url:
        return EchoProvider(model=model or "echo")

    kind = dialect or PROVIDER_DIALECTS.get(provider_code.lower(), "openai_compatible")
    factory = PROVIDERS.get(kind, OpenAICompatibleProvider)
    return factory(model=model, base_url=base_url, api_key=api_key)
