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

const PREFIX = 'item:';

export const api = new Hono<AppEnv>();

// Each item is also stored as the metadata of its key, so listing needs one
// request to KV instead of one per item. KV is eventually consistent: a new
// item can take up to a minute to appear in lists read at other locations.
api.get('/items', async (c) => {
  const { keys } = await c.env.KV.list<Item>({ prefix: PREFIX, limit: 100 });
  const items = keys
    .map((key) => key.metadata)
    .filter((item) => item !== undefined)
    .sort((a, b) => a.createdAt.localeCompare(b.createdAt));
  return c.json({ items });
});

api.post('/items', jsonBody(newItem), async (c) => {
  const { name } = c.req.valid('json');
  const item: Item = {
    id: crypto.randomUUID(),
    name,
    createdAt: new Date().toISOString(),
  };
  await c.env.KV.put(PREFIX + item.id, JSON.stringify(item), {
    metadata: item,
  });
  return c.json(item, 201, { Location: `/api/items/${item.id}` });
});

api.get('/items/:id', async (c) => {
  const item = await c.env.KV.get<Item>(PREFIX + c.req.param('id'), 'json');
  return item ? c.json(item) : c.json({ error: 'Item not found' }, 404);
});

/** Ready when the namespace answers. */
export async function isReady(env: Env): Promise<boolean> {
  try {
    await env.KV.get('readiness-probe');
    return true;
  } catch {
    return false;
  }
}
