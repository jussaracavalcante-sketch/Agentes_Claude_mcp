"""Fixtures dos testes: banco isolado em arquivo temporario e cliente logado."""

from __future__ import annotations

import os
import tempfile
from collections.abc import Iterator

import pytest

# Aponta para um banco descartavel antes de qualquer import que leia settings.
_tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
_tmp.close()
os.environ["DATABASE_URL"] = f"sqlite+pysqlite:///{_tmp.name}"
os.environ["VKB_SECRET_KEY"] = "chave-de-teste"

from fastapi.testclient import TestClient  # noqa: E402

from app.core.config import settings  # noqa: E402
from app.db import seed  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture(scope="session", autouse=True)
def seeded_database() -> Iterator[None]:
    seed.main(reset=True)
    yield
    os.unlink(_tmp.name)


@pytest.fixture(scope="session")
def client() -> Iterator[TestClient]:
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture(scope="session")
def admin_token(client: TestClient) -> str:
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": settings.vkb_seed_admin_email,
            "password": settings.vkb_seed_admin_password,
        },
    )
    assert response.status_code == 200, response.text
    return response.json()["access_token"]


@pytest.fixture(scope="session")
def auth(admin_token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {admin_token}"}


@pytest.fixture(scope="session")
def auditor_auth(client: TestClient) -> dict[str, str]:
    domain = settings.vkb_seed_admin_email.split("@")[-1]
    response = client.post(
        "/api/v1/auth/login",
        json={"email": f"juridico@{domain}", "password": "vanguarda"},
    )
    assert response.status_code == 200, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}
