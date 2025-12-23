# React Frontend App

Production-ready React 18 frontend application built with TypeScript, Vite, Material-UI (MUI), React Query, React Router, and comprehensive testing with Vitest and Playwright.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/example/sample-react-frontend.git
cd sample-react-frontend

# Install dependencies
npm install

# Set up environment
cp .env.example .env.local

# Start development server
npm run dev

# App is available at http://localhost:5173
```

## Features

| Feature | Description | Status |
|---------|-------------|--------|
| **React 18** | Latest React with concurrent features | ✅ Stable |
| **TypeScript 5.x** | Type-safe development | ✅ Stable |
| **Vite 5.x** | Fast build tool with HMR | ✅ Stable |
| **Material-UI 5.x** | Component library with theming | ✅ Stable |
| **React Router 6** | Client-side routing | ✅ Stable |
| **React Query** | Server state management | ✅ Stable |
| **Zustand** | Client state management | ✅ Stable |
| **React Hook Form** | Form handling with validation | ✅ Stable |
| **Zod** | Schema validation | ✅ Stable |
| **Axios** | HTTP client with interceptors | ✅ Stable |
| **Vitest** | Unit and integration testing | ✅ Stable |
| **Playwright** | E2E testing | ✅ Stable |
| **Storybook** | Component documentation | ✅ Stable |
| **Docker** | Production-ready container | ✅ Stable |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         React Frontend Application                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                          Presentation Layer                           │   │
│  │                                                                       │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │   │
│  │  │    Pages    │  │   Layouts   │  │ Components  │  │   Modals    │  │   │
│  │  │             │  │             │  │             │  │             │  │   │
│  │  │ • Dashboard │  │ • MainLayout│  │ • Button    │  │ • Confirm   │  │   │
│  │  │ • Products  │  │ • AuthLayout│  │ • Card      │  │ • Form      │  │   │
│  │  │ • Orders    │  │ • ErrorPage │  │ • Table     │  │ • Alert     │  │   │
│  │  │ • Profile   │  │             │  │ • Form      │  │             │  │   │
│  │  └──────┬──────┘  └─────────────┘  └─────────────┘  └─────────────┘  │   │
│  │         │                                                             │   │
│  └─────────┼─────────────────────────────────────────────────────────────┘   │
│            │                                                                  │
│  ┌─────────▼────────────────────────────────────────────────────────────┐   │
│  │                         State Management                              │   │
│  │                                                                       │   │
│  │  ┌───────────────────────────┐  ┌───────────────────────────────┐    │   │
│  │  │      React Query          │  │         Zustand                │    │   │
│  │  │   (Server State)          │  │     (Client State)             │    │   │
│  │  │                           │  │                                │    │   │
│  │  │ • Queries (GET)           │  │ • Auth state                   │    │   │
│  │  │ • Mutations (POST/PUT)    │  │ • UI state (theme, sidebar)    │    │   │
│  │  │ • Caching                 │  │ • Cart state                   │    │   │
│  │  │ • Background refetch      │  │ • User preferences             │    │   │
│  │  └───────────────────────────┘  └───────────────────────────────┘    │   │
│  │                                                                       │   │
│  └───────────────────────────────────────────────────────────────────────┘   │
│            │                                                                  │
│  ┌─────────▼────────────────────────────────────────────────────────────┐   │
│  │                          Service Layer                                │   │
│  │                                                                       │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │   │
│  │  │  API Client │  │ Auth Service│  │ Storage     │  │  Analytics  │  │   │
│  │  │  (Axios)    │  │             │  │  Service    │  │   Service   │  │   │
│  │  └──────┬──────┘  └─────────────┘  └─────────────┘  └─────────────┘  │   │
│  │         │                                                             │   │
│  └─────────┼─────────────────────────────────────────────────────────────┘   │
│            │                                                                  │
│            ▼                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                       Backend API (REST)                              │   │
│  │                   http://api.example.com/api/v1                       │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
sample-react-frontend/
├── src/
│   ├── main.tsx                    # Application entry point
│   ├── App.tsx                     # Root component
│   ├── vite-env.d.ts               # Vite type declarations
│   ├── assets/
│   │   ├── images/
│   │   └── fonts/
│   ├── components/
│   │   ├── common/
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
│   ├── pages/
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
│   ├── services/
│   │   ├── api.ts                  # Axios instance
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
│   ├── utils/
│   │   ├── formatters.ts
│   │   ├── validators.ts
│   │   └── constants.ts
│   ├── theme/
│   │   ├── index.ts
│   │   ├── palette.ts
│   │   ├── typography.ts
│   │   └── components.ts
│   └── routes/
│       ├── index.tsx
│       ├── PrivateRoute.tsx
│       └── routes.ts
├── public/
│   └── favicon.ico
├── tests/
│   ├── setup.ts
│   ├── utils.tsx
│   └── e2e/
│       └── auth.spec.ts
├── .storybook/
│   ├── main.ts
│   └── preview.ts
├── docker/
│   ├── Dockerfile
│   └── nginx.conf
├── package.json
├── vite.config.ts
├── tsconfig.json
├── vitest.config.ts
├── playwright.config.ts
└── .eslintrc.cjs
```

## Page Routes

| Route | Component | Auth Required | Description |
|-------|-----------|---------------|-------------|
| `/` | Dashboard | Yes | Main dashboard |
| `/login` | Login | No | User login |
| `/register` | Register | No | User registration |
| `/forgot-password` | ForgotPassword | No | Password reset |
| `/products` | ProductList | No | Product catalog |
| `/products/:id` | ProductDetail | No | Product details |
| `/cart` | Cart | Yes | Shopping cart |
| `/checkout` | Checkout | Yes | Order checkout |
| `/orders` | OrderList | Yes | User orders |
| `/orders/:id` | OrderDetail | Yes | Order details |
| `/profile` | Profile | Yes | User profile |
| `/settings` | Settings | Yes | App settings |
| `*` | NotFound | No | 404 page |

## Related Documentation

- [Overview](overview.md) - Detailed architecture, theming, and state management
- [Usage](usage.md) - Development, testing, and deployment
