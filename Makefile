.PHONY: help build start stop restart logs clean dev prod shell test health

# Default target
help:
	@echo "Cloud Sandbox Backstage - Available Commands"
	@echo "============================================="
	@echo ""
	@echo "Development:"
	@echo "  make dev          - Start development environment with hot reload"
	@echo "  make dev-logs     - View development logs"
	@echo ""
	@echo "Production:"
	@echo "  make build        - Build all Docker images"
	@echo "  make start        - Start all services in production mode"
	@echo "  make stop         - Stop all services"
	@echo "  make restart      - Restart all services"
	@echo "  make logs         - View all service logs"
	@echo "  make prod         - Build and start in production mode"
	@echo ""
	@echo "Maintenance:"
	@echo "  make health       - Check health of all services"
	@echo "  make shell        - Open shell in backstage container"
	@echo "  make clean        - Remove all containers, volumes, and images"
	@echo "  make clean-volumes - Remove all data volumes (DESTRUCTIVE)"
	@echo ""
	@echo "Individual Services:"
	@echo "  make logs-backstage  - View Backstage logs"
	@echo "  make logs-postgres   - View PostgreSQL logs"
	@echo "  make logs-redis      - View Redis logs"
	@echo "  make logs-rabbitmq   - View RabbitMQ logs"
	@echo "  make logs-minio      - View MinIO logs"
	@echo "  make logs-nginx      - View Nginx logs"

# =============================================================================
# Development
# =============================================================================

dev:
	@echo "Starting development environment..."
	@if [ ! -f .env ]; then cp .env.example .env; fi
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml -f docker-compose.dev.yaml up --build

dev-logs:
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml -f docker-compose.dev.yaml logs -f

dev-stop:
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml -f docker-compose.dev.yaml down

# =============================================================================
# Production
# =============================================================================

build:
	@echo "Building Docker images..."
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml build

start:
	@echo "Starting all services..."
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example - please configure it!"; fi
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml up -d

stop:
	@echo "Stopping all services..."
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml down

restart: stop start

logs:
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f

prod: build
	@echo "Starting production environment..."
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example - please configure it!"; fi
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml -f docker-compose.prod.yaml up -d

# =============================================================================
# Individual Service Logs
# =============================================================================

logs-backstage:
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f backstage

logs-postgres:
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f postgres

logs-redis:
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f redis

logs-rabbitmq:
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f rabbitmq

logs-minio:
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f minio

logs-nginx:
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f nginx

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
	@docker-compose -f docker-compose.yaml -f docker-compose.services.yaml exec -T postgres pg_isready -U backstage && echo " OK" || echo " FAILED"
	@echo ""
	@echo "Redis:"
	@docker-compose -f docker-compose.yaml -f docker-compose.services.yaml exec -T redis redis-cli ping && echo " OK" || echo " FAILED"
	@echo ""
	@echo "RabbitMQ:"
	@docker-compose -f docker-compose.yaml -f docker-compose.services.yaml exec -T rabbitmq rabbitmq-diagnostics -q ping && echo " OK" || echo " FAILED"
	@echo ""
	@echo "MinIO:"
	@curl -sf http://localhost:9000/minio/health/live && echo " OK" || echo " FAILED"

shell:
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml exec backstage /bin/sh

shell-postgres:
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml exec postgres psql -U backstage -d backstage

shell-redis:
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml exec redis redis-cli

clean:
	@echo "Removing containers and images..."
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml down --rmi local --remove-orphans
	@echo "Done!"

clean-volumes:
	@echo "WARNING: This will delete all data volumes!"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml down -v --remove-orphans
	@echo "All volumes removed!"

# =============================================================================
# TechDocs
# =============================================================================

techdocs-generate:
	@echo "Generating TechDocs..."
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml run --rm techdocs

# =============================================================================
# Database
# =============================================================================

db-backup:
	@echo "Backing up PostgreSQL database..."
	@mkdir -p backups
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml exec -T postgres pg_dump -U backstage backstage > backups/backstage_$$(date +%Y%m%d_%H%M%S).sql
	@echo "Backup saved to backups/"

db-restore:
	@echo "Restoring PostgreSQL database from latest backup..."
	@LATEST=$$(ls -t backups/*.sql 2>/dev/null | head -1); \
	if [ -z "$$LATEST" ]; then echo "No backups found!"; exit 1; fi; \
	docker-compose -f docker-compose.yaml -f docker-compose.services.yaml exec -T postgres psql -U backstage -d backstage < $$LATEST
	@echo "Database restored!"
