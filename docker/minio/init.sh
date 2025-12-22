#!/bin/sh
set -e

# Wait for MinIO to be ready
until curl -sf http://localhost:9000/minio/health/live; do
    echo "Waiting for MinIO to be ready..."
    sleep 2
done

# Configure mc alias
mc alias set local http://localhost:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}

# Create buckets
mc mb --ignore-existing local/techdocs
mc mb --ignore-existing local/scaffolder
mc mb --ignore-existing local/backstage-assets

# Set bucket policies for techdocs (public read)
mc anonymous set download local/techdocs

echo "MinIO initialization complete!"
