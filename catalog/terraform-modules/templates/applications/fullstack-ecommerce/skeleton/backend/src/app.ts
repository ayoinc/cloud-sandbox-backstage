import { timingSafeEqual } from 'node:crypto';
import express, { type ErrorRequestHandler, type Express, type RequestHandler } from 'express';
import { z } from 'zod';
import type { Cache } from './cache.js';
import type { Config } from './config.js';
import type { Db } from './db.js';
import type { PaymentProvider } from './payments.js';
import { OrderError, type Product, Store } from './store.js';

export const API_BASE_PATH = '/api/v1';

export interface Dependencies {
  db: Db;
  cache: Cache;
  payments: PaymentProvider;
}

const productInput = z.object({
  name: z.string().trim().min(1).max(200),
  description: z.string().max(5000).default(''),
  priceCents: z.number().int().min(0),
  imageUrl: z.url().nullish(),
  stock: z.number().int().min(0).default(0),
});

const reviewInput = z.object({
  author: z.string().trim().min(1).max(100),
  rating: z.number().int().min(1).max(5),
  comment: z.string().max(2000).default(''),
});

const orderInput = z.object({
  customerEmail: z.email(),
  items: z
    .array(z.object({ productId: z.string(), quantity: z.number().int().min(1).max(1000) }))
    .min(1)
    .max(100),
  paymentToken: z.string().min(1).optional(),
});

const listQuery = z.object({
  q: z.string().trim().max(100).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(24),
  offset: z.coerce.number().int().min(0).default(0),
});

/** Builds the HTTP API of the store. Features that are off have no routes. */
export function createApp(config: Config, { db, cache, payments }: Dependencies): Express {
  const { features } = config;
  const store = new Store(db);
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '100kb' }));

  app.get('/healthz', (_req, res) => {
    res.json({ status: 'ok' });
  });
  app.get('/readyz', async (_req, res) => {
    try {
      await db.query('select 1');
      res.json({ status: 'ok' });
    } catch {
      res.status(503).json({ status: 'database unavailable' });
    }
  });

  const api = express.Router();
  app.use(API_BASE_PATH, api);

  /** What the API shows of a product: stock levels only when inventory is tracked. */
  const present = ({ stock, ...product }: Product) =>
    features.inventory ? { ...product, stock, available: stock > 0 } : { ...product, available: true };

  // The frontend reads this to know which parts of the store to show.
  api.get('/config', (_req, res) => {
    res.json({ features });
  });

  api.get('/products', async (req, res) => {
    const query = listQuery.parse(req.query);
    const search = features.search ? query.q || undefined : undefined;
    const products = await cache.wrap(`products:${search ?? ''}:${query.limit}:${query.offset}`, () =>
      store.listProducts({ search, limit: query.limit, offset: query.offset }),
    );
    res.json({ products: products.map(present) });
  });

  api.get('/products/:id', async (req, res) => {
    const { id } = req.params;
    const product = await cache.wrap(`product:${id}`, async () => (await store.getProduct(id)) ?? null);
    if (!product) {
      res.status(404).json({ error: 'Product not found.' });
      return;
    }
    const rating = features.reviews ? await cache.wrap(`rating:${id}`, () => store.getRating(id)) : undefined;
    res.json({ product: { ...present(product), rating } });
  });

  if (features.reviews) {
    api.get('/products/:id/reviews', async (req, res) => {
      res.json({ reviews: await store.listReviews(req.params.id) });
    });
    api.post('/products/:id/reviews', async (req, res) => {
      const input = reviewInput.parse(req.body);
      if (!(await store.getProduct(req.params.id))) {
        res.status(404).json({ error: 'Product not found.' });
        return;
      }
      const review = await store.addReview(req.params.id, input);
      await cache.invalidate();
      res.status(201).json({ review });
    });
  }

  api.post('/orders', async (req, res) => {
    const input = orderInput.parse(req.body);
    const order = await store.placeOrder(input, {
      trackStock: features.inventory,
      payments: features.payments ? payments : undefined,
    });
    if (features.inventory) await cache.invalidate();
    res.status(201).json({ order });
  });

  api.get('/orders/:id', async (req, res) => {
    const order = await store.getOrder(req.params.id);
    if (!order) {
      res.status(404).json({ error: 'Order not found.' });
      return;
    }
    res.json({ order });
  });

  if (features.productManagement || features.analytics) {
    const admin = express.Router();
    admin.use(requireAdmin(config.adminToken));
    api.use('/admin', admin);

    if (features.productManagement) {
      admin.post('/products', async (req, res) => {
        const product = await store.createProduct(productInput.parse(req.body));
        await cache.invalidate();
        res.status(201).json({ product });
      });
      admin.put('/products/:id', async (req, res) => {
        const product = await store.updateProduct(req.params.id, productInput.parse(req.body));
        if (!product) {
          res.status(404).json({ error: 'Product not found.' });
          return;
        }
        await cache.invalidate();
        res.json({ product });
      });
      admin.delete('/products/:id', async (req, res) => {
        if (!(await store.deleteProduct(req.params.id))) {
          res.status(404).json({ error: 'Product not found.' });
          return;
        }
        await cache.invalidate();
        res.status(204).end();
      });
    }

    if (features.analytics) {
      admin.get('/analytics/summary', async (_req, res) => {
        res.json({ summary: await store.salesSummary() });
      });
    }
  }

  api.use((_req, res) => {
    res.status(404).json({ error: 'Not found.' });
  });
  app.use(errorHandler);
  return app;
}

/** Lets a request through when it carries the admin token as a bearer token. */
function requireAdmin(adminToken: string | undefined): RequestHandler {
  return (req, res, next) => {
    if (!adminToken) {
      res.status(503).json({ error: 'The admin API is off: ADMIN_TOKEN is not set.' });
      return;
    }
    const presented = Buffer.from(req.headers.authorization?.replace(/^Bearer /, '') ?? '');
    const expected = Buffer.from(adminToken);
    if (presented.length !== expected.length || !timingSafeEqual(presented, expected)) {
      res.status(401).json({ error: 'A valid admin token is required.' });
      return;
    }
    next();
  };
}

const errorHandler: ErrorRequestHandler = (error, _req, res, _next) => {
  if (error instanceof z.ZodError) {
    res.status(400).json({ error: 'Invalid request.', details: z.flattenError(error) });
    return;
  }
  if (error instanceof OrderError) {
    res.status(error.status).json({ error: error.message });
    return;
  }
  if (error instanceof SyntaxError && 'body' in error) {
    res.status(400).json({ error: 'The request body is not valid JSON.' });
    return;
  }
  console.error(error);
  res.status(500).json({ error: 'Internal server error.' });
};
