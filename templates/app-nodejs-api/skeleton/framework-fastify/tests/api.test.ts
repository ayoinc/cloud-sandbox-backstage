import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app';
import { config } from '../src/config';

const app = buildApp();
// Routes that exercise the error handler; they can be added until the app is
// ready.
app.get('/boom', async () => {
  throw new Error('boom');
});
app.post('/echo', async (request) => request.body);

beforeAll(() => app.ready());
afterAll(() => app.close());

describe('Health endpoints', () => {
  it('GET /health reports the service as healthy', async () => {
    const response = await app.inject({ method: 'GET', url: '/health' });
    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body).toMatchObject({
      status: 'healthy',
      service: config.name,
      environment: config.environment,
    });
    expect(Number.isNaN(Date.parse(body.timestamp))).toBe(false);
  });

  it('GET /health/ready reports readiness', async () => {
    const response = await app.inject({ method: 'GET', url: '/health/ready' });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ ready: true });
  });

  it('GET /health/live reports liveness', async () => {
    const response = await app.inject({ method: 'GET', url: '/health/live' });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ alive: true });
  });
});

describe('API endpoints', () => {
  it('GET /api returns the welcome message', async () => {
    const response = await app.inject({ method: 'GET', url: '/api' });
    expect(response.statusCode).toBe(200);
    expect(response.json().message).toContain(config.name);
    expect(response.json().version).toBe('1.0.0');
  });

  it('GET /api/example returns example data', async () => {
    const response = await app.inject({ method: 'GET', url: '/api/example' });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ data: 'Example endpoint' });
  });
});

describe('Error handling', () => {
  it('returns 404 as JSON for unknown routes', async () => {
    const response = await app.inject({ method: 'GET', url: '/unknown-route' });
    expect(response.statusCode).toBe(404);
    expect(response.json()).toEqual({ error: 'Not Found' });
  });

  it('returns 400 as JSON when the request body is not valid JSON', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/echo',
      headers: { 'content-type': 'application/json' },
      payload: '{"broken"',
    });
    expect(response.statusCode).toBe(400);
    expect(response.json().error).toEqual(expect.any(String));
  });

  it('returns 500 as JSON when a handler throws', async () => {
    const response = await app.inject({ method: 'GET', url: '/boom' });
    expect(response.statusCode).toBe(500);
    expect(response.json()).toEqual({ error: 'Internal Server Error' });
  });
});
