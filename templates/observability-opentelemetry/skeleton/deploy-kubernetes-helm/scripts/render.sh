#!/usr/bin/env bash
# Prints the manifests the chart produces from helm/values.yaml and
# collector/config.yaml. Extra arguments go to "helm template".
set -euo pipefail

CHART_VERSION="0.178.3"
RELEASE="${{ values.name }}"
NAMESPACE="${{ values.namespace }}"
root="$(cd "$(dirname "$0")/.." && pwd)"

# The collector configuration becomes the chart value "alternateConfig".
config_values="$(mktemp)"
trap 'rm -f "$config_values"' EXIT
{
  echo "alternateConfig:"
  sed 's/^/  /' "$root/collector/config.yaml"
} > "$config_values"

helm template "$RELEASE" opentelemetry-collector \
  --repo https://open-telemetry.github.io/opentelemetry-helm-charts \
  --version "$CHART_VERSION" \
  --namespace "$NAMESPACE" \
  --values "$root/helm/values.yaml" \
  --values "$config_values" \
  "$@"
