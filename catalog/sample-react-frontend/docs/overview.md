# Overview

## Architecture Deep Dive

### Component Architecture

```d2
direction: down

title: React Component Hierarchy {
  shape: text
  near: top-center
  style.font-size: 20
  style.bold: true
}

App: "<App>" {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  ThemeProvider: "<ThemeProvider>" {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"

    QueryClientProvider: "<QueryClientProvider>" {
      style.fill: "#E8F5E9"
      style.stroke: "#388E3C"

      AuthProvider: "<AuthProvider>" {
        style.fill: "#E8F5E9"
        style.stroke: "#388E3C"

        BrowserRouter: "<BrowserRouter>" {
          style.fill: "#E8F5E9"
          style.stroke: "#388E3C"

          Routes: "<Routes>" {
            style.fill: "#FFF3E0"
            style.stroke: "#FF9800"

            MainLayout: "<MainLayout>" {
              style.fill: "#E3F2FD"
              style.stroke: "#1976D2"

              Header: "<Header />"
              Sidebar: "<Sidebar />"
              Outlet: "<Outlet /> Page content"
              Footer: "<Footer />"
            }

            AuthLayout: "<AuthLayout>" {
              style.fill: "#E3F2FD"
              style.stroke: "#1976D2"

              AuthOutlet: "<Outlet /> Auth pages"
            }

            NotFound: "<NotFound />" {
              style.fill: "#FFCDD2"
              style.stroke: "#D32F2F"
            }
          }
        }
      }
    }
  }
}
```

### State Management Flow

```d2
direction: down

title: State Management Architecture {
  shape: text
  near: top-center
  style.font-size: 20
  style.bold: true
}

tanstack_query: TanStack Query v5 (Server State) {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  user_action: User Action {
    shape: oval
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"
  }

  hooks: Query Hooks {
    direction: right

    useQuery: "useQuery()\n(Read data)" {
      style.fill: "#E8F5E9"
      style.stroke: "#388E3C"
    }

    useMutation: "useMutation()\n(Write data)" {
      style.fill: "#E8F5E9"
      style.stroke: "#388E3C"
    }

    useSuspenseQuery: "useSuspenseQuery()\n(Streaming)" {
      style.fill: "#E8F5E9"
      style.stroke: "#388E3C"
    }
  }

  cache: Query Cache {
    shape: cylinder
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
  }

  api: API Service {
    shape: hexagon
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }

  backend: Backend API {
    shape: cloud
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"
  }

  user_action -> hooks.useQuery
  user_action -> hooks.useMutation
  user_action -> hooks.useSuspenseQuery
  hooks.useQuery -> cache
  hooks.useMutation -> cache
  hooks.useSuspenseQuery -> cache
  cache -> api
  api -> backend
}

zustand: Zustand 5 (Client State) {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  stores: Stores {
    direction: right

    authStore: authStore {
      style.fill: "#E3F2FD"
      style.stroke: "#1976D2"
    }

    uiStore: uiStore {
      style.fill: "#E3F2FD"
      style.stroke: "#1976D2"
    }

    cartStore: cartStore {
      style.fill: "#E3F2FD"
      style.stroke: "#1976D2"
    }
  }

  localStorage: localStorage (persist) {
    shape: cylinder
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
  }

  stores.authStore -> localStorage
  stores.uiStore -> localStorage
  stores.cartStore -> localStorage
}

tanstack_query -> zustand: "Component uses both" {
  style.stroke-dash: 5
}
```

## Theme Configuration

### MUI Theme Setup

```typescript
// src/theme/index.ts
import { createTheme, ThemeOptions } from '@mui/material/styles';
import { palette } from './palette';
import { typography } from './typography';
import { components } from './components';

const baseTheme: ThemeOptions = {
  typography,
  shape: {
    borderRadius: 8,
  },
  shadows: [
    'none',
    '0px 1px 2px rgba(0, 0, 0, 0.05)',
    '0px 1px 3px rgba(0, 0, 0, 0.1)',
    '0px 2px 4px rgba(0, 0, 0, 0.1)',
    // ... more shadows
  ],
};

export const lightTheme = createTheme({
  ...baseTheme,
  palette: palette.light,
  components: components.light,
});

export const darkTheme = createTheme({
  ...baseTheme,
  palette: palette.dark,
  components: components.dark,
});
```

### Palette Configuration

```typescript
// src/theme/palette.ts
import { PaletteOptions } from '@mui/material/styles';

export const palette = {
  light: {
    mode: 'light',
    primary: {
      main: '#1976d2',
      light: '#42a5f5',
      dark: '#1565c0',
      contrastText: '#ffffff',
    },
    secondary: {
      main: '#9c27b0',
      light: '#ba68c8',
      dark: '#7b1fa2',
      contrastText: '#ffffff',
    },
    error: {
      main: '#d32f2f',
      light: '#ef5350',
      dark: '#c62828',
    },
    warning: {
      main: '#ed6c02',
      light: '#ff9800',
      dark: '#e65100',
    },
    success: {
      main: '#2e7d32',
      light: '#4caf50',
      dark: '#1b5e20',
    },
    background: {
      default: '#f5f5f5',
      paper: '#ffffff',
    },
    text: {
      primary: 'rgba(0, 0, 0, 0.87)',
      secondary: 'rgba(0, 0, 0, 0.6)',
      disabled: 'rgba(0, 0, 0, 0.38)',
    },
  } as PaletteOptions,

  dark: {
    mode: 'dark',
    primary: {
      main: '#90caf9',
      light: '#e3f2fd',
      dark: '#42a5f5',
      contrastText: 'rgba(0, 0, 0, 0.87)',
    },
    secondary: {
      main: '#ce93d8',
      light: '#f3e5f5',
      dark: '#ab47bc',
      contrastText: 'rgba(0, 0, 0, 0.87)',
    },
    background: {
      default: '#121212',
      paper: '#1e1e1e',
    },
    text: {
      primary: '#ffffff',
      secondary: 'rgba(255, 255, 255, 0.7)',
      disabled: 'rgba(255, 255, 255, 0.5)',
    },
  } as PaletteOptions,
};
```

### Component Overrides

```typescript
// src/theme/components.ts
import { Components, Theme } from '@mui/material/styles';

export const components = {
  light: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          fontWeight: 600,
        },
        containedPrimary: {
          boxShadow: 'none',
          '&:hover': {
            boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
          },
        },
      },
      defaultProps: {
        disableElevation: true,
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          boxShadow: '0 1px 3px rgba(0,0,0,0.12)',
          borderRadius: 12,
        },
      },
    },
    MuiTextField: {
      defaultProps: {
        variant: 'outlined',
        size: 'small',
      },
    },
    MuiTableCell: {
      styleOverrides: {
        head: {
          fontWeight: 600,
          backgroundColor: '#f5f5f5',
        },
      },
    },
  } as Components<Omit<Theme, 'components'>>,

  dark: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          fontWeight: 600,
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          boxShadow: '0 1px 3px rgba(0,0,0,0.3)',
          borderRadius: 12,
          backgroundColor: '#1e1e1e',
        },
      },
    },
  } as Components<Omit<Theme, 'components'>>,
};
```

## State Management

### Zustand Store Implementation

```typescript
// src/stores/authStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { User, AuthTokens } from '../types/auth.types';
import { authService } from '../services/auth.service';

interface AuthState {
  user: User | null;
  accessToken: string | null;
  refreshToken: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;

  // Actions
  login: (email: string, password: string) => Promise<void>;
  register: (data: RegisterData) => Promise<void>;
  logout: () => void;
  refreshAuth: () => Promise<void>;
  setUser: (user: User) => void;
  clearError: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,

      login: async (email: string, password: string) => {
        set({ isLoading: true, error: null });
        try {
          const response = await authService.login({ email, password });
          set({
            user: response.user,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            isAuthenticated: true,
            isLoading: false,
          });
        } catch (error) {
          set({
            error: error instanceof Error ? error.message : 'Login failed',
            isLoading: false,
          });
          throw error;
        }
      },

      register: async data => {
        set({ isLoading: true, error: null });
        try {
          const response = await authService.register(data);
          set({
            user: response.user,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            isAuthenticated: true,
            isLoading: false,
          });
        } catch (error) {
          set({
            error:
              error instanceof Error ? error.message : 'Registration failed',
            isLoading: false,
          });
          throw error;
        }
      },

      logout: () => {
        authService.logout();
        set({
          user: null,
          accessToken: null,
          refreshToken: null,
          isAuthenticated: false,
        });
      },

      refreshAuth: async () => {
        const { refreshToken } = get();
        if (!refreshToken) return;

        try {
          const tokens = await authService.refresh(refreshToken);
          set({
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
          });
        } catch {
          get().logout();
        }
      },

      setUser: user => set({ user }),
      clearError: () => set({ error: null }),
    }),
    {
      name: 'auth-storage',
      partialize: state => ({
        accessToken: state.accessToken,
        refreshToken: state.refreshToken,
        user: state.user,
        isAuthenticated: state.isAuthenticated,
      }),
    },
  ),
);
```

### React Query Hooks

```typescript
// src/hooks/useProducts.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { productsService, ProductsParams } from '../services/products.service';
import { Product, CreateProductInput } from '../types/product.types';

export const productKeys = {
  all: ['products'] as const,
  lists: () => [...productKeys.all, 'list'] as const,
  list: (params: ProductsParams) => [...productKeys.lists(), params] as const,
  details: () => [...productKeys.all, 'detail'] as const,
  detail: (id: string) => [...productKeys.details(), id] as const,
};

export function useProducts(params: ProductsParams = {}) {
  return useQuery({
    queryKey: productKeys.list(params),
    queryFn: () => productsService.getAll(params),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useProduct(id: string) {
  return useQuery({
    queryKey: productKeys.detail(id),
    queryFn: () => productsService.getById(id),
    enabled: !!id,
  });
}

export function useCreateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateProductInput) => productsService.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: productKeys.lists() });
    },
  });
}

export function useUpdateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Product> }) =>
      productsService.update(id, data),
    onSuccess: updatedProduct => {
      queryClient.setQueryData(
        productKeys.detail(updatedProduct.id),
        updatedProduct,
      );
      queryClient.invalidateQueries({ queryKey: productKeys.lists() });
    },
  });
}

export function useDeleteProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => productsService.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: productKeys.lists() });
    },
  });
}
```

## API Integration

### Axios Client Configuration

```typescript
// src/services/api.ts
import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios';
import { useAuthStore } from '../stores/authStore';

const API_BASE_URL =
  import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1';

export const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor - add auth token
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = useAuthStore.getState().accessToken;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  error => Promise.reject(error),
);

// Response interceptor - handle token refresh
api.interceptors.response.use(
  response => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & {
      _retry?: boolean;
    };

    // Handle 401 errors (unauthorized)
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        await useAuthStore.getState().refreshAuth();
        const newToken = useAuthStore.getState().accessToken;

        if (newToken) {
          originalRequest.headers.Authorization = `Bearer ${newToken}`;
          return api(originalRequest);
        }
      } catch {
        useAuthStore.getState().logout();
        window.location.href = '/login';
      }
    }

    return Promise.reject(error);
  },
);

export default api;
```

### Service Layer Pattern

```typescript
// src/services/products.service.ts
import api from './api';
import {
  Product,
  CreateProductInput,
  UpdateProductInput,
} from '../types/product.types';
import { PaginatedResponse } from '../types/api.types';

export interface ProductsParams {
  page?: number;
  limit?: number;
  category?: string;
  search?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
  minPrice?: number;
  maxPrice?: number;
}

class ProductsService {
  private baseUrl = '/products';

  async getAll(
    params: ProductsParams = {},
  ): Promise<PaginatedResponse<Product>> {
    const { data } = await api.get<PaginatedResponse<Product>>(this.baseUrl, {
      params,
    });
    return data;
  }

  async getById(id: string): Promise<Product> {
    const { data } = await api.get<Product>(`${this.baseUrl}/${id}`);
    return data;
  }

  async create(input: CreateProductInput): Promise<Product> {
    const { data } = await api.post<Product>(this.baseUrl, input);
    return data;
  }

  async update(id: string, input: UpdateProductInput): Promise<Product> {
    const { data } = await api.put<Product>(`${this.baseUrl}/${id}`, input);
    return data;
  }

  async delete(id: string): Promise<void> {
    await api.delete(`${this.baseUrl}/${id}`);
  }

  async getCategories(): Promise<string[]> {
    const { data } = await api.get<string[]>(`${this.baseUrl}/categories`);
    return data;
  }
}

export const productsService = new ProductsService();
```

## Form Handling

### React Hook Form with Zod

```typescript
// src/components/features/auth/LoginForm.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { TextField, Button, Box, Alert } from '@mui/material';
import { useAuthStore } from '../../../stores/authStore';

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

type LoginFormData = z.infer<typeof loginSchema>;

export function LoginForm() {
  const { login, isLoading, error, clearError } = useAuthStore();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: '',
    },
  });

  const onSubmit = async (data: LoginFormData) => {
    try {
      await login(data.email, data.password);
    } catch {
      // Error is handled in store
    }
  };

  return (
    <Box
      component="form"
      onSubmit={handleSubmit(onSubmit)}
      noValidate
      sx={{ mt: 1 }}
    >
      {error && (
        <Alert severity="error" onClose={clearError} sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <TextField
        {...register('email')}
        margin="normal"
        required
        fullWidth
        label="Email Address"
        autoComplete="email"
        autoFocus
        error={!!errors.email}
        helperText={errors.email?.message}
      />

      <TextField
        {...register('password')}
        margin="normal"
        required
        fullWidth
        label="Password"
        type="password"
        autoComplete="current-password"
        error={!!errors.password}
        helperText={errors.password?.message}
      />

      <Button
        type="submit"
        fullWidth
        variant="contained"
        disabled={isLoading}
        sx={{ mt: 3, mb: 2 }}
      >
        {isLoading ? 'Signing in...' : 'Sign In'}
      </Button>
    </Box>
  );
}
```

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Usage](usage.md) - Development, testing, and deployment
