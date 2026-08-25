"""Configuracao da aplicacao, lida de variaveis de ambiente."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=(BASE_DIR.parent.parent / ".env", BASE_DIR / ".env"),
        env_ignore_empty=True,
        extra="ignore",
    )

    app_name: str = "VKB · Vanguarda IA"
    vkb_env: str = "development"
    api_prefix: str = "/api/v1"

    database_url: str = f"sqlite+pysqlite:///{BASE_DIR / 'vkb.db'}"

    vkb_secret_key: str = "troque-esta-chave-em-producao"
    vkb_access_token_ttl_min: int = 480
    vkb_cors_origins: str = "http://localhost:5173,http://localhost:4173"

    vkb_seed_tenant: str = "vanguarda"
    vkb_seed_admin_email: str = "admin@vanguardamartech.com.br"
    vkb_seed_admin_password: str = "vanguarda"

    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.vkb_cors_origins.split(",") if o.strip()]

    @property
    def is_sqlite(self) -> bool:
        return self.database_url.startswith("sqlite")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
