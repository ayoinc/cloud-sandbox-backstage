#!/usr/bin/env bash
# Prints the Kubernetes manifests of one environment as a single YAML stream.
#
{%- if values.environment_strategy == 'multi-env' %}
#   bash scripts/render-manifests.sh [dev|staging|production]
set -euo pipefail
cd "$(dirname "$0")/.."

environment="${1:-dev}"
case "$environment" in
  dev | staging | production) ;;
  *)
    echo "Unknown environment '$environment': use dev, staging or production." >&2
    exit 1
    ;;
esac

kubectl kustomize "k8s/overlays/$environment"
{%- else %}
#   bash scripts/render-manifests.sh
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl kustomize k8s
{%- endif %}
