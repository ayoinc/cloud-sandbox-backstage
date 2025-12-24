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

- Node.js 22 or 24
- Yarn 4.4.1 (installed via Corepack)
- Docker and Docker Compose (for full stack)

### Development Setup

```bash
# Clone the repository
git clone <repository-url>
cd backstage

# Enable Corepack for Yarn
corepack enable

# Install dependencies
yarn install

# Copy environment template
cp .env.example .env
# Edit .env with your configuration

# Start development server
yarn start
```

### Docker Deployment

```bash
# Start all services (PostgreSQL, Redis, MinIO, Backstage)
docker compose up -d

# View logs
docker compose logs -f backstage

# Access the portal
open http://localhost
```

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
| `docker-compose.yaml` | Full stack deployment |
| `docker-compose.dev.yaml` | Development with hot reload |
| `docker-compose.services.yaml` | Infrastructure services only |
| `docker-compose.prod.yaml` | Production configuration |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Nginx (Reverse Proxy)                    │
│                            Port 80/443                           │
└─────────────────────────────────────────────────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
            ┌───────▼───────┐           ┌────────▼────────┐
            │   Frontend    │           │   Backend API   │
            │   (React)     │           │   (Node.js)     │
            │   Port 3000   │           │   Port 7007     │
            └───────────────┘           └────────┬────────┘
                                                 │
        ┌────────────────────────────────────────┼────────────────┐
        │                        │               │                │
┌───────▼───────┐    ┌──────────▼──────────┐ ┌──▼───┐     ┌──────▼──────┐
│  PostgreSQL   │    │       MinIO         │ │Redis │     │   GitHub    │
│   Database    │    │  (TechDocs/Assets)  │ │Cache │     │     API     │
│   Port 5432   │    │   Port 9000/9001    │ │ 6379 │     │             │
└───────────────┘    └─────────────────────┘ └──────┘     └─────────────┘
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

- [Architecture Overview](ARCHITECTURE.md)
- [Backstage Documentation](https://backstage.io/docs)
- [Template Development Guide](templates/README.md)

## License

This project is based on [Backstage](https://backstage.io) by Spotify.
