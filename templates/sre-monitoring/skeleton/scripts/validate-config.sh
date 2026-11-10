#!/usr/bin/env bash
# Validates the monitoring configuration with the tools shipped in the images
# that docker-compose.yaml runs, so the checks match the deployed versions:
# the Compose file itself, the Prometheus configuration and alerting rules
# (promtool) and the Alertmanager configuration (amtool).
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Docker Compose file"
docker compose config --quiet

echo "==> Prometheus configuration"
docker compose run --rm --no-deps --entrypoint promtool prometheus \
  check config /etc/prometheus/prometheus.yml

echo "==> Prometheus alerting rules"
docker compose run --rm --no-deps --entrypoint sh prometheus \
  -c 'promtool check rules /etc/prometheus/rules/*.yaml'

echo "==> Alertmanager configuration"
docker compose run --rm --no-deps --entrypoint amtool alertmanager \
  check-config /etc/alertmanager/alertmanager.yml

echo "Configuration is valid"
