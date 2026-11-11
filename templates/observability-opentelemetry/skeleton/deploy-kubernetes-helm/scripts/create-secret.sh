#!/usr/bin/env bash
# Creates or replaces the Secret with the backend endpoint and credentials
# from a local env file (default .env, see .env.example). The file stays on
# your machine; use your secrets operator instead where one is available.
set -euo pipefail

RELEASE="${{ values.name }}"
NAMESPACE="${{ values.namespace }}"
root="$(cd "$(dirname "$0")/.." && pwd)"
env_file="${1:-$root/.env}"

if [ ! -f "$env_file" ]; then
  echo "There is no $env_file. Copy .env.example to .env and fill it in." >&2
  exit 1
fi

kubectl create namespace "$NAMESPACE" --dry-run=client --output yaml | kubectl apply --filename -
kubectl create secret generic "$RELEASE-backend" \
  --namespace "$NAMESPACE" \
  --from-env-file "$env_file" \
  --dry-run=client --output yaml | kubectl apply --filename -

echo "Secret $RELEASE-backend is up to date in $NAMESPACE. Restart the collector to pick up changes:"
echo "  kubectl rollout restart deployment/$RELEASE-opentelemetry-collector --namespace $NAMESPACE"
