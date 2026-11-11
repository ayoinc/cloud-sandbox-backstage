import { afterEach, describe, expect, it } from 'vitest';
import { CREATE_PRODUCT, startTestServer, type TestServer } from './helpers.js';

let server: TestServer | undefined;
afterEach(async () => {
  await server?.close();
  server = undefined;
});

describe('query complexity limit', () => {
  it('rejects a query that costs more than the limit', async () => {
    server = await startTestServer({ queryComplexityLimit: 50 });

    // 1 + 100 products x 2 fields = 201
    const expensive = await server.query('{ products(limit: 100) { id name } }');
    expect(expensive.status).toBe(400);
    expect(expensive.body.errors![0]!.extensions).toMatchObject({ code: 'QUERY_TOO_COMPLEX', complexity: 201, limit: 50 });

    // 1 + 10 products x 2 fields = 21
    const cheap = await server.query('{ products(limit: 10) { id name } }');
    expect(cheap.body.errors).toBeUndefined();
  });
});

describe('playground', () => {
  const browser = { headers: { accept: 'text/html' } };
  const INTROSPECTION = '{ __schema { queryType { name } } }';

  it('serves the Apollo Sandbox page and introspection when on', async () => {
    server = await startTestServer({ playground: true, nodeEnv: 'production' });

    const page = await fetch(`${server.url}/graphql`, browser);
    expect(page.status).toBe(200);
    expect(page.headers.get('content-type')).toContain('text/html');
    expect(await page.text()).toContain('Apollo');

    expect((await server.query(INTROSPECTION)).body.errors).toBeUndefined();
  });

  it('serves neither in production when off', async () => {
    server = await startTestServer({ playground: false, nodeEnv: 'production' });

    const page = await fetch(`${server.url}/graphql`, browser);
    expect(page.headers.get('content-type') ?? '').not.toContain('text/html');

    expect((await server.query(INTROSPECTION)).body.errors![0]!.extensions!.code).toBe('GRAPHQL_VALIDATION_FAILED');
  });
});

describe('metrics', () => {
  it('serves request durations and process metrics on /metrics when on', async () => {
    server = await startTestServer({ metrics: true });
    await server.query('query ListProducts { products { id } }');

    const response = await fetch(`${server.url}/metrics`);
    const text = await response.text();

    expect(response.status).toBe(200);
    expect(text).toContain(
      'graphql_request_duration_seconds_count{operation_name="ListProducts",operation_type="query",status="ok"} 1',
    );
    expect(text).toContain('process_cpu_user_seconds_total');
  });

  it('has no /metrics when off', async () => {
    server = await startTestServer({ metrics: false });

    expect((await fetch(`${server.url}/metrics`)).status).toBe(404);
  });
});

describe('response cache', () => {
  const LIST = '{ products { name } }';
  const widget = { variables: { input: { name: 'Widget', priceCents: 100 } } };

  it('answers a repeated query from the cache when on', async () => {
    server = await startTestServer({ cache: { enabled: true, ttlSeconds: 60 } });

    const first = await server.query(LIST);
    expect(first.headers.get('cache-control')).toBe('max-age=60, public');
    await server.query(CREATE_PRODUCT, widget);

    // Still the cached answer: the new product only shows once the entry expires.
    expect((await server.query(LIST)).body.data).toEqual({ products: [] });
  });

  it('always reads the database when off', async () => {
    server = await startTestServer({ cache: { enabled: false } });

    await server.query(LIST);
    await server.query(CREATE_PRODUCT, widget);

    expect((await server.query(LIST)).body.data).toEqual({ products: [{ name: 'Widget' }] });
  });
});

describe('health endpoints', () => {
  it('reports liveness and database readiness', async () => {
    server = await startTestServer();

    expect(await (await fetch(`${server.url}/healthz`)).json()).toEqual({ status: 'ok' });
    expect(await (await fetch(`${server.url}/readyz`)).json()).toEqual({ status: 'ok' });
  });
});
