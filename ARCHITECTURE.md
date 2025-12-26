# Cloud Sandbox Architecture

This document describes the architecture of the Cloud Sandbox Backstage developer portal.

## System Overview

Cloud Sandbox is a customized Backstage instance designed to serve as a central developer portal. It provides a unified interface for service discovery, documentation, scaffolding, and team management.

## Architecture Diagram

```d2
# Cloud Sandbox Architecture

direction: down

# External Users
users: {
  shape: person
  label: "Developers"
}

# Edge Layer
edge: {
  label: "Edge Layer"
  style.fill: "#e3f2fd"

  nginx: {
    shape: hexagon
    label: "Nginx\nReverse Proxy"
  }
}

# Application Layer
app: {
  label: "Application Layer"
  style.fill: "#f3e5f5"

  frontend: {
    shape: rectangle
    label: "Frontend\n(React)"
  }

  backend: {
    shape: rectangle
    label: "Backend\n(Node.js)"
  }
}

# Plugin Layer
plugins: {
  label: "Backend Plugins"
  style.fill: "#fff3e0"

  catalog: "Catalog"
  scaffolder: "Scaffolder"
  techdocs: "TechDocs"
  auth: "Auth"
  permission: "Permission"
  search: "Search"

  custom: {
    label: "Custom Plugins"
    style.fill: "#ffecb3"

    branding: "Branding\nSettings"
    ownership: "Ownership\nManagement"
    github_sync: "GitHub\nTeam Sync"
  }
}

# Data Layer
data: {
  label: "Data Layer"
  style.fill: "#e8f5e9"

  postgres: {
    shape: cylinder
    label: "PostgreSQL"
  }

  redis: {
    shape: cylinder
    label: "Redis Cache"
  }

  minio: {
    shape: cylinder
    label: "MinIO\n(S3 Storage)"
  }
}

# External Services
external: {
  label: "External Services"
  style.fill: "#fce4ec"

  github: {
    shape: cloud
    label: "GitHub API"
  }

  k8s: {
    shape: cloud
    label: "Kubernetes\nClusters"
  }
}

# Connections
users -> edge.nginx: "HTTPS"
edge.nginx -> app.frontend: "Static Assets"
edge.nginx -> app.backend: "API Requests"
edge.nginx -> data.minio: "/assets/*"

app.frontend -> app.backend: "REST API"

app.backend -> plugins.catalog
app.backend -> plugins.scaffolder
app.backend -> plugins.techdocs
app.backend -> plugins.auth
app.backend -> plugins.permission
app.backend -> plugins.search
app.backend -> plugins.custom.branding
app.backend -> plugins.custom.ownership
app.backend -> plugins.custom.github_sync

plugins.catalog -> data.postgres
plugins.auth -> data.postgres
plugins.search -> data.postgres
plugins.custom.branding -> data.postgres
plugins.custom.branding -> data.minio
plugins.custom.ownership -> data.postgres
plugins.techdocs -> data.minio

app.backend -> data.redis: "Cache"

plugins.catalog -> external.github: "Org Sync"
plugins.scaffolder -> external.github: "Repo Creation"
plugins.custom.github_sync -> external.github: "Team Sync"
app.backend -> external.k8s: "Cluster Info"
```

## Component Descriptions

### Edge Layer

#### Nginx Reverse Proxy

- Terminates TLS connections
- Routes requests to frontend or backend
- Serves static assets from MinIO
- Provides caching headers

### Application Layer

#### Frontend (React)

- Single-page application built with React
- Material-UI component library
- Backstage core components
- Custom branding support

#### Backend (Node.js)

- Express-based HTTP server
- Plugin-based architecture
- Backstage backend framework
- Custom plugin implementations

### Plugin Layer

#### Core Plugins

| Plugin         | Purpose                                  |
| -------------- | ---------------------------------------- |
| **Catalog**    | Software catalog management              |
| **Scaffolder** | Template-based project creation          |
| **TechDocs**   | Documentation generation and serving     |
| **Auth**       | Authentication providers (GitHub, Guest) |
| **Permission** | Role-based access control                |
| **Search**     | Full-text search across entities         |

#### Custom Plugins

| Plugin                   | Purpose                                     |
| ------------------------ | ------------------------------------------- |
| **Branding Settings**    | Admin-configurable organization branding    |
| **Ownership Management** | Orphan detection and ownership reassignment |
| **GitHub Team Sync**     | Bi-directional GitHub team synchronization  |

### Data Layer

#### PostgreSQL

- Primary data store
- Catalog entities
- Authentication tokens
- Plugin state

#### Redis

- Caching layer
- Session storage
- Performance optimization

#### MinIO (S3-Compatible)

- TechDocs static files
- Branding assets (logos)
- Template artifacts

### External Services

#### GitHub API

- OAuth authentication
- Organization/team sync
- Repository scaffolding
- Token management

#### Kubernetes

- Cluster information
- Service discovery
- Deployment status

## Data Flow

### Authentication Flow

```d2
direction: right

user: User
frontend: Frontend
backend: Backend
github: GitHub OAuth
db: PostgreSQL

user -> frontend: "Click Login"
frontend -> backend: "Initiate OAuth"
backend -> github: "Redirect to GitHub"
github -> backend: "OAuth Callback"
backend -> db: "Store Session"
backend -> frontend: "Set Cookie"
frontend -> user: "Logged In"
```

### Catalog Sync Flow

```d2
direction: right

github_org: GitHub Org
provider: Entity Provider
processor: Entity Processor
db: PostgreSQL
cache: Redis

github_org -> provider: "Fetch Teams/Users"
provider -> processor: "Raw Entities"
processor -> db: "Store Entities"
db -> cache: "Invalidate Cache"
```

### Scaffolding Flow

```d2
direction: right

user: User
scaffolder: Scaffolder
github: GitHub API
catalog: Catalog

user -> scaffolder: "Create from Template"
scaffolder -> github: "Create Repository"
github -> scaffolder: "Repo Created"
scaffolder -> catalog: "Register Entity"
catalog -> user: "Entity Available"
```

## Security Architecture

### Authentication

```d2
direction: down

request: Incoming Request

auth_check: {
  label: "Auth Check"

  cookie: "Session Cookie?"
  token: "API Token?"
  guest: "Guest Allowed?"
}

allow: "Allow Request"
deny: "Deny Request"

request -> auth_check.cookie
auth_check.cookie -> allow: "Valid"
auth_check.cookie -> auth_check.token: "Invalid/Missing"
auth_check.token -> allow: "Valid"
auth_check.token -> auth_check.guest: "Invalid/Missing"
auth_check.guest -> allow: "Yes"
auth_check.guest -> deny: "No"
```

### Authorization

Role-based access control with group membership:

| Role   | Source              | Permissions            |
| ------ | ------------------- | ---------------------- |
| Admin  | `admins` group      | Full access            |
| Editor | `editors` group     | Create/modify entities |
| Viewer | Authenticated users | Read-only access       |
| Guest  | Unauthenticated     | Limited read access    |

## Deployment Architecture

### Docker Compose (Development)

```d2
direction: right

compose: Docker Compose

backstage: {
  label: "Backstage Container"
  frontend: "Frontend"
  backend: "Backend"
}

services: {
  label: "Services"
  postgres: "PostgreSQL"
  redis: "Redis"
  minio: "MinIO"
}

compose -> backstage
compose -> services

backstage -> services.postgres
backstage -> services.redis
backstage -> services.minio
```

### Production Deployment

For production, consider:

1. **Container Orchestration** - Kubernetes or ECS
2. **Managed Database** - RDS, Cloud SQL, or Azure Database
3. **Managed Redis** - ElastiCache, Cloud Memorystore, or Azure Cache
4. **Object Storage** - S3, GCS, or Azure Blob Storage
5. **Load Balancer** - ALB, Cloud Load Balancing, or Azure LB
6. **CDN** - CloudFront, Cloud CDN, or Azure CDN

## Scalability Considerations

### Horizontal Scaling

- Backend is stateless and can be scaled horizontally
- Use Redis for session storage across instances
- Use PostgreSQL connection pooling (PgBouncer)

### Caching Strategy

- Redis caches catalog queries
- Nginx caches static assets
- TechDocs uses CDN-friendly cache headers

### Performance Optimization

- PostgreSQL indexes on frequently queried columns
- Batch processing for large catalog imports
- Async processing for scaffolder tasks

## Monitoring and Observability

### Health Checks

- `/healthcheck` endpoint for liveness probes
- Database connectivity checks
- External service availability

### Logging

- Structured JSON logging
- Correlation IDs for request tracing
- Log levels configurable via environment

### Metrics

- HTTP request latency
- Database query performance
- Cache hit/miss ratios
- External API call metrics

## Disaster Recovery

### Backup Strategy

| Component     | Backup Method  | Frequency |
| ------------- | -------------- | --------- |
| PostgreSQL    | pg_dump        | Daily     |
| MinIO         | S3 replication | Real-time |
| Configuration | Git repository | On change |

### Recovery Procedures

1. **Database Recovery** - Restore from latest backup
2. **Storage Recovery** - Sync from replica or backup
3. **Application Recovery** - Redeploy from container registry
