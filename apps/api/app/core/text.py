"""Utilitarios de texto."""

from __future__ import annotations

import re
import unicodedata


def slugify(value: str, max_length: int = 160) -> str:
    normalized = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode()
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", normalized).strip("-").lower()
    return slug[:max_length] or "item"


def next_version(current: str | None) -> str:
    """v1 -> v2. Aceita None e formatos nao numericos."""
    if not current:
        return "v1"
    match = re.search(r"(\d+)$", current)
    if not match:
        return "v1"
    return f"v{int(match.group(1)) + 1}"
