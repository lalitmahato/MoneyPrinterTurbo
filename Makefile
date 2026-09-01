.DEFAULT_GOAL := help

PYTHON ?= 3.11
ARGS ?=

.PHONY: help sync install config webui api cli test lint coverage clean \
	docker-up docker-down docker-release docker-release-down

help: ## Show available targets
	@echo "MoneyPrinterTurbo Makefile"
	@echo ""
	@echo "Usage: make <target> [ARGS=...]"
	@echo ""
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-20s %s\n", $$1, $$2}'

sync: ## Install Python $(PYTHON) and sync dependencies with uv
	uv python install $(PYTHON)
	uv sync --frozen --python $(PYTHON)

install: sync ## Alias for sync

config: ## Create config.toml from config.example.toml if missing
	@if [ ! -f config.toml ]; then \
		cp config.example.toml config.toml; \
		echo "Created config.toml from config.example.toml"; \
	else \
		echo "config.toml already exists"; \
	fi

webui: ## Start the Streamlit WebUI (honors MPT_WEBUI_HOST / MPT_WEBUI_PORT)
	sh webui.sh

api: ## Start the FastAPI service (http://127.0.0.1:8080/docs)
	uv run python main.py

cli: ## Run the CLI (example: make cli ARGS='--video-subject "Your topic"')
	uv run python cli.py $(ARGS)

test: ## Run the test suite
	uv run python -X utf8 -m pytest -q test $(ARGS)

lint: ## Lint Python sources with ruff
	uv run ruff check app cli.py main.py webui test

coverage: ## Run tests with branch coverage and print the report
	uv run python -X utf8 -m coverage run -m pytest -q test
	uv run python -m coverage report

clean: ## Remove test and coverage artifacts
	rm -rf .pytest_cache .coverage coverage.xml
	find . -type d -name __pycache__ -prune -exec rm -rf {} +

build: ## Build and start local Docker services
	docker compose -f docker-compose.yml up --build -d

up: ## Build and start local Docker services
	docker compose -f docker-compose.yml up -d

down: ## Stop local Docker services
	docker compose -f docker-compose.yml down

prod-build: ## Build production Docker services from GHCR image
	docker compose -f docker-compose.release.yml up --build -d

prod_up: config ## Start production Docker services from GHCR image
	docker compose -f docker-compose.release.yml up -d

prod-down: ## Stop production Docker services
	docker compose -f docker-compose.release.yml down
