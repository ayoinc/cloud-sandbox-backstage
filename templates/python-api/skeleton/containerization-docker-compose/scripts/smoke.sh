#!/usr/bin/env bash
# Creates an item through the API of a running service, reads it back and deletes it.
#
#   bash scripts/smoke.sh [base URL]
{%- if values.auth_type in ['jwt', 'basic-auth'] %}
#
# AUTH_USERNAME and AUTH_PASSWORD override the development credentials.
{%- elif values.auth_type == 'api-key' %}
#
# API_KEY overrides the development API key.
{%- endif %}
set -euo pipefail

base_url="${1:-http://localhost:8000}"
{%- if values.auth_type == 'jwt' %}

token="$(
  curl --fail --silent --show-error \
    --data-urlencode "username=${AUTH_USERNAME:-admin}" \
    --data-urlencode "password=${AUTH_PASSWORD:-change-me}" \
    "$base_url/api/v1/auth/token" |
    python3 -c 'import json, sys; print(json.load(sys.stdin)["access_token"])'
)"

api() {
  curl --fail --silent --show-error --header "Authorization: Bearer $token" "$@"
}
{%- elif values.auth_type == 'api-key' %}

api() {
  curl --fail --silent --show-error --header "X-API-Key: ${API_KEY:-dev-api-key}" "$@"
}
{%- elif values.auth_type == 'basic-auth' %}

api() {
  curl --fail --silent --show-error --user "${AUTH_USERNAME:-admin}:${AUTH_PASSWORD:-change-me}" "$@"
}
{%- else %}

api() {
  curl --fail --silent --show-error "$@"
}
{%- endif %}

created="$(api --json '{"name": "smoke test"}' "$base_url/api/v1/items")"
echo "created: $created"

id="$(python3 -c 'import json, sys; print(json.load(sys.stdin)["id"])' <<<"$created")"
fetched="$(api "$base_url/api/v1/items/$id")"
echo "fetched: $fetched"

if [ "$created" != "$fetched" ]; then
  echo "the item read back differs from the item created" >&2
  exit 1
fi

api --request DELETE "$base_url/api/v1/items/$id"
echo "deleted: $id"
