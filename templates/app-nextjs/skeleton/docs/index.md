# ${{ values.name }}

${{ values.description }}

## Overview

This Next.js 14 application provides a modern, production-ready web application with:

- App Router architecture with React Server Components
- TypeScript for type safety and better developer experience
- Tailwind CSS for utility-first styling (configurable)
- Jest and React Testing Library for comprehensive testing
- Docker containerization for consistent deployments
- GitHub Actions CI/CD pipeline with automated testing and deployment

```d2
direction: right

title: {
  label: Next.js Application Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

client: Browser {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

nextjs: Next.js App {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"

  router: App Router {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"

    layouts: Layouts {
      label: "layout.tsx\nRoot Layout"
    }
    pages: Pages {
      label: "page.tsx\nRoute Handlers"
    }
    loading: Loading States {
      label: "loading.tsx\nSuspense"
    }
  }

  api: API Routes {
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"

    health: /api/health {
      label: "Health Check\nEndpoint"
    }
    custom: /api/* {
      label: "Custom API\nEndpoints"
    }
  }

  components: Components {
    style.fill: "#E1F5FE"
    style.stroke: "#0288D1"

    ui: UI Components
    shared: Shared Components
    features: Feature Components
  }

  lib: Lib {
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"

    utils: Utilities
    hooks: Custom Hooks
    types: TypeScript Types
  }

  router -> pages
  router -> api
  pages -> components
  components -> lib
}

data: External Services {
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"

  db: Database {
    shape: cylinder
  }
  cache: Cache {
    shape: cylinder
  }
  external: Third-party APIs {
    shape: cloud
  }
}

client -> nextjs.router: HTTP Requests
nextjs.api -> data
nextjs.lib -> data
```

## Configuration Summary

| Setting              | Value                          |
| -------------------- | ------------------------------ |
| Application Name     | `${{ values.name }}`           |
| Owner                | `${{ values.owner }}`          |
| Environment          | `${{ values.environment }}`    |
| Framework            | Next.js 14                     |
| Styling              | ${{ values.styling }}          |
| Node.js Version      | 20.x                           |
| Package Manager      | npm                            |
| TypeScript           | Enabled                        |

## Project Structure

```
${{ values.name }}/
├── .github/
│   └── workflows/
│       └── nextjs.yaml       # CI/CD pipeline configuration
├── __tests__/
│   └── index.test.tsx        # Unit and integration tests
├── docs/
│   └── index.md              # This documentation
├── public/                   # Static assets (images, fonts, etc.)
├── src/
│   ├── app/                  # App Router directory
│   │   ├── api/              # API route handlers
│   │   │   └── health/
│   │   │       └── route.ts  # Health check endpoint
│   │   ├── globals.css       # Global styles
│   │   ├── layout.tsx        # Root layout component
│   │   └── page.tsx          # Home page component
│   ├── components/           # Reusable React components
│   └── lib/                  # Utility functions and helpers
├── .eslintrc.json            # ESLint configuration
├── .prettierrc               # Prettier configuration
├── catalog-info.yaml         # Backstage catalog configuration
├── Dockerfile                # Container build configuration
├── jest.config.ts            # Jest test configuration
├── jest.setup.ts             # Jest setup file
├── mkdocs.yml                # MkDocs configuration for TechDocs
├── next.config.js            # Next.js configuration
├── package.json              # Dependencies and scripts
├── postcss.config.js         # PostCSS configuration
├── tailwind.config.js        # Tailwind CSS configuration
└── tsconfig.json             # TypeScript configuration
```

### Directory Purposes

| Directory          | Purpose                                                          |
| ------------------ | ---------------------------------------------------------------- |
| `src/app/`         | App Router pages and layouts using file-based routing            |
| `src/app/api/`     | API route handlers (server-side endpoints)                       |
| `src/components/`  | Reusable UI components (buttons, cards, modals, etc.)            |
| `src/lib/`         | Shared utilities, custom hooks, type definitions, API clients    |
| `__tests__/`       | Test files organized by feature or component                     |
| `public/`          | Static files served at the root path                             |
| `.github/`         | GitHub Actions workflows and templates                           |

---

## CI/CD Pipeline

This repository includes a GitHub Actions pipeline that automates testing, building, and deployment.

### Pipeline Features

- **Linting**: ESLint and Prettier for code quality and consistency
- **Testing**: Jest with React Testing Library for unit and integration tests
- **Building**: Next.js production build validation
- **Docker**: Automated container image builds and registry push
- **Caching**: npm dependency caching for faster builds

### Pipeline Workflow

```d2
direction: right

trigger: Trigger {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Push / PR\nto main"
}

lint: Lint {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "ESLint\nPrettier"
}

test: Test {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  label: "Jest\nUnit Tests"
}

build: Build {
  style.fill: "#E1F5FE"
  style.stroke: "#0288D1"
  label: "Next.js\nProduction Build"
}

docker: Docker {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "Build Image\nPush to GHCR"
}

deploy: Deploy {
  shape: hexagon
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Vercel / K8s\nContainer Deploy"
}

trigger -> lint -> test -> build -> docker -> deploy
```

### Pipeline Stages

| Stage        | Trigger                  | Actions                                         |
| ------------ | ------------------------ | ----------------------------------------------- |
| **Lint**     | All pushes and PRs       | Run ESLint, check Prettier formatting           |
| **Test**     | After lint passes        | Execute Jest test suite                         |
| **Build**    | After tests pass         | Create Next.js production build                 |
| **Docker**   | Push to main only        | Build and push container image to GitHub Registry |
| **Deploy**   | After Docker build       | Deploy to target environment                    |

---

## Prerequisites

### Required Software

| Software    | Version | Purpose                           | Installation                          |
| ----------- | ------- | --------------------------------- | ------------------------------------- |
| Node.js     | 20.x    | JavaScript runtime                | [nodejs.org](https://nodejs.org)      |
| npm         | 10.x    | Package manager (bundled)         | Included with Node.js                 |
| Git         | 2.x     | Version control                   | [git-scm.com](https://git-scm.com)    |
| Docker      | 24.x    | Container builds (optional)       | [docker.com](https://docker.com)      |

### Verify Installation

```bash
# Check Node.js version (should be 20.x or higher)
node --version

# Check npm version
npm --version

# Check Git version
git --version

# Check Docker version (optional)
docker --version
```

### IDE Recommendations

For the best development experience, install these VS Code extensions:

| Extension                       | Purpose                                |
| ------------------------------- | -------------------------------------- |
| ESLint                          | Inline linting feedback                |
| Prettier                        | Code formatting                        |
| Tailwind CSS IntelliSense       | Tailwind class autocomplete            |
| TypeScript Vue Plugin (Volar)   | Enhanced TypeScript support            |
| Jest Runner                     | Run tests from the editor              |

---

## Usage

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Install dependencies
npm install

# Start development server (hot reload enabled)
npm run dev

# The app will be available at http://localhost:3000
```

### Available Scripts

| Script              | Command                    | Description                              |
| ------------------- | -------------------------- | ---------------------------------------- |
| `dev`               | `npm run dev`              | Start development server with hot reload |
| `build`             | `npm run build`            | Create production build                  |
| `start`             | `npm run start`            | Start production server                  |
| `lint`              | `npm run lint`             | Run ESLint checks                        |
| `lint:fix`          | `npm run lint:fix`         | Fix auto-fixable lint issues             |
| `format`            | `npm run format`           | Format code with Prettier                |
| `format:check`      | `npm run format:check`     | Check code formatting                    |
| `test`              | `npm run test`             | Run test suite                           |
| `test:watch`        | `npm run test:watch`       | Run tests in watch mode                  |
| `test:coverage`     | `npm run test:coverage`    | Run tests with coverage report           |

### Building for Production

```bash
# Create optimized production build
npm run build

# Start production server locally
npm run start

# The production app will be available at http://localhost:3000
```

### Deploy to Vercel

Vercel is the recommended deployment platform for Next.js applications:

```bash
# Install Vercel CLI
npm install -g vercel

# Login to Vercel
vercel login

# Deploy to preview environment
vercel

# Deploy to production
vercel --prod
```

**Environment Variables for Vercel:**

Configure in Vercel Dashboard > Project Settings > Environment Variables:

| Variable           | Description                    | Example                |
| ------------------ | ------------------------------ | ---------------------- |
| `NEXT_PUBLIC_*`    | Client-side exposed variables  | `NEXT_PUBLIC_API_URL`  |
| `DATABASE_URL`     | Database connection string     | `postgresql://...`     |
| `API_SECRET`       | Server-side API keys           | `sk-...`               |

### Deploy with Docker

```bash
# Build the Docker image
docker build -t ${{ values.name }}:latest .

# Run the container locally
docker run -p 3000:3000 ${{ values.name }}:latest

# Push to GitHub Container Registry
docker tag ${{ values.name }}:latest ghcr.io/${{ values.owner }}/${{ values.name }}:latest
docker push ghcr.io/${{ values.owner }}/${{ values.name }}:latest
```

### Deploy to Kubernetes

```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${{ values.name }}
  labels:
    app: ${{ values.name }}
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ${{ values.name }}
  template:
    metadata:
      labels:
        app: ${{ values.name }}
    spec:
      containers:
        - name: ${{ values.name }}
          image: ghcr.io/${{ values.owner }}/${{ values.name }}:latest
          ports:
            - containerPort: 3000
          env:
            - name: NODE_ENV
              value: production
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /api/health
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /api/health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
```

```bash
# Apply Kubernetes deployment
kubectl apply -f kubernetes/deployment.yaml
```

---

## API Routes Documentation

### Health Check Endpoint

**Endpoint:** `GET /api/health`

Returns the application health status for monitoring and load balancer health checks.

**Response:**

```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "service": "${{ values.name }}",
  "environment": "${{ values.environment }}"
}
```

**Usage:**

```bash
# Check application health
curl http://localhost:3000/api/health
```

### Creating New API Routes

API routes in the App Router use the file-based routing convention:

```typescript
// src/app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';

// GET /api/users
export async function GET(request: NextRequest) {
  const users = await fetchUsers();
  return NextResponse.json(users);
}

// POST /api/users
export async function POST(request: NextRequest) {
  const body = await request.json();
  const user = await createUser(body);
  return NextResponse.json(user, { status: 201 });
}
```

### API Route Conventions

| File Path                        | HTTP Endpoint         | Methods Supported           |
| -------------------------------- | --------------------- | --------------------------- |
| `src/app/api/route.ts`           | `/api`                | GET, POST, PUT, DELETE, etc |
| `src/app/api/users/route.ts`     | `/api/users`          | GET, POST                   |
| `src/app/api/users/[id]/route.ts`| `/api/users/:id`      | GET, PUT, DELETE            |
| `src/app/api/health/route.ts`    | `/api/health`         | GET                         |

---

## Testing Strategy

### Testing Stack

| Tool                    | Purpose                              |
| ----------------------- | ------------------------------------ |
| Jest                    | Test runner and assertion library    |
| React Testing Library   | Component testing utilities          |
| jest-environment-jsdom  | DOM environment for testing          |

### Test File Organization

```
__tests__/
├── components/           # Component unit tests
│   ├── Button.test.tsx
│   └── Header.test.tsx
├── pages/                # Page integration tests
│   └── home.test.tsx
├── api/                  # API route tests
│   └── health.test.ts
└── lib/                  # Utility function tests
    └── utils.test.ts
```

### Writing Tests

**Component Test Example:**

```typescript
// __tests__/components/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import Button from '@/components/Button';

describe('Button', () => {
  it('renders with correct text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button')).toHaveTextContent('Click me');
  });

  it('calls onClick handler when clicked', () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    fireEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
```

**API Route Test Example:**

```typescript
// __tests__/api/health.test.ts
import { GET } from '@/app/api/health/route';

describe('/api/health', () => {
  it('returns healthy status', async () => {
    const response = await GET();
    const data = await response.json();
    
    expect(response.status).toBe(200);
    expect(data.status).toBe('healthy');
    expect(data.service).toBe('${{ values.name }}');
  });
});
```

### Running Tests

```bash
# Run all tests
npm test

# Run tests in watch mode (re-runs on file changes)
npm run test:watch

# Run tests with coverage report
npm run test:coverage

# Run specific test file
npm test -- __tests__/components/Button.test.tsx

# Run tests matching a pattern
npm test -- --testNamePattern="Button"
```

### E2E Testing with Playwright (Optional)

For end-to-end testing, add Playwright:

```bash
# Install Playwright
npm install -D @playwright/test

# Initialize Playwright
npx playwright install
```

```typescript
// e2e/home.spec.ts
import { test, expect } from '@playwright/test';

test('homepage has correct title', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/\${{ values.name }}/);
});
```

---

## Performance Optimization

### Built-in Optimizations

Next.js 14 includes several performance features out of the box:

| Feature               | Description                                    |
| --------------------- | ---------------------------------------------- |
| Server Components     | Reduce client-side JavaScript bundle           |
| Automatic Code Split  | Load only the code needed for each page        |
| Image Optimization    | Automatic image resizing and format conversion |
| Font Optimization     | Automatic font optimization with `next/font`   |
| Static Generation     | Pre-render pages at build time                 |

### Best Practices

**1. Use Server Components by Default**

```typescript
// src/app/page.tsx - Server Component (default)
async function HomePage() {
  const data = await fetchData(); // Runs on server
  return <div>{data.content}</div>;
}
```

**2. Use Client Components Only When Needed**

```typescript
// src/components/Counter.tsx
'use client';

import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

**3. Optimize Images**

```typescript
import Image from 'next/image';

<Image
  src="/hero.png"
  alt="Hero image"
  width={800}
  height={600}
  priority // Load above-the-fold images first
/>
```

**4. Use Dynamic Imports for Heavy Components**

```typescript
import dynamic from 'next/dynamic';

const HeavyChart = dynamic(() => import('@/components/Chart'), {
  loading: () => <p>Loading chart...</p>,
  ssr: false, // Disable server-side rendering if needed
});
```

**5. Configure Caching Headers**

```typescript
// next.config.js
module.exports = {
  async headers() {
    return [
      {
        source: '/api/:path*',
        headers: [
          { key: 'Cache-Control', value: 's-maxage=60, stale-while-revalidate' },
        ],
      },
    ];
  },
};
```

### Performance Monitoring

```bash
# Analyze bundle size
npm run build
npx @next/bundle-analyzer

# Run Lighthouse audit
npx lighthouse http://localhost:3000 --view
```

---

## Troubleshooting

### Common Issues

**Issue: `npm install` fails with dependency conflicts**

```bash
Error: ERESOLVE unable to resolve dependency tree
```

**Resolution:**

```bash
# Clear npm cache and reinstall
rm -rf node_modules package-lock.json
npm cache clean --force
npm install

# Or use legacy peer deps
npm install --legacy-peer-deps
```

---

**Issue: Hot reload not working in development**

**Resolution:**

1. Check for file watching limits on Linux:
   ```bash
   echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   ```

2. Restart the development server:
   ```bash
   npm run dev
   ```

---

**Issue: Build fails with TypeScript errors**

```bash
Type error: Property 'x' does not exist on type 'y'
```

**Resolution:**

```bash
# Check for type errors
npx tsc --noEmit

# Fix types or add type assertions where appropriate
```

---

**Issue: Docker build fails at standalone output**

```bash
Error: Cannot find module '/app/.next/standalone/server.js'
```

**Resolution:**

Ensure `next.config.js` has standalone output enabled:

```javascript
// next.config.js
module.exports = {
  output: 'standalone',
};
```

---

**Issue: API routes return 404 in production**

**Resolution:**

1. Verify the route file is named `route.ts` (not `index.ts`)
2. Check the export function names match HTTP methods (GET, POST, etc.)
3. Ensure the file is in the correct `src/app/api/` directory

---

**Issue: Environment variables not accessible in client**

**Resolution:**

Client-side environment variables must be prefixed with `NEXT_PUBLIC_`:

```bash
# .env.local
NEXT_PUBLIC_API_URL=https://api.example.com  # Accessible in browser
API_SECRET=secret123                          # Server-only
```

---

**Issue: Tests fail with "Cannot find module"**

**Resolution:**

Check `jest.config.ts` has correct module name mapping:

```typescript
// jest.config.ts
const config = {
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
};
```

---

## Related Templates

| Template                                                          | Description                                |
| ----------------------------------------------------------------- | ------------------------------------------ |
| [app-react](/docs/default/template/app-react)                     | React SPA with Vite                        |
| [app-remix](/docs/default/template/app-remix)                     | Remix full-stack web application           |
| [api-nodejs](/docs/default/template/api-nodejs)                   | Node.js Express/Fastify API                |
| [api-graphql](/docs/default/template/api-graphql)                 | GraphQL API with Apollo Server             |
| [infra-vercel](/docs/default/template/infra-vercel)               | Vercel deployment infrastructure           |
| [infra-kubernetes](/docs/default/template/infra-kubernetes)       | Kubernetes deployment manifests            |

---

## References

- [Next.js Documentation](https://nextjs.org/docs)
- [Next.js App Router](https://nextjs.org/docs/app)
- [React Server Components](https://react.dev/reference/rsc/server-components)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [React Testing Library](https://testing-library.com/docs/react-testing-library/intro/)
- [Vercel Deployment](https://vercel.com/docs)
- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Backstage TechDocs](https://backstage.io/docs/features/techdocs/)
