#!/usr/bin/env bash
# Applies the manifests to the cluster of the current kubectl context with
# the given image and waits until the new version is running.
#
{%- if values.environment_strategy == 'multi-env' %}
#   bash scripts/deploy.sh <image> [dev|staging|production]
{%- else %}
#   bash scripts/deploy.sh <image>
{%- endif %}
set -euo pipefail
cd "$(dirname "$0")/.."

image="${1:?Usage: bash scripts/deploy.sh <image>}"
name='${{ values.name }}'
{%- if values.environment_strategy == 'multi-env' %}
environment="${2:-dev}"
case "$environment" in
  dev | staging | production) ;;
  *)
    echo "Unknown environment '$environment': use dev, staging or production." >&2
    exit 1
    ;;
esac
manifests="k8s/overlays/$environment"
namespace="${{ values.kubernetes_namespace }}-$environment"
{%- else %}
manifests=k8s
namespace='${{ values.kubernetes_namespace }}'
{%- endif %}
{%- if values.database_type != 'none' or values.message_queue != 'none' %}

# The pods read their connection strings from this Secret, which is not kept
# in the repository.
if ! kubectl --namespace "$namespace" get secret "$name-secrets" > /dev/null 2>&1; then
  echo "Secret $name-secrets is missing in namespace $namespace. Create it first, see docs/index.md." >&2
  exit 1
fi
{%- endif %}

# A throwaway kustomization on top of the manifests replaces the image.
overlay="$(mktemp -d .deploy.XXXXXX)"
trap 'rm -rf "$overlay"' EXIT
cat > "$overlay/kustomization.yaml" << YAML
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../$manifests
images:
  - name: ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}
    newName: ${image%:*}
    newTag: ${image##*:}
YAML

kubectl apply --kustomize "$overlay"
{%- if values.deployment_strategy == 'rolling-update' %}

kubectl --namespace "$namespace" rollout status "deployment/$name" --timeout=300s
{%- else %}

# A Rollout is Healthy when the new version takes all traffic and Paused
# when it waits for promotion (kubectl argo rollouts promote).
phase=Progressing
for _ in $(seq 1 60); do
  phase="$(kubectl --namespace "$namespace" get rollout "$name" --output jsonpath='{.status.phase}')"
  case "$phase" in
    Healthy | Paused) break ;;
    Degraded)
      kubectl --namespace "$namespace" get rollout "$name" --output yaml >&2
      echo "Rollout $name is degraded." >&2
      exit 1
      ;;
  esac
  sleep 5
done
if [ "$phase" != Healthy ] && [ "$phase" != Paused ]; then
  echo "Rollout $name did not become healthy in time (phase: $phase)." >&2
  exit 1
fi
echo "Rollout $name is $phase."
{%- endif %}
