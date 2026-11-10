#!/bin/sh
# Publishes the TechDocs sites pre-built into the image to the object store, then
# starts the Backstage backend.
set -eu

TECHDOCS_DIR=/app/techdocs-output

publish_techdocs() {
  endpoint="http://${MINIO_HOST:-minio}:${MINIO_PORT:-9000}"
  bucket="${TECHDOCS_BUCKET:-techdocs}"

  mc alias set techdocs "$endpoint" "${MINIO_ACCESS_KEY:-backstage}" "${MINIO_SECRET_KEY:-backstage123}" >/dev/null

  echo "Waiting for object storage at ${endpoint}..."
  until mc ready techdocs >/dev/null 2>&1; do
    sleep 2
  done

  for dir in "$TECHDOCS_DIR"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    echo "Publishing TechDocs for ${name}"
    mc mirror --overwrite --quiet "$dir" "techdocs/${bucket}/default/component/${name}" ||
      echo "WARN: failed to publish TechDocs for ${name}" >&2
  done
}

if [ -d "$TECHDOCS_DIR" ] && [ -n "$(ls -A "$TECHDOCS_DIR")" ]; then
  publish_techdocs
else
  echo "No pre-built TechDocs found"
fi

exec node packages/backend --config app-config.yaml --config app-config.production.yaml
