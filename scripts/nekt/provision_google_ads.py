#!/usr/bin/env python3
"""Provisiona fontes do Google Ads na Nekt, uma por conta do MCC.

O conector do Google Ads aceita um unico `customer_id` por fonte, entao cada
conta do MCC vira uma fonte. O mesmo refresh token serve para todas (fluxo MCC):
a autorizacao OAuth e feita uma vez e reaproveitada.

Segredos NUNCA ficam no codigo nem no JSON — sao lidos do ambiente:

    NEKT_API_KEY            chave da Platform API (app.nekt.ai/settings/api-keys)
    GADS_REFRESH_TOKEN      refresh token OAuth do Google (obtido uma vez)
    GADS_CLIENT_ID          client ID do app OAuth
    GADS_CLIENT_SECRET      client secret do app OAuth
    GADS_DEVELOPER_TOKEN    developer token do Google Ads
    GADS_MCC_ID             ID da conta administradora, 10 digitos sem hifens

Uso:
    python provision_google_ads.py                 # dry-run: mostra o plano
    python provision_google_ads.py --apply         # provisiona de verdade
    python provision_google_ads.py --apply --only 8740065197 1752443056
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

API = "https://api.nekt.ai/api/v1"
ACCOUNTS_FILE = Path(__file__).with_name("google_ads_accounts.json")

# Extracao inicial e janela de reprocessamento. A janela cobre conversoes que
# o Google atribui retroativamente.
START_DATE = "2023-01-01"
LOOKBACK_WINDOW = 7

# Todas as fontes gravam no folder google_ads da camada do cliente (R-001).
FOLDER_NAME = "google_ads"

# Fuso padrao das pipelines da org.
CRON_TIMEZONE = "America/Manaus"

SECRETS = (
    "NEKT_API_KEY",
    "GADS_REFRESH_TOKEN",
    "GADS_CLIENT_ID",
    "GADS_CLIENT_SECRET",
    "GADS_DEVELOPER_TOKEN",
    "GADS_MCC_ID",
)


class NektError(RuntimeError):
    pass


def request(method: str, path: str, api_key: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        f"{API}{path}",
        data=data,
        method=method,
        headers={"x-api-key": api_key, "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        raise NektError(f"{method} {path} -> {exc.code}: {exc.read().decode()[:800]}") from exc


def load_env() -> dict[str, str]:
    missing = [name for name in SECRETS if not os.environ.get(name)]
    if missing:
        sys.exit(
            "Variaveis de ambiente ausentes: "
            + ", ".join(missing)
            + "\nDefina-as antes de rodar. Elas nao devem ser gravadas em arquivo."
        )
    return {name: os.environ[name] for name in SECRETS}


def connector_config(account: dict, env: dict[str, str]) -> dict:
    """Config do conector para uma conta. O refresh token e o mesmo para todas."""
    return {
        "customer_id": account["customer_id"],
        "login_customer_id": env["GADS_MCC_ID"],
        "start_date": START_DATE,
        "lookback_window": LOOKBACK_WINDOW,
        "developer_token": env["GADS_DEVELOPER_TOKEN"],
        "oauth_credentials": {
            "client_id": env["GADS_CLIENT_ID"],
            "client_secret": env["GADS_CLIENT_SECRET"],
            "refresh_token": env["GADS_REFRESH_TOKEN"],
        },
    }


def resolve_layers(api_key: str) -> dict[str, str]:
    """slug da camada -> uuid."""
    layers = request("GET", "/layers/", api_key).get("results", [])
    return {layer["slug"]: layer["id"] for layer in layers}


def existing_customer_ids(api_key: str) -> set[str]:
    """customer_ids que ja tem fonte google-ads, para o script ser idempotente."""
    found: set[str] = set()
    path = "/sources/?page_size=100"
    while path:
        page = request("GET", path, api_key)
        for src in page.get("results", []):
            if src.get("oauth_type") != "tap-google-ads" or src.get("archived"):
                continue
            cid = (src.get("connector_config") or {}).get("customer_id")
            if cid:
                found.add(str(cid).replace("-", ""))
        nxt = page.get("next")
        path = nxt.split("/api/v1", 1)[1] if nxt else None
    return found


def validate(account: dict, env: dict[str, str]) -> dict:
    """Dispara a validacao e aguarda ate o catalogo de streams voltar."""
    started = request(
        "POST",
        "/sources/connectors/google-ads/validate/",
        env["NEKT_API_KEY"],
        {"config": connector_config(account, env)},
    )
    validation_id = started.get("id") or started.get("validation_id")
    if not validation_id:
        raise NektError(f"validacao sem id: {started}")

    for _ in range(40):  # ate ~10 min
        time.sleep(15)
        status = request("GET", f"/sources/validations/{validation_id}/", env["NEKT_API_KEY"])
        state = status.get("status")
        if state == "success":
            return {"validation_id": validation_id, "streams": status.get("streams", [])}
        if state == "failed":
            raise NektError(f"validacao falhou: {status.get('error') or status}")
    raise NektError("validacao nao concluiu no tempo limite")


def build_streams(catalog: list[dict], prefix: str) -> list[dict]:
    """Habilita todos os streams do catalogo, preservando chaves e tipo de sync."""
    streams = []
    for item in catalog:
        name = item.get("stream") or item.get("stream_name")
        supported = item.get("sync_type") or []
        sync = "INCREMENTAL" if "INCREMENTAL" in supported else "FULL_SYNC"
        streams.append(
            {
                "enabled": True,
                "stream_name": name,
                "table_name": f"{prefix}{name}",
                "primary_keys": item.get("primary_keys") or [],
                "sync_type": sync,
                "extract_all_fields": True,
            }
        )
    return streams


def create_source(account: dict, env: dict[str, str], layer_id: str, cron: str) -> dict:
    result = validate(account, env)
    streams = build_streams(result["streams"], account["table_prefix"])
    if not streams:
        raise NektError("validacao nao retornou nenhum stream")

    payload = {
        "description": f"Google Ads - {account['cliente']} ({account['nome_plataforma']}) - customer {account['customer_id']}",
        "connector_slug": "google-ads",
        "connector_config": connector_config(account, env),
        "connector_validation": result["validation_id"],
        "output_layer": layer_id,
        "folder": {"folder_name": FOLDER_NAME},
        "trigger": {"type": "scheduled", "cron": cron, "timezone": CRON_TIMEZONE},
        "streams": streams,
    }
    return request("POST", "/sources/", env["NEKT_API_KEY"], payload)


def spread_cron(index: int) -> str:
    """Distribui as extracoes de 10 em 10 min a partir das 06:00, para nao
    concentrar dezenas de fontes no mesmo minuto."""
    minute = (index * 10) % 60
    hour = 6 + (index * 10) // 60
    return f"{minute} {hour} * * *"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="provisiona de verdade (padrao e dry-run)")
    parser.add_argument("--only", nargs="*", metavar="CUSTOMER_ID", help="restringe a estes customer_ids")
    args = parser.parse_args()

    data = json.loads(ACCOUNTS_FILE.read_text())
    accounts = data["contas"]
    if args.only:
        wanted = {c.replace("-", "") for c in args.only}
        accounts = [a for a in accounts if a["customer_id"] in wanted]

    env = load_env()
    layers = resolve_layers(env["NEKT_API_KEY"])
    ja_existem = existing_customer_ids(env["NEKT_API_KEY"])

    prontas, bloqueadas, ignoradas = [], [], []
    for account in accounts:
        slug = account.get("layer_slug")
        if account["customer_id"] in ja_existem:
            ignoradas.append((account, "ja possui fonte google-ads"))
        elif not slug:
            bloqueadas.append((account, "catalogo do cliente nao definido (R-001)"))
        elif slug not in layers:
            bloqueadas.append((account, f"camada '{slug}' nao existe na Nekt"))
        else:
            prontas.append(account)

    print(f"contas no mapeamento : {len(accounts)}")
    print(f"prontas para provisionar: {len(prontas)}")
    print(f"bloqueadas             : {len(bloqueadas)}")
    print(f"ja provisionadas       : {len(ignoradas)}\n")

    for account, motivo in bloqueadas:
        print(f"  BLOQUEADA  {account['customer_id']}  {account['cliente']:<32} {motivo}")
    for account, motivo in ignoradas:
        print(f"  IGNORADA   {account['customer_id']}  {account['cliente']:<32} {motivo}")
    for i, account in enumerate(prontas):
        print(
            f"  PRONTA     {account['customer_id']}  {account['cliente']:<32}"
            f" -> {account['layer_slug']}/{FOLDER_NAME}  prefixo={account['table_prefix']}  cron={spread_cron(i)}"
        )

    if not args.apply:
        print("\nDry-run. Rode com --apply para provisionar.")
        return 0
    if not prontas:
        print("\nNada a provisionar.")
        return 0

    print()
    falhas = 0
    for i, account in enumerate(prontas):
        rotulo = f"{account['customer_id']} {account['cliente']}"
        try:
            created = create_source(account, env, layers[account["layer_slug"]], spread_cron(i))
            print(f"  OK    {rotulo} -> {created.get('slug')}")
        except NektError as exc:
            falhas += 1
            print(f"  FALHA {rotulo}: {exc}")

    print(f"\nprovisionadas: {len(prontas) - falhas}  falhas: {falhas}")
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
