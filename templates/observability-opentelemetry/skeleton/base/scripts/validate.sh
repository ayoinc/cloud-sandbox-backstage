#!/usr/bin/env bash
# Checks collector/config.yaml with the collector itself: unknown components,
# misspelt keys and pipelines that refer to something undefined all fail here.
set -euo pipefail

IMAGE="otel/opentelemetry-collector-contrib:0.165.0"
root="$(cd "$(dirname "$0")/.." && pwd)"

# "validate" resolves environment variables, so each one the configuration
# reads gets a stand-in value.
env_args=()
while IFS= read -r name; do
  env_args+=(--env "$name=http://validate.invalid:4318")
done < <(grep -oE '\$\{env:[A-Z0-9_]+\}' "$root/collector/config.yaml" | sed -E 's/^\$\{env:(.*)\}$/\1/' | sort -u)

docker run --rm "${env_args[@]}" \
  --volume "$root/collector/config.yaml:/etc/otelcol/config.yaml:ro" \
  "$IMAGE" validate --config=/etc/otelcol/config.yaml

echo "collector/config.yaml is valid for $IMAGE"
