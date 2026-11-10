#!/bin/sh
# Build every catalog/template mkdocs site found under the current directory into
# <output-dir>/<name>. Sources are copied to a scratch dir first so read-only mounts
# work (the d2 plugin writes its cache next to mkdocs.yml). A failing site is reported
# and counted but does not stop the others.
#
# Usage: build-techdocs <output-dir>
set -eu

out="${1:?usage: build-techdocs <output-dir>}"
mkdir -p "$out"
out=$(cd "$out" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

built=0
failed=0
for dir in catalog/*/ templates/*/; do
  [ -f "${dir}mkdocs.yml" ] || continue
  name=$(basename "$dir")
  echo "Building TechDocs for ${dir}"
  cp -R "$dir" "$work/$name"
  if (cd "$work/$name" && mkdocs build --quiet --site-dir "$out/$name"); then
    built=$((built + 1))
  else
    echo "WARN: TechDocs build failed for ${dir}" >&2
    failed=$((failed + 1))
  fi
  rm -rf "${work:?}/$name"
done

echo "TechDocs build finished: ${built} built, ${failed} failed"
