#!/usr/bin/env bash
# Starts the image and checks it from the outside: the container stays up,
# answers on / and /health and returns 404 for unknown paths.
#
#   bash tests/docker-test.sh [image]
set -euo pipefail

default_image='${{ values.name }}:local'
image="${1:-$default_image}"
port=${{ values.port }}

{%- if values.includeHealthcheck %}

# A short interval makes Docker run the image's HEALTHCHECK soon after start.
container="$(docker run --detach --publish "127.0.0.1::$port" --health-interval=2s "$image")"
{%- else %}

container="$(docker run --detach --publish "127.0.0.1::$port" "$image")"
{%- endif %}
trap 'docker rm --force "$container" > /dev/null' EXIT

fail() {
  echo "FAIL: $1" >&2
  docker logs "$container" >&2
  exit 1
}

# Docker maps the container port to a free port on the host.
address="$(docker port "$container" "$port/tcp" | head -n 1)"

for _ in $(seq 1 30); do
  if curl --fail --silent --output /dev/null "http://$address/health"; then
    break
  fi
  sleep 1
done

curl --fail --silent "http://$address/health" | grep --quiet 'healthy' ||
  fail "/health did not report the service as healthy"
echo "PASS: /health reports healthy"

curl --fail --silent "http://$address/" | grep --quiet '${{ values.name }}' ||
  fail "/ did not return the service name"
echo "PASS: / returns the service name"

status="$(curl --silent --output /dev/null --write-out '%{http_code}' "http://$address/missing")"
[ "$status" = 404 ] || fail "an unknown path returned $status instead of 404"
echo "PASS: unknown paths return 404"
{%- if values.includeHealthcheck %}

health=starting
for _ in $(seq 1 30); do
  health="$(docker inspect --format '{{.State.Health.Status}}' "$container")"
  if [ "$health" = healthy ]; then
    break
  fi
  sleep 1
done
[ "$health" = healthy ] || fail "the HEALTHCHECK of the image reported $health"
echo "PASS: the HEALTHCHECK of the image reports healthy"
{%- endif %}

echo "All checks passed for $image"
