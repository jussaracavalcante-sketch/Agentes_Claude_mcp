"""Leitura das telas de observabilidade e analytics."""

from fastapi.testclient import TestClient


def test_home_overview(client: TestClient, auth):
    body = client.get("/api/v1/home/overview", headers=auth).json()
    assert body["conversation_services"] > 0
    assert body["task_services"] > 0


def test_monitoramento_por_periodo(client: TestClient, auth):
    for period in ("1D", "7D", "30D", "90D"):
        response = client.get("/api/v1/monitoring", headers=auth, params={"period": period})
        assert response.status_code == 200, period
        assert response.json()["period"] == period


def test_conversas_paginam_e_filtram(client: TestClient, auth):
    page = client.get(
        "/api/v1/conversations", headers=auth, params={"page_size": 5, "page": 1}
    ).json()
    assert len(page["items"]) <= 5
    assert page["total"] >= len(page["items"])

    ativas = client.get("/api/v1/conversations", headers=auth, params={"status": "active"}).json()
    assert all(item["status"] == "active" for item in ativas["items"])


def test_trace_traz_arvore_de_spans_encadeada(client: TestClient, auth):
    listagem = client.get("/api/v1/traces", headers=auth, params={"page_size": 1}).json()
    trace_uid = listagem["items"][0]["uid"]

    detalhe = client.get(f"/api/v1/traces/{trace_uid}", headers=auth).json()
    spans = detalhe["spans"]
    assert len(spans) > 1

    raizes = [span for span in spans if span["parent_uid"] is None]
    assert len(raizes) == 1

    conhecidos = {span["uid"] for span in spans}
    filhos = [span for span in spans if span["parent_uid"] is not None]
    assert filhos, "a arvore precisa ter spans filhos"
    assert all(span["parent_uid"] in conhecidos for span in filhos)

    # A raiz engloba a duracao dos filhos diretos.
    diretos = [span for span in spans if span["parent_uid"] == raizes[0]["uid"]]
    assert raizes[0]["duration_ms"] >= sum(span["duration_ms"] for span in diretos)


def test_analytics_de_servico_e_consumo(client: TestClient, auth):
    resposta = client.get("/api/v1/analytics/services", headers=auth, params={"period": "7D"})
    servicos = resposta.json()
    assert servicos["total_conversations"] >= 0
    assert isinstance(servicos["conversations_per_day"], list)

    consumo = client.get("/api/v1/analytics/llm", headers=auth, params={"period": "30D"}).json()
    assert consumo["tokens_in"] > 0
    assert consumo["cost_usd"] >= 0


def test_trace_de_outro_tenant_nao_vaza(client: TestClient, auth):
    assert client.get("/api/v1/traces/inexistente", headers=auth).status_code == 404
