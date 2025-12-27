#!/bin/bash
# Docker Application Test Script
# This script validates the Docker container build and basic functionality

set -e

IMAGE_NAME="${1:-${{ values.name }}}"
IMAGE_TAG="${2:-latest}"
CONTAINER_PORT="${3:-${{ values.port }}}"

echo "=== Docker Application Tests ==="
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Port: ${CONTAINER_PORT}"
echo ""

# Test 1: Dockerfile lint with hadolint
echo "[TEST 1] Dockerfile Linting (hadolint)"
if command -v hadolint &> /dev/null; then
    hadolint Dockerfile && echo "  PASS: Dockerfile passes linting" || echo "  WARN: Dockerfile has linting issues"
else
    echo "  SKIP: hadolint not installed"
fi

# Test 2: Build the Docker image
echo ""
echo "[TEST 2] Docker Build"
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" . && echo "  PASS: Image built successfully" || exit 1

# Test 3: Check image size
echo ""
echo "[TEST 3] Image Size Check"
IMAGE_SIZE=$(docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "{{.Size}}")
echo "  Image size: ${IMAGE_SIZE}"

# Test 4: Run container and check health
echo ""
echo "[TEST 4] Container Health Check"
CONTAINER_ID=$(docker run -d -p "${CONTAINER_PORT}:${CONTAINER_PORT}" "${IMAGE_NAME}:${IMAGE_TAG}")
echo "  Container ID: ${CONTAINER_ID}"

# Wait for container to start
sleep 5

# Check if container is running
if docker ps -q -f id="${CONTAINER_ID}" | grep -q .; then
    echo "  PASS: Container is running"
else
    echo "  FAIL: Container stopped unexpectedly"
    docker logs "${CONTAINER_ID}"
    docker rm -f "${CONTAINER_ID}" 2>/dev/null
    exit 1
fi

{% if values.includeHealthcheck %}
# Test 5: Health endpoint check
echo ""
echo "[TEST 5] Health Endpoint"
if curl -sf "http://localhost:${CONTAINER_PORT}/health" > /dev/null 2>&1; then
    echo "  PASS: Health endpoint responding"
else
    echo "  WARN: Health endpoint not responding (may not be implemented yet)"
fi
{% endif %}

# Cleanup
echo ""
echo "=== Cleanup ==="
docker stop "${CONTAINER_ID}" && docker rm "${CONTAINER_ID}"
echo "Container removed"

echo ""
echo "=== All Tests Completed ==="
