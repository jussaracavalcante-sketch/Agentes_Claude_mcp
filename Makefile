# VKB · Vanguarda IA — atalhos de desenvolvimento
.DEFAULT_GOAL := help
API := apps/api
WEB := apps/web
VENV := $(API)/.venv
PY := $(VENV)/bin/python

.PHONY: help setup api web seed reset test lint build up down logs

help: ## Lista os alvos disponíveis
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

setup: ## Instala as dependências da API e do console
	python3 -m venv $(VENV)
	$(VENV)/bin/pip install --upgrade pip
	$(VENV)/bin/pip install -r $(API)/requirements-dev.txt
	cd $(WEB) && npm install

api: ## Sobe a API em http://localhost:8000
	cd $(API) && .venv/bin/python -m uvicorn app.main:app --reload --port 8000

web: ## Sobe o console em http://localhost:5173
	cd $(WEB) && npm run dev

seed: ## Popula o tenant de demonstração
	cd $(API) && .venv/bin/python -m app.db.seed

reset: ## Recria o schema e popula do zero
	cd $(API) && .venv/bin/python -m app.db.seed --reset

test: ## Roda os testes da API
	cd $(API) && .venv/bin/python -m pytest -q

lint: ## Ruff na API e typecheck no console
	cd $(API) && .venv/bin/python -m ruff check app
	cd $(WEB) && npm run lint

build: ## Build de produção do console
	cd $(WEB) && npm run build

up: ## Sobe a stack completa em containers
	docker compose up -d --build

down: ## Derruba a stack
	docker compose down

logs: ## Acompanha os logs da stack
	docker compose logs -f
