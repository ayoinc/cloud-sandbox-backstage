#!/bin/bash
# Backstage Cloud Sandbox - Stack Shutdown Script
#
# Usage: ./scripts/stack-down.sh [--volumes]
#   --volumes   Also remove all data volumes (DESTRUCTIVE)

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
VOLUMES=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --volumes|-v)
      VOLUMES="-v"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Backstage Cloud Sandbox - Stack Shutdown${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

if [ -n "$VOLUMES" ]; then
  echo -e "${RED}WARNING: This will delete all data volumes!${NC}"
  echo "This includes:"
  echo "  - PostgreSQL database (catalog, users, permissions)"
  echo "  - Redis cache"
  echo "  - MinIO storage (TechDocs, scaffolder outputs, log archives)"
  echo "  - OpenSearch indices (logs, dashboards)"
  echo ""
  read -p "Are you sure you want to continue? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo -e "${YELLOW}Stopping all containers...${NC}"
docker compose -f docker-compose.yaml -f docker-compose.services.yaml down $VOLUMES --remove-orphans

echo ""
echo -e "${GREEN}Stack shutdown complete!${NC}"

if [ -n "$VOLUMES" ]; then
  echo -e "${YELLOW}All data volumes have been removed.${NC}"
  echo "Run './scripts/stack-up.sh' to start fresh."
else
  echo "Data volumes preserved. Run './scripts/stack-up.sh' to restart."
fi
