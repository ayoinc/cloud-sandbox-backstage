# Overview

## Architecture Deep Dive

### Request Processing Pipeline

```d2
direction: down

title: Express 5 Request Pipeline {
  shape: text
  near: top-center
  style.font-size: 20
  style.bold: true
}

request: HTTP Request {
  shape: oval
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

step1: "1. Global Middleware" {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  helmet: "helmet() - Security headers"
  cors: "cors() - Cross-origin requests"
  json: "express.json() - Body parsing"
  pino: "pinoHttp() - Request logging"
  reqId: "requestId() - Correlation ID"
}

step2: "2. Rate Limiting (Redis-backed)" {
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"

  ip_limit: "IP-based limiting"
  user_limit: "User-based limiting"
  endpoint_limit: "Endpoint-specific limits"
}

step3: "3. Route Matching" {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

step4: "4. Authentication Middleware" {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  extract: "Extract JWT from header"
  verify: "Verify token signature"
  attach: "Attach user to request"
}

step5: "5. Authorization Middleware (RBAC)" {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  role: "Check user role"
  perms: "Verify permissions"
}

step6: "6. Validation Middleware (Zod)" {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  body: "Validate request body"
  query: "Validate query parameters"
  path: "Validate path parameters"
}

step7: "7. Controller Handler" {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  logic: "Process business logic"
  services: "Call services"
  return: "Return response"
}

step8: "8. Error Handler" {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"

  format: "Format error response"
  log: "Log error details"
  status: "Return status code"
}

response: HTTP Response {
  shape: oval
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

request -> step1
step1 -> step2
step2 -> step3
step3 -> step4
step4 -> step5
step5 -> step6
step6 -> step7
step7 -> step8
step8 -> response
```

### Database Schema

```prisma
// prisma/schema.prisma (Prisma 6)

generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["driverAdapters", "relationJoins"]
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id           String    @id @default(uuid())
  email        String    @unique
  password     String
  firstName    String    @map("first_name")
  lastName     String    @map("last_name")
  role         Role      @default(USER)
  status       Status    @default(ACTIVE)
  refreshToken String?   @map("refresh_token")
  createdAt    DateTime  @default(now()) @map("created_at")
  updatedAt    DateTime  @updatedAt @map("updated_at")

  orders       Order[]
  sessions     Session[]

  @@map("users")
}

model Product {
  id          String   @id @default(uuid())
  name        String
  description String?
  price       Decimal  @db.Decimal(10, 2)
  stock       Int      @default(0)
  category    String
  imageUrl    String?  @map("image_url")
  isActive    Boolean  @default(true) @map("is_active")
  createdAt   DateTime @default(now()) @map("created_at")
  updatedAt   DateTime @updatedAt @map("updated_at")

  orderItems  OrderItem[]

  @@index([category])
  @@index([isActive])
  @@map("products")
}

model Order {
  id         String      @id @default(uuid())
  userId     String      @map("user_id")
  status     OrderStatus @default(PENDING)
  total      Decimal     @db.Decimal(10, 2)
  createdAt  DateTime    @default(now()) @map("created_at")
  updatedAt  DateTime    @updatedAt @map("updated_at")

  user       User        @relation(fields: [userId], references: [id])
  items      OrderItem[]

  @@index([userId])
  @@index([status])
  @@map("orders")
}

model OrderItem {
  id        String  @id @default(uuid())
  orderId   String  @map("order_id")
  productId String  @map("product_id")
  quantity  Int
  price     Decimal @db.Decimal(10, 2)

  order     Order   @relation(fields: [orderId], references: [id], onDelete: Cascade)
  product   Product @relation(fields: [productId], references: [id])

  @@map("order_items")
}

model Session {
  id        String   @id @default(uuid())
  userId    String   @map("user_id")
  token     String   @unique
  userAgent String?  @map("user_agent")
  ipAddress String?  @map("ip_address")
  expiresAt DateTime @map("expires_at")
  createdAt DateTime @default(now()) @map("created_at")

  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@map("sessions")
}

enum Role {
  USER
  ADMIN
  SUPER_ADMIN
}

enum Status {
  ACTIVE
  INACTIVE
  SUSPENDED
}

enum OrderStatus {
  PENDING
  CONFIRMED
  PROCESSING
  SHIPPED
  DELIVERED
  CANCELLED
}
```

## Configuration

### Environment Variables

```bash
# .env.example

# Application
NODE_ENV=development
PORT=3000
HOST=0.0.0.0
API_VERSION=v1
LOG_LEVEL=info

# Database
DATABASE_URL=postgresql://api_user:api_password@localhost:5432/api_db?schema=public

# Redis
REDIS_URL=redis://localhost:6379

# JWT Configuration
JWT_ACCESS_SECRET=your-super-secret-access-key-min-32-chars
JWT_REFRESH_SECRET=your-super-secret-refresh-key-min-32-chars
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# CORS
CORS_ORIGIN=http://localhost:3001,http://localhost:5173

# AWS S3 (for file uploads)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
S3_BUCKET=your-bucket-name

# Email Service
SENDGRID_API_KEY=your-sendgrid-key
EMAIL_FROM=noreply@example.com

# Monitoring
SENTRY_DSN=https://your-sentry-dsn
```

### Configuration Module

```typescript
// src/config/index.ts
import { z } from 'zod';

// Node.js 22+ has built-in .env support, but we use Zod for validation
const envSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'test', 'production'])
    .default('development'),
  PORT: z.coerce.number().default(3000),
  HOST: z.string().default('0.0.0.0'),
  API_VERSION: z.string().default('v1'),
  LOG_LEVEL: z
    .enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace'])
    .default('info'),

  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url().optional(),

  JWT_ACCESS_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  JWT_ACCESS_EXPIRY: z.string().default('15m'),
  JWT_REFRESH_EXPIRY: z.string().default('7d'),

  RATE_LIMIT_WINDOW_MS: z.coerce.number().default(900000),
  RATE_LIMIT_MAX_REQUESTS: z.coerce.number().default(100),

  CORS_ORIGIN: z
    .string()
    .transform(s => s.split(','))
    .default('*'),

  // OpenTelemetry
  OTEL_SERVICE_NAME: z.string().default('sample-nodejs-api'),
  OTEL_EXPORTER_OTLP_ENDPOINT: z.string().url().optional(),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Invalid environment variables:');
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const config = parsed.data;

export type Config = typeof config;
```

## Security

### Authentication Implementation

```typescript
// src/middleware/auth.middleware.ts
import type { Request, Response, NextFunction } from 'express';
import * as jose from 'jose';
import { prisma } from '../lib/prisma';
import { UnauthorizedError } from '../lib/errors';
import { config } from '../config';

export interface AuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    role: string;
  };
}

const accessSecret = new TextEncoder().encode(config.JWT_ACCESS_SECRET);

export const authenticate = async (
  req: AuthRequest,
  _res: Response,
  next: NextFunction,
) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedError('Missing or invalid authorization header');
    }

    const token = authHeader.split(' ')[1];

    // Use jose for JWT verification (Edge-compatible)
    const { payload } = await jose.jwtVerify(token, accessSecret, {
      algorithms: ['HS256'],
    });

    // Verify user still exists and is active
    const user = await prisma.user.findUnique({
      where: { id: payload.sub as string },
      select: { id: true, email: true, role: true, status: true },
    });

    if (!user || user.status !== 'ACTIVE') {
      throw new UnauthorizedError('User not found or inactive');
    }

    req.user = {
      id: user.id,
      email: user.email,
      role: user.role,
    };

    next();
  } catch (error) {
    next(error);
  }
};

// Optional authentication (user may or may not be logged in)
export const optionalAuth = async (
  req: AuthRequest,
  _res: Response,
  next: NextFunction,
) => {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader?.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const { payload } = await jose.jwtVerify(token, accessSecret, {
        algorithms: ['HS256'],
      });

      const user = await prisma.user.findUnique({
        where: { id: payload.sub as string },
        select: { id: true, email: true, role: true },
      });

      if (user) {
        req.user = user;
      }
    }

    next();
  } catch {
    // Ignore auth errors for optional auth
    next();
  }
};
```

### RBAC Middleware

```typescript
// src/middleware/rbac.middleware.ts
import { Response, NextFunction } from 'express';
import { AuthRequest } from './auth.middleware';
import { ForbiddenError } from '../utils/errors';

type Role = 'USER' | 'ADMIN' | 'SUPER_ADMIN';

const roleHierarchy: Record<Role, number> = {
  USER: 1,
  ADMIN: 2,
  SUPER_ADMIN: 3,
};

export const requireRole = (...allowedRoles: Role[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(new ForbiddenError('Authentication required'));
    }

    const userRole = req.user.role as Role;

    if (!allowedRoles.includes(userRole)) {
      return next(new ForbiddenError('Insufficient permissions'));
    }

    next();
  };
};

export const requireMinRole = (minRole: Role) => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(new ForbiddenError('Authentication required'));
    }

    const userRole = req.user.role as Role;

    if (roleHierarchy[userRole] < roleHierarchy[minRole]) {
      return next(new ForbiddenError('Insufficient permissions'));
    }

    next();
  };
};

// Resource ownership check
export const requireOwnership = (
  getResourceOwnerId: (req: AuthRequest) => Promise<string | null>,
) => {
  return async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      if (!req.user) {
        return next(new ForbiddenError('Authentication required'));
      }

      // Admins can access any resource
      if (req.user.role === 'ADMIN' || req.user.role === 'SUPER_ADMIN') {
        return next();
      }

      const ownerId = await getResourceOwnerId(req);

      if (ownerId !== req.user.id) {
        return next(new ForbiddenError('Access denied to this resource'));
      }

      next();
    } catch (error) {
      next(error);
    }
  };
};
```

### Input Validation

```typescript
// src/schemas/user.schema.ts
import { z } from 'zod';

export const createUserSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
    password: z
      .string()
      .min(8, 'Password must be at least 8 characters')
      .regex(
        /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/,
        'Password must contain uppercase, lowercase, number, and special character',
      ),
    firstName: z.string().min(1).max(50),
    lastName: z.string().min(1).max(50),
  }),
});

export const updateUserSchema = z.object({
  params: z.object({
    id: z.string().uuid(),
  }),
  body: z.object({
    firstName: z.string().min(1).max(50).optional(),
    lastName: z.string().min(1).max(50).optional(),
    email: z.string().email().optional(),
  }),
});

export const getUsersSchema = z.object({
  query: z.object({
    page: z.string().transform(Number).default('1'),
    limit: z.string().transform(Number).default('10'),
    search: z.string().optional(),
    role: z.enum(['USER', 'ADMIN', 'SUPER_ADMIN']).optional(),
    status: z.enum(['ACTIVE', 'INACTIVE', 'SUSPENDED']).optional(),
    sortBy: z.enum(['createdAt', 'email', 'firstName']).default('createdAt'),
    sortOrder: z.enum(['asc', 'desc']).default('desc'),
  }),
});

export type CreateUserInput = z.infer<typeof createUserSchema>['body'];
export type UpdateUserInput = z.infer<typeof updateUserSchema>['body'];
export type GetUsersQuery = z.infer<typeof getUsersSchema>['query'];
```

## Monitoring

### Health Checks

```typescript
// src/controllers/health.controller.ts
import type { Request, Response } from 'express';
import { prisma } from '../lib/prisma';
import { redis } from '../lib/redis';

export const healthCheck = async (_req: Request, res: Response) => {
  const checks = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    nodeVersion: process.version, // Node.js 22 LTS
    version: process.env.npm_package_version || '1.0.0',
  };

  res.json(checks);
};

export const livenessProbe = async (_req: Request, res: Response) => {
  res.status(200).json({ status: 'alive' });
};

export const readinessProbe = async (_req: Request, res: Response) => {
  const checks: Record<string, boolean> = {};

  // Check database (PostgreSQL 17)
  try {
    await prisma.$queryRaw`SELECT 1`;
    checks.database = true;
  } catch {
    checks.database = false;
  }

  // Check Redis 8
  try {
    if (redis) {
      await redis.ping();
      checks.redis = true;
    }
  } catch {
    checks.redis = false;
  }

  const isReady = Object.values(checks).every(Boolean);

  res.status(isReady ? 200 : 503).json({
    status: isReady ? 'ready' : 'not_ready',
    checks,
  });
};
```

### Structured Logging

```typescript
// src/lib/logger.ts
import pino from 'pino';
import { config } from '../config';

export const logger = pino({
  level: config.LOG_LEVEL,
  transport:
    config.NODE_ENV === 'development'
      ? {
          target: 'pino-pretty',
          options: {
            colorize: true,
            translateTime: 'SYS:standard',
          },
        }
      : undefined,
  base: {
    env: config.NODE_ENV,
    service: config.OTEL_SERVICE_NAME,
  },
  redact: ['req.headers.authorization', 'password', 'refreshToken'],
  // Pino 9 supports OpenTelemetry integration
  mixin:
    config.NODE_ENV === 'production'
      ? () => ({
          trace_id: globalThis.__otel_trace_id,
          span_id: globalThis.__otel_span_id,
        })
      : undefined,
});

// Child logger for specific contexts
export const createLogger = (context: string) => {
  return logger.child({ context });
};
```

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Usage](usage.md) - Development, testing, and deployment
