# Node.js REST API

Production-ready Node.js REST API built with Express 5 and PostgreSQL 17, featuring TypeScript 5.7, authentication, validation, testing, Docker containerization, and CI/CD pipeline integration.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/example/sample-nodejs-api.git
cd sample-nodejs-api

# Install dependencies (using pnpm for speed)
pnpm install

# Set up environment
cp .env.example .env

# Start PostgreSQL 17 (using Docker)
docker run -d \
  --name postgres-dev \
  -e POSTGRES_USER=api_user \
  -e POSTGRES_PASSWORD=api_password \
  -e POSTGRES_DB=api_db \
  -p 5432:5432 \
  postgres:17-alpine

# Run database migrations
pnpm db:migrate

# Seed development data
pnpm db:seed

# Start development server
pnpm dev

# API is available at http://localhost:3000
# Swagger docs at http://localhost:3000/api/docs
```

## Features

| Feature                | Description                         | Status    |
| ---------------------- | ----------------------------------- | --------- |
| **Node.js 22 LTS**     | Latest LTS with native TypeScript   | ✅ Stable |
| **Express.js 5.0**     | Async middleware, promise support   | ✅ Stable |
| **TypeScript 5.7**     | Type-safe with verbatimModuleSyntax | ✅ Stable |
| **PostgreSQL 17**      | Relational database with Prisma 6   | ✅ Stable |
| **Prisma 6**           | Type-safe ORM with edge support     | ✅ Stable |
| **JWT Authentication** | Secure token-based auth (jose)      | ✅ Stable |
| **Role-Based Access**  | RBAC with permissions               | ✅ Stable |
| **Input Validation**   | Zod 3.24+ schema validation         | ✅ Stable |
| **API Documentation**  | OpenAPI 3.1 / Scalar UI             | ✅ Stable |
| **Rate Limiting**      | Redis 8 backed rate limiting        | ✅ Stable |
| **Request Logging**    | Pino 9 structured logging           | ✅ Stable |
| **Health Checks**      | Kubernetes 1.31+ ready probes       | ✅ Stable |
| **Testing**            | Vitest 2.1 with 90%+ coverage       | ✅ Stable |
| **Docker**             | Multi-stage production builds       | ✅ Stable |
| **CI/CD**              | GitHub Actions pipeline             | ✅ Stable |
| **OpenTelemetry**      | Distributed tracing & metrics       | ✅ Stable |

## Architecture

```d2
direction: down

title: Node.js REST API {
  shape: text
  near: top-center
  style.font-size: 20
  style.bold: true
}

request_flow: Request Flow {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  client: Client Request {
    shape: oval
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"
  }

  middleware: Middleware Pipeline {
    direction: right

    cors: CORS {
      shape: hexagon
    }
    rate: Rate Limiter {
      shape: hexagon
    }
    auth: Auth {
      shape: hexagon
    }
    validate: Validate {
      shape: hexagon
    }
    controller: Controller {
      shape: hexagon
      style.fill: "#E8F5E9"
      style.stroke: "#388E3C"
    }

    cors -> rate -> auth -> validate -> controller
  }

  client -> middleware.cors
}

service_layer: Service Layer {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  user_svc: UserService {
    shape: hexagon
  }
  order_svc: OrderService {
    shape: hexagon
  }
  product_svc: ProductService {
    shape: hexagon
  }
}

repo_layer: Repository Layer {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"

  user_repo: UserRepo
  order_repo: OrderRepo
  product_repo: ProductRepo
}

prisma: Prisma ORM (PostgreSQL) {
  shape: cylinder
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

external: External Services {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  postgres: PostgreSQL {
    shape: cylinder
  }
  redis: Redis Cache {
    shape: cylinder
  }
  s3: S3 Storage {
    shape: cloud
  }
  email: Email Service {
    shape: cloud
  }
}

request_flow.middleware.controller -> service_layer
service_layer -> repo_layer
repo_layer -> prisma
prisma -> external.postgres
service_layer.user_svc -> external.redis: "caching" {
  style.stroke-dash: 5
}
service_layer.product_svc -> external.s3: "files" {
  style.stroke-dash: 5
}
```

## Project Structure

```
sample-nodejs-api/
├── src/
│   ├── index.ts                 # Application entry point
│   ├── app.ts                   # Express 5 app configuration
│   ├── config/
│   │   ├── index.ts             # Configuration loader (with Zod)
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
│   │   ├── auth.middleware.ts   # JWT verification (jose)
│   │   ├── rbac.middleware.ts   # Role-based access
│   │   ├── validate.middleware.ts
│   │   ├── error.middleware.ts
│   │   └── rateLimit.middleware.ts
│   ├── schemas/
│   │   ├── auth.schema.ts       # Zod validation schemas
│   │   ├── user.schema.ts
│   │   ├── product.schema.ts
│   │   └── order.schema.ts
│   ├── tracing/
│   │   └── otel.ts              # OpenTelemetry configuration
│   ├── types/
│   │   ├── express.d.ts         # Express type extensions
│   │   └── index.ts
│   └── lib/
│       ├── logger.ts            # Pino 9 logger
│       ├── jwt.ts               # JWT utilities (jose)
│       ├── password.ts          # Password hashing (argon2)
│       ├── prisma.ts            # Prisma 6 client
│       └── response.ts          # Response helpers
├── prisma/
│   ├── schema.prisma            # Prisma 6 schema
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
├── biome.json                   # Biome linting/formatting
└── vitest.config.ts             # Vitest configuration
```

## API Endpoints

| Method   | Endpoint             | Description          | Auth Required |
| -------- | -------------------- | -------------------- | ------------- |
| `POST`   | `/api/auth/register` | Register new user    | No            |
| `POST`   | `/api/auth/login`    | User login           | No            |
| `POST`   | `/api/auth/refresh`  | Refresh access token | No            |
| `POST`   | `/api/auth/logout`   | User logout          | Yes           |
| `GET`    | `/api/users`         | List users           | Yes (Admin)   |
| `GET`    | `/api/users/:id`     | Get user by ID       | Yes           |
| `PUT`    | `/api/users/:id`     | Update user          | Yes           |
| `DELETE` | `/api/users/:id`     | Delete user          | Yes (Admin)   |
| `GET`    | `/api/products`      | List products        | No            |
| `GET`    | `/api/products/:id`  | Get product          | No            |
| `POST`   | `/api/products`      | Create product       | Yes (Admin)   |
| `PUT`    | `/api/products/:id`  | Update product       | Yes (Admin)   |
| `DELETE` | `/api/products/:id`  | Delete product       | Yes (Admin)   |
| `GET`    | `/api/orders`        | List user orders     | Yes           |
| `POST`   | `/api/orders`        | Create order         | Yes           |
| `GET`    | `/api/orders/:id`    | Get order            | Yes           |
| `GET`    | `/health`            | Health check         | No            |
| `GET`    | `/health/live`       | Liveness probe       | No            |
| `GET`    | `/health/ready`      | Readiness probe      | No            |

## Related Documentation

- [Overview](overview.md) - Detailed architecture, configuration, and security
- [Usage](usage.md) - Development, testing, deployment, and troubleshooting
