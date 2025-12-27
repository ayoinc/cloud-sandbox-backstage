# ${{ values.name }}

${{ values.description }}

## Overview

This is a production-ready React frontend application built with modern tooling and best practices. The application features:

- **React 19** with TypeScript for type-safe component development
- **Vite** for lightning-fast development and optimized production builds
- **Vitest** with React Testing Library for comprehensive testing
- **Biome** for fast linting and formatting
- **Docker** multi-stage builds for containerized deployments
- **GitHub Actions** CI/CD pipeline with security scanning

```d2
direction: right

title: {
  label: React Application Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

browser: Browser {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

app: React Application {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"

  ui: UI Layer {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"

    pages: Pages {
      home: Home
      about: About
      notfound: 404
    }

    components: Components {
      layout: Layout
      button: Button
      shared: Shared UI
    }
  }

  logic: Logic Layer {
    style.fill: "#FFF3E0"
    style.stroke: "#F57C00"

    hooks: Custom Hooks {
      useApi: useApi
      useTheme: useTheme
    }

    state: State Management {
      local: Local State
      global: Global Store
    }
  }

  data: Data Layer {
    style.fill: "#E3F2FD"
    style.stroke: "#1976D2"

    services: API Services {
      api: API Client
      auth: Auth Handler
    }

    cache: Cache Layer
  }

  ui.pages -> logic.hooks
  ui.components -> logic.state
  logic.hooks -> data.services
  logic.state -> data.cache
}

backend: Backend API {
  shape: hexagon
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
}

browser -> app.ui
app.data.services -> backend
```

## Configuration Summary

| Setting            | Value                                       |
| ------------------ | ------------------------------------------- |
| Application Name   | `${{ values.name }}`                        |
| Owner              | `${{ values.owner }}`                       |
| Repository         | `${{ values.destination.owner }}/${{ values.destination.repo }}` |
| UI Framework       | `${{ values.ui_framework }}`                |
| State Management   | `${{ values.state_management }}`            |
| API Client         | `${{ values.api_client }}`                  |
| Routing            | `${{ values.routing }}`                     |
| Node Version       | 22+                                         |
| Package Manager    | pnpm 9+                                     |

---

## Project Structure

```
${{ values.name }}/
├── .github/
│   └── workflows/
│       └── ci.yaml              # CI/CD pipeline configuration
├── docker/
│   ├── default.conf             # Nginx server block configuration
│   └── nginx.conf               # Nginx main configuration
├── docs/
│   └── index.md                 # This documentation
├── public/
│   └── vite.svg                 # Static assets
├── src/
│   ├── components/              # Reusable UI components
│   │   ├── Button.tsx           # Button component
│   │   ├── Button.module.css    # Button styles
│   │   ├── Layout.tsx           # Layout wrapper
│   │   ├── Layout.module.css    # Layout styles
│   │   └── index.ts             # Component exports
│   ├── hooks/                   # Custom React hooks
│   │   ├── useApi.ts            # API fetching hook
│   │   ├── useTheme.ts          # Theme management hook
│   │   └── index.ts             # Hook exports
│   ├── pages/                   # Page components (routes)
│   │   ├── Home.tsx             # Home page
│   │   ├── About.tsx            # About page
│   │   └── NotFound.tsx         # 404 page
│   ├── services/                # API and external services
│   │   ├── api.ts               # API client configuration
│   │   └── index.ts             # Service exports
│   ├── styles/                  # Global styles and theming
│   │   ├── index.css            # Global CSS
│   │   └── theme.ts             # Theme configuration
│   ├── App.tsx                  # Root application component
│   └── main.tsx                 # Application entry point
├── tests/                       # Test files
│   ├── mocks/                   # MSW mock handlers
│   │   ├── browser.ts           # Browser mock setup
│   │   ├── handlers.ts          # API mock handlers
│   │   └── server.ts            # Test server setup
│   ├── App.test.tsx             # App component tests
│   ├── Button.test.tsx          # Button component tests
│   ├── Home.test.tsx            # Home page tests
│   └── setup.ts                 # Test configuration
├── .dockerignore                # Docker ignore patterns
├── .env.example                 # Environment variables template
├── .gitignore                   # Git ignore patterns
├── biome.json                   # Biome linter configuration
├── catalog-info.yaml            # Backstage component metadata
├── docker-compose.yaml          # Docker Compose configuration
├── Dockerfile                   # Multi-stage Docker build
├── index.html                   # HTML entry point
├── mkdocs.yml                   # MkDocs configuration
├── package.json                 # Project dependencies
├── README.md                    # Project README
├── tsconfig.json                # TypeScript configuration
├── tsconfig.node.json           # TypeScript Node configuration
└── vite.config.ts               # Vite bundler configuration
```

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Lint & Format**: Biome checks for code quality and consistency
- **Type Checking**: TypeScript compilation verification
- **Unit Testing**: Vitest with coverage reporting
- **Security Scanning**: CodeQL analysis and pnpm audit
- **Docker Build**: Multi-stage container builds with GHCR publishing
- **Multi-Environment Deployment**: Staging and production environments

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
  label: "Biome Lint\nFormat Check\nType Check"
}

test: Test {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Vitest\nCoverage\nUpload Results"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "pnpm audit\nCodeQL Analysis"
}

build: Build {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Vite Build\nArtifact Upload"
}

docker: Docker {
  style.fill: "#E1F5FE"
  style.stroke: "#0288D1"
  label: "Build Image\nPush to GHCR"
}

staging: Staging {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Deploy\nStaging"
}

prod: Production {
  shape: diamond
  style.fill: "#C8E6C9"
  style.stroke: "#388E3C"
  label: "Deploy\nProduction"
}

pr -> lint
pr -> test
pr -> security
lint -> build
test -> build
security -> build
build -> docker
docker -> staging: develop
docker -> prod: main
```

### Pipeline Jobs

| Job         | Trigger                    | Actions                                    |
| ----------- | -------------------------- | ------------------------------------------ |
| Lint        | All pushes and PRs         | Biome lint, format check, TypeScript       |
| Test        | All pushes and PRs         | Vitest with coverage, upload to Codecov    |
| Security    | All pushes and PRs         | pnpm audit, CodeQL static analysis         |
| Build       | After lint and test pass   | Vite production build, artifact upload     |
| Docker      | Push to main               | Build and push to GitHub Container Registry|
| Staging     | Push to develop            | Deploy to staging environment              |
| Production  | Push to main               | Deploy to production environment           |

---

## Prerequisites

### 1. Development Environment

#### Required Software

| Software     | Version  | Installation                                                  |
| ------------ | -------- | ------------------------------------------------------------- |
| Node.js      | >= 22.0  | [nodejs.org](https://nodejs.org) or use nvm                   |
| pnpm         | >= 9.0   | `corepack enable && corepack prepare pnpm@9 --activate`       |
| Git          | Latest   | [git-scm.com](https://git-scm.com)                            |
| Docker       | Latest   | [docker.com](https://www.docker.com) (optional)               |

#### Verify Installation

```bash
# Check Node.js version
node --version  # Should be >= 22.0.0

# Check pnpm version
pnpm --version  # Should be >= 9.0.0

# Check Git version
git --version
```

### 2. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret          | Description                        | Required |
| --------------- | ---------------------------------- | -------- |
| `CODECOV_TOKEN` | Token for coverage reporting       | Optional |

#### Repository Variables

Configure these in **Settings > Secrets and variables > Actions > Variables**:

| Variable    | Description              | Default |
| ----------- | ------------------------ | ------- |
| `API_URL`   | Backend API base URL     | `/api`  |

#### GitHub Environments

Create environments in **Settings > Environments**:

| Environment  | Protection Rules                  | URL                                              |
| ------------ | --------------------------------- | ------------------------------------------------ |
| `staging`    | None                              | `https://staging.${{ values.name }}.example.com` |
| `production` | Required reviewers, main only     | `https://${{ values.name }}.example.com`         |

---

## Usage

### Local Development

```bash
# Clone the repository
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
cd ${{ values.name }}

# Install dependencies
pnpm install

# Create environment file
cp .env.example .env.local

# Start development server
pnpm run dev
```

The development server will start at `http://localhost:5173` with hot module replacement enabled.

### Available Scripts

| Command                | Description                                    |
| ---------------------- | ---------------------------------------------- |
| `pnpm run dev`         | Start development server with HMR              |
| `pnpm run build`       | Create production build                        |
| `pnpm run preview`     | Preview production build locally               |
| `pnpm run lint`        | Run Biome linter                               |
| `pnpm run lint:fix`    | Fix linting issues automatically               |
| `pnpm run format`      | Format code with Biome                         |
| `pnpm run test`        | Run tests once                                 |
| `pnpm run test:watch`  | Run tests in watch mode                        |
| `pnpm run test:coverage` | Run tests with coverage report               |
| `pnpm run test:ui`     | Open Vitest UI                                 |
| `pnpm run typecheck`   | Run TypeScript type checking                   |

### Environment Variables

Create a `.env.local` file based on `.env.example`:

```bash
# API Configuration
VITE_API_URL=${{ values.api_base_url }}

# Application Environment
VITE_APP_ENV=development
```

### Docker Development

```bash
# Build and run with Docker Compose
docker compose up --build

# Or build specific target
docker build --target development -t ${{ values.name }}:dev .
docker run -p 5173:5173 -v $(pwd):/app ${{ values.name }}:dev
```

### Production Build

```bash
# Create optimized production build
pnpm run build

# Preview the production build
pnpm run preview

# Build Docker production image
docker build --target production -t ${{ values.name }}:latest .
docker run -p 8080:8080 ${{ values.name }}:latest
```

---

## Component Documentation

### Core Components

#### Layout Component

The `Layout` component provides consistent page structure with header and footer.

```tsx
import { Layout } from './components';

const MyPage = () => (
  <Layout>
    <h1>Page Content</h1>
  </Layout>
);
```

#### Button Component

Reusable button with multiple variants and sizes.

```tsx
import { Button } from './components';

// Primary button (default)
<Button onClick={handleClick}>Click Me</Button>

// Secondary variant
<Button variant="secondary">Secondary</Button>

// With loading state
<Button isLoading>Loading...</Button>
```

### Custom Hooks

#### useApi Hook

Provides data fetching with loading and error states.

```tsx
import { useApiQuery, useApiMutation } from './hooks';

// GET request
const { data, isLoading, error } = useApiQuery<User[]>('/users');

// POST/PUT/DELETE mutations
const { mutate, isLoading } = useApiMutation<User, CreateUserInput>('post', '/users');
await mutate({ name: 'John', email: 'john@example.com' });
```

#### useTheme Hook

Manages application theme with system preference support.

```tsx
import { useTheme } from './hooks';

const { theme, toggleTheme, setTheme } = useTheme();

// Toggle between light and dark
<button onClick={toggleTheme}>Toggle Theme</button>

// Set specific theme
setTheme('dark');
```

### Pages

| Page       | Route   | Description                    |
| ---------- | ------- | ------------------------------ |
| Home       | `/`     | Landing page                   |
| About      | `/about`| About page with app info       |
| NotFound   | `*`     | 404 error page for unknown routes |

---

## Testing Strategy

### Testing Stack

| Tool                    | Purpose                                    |
| ----------------------- | ------------------------------------------ |
| **Vitest**              | Test runner with Jest compatibility        |
| **React Testing Library** | Component testing utilities              |
| **@testing-library/user-event** | User interaction simulation        |
| **MSW (Mock Service Worker)** | API mocking for integration tests    |
| **@vitest/coverage-v8** | Code coverage reporting                    |

### Test Structure

```
tests/
├── mocks/
│   ├── browser.ts       # Browser environment mocks
│   ├── handlers.ts      # MSW API handlers
│   └── server.ts        # MSW server setup
├── setup.ts             # Global test configuration
├── App.test.tsx         # Root component tests
├── Button.test.tsx      # Button component tests
└── Home.test.tsx        # Home page tests
```

### Writing Tests

#### Component Test Example

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from '../src/components';

describe('Button', () => {
  it('renders with correct text', () => {
    render(<Button>Click Me</Button>);
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });

  it('calls onClick when clicked', async () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click</Button>);
    
    await userEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('is disabled when isLoading is true', () => {
    render(<Button isLoading>Loading</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

#### API Integration Test Example

```tsx
import { render, screen, waitFor } from '@testing-library/react';
import { http, HttpResponse } from 'msw';
import { server } from './mocks/server';
import { UserList } from '../src/components/UserList';

describe('UserList', () => {
  it('displays users from API', async () => {
    server.use(
      http.get('/api/users', () => {
        return HttpResponse.json([
          { id: 1, name: 'John Doe' },
          { id: 2, name: 'Jane Smith' },
        ]);
      })
    );

    render(<UserList />);

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
    });
  });

  it('handles API errors gracefully', async () => {
    server.use(
      http.get('/api/users', () => {
        return HttpResponse.error();
      })
    );

    render(<UserList />);

    await waitFor(() => {
      expect(screen.getByText(/error loading users/i)).toBeInTheDocument();
    });
  });
});
```

### Running Tests

```bash
# Run all tests
pnpm run test

# Run tests in watch mode
pnpm run test:watch

# Run with coverage
pnpm run test:coverage

# Open Vitest UI
pnpm run test:ui
```

### Coverage Thresholds

The project enforces minimum coverage thresholds:

| Metric     | Threshold |
| ---------- | --------- |
| Statements | 80%       |
| Branches   | 80%       |
| Functions  | 80%       |
| Lines      | 80%       |

---

## Performance Optimization

### Build Optimizations

The Vite configuration includes several production optimizations:

| Optimization           | Description                                    |
| ---------------------- | ---------------------------------------------- |
| Code Splitting         | Automatic chunk splitting for lazy loading     |
| Tree Shaking           | Removes unused code from bundles               |
| Minification           | Terser minification for production             |
| Asset Hashing          | Content-based hashing for cache busting        |
| Compression            | Gzip/Brotli compression in nginx               |

### Runtime Optimizations

#### Lazy Loading Routes

```tsx
import { lazy, Suspense } from 'react';

const About = lazy(() => import('./pages/About'));

<Suspense fallback={<Loading />}>
  <Route path="/about" element={<About />} />
</Suspense>
```

#### Memoization

```tsx
import { memo, useMemo, useCallback } from 'react';

// Memoize expensive components
const ExpensiveList = memo(({ items }) => (
  <ul>{items.map(item => <li key={item.id}>{item.name}</li>)}</ul>
));

// Memoize computed values
const sortedItems = useMemo(() => 
  items.sort((a, b) => a.name.localeCompare(b.name)),
  [items]
);

// Memoize callbacks
const handleClick = useCallback((id) => {
  setSelected(id);
}, []);
```

### Bundle Analysis

```bash
# Analyze bundle size
pnpm run build
npx vite-bundle-visualizer
```

### Lighthouse Targets

| Metric              | Target |
| ------------------- | ------ |
| Performance         | > 90   |
| Accessibility       | > 90   |
| Best Practices      | > 90   |
| SEO                 | > 90   |

---

## Troubleshooting

### Development Issues

**Error: ENOSPC - System limit for file watchers reached**

```bash
# Linux: Increase inotify watchers
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

**Error: Port 5173 already in use**

```bash
# Find and kill process using the port
lsof -ti:5173 | xargs kill -9

# Or use a different port
pnpm run dev -- --port 3000
```

**Error: Module not found**

```bash
# Clear cache and reinstall dependencies
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

### Build Issues

**Error: TypeScript compilation errors**

```bash
# Check for type errors
pnpm run typecheck

# Fix common issues
pnpm run lint:fix
```

**Error: Out of memory during build**

```bash
# Increase Node.js memory limit
NODE_OPTIONS="--max-old-space-size=4096" pnpm run build
```

### Docker Issues

**Error: Docker build fails on M1/M2 Mac**

```bash
# Build for specific platform
docker build --platform linux/amd64 -t ${{ values.name }}:latest .
```

**Error: Container exits immediately**

```bash
# Check container logs
docker logs <container_id>

# Run with interactive shell for debugging
docker run -it ${{ values.name }}:latest /bin/sh
```

### CI/CD Issues

**Pipeline failing on lint**

```bash
# Run lint locally first
pnpm run lint

# Auto-fix issues
pnpm run lint:fix
pnpm run format
```

**Tests timing out**

- Check for unresolved promises in tests
- Ensure MSW handlers are correctly set up
- Increase test timeout in `vite.config.ts`

**Docker push unauthorized**

- Verify `GITHUB_TOKEN` has `packages: write` permission
- Check repository settings allow GitHub Actions to push packages

---

## Related Templates

| Template                                                  | Description                          |
| --------------------------------------------------------- | ------------------------------------ |
| [react-frontend](/docs/default/template/react-frontend)   | This template                        |
| [node-backend](/docs/default/template/node-backend)       | Node.js backend API service          |
| [express-api](/docs/default/template/express-api)         | Express.js REST API                  |
| [nextjs-fullstack](/docs/default/template/nextjs-fullstack) | Next.js full-stack application     |
| [aws-s3-static](/docs/default/template/aws-s3-static)     | AWS S3 static website hosting        |
| [cloudflare-pages](/docs/default/template/cloudflare-pages) | Cloudflare Pages deployment        |

---

## References

- [React Documentation](https://react.dev)
- [Vite Documentation](https://vitejs.dev)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [React Router Documentation](https://reactrouter.com)
- [Vitest Documentation](https://vitest.dev)
- [React Testing Library](https://testing-library.com/docs/react-testing-library/intro/)
- [MSW Documentation](https://mswjs.io)
- [Biome Documentation](https://biomejs.dev)
- [TanStack Query](https://tanstack.com/query/latest)
- [Docker Documentation](https://docs.docker.com)
- [GitHub Actions](https://docs.github.com/en/actions)
