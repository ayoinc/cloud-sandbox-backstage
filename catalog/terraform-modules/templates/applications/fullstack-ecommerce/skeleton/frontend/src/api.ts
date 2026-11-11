export interface Features {
  productManagement: boolean;
  payments: boolean;
  search: boolean;
  reviews: boolean;
  inventory: boolean;
  analytics: boolean;
  caching: boolean;
}

export interface Product {
  id: string;
  name: string;
  description: string;
  priceCents: number;
  imageUrl: string | null;
  available: boolean;
  /** Only present when the store tracks inventory. */
  stock?: number;
  /** Only present on a single product, when the store has reviews. */
  rating?: { average: number | null; count: number };
}

export interface ProductInput {
  name: string;
  description: string;
  priceCents: number;
  stock: number;
}

export interface Review {
  id: string;
  author: string;
  rating: number;
  comment: string;
  createdAt: string;
}

export interface Order {
  id: string;
  status: string;
  totalCents: number;
}

export interface SalesSummary {
  orders: number;
  revenueCents: number;
  averageOrderCents: number;
  topProducts: { name: string; unitsSold: number }[];
}

const BASE = '/api/v1';

/** A response of the API that is not a success, with the message it gave. */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

async function request<T>(path: string, init: { method?: string; body?: unknown; adminToken?: string } = {}): Promise<T> {
  const response = await fetch(BASE + path, {
    method: init.method ?? 'GET',
    headers: {
      ...(init.body === undefined ? {} : { 'content-type': 'application/json' }),
      ...(init.adminToken ? { authorization: `Bearer ${init.adminToken}` } : {}),
    },
    body: init.body === undefined ? undefined : JSON.stringify(init.body),
  });
  const text = await response.text();
  const body = text ? JSON.parse(text) : undefined;
  if (!response.ok) throw new ApiError(response.status, body?.error ?? `Request failed (${response.status}).`);
  return body as T;
}

export const api = {
  getFeatures: async () => (await request<{ features: Features }>('/config')).features,

  listProducts: async (search = '') =>
    (await request<{ products: Product[] }>(`/products${search ? `?q=${encodeURIComponent(search)}` : ''}`)).products,
  getProduct: async (id: string) => (await request<{ product: Product }>(`/products/${id}`)).product,

  listReviews: async (productId: string) =>
    (await request<{ reviews: Review[] }>(`/products/${productId}/reviews`)).reviews,
  addReview: (productId: string, review: { author: string; rating: number; comment: string }) =>
    request<{ review: Review }>(`/products/${productId}/reviews`, { method: 'POST', body: review }),

  placeOrder: async (order: {
    customerEmail: string;
    items: { productId: string; quantity: number }[];
    paymentToken?: string;
  }) => (await request<{ order: Order }>('/orders', { method: 'POST', body: order })).order,

  createProduct: (product: ProductInput, adminToken: string) =>
    request<{ product: Product }>('/admin/products', { method: 'POST', body: product, adminToken }),
  deleteProduct: (id: string, adminToken: string) =>
    request<void>(`/admin/products/${id}`, { method: 'DELETE', adminToken }),
  getSalesSummary: async (adminToken: string) =>
    (await request<{ summary: SalesSummary }>('/admin/analytics/summary', { adminToken })).summary,
};
