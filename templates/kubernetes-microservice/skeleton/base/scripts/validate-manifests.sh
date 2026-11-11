#!/usr/bin/env bash
# Validates the manifests of every environment against the Kubernetes API
# schemas with kubeconform (https://github.com/yannh/kubeconform).
#
#   bash scripts/validate-manifests.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# Schemas of custom resources (Argo CD, Argo Rollouts) come from the
# community catalogue of CRD schemas.
validate() {
  kubeconform -strict -summary \
    -schema-location default \
    -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
    "$@"
}

{%- if values.environment_strategy == 'multi-env' %}

for environment in dev staging production; do
  echo "== $environment"
  bash scripts/render-manifests.sh "$environment" | validate -
done
{%- else %}

bash scripts/render-manifests.sh | validate -
{%- endif %}
{%- if values.environment_strategy == 'gitops' %}

echo "== argocd/application.yaml"
validate argocd/application.yaml
{%- endif %}
