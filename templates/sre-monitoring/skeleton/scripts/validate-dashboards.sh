#!/usr/bin/env bash
# Checks that every Grafana dashboard is valid JSON and has the fields Grafana
# needs to import it: a unique uid, a title and at least one panel.
set -euo pipefail
shopt -s nullglob

cd "$(dirname "$0")/.."

failures=0
uids=""
for file in dashboards/*.json; do
  echo "Checking $file"
  if ! jq empty "$file"; then
    echo "::error file=$file::Not valid JSON"
    failures=$((failures + 1))
    continue
  fi
  if ! jq -e '(.uid | type == "string" and length > 0 and length <= 40)
      and (.title | type == "string" and length > 0)
      and (.panels | type == "array" and length > 0)' "$file" > /dev/null; then
    echo "::error file=$file::A dashboard needs a uid of at most 40 characters, a title and at least one panel"
    failures=$((failures + 1))
  fi
  uids="$uids$(jq -r '.uid' "$file")"$'\n'
done

duplicates="$(printf '%s' "$uids" | sort | uniq -d)"
if [ -n "$duplicates" ]; then
  echo "::error::Dashboard uid used more than once: $duplicates"
  failures=$((failures + 1))
fi

if [ "$failures" -gt 0 ]; then
  exit 1
fi
echo "Dashboards are valid"
