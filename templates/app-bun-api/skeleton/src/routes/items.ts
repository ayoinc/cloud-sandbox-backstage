import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import { z } from 'zod';
import type { ItemStore } from '../store';

const newItem = z.strictObject({
  name: z.string().trim().min(1).max(200),
});

export function itemRoutes(store: ItemStore): Hono {
  const routes = new Hono();

  routes.get('/', async (c) => c.json({ items: await store.list() }));

  routes.post(
    '/',
    zValidator('json', newItem, (result, c) => {
      if (!result.success) {
        return c.json(
          {
            error: 'The request body is invalid',
            issues: result.error.issues.map((issue) => ({
              path: issue.path.join('.'),
              message: issue.message,
            })),
          },
          422,
        );
      }
    }),
    async (c) => {
      const item = await store.create(c.req.valid('json').name);
      return c.json(item, 201, { Location: `/api/items/${item.id}` });
    },
  );

  routes.get('/:id', async (c) => {
    const item = await store.get(c.req.param('id'));
    return item ? c.json(item) : c.json({ error: 'Item not found' }, 404);
  });

  return routes;
}
