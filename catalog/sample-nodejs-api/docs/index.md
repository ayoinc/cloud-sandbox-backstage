# Node.js REST API

Production-ready Node.js REST API built with Express.js and PostgreSQL, featuring TypeScript, authentication, validation, testing, Docker containerization, and CI/CD pipeline integration.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/example/sample-nodejs-api.git
cd sample-nodejs-api

# Install dependencies
npm install

# Set up environment
cp .env.example .env

# Start PostgreSQL (using Docker)
docker run -d \
  --name postgres-dev \
  -e POSTGRES_USER=api_user \
  -e POSTGRES_PASSWORD=api_password \
  -e POSTGRES_DB=api_db \
  -p 5432:5432 \
  postgres:16-alpine

# Run database migrations
npm run db:migrate

# Seed development data
npm run db:seed

# Start development server
npm run dev

# API is available at http://localhost:3000
# Swagger docs at http://localhost:3000/api/docs
```

## Features

| Feature | Description | Status |
|---------|-------------|--------|
| **Express.js 4.x** | Fast, minimalist web framework | ✅ Stable |
| **TypeScript 5.x** | Type-safe development | ✅ Stable |
| **PostgreSQL 16** | Relational database with Prisma ORM | ✅ Stable |
| **JWT Authentication** | Secure token-based auth | ✅ Stable |
| **Role-Based Access** | RBAC with permissions | ✅ Stable |
| **Input Validation** | Zod schema validation | ✅ Stable |
| **API Documentation** | OpenAPI 3.0 / Swagger UI | ✅ Stable |
| **Rate Limiting** | Redis-backed rate limiting | ✅ Stable |
| **Request Logging** | Pino structured logging | ✅ Stable |
| **Health Checks** | Kubernetes-ready probes | ✅ Stable |
| **Testing** | Jest with 90%+ coverage | ✅ Stable |
| **Docker** | Multi-stage production builds | ✅ Stable |
| **CI/CD** | GitHub Actions pipeline | ✅ Stable |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Node.js REST API                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                         Request Flow                                  │   │
│  │                                                                       │   │
│  │  Client Request                                                       │   │
│  │       │                                                               │   │
│  │       ▼                                                               │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────┐ │   │
│  │  │  CORS   │─▶│  Rate   │─▶│  Auth   │─▶│ Validate│─▶│  Controller │ │   │
│  │  │Middleware│  │ Limiter │  │Middleware│  │ Schema  │  │   Handler   │ │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └──────┬──────┘ │   │
│  │                                                              │        │   │
│  │                                                              ▼        │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │   │
│  │  │                        Service Layer                            │ │   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │ │   │
│  │  │  │ UserService │  │OrderService │  │ProductService│             │ │   │
│  │  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘             │ │   │
│  │  │         │                │                │                     │ │   │
│  │  └─────────┼────────────────┼────────────────┼─────────────────────┘ │   │
│  │            │                │                │                       │   │
│  │            ▼                ▼                ▼                       │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │   │
│  │  │                      Repository Layer                           │ │   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │ │   │
│  │  │  │  UserRepo   │  │  OrderRepo  │  │ ProductRepo │             │ │   │
│  │  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘             │ │   │
│  │  │         │                │                │                     │ │   │
│  │  └─────────┼────────────────┼────────────────┼─────────────────────┘ │   │
│  │            │                │                │                       │   │
│  │            └────────────────┼────────────────┘                       │   │
│  │                             ▼                                        │   │
│  │                    ┌─────────────────┐                               │   │
│  │                    │   Prisma ORM    │                               │   │
│  │                    │  (PostgreSQL)   │                               │   │
│  │                    └─────────────────┘                               │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                      External Services                                │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────────────┐  │   │
│  │  │PostgreSQL │  │   Redis   │  │    S3     │  │   Email Service   │  │   │
│  │  │ Database  │  │   Cache   │  │  Storage  │  │    (SendGrid)     │  │   │
│  │  └───────────┘  └───────────┘  └───────────┘  └───────────────────┘  │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
sample-nodejs-api/
├── src/
│   ├── index.ts                 # Application entry point
│   ├── app.ts                   # Express app configuration
│   ├── config/
│   │   ├── index.ts             # Configuration loader
│   │   ├── database.ts          # Database configuration
│   │   └── auth.ts              # Auth configuration
│   ├── controllers/
│   │   ├── auth.controller.ts   # Authentication endpoints
│   │   ├── users.controller.ts  # User management
│   │   ├── products.controller.ts
│   │   └── orders.controller.ts
│   ├── services/
│   │   ├── auth.service.ts
│   │   ├── users.service.ts
│   │   ├── products.service.ts
│   │   └── orders.service.ts
│   ├── repositories/
│   │   ├── users.repository.ts
│   │   ├── products.repository.ts
│   │   └── orders.repository.ts
│   ├── middleware/
│   │   ├── auth.middleware.ts   # JWT verification
│   │   ├── rbac.middleware.ts   # Role-based access
│   │   ├── validate.middleware.ts
│   │   ├── error.middleware.ts
│   │   └── rateLimit.middleware.ts
│   ├── schemas/
│   │   ├── auth.schema.ts       # Zod validation schemas
│   │   ├── user.schema.ts
│   │   ├── product.schema.ts
│   │   └── order.schema.ts
│   ├── types/
│   │   ├── express.d.ts         # Express type extensions
│   │   └── index.ts
│   └── utils/
│       ├── logger.ts            # Pino logger
│       ├── jwt.ts               # JWT utilities
│       ├── password.ts          # Password hashing
│       └── response.ts          # Response helpers
├── prisma/
│   ├── schema.prisma            # Database schema
│   ├── migrations/              # Database migrations
│   └── seed.ts                  # Seed data
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yaml
├── .github/
│   └── workflows/
│       └── ci.yaml
├── package.json
├── tsconfig.json
└── jest.config.js
```

## API Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `POST` | `/api/auth/register` | Register new user | No |
| `POST` | `/api/auth/login` | User login | No |
| `POST` | `/api/auth/refresh` | Refresh access token | No |
| `POST` | `/api/auth/logout` | User logout | Yes |
| `GET` | `/api/users` | List users | Yes (Admin) |
| `GET` | `/api/users/:id` | Get user by ID | Yes |
| `PUT` | `/api/users/:id` | Update user | Yes |
| `DELETE` | `/api/users/:id` | Delete user | Yes (Admin) |
| `GET` | `/api/products` | List products | No |
| `GET` | `/api/products/:id` | Get product | No |
| `POST` | `/api/products` | Create product | Yes (Admin) |
| `PUT` | `/api/products/:id` | Update product | Yes (Admin) |
| `DELETE` | `/api/products/:id` | Delete product | Yes (Admin) |
| `GET` | `/api/orders` | List user orders | Yes |
| `POST` | `/api/orders` | Create order | Yes |
| `GET` | `/api/orders/:id` | Get order | Yes |
| `GET` | `/health` | Health check | No |
| `GET` | `/health/live` | Liveness probe | No |
| `GET` | `/health/ready` | Readiness probe | No |

## Related Documentation

- [Overview](overview.md) - Detailed architecture, configuration, and security
- [Usage](usage.md) - Development, testing, deployment, and troubleshooting
