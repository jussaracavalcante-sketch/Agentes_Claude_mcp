"""VKB · Vanguarda IA — camada de orquestracao e governanca de agentes."""

from __future__ import annotations

import logging
import time
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1.router import api_router
from app.core.config import settings
from app.db.session import init_db

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s %(levelname)-8s %(name)s — %(message)s"
)
logger = logging.getLogger("vkb")

@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    if settings.is_sqlite:
        # Em desenvolvimento o schema e criado na subida; em producao use migracoes.
        init_db()
    logger.info("%s iniciado no ambiente %s", settings.app_name, settings.vkb_env)
    yield


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description=(
        "Plataforma corporativa de orquestracao de agentes de IA, automacoes e "
        "integracoes — projeto VKB e Vanguarda IA."
    ),
    docs_url="/docs",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def observability_headers(request: Request, call_next):
    """Mede latencia de cada requisicao — insumo da camada de observabilidade."""
    started = time.perf_counter()
    response = await call_next(request)
    elapsed_ms = (time.perf_counter() - started) * 1000
    response.headers["X-Response-Time-Ms"] = f"{elapsed_ms:.1f}"
    return response


@app.exception_handler(Exception)
async def unhandled_exception(request: Request, exc: Exception):
    logger.exception("Falha nao tratada em %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=500,
        content={"detail": "Erro interno. A ocorrencia foi registrada."},
    )


@app.get("/health", tags=["infra"])
def health() -> dict:
    return {"status": "ok", "app": settings.app_name, "env": settings.vkb_env}


app.include_router(api_router, prefix=settings.api_prefix)
