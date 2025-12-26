# Usage Guide

## Development Setup

### Prerequisites

```bash
# Required tools
node --version   # v20.x or higher
npm --version    # v10.x or higher
docker --version # Docker 24+

# Install dependencies
npm install

# Set up environment
cp .env.example .env
```

### Database Setup

```bash
# Start PostgreSQL with Docker
docker run -d \
  --name postgres-dev \
  -e POSTGRES_USER=api_user \
  -e POSTGRES_PASSWORD=api_password \
  -e POSTGRES_DB=api_db \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:16-alpine

# Generate Prisma client
npx prisma generate

# Run migrations
npx prisma migrate dev

# Seed database
npx prisma db seed

# View database with Prisma Studio
npx prisma studio
```

### Development Server

```bash
# Start with hot reload
npm run dev

# Start with debugging
npm run dev:debug

# Watch mode with type checking
npm run dev:watch
```

## API Examples

### Authentication

```bash
# Register new user
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecureP@ss123",
    "firstName": "John",
    "lastName": "Doe"
  }'

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecureP@ss123"
  }'

# Response:
# {
#   "accessToken": "eyJhbGciOiJIUzI1NiIs...",
#   "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
#   "expiresIn": 900
# }

# Refresh token
curl -X POST http://localhost:3000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
  }'

# Logout
curl -X POST http://localhost:3000/api/v1/auth/logout \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..."
```

### CRUD Operations

```bash
# Set token variable
TOKEN="eyJhbGciOiJIUzI1NiIs..."

# Get current user
curl http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN"

# List products (public)
curl "http://localhost:3000/api/v1/products?page=1&limit=10&category=electronics"

# Get single product
curl http://localhost:3000/api/v1/products/123e4567-e89b-12d3-a456-426614174000

# Create product (admin only)
curl -X POST http://localhost:3000/api/v1/products \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Wireless Keyboard",
    "description": "Ergonomic wireless keyboard",
    "price": 79.99,
    "stock": 100,
    "category": "electronics"
  }'

# Create order
curl -X POST http://localhost:3000/api/v1/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      { "productId": "123e4567-e89b-12d3-a456-426614174000", "quantity": 2 }
    ]
  }'

# Get user orders
curl http://localhost:3000/api/v1/orders \
  -H "Authorization: Bearer $TOKEN"
```

### TypeScript SDK Usage

```typescript
// sdk/client.ts
import axios, { AxiosInstance } from 'axios';

interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export class ApiClient {
  private client: AxiosInstance;
  private accessToken?: string;
  private refreshToken?: string;

  constructor(baseURL: string) {
    this.client = axios.create({
      baseURL,
      headers: { 'Content-Type': 'application/json' },
    });

    // Add auth interceptor
    this.client.interceptors.request.use(config => {
      if (this.accessToken) {
        config.headers.Authorization = `Bearer ${this.accessToken}`;
      }
      return config;
    });

    // Add refresh interceptor
    this.client.interceptors.response.use(
      response => response,
      async error => {
        if (error.response?.status === 401 && this.refreshToken) {
          try {
            await this.refresh();
            return this.client.request(error.config);
          } catch {
            this.logout();
            throw error;
          }
        }
        throw error;
      },
    );
  }

  async login(email: string, password: string): Promise<AuthTokens> {
    const { data } = await this.client.post<AuthTokens>('/auth/login', {
      email,
      password,
    });
    this.accessToken = data.accessToken;
    this.refreshToken = data.refreshToken;
    return data;
  }

  async refresh(): Promise<void> {
    const { data } = await this.client.post<AuthTokens>('/auth/refresh', {
      refreshToken: this.refreshToken,
    });
    this.accessToken = data.accessToken;
    this.refreshToken = data.refreshToken;
  }

  logout(): void {
    this.accessToken = undefined;
    this.refreshToken = undefined;
  }

  // Products
  async getProducts(params?: {
    page?: number;
    limit?: number;
    category?: string;
  }) {
    return this.client.get('/products', { params });
  }

  async getProduct(id: string) {
    return this.client.get(`/products/${id}`);
  }

  async createProduct(data: {
    name: string;
    description?: string;
    price: number;
    stock: number;
    category: string;
  }) {
    return this.client.post('/products', data);
  }

  // Orders
  async getOrders() {
    return this.client.get('/orders');
  }

  async createOrder(items: { productId: string; quantity: number }[]) {
    return this.client.post('/orders', { items });
  }
}

// Usage
const api = new ApiClient('http://localhost:3000/api/v1');

await api.login('user@example.com', 'password');
const products = await api.getProducts({ category: 'electronics' });
await api.createOrder([{ productId: products.data[0].id, quantity: 1 }]);
```

## Testing

### Unit Tests

```typescript
// tests/unit/services/users.service.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { UsersService } from '../../../src/services/users.service';
import { prisma } from '../../../src/utils/prisma';

vi.mock('../../../src/utils/prisma', () => ({
  prisma: {
    user: {
      findUnique: vi.fn(),
      findMany: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      delete: vi.fn(),
    },
  },
}));

describe('UsersService', () => {
  let usersService: UsersService;

  beforeEach(() => {
    usersService = new UsersService();
    vi.clearAllMocks();
  });

  describe('findById', () => {
    it('should return user when found', async () => {
      const mockUser = {
        id: '123',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
      };

      vi.mocked(prisma.user.findUnique).mockResolvedValue(mockUser as any);

      const result = await usersService.findById('123');

      expect(result).toEqual(mockUser);
      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { id: '123' },
      });
    });

    it('should return null when user not found', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue(null);

      const result = await usersService.findById('nonexistent');

      expect(result).toBeNull();
    });
  });

  describe('create', () => {
    it('should hash password and create user', async () => {
      const input = {
        email: 'new@example.com',
        password: 'password123',
        firstName: 'Jane',
        lastName: 'Doe',
      };

      vi.mocked(prisma.user.create).mockResolvedValue({
        id: '456',
        ...input,
        password: 'hashed',
      } as any);

      const result = await usersService.create(input);

      expect(result.id).toBe('456');
      expect(prisma.user.create).toHaveBeenCalled();
    });
  });
});
```

### Integration Tests

```typescript
// tests/integration/api/products.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import supertest from 'supertest';
import { app } from '../../../src/app';
import { prisma } from '../../../src/utils/prisma';
import { createTestUser, generateToken } from '../../helpers';

describe('Products API', () => {
  let adminToken: string;
  let userToken: string;

  beforeAll(async () => {
    // Create test users
    const admin = await createTestUser({ role: 'ADMIN' });
    const user = await createTestUser({ role: 'USER' });

    adminToken = generateToken(admin);
    userToken = generateToken(user);

    // Seed products
    await prisma.product.createMany({
      data: [
        { name: 'Product 1', price: 10.99, stock: 100, category: 'test' },
        { name: 'Product 2', price: 20.99, stock: 50, category: 'test' },
      ],
    });
  });

  afterAll(async () => {
    await prisma.product.deleteMany({ where: { category: 'test' } });
    await prisma.user.deleteMany({ where: { email: { contains: 'test' } } });
  });

  describe('GET /api/v1/products', () => {
    it('should return paginated products', async () => {
      const response = await supertest(app)
        .get('/api/v1/products')
        .query({ page: 1, limit: 10 })
        .expect(200);

      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.pagination).toHaveProperty('total');
      expect(response.body.pagination).toHaveProperty('page');
    });

    it('should filter by category', async () => {
      const response = await supertest(app)
        .get('/api/v1/products')
        .query({ category: 'test' })
        .expect(200);

      expect(response.body.data.every((p: any) => p.category === 'test')).toBe(
        true,
      );
    });
  });

  describe('POST /api/v1/products', () => {
    it('should create product as admin', async () => {
      const newProduct = {
        name: 'New Product',
        price: 29.99,
        stock: 25,
        category: 'test',
      };

      const response = await supertest(app)
        .post('/api/v1/products')
        .set('Authorization', `Bearer ${adminToken}`)
        .send(newProduct)
        .expect(201);

      expect(response.body.name).toBe(newProduct.name);
    });

    it('should reject non-admin users', async () => {
      await supertest(app)
        .post('/api/v1/products')
        .set('Authorization', `Bearer ${userToken}`)
        .send({ name: 'Test', price: 10, stock: 1, category: 'test' })
        .expect(403);
    });
  });
});
```

### Running Tests

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific tests
npm test -- --grep "Products API"

# Run in watch mode
npm run test:watch

# Run E2E tests
npm run test:e2e
```

## Docker Deployment

### Dockerfile

```dockerfile
# docker/Dockerfile
# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build
RUN npx prisma generate

# Production stage
FROM node:20-alpine AS production

WORKDIR /app

# Install production dependencies only
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci --only=production && \
    npx prisma generate && \
    npm cache clean --force

# Copy built application
COPY --from=builder /app/dist ./dist

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

EXPOSE 3000

CMD ["node", "dist/index.js"]
```

### Docker Compose

```yaml
# docker/docker-compose.yaml
version: '3.8'

services:
  api:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    ports:
      - '3000:3000'
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://api_user:api_password@postgres:5432/api_db
      REDIS_URL: redis://redis:6379
      JWT_ACCESS_SECRET: ${JWT_ACCESS_SECRET}
      JWT_REFRESH_SECRET: ${JWT_REFRESH_SECRET}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    healthcheck:
      test: ['CMD', 'wget', '-q', '--spider', 'http://localhost:3000/health']
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: api_user
      POSTGRES_PASSWORD: api_password
      POSTGRES_DB: api_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U api_user -d api_db']
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

  migrate:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    command: npx prisma migrate deploy
    environment:
      DATABASE_URL: postgresql://api_user:api_password@postgres:5432/api_db
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  postgres_data:
  redis_data:
```

### Kubernetes Deployment

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-api
  labels:
    app: nodejs-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nodejs-api
  template:
    metadata:
      labels:
        app: nodejs-api
    spec:
      containers:
        - name: api
          image: nodejs-api:latest
          ports:
            - containerPort: 3000
          env:
            - name: NODE_ENV
              value: production
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: api-secrets
                  key: database-url
            - name: JWT_ACCESS_SECRET
              valueFrom:
                secretKeyRef:
                  name: api-secrets
                  key: jwt-access-secret
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /health/live
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: nodejs-api
spec:
  selector:
    app: nodejs-api
  ports:
    - port: 80
      targetPort: 3000
  type: ClusterIP
```

## Troubleshooting

### Common Issues

| Issue               | Cause                | Solution                                      |
| ------------------- | -------------------- | --------------------------------------------- |
| Connection refused  | Database not running | Start PostgreSQL: `docker start postgres-dev` |
| Prisma client error | Client not generated | Run `npx prisma generate`                     |
| Migration failed    | Schema conflict      | Run `npx prisma migrate reset` (dev only)     |
| JWT invalid         | Wrong secret         | Check JWT_ACCESS_SECRET in .env               |
| CORS error          | Origin not allowed   | Add origin to CORS_ORIGIN env var             |
| Rate limited        | Too many requests    | Wait for rate limit window to reset           |

### Debug Commands

```bash
# Check database connection
npx prisma db execute --stdin <<< "SELECT 1"

# View database schema
npx prisma db pull

# Reset database (development)
npx prisma migrate reset

# Check logs
docker logs nodejs-api --tail 100 -f

# Debug mode
DEBUG=express:* npm run dev
```

## Best Practices

### Security Checklist

- [ ] Use HTTPS in production
- [ ] Set secure JWT secrets (32+ characters)
- [ ] Enable rate limiting
- [ ] Validate all inputs with Zod
- [ ] Use parameterized queries (Prisma handles this)
- [ ] Set security headers with Helmet
- [ ] Implement CORS properly
- [ ] Hash passwords with bcrypt
- [ ] Log security events
- [ ] Regular dependency updates

### Performance Checklist

- [ ] Enable response compression
- [ ] Use Redis for caching
- [ ] Implement pagination
- [ ] Add database indexes
- [ ] Use connection pooling
- [ ] Enable HTTP/2
- [ ] Implement request timeout
- [ ] Monitor with APM tools

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Overview](overview.md) - Architecture and security details
