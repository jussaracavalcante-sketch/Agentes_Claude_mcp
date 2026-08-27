"""Agregador das rotas da versao 1 da API."""

from fastapi import APIRouter

from app.api.v1.routers import (
    analytics,
    auth,
    execution,
    governance,
    lifecycle,
    observability,
    security,
    studio,
)

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(studio.router)
api_router.include_router(observability.router)
api_router.include_router(analytics.router)
api_router.include_router(lifecycle.router)
api_router.include_router(security.router)
api_router.include_router(governance.router)
api_router.include_router(execution.router)
