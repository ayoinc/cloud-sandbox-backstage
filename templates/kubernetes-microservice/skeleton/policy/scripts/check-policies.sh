#!/usr/bin/env bash
# Checks the manifests of every environment against the policies in policy/
# with conftest (https://www.conftest.dev).
#
#   bash scripts/check-policies.sh
set -euo pipefail
cd "$(dirname "$0")/.."

{%- if values.environment_strategy == 'multi-env' %}

for environment in dev staging production; do
  echo "== $environment"
  bash scripts/render-manifests.sh "$environment" | conftest test --policy policy -
done
{%- else %}

bash scripts/render-manifests.sh | conftest test --policy policy -
{%- endif %}
