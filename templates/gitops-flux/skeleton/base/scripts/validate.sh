#!/usr/bin/env bash
# Renders every kustomization of the repository and validates the result
# against the Kubernetes, Flux and CRD schemas. Run it before pushing; CI runs
# it too.
#
# kustomize, kubeconform and the Flux CRD schemas are downloaded into .bin/ at
# pinned versions.
set -euo pipefail

FLUX_VERSION="2.10.0"
KUSTOMIZE_VERSION="5.8.3"
KUBECONFORM_VERSION="0.8.0"
KUBERNETES_VERSION="1.37.0"

root="$(cd "$(dirname "$0")/.." && pwd)"
bin="$root/.bin"
schemas="$bin/flux-crd-schemas-$FLUX_VERSION"
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
if [ ! -d "$schemas" ]; then
  mkdir -p "$schemas"
  curl -fsSL "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/crd-schemas.tar.gz" |
    tar -xz -C "$schemas"
fi
kustomize="$bin/kustomize-$KUSTOMIZE_VERSION"
kubeconform="$bin/kubeconform-$KUBECONFORM_VERSION"

# Secrets are skipped: encrypted ones carry sops metadata that is not part of
# the Secret schema. The check further down makes sure they are encrypted.
validate() {
  "$kubeconform" -strict -summary -skip Secret \
    -kubernetes-version "$KUBERNETES_VERSION" \
    -schema-location default \
    -schema-location "$schemas" \
    -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
    "$@"
}

failed=0

# The files Flux reads directly: the Kustomizations of each cluster.
while IFS= read -r file; do
  echo "== ${file#"$root"/}"
  validate "$file" || failed=1
done < <(find "$root/clusters" -name '*.yaml' -not -path '*/flux-system/*' | sort)

# Everything those Kustomizations build.
while IFS= read -r file; do
  dir="$(dirname "$file")"
  echo "== ${dir#"$root"/}"
  if ! rendered="$("$kustomize" build "$dir")"; then
    failed=1
    continue
  fi
  printf '%s\n' "$rendered" | validate - || failed=1
done < <(find "$root/infrastructure" "$root/apps" -name kustomization.yaml | sort)

# A Secret may only be committed encrypted: in a *.sops.yaml file that sops
# has processed. Anything else is a leak.
while IFS= read -r file; do
  case "$file" in
    *.sops.yaml | *.sops.yml)
      if ! grep -q '^sops:' "$file"; then
        echo "ERROR: ${file#"$root"/} is named as encrypted but is plain text. Run: sops --encrypt --in-place $file" >&2
        failed=1
      fi
      ;;
    *)
      echo "ERROR: ${file#"$root"/} contains a plain Kubernetes Secret" >&2
      failed=1
      ;;
  esac
done < <(grep -rlE '^kind: Secret$' "$root/clusters" "$root/infrastructure" "$root/apps" 2>/dev/null || true)

exit "$failed"
