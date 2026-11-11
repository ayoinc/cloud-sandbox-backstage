#!/usr/bin/env bash
# Runs the collector with the real configuration, sends traces, metrics and
# logs through it, and checks that they arrive at a stand-in backend.
set -euo pipefail

TELEMETRYGEN="ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.165.0"
root="$(cd "$(dirname "$0")/.." && pwd)"
compose=(docker compose --file "$root/test/docker-compose.yaml")
project="$(basename "$root")"

cleanup() {
  status=$?
  if [ "$status" -ne 0 ]; then
    echo "--- collector logs" >&2
    "${compose[@]}" logs --tail 60 collector >&2 || true
  fi
  "${compose[@]}" down --volumes --timeout 5 >/dev/null 2>&1 || true
  exit "$status"
}
trap cleanup EXIT

"${compose[@]}" up --detach --wait-timeout 60

echo "Waiting for the collector to be healthy"
for _ in $(seq 1 30); do
  if curl --fail --silent --output /dev/null http://127.0.0.1:13133/; then
    healthy=1
    break
  fi
  sleep 1
done
[ "${healthy:-0}" = 1 ] || { echo "The collector did not become healthy" >&2; exit 1; }

network="$("${compose[@]}" ps --format '{{.Networks}}' collector | head -n 1)"
generate() {
  if ! output="$(docker run --rm --network "$network" "$TELEMETRYGEN" "$@" \
    --otlp-endpoint collector:4317 --otlp-insecure 2>&1)"; then
    echo "$output" >&2
    echo "telemetrygen $1 failed" >&2
    return 1
  fi
}

echo "Sending telemetry"
generate traces --traces 5 --service "$project-smoke" --status-code Error \
  --telemetry-attributes 'http.request.header.authorization="Bearer leaked"'
generate metrics --metrics 5 --service "$project-smoke"
generate logs --logs 5 --service "$project-smoke" --body "smoke test log"

# Batches are sent after at most five seconds; tail sampling, when enabled,
# decides ten seconds after the first span of a trace.
expect() {
  description="$1"
  shift
  for _ in $(seq 1 40); do
    if "$@" >/dev/null 2>&1; then
      echo "ok    $description"
      return 0
    fi
    sleep 1
  done
  echo "FAIL  $description" >&2
  return 1
}
# grep reads the whole log (--count, not --quiet): stopping early would break
# the pipe and, with pipefail, fail the check.
sink_has() { "${compose[@]}" logs --no-color sink 2>/dev/null | grep --count -- "$1" >/dev/null; }

expect "traces reach the backend" sink_has 'Span #0'
expect "logs reach the backend" sink_has 'smoke test log'
expect "telemetry carries the environment" sink_has 'deployment.environment.name: Str(smoke-test)'
if "${compose[@]}" config --services | grep --count '^prometheus$' >/dev/null; then
  expect "metrics reach the remote-write endpoint" \
    sh -c "curl --fail --silent 'http://127.0.0.1:19090/api/v1/label/__name__/values' | grep --quiet '\"gen'"
else
  expect "metrics reach the backend" sink_has 'Metric #0'
fi
if grep --quiet 'attributes/scrub' "$root/collector/config.yaml"; then
  if sink_has 'Bearer leaked'; then
    echo "FAIL  a captured authorization header reached the backend" >&2
    exit 1
  fi
  echo "ok    captured credentials are removed"
fi

echo "Smoke test passed"
