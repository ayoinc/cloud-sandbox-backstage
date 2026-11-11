#!/usr/bin/env bash
# Encrypts a secret for one app and environment and adds it to the overlay.
#
#   scripts/seal.sh <app> <environment> KEY=value [KEY=value ...]
#   scripts/seal.sh podinfo dev PODINFO_UI_MESSAGE='hello from dev'
#
# The values are encrypted with the public key of the Sealed Secrets
# controller of the current kubectl context, so only that cluster can read
# them. The result, apps/<app>/overlays/<environment>/sealedsecret.yaml, is
# safe to commit. The plain values never touch the disk.
set -euo pipefail

if [ "$#" -lt 3 ]; then
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
fi

app="$1"
environment="$2"
shift 2

root="$(cd "$(dirname "$0")/.." && pwd)"
overlay="$root/apps/$app/overlays/$environment"
if [ ! -d "$overlay" ]; then
  echo "There is no overlay $overlay" >&2
  exit 1
fi
for tool in kubectl kubeseal kustomize; do
  command -v "$tool" >/dev/null || { echo "$tool is required" >&2; exit 1; }
done

literals=()
for pair in "$@"; do
  case "$pair" in
    *=*) literals+=("--from-literal=$pair") ;;
    *) echo "Expected KEY=value, got: $pair" >&2; exit 2 ;;
  esac
done

# The sealed secret is bound to its name and namespace: it cannot be decrypted
# under another name or in another namespace.
kubectl create secret generic "$app-config" \
  --namespace "$app-$environment" \
  --dry-run=client --output yaml "${literals[@]}" |
  kubeseal \
    --controller-name sealed-secrets-controller \
    --controller-namespace sealed-secrets \
    --format yaml |
  # Before the Deployment (wave 0), so the Secret exists when the pods start.
  awk '{ print }
    /^metadata:$/ && !done {
      print "  annotations:"
      print "    argocd.argoproj.io/sync-wave: \"-1\""
      done = 1
    }' > "$overlay/sealedsecret.yaml"

if ! grep -q 'sealedsecret.yaml' "$overlay/kustomization.yaml"; then
  (cd "$overlay" && kustomize edit add resource sealedsecret.yaml)
fi

echo "Wrote $overlay/sealedsecret.yaml. Commit it together with kustomization.yaml."
