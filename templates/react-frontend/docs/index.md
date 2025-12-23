# React Frontend Application Template

This template creates a modern React frontend application with TypeScript, testing, and deployment pipeline.

## Overview

Build production-ready React applications with modern tooling, component libraries, state management, and CI/CD automation.

## Features

### Build Tools
- **Vite** (Recommended) - Lightning fast HMR
- **Webpack** - Feature-rich bundling
- **Parcel** - Zero configuration
- **ESBuild** - Extremely fast builds

### UI Frameworks
- Material-UI (MUI)
- Ant Design
- Chakra UI
- Mantine
- Tailwind CSS

### State Management
- React Context (built-in)
- Redux Toolkit
- Zustand
- Jotai
- Recoil

## Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `react_version` | React version | 18 |
| `typescript` | Enable TypeScript | true |
| `build_tool` | Build tool | vite |
| `ui_framework` | UI component library | mui |
| `state_management` | State management | context |

## Getting Started

### Prerequisites
- Node.js 18+
- npm or yarn

### Local Development

1. **Install dependencies**
   ```bash
   npm install
   ```

2. **Start development server**
   ```bash
   npm run dev
   ```

3. **Open in browser**
   ```
   http://localhost:5173
   ```

### Available Scripts

```bash
# Development
npm run dev          # Start dev server
npm run build        # Production build
npm run preview      # Preview production build

# Testing
npm run test         # Run tests
npm run test:watch   # Watch mode
npm run test:coverage # Coverage report

# Code Quality
npm run lint         # ESLint
npm run format       # Prettier
npm run type-check   # TypeScript check

# Storybook
npm run storybook    # Start Storybook
npm run build-storybook # Build Storybook
```

## Project Structure

```
├── src/
│   ├── main.tsx              # Application entry
│   ├── App.tsx               # Root component
│   ├── components/           # Reusable components
│   │   ├── common/           # Generic components
│   │   ├── layout/           # Layout components
│   │   └── features/         # Feature-specific
│   ├── pages/                # Page components
│   ├── hooks/                # Custom hooks
│   ├── context/              # React Context providers
│   ├── services/             # API services
│   ├── utils/                # Utility functions
│   ├── types/                # TypeScript types
│   └── styles/               # Global styles
├── public/                   # Static assets
├── tests/                    # Test files
├── .storybook/              # Storybook config
└── vite.config.ts           # Vite configuration
```

## Component Development

### Function Component with TypeScript
```tsx
interface ButtonProps {
  label: string;
  onClick: () => void;
  variant?: 'primary' | 'secondary';
}

export const Button: React.FC<ButtonProps> = ({
  label,
  onClick,
  variant = 'primary'
}) => {
  return (
    <button
      className={`btn btn-${variant}`}
      onClick={onClick}
    >
      {label}
    </button>
  );
};
```

### Custom Hook Example
```tsx
import { useState, useEffect } from 'react';

export function useFetch<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    fetch(url)
      .then(res => res.json())
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [url]);

  return { data, loading, error };
}
```

## Routing

### React Router Setup
```tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/about" element={<About />} />
        <Route path="/users/:id" element={<UserDetail />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </BrowserRouter>
  );
}
```

## State Management

### React Context Example
```tsx
// AuthContext.tsx
const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: PropsWithChildren) {
  const [user, setUser] = useState<User | null>(null);

  const login = async (credentials: Credentials) => {
    const user = await authService.login(credentials);
    setUser(user);
  };

  return (
    <AuthContext.Provider value={{ user, login }}>
      {children}
    </AuthContext.Provider>
  );
}
```

### Redux Toolkit Example
```tsx
// userSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

const userSlice = createSlice({
  name: 'user',
  initialState: { user: null, loading: false },
  reducers: {
    setUser: (state, action: PayloadAction<User>) => {
      state.user = action.payload;
    },
  },
});
```

## Testing

### Component Testing
```tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from './Button';

describe('Button', () => {
  it('renders with label', () => {
    render(<Button label="Click me" onClick={() => {}} />);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('calls onClick when clicked', () => {
    const handleClick = jest.fn();
    render(<Button label="Click" onClick={handleClick} />);
    fireEvent.click(screen.getByText('Click'));
    expect(handleClick).toHaveBeenCalled();
  });
});
```

### API Mocking with MSW
```tsx
import { rest } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
  rest.get('/api/users', (req, res, ctx) => {
    return res(ctx.json([{ id: 1, name: 'John' }]));
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

## Storybook

### Component Story
```tsx
// Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  component: Button,
  title: 'Components/Button',
};

export default meta;
type Story = StoryObj<typeof Button>;

export const Primary: Story = {
  args: {
    label: 'Primary Button',
    variant: 'primary',
  },
};
```

## Deployment

### Docker Build
```dockerfile
FROM node:18-alpine as build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
```

### Static Hosting
The built application can be deployed to:
- Netlify
- Vercel
- AWS S3 + CloudFront
- Azure Static Web Apps
- GitHub Pages

## Performance Optimization

- Code splitting with dynamic imports
- Image optimization
- Bundle analysis with `vite-bundle-visualizer`
- React.lazy for route-based splitting
- useMemo and useCallback for expensive operations

## Related Templates

- [Python API](../python-api) - Backend API for your frontend
- [Node.js API](../app-nodejs-api) - Node.js backend
- [Kubernetes Microservice](../kubernetes-microservice) - Container deployment
