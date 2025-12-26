# ${{ values.name }}

${{ values.description }}

## Overview

This Cloud Run service is managed by Terraform for the **${{ values.environment }}** environment.

## Configuration

| Setting       | Value                              |
| ------------- | ---------------------------------- |
| Region        | ${{ values.region }}               |
| GCP Project   | ${{ values.gcpProject }}           |
| Memory        | ${{ values.memory }}               |
| CPU           | ${{ values.cpu }}                  |
| Max Instances | ${{ values.maxInstances }}         |
| Public Access | ${{ values.allowUnauthenticated }} |

## Features

- **Auto-scaling**: Scales from 0 to ${{ values.maxInstances }} instances
- **Artifact Registry**: Private container registry included
- **Health Checks**: Startup and liveness probes configured
- **Monitoring**: Alert policies for latency and errors
- **HTTPS**: Automatic TLS certificates

## Local Development

```bash
# Build container
docker build -t ${{ values.name }}:latest .

# Run locally
docker run -p 8080:8080 ${{ values.name }}:latest

# Test health endpoint
curl http://localhost:8080/health
```

## Deployment

### Push to Artifact Registry

```bash
# Configure Docker
gcloud auth configure-docker ${{ values.region }}-docker.pkg.dev

# Tag image
docker tag ${{ values.name }}:latest \
  ${{ values.region }}-docker.pkg.dev/${{ values.gcpProject }}/${{ values.name }}-${{ values.environment }}/${{ values.name }}:latest

# Push image
docker push ${{ values.region }}-docker.pkg.dev/${{ values.gcpProject }}/${{ values.name }}-${{ values.environment }}/${{ values.name }}:latest
```

### Deploy via Terraform

```bash
terraform apply
```

### Deploy via gcloud

```bash
gcloud run deploy ${{ values.name }}-${{ values.environment }} \
  --image ${{ values.region }}-docker.pkg.dev/${{ values.gcpProject }}/${{ values.name }}-${{ values.environment }}/${{ values.name }}:latest \
  --region ${{ values.region }}
```

## Environment Variables

Add environment variables in main.tf:

```hcl
env {
  name  = "DATABASE_URL"
  value = "postgres://..."
}

# Or from Secret Manager
env {
  name = "API_KEY"
  value_source {
    secret_key_ref {
      secret  = google_secret_manager_secret.api_key.secret_id
      version = "latest"
    }
  }
}
```

## Owner

This resource is owned by **${{ values.owner }}**.
