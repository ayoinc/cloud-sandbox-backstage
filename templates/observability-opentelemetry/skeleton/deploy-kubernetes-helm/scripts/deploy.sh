#!/usr/bin/env bash
# Installs or upgrades the collector in the cluster of the current kubectl
# context. Extra arguments go to "helm upgrade", for example --dry-run=server.
set -euo pipefail

CHART_VERSION="0.178.3"
RELEASE="${{ values.name }}"
NAMESPACE="${{ values.namespace }}"
root="$(cd "$(dirname "$0")/.." && pwd)"

if ! kubectl get secret "$RELEASE-backend" --namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "The Secret $RELEASE-backend does not exist in $NAMESPACE. Create it with scripts/create-secret.sh." >&2
  exit 1
fi

# The collector configuration becomes the chart value "alternateConfig".
config_values="$(mktemp)"
trap 'rm -f "$config_values"' EXIT
{
  echo "alternateConfig:"
  sed 's/^/  /' "$root/collector/config.yaml"
} > "$config_values"

helm upgrade "$RELEASE" opentelemetry-collector \
  --install \
  --repo https://open-telemetry.github.io/opentelemetry-helm-charts \
  --version "$CHART_VERSION" \
  --namespace "$NAMESPACE" \
  --values "$root/helm/values.yaml" \
  --values "$config_values" \
  --wait --timeout 5m \
  "$@"

kubectl rollout status "deployment/$RELEASE-opentelemetry-collector" --namespace "$NAMESPACE"
