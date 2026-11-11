#!/usr/bin/env bash
# Imports every dashboard in dashboards/ into a Grafana folder through the
# Grafana HTTP API, replacing earlier versions of the same dashboards.
#
#   GRAFANA_URL      Base URL of Grafana
#   GRAFANA_API_KEY  Service account token allowed to edit dashboards
#   DASHBOARD_DIR    Directory with dashboard JSON files (default: dashboards)
set -euo pipefail
shopt -s nullglob

cd "$(dirname "$0")/.."

DEFAULT_GRAFANA_URL='${{ values.grafanaUrl | replace("'", "'\\''") }}'
GRAFANA_URL="${GRAFANA_URL:-$DEFAULT_GRAFANA_URL}"
GRAFANA_URL="${GRAFANA_URL%/}"
GRAFANA_API_KEY="${GRAFANA_API_KEY:-}"
DASHBOARD_DIR="${DASHBOARD_DIR:-dashboards}"
FOLDER_UID="${{ values.name }}"
FOLDER_TITLE="${{ values.name }}"

if [ -z "$GRAFANA_API_KEY" ]; then
  echo "Error: GRAFANA_API_KEY environment variable is required" >&2
  exit 1
fi

# grafana <method> <path> [json body]: prints the response body, then the
# HTTP status on a line of its own.
grafana() {
  local method="$1" path="$2" body="${3:-}"
  local args=(-sS -X "$method" -w '\n%{http_code}'
    -H "Authorization: Bearer $GRAFANA_API_KEY"
    -H "Content-Type: application/json")
  if [ -n "$body" ]; then
    args+=(--data-binary "$body")
  fi
  curl "${args[@]}" "$GRAFANA_URL$path"
}

echo "Importing dashboards to Grafana at $GRAFANA_URL"

response="$(grafana GET "/api/folders/$FOLDER_UID")"
status="${response##*$'\n'}"
if [ "$status" = "404" ]; then
  payload="$(jq -n --arg uid "$FOLDER_UID" --arg title "$FOLDER_TITLE" '{uid: $uid, title: $title}')"
  response="$(grafana POST /api/folders "$payload")"
  status="${response##*$'\n'}"
fi
if [ "$status" != "200" ]; then
  echo "Error: could not find or create folder '$FOLDER_TITLE' (HTTP $status)" >&2
  echo "${response%$'\n'*}" >&2
  exit 1
fi
echo "Using folder: $FOLDER_TITLE"

failures=0
imported=0
for dashboard_file in "$DASHBOARD_DIR"/*.json; do
  dashboard_name="$(basename "$dashboard_file" .json)"
  payload="$(jq -n --slurpfile dashboard "$dashboard_file" --arg folderUid "$FOLDER_UID" \
    '{dashboard: ($dashboard[0] | .id = null), folderUid: $folderUid, overwrite: true, message: "Imported by scripts/import-dashboards.sh"}')"
  response="$(grafana POST /api/dashboards/db "$payload")"
  status="${response##*$'\n'}"
  if [ "$status" = "200" ]; then
    echo "  Imported: $dashboard_name"
    imported=$((imported + 1))
  else
    echo "  Failed to import: $dashboard_name (HTTP $status)" >&2
    echo "  ${response%$'\n'*}" >&2
    failures=$((failures + 1))
  fi
done

if [ "$failures" -gt 0 ]; then
  echo "$failures dashboard(s) could not be imported" >&2
  exit 1
fi
echo "Imported $imported dashboard(s)"
