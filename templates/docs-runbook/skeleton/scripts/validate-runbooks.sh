#!/usr/bin/env bash
# Checks that every runbook has the sections an on-call engineer relies on
# and is listed in the index of its directory.
set -euo pipefail
shopt -s nullglob

incident_sections=(
  "## Summary"
  "## Symptoms"
  "## Impact"
  "## Investigation Steps"
  "## Resolution Steps"
  "## Verification"
  "## Escalation"
)
procedure_sections=(
  "## Summary"
)
failures=0
checked=0

fail() {
  echo "::error file=$1::$2"
  failures=$((failures + 1))
}

# check_runbooks <directory> <required section>...
check_runbooks() {
  local dir="$1"
  shift
  local file name section
  for file in "$dir"/*.md; do
    name="$(basename "$file")"
    if [ "$name" = "index.md" ]; then
      continue
    fi
    checked=$((checked + 1))

    if ! [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*\.md$ ]]; then
      fail "$file" "File name must be lowercase words separated by hyphens"
    fi
    for section in "$@"; do
      if ! grep -qxF "$section" "$file"; then
        fail "$file" "Missing section '$section'"
      fi
    done
    if ! grep -qF "($name)" "$dir/index.md"; then
      fail "$file" "Not listed in $dir/index.md"
    fi
  done
}

check_runbooks docs/incidents "${incident_sections[@]}"
check_runbooks docs/procedures "${procedure_sections[@]}"

if [ "$failures" -gt 0 ]; then
  echo "$failures problem(s) found in $checked runbook(s)"
  exit 1
fi
echo "$checked runbook(s) follow the repository conventions"
