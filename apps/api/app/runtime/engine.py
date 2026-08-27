"""Motor de execucao de um servico de IA.

Sequencia de uma execucao:

1. resolve o servico, o agente supervisor e o modelo;
2. checa o orcamento do mes — `hard_stop` estourado impede a chamada;
3. monta o prompt com instrucao do servico, do agente e do estagio corrente;
4. chama o provedor; se ele pedir ferramenta, aplica o nivel de autonomia;
5. executa a ferramenta ou retem a acao para aprovacao humana;
6. devolve ao modelo o resultado e fecha o turno;
7. grava o trace com a arvore de spans, tokens e custo.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.models import (
    ActionStatus,
    Agent,
    AutonomyLevel,
    BudgetRule,
    LLMModel,
    LLMProvider,
    PendingAction,
    Service,
    ServiceAgent,
    ServiceStatus,
    SpanKind,
    Tool,
    Trace,
)
from app.runtime.providers import ChatMessage, LLMResponse, Provider, build_provider
from app.runtime.tools import ToolContext, ToolError, execute_tool, tool_schema
from app.runtime.tracing import SpanRecorder

logger = logging.getLogger("vkb.runtime")

# Teto de idas ao modelo em um turno. Sem isso, um modelo que insiste em chamar
# ferramenta gera custo sem convergir.
MAX_MODEL_CALLS = 4

# Niveis que podem executar ferramenta sem aprovacao humana.
AUTONOMOUS_LEVELS = {
    AutonomyLevel.n2_executa_reversivel,
    AutonomyLevel.n3_executa_irreversivel,
}


class RuntimeRefusal(RuntimeError):
    """Execucao recusada por politica — orcamento, estado ou configuracao."""


@dataclass
class RunOutcome:
    text: str
    trace_uid: str
    tokens_in: int
    tokens_out: int
    cost_usd: float
    status: str = "ok"
    pending_action_uid: str | None = None
    tool_calls: list[dict] = field(default_factory=list)
    provider: str | None = None
    model: str | None = None

    @property
    def awaiting_approval(self) -> bool:
        return self.pending_action_uid is not None


@dataclass
class _Resolved:
    service: Service
    agent: Agent | None
    provider: Provider
    # O provedor configurado no LLM Gateway e o que de fato executou podem
    # divergir: sem credencial o motor cai no adaptador local. O trace registra
    # o que executou — dizer o contrario falsearia a observabilidade e o FinOps.
    configured_provider: str
    configured_model: str
    effective_provider: str
    effective_model: str
    model: LLMModel | None
    tools: dict[str, Tool]

    @property
    def is_local(self) -> bool:
        """True quando nao houve chamada a servico externo (logo, custo zero)."""
        return self.provider.name == "echo"


class AgentEngine:
    """Executa um turno de um servico. Sincrono e in-process.

    O motor e sincrono de proposito: mantem a borda simples e o trace coeso.
    Trocar por fila e substituir quem chama `run_turn`, nao o motor.
    """

    def __init__(self, db: Session, *, tenant_uid: str, actor_email: str | None = None) -> None:
        self.db = db
        self.tenant_uid = tenant_uid
        self.actor_email = actor_email

    # ── entrada publica ───────────────────────────────────────────────────────
    def run_turn(
        self,
        service_uid: str,
        user_message: str,
        *,
        history: list[ChatMessage] | None = None,
        stage_code: str | None = None,
        conversation_uid: str | None = None,
        task_run_uid: str | None = None,
        origin: str = "chat",
        reference_label: str = "",
    ) -> RunOutcome:
        resolved = self._resolve(service_uid)
        self._assert_budget(resolved.service)

        recorder = SpanRecorder(
            self.db,
            tenant_uid=self.tenant_uid,
            service_uid=resolved.service.uid,
            origin=origin,
            reference_label=reference_label or f"{origin}:{resolved.service.slug}",
            provider=resolved.effective_provider,
            model=resolved.effective_model,
            conversation_uid=conversation_uid,
            task_run_uid=task_run_uid,
        )

        stage = self._pick_stage(resolved.service, stage_code)
        root_name = stage.code if stage else "TURNO"

        outcome: RunOutcome
        try:
            with recorder.span(root_name, SpanKind.chain, metadata_json={"stage": root_name}):
                outcome = self._execute(resolved, recorder, user_message, history or [], stage)
        except RuntimeRefusal:
            recorder.flush()
            self.db.commit()
            raise
        except Exception:  # noqa: BLE001 — falha vira trace, nao 500 silencioso
            logger.exception("falha na execucao do servico %s", service_uid)
            trace = recorder.flush()
            self.db.commit()
            return RunOutcome(
                text=(
                    "Nao foi possivel concluir a execucao. A falha esta registrada no "
                    "trace para diagnostico."
                ),
                trace_uid=trace.uid,
                tokens_in=recorder.tokens_in,
                tokens_out=recorder.tokens_out,
                cost_usd=recorder.cost_usd,
                status="error",
                provider=resolved.effective_provider,
                model=resolved.effective_model,
            )

        trace = recorder.flush()
        outcome.trace_uid = trace.uid
        outcome.tokens_in = recorder.tokens_in
        outcome.tokens_out = recorder.tokens_out
        outcome.cost_usd = recorder.cost_usd
        outcome.provider = resolved.effective_provider
        outcome.model = resolved.effective_model
        self.db.commit()
        return outcome

    # ── resolucao ─────────────────────────────────────────────────────────────
    def _resolve(self, service_uid: str) -> _Resolved:
        service = self.db.scalar(
            select(Service)
            .options(
                selectinload(Service.agents).selectinload(ServiceAgent.agent),
                selectinload(Service.stages),
            )
            .where(Service.uid == service_uid, Service.tenant_uid == self.tenant_uid)
        )
        if service is None:
            raise RuntimeRefusal("Servico nao encontrado neste tenant.")
        if service.status is ServiceStatus.archived:
            raise RuntimeRefusal("Servico arquivado nao executa.")

        links = sorted(service.agents, key=lambda link: (not link.is_supervisor, link.position))
        agent = next((link.agent for link in links if link.agent is not None), None)

        model: LLMModel | None = None
        provider_row: LLMProvider | None = None
        if agent is not None and agent.model_uid:
            row = self.db.execute(
                select(LLMModel, LLMProvider)
                .join(LLMProvider, LLMModel.provider_uid == LLMProvider.uid)
                .where(LLMModel.uid == agent.model_uid, LLMProvider.tenant_uid == self.tenant_uid)
            ).first()
            if row is not None:
                model, provider_row = row

        provider_code = provider_row.code if provider_row else "echo"
        model_code = model.code if model else "echo"
        provider = build_provider(
            provider_code,
            model_code,
            base_url=provider_row.base_url if provider_row else None,
            # `credential_ref` aponta para o cofre; a plataforma nao guarda o
            # segredo. Sem resolvedor de cofre configurado, cai no echo.
            api_key=_resolve_credential(provider_row.credential_ref if provider_row else None),
        )

        tools: dict[str, Tool] = {}
        if agent is not None:
            for link in agent.tools:
                if link.tool is not None and link.tool.is_enabled:
                    tools[tool_schema(link.tool)["name"]] = link.tool

        local = provider.name == "echo"
        return _Resolved(
            service=service,
            agent=agent,
            provider=provider,
            configured_provider=provider_code,
            configured_model=model_code,
            effective_provider="echo" if local else provider_code,
            effective_model="echo" if local else model_code,
            # Sem chamada externa nao existe preco a aplicar.
            model=None if local else model,
            tools=tools,
        )

    def _pick_stage(self, service: Service, stage_code: str | None):
        if not service.stages:
            return None
        if stage_code:
            for stage in service.stages:
                if stage.code == stage_code:
                    return stage
        return service.stages[0]

    # ── governanca ────────────────────────────────────────────────────────────
    def _assert_budget(self, service: Service) -> None:
        """Bloqueia a execucao se um limite com `hard_stop` ja foi estourado."""
        rules = self.db.scalars(
            select(BudgetRule).where(
                BudgetRule.tenant_uid == self.tenant_uid,
                BudgetRule.is_enabled.is_(True),
                BudgetRule.hard_stop.is_(True),
            )
        ).all()
        if not rules:
            return

        month_start = datetime.now(UTC).replace(
            day=1, hour=0, minute=0, second=0, microsecond=0
        )
        for rule in rules:
            if rule.scope == "service" and rule.scope_uid not in (None, service.uid):
                continue
            if rule.scope == "unit" and rule.scope_uid != service.unit_uid:
                continue

            stmt = select(func.coalesce(func.sum(Trace.cost_usd), 0.0)).where(
                Trace.tenant_uid == self.tenant_uid, Trace.started_at >= month_start
            )
            if rule.scope == "service" and rule.scope_uid:
                stmt = stmt.where(Trace.service_uid == rule.scope_uid)
            spent = float(self.db.scalar(stmt) or 0.0)

            if spent >= rule.limit_usd:
                raise RuntimeRefusal(
                    f"Limite de consumo atingido: US$ {spent:.2f} de US$ "
                    f"{rule.limit_usd:.2f} no escopo '{rule.scope}'. A regra tem "
                    "bloqueio duro; ajuste o orcamento em Privacidade e FinOps."
                )

    def _autonomy_allows(self, agent: Agent | None, tool: Tool) -> tuple[bool, str]:
        """Decide se a ferramenta roda direto ou espera aprovacao."""
        if tool.requires_approval:
            return False, f"A ferramenta '{tool.name}' exige aprovacao humana."
        if agent is None:
            return False, "Servico sem agente definido nao executa ferramenta."

        autonomy = agent.autonomy
        if isinstance(autonomy, str):
            autonomy = AutonomyLevel(autonomy)

        if autonomy is AutonomyLevel.n0_sugere:
            return False, (
                f"O agente '{agent.name}' tem autonomia N0 (apenas sugere) e nao "
                "executa ferramenta."
            )
        if autonomy in AUTONOMOUS_LEVELS:
            return True, ""
        return False, (
            f"O agente '{agent.name}' tem autonomia N1: a acao precisa de aprovacao."
        )

    # ── execucao ──────────────────────────────────────────────────────────────
    def _execute(
        self,
        resolved: _Resolved,
        recorder: SpanRecorder,
        user_message: str,
        history: list[ChatMessage],
        stage,
    ) -> RunOutcome:
        messages = [ChatMessage("system", self._system_prompt(resolved, stage))]
        messages.extend(history)
        messages.append(ChatMessage("user", user_message))

        schemas = [tool_schema(tool) for tool in resolved.tools.values()]
        executed: list[dict] = []
        final_text = ""

        for attempt in range(MAX_MODEL_CALLS):
            response = self._call_model(resolved, recorder, messages, schemas)

            if not response.tool_calls:
                final_text = response.text
                break

            with recorder.span("tools", SpanKind.chain):
                stop = self._run_tool_calls(
                    resolved, recorder, response, messages, executed
                )
            if stop is not None:
                return stop

            if attempt == MAX_MODEL_CALLS - 1:
                final_text = response.text or (
                    "Nao consegui concluir dentro do limite de chamadas ao modelo."
                )

        with recorder.span(
            "OutputGuardrail", SpanKind.guardrail, output_json={"chars": len(final_text)}
        ):
            final_text = final_text.strip() or (
                "O modelo nao devolveu conteudo. Verifique a instrucao do servico."
            )

        return RunOutcome(
            text=final_text,
            trace_uid=recorder.trace_uid,
            tokens_in=0,
            tokens_out=0,
            cost_usd=0.0,
            tool_calls=executed,
        )

    def _call_model(
        self,
        resolved: _Resolved,
        recorder: SpanRecorder,
        messages: list[ChatMessage],
        schemas: list[dict],
    ) -> LLMResponse:
        agent = resolved.agent
        with recorder.span("model", SpanKind.chain):
            with recorder.span(
                agent.name if agent else "modelo",
                SpanKind.model,
                model=resolved.effective_model,
                input_json={"messages": len(messages), "tools": len(schemas)},
                metadata_json={
                    "adaptador": resolved.provider.name,
                    "provedor_configurado": resolved.configured_provider,
                    "modelo_configurado": resolved.configured_model,
                    "execucao_local": resolved.is_local,
                },
            ) as span:
                response = resolved.provider.complete(
                    messages,
                    tools=schemas or None,
                    temperature=agent.temperature if agent else 0.2,
                    max_tokens=agent.max_tokens if agent else 2048,
                )
                span.tokens_in = response.tokens_in
                span.tokens_out = response.tokens_out
                span.cost_usd = _cost_of(resolved.model, response)
                span.output_json = {
                    "finish_reason": response.finish_reason,
                    "tool_calls": [call.name for call in response.tool_calls],
                    "chars": len(response.text),
                }
        return response

    def _run_tool_calls(
        self,
        resolved: _Resolved,
        recorder: SpanRecorder,
        response: LLMResponse,
        messages: list[ChatMessage],
        executed: list[dict],
    ) -> RunOutcome | None:
        """Executa as chamadas pedidas. Devolve RunOutcome se retiver a acao."""
        for call in response.tool_calls:
            tool = resolved.tools.get(call.name)
            if tool is None:
                messages.append(
                    ChatMessage(
                        "tool",
                        f"Ferramenta '{call.name}' nao esta disponivel para este agente.",
                        tool_call_id=call.id,
                    )
                )
                continue

            allowed, reason = self._autonomy_allows(resolved.agent, tool)
            if not allowed:
                with recorder.span(
                    f"aprovacao:{tool.slug}",
                    SpanKind.handoff,
                    input_json={"arguments": call.arguments},
                    output_json={"retido": True, "motivo": reason},
                ):
                    action = PendingAction(
                        tenant_uid=self.tenant_uid,
                        service_uid=resolved.service.uid,
                        agent_uid=resolved.agent.uid if resolved.agent else None,
                        tool_uid=tool.uid,
                        tool_name=tool.name,
                        conversation_uid=recorder.conversation_uid,
                        task_run_uid=recorder.task_run_uid,
                        trace_uid=recorder.trace_uid,
                        arguments_json=call.arguments,
                        reason=reason,
                    )
                    self.db.add(action)
                    self.db.flush()

                return RunOutcome(
                    text=(
                        f"{reason} A acao foi registrada na fila de aprovacoes e sera "
                        "executada apos autorizacao."
                    ),
                    trace_uid=recorder.trace_uid,
                    tokens_in=0,
                    tokens_out=0,
                    cost_usd=0.0,
                    status="awaiting_approval",
                    pending_action_uid=action.uid,
                    tool_calls=executed,
                )

            with recorder.span(
                tool.slug,
                SpanKind.retrieval if tool.kind == "retrieval" else SpanKind.tool,
                input_json={"arguments": call.arguments},
            ) as span:
                try:
                    result = execute_tool(
                        tool,
                        call.arguments,
                        ToolContext(self.db, self.tenant_uid, self.actor_email),
                    )
                    span.output_json = result.payload
                    messages.append(
                        ChatMessage("tool", result.content, name=call.name, tool_call_id=call.id)
                    )
                    executed.append(
                        {"tool": tool.name, "arguments": call.arguments, "ok": True}
                    )
                except ToolError as exc:
                    span.status = "error"
                    span.error = str(exc)
                    recorder.status = "error"
                    messages.append(
                        ChatMessage("tool", f"Erro: {exc}", name=call.name, tool_call_id=call.id)
                    )
                    executed.append(
                        {"tool": tool.name, "arguments": call.arguments, "ok": False,
                         "erro": str(exc)}
                    )
        return None

    # ── aprovacao ─────────────────────────────────────────────────────────────
    def decide_action(
        self, action_uid: str, *, approve: bool, decided_by: str
    ) -> PendingAction:
        """Aprova ou rejeita uma acao retida. Aprovar executa a ferramenta.

        A execucao acontece aqui, e nao no turno original, porque entre a retencao
        e a decisao pode passar tempo indefinido — a acao e o registro duravel do
        que ficou pendente.
        """
        action = self.db.scalar(
            select(PendingAction).where(
                PendingAction.uid == action_uid, PendingAction.tenant_uid == self.tenant_uid
            )
        )
        if action is None:
            raise RuntimeRefusal("Acao nao encontrada neste tenant.")
        if action.status is not ActionStatus.pending:
            estado = action.status.value if hasattr(action.status, "value") else action.status
            raise RuntimeRefusal(f"Acao ja decidida (estado '{estado}').")

        action.decided_by = decided_by
        action.decided_at = datetime.now(UTC)

        if not approve:
            action.status = ActionStatus.rejected
            self.db.commit()
            return action

        tool = self.db.get(Tool, action.tool_uid) if action.tool_uid else None
        if tool is None:
            action.status = ActionStatus.rejected
            action.error = "Ferramenta nao existe mais; a acao nao pode ser executada."
            self.db.commit()
            return action

        try:
            result = execute_tool(
                tool,
                action.arguments_json or {},
                ToolContext(self.db, self.tenant_uid, decided_by),
            )
            action.status = ActionStatus.executed
            action.result_json = result.payload
        except ToolError as exc:
            # Aprovada e falhou na execucao: o estado registra a aprovacao e o erro,
            # para nao parecer que a decisao humana nunca aconteceu.
            action.status = ActionStatus.approved
            action.error = str(exc)

        self.db.commit()
        return action

    def _system_prompt(self, resolved: _Resolved, stage) -> str:
        service = resolved.service
        agent = resolved.agent

        blocos = [
            f"Voce opera o servico '{service.name}' da plataforma VKB da Vanguarda MarTech.",
            service.instruction.strip(),
        ]
        if agent is not None and agent.instruction.strip():
            papel = agent.role or "nao definido"
            blocos.append(f"Papel do agente ({papel}):\n{agent.instruction.strip()}")
        if service.objectives_json:
            objetivos = "\n".join(f"- {item}" for item in service.objectives_json)
            blocos.append(f"Objetivos do servico:\n{objetivos}")
        if stage is not None:
            blocos.append(
                f"Estagio atual: {stage.code} — {stage.name}.\n{stage.instruction}\n"
                f"Condicao de saida: {stage.exit_condition}"
            )
        if resolved.tools:
            nomes = ", ".join(sorted(resolved.tools))
            blocos.append(f"Ferramentas disponiveis: {nomes}.")
        blocos.append(
            f"Classificacao do dado tratado: {service.data_classification}. "
            "Nao invente informacao que nao esteja nas fontes disponiveis; quando "
            "faltar dado, peca ou encaminhe ao humano responsavel."
        )
        return "\n\n".join(bloco for bloco in blocos if bloco)


def _resolve_credential(reference: str | None) -> str | None:
    """Resolve a referencia de credencial para o segredo.

    A plataforma guarda apenas `secret://...`. Um resolvedor de cofre real entra
    aqui; sem ele, nao ha segredo e o provedor cai no adaptador local.
    """
    if not reference:
        return None
    if reference.startswith("secret://"):
        # Integracao com cofre pendente — decisao do discovery de infraestrutura.
        return None
    return reference


def _cost_of(model: LLMModel | None, response: LLMResponse) -> float:
    """Custo do turno, a partir do preco cadastrado do modelo."""
    if model is None:
        return 0.0
    entrada = (response.tokens_in / 1_000) * model.input_cost_per_1k
    saida = (response.tokens_out / 1_000) * model.output_cost_per_1k
    return round(entrada + saida, 6)
