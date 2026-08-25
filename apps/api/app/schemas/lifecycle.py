from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel

from app.schemas.common import ORMModel


class DeploymentOut(ORMModel):
    uid: str
    version_uid: str
    environment: str
    status: str
    requested_by: str | None = None
    approved_by: str | None = None
    started_at: datetime | None = None
    finished_at: datetime | None = None
    rollback_of_uid: str | None = None
    notes: str
    created_at: datetime


class VersionOut(ORMModel):
    uid: str
    service_uid: str
    service_name: str = ""
    version: str
    status: str
    is_active: bool
    tags_json: list = []
    changelog: str
    approved_by: str | None = None
    approved_at: datetime | None = None
    created_at: datetime
    created_by: str | None = None


class VersionDetail(VersionOut):
    snapshot_json: dict = {}
    deployments: list[DeploymentOut] = []


class VersionIn(BaseModel):
    version: str | None = None
    changelog: str = ""
    tags: list[str] = []


class DeploymentIn(BaseModel):
    environment: str
    notes: str = ""


class PortabilityJobOut(ORMModel):
    uid: str
    direction: str
    scope_json: list = []
    status: str
    item_count: int
    artifact_uri: str | None = None
    checksum: str | None = None
    message: str
    created_at: datetime
    created_by: str | None = None


class ExportRequest(BaseModel):
    scope: list[str] = ["services", "agents", "skills", "tools", "integrations"]
    service_uids: list[str] = []
