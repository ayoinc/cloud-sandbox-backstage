# Cloud Sandbox - Backstage Developer Portal

A fully-featured [Backstage](https://backstage.io) developer portal configured for cloud-native development teams. This portal provides a centralized hub for software catalog management, documentation, scaffolding, and team collaboration.

## Features

### Core Capabilities

- **Software Catalog** - Centralized registry of all software components, APIs, resources, and systems
- **TechDocs** - Built-in technical documentation with MkDocs and D2 diagram support
- **Software Templates** - Scaffolder templates for creating new projects, infrastructure, and resources
- **Search** - Full-text search across catalog entities, documentation, and more

### Custom Plugins

- **Branding Settings** - Admin-configurable organization branding (logo, colors, name)
- **Ownership Management** - Orphan detection and ownership reassignment for catalog entities
- **GitHub Team Sync** - Bi-directional synchronization between Backstage groups and GitHub teams

### Integrations

- **GitHub** - OAuth authentication, organization/team sync, repository scaffolding
- **Kubernetes** - Cluster visualization and management
- **MinIO/S3** - TechDocs storage and asset management
- **PostgreSQL** - Persistent data storage
- **Redis** - Caching for improved performance

### Templates

50+ scaffolder templates for:
- Cloud infrastructure (AWS, Azure, GCP)
- Application development (Node.js, Python, React, Spring Boot)
- DevOps automation (Terraform, Ansible, Docker, Kubernetes)
- Data engineering (Airflow, dbt, Superset)
- Documentation (ADRs, Runbooks, D2 diagrams)

## Quick Start

### Prerequisites

- Docker and Docker Compose
- **For Devbox (Recommended):** [Devbox](https://www.jetify.com/devbox/) (automatically installs Node.js, Yarn, Python, D2, etc.)
- **For Manual Setup:** Node.js 22+, Yarn 4.4.1 (via Corepack)

### Development Modes

This project supports two development modes:

| Mode | Best For | Hot Reload | Setup Complexity |
|------|----------|------------|------------------|
| **Devbox + Docker Services** | Daily development | Yes | Low |
| **Full Docker Stack** | Testing production setup | No (rebuild required) | Very Low |

---

## Option 1: Devbox Development (Recommended)

Devbox provides a reproducible development environment with all tools pre-configured.

### Install Devbox

```bash
# Install Devbox (one-time setup)
curl -fsSL https://get.jetify.com/devbox | bash

# Devbox will automatically install Nix on first use
```

### Start Development

```bash
# Clone the repository
git clone <repository-url>
cd backstage

# Enter Devbox shell (installs Node.js 22, Yarn 4, Python, D2, etc.)
devbox shell

# Start Docker services (PostgreSQL, Redis, MinIO)
devbox run services:start

# Copy environment template
cp .env.example .env
# Edit .env with your configuration (especially GITHUB_* variables)

# Install dependencies
yarn install

# Start Backstage in development mode with hot reload
devbox run dev
```

Access the portal at http://localhost:3000 (frontend) and http://localhost:7007 (backend API).

### Devbox Commands

```bash
devbox run services:start    # Start Docker services (Postgres, Redis, MinIO)
devbox run services:stop     # Stop Docker services
devbox run services:status   # Check service status
devbox run dev               # Start Backstage with hot reload
devbox run build             # Build the backend
devbox run test              # Run tests
devbox run lint              # Run linter
devbox run techdocs          # Generate TechDocs
devbox run clean             # Clean build artifacts
devbox run reset             # Reset entire dev environment
```

---

## Option 2: Full Docker Stack

Run everything in Docker containers (closest to production).

### Start Full Stack

```bash
# Clone the repository
git clone <repository-url>
cd backstage

# Copy environment template
cp .env.example .env
# Edit .env with your configuration

# Start all services (PostgreSQL, Redis, MinIO, Backstage, Nginx)
docker compose -f docker-compose.yaml -f docker-compose.services.yaml up -d

# View logs
docker compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f backstage

# Access the portal
open http://localhost
```

### Full Docker Commands

```bash
# Start full stack
docker compose -f docker-compose.yaml -f docker-compose.services.yaml up -d

# Stop full stack
docker compose -f docker-compose.yaml -f docker-compose.services.yaml down

# Rebuild after code changes
docker compose -f docker-compose.yaml -f docker-compose.services.yaml up -d --build backstage

# View logs
docker compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f

# Check status
docker compose -f docker-compose.yaml -f docker-compose.services.yaml ps
```

---

## Option 3: Makefile Shortcuts

The Makefile provides convenient shortcuts for common operations:

```bash
make help              # Show all available commands
make up                # Start full Docker stack
make down              # Stop full Docker stack
make dev               # Start dev environment (services only)
make build             # Build Docker image
make logs              # Tail logs
make ps                # Show container status
make devbox            # Enter Devbox shell
make devbox-services   # Start services for Devbox mode
```

---

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

| Variable | Description | Required |
|----------|-------------|----------|
| `GITHUB_TOKEN` | Personal access token for GitHub API | Yes |
| `GITHUB_CLIENT_ID` | OAuth App client ID | Yes (for auth) |
| `GITHUB_CLIENT_SECRET` | OAuth App client secret | Yes (for auth) |
| `GITHUB_ORG` | GitHub organization for team sync | Optional |
| `POSTGRES_*` | Database connection settings | Yes |
| `REDIS_*` | Cache connection settings | Yes |
| `MINIO_*` | Object storage settings | Yes |

See `.env.example` for the complete list with descriptions.

### Configuration Files

| File | Purpose |
|------|---------|
| `app-config.yaml` | Development configuration |
| `app-config.production.yaml` | Production overrides |
| `app-config.local.yaml` | Local overrides (git-ignored) |

## Development

### Available Scripts

```bash
# Start development server (frontend + backend)
yarn start

# Build production backend
yarn build:backend

# Run TypeScript compiler
yarn tsc

# Run all tests
yarn test

# Run linting
yarn lint:all

# Format code
yarn prettier:check
```

### Project Structure

```
backstage/
├── packages/
│   ├── app/                 # Frontend application
│   │   └── src/
│   │       ├── components/  # React components
│   │       └── hooks/       # Custom React hooks
│   └── backend/             # Backend application
│       └── src/
│           ├── branding/    # Branding settings plugin
│           ├── index.ts     # Backend entry point
│           ├── permissionPolicy.ts
│           ├── ownershipManagementPlugin.ts
│           └── githubTeamSyncPlugin.ts
├── catalog/                 # Software catalog entities
├── templates/               # Scaffolder templates
├── docker/                  # Docker configuration
├── .github/workflows/       # CI/CD workflows
└── app-config.yaml          # Backstage configuration
```

## Docker Deployment

### Production Build

```bash
# Build the production Docker image
docker build -t backstage:latest .

# Run with environment variables
docker run -p 7007:7007 \
  -e POSTGRES_HOST=postgres \
  -e GITHUB_TOKEN=your-token \
  backstage:latest
```

### Docker Compose

The repository includes several compose files:

| File | Purpose |
|------|---------|
| `docker-compose.yaml` | Base configuration with networks and volumes |
| `docker-compose.services.yaml` | Infrastructure services (PostgreSQL, Redis, MinIO) |
| `docker-compose.services-only.yaml` | Services only for Devbox mode |
| `docker-compose.dev.yaml` | Development with hot reload |
| `docker-compose.prod.yaml` | Production configuration |

## Troubleshooting

### Devbox Issues

**"Nix not installed" error:**
```bash
# Devbox will prompt to install Nix automatically, or install manually:
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**Package installation fails:**
```bash
# Clear Devbox cache and retry
devbox rm --all
devbox install
```

### Docker Issues

**Port already in use:**
```bash
# Check what's using the port
lsof -i :7007
lsof -i :5432

# Stop conflicting services or change ports in docker-compose
```

**Container won't start:**
```bash
# Check logs for the specific container
docker compose -f docker-compose.yaml -f docker-compose.services.yaml logs backstage

# Rebuild from scratch
docker compose -f docker-compose.yaml -f docker-compose.services.yaml down -v
docker compose -f docker-compose.yaml -f docker-compose.services.yaml up -d --build
```

### Database Issues

**Reset database:**
```bash
# Stop services and remove volumes
docker compose -f docker-compose.yaml -f docker-compose.services.yaml down -v

# Or in Devbox mode:
devbox run reset
```

## Architecture

```d2
direction: down

nginx: Nginx Reverse Proxy {
  shape: rectangle
  style.fill: "#4A90A4"
}

nginx -> frontend: Routes /
nginx -> backend: Routes /api

frontend: Frontend (React) {
  shape: rectangle
  style.fill: "#61DAFB"
  port: "3000"
}

backend: Backend API (Node.js) {
  shape: rectangle
  style.fill: "#68A063"
  port: "7007"
}

backend -> postgres: Queries
backend -> redis: Cache
backend -> minio: Assets
backend -> github: API

postgres: PostgreSQL {
  shape: cylinder
  style.fill: "#336791"
  port: "5432"
}

redis: Redis Cache {
  shape: cylinder
  style.fill: "#DC382D"
  port: "6379"
}

minio: MinIO Storage {
  shape: cylinder
  style.fill: "#C72C48"
  port: "9000/9001"
}

github: GitHub API {
  shape: cloud
  style.fill: "#333333"
}
```

### Key Components

- **Frontend (React)** - User interface built with Material-UI
- **Backend (Node.js)** - API server with plugin architecture
- **PostgreSQL** - Persistent storage for catalog, auth, and plugin data
- **Redis** - Caching layer for improved performance
- **MinIO** - S3-compatible storage for TechDocs and assets
- **Nginx** - Reverse proxy for routing and SSL termination

## Security

### Authentication

The portal supports multiple authentication providers:

- **GitHub OAuth** - Primary authentication for production
- **Guest Access** - Optional read-only access (disabled by default in production)

### Authorization

Role-based access control via group membership:

| Role | Groups | Permissions |
|------|--------|-------------|
| Admin | `admins`, `platform-admins` | Full access |
| Editor | `editors`, `developers` | Create/modify entities |
| Viewer | All authenticated users | Read-only access |

### Security Best Practices

- CORS is restricted to specific origins in production
- Guest auth is disabled by default in production
- All secrets are managed via environment variables
- TLS termination at the reverse proxy

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## Documentation

- [Complete Setup Guide](SETUP.md) - Detailed installation and configuration
- [Architecture Overview](ARCHITECTURE.md) - System design and components
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute
- [Backstage Documentation](https://backstage.io/docs) - Official Backstage docs
- [Template Development Guide](templates/README.md) - Creating custom templates

## License

This project is based on [Backstage](https://backstage.io) by Spotify.
