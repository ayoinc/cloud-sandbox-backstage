# React Frontend App

Production-ready React 19 frontend application built with TypeScript 5.7, Vite 6, Material-UI 6, TanStack Query v5, React Router 7, and comprehensive testing with Vitest 2 and Playwright 1.49.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/example/sample-react-frontend.git
cd sample-react-frontend

# Install dependencies (using pnpm for faster installs)
pnpm install

# Set up environment
cp .env.example .env.local

# Start development server
pnpm dev

# App is available at http://localhost:5173
```

## Features

| Feature               | Description                                                      | Status    |
| --------------------- | ---------------------------------------------------------------- | --------- |
| **React 19**          | Latest React with React Compiler, Actions, and enhanced Suspense | ✅ Stable |
| **TypeScript 5.7**    | Type-safe development with latest features                       | ✅ Stable |
| **Vite 6**            | Lightning-fast build tool with Rolldown bundler                  | ✅ Stable |
| **Material-UI 6**     | Component library with Pigment CSS and zero-runtime styling      | ✅ Stable |
| **React Router 7**    | Full-stack routing with RSC support and type-safe routes         | ✅ Stable |
| **TanStack Query v5** | Powerful server state management with streaming                  | ✅ Stable |
| **Zustand 5**         | Lightweight client state with improved TypeScript support        | ✅ Stable |
| **React Hook Form 7** | Performant form handling with validation                         | ✅ Stable |
| **Zod 3.24**          | Schema validation with enhanced inference                        | ✅ Stable |
| **Axios 1.7**         | HTTP client with interceptors                                    | ✅ Stable |
| **Vitest 2.1**        | Fast unit and integration testing                                | ✅ Stable |
| **Playwright 1.49**   | Cross-browser E2E testing with trace viewer                      | ✅ Stable |
| **Storybook 8.4**     | Component documentation with RSC support                         | ✅ Stable |
| **Docker**            | Multi-stage production builds with distroless images             | ✅ Stable |
| **Biome**             | Fast linting and formatting (ESLint/Prettier alternative)        | ✅ Stable |

## Architecture

```d2
direction: down

title: React Frontend Application {
  shape: text
  near: top-center
  style.font-size: 20
  style.bold: true
}

presentation: Presentation Layer {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  pages: Pages {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }

  layouts: Layouts {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }

  components: Components {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }

  modals: Modals {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }
}

state: State Management {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  react_query: React Query {
    style.fill: "#E3F2FD"
    style.stroke: "#1976D2"
  }

  zustand: Zustand {
    style.fill: "#E3F2FD"
    style.stroke: "#1976D2"
  }
}

services: Service Layer {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  api_client: API Client (Axios) {
    shape: hexagon
    style.fill: "#E3F2FD"
    style.stroke: "#1976D2"
  }

  auth_service: Auth Service {
    shape: hexagon
  }

  storage: Storage Service {
    shape: hexagon
  }

  analytics: Analytics Service {
    shape: hexagon
  }
}

backend: Backend API (REST) {
  shape: cloud
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

presentation -> state
state -> services
services.api_client -> backend: HTTPS
```

## Project Structure

```
sample-react-frontend/
├── src/
│   ├── main.tsx                    # Application entry point
│   ├── App.tsx                     # Root component with providers
│   ├── vite-env.d.ts               # Vite type declarations
│   ├── assets/
│   │   ├── images/
│   │   └── fonts/
│   ├── components/
│   │   ├── ui/                     # Shadcn-style reusable components
│   │   │   ├── Button/
│   │   │   │   ├── Button.tsx
│   │   │   │   ├── Button.test.tsx
│   │   │   │   ├── Button.stories.tsx
│   │   │   │   └── index.ts
│   │   │   ├── Card/
│   │   │   ├── DataTable/
│   │   │   ├── Form/
│   │   │   └── Modal/
│   │   ├── layout/
│   │   │   ├── Header/
│   │   │   ├── Sidebar/
│   │   │   └── Footer/
│   │   └── features/
│   │       ├── auth/
│   │       ├── products/
│   │       └── orders/
│   ├── pages/                      # Route components
│   │   ├── Dashboard/
│   │   ├── Auth/
│   │   │   ├── Login.tsx
│   │   │   ├── Register.tsx
│   │   │   └── ForgotPassword.tsx
│   │   ├── Products/
│   │   ├── Orders/
│   │   └── Settings/
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useProducts.ts
│   │   ├── useOrders.ts
│   │   └── useDebounce.ts
│   ├── lib/                        # Third-party library configs
│   │   ├── api.ts                  # Axios/fetch instance
│   │   ├── query-client.ts         # TanStack Query client
│   │   └── utils.ts                # Utility functions (cn, etc.)
│   ├── services/
│   │   ├── auth.service.ts
│   │   ├── products.service.ts
│   │   └── orders.service.ts
│   ├── stores/
│   │   ├── authStore.ts
│   │   ├── uiStore.ts
│   │   └── cartStore.ts
│   ├── types/
│   │   ├── api.types.ts
│   │   ├── auth.types.ts
│   │   └── product.types.ts
│   ├── theme/
│   │   ├── index.ts
│   │   ├── palette.ts
│   │   ├── typography.ts
│   │   └── components.ts
│   └── routes/
│       ├── index.tsx               # Route definitions
│       ├── PrivateRoute.tsx
│       └── routes.ts
├── public/
│   └── favicon.ico
├── tests/
│   ├── setup.ts
│   ├── utils.tsx                   # Test utilities and providers
│   └── e2e/
│       └── auth.spec.ts
├── .storybook/
│   ├── main.ts
│   └── preview.ts
├── docker/
│   ├── Dockerfile                  # Multi-stage with distroless
│   └── nginx.conf
├── package.json
├── pnpm-lock.yaml                  # pnpm lockfile
├── vite.config.ts
├── tsconfig.json
├── vitest.config.ts
├── playwright.config.ts
└── biome.json                      # Linting and formatting
```

## Page Routes

| Route              | Component      | Auth Required | Description       |
| ------------------ | -------------- | ------------- | ----------------- |
| `/`                | Dashboard      | Yes           | Main dashboard    |
| `/login`           | Login          | No            | User login        |
| `/register`        | Register       | No            | User registration |
| `/forgot-password` | ForgotPassword | No            | Password reset    |
| `/products`        | ProductList    | No            | Product catalog   |
| `/products/:id`    | ProductDetail  | No            | Product details   |
| `/cart`            | Cart           | Yes           | Shopping cart     |
| `/checkout`        | Checkout       | Yes           | Order checkout    |
| `/orders`          | OrderList      | Yes           | User orders       |
| `/orders/:id`      | OrderDetail    | Yes           | Order details     |
| `/profile`         | Profile        | Yes           | User profile      |
| `/settings`        | Settings       | Yes           | App settings      |
| `*`                | NotFound       | No            | 404 page          |

## Related Documentation

- [Overview](overview.md) - Detailed architecture, theming, and state management
- [Usage](usage.md) - Development, testing, and deployment
