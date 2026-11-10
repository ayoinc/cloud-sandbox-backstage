.PHONY: help up up-build down down-clean restart-full status \
	infra-up infra-down infra-status \
	devbox devbox-services devbox-services-stop devbox-dev devbox-build devbox-test devbox-lint \
	dev dev-detached dev-logs dev-stop \
	build start stop restart logs prod \
	logs-backstage logs-postgres logs-redis logs-minio logs-nginx \
	health shell shell-postgres shell-redis clean clean-volumes builder builder-reset \
	techdocs techdocs-docker db-backup db-restore \
	test test-all test-e2e lint typecheck format-check format setup install

# Works with Docker Engine and with Apple `container` via the socktainer Docker context.
COMPOSE       := docker compose
COMPOSE_DEV   := docker compose -f docker-compose.yaml -f docker-compose.dev.yaml
COMPOSE_PROD  := docker compose -f docker-compose.yaml -f docker-compose.prod.yaml
COMPOSE_INFRA := docker compose -f docker-compose.services.yaml

# Image builds run in a dedicated BuildKit container sized for the monorepo build
# (Apple `container` gives each container 1 GB by default, which stalls `yarn install`).
# Buildx keys builders by endpoint, so DOCKER_HOST is pinned to the active context's
# endpoint for both `docker buildx` and `docker compose`.
ifndef DOCKER_HOST
DOCKER_HOST := $(shell docker context inspect --format '{{.Endpoints.docker.Host}}' 2>/dev/null)
endif
export DOCKER_HOST
export BUILDX_BUILDER ?= backstage-builder
BUILDER_MEMORY ?= 8g

# Default target
help:
	@echo "Cloud Sandbox Backstage - Available Commands"
	@echo "============================================="
	@echo ""
	@echo "🚀 Quick Start:"
	@echo "  make up               - Build (if needed) and start the full stack, wait until healthy"
	@echo "  make up-build         - Rebuild images, then start the full stack"
	@echo "  make down             - Stop the full stack (preserves data)"
	@echo "  make down-clean       - Stop and remove all data (DESTRUCTIVE)"
	@echo "  make restart-full     - Stop then start the full stack"
	@echo ""
	@echo "🧱 Infrastructure only (Postgres, Redis, MinIO):"
	@echo "  make infra-up         - Start infrastructure services, wait until healthy"
	@echo "  make infra-down       - Stop infrastructure services"
	@echo "  make infra-status     - Show infrastructure service status"
	@echo ""
	@echo "🔧 Devbox Development:"
	@echo "  make devbox           - Enter Devbox shell with all tools"
	@echo "  make devbox-services  - Start services via Devbox"
	@echo "  make devbox-dev       - Start Backstage via Devbox"
	@echo ""
	@echo "🐳 Docker Development:"
	@echo "  make dev              - Start containerised hot-reload development stack"
	@echo "  make dev-logs         - View development logs"
	@echo "  make dev-stop         - Stop development environment"
	@echo ""
	@echo "📦 Production (Docker):"
	@echo "  make build            - Build all Docker images"
	@echo "  make start            - Start all services"
	@echo "  make stop             - Stop all services"
	@echo "  make restart          - Restart all services"
	@echo "  make logs             - View all service logs"
	@echo "  make prod             - Build and start with production overrides"
	@echo ""
	@echo "🔧 Maintenance:"
	@echo "  make health           - Check health of all services"
	@echo "  make status           - Show container status"
	@echo "  make shell            - Open shell in backstage container"
	@echo "  make clean            - Remove all containers and locally built images"
	@echo "  make clean-volumes    - Remove all data volumes (DESTRUCTIVE)"
	@echo "  make builder          - Create the BuildKit builder used for image builds (8 GB)"
	@echo "  make builder-reset    - Recreate the BuildKit builder (fixes 'structure needs cleaning')"
	@echo ""
	@echo "📚 TechDocs:"
	@echo "  make techdocs         - Generate TechDocs locally (Devbox)"
	@echo "  make techdocs-docker  - Generate TechDocs via Docker"
	@echo ""
	@echo "💾 Database:"
	@echo "  make db-backup        - Backup PostgreSQL database"
	@echo "  make db-restore       - Restore from latest backup"
	@echo ""
	@echo "Individual Service Logs:"
	@echo "  make logs-backstage   - View Backstage logs"
	@echo "  make logs-postgres    - View PostgreSQL logs"
	@echo "  make logs-redis       - View Redis logs"
	@echo "  make logs-minio       - View MinIO logs"
	@echo "  make logs-nginx       - View Nginx logs"

# =============================================================================
# Quick Start (Recommended)
# =============================================================================

.env:
	cp .env.example .env
	@echo "Created .env from .env.example - please configure it!"

up: .env builder
	@echo "Starting Backstage Cloud Sandbox..."
	$(COMPOSE) up -d --wait

up-build: .env builder
	@echo "Starting Backstage Cloud Sandbox (rebuild)..."
	$(COMPOSE) up -d --build --wait

down:
	@echo "Stopping Backstage Cloud Sandbox..."
	$(COMPOSE) down --remove-orphans

down-clean:
	@echo "Stopping and removing all data..."
	$(COMPOSE) down -v --remove-orphans

restart-full: down up

status:
	$(COMPOSE) ps -a

infra-up:
	$(COMPOSE_INFRA) up -d --wait

infra-down:
	$(COMPOSE_INFRA) down --remove-orphans

infra-status:
	$(COMPOSE_INFRA) ps -a

# =============================================================================
# Devbox Development (Recommended)
# =============================================================================

devbox:
	@echo "Entering Devbox development shell..."
	@echo "Run 'devbox run services:start' then 'devbox run dev' to start developing"
	devbox shell

devbox-services:
	@echo "Starting Docker services for Devbox development..."
	devbox run services:start

devbox-services-stop:
	@echo "Stopping Docker services..."
	devbox run services:stop

devbox-dev:
	@echo "Starting Backstage in Devbox..."
	devbox run dev

devbox-build:
	@echo "Building backend in Devbox..."
	devbox run build

devbox-test:
	@echo "Running tests in Devbox..."
	devbox run test

devbox-lint:
	@echo "Running linter in Devbox..."
	devbox run lint

# =============================================================================
# Docker Development (Full Container Stack)
# =============================================================================

dev: .env builder
	@echo "Starting development environment (full Docker stack)..."
	$(COMPOSE_DEV) up --build

dev-detached: .env builder
	@echo "Starting development environment (detached)..."
	$(COMPOSE_DEV) up -d --build

dev-logs:
	$(COMPOSE_DEV) logs -f

dev-stop:
	$(COMPOSE_DEV) down --remove-orphans

# =============================================================================
# Production (Docker)
# =============================================================================

build: builder
	@echo "Building Docker images..."
	$(COMPOSE) --profile tools build

start: .env builder
	@echo "Starting all services..."
	$(COMPOSE) up -d --wait

stop:
	@echo "Stopping all services..."
	$(COMPOSE) down --remove-orphans

restart: stop start

logs:
	$(COMPOSE) logs -f

prod: .env build
	@echo "Starting production environment..."
	$(COMPOSE_PROD) up -d --wait

# =============================================================================
# Individual Service Logs
# =============================================================================

logs-backstage:
	$(COMPOSE) logs -f backstage

logs-postgres:
	$(COMPOSE) logs -f postgres

logs-redis:
	$(COMPOSE) logs -f redis

logs-minio:
	$(COMPOSE) logs -f minio

logs-nginx:
	$(COMPOSE) logs -f nginx

# =============================================================================
# Maintenance
# =============================================================================

health:
	@echo "Checking service health..."
	@echo ""
	@echo "Nginx:"
	@curl -sf http://localhost/health && echo " OK" || echo " FAILED"
	@echo ""
	@echo "Backstage:"
	@curl -sf http://localhost:7007/.backstage/health/v1/readiness && echo " OK" || echo " FAILED"
	@echo ""
	@echo "PostgreSQL:"
	@$(COMPOSE) exec -T postgres pg_isready -U backstage && echo " OK" || echo " FAILED"
	@echo ""
	@echo "Redis:"
	@$(COMPOSE) exec -T redis redis-cli ping && echo " OK" || echo " FAILED"
	@echo ""
	@echo "MinIO:"
	@curl -sf http://localhost:9000/minio/health/live && echo " OK" || echo " FAILED"

shell:
	$(COMPOSE) exec backstage /bin/sh

shell-postgres:
	$(COMPOSE) exec postgres psql -U backstage -d backstage

shell-redis:
	$(COMPOSE) exec redis redis-cli

clean:
	@echo "Removing containers and images..."
	$(COMPOSE) --profile tools down --rmi local --remove-orphans
	@echo "Done!"

clean-volumes:
	@echo "WARNING: This will delete all data volumes!"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	$(COMPOSE_DEV) --profile tools down -v --remove-orphans
	@echo "All volumes removed!"

builder:
	@docker buildx inspect $(BUILDX_BUILDER) >/dev/null 2>&1 || \
		docker buildx create --name $(BUILDX_BUILDER) --driver docker-container \
			--driver-opt memory=$(BUILDER_MEMORY) --bootstrap

# Apple `container` stores BuildKit state on an ext4 volume image that can become
# corrupt ("structure needs cleaning"); recreating the builder and its state fixes it.
builder-reset:
	-docker buildx rm $(BUILDX_BUILDER)
	$(MAKE) builder

# =============================================================================
# TechDocs
# =============================================================================

techdocs:
	@echo "Generating TechDocs (requires Devbox or local mkdocs)..."
	./docker/build-techdocs.sh techdocs-output

techdocs-docker: builder
	@echo "Generating TechDocs via Docker..."
	@mkdir -p techdocs-output
	$(COMPOSE) run --rm --build techdocs

# =============================================================================
# Database
# =============================================================================

db-backup:
	@echo "Backing up PostgreSQL database..."
	@mkdir -p backups
	$(COMPOSE) exec -T postgres pg_dump -U backstage backstage > backups/backstage_$$(date +%Y%m%d_%H%M%S).sql
	@echo "Backup saved to backups/"

db-restore:
	@echo "Restoring PostgreSQL database from latest backup..."
	@LATEST=$$(ls -t backups/*.sql 2>/dev/null | head -1); \
	if [ -z "$$LATEST" ]; then echo "No backups found!"; exit 1; fi; \
	$(COMPOSE) exec -T postgres psql -U backstage -d backstage < $$LATEST
	@echo "Database restored!"

# =============================================================================
# Testing & Quality
# =============================================================================

test:
	@echo "Running tests..."
	yarn test

test-all:
	@echo "Running all tests with coverage..."
	yarn test:all

test-e2e:
	@echo "Running E2E tests..."
	yarn test:e2e

lint:
	@echo "Running linter..."
	yarn lint:all

typecheck:
	@echo "Running TypeScript check..."
	yarn tsc --noEmit

format-check:
	@echo "Checking code format..."
	yarn prettier:check

format:
	@echo "Formatting code..."
	yarn prettier --write .

# =============================================================================
# Quick Setup
# =============================================================================

setup:
	@echo "Setting up development environment..."
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env file"; fi
	@echo "Installing dependencies..."
	yarn install
	@echo ""
	@echo "Setup complete! Next steps:"
	@echo "  Option 1 (Devbox - recommended): make devbox"
	@echo "  Option 2 (Docker): make dev"

install:
	@echo "Installing dependencies..."
	yarn install
