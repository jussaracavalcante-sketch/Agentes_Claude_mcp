"""Expressoes SQL que diferem entre SQLite (dev) e Postgres (producao)."""

from __future__ import annotations

from sqlalchemy import func

from app.core.config import settings


def day_expr(column):
    """Trunca um timestamp para o dia, devolvendo texto YYYY-MM-DD."""
    if settings.is_sqlite:
        return func.strftime("%Y-%m-%d", column)
    return func.to_char(func.date_trunc("day", column), "YYYY-MM-DD")
