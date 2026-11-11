#!/usr/bin/env bash
# Checks a running store end to end through the storefront: the page, the
# catalogue and an order. Start the store first:
#
#   docker compose up --build --detach --wait
#   bash scripts/smoke-test.sh [storefront address]
set -euo pipefail

store="${1:-http://localhost:3000}"

curl --fail --silent --show-error "$store/" | grep --quiet '<div id="root">'
echo "The storefront serves its page"

products="$(curl --fail --silent --show-error "$store/api/v1/products")"
product_id="$(jq --raw-output '[.products[] | select(.available)][0].id' <<< "$products")"
if [ -z "$product_id" ] || [ "$product_id" = "null" ]; then
  echo "The catalogue has no product that can be ordered: $products" >&2
  exit 1
fi
echo "The catalogue lists $(jq '.products | length' <<< "$products") products"

order="$(curl --fail --silent --show-error "$store/api/v1/orders" \
  --header 'content-type: application/json' \
  --data "{\"customerEmail\": \"smoke-test@example.com\", \"paymentToken\": \"tok_smoke_test\", \"items\": [{\"productId\": \"$product_id\", \"quantity\": 1}]}")"
jq --exit-status '.order.id' <<< "$order" > /dev/null
echo "Placed order $(jq --raw-output '.order.id' <<< "$order"), status $(jq --raw-output '.order.status' <<< "$order")"
