"""Hash de senha, emissao e validacao de token de acesso."""

from __future__ import annotations

import base64
import hashlib
import hmac
import secrets
from datetime import UTC, datetime, timedelta
from typing import Any

from jose import JWTError, jwt

from app.core.config import settings

ALGORITHM = "HS256"
_PBKDF2_ROUNDS = 240_000


def hash_password(password: str) -> str:
    """PBKDF2-SHA256 com sal aleatorio.

    Formato armazenado: pbkdf2$<rounds>$<sal>$<hash>.
    """
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, _PBKDF2_ROUNDS)
    salt_b64 = base64.b64encode(salt).decode()
    digest_b64 = base64.b64encode(digest).decode()
    return f"pbkdf2${_PBKDF2_ROUNDS}${salt_b64}${digest_b64}"


def verify_password(password: str, stored: str) -> bool:
    try:
        scheme, rounds, salt_b64, digest_b64 = stored.split("$")
    except ValueError:
        return False
    if scheme != "pbkdf2":
        return False
    digest = hashlib.pbkdf2_hmac(
        "sha256", password.encode(), base64.b64decode(salt_b64), int(rounds)
    )
    return hmac.compare_digest(digest, base64.b64decode(digest_b64))


def create_access_token(subject: str, claims: dict[str, Any] | None = None) -> str:
    expire = datetime.now(UTC) + timedelta(minutes=settings.vkb_access_token_ttl_min)
    payload: dict[str, Any] = {"sub": subject, "exp": expire, "iat": datetime.now(UTC)}
    payload.update(claims or {})
    return jwt.encode(payload, settings.vkb_secret_key, algorithm=ALGORITHM)


def decode_access_token(token: str) -> dict[str, Any] | None:
    try:
        return jwt.decode(token, settings.vkb_secret_key, algorithms=[ALGORITHM])
    except JWTError:
        return None


def generate_api_key() -> tuple[str, str, str]:
    """Devolve (chave em claro, prefixo visivel, hash armazenado)."""
    raw = f"vkb_{secrets.token_urlsafe(32)}"
    prefix = raw[:12]
    stored = hashlib.sha256(raw.encode()).hexdigest()
    return raw, prefix, stored


def hash_api_key(raw: str) -> str:
    return hashlib.sha256(raw.encode()).hexdigest()
