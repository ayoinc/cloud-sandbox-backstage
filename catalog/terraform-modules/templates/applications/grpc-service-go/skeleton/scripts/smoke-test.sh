#!/usr/bin/env bash
# Starts the container image and checks over gRPC that the service answers.
#
#   scripts/smoke-test.sh <image>
set -euo pipefail

image="$1"
service="${{ values.pkg }}.v1.${{ values.serviceType }}"
grpcurl_image="fullstorydev/grpcurl:v1.9.3"
container="$(docker run --detach "$image")"
trap 'docker rm --force "$container" > /dev/null' EXIT

# grpcurl shares the network of the service container, so no port is published.
call() { docker run --rm --network "container:$container" "$grpcurl_image" -plaintext "$@"; }

services=""
for _ in $(seq 1 30); do
  if services="$(call 127.0.0.1:50051 list 2>&1)"; then
    break
  fi
  sleep 1
done

if ! grep --quiet --line-regexp "$service" <<< "$services"; then
  echo "The server did not list $service:" >&2
  echo "$services" >&2
  docker logs "$container" >&2
  exit 1
fi
echo "Reflection lists $service"
{% if values.enableHealthChecks %}

status="$(call -d "{\"service\": \"$service\"}" 127.0.0.1:50051 grpc.health.v1.Health/Check)"
if ! grep --quiet '"SERVING"' <<< "$status"; then
  echo "The health check did not report SERVING: $status" >&2
  exit 1
fi
echo "Health check reports SERVING"
{% endif %}
