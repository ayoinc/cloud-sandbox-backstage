#!/usr/bin/env bash
# Checks a running stack (docker compose up -d): every service is healthy,
# Prometheus loaded the alerting rules and reaches Alertmanager, and Grafana
# provisioned the data sources and dashboards.
set -euo pipefail

cd "$(dirname "$0")/.."

PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"
ALERTMANAGER_URL="${ALERTMANAGER_URL:-http://localhost:9093}"
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_ADMIN="${GRAFANA_ADMIN:-admin:admin}"

# expect <description> <expected> <command>...: runs the command every two
# seconds, for up to two minutes, until it prints the expected value. The
# services finish loading their configuration shortly after they start.
expect() {
  local description="$1" expected="$2" actual=""
  shift 2
  for _ in $(seq 1 60); do
    actual="$("$@" 2> /dev/null || true)"
    if [ "$actual" = "$expected" ]; then
      echo "ok: $description"
      return 0
    fi
    sleep 2
  done
  echo "::error::$description: expected '$expected', got '$actual'"
  return 1
}

status() { curl -s -o /dev/null -w '%{http_code}' "$1"; }
rule_groups() { curl -sf "$PROMETHEUS_URL/api/v1/rules" | jq '.data.groups | length'; }
active_alertmanagers() { curl -sf "$PROMETHEUS_URL/api/v1/alertmanagers" | jq '.data.activeAlertmanagers | length'; }
datasources() { curl -sf -u "$GRAFANA_ADMIN" "$GRAFANA_URL/api/datasources" | jq 'length'; }
dashboards() { curl -sf -u "$GRAFANA_ADMIN" "$GRAFANA_URL/api/search?type=dash-db" | jq 'length'; }

expected_groups="$(cat alerts/*.yaml | grep -c '^  - name:')"
expected_dashboards="$(find dashboards -name '*.json' | wc -l | tr -d ' ')"

expect "Prometheus is healthy" 200 status "$PROMETHEUS_URL/-/healthy"
expect "Alertmanager is healthy" 200 status "$ALERTMANAGER_URL/-/healthy"
expect "Grafana is healthy" 200 status "$GRAFANA_URL/api/health"
expect "Prometheus loaded $expected_groups rule group(s)" "$expected_groups" rule_groups
expect "Prometheus sends alerts to Alertmanager" 1 active_alertmanagers
expect "Grafana provisioned 2 data sources" 2 datasources
expect "Grafana provisioned $expected_dashboards dashboard(s)" "$expected_dashboards" dashboards
