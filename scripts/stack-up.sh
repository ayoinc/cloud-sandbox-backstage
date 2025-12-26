#!/bin/bash
# Backstage Cloud Sandbox - Full Stack Startup Script
# This script handles the proper startup sequence to avoid the fluentd logging driver chicken-egg problem
#
# Usage: ./scripts/stack-up.sh [--clean] [--build]
#   --clean   Remove all volumes and start fresh
#   --build   Force rebuild of images

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
CLEAN=false
BUILD=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --clean)
      CLEAN=true
      shift
      ;;
    --build)
      BUILD="--build"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Backstage Cloud Sandbox - Stack Startup${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Ensure .env exists
if [ ! -f .env ]; then
  echo -e "${YELLOW}Creating .env from .env.example...${NC}"
  cp .env.example .env
  echo -e "${YELLOW}Please configure .env with your settings!${NC}"
fi

# Clean if requested
if [ "$CLEAN" = true ]; then
  echo -e "${YELLOW}Cleaning up existing containers and volumes...${NC}"
  docker compose -f docker-compose.yaml -f docker-compose.services.yaml down -v --remove-orphans 2>/dev/null || true
  echo -e "${GREEN}Cleanup complete!${NC}"
  echo ""
fi

# Define compose command
COMPOSE="docker compose -f docker-compose.yaml -f docker-compose.services.yaml"

echo -e "${BLUE}Phase 1: Starting Logging Stack (OpenSearch + Fluentd)${NC}"
echo "This must start first so other containers can use the fluentd logging driver..."
echo ""

# Start OpenSearch first (fluentd depends on it)
echo -e "${YELLOW}Starting OpenSearch...${NC}"
$COMPOSE up -d opensearch

# Wait for OpenSearch to be healthy
echo "Waiting for OpenSearch to be healthy..."
timeout=120
elapsed=0
while ! curl -s http://localhost:9200/_cluster/health 2>/dev/null | grep -qE '"status":"(green|yellow)"'; do
  if [ $elapsed -ge $timeout ]; then
    echo -e "${RED}Timeout waiting for OpenSearch!${NC}"
    exit 1
  fi
  echo "  OpenSearch not ready yet... ($elapsed/$timeout seconds)"
  sleep 5
  elapsed=$((elapsed + 5))
done
echo -e "${GREEN}OpenSearch is healthy!${NC}"

# Start Fluentd
echo -e "${YELLOW}Starting Fluentd...${NC}"
$COMPOSE up -d $BUILD fluentd

# Wait for Fluentd to be healthy
echo "Waiting for Fluentd to be healthy..."
timeout=120
elapsed=0
while true; do
  # Check if container is running and healthy
  status=$(docker inspect --format='{{.State.Health.Status}}' backstage-fluentd 2>/dev/null || echo "not_found")
  if [ "$status" = "healthy" ]; then
    echo -e "${GREEN}Fluentd is healthy!${NC}"
    break
  fi
  if [ $elapsed -ge $timeout ]; then
    # Check if at least the container is running
    if docker ps --filter "name=backstage-fluentd" --filter "status=running" | grep -q fluentd; then
      echo -e "${YELLOW}Fluentd health check timed out but container is running, continuing...${NC}"
      break
    else
      echo -e "${RED}Fluentd container is not running!${NC}"
      docker logs backstage-fluentd --tail 20
      exit 1
    fi
  fi
  echo "  Fluentd status: $status ($elapsed/$timeout seconds)"
  sleep 5
  elapsed=$((elapsed + 5))
done

# Start OpenSearch Dashboards
echo -e "${YELLOW}Starting OpenSearch Dashboards...${NC}"
$COMPOSE up -d opensearch-dashboards

echo ""
echo -e "${BLUE}Phase 2: Starting Core Services (PostgreSQL, Redis, MinIO)${NC}"
echo ""

# Start core services (they can now use fluentd logging driver)
echo -e "${YELLOW}Starting PostgreSQL, Redis, MinIO...${NC}"
$COMPOSE up -d postgres redis minio

# Wait for core services to be healthy
echo "Waiting for core services..."

# PostgreSQL
timeout=60
elapsed=0
while ! docker exec backstage-postgres pg_isready -U backstage >/dev/null 2>&1; do
  if [ $elapsed -ge $timeout ]; then
    echo -e "${RED}Timeout waiting for PostgreSQL!${NC}"
    exit 1
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done
echo -e "${GREEN}PostgreSQL is healthy!${NC}"

# Redis
timeout=30
elapsed=0
while ! docker exec backstage-redis redis-cli ping >/dev/null 2>&1; do
  if [ $elapsed -ge $timeout ]; then
    echo -e "${RED}Timeout waiting for Redis!${NC}"
    exit 1
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done
echo -e "${GREEN}Redis is healthy!${NC}"

# MinIO
timeout=30
elapsed=0
while ! curl -sf http://localhost:9000/minio/health/live >/dev/null 2>&1; do
  if [ $elapsed -ge $timeout ]; then
    echo -e "${RED}Timeout waiting for MinIO!${NC}"
    exit 1
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done
echo -e "${GREEN}MinIO is healthy!${NC}"

# Run MinIO initialization
echo -e "${YELLOW}Initializing MinIO buckets...${NC}"
$COMPOSE up minio-init
echo -e "${GREEN}MinIO buckets created!${NC}"

echo ""
echo -e "${BLUE}Phase 3: Starting Backstage Application${NC}"
echo ""

# Start Backstage
echo -e "${YELLOW}Building and starting Backstage...${NC}"
$COMPOSE up -d $BUILD backstage

# Wait for Backstage to be healthy (using docker inspect since port 7007 is not exposed to host)
echo "Waiting for Backstage to be healthy (this may take a minute)..."
timeout=180
elapsed=0
while true; do
  # Check if container is running and healthy using Docker's health check
  status=$(docker inspect --format='{{.State.Health.Status}}' backstage-app 2>/dev/null || echo "not_found")
  if [ "$status" = "healthy" ]; then
    echo -e "${GREEN}Backstage is healthy!${NC}"
    break
  fi
  if [ $elapsed -ge $timeout ]; then
    # Check if at least the container is running
    if docker ps --filter "name=backstage-app" --filter "status=running" | grep -q backstage-app; then
      echo -e "${YELLOW}Backstage health check timed out but container is running, continuing...${NC}"
      break
    else
      echo -e "${RED}Backstage container is not running!${NC}"
      docker logs backstage-app --tail 30
      exit 1
    fi
  fi
  echo "  Backstage status: $status ($elapsed/$timeout seconds)"
  sleep 10
  elapsed=$((elapsed + 10))
done

echo ""
echo -e "${BLUE}Phase 4: Starting Nginx Proxy${NC}"
echo ""

# Start Nginx
echo -e "${YELLOW}Starting Nginx...${NC}"
$COMPOSE up -d nginx

# Wait for Nginx
timeout=30
elapsed=0
while ! curl -sf http://localhost/health >/dev/null 2>&1; do
  if [ $elapsed -ge $timeout ]; then
    echo -e "${RED}Timeout waiting for Nginx!${NC}"
    exit 1
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done
echo -e "${GREEN}Nginx is healthy!${NC}"

echo ""
echo -e "${BLUE}Phase 5: Running OpenSearch Setup${NC}"
echo ""

# Wait for OpenSearch Dashboards to be healthy
echo "Waiting for OpenSearch Dashboards..."
timeout=120
elapsed=0
while ! curl -s http://localhost:5601/api/status 2>/dev/null | grep -q '"state":"green"'; do
  if [ $elapsed -ge $timeout ]; then
    echo -e "${YELLOW}OpenSearch Dashboards taking longer than expected, continuing anyway...${NC}"
    break
  fi
  sleep 5
  elapsed=$((elapsed + 5))
done

# Run OpenSearch setup (creates index patterns, visualizations, dashboards)
echo -e "${YELLOW}Running OpenSearch setup...${NC}"
$COMPOSE up opensearch-setup

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Stack Startup Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Access Points:"
echo "  Backstage:             http://localhost"
echo "  OpenSearch Dashboards: http://localhost:5601"
echo "  OpenSearch API:        http://localhost:9200"
echo "  MinIO Console:         http://localhost:9001"
echo "  PostgreSQL:            localhost:5432"
echo "  Redis:                 localhost:6379"
echo ""
echo "Useful Commands:"
echo "  View logs:     make logs"
echo "  Stop stack:    make stop"
echo "  Check health:  make health"
echo ""
