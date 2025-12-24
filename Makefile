.PHONY: help build start stop restart logs clean dev prod shell test health devbox

# Default target
help:
	@echo "Cloud Sandbox Backstage - Available Commands"
	@echo "============================================="
	@echo ""
	@echo "🚀 Devbox Development (Recommended):"
	@echo "  make devbox           - Enter Devbox shell with all tools"
	@echo "  make devbox-services  - Start services via Devbox"
	@echo "  make devbox-dev       - Start Backstage via Devbox"
	@echo ""
	@echo "🐳 Docker Development:"
	@echo "  make dev              - Start full Docker development environment"
	@echo "  make dev-logs         - View development logs"
	@echo "  make dev-stop         - Stop development environment"
	@echo ""
	@echo "📦 Production (Docker):"
	@echo "  make build            - Build all Docker images"
	@echo "  make start            - Start all services in production mode"
	@echo "  make stop             - Stop all services"
	@echo "  make restart          - Restart all services"
	@echo "  make logs             - View all service logs"
	@echo "  make prod             - Build and start in production mode"
	@echo ""
	@echo "🔧 Maintenance:"
	@echo "  make health           - Check health of all services"
	@echo "  make shell            - Open shell in backstage container"
	@echo "  make clean            - Remove all containers and images"
	@echo "  make clean-volumes    - Remove all data volumes (DESTRUCTIVE)"
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

dev:
	@echo "Starting development environment (full Docker stack)..."
	@if [ ! -f .env ]; then cp .env.example .env; fi
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml -f docker-compose.dev.yaml up --build

dev-detached:
	@echo "Starting development environment (detached)..."
	@if [ ! -f .env ]; then cp .env.example .env; fi
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml -f docker-compose.dev.yaml up -d --build

dev-logs:
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml -f docker-compose.dev.yaml logs -f

dev-stop:
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml -f docker-compose.dev.yaml down

# =============================================================================
# Production (Docker)
# =============================================================================

build:
	@echo "Building Docker images..."
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml build

start:
	@echo "Starting all services..."
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example - please configure it!"; fi
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml up -d

stop:
	@echo "Stopping all services..."
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml down

restart: stop start

logs:
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f

prod: build
	@echo "Starting production environment..."
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example - please configure it!"; fi
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml up -d

# =============================================================================
# Individual Service Logs
# =============================================================================

logs-backstage:
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f backstage

logs-postgres:
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f postgres

logs-redis:
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f redis

logs-minio:
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f minio

logs-nginx:
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f nginx

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
	@curl -sf http://localhost:7007/healthcheck && echo " OK" || echo " FAILED"
	@echo ""
	@echo "PostgreSQL:"
	@docker compose -f docker-compose.yaml -f docker-compose.services.yaml exec -T postgres pg_isready -U backstage && echo " OK" || echo " FAILED"
	@echo ""
	@echo "Redis:"
	@docker compose -f docker-compose.yaml -f docker-compose.services.yaml exec -T redis redis-cli ping && echo " OK" || echo " FAILED"
	@echo ""
	@echo "MinIO:"
	@curl -sf http://localhost:9000/minio/health/live && echo " OK" || echo " FAILED"

shell:
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml exec backstage /bin/sh

shell-postgres:
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml exec postgres psql -U backstage -d backstage

shell-redis:
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml exec redis redis-cli

clean:
	@echo "Removing containers and images..."
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml down --rmi local --remove-orphans
	docker compose -f docker-compose.services-only.yaml down --rmi local --remove-orphans 2>/dev/null || true
	@echo "Done!"

clean-volumes:
	@echo "WARNING: This will delete all data volumes!"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml down -v --remove-orphans
	docker compose -f docker-compose.services-only.yaml down -v --remove-orphans 2>/dev/null || true
	@echo "All volumes removed!"

# =============================================================================
# TechDocs
# =============================================================================

techdocs:
	@echo "Generating TechDocs (requires Devbox or local mkdocs)..."
	@for dir in catalog/*/; do \
		if [ -f "$${dir}mkdocs.yml" ]; then \
			echo "Building TechDocs for $${dir}"; \
			(cd "$${dir}" && mkdocs build -d ../../techdocs-output/$$(basename $${dir})); \
		fi; \
	done
	@echo "TechDocs generation complete!"

techdocs-docker:
	@echo "Generating TechDocs via Docker..."
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml run --rm techdocs

# =============================================================================
# Database
# =============================================================================

db-backup:
	@echo "Backing up PostgreSQL database..."
	@mkdir -p backups
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml exec -T postgres pg_dump -U backstage backstage > backups/backstage_$$(date +%Y%m%d_%H%M%S).sql
	@echo "Backup saved to backups/"

db-restore:
	@echo "Restoring PostgreSQL database from latest backup..."
	@LATEST=$$(ls -t backups/*.sql 2>/dev/null | head -1); \
	if [ -z "$$LATEST" ]; then echo "No backups found!"; exit 1; fi; \
	docker compose -f docker-compose.yaml -f docker-compose.services.yaml exec -T postgres psql -U backstage -d backstage < $$LATEST
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
