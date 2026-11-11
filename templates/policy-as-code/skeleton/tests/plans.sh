#!/usr/bin/env bash
# Runs the plan policies against the fixture plans and compares what they
# report with what is expected: nothing for the compliant plan, exactly the
# messages of violating.expected.txt for the violating one.
set -euo pipefail

cd "$(dirname "$0")/.."
fixtures=tests/fixtures/plans

conftest test "$fixtures/compliant.json" --policy policy --all-namespaces --no-color

actual=$(mktemp)
trap 'rm -f "$actual"' EXIT

# Conftest exits non-zero when a policy denies, which is what this plan is for.
conftest test "$fixtures/violating.json" --policy policy --all-namespaces --output json |
  jq -r '.[] | ((.failures // [])[] | "FAIL " + .msg), ((.warnings // [])[] | "WARN " + .msg)' |
  sort > "$actual" || true

if ! diff -u "$fixtures/violating.expected.txt" "$actual"; then
  echo "The policies no longer report what tests/fixtures/plans/violating.expected.txt lists." >&2
  exit 1
fi
echo "violating.json: reported exactly the expected failures and warnings"
