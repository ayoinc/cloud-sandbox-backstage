#!/usr/bin/env bash
# Renders every kustomization of the repository and validates the result
# against the Kubernetes and CRD schemas. Run it before pushing; CI runs it too.
#
# kustomize and kubeconform are downloaded into .bin/ at pinned versions.
set -euo pipefail

KUSTOMIZE_VERSION="5.8.3"
KUBECONFORM_VERSION="0.8.0"
KUBERNETES_VERSION="1.37.0"

root="$(cd "$(dirname "$0")/.." && pwd)"
bin="$root/.bin"
mkdir -p "$bin"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "$(uname -m)" in
  x86_64 | amd64) arch=amd64 ;;
  arm64 | aarch64) arch=arm64 ;;
  *) echo "Unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac

if [ ! -x "$bin/kustomize-$KUSTOMIZE_VERSION" ]; then
  curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_${os}_${arch}.tar.gz" |
    tar -xz -C "$bin" kustomize
  mv "$bin/kustomize" "$bin/kustomize-$KUSTOMIZE_VERSION"
fi
if [ ! -x "$bin/kubeconform-$KUBECONFORM_VERSION" ]; then
  curl -fsSL "https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-${os}-${arch}.tar.gz" |
    tar -xz -C "$bin" kubeconform
  mv "$bin/kubeconform" "$bin/kubeconform-$KUBECONFORM_VERSION"
fi
kustomize="$bin/kustomize-$KUSTOMIZE_VERSION"
kubeconform="$bin/kubeconform-$KUBECONFORM_VERSION"

validate() {
  "$kubeconform" -strict -summary \
    -kubernetes-version "$KUBERNETES_VERSION" \
    -schema-location default \
    -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
    "$@"
}

failed=0

echo "== bootstrap/root.yaml"
validate "$root/bootstrap/root.yaml" || failed=1

while IFS= read -r file; do
  dir="$(dirname "$file")"
  echo "== ${dir#"$root"/}"
  if ! rendered="$("$kustomize" build "$dir")"; then
    failed=1
    continue
  fi
  printf '%s\n' "$rendered" | validate - || failed=1
done < <(find "$root/argocd" "$root/apps" -name kustomization.yaml | sort)

# Every overlay needs the file that tells the ApplicationSet where it runs.
for overlay in "$root"/apps/*/overlays/*/; do
  environment="$(basename "$overlay")"
  if [ ! -f "$root/environments/$environment.yaml" ]; then
    echo "ERROR: ${overlay#"$root"/} has no environments/$environment.yaml" >&2
    failed=1
  fi
done

# A Secret with data in Git is a leak, however it got there.
if grep -rlE '^kind: Secret$' "$root/apps" "$root/argocd" 2>/dev/null; then
  echo "ERROR: the files above contain a plain Kubernetes Secret" >&2
  failed=1
fi

exit "$failed"
