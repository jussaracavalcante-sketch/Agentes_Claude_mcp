"""Execucao: turno conversacional, gate de autonomia, aprovacao e trace real."""

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.db.session import SessionLocal
from app.models import Agent, AgentTool, AutonomyLevel, ServiceType, Tool


def _uid_de_servico(client: TestClient, auth, tipo: str) -> str:
    servicos = client.get(f"/api/v1/services?type={tipo}", headers=auth).json()
    assert servicos, f"o seed precisa ter servico do tipo {tipo}"
    return servicos[0]["uid"]


def _preparar_agente(*, autonomia: AutonomyLevel, aprovacao: bool) -> None:
    """Ajusta o supervisor e a ferramenta de recuperacao para o cenario."""
    db = SessionLocal()
    try:
        agente = db.scalar(select(Agent).where(Agent.role == "roteador"))
        ferramenta = db.scalar(select(Tool).where(Tool.kind == "retrieval"))
        agente.autonomy = autonomia
        ferramenta.requires_approval = aprovacao
        if not any(link.tool_uid == ferramenta.uid for link in agente.tools):
            db.add(AgentTool(agent_uid=agente.uid, tool_uid=ferramenta.uid))
        db.commit()
    finally:
        db.close()


def test_turno_simples_devolve_resposta_e_trace(client: TestClient, auth):
    uid = _uid_de_servico(client, auth, "conversation")
    resposta = client.post(
        f"/api/v1/services/{uid}/run", headers=auth, json={"message": "Bom dia."}
    )
    assert resposta.status_code == 200, resposta.text
    corpo = resposta.json()

    assert corpo["status"] == "ok"
    assert corpo["text"]
    assert corpo["conversation_uid"]
    assert corpo["tokens_in"] > 0

    trace = client.get(f"/api/v1/traces/{corpo['trace_uid']}", headers=auth)
    assert trace.status_code == 200
    spans = trace.json()["spans"]
    assert len(spans) >= 3
    assert sum(1 for span in spans if span["parent_uid"] is None) == 1


def test_execucao_local_nao_cobra_e_declara_o_adaptador(client: TestClient, auth):
    """Sem credencial o motor cai no adaptador local — e o trace precisa dizer isso.

    Registrar o provedor configurado, e nao o que executou, inflaria o FinOps e
    mentiria na observabilidade.
    """
    uid = _uid_de_servico(client, auth, "conversation")
    corpo = client.post(
        f"/api/v1/services/{uid}/run", headers=auth, json={"message": "Teste."}
    ).json()

    assert corpo["provider"] == "echo"
    assert corpo["cost_usd"] == 0.0

    spans = client.get(f"/api/v1/traces/{corpo['trace_uid']}", headers=auth).json()["spans"]
    span_modelo = next(span for span in spans if span["kind"] == "model")
    assert span_modelo["metadata_json"]["execucao_local"] is True
    assert span_modelo["metadata_json"]["provedor_configurado"]


def test_historico_mantem_a_mesma_conversa(client: TestClient, auth):
    uid = _uid_de_servico(client, auth, "conversation")
    primeiro = client.post(
        f"/api/v1/services/{uid}/run", headers=auth, json={"message": "Primeira."}
    ).json()
    segundo = client.post(
        f"/api/v1/services/{uid}/run",
        headers=auth,
        json={"message": "Segunda.", "conversation_uid": primeiro["conversation_uid"]},
    ).json()

    assert segundo["conversation_uid"] == primeiro["conversation_uid"]
    detalhe = client.get(
        f"/api/v1/conversations/{primeiro['conversation_uid']}", headers=auth
    ).json()
    assert len(detalhe["messages"]) == 4


def test_autonomia_n0_retem_a_acao(client: TestClient, auth):
    _preparar_agente(autonomia=AutonomyLevel.n0_sugere, aprovacao=False)
    uid = _uid_de_servico(client, auth, "conversation")

    corpo = client.post(
        f"/api/v1/services/{uid}/run",
        headers=auth,
        json={"message": 'consulta [[usar: buscar_no_conhecimento {"query":"prazo Manaus"}]]'},
    ).json()

    assert corpo["status"] == "awaiting_approval"
    assert corpo["pending_action_uid"]

    fila = client.get("/api/v1/approvals", headers=auth).json()
    assert any(item["uid"] == corpo["pending_action_uid"] for item in fila)


def test_ferramenta_com_aprovacao_vence_autonomia_alta(client: TestClient, auth):
    """Marca na ferramenta tem precedencia sobre a autonomia do agente."""
    _preparar_agente(autonomia=AutonomyLevel.n3_executa_irreversivel, aprovacao=True)
    uid = _uid_de_servico(client, auth, "conversation")

    corpo = client.post(
        f"/api/v1/services/{uid}/run",
        headers=auth,
        json={"message": 'consulta [[usar: buscar_no_conhecimento {"query":"prazo"}]]'},
    ).json()
    assert corpo["status"] == "awaiting_approval"
    assert "exige aprovacao humana" in corpo["text"]


def test_autonomia_n2_executa_a_ferramenta(client: TestClient, auth):
    _preparar_agente(autonomia=AutonomyLevel.n2_executa_reversivel, aprovacao=False)
    uid = _uid_de_servico(client, auth, "conversation")

    corpo = client.post(
        f"/api/v1/services/{uid}/run",
        headers=auth,
        json={
            "message": 'consulta [[usar: buscar_no_conhecimento '
            '{"query":"prazo de veiculacao Manaus"}]]'
        },
    ).json()

    assert corpo["status"] == "ok"
    assert corpo["pending_action_uid"] is None
    assert corpo["tool_calls"] and corpo["tool_calls"][0]["ok"] is True
    assert "Manaus" in corpo["text"]

    spans = client.get(f"/api/v1/traces/{corpo['trace_uid']}", headers=auth).json()["spans"]
    assert any(span["kind"] == "retrieval" for span in spans)


def test_aprovar_executa_a_ferramenta_retida(client: TestClient, auth):
    _preparar_agente(autonomia=AutonomyLevel.n0_sugere, aprovacao=False)
    uid = _uid_de_servico(client, auth, "conversation")
    corpo = client.post(
        f"/api/v1/services/{uid}/run",
        headers=auth,
        json={"message": 'x [[usar: buscar_no_conhecimento {"query":"verba minima"}]]'},
    ).json()
    acao = corpo["pending_action_uid"]

    decidida = client.post(
        f"/api/v1/approvals/{acao}/decide", headers=auth, json={"approve": True}
    )
    assert decidida.status_code == 200, decidida.text
    corpo_decidido = decidida.json()
    assert corpo_decidido["status"] == "executed"
    assert corpo_decidido["decided_by"]
    assert corpo_decidido["result_json"].get("hits", 0) > 0


def test_acao_nao_pode_ser_decidida_duas_vezes(client: TestClient, auth):
    _preparar_agente(autonomia=AutonomyLevel.n0_sugere, aprovacao=False)
    uid = _uid_de_servico(client, auth, "conversation")
    corpo = client.post(
        f"/api/v1/services/{uid}/run",
        headers=auth,
        json={"message": 'x [[usar: buscar_no_conhecimento {"query":"prazo"}]]'},
    ).json()
    acao = corpo["pending_action_uid"]

    client.post(f"/api/v1/approvals/{acao}/decide", headers=auth, json={"approve": False})
    repetida = client.post(
        f"/api/v1/approvals/{acao}/decide", headers=auth, json={"approve": True}
    )
    assert repetida.status_code == 409


def test_aprovar_exige_permissao(client: TestClient, auditor_auth, auth):
    _preparar_agente(autonomia=AutonomyLevel.n0_sugere, aprovacao=False)
    uid = _uid_de_servico(client, auth, "conversation")
    corpo = client.post(
        f"/api/v1/services/{uid}/run",
        headers=auth,
        json={"message": 'x [[usar: buscar_no_conhecimento {"query":"prazo"}]]'},
    ).json()

    negada = client.post(
        f"/api/v1/approvals/{corpo['pending_action_uid']}/decide",
        headers=auditor_auth,
        json={"approve": True},
    )
    assert negada.status_code == 403
    assert "runtime:approve" in negada.json()["detail"]


def test_executar_exige_permissao(client: TestClient, auditor_auth, auth):
    uid = _uid_de_servico(client, auth, "conversation")
    negada = client.post(
        f"/api/v1/services/{uid}/run", headers=auditor_auth, json={"message": "oi"}
    )
    assert negada.status_code == 403


def test_task_nao_aceita_turno_conversacional(client: TestClient, auth):
    uid = _uid_de_servico(client, auth, "task")
    resposta = client.post(
        f"/api/v1/services/{uid}/run", headers=auth, json={"message": "oi"}
    )
    assert resposta.status_code == 409


def test_run_task_registra_execucao(client: TestClient, auth):
    uid = _uid_de_servico(client, auth, "task")
    resposta = client.post(
        f"/api/v1/services/{uid}/run-task",
        headers=auth,
        json={"input": {"lote": 1}, "note": "Processar o lote 1."},
    )
    assert resposta.status_code == 200, resposta.text
    corpo = resposta.json()
    assert corpo["trace_uid"]

    tarefas = client.get("/api/v1/tasks", headers=auth, params={"page_size": 5}).json()
    assert any(item["trigger"] == "manual" for item in tarefas["items"])


def test_orcamento_com_bloqueio_duro_impede_execucao(client: TestClient, auth):
    """Um limite ja estourado com `hard_stop` recusa a execucao."""
    uid = _uid_de_servico(client, auth, "conversation")
    criada = client.post(
        "/api/v1/finops/budgets",
        headers=auth,
        json={
            "scope": "service",
            "scope_uid": uid,
            "limit_usd": 0.0,
            "hard_stop": True,
            "alert_at_percent": 50,
        },
    )
    assert criada.status_code == 201, criada.text

    bloqueada = client.post(
        f"/api/v1/services/{uid}/run", headers=auth, json={"message": "oi"}
    )
    assert bloqueada.status_code == 409
    assert "Limite de consumo" in bloqueada.json()["detail"]

    client.delete(f"/api/v1/finops/budgets/{criada.json()['uid']}", headers=auth)


def test_servico_de_outro_tenant_nao_executa(client: TestClient, auth):
    resposta = client.post(
        "/api/v1/services/inexistente/run", headers=auth, json={"message": "oi"}
    )
    assert resposta.status_code == 404


def test_seed_tem_servico_de_cada_tipo(client: TestClient, auth):
    servicos = client.get("/api/v1/services", headers=auth).json()
    tipos = {servico["type"] for servico in servicos}
    assert tipos == {tipo.value for tipo in ServiceType}
