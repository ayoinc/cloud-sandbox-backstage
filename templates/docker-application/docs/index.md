# Docker Application Template

This template creates a containerized application with Docker best practices.

## Features

- **Multi-stage builds** - Optimized image sizes
- **Docker Compose** - Local development environment
- **Health checks** - Container health monitoring
- **Security** - Non-root user, minimal base images
- **CI/CD** - GitHub Actions for building and pushing

## Prerequisites

- Docker 20+
- Docker Compose 2+

## Quick Start

```bash
# Build image
docker build -t myapp .

# Run container
docker run -p 8080:8080 myapp

# Development with compose
docker-compose up -d
```

## Project Structure

```
├── Dockerfile          # Production image
├── Dockerfile.dev      # Development image
├── docker-compose.yml  # Local services
├── .dockerignore       # Build exclusions
└── scripts/
    ├── entrypoint.sh   # Container entrypoint
    └── healthcheck.sh  # Health check script
```

## Dockerfile Best Practices

```dockerfile
# Multi-stage build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine
RUN addgroup -g 1001 appgroup && adduser -u 1001 -G appgroup -s /bin/sh -D appuser
WORKDIR /app
COPY --from=builder /app/dist ./dist
USER appuser
EXPOSE 8080
CMD ["node", "dist/index.js"]
```

## Support

Contact the Platform Team for assistance.
