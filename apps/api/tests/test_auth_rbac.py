"""Autenticacao, escopo do tenant e controle de acesso por papel."""

from fastapi.testclient import TestClient


def test_health(client: TestClient):
    assert client.get("/health").json()["status"] == "ok"


def test_login_rejeita_senha_errada(client: TestClient):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@vanguardamartech.com.br", "password": "errada"},
    )
    assert response.status_code == 401


def test_rota_protegida_exige_credencial(client: TestClient):
    assert client.get("/api/v1/services").status_code == 401


def test_me_traz_papeis_e_permissoes(client: TestClient, auth):
    body = client.get("/api/v1/auth/me", headers=auth).json()
    assert body["tenant_slug"] == "vanguarda"
    assert "admin" in body["roles"]
    assert "*" in body["permissions"]


def test_auditor_le_mas_nao_escreve(client: TestClient, auditor_auth):
    assert client.get("/api/v1/services", headers=auditor_auth).status_code == 200

    response = client.post(
        "/api/v1/services",
        headers=auditor_auth,
        json={"name": "Tentativa", "type": "task"},
    )
    assert response.status_code == 403
    assert "services:write" in response.json()["detail"]


def test_chave_de_api_invalida_e_recusada(client: TestClient):
    response = client.get("/api/v1/services", headers={"X-API-Key": "vkb_inexistente"})
    assert response.status_code == 401
