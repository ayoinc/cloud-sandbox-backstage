{%- if values.api_client == 'react-query' %}
import { useQuery, useMutation, useQueryClient, type UseQueryOptions, type UseMutationOptions } from '@tanstack/react-query';
import { api, type ApiError } from '../services/api';

/**
 * Generic hook for GET requests with TanStack Query
 */
export function useApiQuery<TData>(
  key: string[],
  endpoint: string,
  options?: Omit<UseQueryOptions<TData, ApiError>, 'queryKey' | 'queryFn'>
) {
  return useQuery<TData, ApiError>({
    queryKey: key,
    queryFn: () => api.get<TData>(endpoint),
    ...options,
  });
}

/**
 * Generic hook for POST/PUT/DELETE mutations with TanStack Query
 */
export function useApiMutation<TData, TVariables>(
  method: 'post' | 'put' | 'patch' | 'delete',
  endpoint: string,
  options?: Omit<UseMutationOptions<TData, ApiError, TVariables>, 'mutationFn'>
) {
  const queryClient = useQueryClient();
  
  return useMutation<TData, ApiError, TVariables>({
    mutationFn: (variables) => api[method]<TData>(endpoint, variables),
    onSuccess: () => {
      // Invalidate related queries on success
      queryClient.invalidateQueries();
    },
    ...options,
  });
}

/**
 * Example: Fetch items
 */
export function useItems() {
  return useApiQuery<unknown[]>(['items'], '/items');
}

/**
 * Example: Create item mutation
 */
export function useCreateItem() {
  return useApiMutation<unknown, { name: string; description?: string }>(
    'post',
    '/items'
  );
}
{%- elif values.api_client == 'swr' %}
import useSWR, { type SWRConfiguration } from 'swr';
import useSWRMutation, { type SWRMutationConfiguration } from 'swr/mutation';
import { api, type ApiError } from '../services/api';

/**
 * Generic hook for GET requests with SWR
 */
export function useApiQuery<TData>(
  key: string | null,
  endpoint: string,
  options?: SWRConfiguration<TData, ApiError>
) {
  return useSWR<TData, ApiError>(
    key,
    () => api.get<TData>(endpoint),
    {
      revalidateOnFocus: false,
      ...options,
    }
  );
}

/**
 * Generic hook for mutations with SWR
 */
export function useApiMutation<TData, TVariables>(
  key: string,
  method: 'post' | 'put' | 'patch' | 'delete',
  endpoint: string,
  options?: SWRMutationConfiguration<TData, ApiError, string, TVariables>
) {
  return useSWRMutation<TData, ApiError, string, TVariables>(
    key,
    (_key, { arg }) => api[method]<TData>(endpoint, arg),
    options
  );
}

/**
 * Example: Fetch items
 */
export function useItems() {
  return useApiQuery<unknown[]>('items', '/items');
}

/**
 * Example: Create item mutation
 */
export function useCreateItem() {
  return useApiMutation<unknown, { name: string; description?: string }>(
    'items',
    'post',
    '/items'
  );
}
{%- else %}
import { useState, useCallback, useEffect } from 'react';
import { api, type ApiError } from '../services/api';

interface UseApiQueryResult<T> {
  data: T | null;
  error: ApiError | null;
  isLoading: boolean;
  isError: boolean;
  refetch: () => Promise<void>;
}

interface UseApiMutationResult<T, V> {
  data: T | null;
  error: ApiError | null;
  isLoading: boolean;
  isError: boolean;
  isSuccess: boolean;
  mutate: (variables: V) => Promise<T>;
  reset: () => void;
}

/**
 * Generic hook for GET requests
 */
export function useApiQuery<T>(endpoint: string, options?: { enabled?: boolean }): UseApiQueryResult<T> {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<ApiError | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const enabled = options?.enabled ?? true;

  const fetchData = useCallback(async () => {
    if (!enabled) return;
    
    setIsLoading(true);
    setError(null);
    
    try {
      const result = await api.get<T>(endpoint);
      setData(result);
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setIsLoading(false);
    }
  }, [endpoint, enabled]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return {
    data,
    error,
    isLoading,
    isError: error !== null,
    refetch: fetchData,
  };
}

/**
 * Generic hook for POST/PUT/DELETE mutations
 */
export function useApiMutation<T, V>(
  method: 'post' | 'put' | 'patch' | 'delete',
  endpoint: string
): UseApiMutationResult<T, V> {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<ApiError | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);

  const mutate = useCallback(
    async (variables: V): Promise<T> => {
      setIsLoading(true);
      setError(null);
      setIsSuccess(false);

      try {
        const result = await api[method]<T>(endpoint, variables);
        setData(result);
        setIsSuccess(true);
        return result;
      } catch (err) {
        const apiError = err as ApiError;
        setError(apiError);
        throw apiError;
      } finally {
        setIsLoading(false);
      }
    },
    [method, endpoint]
  );

  const reset = useCallback(() => {
    setData(null);
    setError(null);
    setIsLoading(false);
    setIsSuccess(false);
  }, []);

  return {
    data,
    error,
    isLoading,
    isError: error !== null,
    isSuccess,
    mutate,
    reset,
  };
}

/**
 * Example: Fetch items
 */
export function useItems() {
  return useApiQuery<unknown[]>('/items');
}

/**
 * Example: Create item mutation
 */
export function useCreateItem() {
  return useApiMutation<unknown, { name: string; description?: string }>('post', '/items');
}
{%- endif %}
