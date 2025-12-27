# ${{ values.name }}

${{ values.description }}

## Overview

This Node.js API service provides a production-ready foundation with:

- Express.js framework with TypeScript support
- Security middleware (Helmet, CORS, compression)
- Structured logging with Pino
- Health check endpoints for Kubernetes probes
- Docker containerization with multi-stage builds
- Comprehensive CI/CD pipeline with GitHub Actions
- Testing framework with Jest coverage reporting

```d2
direction: right

title: {
  label: Node.js API Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

client: Client {
  shape: cloud
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

api: ${{ values.name }} API {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  middleware: Middleware Layer {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"

    helmet: Helmet {
      label: "Security\nHeaders"
    }
    cors: CORS {
      label: "Cross-Origin\nRequests"
    }
    compression: Compression {
      label: "Response\nCompression"
    }
    logger: Pino Logger {
      label: "Request\nLogging"
    }
  }

  routes: Route Handlers {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"

    health: /health {
      label: "Health\nEndpoints"
    }
    api_routes: /api {
      label: "API\nEndpoints"
    }
  }

  services: Business Logic {
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"

    logic: Services {
      label: "Business\nLogic"
    }
  }

  middleware -> routes
  routes -> services
}

database: Database {
  shape: cylinder
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

cache: Cache {
  shape: cylinder
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

client -> api.middleware: HTTPS
api.services -> database: Query
api.services -> cache: Read/Write
```

## Configuration Summary

| Setting         | Value                     |
| --------------- | ------------------------- |
| **Name**        | `${{ values.name }}`      |
| **Owner**       | ${{ values.owner }}       |
| **Environment** | `${{ values.environment }}`|
| **Framework**   | ${{ values.framework }}   |
| **Port**        | `${{ values.port }}`      |
| **Node Version**| `>=18.0.0`                |

## Project Structure

```
${{ values.name }}/
├── .github/
│   └── workflows/
│       └── nodejs.yaml       # CI/CD pipeline configuration
├── src/
│   ├── __tests__/
│   │   └── api.test.ts       # Unit tests
│   ├── routes/
│   │   ├── api.ts            # API route handlers
│   │   └── health.ts         # Health check endpoints
│   ├── config.ts             # Application configuration
│   └── index.ts              # Application entry point
├── tests/
│   └── api.test.ts           # Integration tests
├── docs/
│   └── index.md              # This documentation
├── .dockerignore             # Docker ignore patterns
├── Dockerfile                # Multi-stage Docker build
├── catalog-info.yaml         # Backstage catalog metadata
├── mkdocs.yml                # Documentation configuration
├── package.json              # Dependencies and scripts
├── tsconfig.json             # TypeScript configuration
└── vitest.config.ts          # Test runner configuration
```

### Key Files

| File                 | Purpose                                          |
| -------------------- | ------------------------------------------------ |
| `src/index.ts`       | Express app initialization and middleware setup  |
| `src/config.ts`      | Environment variable configuration               |
| `src/routes/api.ts`  | API endpoint definitions                         |
| `src/routes/health.ts`| Kubernetes health probe endpoints               |
| `Dockerfile`         | Production container image build                 |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Linting**: ESLint and Prettier formatting checks
- **Testing**: Jest with coverage reporting to Codecov
- **Building**: TypeScript compilation and artifact upload
- **Docker**: Container image build and push to GitHub Container Registry
- **Security**: Automated dependency scanning

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

lint: Lint {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "ESLint\nPrettier"
}

test: Test {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Jest\nCoverage"
}

build: Build {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "TypeScript\nCompile"
}

docker: Docker {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
  label: "Build Image\nPush to GHCR"
}

deploy: Deploy {
  shape: oval
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

pr -> lint -> test -> build -> docker -> deploy
```

### Workflow Triggers

| Trigger       | Actions                                       |
| ------------- | --------------------------------------------- |
| Pull Request  | Lint, Test, Build                             |
| Push to main  | Lint, Test, Build, Docker Build & Push        |

### Container Registry

Images are automatically pushed to GitHub Container Registry:

```
ghcr.io/<organization>/${{ values.name }}:latest
ghcr.io/<organization>/${{ values.name }}:sha-<commit>
```

---

## Prerequisites

### 1. Node.js Runtime

Ensure Node.js 18+ is installed:

```bash
# Check Node.js version
node --version  # Should be v18.x.x or higher

# Install using nvm (recommended)
nvm install 20
nvm use 20

# Or using Homebrew (macOS)
brew install node@20
```

### 2. npm Package Manager

npm comes bundled with Node.js:

```bash
# Check npm version
npm --version  # Should be v9.x.x or higher

# Update npm to latest
npm install -g npm@latest
```

### 3. Docker (Optional)

Required for containerized deployment:

```bash
# Check Docker version
docker --version  # Should be v20.x.x or higher

# Install Docker Desktop
# macOS: brew install --cask docker
# Linux: https://docs.docker.com/engine/install/
```

### 4. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret          | Description                              | Required |
| --------------- | ---------------------------------------- | -------- |
| `GITHUB_TOKEN`  | Auto-generated token for GHCR access     | Auto     |
| `CODECOV_TOKEN` | Token for coverage reporting (optional)  | No       |

#### Repository Permissions

Ensure the repository has package write permissions:

1. Go to **Settings > Actions > General**
2. Under "Workflow permissions", select "Read and write permissions"
3. Check "Allow GitHub Actions to create and approve pull requests"

---

## Usage

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Install dependencies
npm install

# Create environment file
cp .env.example .env  # If available

# Run in development mode (with hot reload)
npm run dev

# Server will start at http://localhost:${{ values.port }}
```

### npm Commands

| Command               | Description                              |
| --------------------- | ---------------------------------------- |
| `npm run dev`         | Start development server with hot reload |
| `npm run build`       | Compile TypeScript to JavaScript         |
| `npm start`           | Run production server                    |
| `npm test`            | Run tests with coverage                  |
| `npm run test:watch`  | Run tests in watch mode                  |
| `npm run lint`        | Run ESLint                               |
| `npm run lint:fix`    | Fix ESLint issues automatically          |
| `npm run format`      | Format code with Prettier                |
| `npm run format:check`| Check code formatting                    |

### Docker Usage

#### Build and Run Locally

```bash
# Build the Docker image
docker build -t ${{ values.name }} .

# Run the container
docker run -p ${{ values.port }}:${{ values.port }} ${{ values.name }}

# Run with environment variables
docker run -p ${{ values.port }}:${{ values.port }} \
  -e NODE_ENV=production \
  -e PORT=${{ values.port }} \
  ${{ values.name }}

# Run in detached mode
docker run -d -p ${{ values.port }}:${{ values.port }} --name ${{ values.name }} ${{ values.name }}

# View logs
docker logs -f ${{ values.name }}

# Stop container
docker stop ${{ values.name }}
```

#### Docker Compose (Recommended for Development)

Create a `docker-compose.yml`:

```yaml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "${{ values.port }}:${{ values.port }}"
    environment:
      - NODE_ENV=development
      - PORT=${{ values.port }}
    volumes:
      - ./src:/app/src:ro
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:${{ values.port }}/health"]
      interval: 30s
      timeout: 3s
      retries: 3
```

---

## API Documentation

### Base URL

```
http://localhost:${{ values.port }}
```

### Endpoints

#### Health Endpoints

| Endpoint        | Method | Description                    | Response               |
| --------------- | ------ | ------------------------------ | ---------------------- |
| `/health`       | GET    | Overall health status          | `{ status, timestamp }`|
| `/health/ready` | GET    | Readiness probe for Kubernetes | `{ ready: boolean }`   |
| `/health/live`  | GET    | Liveness probe for Kubernetes  | `{ alive: boolean }`   |

#### API Endpoints

| Endpoint       | Method | Description       | Response                    |
| -------------- | ------ | ----------------- | --------------------------- |
| `/api`         | GET    | API root/info     | `{ message, version }`      |
| `/api/example` | GET    | Example endpoint  | `{ data: "Example" }`       |

### Example Requests

```bash
# Health check
curl http://localhost:${{ values.port }}/health
# Response: {"status":"healthy","timestamp":"2024-01-15T10:30:00.000Z","service":"${{ values.name }}","environment":"${{ values.environment }}"}

# Readiness probe
curl http://localhost:${{ values.port }}/health/ready
# Response: {"ready":true}

# Liveness probe
curl http://localhost:${{ values.port }}/health/live
# Response: {"alive":true}

# API root
curl http://localhost:${{ values.port }}/api
# Response: {"message":"Welcome to ${{ values.name }} API","version":"1.0.0"}
```

### Error Responses

All errors follow a consistent format:

```json
{
  "error": "Error message description",
  "statusCode": 500
}
```

| Status Code | Description                                |
| ----------- | ------------------------------------------ |
| 400         | Bad Request - Invalid input                |
| 401         | Unauthorized - Authentication required     |
| 403         | Forbidden - Insufficient permissions       |
| 404         | Not Found - Resource doesn't exist         |
| 500         | Internal Server Error                      |

---

## Testing Strategy

This project uses a dual testing approach with both Jest and Vitest support.

### Test Structure

```
├── src/__tests__/           # Unit tests (co-located)
│   └── api.test.ts
└── tests/                   # Integration tests
    └── api.test.ts
```

### Running Tests

```bash
# Run all tests with coverage
npm test

# Run tests in watch mode
npm run test:watch

# Run specific test file
npm test -- api.test.ts

# Run with verbose output
npm test -- --verbose
```

### Coverage Requirements

Coverage thresholds are configured in `vitest.config.ts`:

| Metric     | Threshold |
| ---------- | --------- |
| Branches   | 70%       |
| Functions  | 70%       |
| Lines      | 70%       |
| Statements | 70%       |

### Test Categories

#### Unit Tests

Located in `src/__tests__/`, these test individual functions and modules:

```typescript
describe('Health Endpoints', () => {
  it('GET /health should return healthy status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('healthy');
  });
});
```

#### Integration Tests

Located in `tests/`, these test the full API flow:

```typescript
describe('API Endpoints', () => {
  it('should return 404 for unknown routes', async () => {
    const response = await request(app).get('/unknown-route');
    expect(response.status).toBe(404);
  });
});
```

### Mocking

Use Jest mocking for external dependencies:

```typescript
jest.mock('../services/database', () => ({
  query: jest.fn().mockResolvedValue({ rows: [] }),
}));
```

---

## Security Features

This API includes multiple layers of security:

### Middleware Protection

| Middleware    | Purpose                                      |
| ------------- | -------------------------------------------- |
| **Helmet**    | Sets security HTTP headers                   |
| **CORS**      | Controls cross-origin resource sharing       |
| **Compression**| Compresses responses (also prevents attacks)|

### Helmet Security Headers

Helmet automatically sets these headers:

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security` (HSTS)
- `Content-Security-Policy`

### Docker Security

The Dockerfile implements security best practices:

```dockerfile
# Non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs

# Production dependencies only
RUN npm ci --only=production

# Health check configured
HEALTHCHECK --interval=30s --timeout=3s CMD wget --spider http://localhost:${{ values.port }}/health
```

### Recommended Additional Security

1. **Rate Limiting**: Add `express-rate-limit`
   ```typescript
   import rateLimit from 'express-rate-limit';
   app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));
   ```

2. **Input Validation**: Add `express-validator` or `zod`
   ```typescript
   import { z } from 'zod';
   const schema = z.object({ name: z.string().min(1) });
   ```

3. **Request Sanitization**: Add `express-mongo-sanitize` or `xss-clean`

4. **API Key Authentication**: Implement middleware for protected routes

---

## Troubleshooting

### Common Issues

#### Port Already in Use

**Error:**
```
Error: listen EADDRINUSE: address already in use :::${{ values.port }}
```

**Resolution:**
```bash
# Find process using the port
lsof -i :${{ values.port }}

# Kill the process
kill -9 <PID>

# Or use a different port
PORT=3001 npm run dev
```

#### Module Not Found

**Error:**
```
Error: Cannot find module 'express'
```

**Resolution:**
```bash
# Remove node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

#### TypeScript Compilation Errors

**Error:**
```
error TS2307: Cannot find module './config'
```

**Resolution:**
```bash
# Rebuild TypeScript
npm run build

# Check tsconfig.json paths
cat tsconfig.json
```

#### Docker Build Fails

**Error:**
```
npm ERR! code ENOENT
```

**Resolution:**
```bash
# Ensure package-lock.json exists
npm install

# Rebuild without cache
docker build --no-cache -t ${{ values.name }} .
```

#### Tests Failing in CI

**Error:**
```
Jest encountered an unexpected token
```

**Resolution:**
1. Ensure `ts-jest` is properly configured
2. Check Jest config in `package.json`:
   ```json
   {
     "jest": {
       "preset": "ts-jest",
       "testEnvironment": "node"
     }
   }
   ```

### Debug Mode

Enable debug logging:

```bash
# Set log level to debug
LOG_LEVEL=debug npm run dev

# Enable Node.js debugging
node --inspect dist/index.js
```

### Health Check Debugging

```bash
# Test health endpoint
curl -v http://localhost:${{ values.port }}/health

# Check Docker container health
docker inspect --format='{{.State.Health.Status}}' ${{ values.name }}
```

---

## Related Templates

| Template                                                          | Description                        |
| ----------------------------------------------------------------- | ---------------------------------- |
| [app-nodejs-api](/docs/default/template/app-nodejs-api)           | Node.js Express API (this template)|
| [app-nodejs-fastify](/docs/default/template/app-nodejs-fastify)   | Node.js Fastify API                |
| [app-python-api](/docs/default/template/app-python-api)           | Python FastAPI service             |
| [app-go-api](/docs/default/template/app-go-api)                   | Go HTTP API service                |
| [app-java-spring](/docs/default/template/app-java-spring)         | Java Spring Boot API               |
| [aws-eks](/docs/default/template/aws-eks)                         | Amazon EKS Kubernetes cluster      |
| [aws-rds](/docs/default/template/aws-rds)                         | Amazon RDS PostgreSQL database     |

---

## References

- [Express.js Documentation](https://expressjs.com/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Docker Node.js Guide](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)
- [GitHub Actions Node.js](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-nodejs)
- [Jest Testing Framework](https://jestjs.io/docs/getting-started)
- [Helmet.js Security](https://helmetjs.github.io/)
- [Pino Logger](https://getpino.io/)
- [Backstage Software Catalog](https://backstage.io/docs/features/software-catalog/)
