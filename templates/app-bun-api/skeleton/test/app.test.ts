import { describe, expect, it } from 'bun:test';
import { createApp } from '../src/app';
import { SERVICE_NAME } from '../src/config';
import { loadEnv } from '../src/env';
import { createLogger } from '../src/logger';
import { type ItemStore, MemoryItemStore } from '../src/store';

function testApp(options: { store?: ItemStore; isReady?: () => boolean } = {}) {
  const lines: string[] = [];
  const app = createApp({
    env: loadEnv({ APP_ENV: 'test' }),
    logger: createLogger('debug', (line) => lines.push(line)),
    store: options.store ?? new MemoryItemStore(),
    isReady: options.isReady,
  });
  return { app, lines };
}

const json = (body: unknown) => ({
  method: 'POST',
  headers: { 'content-type': 'application/json' },
  body: typeof body === 'string' ? body : JSON.stringify(body),
});

describe('health', () => {
  it('reports the service', async () => {
    const response = await testApp().app.request('/health');
    expect(response.status).toBe(200);
    expect(await response.json()).toMatchObject({
      status: 'ok',
      service: SERVICE_NAME,
      environment: 'test',
    });
    expect(response.headers.get('x-request-id')).toBeTruthy();
  });

  it('answers the probes', async () => {
    const { app } = testApp();
    expect(await (await app.request('/health/live')).json()).toEqual({
      alive: true,
    });
    expect((await app.request('/health/ready')).status).toBe(200);
  });

  it('is not ready while shutting down', async () => {
    const { app } = testApp({ isReady: () => false });
    const response = await app.request('/health/ready');
    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({ ready: false });
  });
});

describe('items', () => {
  it('creates, reads and lists an item', async () => {
    const { app } = testApp();

    const created = await app.request(
      '/api/items',
      json({ name: '  first  ' }),
    );
    expect(created.status).toBe(201);
    const item = (await created.json()) as { id: string; name: string };
    expect(item.name).toBe('first');
    expect(created.headers.get('location')).toBe(`/api/items/${item.id}`);

    const fetched = await app.request(`/api/items/${item.id}`);
    expect(await fetched.json()).toEqual(item);

    const listed = await app.request('/api/items');
    expect(await listed.json()).toEqual({ items: [item] });
  });

  it('rejects invalid input', async () => {
    const { app } = testApp();
    const status = async (body: unknown) =>
      (await app.request('/api/items', json(body))).status;

    expect(await status('name=first')).toBe(400);
    expect(await status({ name: '   ' })).toBe(422);
    expect(await status({ name: 'a', admin: true })).toBe(422);
  });

  it('answers 404 for an unknown item', async () => {
    const response = await testApp().app.request('/api/items/missing');
    expect(response.status).toBe(404);
  });
});

describe('errors and logs', () => {
  it('answers unknown routes with JSON', async () => {
    const response = await testApp().app.request('/nowhere');
    expect(response.status).toBe(404);
    expect(await response.json()).toEqual({ error: 'Not Found' });
  });

  it('hides the cause of unhandled errors and logs it', async () => {
    const store = new MemoryItemStore();
    store.list = async () => {
      throw new Error('database unreachable');
    };
    const { app, lines } = testApp({ store });

    const response = await app.request('/api/items');
    expect(response.status).toBe(500);
    expect(await response.json()).toEqual({ error: 'Internal Server Error' });

    const entries = lines.map((line) => JSON.parse(line));
    expect(entries).toContainEqual(
      expect.objectContaining({
        level: 'error',
        error: 'database unreachable',
      }),
    );
    expect(entries).toContainEqual(
      expect.objectContaining({ message: 'request', status: 500 }),
    );
  });

  it('skips entries below the configured level', () => {
    const lines: string[] = [];
    const logger = createLogger('warn', (line) => lines.push(line));
    logger.info('ignored');
    logger.warn('kept');
    expect(lines).toHaveLength(1);
  });
});
