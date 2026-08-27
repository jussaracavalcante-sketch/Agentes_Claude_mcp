"""Engine, sessao e dependencia de banco."""

from __future__ import annotations

from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings

connect_args = {"check_same_thread": False} if settings.is_sqlite else {}

engine = create_engine(
    settings.database_url,
    connect_args=connect_args,
    pool_pre_ping=not settings.is_sqlite,
    future=True,
)

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)


def get_db() -> Iterator[Session]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    """Cria o schema direto do metadata.

    Atalho de desenvolvimento e de teste. Em qualquer ambiente compartilhado o
    caminho e `alembic upgrade head` (`make migrate`), que preserva os dados.
    """
    from app.models import Base  # noqa: F401  (garante o registro dos modelos)

    Base.metadata.create_all(bind=engine)
