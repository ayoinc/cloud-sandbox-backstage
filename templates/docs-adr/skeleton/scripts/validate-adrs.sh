#!/usr/bin/env bash
# Checks every ADR in docs/adrs against the conventions of this repository:
# the file name, the sections of docs/templates/adr-template.md, a known
# status, and an entry in docs/adrs/index.md.
set -euo pipefail
shopt -s nullglob

adr_dir="docs/adrs"
template="docs/templates/adr-template.md"
index="$adr_dir/index.md"
failures=0

fail() {
  echo "::error file=$1::$2"
  failures=$((failures + 1))
}

if [ ! -f "$template" ]; then
  echo "::error::$template is missing; it defines the sections every ADR needs"
  exit 1
fi

checked=0
for file in "$adr_dir"/*.md; do
  name="$(basename "$file")"
  if [ "$name" = "index.md" ]; then
    continue
  fi
  checked=$((checked + 1))

  if ! [[ "$name" =~ ^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*\.md$ ]]; then
    fail "$file" "File name must look like NNN-short-title.md"
  fi

  while IFS= read -r section; do
    if ! grep -qxF "$section" "$file"; then
      fail "$file" "Missing section '$section' required by $template"
    fi
  done < <(grep -E '^## ' "$template")

  status="$(awk '/^## Status/ { found = 1; next } found && NF { print; exit }' "$file")"
  if ! [[ "$status" =~ ^(Proposed|Accepted|Rejected|Deprecated|Superseded)([[:space:]]|$) ]]; then
    fail "$file" "Status must start with Proposed, Accepted, Rejected, Deprecated or Superseded (found '$status')"
  fi

  if ! grep -qF "($name)" "$index"; then
    fail "$file" "Not listed in $index"
  fi
done

if [ "$failures" -gt 0 ]; then
  echo "$failures problem(s) found in $checked ADR file(s)"
  exit 1
fi
echo "$checked ADR file(s) follow the repository conventions"
