#!/usr/bin/env bash
# Deploys the image to a throwaway kind cluster with the manifests of this
# repository and calls the service. Needs docker, kind, kubectl and curl.
#
#   docker build -t ${{ values.name }}:local .
#   bash scripts/kind-test.sh ${{ values.name }}:local
set -euo pipefail
cd "$(dirname "$0")/.."

image="${1:?Usage: bash scripts/kind-test.sh <image>}"
name='${{ values.name }}'
cluster="$name-test"
{%- if values.environment_strategy == 'multi-env' %}
namespace='${{ values.kubernetes_namespace }}-dev'
{%- else %}
namespace='${{ values.kubernetes_namespace }}'
{%- endif %}

kind create cluster --name "$cluster" --wait 120s
trap 'kind delete cluster --name "$cluster"' EXIT
kind load docker-image "$image" --name "$cluster"
{%- if values.deployment_strategy != 'rolling-update' %}

# Rollout resources need the Argo Rollouts controller. Its resource
# definitions are too large for a client-side apply.
kubectl create namespace argo-rollouts
kubectl apply --server-side --namespace argo-rollouts \
  --filename https://github.com/argoproj/argo-rollouts/releases/download/v1.10.2/install.yaml
kubectl --namespace argo-rollouts rollout status deployment/argo-rollouts --timeout=180s
{%- endif %}
{%- if values.database_type != 'none' or values.message_queue != 'none' %}

# Placeholder connection strings: the service only has to start.
kubectl create namespace "$namespace" --dry-run=client --output yaml | kubectl apply --filename -
kubectl --namespace "$namespace" create secret generic "$name-secrets" \
  --from-literal=database-url=placeholder \
  --from-literal=message-queue-url=placeholder
{%- endif %}

{% if values.environment_strategy == 'multi-env' -%}
bash scripts/deploy.sh "$image" dev
{%- else -%}
bash scripts/deploy.sh "$image"
{%- endif %}

kubectl --namespace "$namespace" get pods --output wide

kubectl --namespace "$namespace" port-forward "service/$name" 18080:80 > /dev/null &
forward=$!
trap 'kill "$forward" 2> /dev/null || true; kind delete cluster --name "$cluster"' EXIT

for _ in $(seq 1 30); do
  if curl --fail --silent --output /dev/null http://127.0.0.1:18080/health; then
    break
  fi
  sleep 1
done

for path in / /health /ready /metrics; do
  echo "GET $path"
  curl --fail --silent --show-error "http://127.0.0.1:18080$path"
  echo
done

curl --fail --silent http://127.0.0.1:18080/ | grep --quiet "$name" || {
  echo "GET / did not return the service name." >&2
  exit 1
}
echo "The service answers in the cluster."
