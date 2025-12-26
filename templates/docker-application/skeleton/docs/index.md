# ${{ values.name }}

${{ values.description }}

## Overview

A containerized Docker application.

## Quick Start

### Prerequisites

- Docker 20+
- Docker Compose (optional)

### Building

```bash
docker build -t ${{ values.name }} .
```

### Running

```bash
docker run -p 8080:8080 ${{ values.name }}
```

### Using Docker Compose

```bash
docker-compose up -d
```

## Project Structure

```
.
├── src/                 # Application source
├── Dockerfile           # Container definition
├── docker-compose.yml   # Multi-container setup
├── .dockerignore        # Docker ignore rules
├── docs/                # Documentation
└── catalog-info.yaml    # Backstage metadata
```

## Configuration

Environment variables:
- `PORT`: Application port (default: 8080)
- `LOG_LEVEL`: Logging verbosity

## Health Checks

- `/health`: Health endpoint
- `/ready`: Readiness endpoint

## Deployment

Push to container registry:

```bash
docker tag ${{ values.name }} registry.example.com/${{ values.name }}:latest
docker push registry.example.com/${{ values.name }}:latest
```
