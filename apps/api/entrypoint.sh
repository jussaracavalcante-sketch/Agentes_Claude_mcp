#!/bin/sh
# Aplica as migracoes pendentes antes de servir. Idempotente: se o schema ja
# esta na ultima revisao, o upgrade e um no-op.
set -e

echo "→ aplicando migracoes"
alembic upgrade head

echo "→ iniciando aplicacao"
exec "$@"
