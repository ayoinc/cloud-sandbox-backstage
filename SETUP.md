# Complete Setup Guide

This guide provides comprehensive instructions for setting up the Cloud Sandbox Backstage Developer Portal for development and production use.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Quick Start (5 minutes)](#quick-start-5-minutes)
3. [Detailed Setup - Devbox Mode](#detailed-setup---devbox-mode)
4. [Detailed Setup - Docker Mode](#detailed-setup---docker-mode)
5. [GitHub OAuth Configuration](#github-oauth-configuration)
6. [Environment Configuration](#environment-configuration)
7. [Database Setup](#database-setup)
8. [TechDocs Configuration](#techdocs-configuration)
9. [Production Deployment](#production-deployment)
10. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Minimum Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| Docker | 24.0+ | Required for all setups |
| Docker Compose | 2.20+ | V2 compose plugin |
| RAM | 8GB | 16GB recommended |
| Disk | 20GB | For Docker images and node_modules |

### For Devbox Development (Recommended)

| Component | Version | Notes |
|-----------|---------|-------|
| Devbox | 0.10+ | Manages all dev tools |
| Nix | 2.18+ | Installed automatically by Devbox |

### For Manual Development

| Component | Version | Notes |
|-----------|---------|-------|
| Node.js | 22.x | LTS recommended |
| Yarn | 4.4.1 | Via Corepack |
| Python | 3.11+ | For TechDocs |
| D2 | 0.6+ | For diagrams |

---

## Quick Start (5 minutes)

### Option A: Devbox (Recommended)

```bash
# 1. Install Devbox (if not already installed)
curl -fsSL https://get.jetify.com/devbox | bash

# 2. Clone and enter directory
git clone https://github.com/ayointegral/cloud-sandbox-backstage.git
cd cloud-sandbox-backstage

# 3. Enter Devbox shell
devbox shell

# 4. Start services and application
devbox run services:start
cp .env.example .env
yarn install
devbox run dev

# 5. Open browser
# Frontend: http://localhost:3000
# Backend:  http://localhost:7007
```

### Option B: Full Docker

```bash
# 1. Clone and enter directory
git clone https://github.com/ayointegral/cloud-sandbox-backstage.git
cd cloud-sandbox-backstage

# 2. Configure and start
cp .env.example .env
docker compose -f docker-compose.yaml -f docker-compose.services.yaml up -d

# 3. Open browser
# Portal: http://localhost
# MinIO:  http://localhost:9001
```

---

## Detailed Setup - Devbox Mode

Devbox provides a reproducible development environment with automatic tool management.

### Step 1: Install Devbox

```bash
# Install Devbox
curl -fsSL https://get.jetify.com/devbox | bash

# Verify installation
devbox version
```

On first run, Devbox will prompt to install Nix. Accept the installation - it requires sudo access.

### Step 2: Clone the Repository

```bash
git clone https://github.com/ayointegral/cloud-sandbox-backstage.git
cd cloud-sandbox-backstage
```

### Step 3: Enter Devbox Shell

```bash
devbox shell
```

This will:
- Download and install Node.js 22, Yarn 4, Python 3.12, D2, Git, and other tools
- Set up environment variables
- Display available commands

You should see:
```
╔══════════════════════════════════════════════════════════════╗
║     Cloud Sandbox Backstage - Development Environment        ║
╚══════════════════════════════════════════════════════════════╝

  Node.js:  v22.14.0
  Yarn:     4.4.1
  Python:   3.12.12
  D2:       v0.7.1

  Available commands:
    devbox run services:start   - Start Docker services
    devbox run dev              - Start Backstage
    ...
```

### Step 4: Start Docker Services

```bash
devbox run services:start
```

This starts:
- PostgreSQL (port 5432)
- Redis (port 6379)
- MinIO (ports 9000, 9001)

Verify services are running:
```bash
devbox run services:status
```

### Step 5: Configure Environment

```bash
# Copy template
cp .env.example .env

# Edit with your values
nano .env  # or vim, code, etc.
```

**Minimum required configuration:**
```bash
# GitHub (required for authentication)
GITHUB_TOKEN=ghp_your_personal_access_token
GITHUB_CLIENT_ID=your_oauth_app_client_id
GITHUB_CLIENT_SECRET=your_oauth_app_client_secret
GITHUB_ORG=your-organization

# These have working defaults for local development:
POSTGRES_HOST=localhost
POSTGRES_USER=backstage
POSTGRES_PASSWORD=backstage
```

### Step 6: Install Dependencies

```bash
yarn install
```

### Step 7: Start Development Server

```bash
devbox run dev
```

Access the portal:
- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:7007
- **MinIO Console:** http://localhost:9001 (user: backstage, password: backstage123)

### Devbox Command Reference

| Command | Description |
|---------|-------------|
| `devbox shell` | Enter development environment |
| `devbox run services:start` | Start PostgreSQL, Redis, MinIO |
| `devbox run services:stop` | Stop all services |
| `devbox run services:status` | Check service health |
| `devbox run dev` | Start Backstage with hot reload |
| `devbox run build` | Build backend for production |
| `devbox run test` | Run test suite |
| `devbox run lint` | Run linter |
| `devbox run techdocs` | Generate TechDocs |
| `devbox run clean` | Clean build artifacts |
| `devbox run reset` | Full environment reset |

---

## Detailed Setup - Docker Mode

Run everything in Docker containers - closest to production.

### Step 1: Clone the Repository

```bash
git clone https://github.com/ayointegral/cloud-sandbox-backstage.git
cd cloud-sandbox-backstage
```

### Step 2: Configure Environment

```bash
cp .env.example .env
nano .env
```

**Required for Docker mode:**
```bash
# GitHub
GITHUB_TOKEN=ghp_your_personal_access_token
GITHUB_CLIENT_ID=your_oauth_app_client_id
GITHUB_CLIENT_SECRET=your_oauth_app_client_secret
GITHUB_ORG=your-organization

# Database (these work with the included PostgreSQL container)
POSTGRES_HOST=postgres
POSTGRES_USER=backstage
POSTGRES_PASSWORD=backstage

# MinIO (these work with the included MinIO container)
MINIO_HOST=minio
MINIO_ACCESS_KEY=backstage
MINIO_SECRET_KEY=backstage123
```

### Step 3: Start Full Stack

```bash
docker compose -f docker-compose.yaml -f docker-compose.services.yaml up -d
```

### Step 4: Verify Deployment

```bash
# Check all containers are healthy
docker compose -f docker-compose.yaml -f docker-compose.services.yaml ps

# Expected output:
# NAME                 STATUS
# backstage-app        Up (healthy)
# backstage-minio      Up (healthy)
# backstage-nginx      Up (healthy)
# backstage-postgres   Up (healthy)
# backstage-redis      Up (healthy)
```

### Step 5: Access the Portal

- **Portal:** http://localhost
- **API:** http://localhost/api
- **MinIO Console:** http://localhost:9001

### Docker Command Reference

| Command | Description |
|---------|-------------|
| `docker compose -f docker-compose.yaml -f docker-compose.services.yaml up -d` | Start full stack |
| `docker compose -f docker-compose.yaml -f docker-compose.services.yaml down` | Stop all containers |
| `docker compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f` | Tail logs |
| `docker compose -f docker-compose.yaml -f docker-compose.services.yaml ps` | Show status |
| `docker compose -f docker-compose.yaml -f docker-compose.services.yaml up -d --build` | Rebuild and start |
| `docker compose -f docker-compose.yaml -f docker-compose.services.yaml down -v` | Stop and remove volumes |

---

## GitHub OAuth Configuration

### Step 1: Create OAuth App

1. Go to GitHub > Settings > Developer settings > OAuth Apps
2. Click "New OAuth App"
3. Fill in:
   - **Application name:** Cloud Sandbox Backstage (or your preferred name)
   - **Homepage URL:** http://localhost:3000 (or your production URL)
   - **Authorization callback URL:** http://localhost:7007/api/auth/github/handler/frame

### Step 2: Get Credentials

After creating the app:
1. Copy the **Client ID**
2. Generate a new **Client Secret** and copy it

### Step 3: Create Personal Access Token

1. Go to GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic)
2. Generate new token with scopes:
   - `repo` (for scaffolder)
   - `read:org` (for team sync)
   - `read:user` (for authentication)
   - `user:email` (for user info)

### Step 4: Configure Environment

Add to your `.env`:
```bash
GITHUB_TOKEN=ghp_your_personal_access_token
GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx
GITHUB_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GITHUB_ORG=your-organization
```

---

## Environment Configuration

### Complete Environment Variables

```bash
# =============================================================================
# GitHub Integration (Required)
# =============================================================================
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx
GITHUB_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GITHUB_ORG=your-organization

# =============================================================================
# Database (Required)
# =============================================================================
POSTGRES_HOST=localhost          # Use 'postgres' for Docker mode
POSTGRES_PORT=5432
POSTGRES_USER=backstage
POSTGRES_PASSWORD=backstage
POSTGRES_DB=backstage

# =============================================================================
# Redis Cache (Required)
# =============================================================================
REDIS_HOST=localhost             # Use 'redis' for Docker mode
REDIS_PORT=6379

# =============================================================================
# MinIO/S3 Storage (Required)
# =============================================================================
MINIO_HOST=localhost             # Use 'minio' for Docker mode
MINIO_PORT=9000
MINIO_ROOT_USER=backstage
MINIO_ROOT_PASSWORD=backstage123
MINIO_ACCESS_KEY=backstage
MINIO_SECRET_KEY=backstage123
TECHDOCS_BUCKET=techdocs
BRANDING_BUCKET=backstage-assets

# =============================================================================
# Authentication (Optional)
# =============================================================================
AUTH_SESSION_SECRET=change-me-to-a-random-string-in-production
GUEST_AUTH_ENABLED=true          # Set to 'false' in production

# =============================================================================
# Security (Production)
# =============================================================================
CORS_ORIGIN=http://localhost     # Set to your domain in production

# =============================================================================
# Branding Admin (Optional)
# =============================================================================
BRANDING_INITIAL_ADMIN=your-github-username
BRANDING_ADMIN_USERS=user1,user2,user3
```

---

## Database Setup

### Automatic Setup

The database schema is created automatically on first run via migrations.

### Manual Database Access

```bash
# Devbox mode
psql -h localhost -U backstage -d backstage

# Docker mode
docker exec -it backstage-postgres psql -U backstage -d backstage
```

### Reset Database

```bash
# Devbox mode
devbox run reset

# Docker mode
docker compose -f docker-compose.yaml -f docker-compose.services.yaml down -v
docker compose -f docker-compose.yaml -f docker-compose.services.yaml up -d
```

---

## TechDocs Configuration

### Generate Documentation

```bash
# Devbox mode
devbox run techdocs

# Manual mode
cd catalog/some-component
mkdocs build
```

### TechDocs Storage

TechDocs are stored in MinIO (S3-compatible storage):
- **Bucket:** techdocs
- **Console:** http://localhost:9001

### D2 Diagrams

D2 diagrams are supported in TechDocs. Example:

```markdown
# Architecture

```d2
user -> frontend: HTTPS
frontend -> backend: API calls
backend -> database: Queries
```
```

---

## Production Deployment

### Step 1: Build Production Image

```bash
docker build -t backstage:latest .
```

### Step 2: Configure Production Environment

Create `.env.production`:
```bash
NODE_ENV=production
POSTGRES_HOST=your-production-db.example.com
POSTGRES_PASSWORD=your-secure-password
GITHUB_CLIENT_ID=your-production-client-id
GITHUB_CLIENT_SECRET=your-production-secret
AUTH_SESSION_SECRET=your-random-session-secret
GUEST_AUTH_ENABLED=false
CORS_ORIGIN=https://backstage.your-domain.com
```

### Step 3: Deploy

```bash
docker compose -f docker-compose.yaml -f docker-compose.services.yaml -f docker-compose.prod.yaml up -d
```

### Production Checklist

- [ ] Set strong passwords for PostgreSQL, MinIO
- [ ] Set `GUEST_AUTH_ENABLED=false`
- [ ] Configure proper `CORS_ORIGIN`
- [ ] Set random `AUTH_SESSION_SECRET`
- [ ] Configure TLS/SSL via reverse proxy
- [ ] Set up database backups
- [ ] Configure monitoring and logging

---

## Troubleshooting

### Devbox Issues

**"Nix is not installed" error:**
```bash
# Install Nix manually
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Restart terminal, then retry
devbox shell
```

**Packages fail to install:**
```bash
# Clear cache and retry
devbox rm --all
rm -rf .devbox
devbox shell
```

**Wrong Node.js version:**
```bash
# Verify you're in Devbox shell
node --version  # Should show v22.x

# If not, enter shell
devbox shell
```

### Docker Issues

**Container won't start:**
```bash
# Check logs
docker compose -f docker-compose.yaml -f docker-compose.services.yaml logs backstage

# Common fix: rebuild
docker compose -f docker-compose.yaml -f docker-compose.services.yaml down
docker compose -f docker-compose.yaml -f docker-compose.services.yaml up -d --build
```

**Port already in use:**
```bash
# Find what's using the port
lsof -i :7007
lsof -i :5432
lsof -i :6379

# Kill the process or change ports in docker-compose
```

**Out of disk space:**
```bash
# Clean up Docker
docker system prune -a --volumes
```

### Database Issues

**Connection refused:**
```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Check connection
psql -h localhost -U backstage -d backstage -c "SELECT 1"
```

**Migration errors:**
```bash
# Reset and retry
docker compose -f docker-compose.yaml -f docker-compose.services.yaml down -v
docker compose -f docker-compose.yaml -f docker-compose.services.yaml up -d
```

### Authentication Issues

**GitHub OAuth fails:**
1. Verify callback URL matches exactly: `http://localhost:7007/api/auth/github/handler/frame`
2. Check `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` are correct
3. Ensure OAuth app is not suspended

**"Guest access disabled" error:**
```bash
# Enable guest access for development
echo "GUEST_AUTH_ENABLED=true" >> .env
```

### Build Issues

**yarn install fails:**
```bash
# Clear cache
rm -rf node_modules .yarn/cache
yarn cache clean
yarn install
```

**Build fails:**
```bash
# Clear build artifacts
yarn clean
yarn build:backend
```

---

## Getting Help

- **Issues:** https://github.com/ayointegral/cloud-sandbox-backstage/issues
- **Backstage Docs:** https://backstage.io/docs
- **Backstage Discord:** https://discord.gg/backstage-687207715902193673

---

## Next Steps

After setup is complete:

1. **Explore the Catalog** - Browse software components at http://localhost:3000/catalog
2. **Create a Component** - Use templates at http://localhost:3000/create
3. **Read the Docs** - View TechDocs at http://localhost:3000/docs
4. **Configure Branding** - Customize logo and colors (admin only)
5. **Add Your Components** - Register your own software in the catalog
