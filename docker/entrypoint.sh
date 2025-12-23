#!/bin/bash
set -e

echo "Starting Backstage entrypoint..."

# Upload pre-built TechDocs to MinIO using mc (MinIO client)
upload_techdocs_to_minio() {
    echo "Uploading pre-built TechDocs to MinIO..."
    
    # Wait for MinIO to be ready
    echo "Waiting for MinIO to be ready..."
    until curl -sf "http://${MINIO_HOST:-minio}:${MINIO_PORT:-9000}/minio/health/ready" > /dev/null 2>&1; do
        echo "MinIO not ready, waiting..."
        sleep 2
    done
    echo "MinIO is ready"
    
    # Configure mc alias
    mc alias set myminio "http://${MINIO_HOST:-minio}:${MINIO_PORT:-9000}" "${MINIO_ACCESS_KEY:-backstage}" "${MINIO_SECRET_KEY:-backstage123}" --api S3v4 2>/dev/null || true
    
    # Upload terraform-modules TechDocs
    if [ -d "/app/techdocs-output/terraform-modules" ]; then
        echo "Uploading TechDocs for terraform-modules..."
        mc cp --recursive /app/techdocs-output/terraform-modules/ myminio/${TECHDOCS_BUCKET:-techdocs}/default/component/terraform-modules/ 2>/dev/null || echo "Warning: Failed to upload terraform-modules TechDocs"
    fi
    
    # Upload any other component TechDocs
    for dir in /app/techdocs-output/*/; do
        if [ -d "$dir" ]; then
            name=$(basename "$dir")
            if [ "$name" != "terraform-modules" ]; then
                echo "Uploading TechDocs for ${name}..."
                # Try as component first, then template
                mc cp --recursive "$dir" myminio/${TECHDOCS_BUCKET:-techdocs}/default/component/${name}/ 2>/dev/null || \
                mc cp --recursive "$dir" myminio/${TECHDOCS_BUCKET:-techdocs}/default/template/${name}/ 2>/dev/null || \
                echo "Warning: Failed to upload ${name} TechDocs"
            fi
        fi
    done
    
    echo "TechDocs upload complete"
}

# Check if mc is available and techdocs-output exists
if command -v mc &> /dev/null && [ -d "/app/techdocs-output" ]; then
    upload_techdocs_to_minio
elif [ -d "/app/techdocs-output" ]; then
    echo "MinIO client (mc) not available, skipping TechDocs upload"
else
    echo "No pre-built TechDocs found"
fi

# Start Backstage
echo "Starting Backstage..."
exec node packages/backend --config app-config.yaml --config app-config.production.yaml
