{%- if values.api_client == 'axios' %}
import axios, { type AxiosInstance, type AxiosError, type AxiosRequestConfig } from 'axios';

export interface ApiError {
  message: string;
  status: number;
  code?: string;
  details?: unknown;
}

const BASE_URL = import.meta.env.VITE_API_URL || '${{ values.api_base_url }}';

const axiosInstance: AxiosInstance = axios.create({
  baseURL: BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for auth tokens
axiosInstance.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor for error handling
axiosInstance.interceptors.response.use(
  (response) => response,
  (error: AxiosError<{ message?: string; code?: string }>) => {
    const apiError: ApiError = {
      message: error.response?.data?.message || error.message || 'An error occurred',
      status: error.response?.status || 500,
      code: error.response?.data?.code,
      details: error.response?.data,
    };

    // Handle 401 - Unauthorized
    if (error.response?.status === 401) {
      localStorage.removeItem('auth_token');
      window.location.href = '/login';
    }

    return Promise.reject(apiError);
  }
);

export const api = {
  get: async <T>(url: string, config?: AxiosRequestConfig): Promise<T> => {
    const response = await axiosInstance.get<T>(url, config);
    return response.data;
  },

  post: async <T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> => {
    const response = await axiosInstance.post<T>(url, data, config);
    return response.data;
  },

  put: async <T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> => {
    const response = await axiosInstance.put<T>(url, data, config);
    return response.data;
  },

  patch: async <T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> => {
    const response = await axiosInstance.patch<T>(url, data, config);
    return response.data;
  },

  delete: async <T>(url: string, config?: AxiosRequestConfig): Promise<T> => {
    const response = await axiosInstance.delete<T>(url, config);
    return response.data;
  },
};

export default api;
{%- else %}
export interface ApiError {
  message: string;
  status: number;
  code?: string;
  details?: unknown;
}

interface RequestConfig {
  headers?: Record<string, string>;
  signal?: AbortSignal;
}

const BASE_URL = import.meta.env.VITE_API_URL || '${{ values.api_base_url }}';

async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const error: ApiError = {
      message: errorData.message || `HTTP Error: ${response.status}`,
      status: response.status,
      code: errorData.code,
      details: errorData,
    };

    // Handle 401 - Unauthorized
    if (response.status === 401) {
      localStorage.removeItem('auth_token');
      window.location.href = '/login';
    }

    throw error;
  }

  // Handle 204 No Content
  if (response.status === 204) {
    return undefined as T;
  }

  return response.json();
}

function getHeaders(customHeaders?: Record<string, string>): Headers {
  const headers = new Headers({
    'Content-Type': 'application/json',
    ...customHeaders,
  });

  const token = localStorage.getItem('auth_token');
  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  return headers;
}

export const api = {
  get: async <T>(endpoint: string, config?: RequestConfig): Promise<T> => {
    const response = await fetch(`${BASE_URL}${endpoint}`, {
      method: 'GET',
      headers: getHeaders(config?.headers),
      signal: config?.signal,
    });
    return handleResponse<T>(response);
  },

  post: async <T>(endpoint: string, data?: unknown, config?: RequestConfig): Promise<T> => {
    const response = await fetch(`${BASE_URL}${endpoint}`, {
      method: 'POST',
      headers: getHeaders(config?.headers),
      body: data ? JSON.stringify(data) : undefined,
      signal: config?.signal,
    });
    return handleResponse<T>(response);
  },

  put: async <T>(endpoint: string, data?: unknown, config?: RequestConfig): Promise<T> => {
    const response = await fetch(`${BASE_URL}${endpoint}`, {
      method: 'PUT',
      headers: getHeaders(config?.headers),
      body: data ? JSON.stringify(data) : undefined,
      signal: config?.signal,
    });
    return handleResponse<T>(response);
  },

  patch: async <T>(endpoint: string, data?: unknown, config?: RequestConfig): Promise<T> => {
    const response = await fetch(`${BASE_URL}${endpoint}`, {
      method: 'PATCH',
      headers: getHeaders(config?.headers),
      body: data ? JSON.stringify(data) : undefined,
      signal: config?.signal,
    });
    return handleResponse<T>(response);
  },

  delete: async <T>(endpoint: string, config?: RequestConfig): Promise<T> => {
    const response = await fetch(`${BASE_URL}${endpoint}`, {
      method: 'DELETE',
      headers: getHeaders(config?.headers),
      signal: config?.signal,
    });
    return handleResponse<T>(response);
  },
};

export default api;
{%- endif %}
