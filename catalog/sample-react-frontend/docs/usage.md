# Usage Guide

## Development Setup

### Prerequisites

```bash
# Required tools
node --version   # v20.x or higher
npm --version    # v10.x or higher

# Install dependencies
npm install

# Set up environment
cp .env.example .env.local
```

### Environment Configuration

```bash
# .env.local
VITE_API_URL=http://localhost:3000/api/v1
VITE_APP_NAME=Sample React App
VITE_ENABLE_MOCKS=false
VITE_SENTRY_DSN=
VITE_GA_TRACKING_ID=
```

### Development Server

```bash
# Start development server
npm run dev

# Start with host access (for mobile testing)
npm run dev -- --host

# Preview production build
npm run preview
```

## Component Development

### Creating a New Component

```typescript
// src/components/common/Button/Button.tsx
import React from 'react';
import {
  Button as MuiButton,
  ButtonProps as MuiButtonProps,
} from '@mui/material';
import { styled } from '@mui/material/styles';

export interface ButtonProps extends Omit<MuiButtonProps, 'color'> {
  color?: 'primary' | 'secondary' | 'success' | 'error' | 'warning';
  loading?: boolean;
}

const StyledButton = styled(MuiButton)(({ theme }) => ({
  position: 'relative',
  '&.loading': {
    color: 'transparent',
  },
}));

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ children, loading = false, disabled, className, ...props }, ref) => {
    return (
      <StyledButton
        ref={ref}
        disabled={disabled || loading}
        className={`${className || ''} ${loading ? 'loading' : ''}`}
        {...props}
      >
        {children}
        {loading && (
          <span className="loading-spinner">{/* Spinner component */}</span>
        )}
      </StyledButton>
    );
  },
);

Button.displayName = 'Button';
```

### Component Export Pattern

```typescript
// src/components/common/Button/index.ts
export { Button } from './Button';
export type { ButtonProps } from './Button';
```

### Creating a Page

```typescript
// src/pages/Products/ProductList.tsx
import { useState } from 'react';
import {
  Box,
  Typography,
  TextField,
  InputAdornment,
  Grid,
  Pagination,
  Skeleton,
} from '@mui/material';
import { Search as SearchIcon } from '@mui/icons-material';
import { useProducts } from '../../hooks/useProducts';
import { ProductCard } from '../../components/features/products/ProductCard';
import { useDebounce } from '../../hooks/useDebounce';

export function ProductList() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const debouncedSearch = useDebounce(search, 300);

  const { data, isLoading, error } = useProducts({
    page,
    limit: 12,
    search: debouncedSearch,
  });

  if (error) {
    return (
      <Box sx={{ textAlign: 'center', py: 4 }}>
        <Typography color="error">Failed to load products</Typography>
      </Box>
    );
  }

  return (
    <Box>
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between' }}>
        <Typography variant="h4" component="h1">
          Products
        </Typography>

        <TextField
          placeholder="Search products..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon />
              </InputAdornment>
            ),
          }}
          sx={{ width: 300 }}
        />
      </Box>

      <Grid container spacing={3}>
        {isLoading
          ? Array.from({ length: 12 }).map((_, i) => (
              <Grid item xs={12} sm={6} md={4} lg={3} key={i}>
                <Skeleton variant="rectangular" height={300} />
              </Grid>
            ))
          : data?.data.map(product => (
              <Grid item xs={12} sm={6} md={4} lg={3} key={product.id}>
                <ProductCard product={product} />
              </Grid>
            ))}
      </Grid>

      {data && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}>
          <Pagination
            count={data.pagination.totalPages}
            page={page}
            onChange={(_, value) => setPage(value)}
            color="primary"
          />
        </Box>
      )}
    </Box>
  );
}
```

## Routing

### Route Configuration

```typescript
// src/routes/routes.ts
import { lazy } from 'react';

// Lazy load pages for code splitting
const Dashboard = lazy(() => import('../pages/Dashboard'));
const ProductList = lazy(() => import('../pages/Products/ProductList'));
const ProductDetail = lazy(() => import('../pages/Products/ProductDetail'));
const Login = lazy(() => import('../pages/Auth/Login'));
const Register = lazy(() => import('../pages/Auth/Register'));
const Orders = lazy(() => import('../pages/Orders'));
const Profile = lazy(() => import('../pages/Profile'));
const NotFound = lazy(() => import('../pages/NotFound'));

export const routes = [
  {
    path: '/',
    element: Dashboard,
    auth: true,
  },
  {
    path: '/products',
    element: ProductList,
    auth: false,
  },
  {
    path: '/products/:id',
    element: ProductDetail,
    auth: false,
  },
  {
    path: '/orders',
    element: Orders,
    auth: true,
  },
  {
    path: '/profile',
    element: Profile,
    auth: true,
  },
  {
    path: '/login',
    element: Login,
    auth: false,
    guestOnly: true,
  },
  {
    path: '/register',
    element: Register,
    auth: false,
    guestOnly: true,
  },
  {
    path: '*',
    element: NotFound,
    auth: false,
  },
];
```

### Protected Routes

```typescript
// src/routes/PrivateRoute.tsx
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuthStore } from '../stores/authStore';

interface PrivateRouteProps {
  redirectTo?: string;
}

export function PrivateRoute({ redirectTo = '/login' }: PrivateRouteProps) {
  const isAuthenticated = useAuthStore(state => state.isAuthenticated);
  const location = useLocation();

  if (!isAuthenticated) {
    return <Navigate to={redirectTo} state={{ from: location }} replace />;
  }

  return <Outlet />;
}

// Guest only route (redirect if authenticated)
export function GuestRoute({ redirectTo = '/' }: PrivateRouteProps) {
  const isAuthenticated = useAuthStore(state => state.isAuthenticated);

  if (isAuthenticated) {
    return <Navigate to={redirectTo} replace />;
  }

  return <Outlet />;
}
```

## Testing

### Unit Testing with Vitest

```typescript
// src/components/common/Button/Button.test.tsx
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from './Button';

describe('Button', () => {
  it('renders children correctly', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button')).toHaveTextContent('Click me');
  });

  it('handles click events', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);

    fireEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('shows loading state', () => {
    render(<Button loading>Click me</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });

  it('applies variant styles', () => {
    render(
      <Button variant="contained" color="primary">
        Primary
      </Button>,
    );
    const button = screen.getByRole('button');
    expect(button).toHaveClass('MuiButton-containedPrimary');
  });
});
```

### Integration Testing

```typescript
// src/pages/Products/ProductList.test.tsx
import { describe, it, expect, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { ProductList } from './ProductList';
import { productsService } from '../../services/products.service';

vi.mock('../../services/products.service');

const mockProducts = {
  data: [
    { id: '1', name: 'Product 1', price: 10.99, category: 'electronics' },
    { id: '2', name: 'Product 2', price: 20.99, category: 'electronics' },
  ],
  pagination: {
    page: 1,
    limit: 12,
    total: 2,
    totalPages: 1,
  },
};

const renderWithProviders = (ui: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
    },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>{ui}</MemoryRouter>
    </QueryClientProvider>,
  );
};

describe('ProductList', () => {
  it('displays products after loading', async () => {
    vi.mocked(productsService.getAll).mockResolvedValue(mockProducts);

    renderWithProviders(<ProductList />);

    await waitFor(() => {
      expect(screen.getByText('Product 1')).toBeInTheDocument();
      expect(screen.getByText('Product 2')).toBeInTheDocument();
    });
  });

  it('filters products by search', async () => {
    const user = userEvent.setup();
    vi.mocked(productsService.getAll).mockResolvedValue(mockProducts);

    renderWithProviders(<ProductList />);

    const searchInput = screen.getByPlaceholderText('Search products...');
    await user.type(searchInput, 'Product 1');

    await waitFor(() => {
      expect(productsService.getAll).toHaveBeenCalledWith(
        expect.objectContaining({ search: 'Product 1' }),
      );
    });
  });
});
```

### E2E Testing with Playwright

```typescript
// tests/e2e/auth.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('should login successfully', async ({ page }) => {
    await page.goto('/login');

    await page.fill('[name="email"]', 'user@example.com');
    await page.fill('[name="password"]', 'SecureP@ss123');
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL('/');
    await expect(page.getByText('Dashboard')).toBeVisible();
  });

  test('should show error for invalid credentials', async ({ page }) => {
    await page.goto('/login');

    await page.fill('[name="email"]', 'invalid@example.com');
    await page.fill('[name="password"]', 'wrongpassword');
    await page.click('button[type="submit"]');

    await expect(page.getByRole('alert')).toContainText('Invalid credentials');
  });

  test('should logout successfully', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('[name="email"]', 'user@example.com');
    await page.fill('[name="password"]', 'SecureP@ss123');
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL('/');

    // Logout
    await page.click('[data-testid="user-menu"]');
    await page.click('text=Logout');

    await expect(page).toHaveURL('/login');
  });
});
```

### Running Tests

```bash
# Unit and integration tests
npm test

# With coverage
npm run test:coverage

# Watch mode
npm run test:watch

# E2E tests
npm run test:e2e

# E2E in headed mode
npm run test:e2e:headed
```

## Docker Deployment

### Dockerfile

```dockerfile
# docker/Dockerfile
# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy custom nginx config
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=builder /app/dist /usr/share/nginx/html

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### Nginx Configuration

```nginx
# docker/nginx.conf
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    gzip_min_length 1000;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK";
        add_header Content-Type text/plain;
    }

    # SPA routing - serve index.html for all routes
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
```

### Docker Compose

```yaml
# docker/docker-compose.yaml
version: '3.8'

services:
  frontend:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    ports:
      - '80:80'
    environment:
      - VITE_API_URL=http://api:3000/api/v1
    depends_on:
      - api
    healthcheck:
      test: ['CMD', 'wget', '-q', '--spider', 'http://localhost/health']
      interval: 30s
      timeout: 10s
      retries: 3

  api:
    image: sample-nodejs-api:latest
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@postgres:5432/db
    depends_on:
      - postgres

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: db
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Kubernetes Deployment

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: react-frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: react-frontend
  template:
    metadata:
      labels:
        app: react-frontend
    spec:
      containers:
        - name: frontend
          image: react-frontend:latest
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
          livenessProbe:
            httpGet:
              path: /health
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: react-frontend
spec:
  selector:
    app: react-frontend
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: react-frontend
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: react-frontend
                port:
                  number: 80
```

## Troubleshooting

### Common Issues

| Issue                  | Cause               | Solution                                     |
| ---------------------- | ------------------- | -------------------------------------------- |
| White screen           | JavaScript error    | Check browser console for errors             |
| API CORS error         | Backend CORS config | Verify API CORS_ORIGIN includes frontend URL |
| Token expired          | JWT expired         | Check refresh token flow implementation      |
| Hot reload not working | Vite cache          | Clear `.vite` cache and restart dev server   |
| Build fails            | Type errors         | Run `npm run type-check` to find issues      |
| Styles not applied     | CSS import order    | Check theme provider is at root level        |

### Debug Commands

```bash
# Type checking
npm run type-check

# Lint check
npm run lint

# Build analysis
npm run build -- --analyze

# Clear cache
rm -rf node_modules/.vite dist
npm run dev
```

## Best Practices

### Performance Checklist

- [ ] Lazy load routes with React.lazy
- [ ] Memoize expensive computations with useMemo
- [ ] Use React.memo for pure components
- [ ] Implement virtualization for long lists
- [ ] Optimize images with proper formats/sizes
- [ ] Enable gzip/brotli compression
- [ ] Use code splitting effectively
- [ ] Monitor bundle size

### Security Checklist

- [ ] Sanitize user inputs
- [ ] Use HTTPS in production
- [ ] Implement proper CORS
- [ ] Store tokens securely
- [ ] Validate API responses
- [ ] Add CSP headers
- [ ] Protect against XSS
- [ ] Implement rate limiting

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Overview](overview.md) - Architecture and state management
