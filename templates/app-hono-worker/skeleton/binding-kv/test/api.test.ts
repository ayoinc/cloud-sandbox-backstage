import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import { app } from '../src/app';

const post = (body: string) =>
  app.request(
    '/api/items',
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body,
    },
    env,
  );

describe('items', () => {
  it('creates, reads and lists an item', async () => {
    const created = await post(JSON.stringify({ name: '  first  ' }));
    expect(created.status).toBe(201);
    const item = await created.json<{ id: string; name: string }>();
    expect(item.name).toBe('first');
    expect(created.headers.get('location')).toBe(`/api/items/${item.id}`);

    const fetched = await app.request(`/api/items/${item.id}`, {}, env);
    expect(fetched.status).toBe(200);
    expect(await fetched.json()).toEqual(item);

    const listed = await app.request('/api/items', {}, env);
    const { items } = await listed.json<{ items: unknown[] }>();
    expect(items).toContainEqual(item);
  });

  it('rejects invalid input', async () => {
    expect((await post('name=first')).status).toBe(400);
    expect((await post(JSON.stringify({ name: '   ' }))).status).toBe(422);
    expect(
      (await post(JSON.stringify({ name: 'a', admin: true }))).status,
    ).toBe(422);
  });

  it('answers 404 for an unknown item', async () => {
    const response = await app.request('/api/items/missing', {}, env);
    expect(response.status).toBe(404);
    expect(await response.json()).toEqual({ error: 'Item not found' });
  });
});
