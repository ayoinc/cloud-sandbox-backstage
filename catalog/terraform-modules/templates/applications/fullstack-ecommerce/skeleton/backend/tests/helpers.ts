import type { Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import { createApp, type Dependencies } from '../src/app.js';
import { noCache } from '../src/cache.js';
import { type Config, loadConfig } from '../src/config.js';
import { createDb, type Db, migrate } from '../src/db.js';
import type { Features } from '../src/features.js';
import { SandboxPaymentProvider } from '../src/payments.js';
import { type ProductInput, Store } from '../src/store.js';

export const ADMIN_TOKEN = 'test-admin-token';

const allOff: Features = {
  productManagement: false,
  payments: false,
  search: false,
  reviews: false,
  inventory: false,
  analytics: false,
  caching: false,
};

// Each test asserts the shape of the JSON it asked for, so bodies are not typed further.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Json = any;

export interface TestApp {
  db: Db;
  store: Store;
  /** Calls the API under /api/v1 and returns the status and the JSON body. */
  call(method: string, path: string, body?: unknown, token?: string): Promise<{ status: number; body: Json }>;
  /** Adds a product straight to the database. */
  addProduct(input?: Partial<ProductInput>): Promise<{ id: string }>;
  close(): Promise<void>;
}

/**
 * Starts the API on a free port against an empty database, with every
 * feature off except the ones given.
 */
export async function startTestApp(
  features: Partial<Features> = {},
  overrides: Partial<Config> & Partial<Dependencies> = {},
): Promise<TestApp> {
  const base = loadConfig({ DATABASE_URL: process.env.DATABASE_URL });
  const db = createDb(base.databaseUrl);
  await migrate(db);
  await db.query('truncate order_items, orders, reviews, products');

  const config: Config = { ...base, adminToken: ADMIN_TOKEN, ...overrides, features: { ...allOff, ...features } };
  const app = createApp(config, {
    db,
    cache: overrides.cache ?? noCache,
    payments: overrides.payments ?? new SandboxPaymentProvider(),
  });
  const server = await new Promise<Server>(resolve => {
    const listening = app.listen(0, '127.0.0.1', () => resolve(listening));
  });
  const url = `http://127.0.0.1:${(server.address() as AddressInfo).port}/api/v1`;
  const store = new Store(db);

  return {
    db,
    store,
    async call(method, path, body, token) {
      const response = await fetch(url + path, {
        method,
        headers: {
          ...(body === undefined ? {} : { 'content-type': 'application/json' }),
          ...(token ? { authorization: `Bearer ${token}` } : {}),
        },
        body: body === undefined ? undefined : JSON.stringify(body),
      });
      const text = await response.text();
      return { status: response.status, body: text ? JSON.parse(text) : undefined };
    },
    addProduct: input => store.createProduct({ name: 'Mug', description: 'A mug', priceCents: 1400, stock: 10, ...input }),
    async close() {
      await new Promise(resolve => server.close(resolve));
      await db.end();
    },
  };
}
