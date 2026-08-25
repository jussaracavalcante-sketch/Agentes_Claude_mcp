"""Regras de governanca que a plataforma precisa impor, nao apenas documentar."""

from fastapi.testclient import TestClient


def _novo_servico(client: TestClient, auth, nome: str) -> str:
    response = client.post(
        "/api/v1/services",
        headers=auth,
        json={"name": nome, "type": "task", "description": "Serviço de teste."},
    )
    assert response.status_code == 201, response.text
    return response.json()["uid"]


def test_autonomia_n4_e_vedada(client: TestClient, auth):
    response = client.post(
        "/api/v1/agents",
        headers=auth,
        json={"name": "Agente Irrestrito", "autonomy": "n4_autonomo"},
    )
    assert response.status_code == 422
    assert "N4" in response.json()["detail"]


def test_criador_nao_aprova_a_propria_versao(client: TestClient, auth):
    service_uid = _novo_servico(client, auth, "Segregação de funções")
    version = client.post(
        f"/api/v1/services/{service_uid}/versions", headers=auth, json={"changelog": "v1"}
    ).json()

    response = client.post(f"/api/v1/versions/{version['uid']}/approve", headers=auth)
    assert response.status_code == 403
    assert "Segregacao" in response.json()["detail"]


def test_producao_exige_versao_aprovada(client: TestClient, auth):
    service_uid = _novo_servico(client, auth, "Gate de produção")
    version = client.post(
        f"/api/v1/services/{service_uid}/versions", headers=auth, json={"changelog": "v1"}
    ).json()

    bloqueado = client.post(
        f"/api/v1/versions/{version['uid']}/deploy",
        headers=auth,
        json={"environment": "production"},
    )
    assert bloqueado.status_code == 409

    homologacao = client.post(
        f"/api/v1/versions/{version['uid']}/deploy",
        headers=auth,
        json={"environment": "staging"},
    )
    assert homologacao.status_code == 201


def test_versao_duplicada_e_recusada(client: TestClient, auth):
    service_uid = _novo_servico(client, auth, "Versão duplicada")
    client.post(f"/api/v1/services/{service_uid}/versions", headers=auth, json={"version": "v1"})
    repetida = client.post(
        f"/api/v1/services/{service_uid}/versions", headers=auth, json={"version": "v1"}
    )
    assert repetida.status_code == 409


def test_salvar_versao_limpa_o_rascunho(client: TestClient, auth):
    service_uid = _novo_servico(client, auth, "Ciclo do rascunho")
    assert client.get(f"/api/v1/services/{service_uid}", headers=auth).json()["has_draft"] is True

    client.post(f"/api/v1/services/{service_uid}/versions", headers=auth, json={})
    assert client.get(f"/api/v1/services/{service_uid}", headers=auth).json()["has_draft"] is False

    client.patch(f"/api/v1/services/{service_uid}", headers=auth, json={"description": "mudou"})
    assert client.get(f"/api/v1/services/{service_uid}", headers=auth).json()["has_draft"] is True


def test_escrita_gera_trilha_de_auditoria(client: TestClient, auth):
    _novo_servico(client, auth, "Serviço auditado")
    logs = client.get(
        "/api/v1/security/audit-logs", headers=auth, params={"resource_type": "service"}
    ).json()
    assert any("Serviço auditado" in item["summary"] for item in logs["items"])


def test_export_devolve_pacote_com_checksum(client: TestClient, auth):
    response = client.post(
        "/api/v1/portability/export", headers=auth, json={"scope": ["agents", "skills"]}
    )
    assert response.status_code == 201
    body = response.json()
    assert body["item_count"] > 0
    assert len(body["checksum"]) == 64
    assert "agents" in body["bundle"]
