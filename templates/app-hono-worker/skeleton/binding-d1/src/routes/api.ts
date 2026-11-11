import { Hono } from 'hono';
import { z } from 'zod';
import type { AppEnv } from '../app';
import { jsonBody } from '../validation';

export type Item = {
  id: string;
  name: string;
  createdAt: string;
};

const newItem = z.strictObject({
  name: z.string().trim().min(1).max(200),
});

const columns = 'id, name, created_at AS createdAt';

export const api = new Hono<AppEnv>();

api.get('/items', async (c) => {
  const { results } = await c.env.DB.prepare(
    `SELECT ${columns} FROM items ORDER BY created_at, id LIMIT 100`,
  ).all<Item>();
  return c.json({ items: results });
});

api.post('/items', jsonBody(newItem), async (c) => {
  const { name } = c.req.valid('json');
  const item: Item = {
    id: crypto.randomUUID(),
    name,
    createdAt: new Date().toISOString(),
  };
  await c.env.DB.prepare(
    'INSERT INTO items (id, name, created_at) VALUES (?1, ?2, ?3)',
  )
    .bind(item.id, item.name, item.createdAt)
    .run();
  return c.json(item, 201, { Location: `/api/items/${item.id}` });
});

api.get('/items/:id', async (c) => {
  const item = await c.env.DB.prepare(
    `SELECT ${columns} FROM items WHERE id = ?1`,
  )
    .bind(c.req.param('id'))
    .first<Item>();
  return item ? c.json(item) : c.json({ error: 'Item not found' }, 404);
});

/** Ready when the database answers. */
export async function isReady(env: Env): Promise<boolean> {
  try {
    await env.DB.prepare('SELECT 1').first();
    return true;
  } catch {
    return false;
  }
}
